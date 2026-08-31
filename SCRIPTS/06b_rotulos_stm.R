#!/usr/bin/env Rscript
# ==============================================================================
# 06b_rotulos_stm.R — Regenera artefatos de rótulos do STM sem re-estimar
# ==============================================================================
# Usa o modelo salvo (stm_model_k8.rds) e as séries de prevalência salvas para
# regenerar: stm_topicos_nomes.rds, tabela_topicos_stm.csv, fig05, fig06 e
# valores_inline_stm.rds. Necessário quando os rótulos são revisados depois da
# estimação (ver AUDITORIA.md). Para re-estimar do zero, rode 06_analise_tematica_stm.R.

source(here::here("SCRIPTS", "00_setup.R"))

suppressPackageStartupMessages({
  library(stm)
})

dir_processed <- here::here("DADOS", "processed")
dir_figuras   <- here::here("FIGURAS")
dir_tabelas   <- here::here("TABELAS")
dir.create(dir_figuras, recursive = TRUE, showWarnings = FALSE)
dir.create(dir_tabelas, recursive = TRUE, showWarnings = FALSE)

# Rótulos alinhados aos termos FREX do modelo reestimado (corpus corrigido,
# 16.457 documentos). CONFERIR com os termos impressos abaixo.
topicos_nomes <- c(
  "T1: Direitos Humanos, Gênero e Segurança Pública",
  "T2: Relações Internacionais, Política Externa e Cooperação",
  "T3: Políticas Públicas, Saúde e Educação",
  "T4: Eleições, Partidos e Instituições Representativas",
  "T5: Corpus em espanhol (artefato de idioma)",
  "T6: Teoria Política e Pensamento Político",
  "T7: Corpus em inglês (BPSR)",
  "T8: Opinião Pública, Comunicação e Participação"
)

stm_model <- readRDS(file.path(dir_processed, "stm_model_k8.rds"))
K <- stm_model$settings$dim$K
cat(">>> Modelo: ", nrow(stm_model$theta), " documentos, K = ", K, "\n", sep = "")

top_terms <- labelTopics(stm_model, n = 8)
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

# Figura 5: evolução temporal (mesmo código de 06_analise_tematica_stm.R)
p_topicos <- ggplot(df_evolucao_anual, aes(x = ano, y = prevalencia, colour = topico)) +
  geom_point(alpha = 0.4, size = 1.5) +
  geom_smooth(method = "loess", span = 0.5, se = FALSE, linewidth = 1) +
  facet_wrap(~ topico, ncol = 2, scales = "free_y") +
  scale_x_continuous(breaks = seq(1995, 2024, by = 5)) +
  scale_y_continuous(labels = pct_ptbr(accuracy = 1)) +
  scale_colour_brewer(palette = "Dark2", guide = "none") +
  # anota a queda de dominância do tópico de teoria política (magnitude que o
  # free_y esconderia)
  geom_text(
    data = df_evolucao_anual %>%
      filter(grepl("Teoria Política", topico)) %>%
      group_by(ano) %>%
      summarise(prevalencia = mean(prevalencia), .groups = "drop") %>%
      filter(ano %in% c(min(ano), max(ano))) %>%
      mutate(rotulo = if_else(ano == min(ano), "36% (1995-97)", "13% (2022-24)")),
    aes(x = ano, y = prevalencia, label = rotulo), inherit.aes = FALSE,
    size = 2.6, colour = "#1A3559", fontface = "bold", vjust = -0.8
  ) +
  labs(
    title = "Evolução Temática da Ciência Política no Brasil",
    subtitle = "Prevalência média anual dos 8 tópicos (STM); descritivas, sem intervalos de incerteza",
    x = "Ano de Defesa / Publicação",
    y = "Proporção média no corpus",
    caption = paste0("Fonte: Corpus integrado CAPES e periódicos OpenAlex (N = ",
                     format(nrow(stm_model$theta), big.mark = "."), "). Elaboração própria.")
  ) +
  theme_artigo() +
  theme(plot.title = element_text(size = 13),
        strip.text = element_text(size = 8.5, face = "bold"))

ggsave(file.path(dir_figuras, "fig05_stm_evolucao_tematica.png"), p_topicos, width = 8, height = 7.5, dpi = 300)
ggsave(file.path(dir_figuras, "fig05_stm_evolucao_tematica.pdf"), p_topicos, width = 8, height = 7.5)

# Figura 6: heatmap por década (paleta sequencial clara + texto escuro legível)
p_heatmap <- ggplot(df_evolucao_decada, aes(x = decada, y = topico, fill = prevalencia)) +
  geom_tile(colour = "white", linewidth = 0.8) +
  geom_text(aes(label = pct_ptbr(accuracy = 0.1)(prevalencia)), colour = "#08306B", fontface = "bold", size = 3.2) +
  scale_fill_gradient(low = "#F7FBFF", high = "#2C7FB8", labels = pct_ptbr()) +
  labs(
    title = "Prevalência Média dos Tópicos por Década",
    subtitle = "Prevalências descritivas, sem intervalos de incerteza",
    x = "Período / Década",
    y = NULL,
    fill = "Prevalência"
  ) +
  theme_artigo() +
  theme(
    axis.text.y = element_text(size = 9, face = "bold"),
    legend.position = "bottom"
  )

ggsave(file.path(dir_figuras, "fig06_stm_heatmap_decadas.png"), p_heatmap, width = 8.5, height = 5, dpi = 300)
ggsave(file.path(dir_figuras, "fig06_stm_heatmap_decadas.pdf"), p_heatmap, width = 8.5, height = 5)

# Valores inline
saveRDS(list(corpus_stm_n = nrow(stm_model$theta),
             modelo_docs = nrow(stm_model$theta)),
        file.path(dir_processed, "valores_inline_stm.rds"))

cat(">>> ARTEFATOS DE RÓTULOS REGENERADOS.\n")
