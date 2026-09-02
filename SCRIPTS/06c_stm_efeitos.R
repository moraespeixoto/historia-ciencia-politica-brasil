#!/usr/bin/env Rscript
# ==============================================================================
# 06c_stm_efeitos.R — Efeitos de prevalência com controle de composição
# ==============================================================================
# Fase 2, T2.3 e T2.4 do PLANO_OPUS5.
#
# O problema que este script resolve. A Figura 5 do artigo mostra a MÉDIA de
# theta por ano. Essa média confunde duas coisas: mudança temática dentro de um
# mesmo tipo de documento e mudança na COMPOSIÇÃO do corpus. Entre 1995 e 2024
# o corpus deixa de ser quase só teses de ciência política estrita e passa a
# incluir RI, políticas públicas, defesa e segurança pública, além de resumos
# em outros idiomas. A "queda da teoria política" pode, em parte, ser apenas
# isso: novos documentos entrando, e não os antigos mudando de assunto.
#
# `estimateEffect` estima o efeito do ano sobre a prevalência de cada tópico
# CONTROLANDO fonte (tese vs artigo) e subárea do programa, com incerteza
# global (que propaga a incerteza da própria estimação do modelo de tópicos).
# Só sobrevive como achado o tópico cujo efeito de ano mantém sinal e
# significância depois desse controle.
#
# Também grava os documentos mais representativos de cada tópico
# (`findThoughts`), insumo obrigatório da rotulagem humana (T2.4).
# ==============================================================================

source(here::here("SCRIPTS", "00_setup.R"))
suppressPackageStartupMessages(library(stm))

dir_processed <- here::here("DADOS", "processed")
dir_tabelas   <- here::here("TABELAS")
dir_figuras   <- here::here("FIGURAS")

prep <- readRDS(file.path(dir_processed, "stm_prep.rds"))
modelo_path <- file.path(dir_processed, "stm_modelo.rds")
if (!file.exists(modelo_path)) modelo_path <- file.path(dir_processed, "stm_model_k8.rds")
mod <- readRDS(modelo_path)
K <- mod$settings$dim$K
meta <- prep$meta
stopifnot(nrow(meta) == nrow(mod$theta))

topicos_nomes <- readRDS(file.path(dir_processed, "stm_topicos_nomes.rds"))

# Subáreas com poucos documentos viram uma categoria só, para o modelo de
# efeitos não estimar coeficientes sobre um punhado de casos.
#
# ATENÇÃO à colinearidade: a subárea é uma propriedade do PROGRAMA, e só
# existe para teses; todo artigo de periódico recebe o valor "ARTIGO". Logo
# `subarea_f` determina `fonte` perfeitamente, e pôr as duas no mesmo modelo
# torna a matriz de covariáveis singular (o `estimateEffect` avisa, mas segue
# em frente com coeficientes não identificados). A solução usada aqui é
# controlar por `subarea_f` SOZINHA no modelo A: como "ARTIGO" é um de seus
# níveis, ela já absorve a diferença entre teses e artigos e ainda distingue as
# subáreas dentro das teses. O modelo B, que precisa de `fonte` explícita para
# testar a diferença de inclinação, dispensa `subarea_f` pela mesma razão.
meta <- meta %>%
  mutate(subarea_f = factor(if_else(subarea %in% c("CP", "RI", "PP", "DEFESA", "SEGPUB", "ARTIGO"),
                                    subarea, "OUTROS")),
         fonte = factor(fonte))
stopifnot(all(meta$subarea_f[meta$fonte == "OpenAlex"] == "ARTIGO"))

# Dois modelos, com papéis distintos.
#
# MODELO A (o do texto e da figura): `~ s(ano) + subarea_f`. Descreve
# a prevalência esperada ao longo do tempo MANTENDO FIXA a composição do
# corpus (mesma mistura de teses/artigos e de subáreas). É a resposta direta à
# objeção de composição: se a queda da teoria política persiste aqui, ela não
# é só efeito de entrada de novos tipos de documento.
#
# MODELO B (teste auxiliar): `~ ano * fonte`, linear no ano. Testa
# se a inclinação temporal difere entre teses e artigos. Usa-se ano LINEAR, e
# não spline, de propósito: o corpus de artigos é cerca de cinco vezes menor
# que o de teses, e uma interação spline x fonte fica superparametrizada nele —
# na prática devolvia prevalências esperadas negativas de até -1,1, que são
# artefato de ajuste, não resultado.
set.seed(20260828)
ef <- estimateEffect(1:K ~ s(ano) + subarea_f, mod,
                     metadata = meta, uncertainty = "Global")
saveRDS(ef, file.path(dir_processed, "stm_estimateEffect.rds"))

ef_int <- estimateEffect(1:K ~ ano * fonte, mod,
                         metadata = meta, uncertainty = "Global")
saveRDS(ef_int, file.path(dir_processed, "stm_estimateEffect_interacao.rds"))

# ---------------------------------------------------------------------------
# Modelo A: prevalência esperada por ano, composição fixa
# ---------------------------------------------------------------------------
faixa <- range(meta$ano)
grade <- seq(faixa[1], faixa[2], by = 1)
efeitos <- purrr::map_dfr(1:K, function(k) {
  p <- plot(ef, covariate = "ano", topics = k, model = mod,
            method = "continuous", printlegend = FALSE, plot = FALSE,
            ci.level = 0.95, npoints = length(grade))
  tibble(fonte = "composição fixa", k_num = k, topico = topicos_nomes[k],
         ano = p$x, estimativa = p$means[[1]],
         ic_inf = p$ci[[1]][1, ], ic_sup = p$ci[[1]][2, ])
})

# ---------------------------------------------------------------------------
# Modelo B: a inclinação temporal difere entre teses e artigos?
# ---------------------------------------------------------------------------
inclinacoes <- purrr::map_dfr(1:K, function(k) {
  s <- summary(ef_int, topics = k)$tables[[1]]
  linhas <- rownames(s)
  pega <- function(padrao) {
    i <- grep(padrao, linhas)
    if (!length(i)) return(c(NA_real_, NA_real_))
    c(s[i[1], "Estimate"], s[i[1], "Pr(>|t|)"])
  }
  a <- pega("^ano$"); b <- pega("^ano:fonte")
  tibble(k_num = k, topico = topicos_nomes[k],
         slope_capes = a[1], p_slope_capes = a[2],
         dif_slope_openalex = b[1], p_dif_slope = b[2])
})
write_csv(inclinacoes, file.path(dir_tabelas, "tabela_stm_inclinacoes_por_fonte.csv"))
write_csv(efeitos, file.path(dir_tabelas, "tabela_stm_efeitos_ano.csv"))
saveRDS(efeitos, file.path(dir_processed, "stm_efeitos_ano.rds"))

p_ef <- efeitos %>%
  ggplot(aes(ano, estimativa)) +
  geom_ribbon(aes(ymin = ic_inf, ymax = ic_sup), alpha = .20, fill = "#1F5FA8") +
  geom_line(linewidth = .9, colour = "#1F5FA8") +
  facet_wrap(~ topico, ncol = 2, scales = "free_y", labeller = label_wrap_gen(34)) +
  scale_y_continuous(labels = pct_ptbr(accuracy = 1)) +
  scale_x_continuous(breaks = seq(1990, 2025, 5)) +
  labs(title = "Prevalência esperada dos tópicos, com composição do corpus mantida fixa",
       subtitle = "estimateEffect com spline no ano, controlando a subárea do programa (nível \"artigo\" para os periódicos); faixas = IC de 95%",
       x = "Ano", y = "Prevalência esperada",
       caption = "Fonte: STM sobre o corpus integrado CAPES/OpenAlex em português. Incerteza \"Global\" (propaga a incerteza do modelo de tópicos). Elaboração própria.") +
  theme_artigo() + theme(strip.text = element_text(size = 7.6, face = "bold", lineheight = .95))
ggsave(file.path(dir_figuras, "fig05b_stm_efeitos_ano.png"), p_ef, width = 8.2, height = 8.6, dpi = 300)
ggsave(file.path(dir_figuras, "fig05b_stm_efeitos_ano.pdf"), p_ef, width = 8.2, height = 8.6)

# ---------------------------------------------------------------------------
# Teste da afirmação substantiva: o tópico caiu, controlando composição?
# ---------------------------------------------------------------------------
# Compara a prevalência esperada nos três primeiros e nos três últimos anos,
# dentro de cada fonte, com os ICs. Se os ICs se sobrepõem, a variação não
# sustenta uma afirmação de mudança.
resumo_ef <- efeitos %>%
  group_by(fonte, k_num, topico) %>%
  summarise(
    ini = mean(estimativa[ano <= min(ano) + 2]),
    ini_inf = mean(ic_inf[ano <= min(ano) + 2]),
    ini_sup = mean(ic_sup[ano <= min(ano) + 2]),
    fim = mean(estimativa[ano >= max(ano) - 2]),
    fim_inf = mean(ic_inf[ano >= max(ano) - 2]),
    fim_sup = mean(ic_sup[ano >= max(ano) - 2]),
    .groups = "drop"
  ) %>%
  mutate(variacao_pp = 100 * (fim - ini),
         ic_disjunto = (fim_sup < ini_inf) | (fim_inf > ini_sup),
         direcao = case_when(!ic_disjunto ~ "sem mudança distinguível",
                             fim > ini ~ "alta", TRUE ~ "queda"))
write_csv(resumo_ef, file.path(dir_tabelas, "tabela_stm_efeitos_resumo.csv"))

# ---------------------------------------------------------------------------
# Documentos exemplares por tópico (findThoughts) — insumo da rotulagem humana
# ---------------------------------------------------------------------------
textos <- meta$texto_original
if (is.null(textos)) textos <- meta$texto
exemplares <- purrr::map_dfr(1:K, function(k) {
  ft <- findThoughts(mod, texts = textos, topics = k, n = 20)
  idx <- ft$index[[1]]
  tibble(k_num = k, topico = topicos_nomes[k], posicao = seq_along(idx),
         theta = round(mod$theta[idx, k], 3),
         ano = meta$ano[idx], fonte = as.character(meta$fonte)[idx],
         subarea = meta$subarea[idx],
         trecho = str_trunc(str_squish(textos[idx]), 500))
})
write_csv(exemplares, file.path(dir_tabelas, "tabela_stm_exemplares_topicos.csv"))

saveRDS(list(efeitos = efeitos, resumo = resumo_ef, K = K),
        file.path(dir_processed, "valores_inline_stm_efeitos.rds"))

cat("=== EFEITOS DE PREVALÊNCIA (controlando fonte e subárea) ===\n")
print(as.data.frame(resumo_ef %>% select(fonte, topico, ini, fim, variacao_pp, direcao)))
cat("\n>>> Exemplares gravados em TABELAS/tabela_stm_exemplares_topicos.csv\n")
