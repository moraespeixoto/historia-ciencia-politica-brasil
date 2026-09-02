#!/usr/bin/env Rscript
# ==============================================================================
# 20_concentracao.R — Concentração institucional e geográfica das seis áreas
# ==============================================================================
# Fase 2, T2.6 do PLANO_OPUS5. (O plano sugeria o número 16; 16 e 17 já estão
# ocupados por `16_auditoria_pos_graduacao.R` e `17_figuras_slides.R`, então
# esta rotina entra como 20 para não sobrescrever nada.)
#
# Pergunta: a expansão da pós-graduação desconcentrou o sistema, ou apenas o
# espalhou geograficamente mantendo as mesmas instituições dominantes? Dois
# índices, calculados sobre TÍTULOS (não sobre programas), para 1995, 2013 e
# 2024, nas seis áreas comparadas:
#   HHI  — Herfindahl-Hirschman (soma dos quadrados das participações). Vai de
#          1/n (perfeitamente dividido) a 1 (uma única instituição).
#   Gini — desigualdade da distribuição de títulos entre IES e entre UFs.
# Os dois medem coisas diferentes: o HHI é sensível ao topo, o Gini à cauda.
# ==============================================================================

source(here::here("SCRIPTS", "00_setup.R"))
suppressPackageStartupMessages(library(ineq))

dir_processed <- here::here("DADOS", "processed")
dir_tabelas   <- here::here("TABELAS")
dir_figuras   <- here::here("FIGURAS")
dir_raw       <- here::here("DADOS", "raw", "capes_teses_comparada")

# Reaproveita o leitor da base comparada (mesma classificação de áreas), para
# não haver duas definições de "área" no projeto.
base_path <- file.path(dir_processed, "base_comparada_titulos.rds")
if (!file.exists(base_path)) {
  stop("Rode antes SCRIPTS/14_consolida_comparacao_teses.R (grava base_comparada_titulos.rds).")
}
base <- readRDS(base_path) %>% filter(area_nome != "Não identificado")

anos_alvo <- c(1995, 2013, 2024)

hhi <- function(x) { p <- x / sum(x); sum(p^2) }

indices <- purrr::map_dfr(anos_alvo, function(a) {
  d <- base %>% filter(ano == a)
  bind_rows(
    d %>% filter(!is.na(sigla_ies), sigla_ies != "") %>%
      count(area_nome, unidade = sigla_ies, name = "titulos") %>%
      group_by(area_nome) %>%
      # NB: as colunas criadas em `summarise` são visíveis para as seguintes,
      # então `titulos = sum(titulos)` ANTES de `hhi(titulos)` faria o HHI ser
      # calculado sobre um escalar (e dar 1). O total sai por último.
      summarise(ano = a, dimensao = "IES", n_unidades = n(),
                hhi = hhi(titulos), gini = ineq::Gini(titulos),
                part_maior = max(titulos) / sum(titulos),
                total_titulos = sum(titulos), .groups = "drop"),
    d %>% filter(!is.na(uf), uf != "") %>%
      count(area_nome, unidade = uf, name = "titulos") %>%
      group_by(area_nome) %>%
      summarise(ano = a, dimensao = "UF", n_unidades = n(),
                hhi = hhi(titulos), gini = ineq::Gini(titulos),
                part_maior = max(titulos) / sum(titulos),
                total_titulos = sum(titulos), .groups = "drop")
  )
})

write_csv(indices, file.path(dir_tabelas, "tabela_concentracao_hhi_gini.csv"))
saveRDS(indices, file.path(dir_processed, "concentracao_hhi_gini.rds"))

# Série anual completa, para o texto poder falar de tendência e não só de dois
# pontos.
serie_indices <- base %>%
  filter(!is.na(sigla_ies), sigla_ies != "", ano >= 1995) %>%
  count(ano, area_nome, sigla_ies, name = "titulos") %>%
  group_by(ano, area_nome) %>%
  summarise(hhi_ies = hhi(titulos), gini_ies = ineq::Gini(titulos), .groups = "drop")
serie_uf <- base %>%
  filter(!is.na(uf), uf != "", ano >= 1995) %>%
  count(ano, area_nome, uf, name = "titulos") %>%
  group_by(ano, area_nome) %>%
  summarise(gini_uf = ineq::Gini(titulos), .groups = "drop")
serie_indices <- serie_indices %>% left_join(serie_uf, by = c("ano", "area_nome"))
write_csv(serie_indices, file.path(dir_tabelas, "tabela_concentracao_serie.csv"))

p <- serie_indices %>%
  pivot_longer(c(hhi_ies, gini_ies, gini_uf), names_to = "indice", values_to = "valor") %>%
  mutate(indice = recode(indice, hhi_ies = "HHI (títulos por IES)",
                         gini_ies = "Gini (títulos por IES)",
                         gini_uf = "Gini (títulos por UF)")) %>%
  ggplot(aes(ano, valor, colour = area_nome)) +
  geom_line(linewidth = .8) +
  facet_wrap(~indice, scales = "free_y") +
  scale_colour_brewer(palette = "Dark2", name = "Área") +
  scale_x_continuous(breaks = seq(1995, 2025, 10)) +
  labs(title = "Concentração institucional e geográfica das titulações",
       subtitle = "Seis áreas de avaliação comparadas, 1995–2024",
       x = "Ano", y = "Índice",
       caption = "Fonte: Catálogo de Teses e Dissertações CAPES. HHI e Gini calculados sobre títulos por IES e por UF. Elaboração própria.") +
  theme_artigo() + theme(legend.position = "bottom")
ggsave(file.path(dir_figuras, "fig21_concentracao.png"), p, width = 9, height = 4.6, dpi = 300)
ggsave(file.path(dir_figuras, "fig21_concentracao.pdf"), p, width = 9, height = 4.6)

pega <- function(a, dim, col) {
  v <- indices[[col]][indices$ano == a & indices$dimensao == dim &
                        indices$area_nome == "Ciência Política / RI"]
  round(v, 3)
}
v_conc <- list(
  anos = anos_alvo,
  hhi_ies_39_2013 = pega(2013, "IES", "hhi"), hhi_ies_39_2024 = pega(2024, "IES", "hhi"),
  gini_ies_39_2013 = pega(2013, "IES", "gini"), gini_ies_39_2024 = pega(2024, "IES", "gini"),
  gini_uf_39_2013 = pega(2013, "UF", "gini"), gini_uf_39_2024 = pega(2024, "UF", "gini"),
  tabela = indices
)
saveRDS(v_conc, file.path(dir_processed, "valores_inline_concentracao.rds"))

cat("=== CONCENTRAÇÃO ===\n")
print(indices %>% filter(dimensao == "IES") %>%
        select(ano, area_nome, n_unidades, hhi, gini, part_maior, total_titulos) %>% arrange(ano, area_nome))
cat("\nGini por UF:\n")
print(indices %>% filter(dimensao == "UF") %>% select(ano, area_nome, n_unidades, gini))
