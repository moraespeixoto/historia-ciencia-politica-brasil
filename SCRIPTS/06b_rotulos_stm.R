#!/usr/bin/env Rscript
# ==============================================================================
# 06b_rotulos_stm.R — Rótulos dos tópicos e figuras do STM (sem re-estimar)
# ==============================================================================
# Usa o modelo salvo por 06 e as séries de prevalência já calculadas para
# regenerar `stm_topicos_nomes.rds`, `tabela_topicos_stm.csv`, fig05 e fig06.
# Para re-estimar do zero, rode 06_analise_tematica_stm.R.
#
# Correções de 2026-09-02 (REVISAO_CRITICA C6, C7, F22):
#  - os rótulos deixam de ser um vetor hardcoded no script e passam a vir de
#    DADOS/rotulos_stm.csv, um insumo editável conferido contra os termos FREX
#    do modelo VIGENTE. Se o arquivo não existir ou não tiver o mesmo K, o
#    script gera rótulos provisórios a partir dos próprios termos FREX e avisa
#    — nunca reutiliza rótulos de um modelo anterior;
#  - a anotação da Fig. 5 é CALCULADA a partir de `stm_evolucao_anual.rds` e
#    desenhada apenas na faceta correspondente. A versão anterior escrevia
#    "36% (1995-97)" à mão (o valor real era 38,6%) e o `geom_text` repetia o
#    rótulo em todas as oito facetas, saindo truncado como "13% (2022";
#  - rótulos de faceta quebrados em várias linhas (`label_wrap_gen`);
#  - `corpus_stm_n` (documentos antes de prepDocuments) e `modelo_docs`
#    (depois) deixam de ser o mesmo número.
# ==============================================================================

source(here::here("SCRIPTS", "00_setup.R"))
suppressPackageStartupMessages(library(stm))

dir_processed <- here::here("DADOS", "processed")
dir_figuras   <- here::here("FIGURAS")
dir_tabelas   <- here::here("TABELAS")
dir.create(dir_figuras, recursive = TRUE, showWarnings = FALSE)
dir.create(dir_tabelas, recursive = TRUE, showWarnings = FALSE)

modelo_path <- file.path(dir_processed, "stm_modelo.rds")
if (!file.exists(modelo_path)) modelo_path <- file.path(dir_processed, "stm_model_k8.rds")
stm_model <- readRDS(modelo_path)
K <- stm_model$settings$dim$K
cat(">>> Modelo: ", nrow(stm_model$theta), " documentos, K = ", K, "\n", sep = "")

top_terms <- labelTopics(stm_model, n = 8)

# ---------------------------------------------------------------------------
# Rótulos: insumo editável, conferido contra os termos FREX do modelo vigente
# ---------------------------------------------------------------------------
rotulos_path <- here::here("DADOS", "rotulos_stm.csv")
topicos_nomes <- NULL
if (file.exists(rotulos_path)) {
  rot <- read_csv(rotulos_path, show_col_types = FALSE)
  if (nrow(rot) == K && all(c("k", "rotulo") %in% names(rot))) {
    topicos_nomes <- rot$rotulo[order(rot$k)]
  } else {
    warning("DADOS/rotulos_stm.csv não corresponde ao K do modelo (", K, "): ignorado.")
  }
}
if (is.null(topicos_nomes)) {
  topicos_nomes <- sprintf("T%d: %s [a rotular]", 1:K,
                           apply(top_terms$frex[, 1:4, drop = FALSE], 1, paste, collapse = ", "))
  message(">>> Rótulos provisórios gerados a partir dos termos FREX.")
}

cat(">>> CONFERIR rótulos x termos FREX:\n")
for (k in 1:K) {
  cat(sprintf("  [%s]\n      FREX: %s\n", topicos_nomes[k],
              paste(top_terms$frex[k, 1:7], collapse = ", ")))
}

# Re-rotula as séries de prevalência salvas
relabel <- function(df) {
  df %>%
    mutate(k_num = as.integer(sub("Topico_", "", topico_id)),
           topico = topicos_nomes[k_num])
}
df_evolucao_anual  <- relabel(readRDS(file.path(dir_processed, "stm_evolucao_anual.rds")))
df_evolucao_decada <- relabel(readRDS(file.path(dir_processed, "stm_evolucao_decada.rds")))

saveRDS(df_evolucao_anual, file.path(dir_processed, "stm_evolucao_anual.rds"))
saveRDS(df_evolucao_decada, file.path(dir_processed, "stm_evolucao_decada.rds"))
saveRDS(topicos_nomes, file.path(dir_processed, "stm_topicos_nomes.rds"))

# Tabela de tópicos
tab_topicos <- purrr::map_dfr(1:K, function(k) {
  tibble(
    Tópico = topicos_nomes[k],
    `Termos FREX` = paste(top_terms$frex[k, 1:7], collapse = ", "),
    `Termos Alta Probabilidade` = paste(top_terms$prob[k, 1:7], collapse = ", ")
  )
})
write_csv(tab_topicos, file.path(dir_tabelas, "tabela_topicos_stm.csv"))

# ---------------------------------------------------------------------------
# Figura 5: evolução temporal, com anotação gerada a partir dos dados
# ---------------------------------------------------------------------------
# Para CADA tópico, marca a média dos três primeiros e dos três últimos anos da
# série. Os valores saem do próprio `stm_evolucao_anual.rds`; nenhum número é
# escrito à mão, e cada rótulo pertence à sua faceta (a coluna `topico` está no
# data frame da anotação, então o facet_wrap o distribui corretamente).
anos_ini <- sort(unique(df_evolucao_anual$ano))[1:3]
anos_fim <- rev(sort(unique(df_evolucao_anual$ano)))[3:1]
anotacoes <- bind_rows(
  df_evolucao_anual %>% filter(ano %in% anos_ini) %>%
    group_by(topico) %>%
    summarise(ano = max(anos_ini), prevalencia = mean(prevalencia), .groups = "drop") %>%
    mutate(rotulo = sprintf("%s%% (%d-%s)", format(round(100 * prevalencia, 1), decimal.mark = ","),
                            min(anos_ini), substr(max(anos_ini), 3, 4))),
  df_evolucao_anual %>% filter(ano %in% anos_fim) %>%
    group_by(topico) %>%
    summarise(ano = min(anos_fim), prevalencia = mean(prevalencia), .groups = "drop") %>%
    mutate(rotulo = sprintf("%s%% (%d-%s)", format(round(100 * prevalencia, 1), decimal.mark = ","),
                            min(anos_fim), substr(max(anos_fim), 3, 4)))
)
write_csv(anotacoes, file.path(dir_tabelas, "tabela_stm_anotacoes_fig05.csv"))

p_topicos <- ggplot(df_evolucao_anual, aes(x = ano, y = prevalencia, colour = topico)) +
  geom_point(alpha = 0.4, size = 1.5) +
  geom_smooth(method = "loess", span = 0.5, se = FALSE, linewidth = 1) +
  facet_wrap(~ topico, ncol = 2, scales = "free_y",
             labeller = label_wrap_gen(width = 34)) +
  scale_x_continuous(breaks = seq(min(df_evolucao_anual$ano), max(df_evolucao_anual$ano), by = 5),
                     expand = expansion(mult = c(0.06, 0.10))) +
  scale_y_continuous(labels = pct_ptbr(accuracy = 1),
                     expand = expansion(mult = c(0.10, 0.22))) +
  scale_colour_brewer(palette = "Dark2", guide = "none") +
  geom_text(data = anotacoes, aes(x = ano, y = prevalencia, label = rotulo),
            inherit.aes = FALSE, size = 2.4, colour = "#1A3559",
            fontface = "bold", vjust = -0.9) +
  labs(
    title = "Evolução Temática da Área 39 (Ciência Política e Relações Internacionais)",
    subtitle = paste0("Prevalência média anual dos ", K,
                      " tópicos (STM); médias descritivas, sem intervalos de incerteza"),
    x = "Ano de Defesa / Publicação",
    y = "Proporção média no corpus",
    caption = paste0("Fonte: Corpus integrado CAPES e periódicos OpenAlex (N = ",
                     format(nrow(stm_model$theta), big.mark = "."),
                     " documentos modelados). Rótulos calculados a partir de stm_evolucao_anual.rds. Elaboração própria.")
  ) +
  theme_artigo() +
  theme(plot.title = element_text(size = 12.5),
        strip.text = element_text(size = 7.6, face = "bold", lineheight = 0.95))

ggsave(file.path(dir_figuras, "fig05_stm_evolucao_tematica.png"), p_topicos, width = 8, height = 8.4, dpi = 300)
ggsave(file.path(dir_figuras, "fig05_stm_evolucao_tematica.pdf"), p_topicos, width = 8, height = 8.4)

# ---------------------------------------------------------------------------
# Figura 6: heatmap por década
# ---------------------------------------------------------------------------
p_heatmap <- ggplot(df_evolucao_decada, aes(x = decada, y = topico, fill = prevalencia)) +
  geom_tile(colour = "white", linewidth = 0.8) +
  geom_text(aes(label = pct_ptbr(accuracy = 0.1)(prevalencia)), colour = "#08306B", fontface = "bold", size = 3.2) +
  scale_fill_gradient(low = "#F7FBFF", high = "#2C7FB8", labels = pct_ptbr()) +
  scale_y_discrete(labels = function(x) str_wrap(x, 38)) +
  labs(
    title = "Prevalência Média dos Tópicos por Período",
    subtitle = "Prevalências descritivas, sem intervalos de incerteza; o corpus modelado começa em 1995",
    x = "Período", y = NULL, fill = "Prevalência"
  ) +
  theme_artigo() +
  theme(axis.text.y = element_text(size = 8, face = "bold", lineheight = 0.95),
        legend.position = "bottom")

ggsave(file.path(dir_figuras, "fig06_stm_heatmap_decadas.png"), p_heatmap, width = 8.5, height = 5.4, dpi = 300)
ggsave(file.path(dir_figuras, "fig06_stm_heatmap_decadas.pdf"), p_heatmap, width = 8.5, height = 5.4)

# ---------------------------------------------------------------------------
# Valores inline: preserva os valores gravados por 06 e apenas complementa.
# ---------------------------------------------------------------------------
v_stm_path <- file.path(dir_processed, "valores_inline_stm.rds")
v_stm <- if (file.exists(v_stm_path)) readRDS(v_stm_path) else list()
v_stm$modelo_docs <- nrow(stm_model$theta)
v_stm$K <- K
v_stm$topicos_nomes <- topicos_nomes
v_stm$anotacoes_fig05 <- anotacoes
saveRDS(v_stm, v_stm_path)

cat(">>> ARTEFATOS DE RÓTULOS REGENERADOS. corpus_stm_n =",
    v_stm$corpus_stm_n, "| modelo_docs =", v_stm$modelo_docs, "\n")
