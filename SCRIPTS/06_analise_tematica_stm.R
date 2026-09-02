#!/usr/bin/env Rscript
# ==============================================================================
# 06_analise_tematica_stm.R — Modelagem de Tópicos (STM) em Teses e Artigos
# ==============================================================================

source(here::here("SCRIPTS", "00_setup.R"))

suppressPackageStartupMessages({
  library(tidytext)
  library(stm)
  library(stopwords)
  library(stringi)
})

dir_processed <- here::here("DADOS", "processed")
dir_figuras   <- here::here("FIGURAS")
dir_tabelas   <- here::here("TABELAS")
dir.create(dir_figuras, recursive = TRUE, showWarnings = FALSE)
dir.create(dir_tabelas, recursive = TRUE, showWarnings = FALSE)

message(">>> Carregando bases para modelagem de tópicos...")
# Artefato canônico já filtrado pela área 39 (gerado por 08_auditoria_series_temporais.R).
capes    <- readRDS(file.path(dir_processed, "capes_cp_area39.rds"))
openalex <- readRDS(file.path(dir_processed, "artigos_periodicos_openalex.rds"))
prog     <- readRDS(file.path(dir_processed, "sucupira_programas_cp_2013_2024.rds"))

# -----------------------------------------------------------------------------
# 1. PREPARAÇÃO DO CORPUS COM TRANSLITERAÇÃO LIMPA
# -----------------------------------------------------------------------------
limpar_texto <- function(txt) {
  # Converte caracteres para UTF-8 válido e translitera acentos para ASCII limpo
  txt <- iconv(txt, from = "UTF-8", to = "ASCII//TRANSLIT", sub = "")
  txt <- tolower(txt)
  txt <- str_replace_all(txt, "[0-9]+", " ")
  txt <- str_replace_all(txt, "[[:punct:]]+", " ")
  txt <- str_replace_all(txt, "\\b[a-z]{1,2}\\b", " ") # Remove palavras <= 2 letras
  txt <- str_squish(txt)
  txt
}

# O idioma é detectado no resumo ORIGINAL (com acentos), antes da
# transliteração, e a subárea vem do nome do programa — ambos viram covariáveis
# do modelo e critérios da decisão de corpus (Fase 2).
if (!requireNamespace("cld2", quietly = TRUE)) stop("Pacote cld2 necessário.")
source(here::here("SCRIPTS", "10_classificacao_subareas_fun.R"))

# Corpus CAPES
df_capes_txt <- capes %>%
  mutate(
    resumo_raw = coalesce(ds_resumo, resumo_tese),
    ano = as.integer(coalesce(an_base, ano_base)),
    subarea = classificar_programa(coalesce(nm_programa, nome_programa))
  ) %>%
  filter(!is.na(resumo_raw), !is.na(ano)) %>%
  mutate(
    doc_id = paste0("CAPES_", row_number()),
    fonte = "CAPES",
    idioma_resumo = cld2::detect_language(resumo_raw),
    texto_original = resumo_raw,
    texto = limpar_texto(resumo_raw)
  ) %>%
  filter(nchar(texto) > 60) %>%
  select(doc_id, fonte, ano, subarea, idioma_resumo, texto, texto_original)

# Corpus OpenAlex (apenas artigos de pesquisa, sem front matter)
# O corte em 2024 é o mesmo da série de artigos (08): 2025-2026 têm indexação
# incompleta no OpenAlex. Sem ele, o corpus do STM ia até 2026 enquanto todas
# as demais séries do artigo paravam em 2024, e o spline do ano extrapolava
# para dois anos com um punhado de documentos.
df_oa_txt <- openalex %>%
  filter(!is.na(resumo), !is.na(ano), ano <= 2024, tipo == "article", !front_matter) %>%
  mutate(
    doc_id = paste0("OA_", row_number()),
    fonte = "OpenAlex",
    subarea = "ARTIGO",
    idioma_resumo = if ("idioma_resumo" %in% names(.)) idioma_resumo else cld2::detect_language(resumo),
    texto_original = resumo,
    texto = limpar_texto(resumo)
  ) %>%
  filter(nchar(texto) > 60) %>%
  select(doc_id, fonte, ano, subarea, idioma_resumo, texto, texto_original)

corpus_total <- bind_rows(df_capes_txt, df_oa_txt) %>%
  mutate(
    # C7/F23: o corpus modelado começa em 1995; o rótulo "1980-1999" prometia
    # uma década que não existe nos dados.
    decada = case_when(
      ano < 2000 ~ "1995-1999",
      ano >= 2000 & ano < 2010 ~ "2000-2009",
      ano >= 2010 & ano < 2020 ~ "2010-2019",
      ano >= 2020 ~ "2020-2024"
    )
  )

# ---------------------------------------------------------------------------
# 1b. Idioma do resumo e subárea do documento (covariáveis do modelo)
# ---------------------------------------------------------------------------
# O corpus é multilíngue (resumos em pt, en e es). Dois dos oito tópicos do
# modelo anterior eram artefatos de idioma, não linhas substantivas de
# pesquisa. Detectar o idioma permite (i) usá-lo como critério de corpus e
# (ii) reportar quantos documentos cada decisão descarta.
message(">>> Corpus total: ", nrow(corpus_total), " documentos.")
message(">>> Idioma dos resumos: ",
        paste(names(table(corpus_total$idioma_resumo, useNA = "ifany")),
              table(corpus_total$idioma_resumo, useNA = "ifany"),
              sep = "=", collapse = " "))

# ---------------------------------------------------------------------------
# 1c. DECISÃO DE CORPUS (Fase 2, T2.2)
# ---------------------------------------------------------------------------
# `stm_config.rds` é gravado por 06a_stm_searchK.R e carrega K e o recorte de
# idioma escolhidos. Sem o arquivo, o script roda no padrão histórico
# (corpus completo, K = 8), para continuar reproduzível sozinho.
cfg_path <- file.path(dir_processed, "stm_config.rds")
cfg <- if (file.exists(cfg_path)) readRDS(cfg_path) else list(K = 8, idioma = "todos")
corpus_modelado <- if (identical(cfg$idioma, "pt")) {
  corpus_total %>% filter(!is.na(idioma_resumo), idioma_resumo == "pt")
} else corpus_total
n_descartados_idioma <- nrow(corpus_total) - nrow(corpus_modelado)
message(">>> Corpus modelado (", cfg$idioma, "): ", nrow(corpus_modelado),
        " documentos (", n_descartados_idioma, " descartados por idioma).")
corpus_total <- corpus_modelado

# -----------------------------------------------------------------------------
# 2. STOPWORDS MULTILÍNGUES + ACADÊMICAS (TRANSLITERADAS)
# -----------------------------------------------------------------------------
sw_pt <- iconv(stopwords::stopwords("pt", source = "snowball"), to = "ASCII//TRANSLIT")
sw_en <- iconv(stopwords::stopwords("en", source = "snowball"), to = "ASCII//TRANSLIT")
sw_es <- iconv(stopwords::stopwords("es", source = "snowball"), to = "ASCII//TRANSLIT")
sw_fr <- iconv(stopwords::stopwords("fr", source = "snowball"), to = "ASCII//TRANSLIT")

sw_acad <- c(
  "artigo", "tese", "dissertacao", "dissertacoes", "teses", "pesquisa", "pesquisas",
  "estudo", "estudos", "analise", "analises", "analisar", "objetivo", "objetivos",
  "resultado", "resultados", "conclusao", "conclusoes", "trabalho", "trabalhos",
  "presente", "partir", "atraves", "sobre", "forma", "formas", "processo", "processos",
  "paper", "abstract", "resumo", "dados", "ano", "anos", "brasil", "brasileiro",
  "brasileira", "brasileiros", "brasileiras", "nacional", "geral", "contexto",
  "relevancia", "abordagem", "busca", "compreender", "identificar", "mostrar",
  "segundo", "sendo", "assim", "alem", "caso", "casos", "campo", "campos",
  "propoe", "busca", "busca-se", "analisa-se", "objetiva-se", "pretende-se",
  "principais", "diferentes", "tanto", "quanto", "ainda", "apenas", "sobretudo",
  "author", "article", "paper", "study", "research", "results", "analysis",
  "universidade", "programa", "pos", "graduacao", "mestrado", "doutorado"
)

todas_stopwords <- unique(tolower(c(sw_pt, sw_en, sw_es, sw_fr, sw_acad)))

processed <- textProcessor(
  documents = corpus_total$texto,
  metadata = corpus_total,
  lowercase = TRUE,
  removestopwords = TRUE,
  customstopwords = todas_stopwords,
  removenumbers = TRUE,
  removepunctuation = TRUE,
  stem = FALSE,
  wordLengths = c(3, Inf)
)

out <- prepDocuments(
  processed$documents,
  processed$vocab,
  processed$meta,
  lower.thresh = 20 # Aparece em no mínimo 20 documentos
)

# C: `corpus_stm_n` (documentos ANTES de prepDocuments) e `modelo_docs`
# (depois) são grandezas diferentes; a versão anterior sobrescrevia as duas com
# o mesmo valor.
n_corpus_antes <- nrow(corpus_total)
n_modelo_docs <- length(out$documents)
message(">>> Vocabulário final: ", length(out$vocab), " termos em ", n_modelo_docs,
        " documentos (", n_corpus_antes - n_modelo_docs, " descartados por prepDocuments).")

# Objeto de entrada preservado para `searchK` e `estimateEffect` (06a/06c).
saveRDS(list(documents = out$documents, vocab = out$vocab, meta = out$meta,
             n_corpus_antes = n_corpus_antes, n_modelo_docs = n_modelo_docs,
             config = cfg, n_descartados_idioma = n_descartados_idioma),
        file.path(dir_processed, "stm_prep.rds"))

# -----------------------------------------------------------------------------
# 3. ESTIMATIVA DO MODELO STM
# -----------------------------------------------------------------------------
set.seed(20260828)
K <- cfg$K
message(">>> Estimando modelo STM com K = ", K, " tópicos...")

stm_model <- stm(
  documents = out$documents,
  vocab = out$vocab,
  K = K,
  prevalence = ~ s(ano) + fonte,
  data = out$meta,
  max.em.its = 60,
  init.type = "Spectral",
  verbose = FALSE
)

# -----------------------------------------------------------------------------
# 4. ROTULAGEM DOS TÓPICOS A PARTIR DOS TERMOS FREX
# -----------------------------------------------------------------------------
top_terms <- labelTopics(stm_model, n = 8)

# Os rótulos NÃO são hardcodados aqui: dependem da ordem dos tópicos do modelo
# estimado e mudam a cada re-estimação. `stm_topicos_nomes.rds` guarda os
# rótulos vigentes; se o K mudar ou o arquivo não existir, o script gera
# rótulos provisórios com os próprios termos FREX, para que nenhuma figura
# saia com um rótulo herdado de outro modelo (foi o erro da rodada anterior).
nomes_path <- file.path(dir_processed, "stm_topicos_nomes.rds")
topicos_nomes <- if (file.exists(nomes_path)) readRDS(nomes_path) else NULL
if (is.null(topicos_nomes) || length(topicos_nomes) != K) {
  topicos_nomes <- sprintf("T%d: %s [a rotular]", 1:K,
                           apply(top_terms$frex[, 1:4, drop = FALSE], 1, paste, collapse = ", "))
  message(">>> Rótulos provisórios gerados (K mudou ou não havia rótulos salvos).")
}

message(">>> Tópicos identificados:")
for (k in 1:K) {
  termos_frex <- paste(top_terms$frex[k, 1:6], collapse = ", ")
  cat(sprintf("  [%s]: %s\n", topicos_nomes[k], termos_frex))
}

# -----------------------------------------------------------------------------
# 5. MATRIZ THETA (PREVALÊNCIA DOCUMENTO-TÓPICO) E AGREGADOS TEMPORAIS
# -----------------------------------------------------------------------------
theta_matrix <- stm_model$theta
colnames(theta_matrix) <- paste0("Topico_", 1:K)

df_theta <- bind_cols(out$meta, as.data.frame(theta_matrix))

# Prevalência média anual de cada tópico
df_evolucao_anual <- df_theta %>%
  filter(ano >= 1995, ano <= 2024) %>%
  group_by(ano) %>%
  summarise(across(starts_with("Topico_"), mean), .groups = "drop") %>%
  pivot_longer(starts_with("Topico_"), names_to = "topico_id", values_to = "prevalencia") %>%
  mutate(
    k_num = as.integer(sub("Topico_", "", topico_id)),
    topico = topicos_nomes[k_num]
  )

# Prevalência média por década
df_evolucao_decada <- df_theta %>%
  filter(!is.na(decada)) %>%
  group_by(decada) %>%
  summarise(across(starts_with("Topico_"), mean), .groups = "drop") %>%
  pivot_longer(starts_with("Topico_"), names_to = "topico_id", values_to = "prevalencia") %>%
  mutate(
    k_num = as.integer(sub("Topico_", "", topico_id)),
    topico = topicos_nomes[k_num]
  )

# -----------------------------------------------------------------------------
# 6. FIGURAS COM TEMA ARTIGO
# -----------------------------------------------------------------------------

# Figura 5: Evolução temporal da prevalência temática anual (com suavização loess)
p_topicos <- ggplot(df_evolucao_anual, aes(x = ano, y = prevalencia, colour = topico)) +
  geom_point(alpha = 0.4, size = 1.5) +
  geom_smooth(method = "loess", span = 0.5, se = FALSE, linewidth = 1) +
  facet_wrap(~ topico, ncol = 2, scales = "free_y") +
  scale_x_continuous(breaks = seq(1995, 2024, by = 5)) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_colour_brewer(palette = "Dark2", guide = "none") +
  labs(
    title = "Evolução Temática da Ciência Política no Brasil (1995–2024)",
    subtitle = paste0("Prevalência média anual dos ", K, " tópicos modelados via Structural Topic Model (STM)"),
    x = "Ano de Defesa / Publicação",
    y = "Proporção média no corpus",
    caption = paste0("Fonte: Corpus integrado CAPES e periódicos OpenAlex (N = ",
                     format(n_modelo_docs, big.mark = "."), "). Elaboração própria.")
  ) +
  theme_artigo() +
  theme(strip.text = element_text(size = 8.5, face = "bold"))

ggsave(file.path(dir_figuras, "fig05_stm_evolucao_tematica.png"), p_topicos, width = 8, height = 7.5, dpi = 300)
ggsave(file.path(dir_figuras, "fig05_stm_evolucao_tematica.pdf"), p_topicos, width = 8, height = 7.5)

# Figura 6: Comparação de Prevalência por Década (Heatmap)
p_heatmap <- ggplot(df_evolucao_decada, aes(x = decada, y = topico, fill = prevalencia)) +
  geom_tile(colour = "white", linewidth = 0.8) +
  geom_text(aes(label = scales::percent(prevalencia, accuracy = 0.1)), colour = "white", fontface = "bold", size = 3.5) +
  scale_fill_gradient(low = "#4C78A8", high = "#E45756", labels = scales::percent_format()) +
  labs(
    title = "Prevalência Média dos Tópicos por Ciclo Temporal (Décadas)",
    subtitle = "Matriz de transição temática na produção científica e acadêmica de CP no Brasil",
    x = "Período / Década",
    y = NULL,
    fill = "Prevalência"
  ) +
  theme_artigo() +
  theme(
    axis.text.y = element_text(size = 9, face = "bold"),
    legend.position = "right"
  )

ggsave(file.path(dir_figuras, "fig06_stm_heatmap_decadas.png"), p_heatmap, width = 8.5, height = 5, dpi = 300)
ggsave(file.path(dir_figuras, "fig06_stm_heatmap_decadas.pdf"), p_heatmap, width = 8.5, height = 5)

# -----------------------------------------------------------------------------
# 7. SALVAMENTO DE RESULTADOS
# -----------------------------------------------------------------------------
saveRDS(stm_model, file.path(dir_processed, "stm_modelo.rds"))
saveRDS(stm_model, file.path(dir_processed, paste0("stm_model_k", K, ".rds")))
saveRDS(df_theta, file.path(dir_processed, "stm_theta.rds"))
saveRDS(df_evolucao_anual, file.path(dir_processed, "stm_evolucao_anual.rds"))
saveRDS(df_evolucao_decada, file.path(dir_processed, "stm_evolucao_decada.rds"))
saveRDS(topicos_nomes, file.path(dir_processed, "stm_topicos_nomes.rds"))

# Valores inline para o manuscrito. `corpus_stm_n` e `modelo_docs` são
# grandezas DISTINTAS (antes e depois de prepDocuments).
saveRDS(
  list(corpus_stm_n = n_corpus_antes, modelo_docs = n_modelo_docs,
       corpus_bruto_n = n_corpus_antes + n_descartados_idioma,
       K = K, corpus_idioma = cfg$idioma,
       n_descartados_idioma = n_descartados_idioma,
       n_vocab = length(out$vocab)),
  file.path(dir_processed, "valores_inline_stm.rds")
)

tab_topicos <- purrr::map_dfr(1:K, function(k) {
  tibble(
    Tópico = topicos_nomes[k],
    `Termos FREX` = paste(top_terms$frex[k, 1:7], collapse = ", "),
    `Termos Alta Probabilidade` = paste(top_terms$prob[k, 1:7], collapse = ", ")
  )
})
write_csv(tab_topicos, file.path(dir_tabelas, "tabela_topicos_stm.csv"))

message(">>> MODELAGEM DE TÓPICOS CONCLUÍDA E SALVA COM SUCESSO!")
