#!/usr/bin/env Rscript
# ==============================================================================
# 15_associacoes_cientificas.R — Associações científicas: dados e figuras
# ==============================================================================
# Consolida as tabelas por associação (TABELAS/tabela_<sigla>_encontros.csv) e
# gera as figuras comparativas. Dados coletados e verificados manualmente com
# URL de fonte (ver AUDITORIA.md e anpege_dados/).
# ==============================================================================

source(here::here("SCRIPTS", "00_setup.R"))

dir_tabelas <- here::here("TABELAS")
dir_figuras <- here::here("FIGURAS")
dir_processed <- here::here("DADOS", "processed")
dir.create(dir_tabelas, recursive = TRUE, showWarnings = FALSE)
dir.create(dir_figuras, recursive = TRUE, showWarnings = FALSE)

# -----------------------------------------------------------------------------
# 1. Consolida tabelas por associação
# -----------------------------------------------------------------------------
arquivos <- c("anpege", "anpec", "anpocs", "abcp", "anpuh", "sbs", "aba")
lista <- list()
for (a in arquivos) {
  f <- file.path(dir_tabelas, paste0("tabela_", a, "_encontros.csv"))
  if (file.exists(f)) {
    lista[[a]] <- read_csv(f, show_col_types = FALSE)
  }
}
if (length(lista) == 0) stop("Nenhuma tabela de associação encontrada.")
eventos <- bind_rows(lista) %>%
  mutate(across(c(participantes, trabalhos, gt), ~ as.numeric(.)))

if ("trabalhos_aprovados" %in% names(eventos)) {
  eventos <- eventos %>% mutate(trabalhos_aprovados = as.numeric(trabalhos_aprovados))
} else {
  eventos$trabalhos_aprovados <- NA_real_
}
eventos <- eventos %>% select(associacao, area, ano, edicao, local, participantes,
                              trabalhos, trabalhos_aprovados, gt, fonte)

# -----------------------------------------------------------------------------
# 1b. Comparabilidade das métricas (F13)
# -----------------------------------------------------------------------------
# As associações publicam indicadores incomensuráveis: inscritos, credenciados,
# presentes, propostas recebidas, submetidos, aprovados, publicados, e ainda
# estimativas pré-evento. Comparar "1.722 inscritos da ABCP" com "1.193
# credenciados da ANPOCS" induz a erro. `metrica_comparavel` marca TRUE apenas
# as linhas em que há um número de TRABALHOS APROVADOS de fonte oficial da
# própria associação (relatório de gestão, anais ou site institucional) — a
# única base em que uma comparação entre áreas se sustenta.
fonte_oficial_re <- "(?i)relat[oó]rio|anais|site (oficial|institucional)|associa|abcp|anpocs|anpec|anpege|anpuh|sbs|aba\\b"
fonte_fraca_re <- "(?i)blog|imprensa|estimativa|not[ií]cia|jornal|previsto"
eventos <- eventos %>%
  mutate(
    fonte_oficial = grepl(fonte_oficial_re, replace_na(fonte, "")) &
      !grepl(fonte_fraca_re, replace_na(fonte, "")),
    metrica_comparavel = !is.na(trabalhos_aprovados) & fonte_oficial
  )

write_csv(eventos, file.path(dir_tabelas, "tabela_associacoes_consolidada.csv"))
saveRDS(eventos, file.path(dir_processed, "associacoes_consolidado.rds"))

# -----------------------------------------------------------------------------
# 1c. Métrica normalizada: trabalhos aprovados por programa ativo da área
# -----------------------------------------------------------------------------
# Normalizar pelo tamanho do sistema de pós-graduação da área elimina o efeito
# de escala que faz a comparação bruta de encontros ser trivialmente vencida
# pelas áreas maiores. Só é calculável na janela 2013-2024 (Sucupira).
mapa_assoc_area <- c(ABCP = "Ciência Política / RI", ANPOCS = NA_character_,
                     SBS = "Sociologia", ABA = "Antropologia / Arqueologia",
                     ANPUH = "História", ANPEC = "Economia", ANPEGE = "Geografia")
suc_path <- file.path(dir_tabelas, "tabela_comparacao_programas_sucupira.csv")
if (file.exists(suc_path)) {
  suc <- read_csv(suc_path, show_col_types = FALSE) %>%
    select(ano, area_nome, programas_ativos)
  trabalhos_norm <- eventos %>%
    mutate(area_avaliacao = unname(mapa_assoc_area[associacao])) %>%
    filter(!is.na(area_avaliacao), !is.na(trabalhos_aprovados), ano >= 2013, ano <= 2024) %>%
    left_join(suc, by = c("ano", "area_avaliacao" = "area_nome")) %>%
    mutate(trabalhos_por_programa = trabalhos_aprovados / programas_ativos) %>%
    select(associacao, area_avaliacao, ano, trabalhos_aprovados, programas_ativos,
           trabalhos_por_programa, metrica_comparavel, fonte)
  write_csv(trabalhos_norm, file.path(dir_tabelas, "tabela_associacoes_trabalhos_por_programa.csv"))
  saveRDS(trabalhos_norm, file.path(dir_processed, "associacoes_trabalhos_por_programa.rds"))
  cat(">>> Trabalhos por programa ativo (linhas calculáveis):", nrow(trabalhos_norm), "\n")
}

# -----------------------------------------------------------------------------
# 2. Figura A: ANPEGE — trabalhos por edição
# -----------------------------------------------------------------------------
p_a <- eventos %>%
  filter(associacao == "ANPEGE", !is.na(trabalhos)) %>%
  ggplot(aes(x = ano, y = trabalhos)) +
  geom_col(fill = "#4C78A8", alpha = 0.9, width = 0.6) +
  geom_text(aes(label = format(trabalhos, big.mark = ".")), vjust = -0.4, size = 2.6) +
  scale_x_continuous(breaks = seq(1995, 2025, by = 2)) +
  scale_y_continuous(name = "Trabalhos aceitos", breaks = scales::pretty_breaks(6)) +
  labs(title = "Encontros Nacionais da ANPEGE (Geografia)",
       subtitle = "Trabalhos aceitos/publicados por edição, 1995–2023",
       x = "Ano",
       caption = "Fonte: Teixeira (2019, Rev. Tamoios) e Barros (2024). Elaboração própria.") +
  theme_artigo()
ggsave(file.path(dir_figuras, "fig18a_anpege_trabalhos.png"), p_a, width = 7.5, height = 4.6, dpi = 300)

# -----------------------------------------------------------------------------
# 3. Figura B: ANPEC — submetidos vs aprovados
# -----------------------------------------------------------------------------
p_b <- eventos %>%
  filter(associacao == "ANPEC", !is.na(trabalhos)) %>%
  mutate(aprovados = coalesce(trabalhos_aprovados, trabalhos)) %>%
  pivot_longer(c(trabalhos, aprovados), names_to = "indicador", values_to = "n") %>%
  mutate(indicador = if_else(indicador == "trabalhos", "Submetidos", "Aprovados")) %>%
  ggplot(aes(x = ano, y = n, fill = indicador)) +
  geom_col(position = "dodge", width = 0.7, alpha = 0.9) +
  scale_fill_manual(values = c("Submetidos" = "#4C78A8", "Aprovados" = "#E45756"), name = NULL) +
  scale_x_continuous(breaks = seq(2007, 2017, by = 1)) +
  scale_y_continuous(name = "Artigos", breaks = scales::pretty_breaks(6)) +
  labs(title = "Encontro Nacional de Economia (ANPEC)",
       subtitle = "Artigos submetidos e aprovados, 2007–2017 (taxa média de aprovação ≈ 30%)",
       x = "Ano",
       caption = "Fonte: Rocha, Pereda & Matsunaga (2021), Cuadernos de Economía. Elaboração própria.") +
  theme_artigo() + theme(legend.position = "top")
ggsave(file.path(dir_figuras, "fig18b_anpec_submissoes.png"), p_b, width = 7.5, height = 4.6, dpi = 300)

# -----------------------------------------------------------------------------
# 4. Figura principal: fluxo de trabalhos por associação (facetas)
# -----------------------------------------------------------------------------
d_trab <- eventos %>%
  filter(associacao %in% c("ANPOCS", "ANPEGE", "ANPEC", "ANPUH")) %>%
  mutate(
    serie = case_when(
      associacao == "ANPOCS" ~ "ANPOCS (propostas)",
      associacao == "ANPEGE" ~ "ANPEGE (aceitos)",
      associacao == "ANPEC"  ~ "ANPEC (submetidos)",
      associacao == "ANPUH"  ~ "ANPUH (inscritos)"
    ),
    indicador = case_when(
      associacao == "ANPEC" ~ "trabalhos",
      TRUE ~ "trabalhos"
    )
  ) %>%
  filter(!is.na(trabalhos))

d_aprov <- eventos %>%
  filter(associacao %in% c("ANPOCS", "ANPEC"), !is.na(trabalhos_aprovados)) %>%
  mutate(serie = if_else(associacao == "ANPOCS", "ANPOCS (aprovadas)", "ANPEC (aprovados)"))

p_main <- bind_rows(
  d_trab %>% select(ano, serie, n = trabalhos),
  d_aprov %>% select(ano, serie, n = trabalhos_aprovados)
) %>%
  ggplot(aes(x = ano, y = n, colour = serie)) +
  geom_line(linewidth = 1) +
  geom_point(size = 1.8) +
  scale_colour_manual(values = c(
    "ANPOCS (propostas)" = "#4C78A8", "ANPOCS (aprovadas)" = "#BAB0AC",
    "ANPEGE (aceitos)" = "#54A24B",
    "ANPEC (submetidos)" = "#F58518", "ANPEC (aprovados)" = "#E45756",
    "ANPUH (inscritos)" = "#1F5FA8"
  )) +
  facet_wrap(~ serie, ncol = 2, scales = "free_y") +
  scale_x_continuous(limits = c(1990, NA), breaks = seq(1990, 2025, by = 5)) +
  scale_y_continuous(name = "Trabalhos", breaks = scales::pretty_breaks(5),
                     labels = scales::label_number(big.mark = ".", decimal.mark = ",")) +
  labs(
    title = "Fluxo de Trabalhos nos Encontros das Associações Científicas",
    subtitle = "Séries com dados publicados: propostas/aceitos (ANPOCS), aceitos (ANPEGE), submetidos/aprovados (ANPEC) e inscritos (ANPUH)",
    x = "Ano", colour = "Série",
    caption = "Fontes: relatórios e sites oficiais das associações (ver tabela consolidada). Elaboração própria."
  ) +
  theme_artigo() + theme(legend.position = "bottom", strip.text = element_text(size = 9, face = "bold"))
ggsave(file.path(dir_figuras, "fig18_associacoes_trabalhos.png"), p_main, width = 9.5, height = 6, dpi = 300)
ggsave(file.path(dir_figuras, "fig18_associacoes_trabalhos.pdf"), p_main, width = 9.5, height = 6)

# -----------------------------------------------------------------------------
# 5. Figura C: participantes da edição mais recente por associação
#    (apenas dados realizados até 2024; anos de 2025 são estimativas pré-evento)
# -----------------------------------------------------------------------------
recentes <- eventos %>%
  filter(!is.na(participantes), ano <= 2024) %>%
  group_by(associacao, area) %>%
  slice_max(ano, n = 1, with_ties = FALSE) %>%
  ungroup()


if (nrow(recentes) > 1) {
  p_c <- recentes %>%
    mutate(rotulo = paste0(associacao, " (", ano, ")")) %>%
    ggplot(aes(x = reorder(rotulo, participantes), y = participantes)) +
    geom_col(fill = "#1F5FA8", alpha = 0.9, width = 0.65) +
    geom_text(aes(label = format(participantes, big.mark = ".")), hjust = -0.1, size = 3) +
    coord_flip() +
    scale_y_continuous(name = "Participantes (edição mais recente com dado)", limits = c(0, NA),
                       breaks = scales::pretty_breaks(6),
                       expand = expansion(mult = c(0.02, 0.18))) +
    labs(title = "Participantes na edição mais recente, por associação",
         subtitle = "Dado disponível; métrica varia entre inscritos e credenciados",
         x = NULL,
         caption = "Fontes: ver tabela consolidada. Elaboração própria.") +
    theme_artigo()
  ggsave(file.path(dir_figuras, "fig18c_participantes_recentes.png"), p_c, width = 7.5, height = 4.2, dpi = 300)
}

cat(">>> ASSOCIAÇÕES CONSOLIDADAS: ", nrow(eventos), " linhas | associações: ",
    paste(unique(eventos$associacao), collapse = ", "), "\n")
if (nrow(recentes) > 0) {
  cat(">>> Participantes recentes:\n")
  print(recentes %>% select(associacao, ano, participantes))
}
