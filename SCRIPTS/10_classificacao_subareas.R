#!/usr/bin/env Rscript
# ==============================================================================
# 10_classificacao_subareas.R — Separação da Área 39 em Subáreas
# Projeto: História, Expansão e Institucionalização da Ciência Política no Brasil
#
# A "área 39" da CAPES abriga programas de Ciência Política, Relações
# Internacionais, Políticas Públicas e Defesa/Segurança. Este script classifica
# cada registro do Catálogo CAPES e cada programa do Sucupira em cinco
# categorias mutuamente exclusivas:
#   CP      — Ciência Política (incl. comportamento político e estudos legislativos)
#   RI      — Relações Internacionais, Política Externa e Integração Regional
#   PP      — Políticas Públicas, Gestão e Avaliação
#   DEFESA  — Defesa, Segurança, Estudos Estratégicos e Militares
#   OUTROS  — residual (programas interdisciplinares, direito, educação etc.)
#
# Saídas:
#   TABELAS/tabela_titulos_subareas.csv        (ano x subárea x n, 1987-2024)
#   TABELAS/tabela_programas_subareas.csv      (programas Sucupira por subárea)
#   FIGURAS/fig09_subareas_temporal.png/.pdf   (série temporal da composição)
#   DADOS/processed/valores_inline_subareas.rds (valores para o manuscrito)
# ==============================================================================

source(here::here("SCRIPTS", "00_setup.R"))

dir_processed <- here::here("DADOS", "processed")
dir_figuras   <- here::here("FIGURAS")
dir_tabelas   <- here::here("TABELAS")
dir.create(dir_figuras, recursive = TRUE, showWarnings = FALSE)
dir.create(dir_tabelas, recursive = TRUE, showWarnings = FALSE)

# -----------------------------------------------------------------------------
# 1. Função de classificação (ordem das regras é relevante)
# -----------------------------------------------------------------------------
classificar_programa <- function(prog) {
  p <- toupper(iconv(prog, to = "ASCII//TRANSLIT", sub = ""))
  sub <- dplyr::case_when(
    grepl("CIENCIA POLITICA|COMPORTAMENTO POLITICO|PODER LEGISLATIVO", p) ~ "CP",
    grepl("ESTRATEGIC|MILITAR|AEROESPACIAL|MARITIMO|DEFESA|SEGURANCA(?! SOCIAL)", p, perl = TRUE) ~ "DEFESA",
    grepl("RELACOES INTERNACIONAIS|POLITICA INTERNACIONAL|ECONOMIA POLITICA INTERNACIONAL|GOVERNANCA GLOBAL|INTEGRACAO CONTEMPORANEA|ANALISE E GESTAO DE POLITICAS INTERNACIONAIS|INTERNACIONAIS$", p) ~ "RI",
    grepl("POLITICAS PUBLICAS|GESTAO DE POLITICAS|AVALIACAO E MONITORAMENTO|GOVERNANCA E DESENVOLVIMENTO", p) ~ "PP",
    TRUE ~ "OUTROS"
  )
  sub
}

classificar_capes <- function(df) {
  # Regra 1 (layout antigo): área de conhecimento CNPq
  #   7090xxxx (exceto 70905) = Ciência Política/Comportamento Político -> CP
  #   70905xxx = Política Internacional / RI -> RI
  code <- df$area_conhecimento_codigo
  sub <- rep(NA_character_, nrow(df))
  sub <- ifelse(grepl("^7090", code) & !grepl("^70905", code), "CP", sub)
  sub <- ifelse(grepl("^70905", code), "RI", sub)

  # Regra 2 (ambos os layouts): override pelo nome do programa (ordem relevante)
  prog <- ifelse(!is.na(df$an_base), df$nm_programa, df$nome_programa)
  p <- toupper(iconv(prog, to = "ASCII//TRANSLIT", sub = ""))

  # DEFESA/SEGURANÇA primeiro (exclui "SEGURANÇA SOCIAL", que é programa de PP)
  sub <- ifelse(grepl("ESTRATEGIC|MILITAR|AEROESPACIAL|MARITIMO|DEFESA|SEGURANCA(?! SOCIAL)", p, perl = TRUE), "DEFESA", sub)
  # POLÍTICAS PÚBLICAS
  sub <- ifelse(grepl("POLITICAS PUBLICAS|GESTAO DE POLITICAS|AVALIACAO E MONITORAMENTO|GOVERNANCA E DESENVOLVIMENTO", p), "PP", sub)
  # RELAÇÕES INTERNACIONAIS / diplomacia / integração regional
  sub <- ifelse(grepl("RELACOES INTERNACIONAIS|POLITICA INTERNACIONAL|ECONOMIA POLITICA INTERNACIONAL|GOVERNANCA GLOBAL|INTEGRACAO CONTEMPORANEA|INTEGRACAO LATINO|LATINO-AMERICANA|LATINO AMERICANA|DIPLOMACIA|ANALISE E GESTAO DE POLITICAS INTERNACIONAIS|INTERNACIONAIS$", p), "RI", sub)
  # CIÊNCIA POLÍTICA
  sub <- ifelse(grepl("CIENCIA POLITICA|COMPORTAMENTO POLITICO|PODER LEGISLATIVO", p), "CP", sub)

  sub[is.na(sub)] <- "OUTROS"
  sub
}

# -----------------------------------------------------------------------------
# 2. Classifica registros do Catálogo CAPES (apenas área 39, ver AUDITORIA.md)
# -----------------------------------------------------------------------------
# Artefato canônico já filtrado pela área 39 (gerado por 08_auditoria_series_temporais.R).
capes <- readRDS(file.path(dir_processed, "capes_cp_area39.rds"))
prog <- readRDS(file.path(dir_processed, "sucupira_programas_cp_2013_2024.rds"))
capes$subarea <- classificar_capes(capes)
capes$ano_unificado <- as.integer(coalesce(capes$an_base, capes$ano_base))

message(">>> Distribuição de registros por subárea:")
print(table(capes$subarea, useNA = "ifany"))

# Série anual de títulos por subárea
serie_subarea <- capes %>%
  filter(!is.na(ano_unificado)) %>%
  count(ano = ano_unificado, subarea, name = "titulos") %>%
  complete(ano = seq(min(ano), max(ano)), subarea = c("CP", "RI", "PP", "DEFESA", "OUTROS"),
           fill = list(titulos = 0)) %>%
  arrange(ano, subarea)

write_csv(serie_subarea, file.path(dir_tabelas, "tabela_titulos_subareas.csv"))
saveRDS(serie_subarea, file.path(dir_processed, "tabela_titulos_subareas.rds"))

# -----------------------------------------------------------------------------
# 3. Programas Sucupira por subárea (2013-2024)
# -----------------------------------------------------------------------------
prog <- readRDS(file.path(dir_processed, "sucupira_programas_cp_2013_2024.rds")) %>%
  filter(is.na(ds_situacao_programa) | ds_situacao_programa != "EM DESATIVACAO")
prog_sub <- prog %>%
  distinct(cd_programa_ies, .keep_all = TRUE) %>%
  mutate(subarea = classificar_programa(nm_programa_ies))

tab_programas <- prog_sub %>%
  count(subarea, name = "n_programas") %>%
  mutate(pct = round(100 * n_programas / sum(n_programas), 1))

# Programas ativos em 2024 por subárea
prog_2024 <- prog %>%
  filter(ano_base == "2024") %>%
  distinct(cd_programa_ies, .keep_all = TRUE) %>%
  mutate(subarea = classificar_programa(nm_programa_ies))

tab_programas_2024 <- prog_2024 %>%
  count(subarea, name = "n_programas_2024") %>%
  mutate(pct_2024 = round(100 * n_programas_2024 / sum(n_programas_2024), 1))

tab_final <- tab_programas %>%
  left_join(tab_programas_2024, by = "subarea") %>%
  replace_na(list(n_programas_2024 = 0, pct_2024 = 0))

write_csv(tab_final, file.path(dir_tabelas, "tabela_programas_subareas.csv"))

# Mapeamento completo (transparência da classificação)
mapa <- prog_sub %>%
  select(cd_programa_ies, nm_programa_ies, subarea) %>%
  arrange(subarea, nm_programa_ies)
write_csv(mapa, file.path(dir_tabelas, "tabela_mapeamento_programas_subareas.csv"))

# -----------------------------------------------------------------------------
# 4. Figura: composição da área 39 ao longo do tempo
# -----------------------------------------------------------------------------
legenda <- c(CP = "Ciência Política", RI = "Relações Internacionais",
             PP = "Políticas Públicas", DEFESA = "Defesa e Segurança",
             OUTROS = "Outros / Interdisciplinares")

p9 <- serie_subarea %>%
  filter(ano >= 1995) %>%
  mutate(subarea = factor(subarea, levels = rev(c("CP", "RI", "PP", "DEFESA", "OUTROS")))) %>%
  ggplot(aes(x = ano, y = titulos, fill = subarea)) +
  geom_area(position = "stack", alpha = 0.85) +
  scale_fill_manual(
    values = c(CP = "#4C78A8", RI = "#54A24B", PP = "#F58518", DEFESA = "#E45756", OUTROS = "#BAB0AC"),
    labels = legenda, name = "Subárea"
  ) +
  # Legenda em 2 linhas: com rótulos longos, a linha única transbordava a largura
  # da figura e cortava a última categoria (Ciência Política).
  guides(fill = guide_legend(nrow = 2, byrow = TRUE)) +
  scale_x_continuous(breaks = seq(1995, 2025, by = 5)) +
  scale_y_continuous(name = "Títulos (mestrado e doutorado)", breaks = scales::pretty_breaks(6)) +
  labs(
    title = "Composição da Área 39 por Subárea (1995–2024)",
    subtitle = "Teses e dissertações classificadas por programa: CP, RI, Políticas Públicas, Defesa/Segurança e outros",
    x = "Ano",
    caption = "Fonte: Catálogo de Teses e Dissertações CAPES (classificação própria por nome de programa e área de conhecimento). Elaboração própria."
  ) +
  theme_artigo() + theme(legend.position = "bottom")
ggsave(file.path(dir_figuras, "fig09_subareas_temporal.png"), p9, width = 7.5, height = 5.8, dpi = 300)
ggsave(file.path(dir_figuras, "fig09_subareas_temporal.pdf"), p9, width = 7.5, height = 5.8)

# -----------------------------------------------------------------------------
# 5. Valores inline para o manuscrito
# -----------------------------------------------------------------------------
share_2024 <- serie_subarea %>% filter(ano == 2024) %>% mutate(pct = round(100 * titulos / sum(titulos), 1))
valores <- list(
  titulos_2024_sub = setNames(share_2024$titulos, share_2024$subarea),
  pct_2024_sub = setNames(share_2024$pct, share_2024$subarea),
  pct_cp_2024 = share_2024$pct[share_2024$subarea == "CP"],
  pct_ri_2024 = share_2024$pct[share_2024$subarea == "RI"],
  pct_pp_2024 = share_2024$pct[share_2024$subarea == "PP"],
  pct_def_2024 = share_2024$pct[share_2024$subarea == "DEFESA"],
  pct_outros_2024 = share_2024$pct[share_2024$subarea == "OUTROS"],
  n_programas_2024_sub = setNames(tab_programas_2024$n_programas_2024, tab_programas_2024$subarea),
  n_programas_2024_cp = tab_programas_2024$n_programas_2024[tab_programas_2024$subarea == "CP"],
  n_programas_2024_ri = tab_programas_2024$n_programas_2024[tab_programas_2024$subarea == "RI"],
  n_programas_2024_pp = tab_programas_2024$n_programas_2024[tab_programas_2024$subarea == "PP"],
  n_programas_2024_def = tab_programas_2024$n_programas_2024[tab_programas_2024$subarea == "DEFESA"],
  primeiro_ano_def = min(serie_subarea$ano[serie_subarea$subarea == "DEFESA" & serie_subarea$titulos > 0]),
  total_def = sum(serie_subarea$titulos[serie_subarea$subarea == "DEFESA"])
)
saveRDS(valores, file.path(dir_processed, "valores_inline_subareas.rds"))

cat("\n=== VALORES SUBÁREAS ===\n")
cat("2024: CP", valores$pct_cp_2024, "% | RI", valores$pct_ri_2024, "% | PP", valores$pct_pp_2024,
    "% | DEFESA", valores$pct_def_2024, "% | OUTROS", valores$pct_outros_2024, "%\n")
cat("Programas 2024: CP", valores$n_programas_2024_cp, "| RI", valores$n_programas_2024_ri,
    "| PP", valores$n_programas_2024_pp, "| DEFESA", valores$n_programas_2024_def, "\n")
cat("Primeiro ano com títulos de defesa:", valores$primeiro_ano_def, "| total:", valores$total_def, "\n")
cat("\n>>> CLASSIFICAÇÃO DE SUBÁREAS CONCLUÍDA!")
