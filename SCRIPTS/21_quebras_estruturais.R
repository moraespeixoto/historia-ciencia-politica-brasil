#!/usr/bin/env Rscript
# ==============================================================================
# 21_quebras_estruturais.R — Pontos de quebra nas séries de titulação
# ==============================================================================
# Fase 2, T2.6 do PLANO_OPUS5.
#
# O artigo propõe uma periodização em "três idades" construída a partir da
# literatura. Este script faz a pergunta simétrica: se ninguém tivesse proposto
# uma periodização, ONDE os dados a colocariam? `strucchange::breakpoints`
# estima as datas de quebra na tendência de log(títulos) por ano, escolhendo o
# número de quebras por BIC, e devolve intervalos de confiança para cada data.
#
# Trabalha em log porque a série cresce por ordens de grandeza: em nível, uma
# quebra dos anos 1990 seria invisível ao lado da variação absoluta dos anos
# 2010. A janela começa em 1995 porque o Catálogo é reconhecidamente incompleto
# antes disso (26 títulos em 1987 para seis programas de doutorado ativos).
#
# O que ISTO É: uma descrição de quando a inclinação da série muda. O que NÃO
# É: identificação do efeito de qualquer política. As datas de política
# (PNPG, Reuni, cortes de 2015-16, pandemia) entram só como referência visual.
# ==============================================================================

source(here::here("SCRIPTS", "00_setup.R"))
suppressPackageStartupMessages(library(strucchange))

dir_processed <- here::here("DADOS", "processed")
dir_tabelas   <- here::here("TABELAS")
dir_figuras   <- here::here("FIGURAS")

ANO_INICIO <- 1995
H_MIN <- 5  # mínimo de anos em cada segmento

base <- readRDS(file.path(dir_processed, "base_comparada_titulos.rds")) %>%
  filter(area_nome != "Não identificado")

series <- base %>%
  filter(ano >= ANO_INICIO) %>%
  count(ano, area_nome, name = "titulos") %>%
  filter(titulos > 0)

estimar_quebras <- function(d, rotulo) {
  d <- arrange(d, ano)
  if (nrow(d) < 3 * H_MIN) return(NULL)
  bp <- tryCatch(
    strucchange::breakpoints(log(titulos) ~ ano, data = d,
                             h = H_MIN / nrow(d)),
    error = function(e) NULL)
  if (is.null(bp) || all(is.na(bp$breakpoints))) {
    return(tibble(serie = rotulo, quebra = NA_integer_, ic_inf = NA_integer_,
                  ic_sup = NA_integer_, n_quebras = 0L,
                  bic_otimo = NA_real_))
  }
  idx <- bp$breakpoints
  ic <- tryCatch(confint(bp)$confint, error = function(e) NULL)
  tibble(
    serie = rotulo,
    quebra = d$ano[idx],
    ic_inf = if (!is.null(ic)) d$ano[pmax(1, ic[, 1])] else NA_integer_,
    ic_sup = if (!is.null(ic)) d$ano[pmin(nrow(d), ic[, 3])] else NA_integer_,
    n_quebras = length(idx),
    bic_otimo = min(BIC(bp), na.rm = TRUE)
  )
}

quebras <- purrr::map_dfr(unique(series$area_nome), function(a) {
  estimar_quebras(series %>% filter(area_nome == a), a)
})

write_csv(quebras, file.path(dir_tabelas, "tabela_quebras_estruturais.csv"))
saveRDS(quebras, file.path(dir_processed, "quebras_estruturais.rds"))

marcos_politica <- tribble(
  ~ano, ~marco,
  2005, "PNPG 2005-2010",
  2007, "Reuni",
  2011, "PNPG 2011-2020",
  2016, "Contingenciamento CAPES/CNPq",
  2020, "Pandemia"
)
write_csv(marcos_politica, file.path(dir_tabelas, "tabela_marcos_politica_pos.csv"))

q39 <- quebras %>% filter(serie == "Ciência Política / RI", !is.na(quebra))
p <- series %>%
  ggplot(aes(ano, titulos)) +
  geom_line(linewidth = .8, colour = "#1F5FA8") +
  geom_vline(data = quebras %>% filter(!is.na(quebra)),
             aes(xintercept = quebra), linetype = "dashed", colour = "#E45756") +
  geom_rect(data = quebras %>% filter(!is.na(ic_inf)),
            aes(xmin = ic_inf, xmax = ic_sup, ymin = -Inf, ymax = Inf),
            inherit.aes = FALSE, fill = "#E45756", alpha = .12) +
  facet_wrap(~area_nome, scales = "free_y") +
  scale_y_continuous(trans = "log10", labels = num_ptbr()) +
  scale_x_continuous(breaks = seq(1995, 2025, 10)) +
  labs(title = "Quebras estimadas na tendência das titulações (1995–2024)",
       subtitle = "Linhas tracejadas: datas de quebra estimadas por strucchange; faixas: intervalos de confiança de 95%",
       x = "Ano", y = "Títulos (escala log)",
       caption = "Fonte: Catálogo de Teses e Dissertações CAPES. Modelo: log(títulos) ~ ano, quebras por BIC, segmentos de no mínimo 5 anos. Descritivo, não causal.") +
  theme_artigo()
ggsave(file.path(dir_figuras, "fig22_quebras_estruturais.png"), p, width = 9, height = 5.6, dpi = 300)
ggsave(file.path(dir_figuras, "fig22_quebras_estruturais.pdf"), p, width = 9, height = 5.6)

saveRDS(list(quebras = quebras, quebras_area39 = q39$quebra,
             ic_area39 = if (nrow(q39)) paste0(q39$ic_inf, "-", q39$ic_sup) else character(0),
             ano_inicio = ANO_INICIO, h_min = H_MIN),
        file.path(dir_processed, "valores_inline_quebras.rds"))

cat("=== QUEBRAS ESTRUTURAIS (log títulos ~ ano, 1995-2024) ===\n")
print(as.data.frame(quebras))
