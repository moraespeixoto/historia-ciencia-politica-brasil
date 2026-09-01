#!/usr/bin/env Rscript
# 17_figuras_slides.R — Figuras redesenhadas e inéditas para a apresentação
# (presentacao.qmd). Usa theme_slides() em vez de theme_artigo(): tipografia
# maior, rotulagem direta, sem legenda em caixa, fundo casado com o slide.
# Nunca sobrescreve as figuras do paper (FIGURAS/); grava em FIGURAS/slides/.
source(here::here("SCRIPTS", "00_setup.R"))
source(here::here("SCRIPTS", "tema_slides.R"))
suppressPackageStartupMessages(library(sf))
theme_set(theme_slides())

dir_processed <- here::here("DADOS", "processed")
dir_tabelas   <- here::here("TABELAS")
dir_slides    <- here::here("FIGURAS", "slides")
dir.create(dir_slides, recursive = TRUE, showWarnings = FALSE)

# -----------------------------------------------------------------------------
# 1. Títulos por grau acadêmico (redesenho da fig01) — rotulagem direta,
#    anotação da queda 2019-2020 e do pico 2024
# -----------------------------------------------------------------------------
grau_ano <- readRDS(file.path(dir_processed, "capes_titulos_por_grau_ano.rds")) %>%
  filter(grau != "Grau não informado")
ultimo <- grau_ano %>% filter(ano == max(ano))

p1 <- ggplot(grau_ano, aes(ano, titulos, colour = grau)) +
  geom_line(linewidth = 1.4) +
  geom_point(data = ultimo, size = 3.2) +
  ggrepel::geom_text_repel(data = ultimo, aes(label = paste0(grau, ": ", num_ptbr_slide()(titulos))),
                            hjust = 0, nudge_x = 1.5, direction = "y", segment.size = 0.3,
                            size = 5, fontface = "bold", show.legend = FALSE) +
  annotate("curve", x = 2013.5, xend = 2019.6, y = 900, yend = 940,
           curvature = -0.25, colour = "grey40", linewidth = 0.4,
           arrow = arrow(length = unit(0.018, "npc"))) +
  annotate("text", x = 2013.3, y = 900, label = "queda 2019→2020 (pandemia)",
           size = 4.2, colour = "grey35", hjust = 1) +
  scale_colour_manual(values = c("Mestrado" = cor_cp_ri, "Doutorado" = cor_destaque2)) +
  scale_x_continuous(breaks = seq(1990, 2024, 5), limits = c(1987, 2034), expand = expansion(mult = c(0.02, 0))) +
  scale_y_continuous(labels = num_ptbr_slide(), expand = expansion(mult = c(0.03, 0.08))) +
  labs(subtitle = "Títulos de mestrado e doutorado em Ciência Política/RI, 1987–2024",
       x = NULL, y = "Títulos concedidos")
salva_fig_slide(p1, file.path(dir_slides, "slide_01_titulos_grau.png"), largura = 9, altura = 5)
salva_fig_slide(p1, file.path(dir_slides, "slide_01_titulos_grau.pdf"), largura = 9, altura = 5)

# -----------------------------------------------------------------------------
# 2. Programas por área em 2024 — inédita: barras horizontais ordenadas
# -----------------------------------------------------------------------------
comp_ind <- read_csv(file.path(dir_tabelas, "tabela_comparacao_painel_integrado.csv"), show_col_types = FALSE)
comp_2024 <- comp_ind %>% filter(ano == max(ano, na.rm = TRUE)) %>%
  mutate(area_nome = forcats::fct_reorder(area_nome, programas_ativos))

p2 <- ggplot(comp_2024, aes(programas_ativos, area_nome, fill = area_nome)) +
  geom_col(width = 0.68) +
  geom_text(aes(label = num_ptbr_slide()(programas_ativos)), hjust = -0.25, size = 5.5, fontface = "bold", colour = "grey15") +
  scale_fill_manual(values = cores_areas_slides) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.14))) +
  labs(subtitle = "Programas ativos na Plataforma Sucupira por área de avaliação, 2024",
       x = NULL, y = NULL)
salva_fig_slide(p2, file.path(dir_slides, "slide_05_programas_area.png"), largura = 9, altura = 5)
salva_fig_slide(p2, file.path(dir_slides, "slide_05_programas_area.pdf"), largura = 9, altura = 5)

# -----------------------------------------------------------------------------
# 3. Comparação de títulos entre áreas (redesenho da fig11, dados corrigidos)
# -----------------------------------------------------------------------------
titulos_comp <- readRDS(file.path(dir_processed, "tabela_comparacao_titulos_capes.rds")) %>%
  filter(area_nome != "Não identificado", nivel != "Não informado") %>%
  count(ano, area_nome, wt = titulos, name = "titulos")
ultimo_comp <- titulos_comp %>% filter(ano == max(ano))

titulos_comp <- titulos_comp %>%
  mutate(destaque = area_nome == "Ciência Política / RI")
ultimo_comp <- ultimo_comp %>% mutate(destaque = area_nome == "Ciência Política / RI")

p3 <- ggplot(titulos_comp, aes(ano, titulos, colour = area_nome, linewidth = destaque)) +
  geom_line() +
  ggrepel::geom_text_repel(data = ultimo_comp, aes(label = area_nome), hjust = 0, nudge_x = 1.3,
                            direction = "y", segment.size = 0.3, size = 4.6, fontface = "bold",
                            show.legend = FALSE) +
  scale_colour_manual(values = cores_areas_slides) +
  scale_linewidth_manual(values = c(`TRUE` = 1.7, `FALSE` = 0.9), guide = "none") +
  scale_x_continuous(breaks = seq(1990, 2020, 10), limits = c(1987, 2034), expand = expansion(mult = c(0.01, 0))) +
  scale_y_continuous(labels = num_ptbr_slide()) +
  labs(subtitle = "Títulos de mestrado e doutorado por área de avaliação, 1987–2024",
       x = NULL, y = "Títulos/ano")
salva_fig_slide(p3, file.path(dir_slides, "slide_06_comparacao_titulos.png"), largura = 9.5, altura = 5.2)
salva_fig_slide(p3, file.path(dir_slides, "slide_06_comparacao_titulos.pdf"), largura = 9.5, altura = 5.2)

# -----------------------------------------------------------------------------
# 4. Escala x intensidade — inédita: dispersão programas x títulos/programa 2024
# -----------------------------------------------------------------------------
disp <- comp_2024 %>% mutate(titulos_por_programa = titulos / programas_ativos)
p4 <- ggplot(disp, aes(programas_ativos, titulos_por_programa, colour = area_nome)) +
  geom_point(size = 5.5) +
  ggrepel::geom_text_repel(aes(label = area_nome), size = 4.8, fontface = "bold",
                            show.legend = FALSE, seed = 1, box.padding = 0.6) +
  scale_colour_manual(values = cores_areas_slides) +
  scale_x_continuous(labels = num_ptbr_slide(), expand = expansion(mult = 0.12)) +
  scale_y_continuous(labels = num_ptbr_slide(accuracy = 0.1), expand = expansion(mult = 0.12)) +
  labs(subtitle = "Programas ativos (eixo x) versus títulos por programa (eixo y), 2024",
       x = "Programas ativos (Sucupira, 2024)", y = "Títulos por programa (CAPES, 2024)")
salva_fig_slide(p4, file.path(dir_slides, "slide_07_escala_intensidade.png"), largura = 9, altura = 5.5)
salva_fig_slide(p4, file.path(dir_slides, "slide_07_escala_intensidade.pdf"), largura = 9, altura = 5.5)

# -----------------------------------------------------------------------------
# 5. Composição da Área 39 por subárea (redesenho da fig09) — achado central
# -----------------------------------------------------------------------------
sub_serie <- readRDS(file.path(dir_processed, "tabela_titulos_subareas.rds")) %>%
  filter(ano >= 1995) %>%
  group_by(ano) %>% mutate(pct = titulos / sum(titulos)) %>% ungroup() %>%
  mutate(subarea_nome = recode(subarea,
    CP = "Ciência Política", RI = "Relações Internacionais",
    PP = "Políticas Públicas", DEFESA = "Defesa e Segurança", OUTROS = "Outros"))
ultimo_sub <- sub_serie %>% filter(ano == max(ano))
cores_sub <- c("Ciência Política" = cor_cp_ri, "Relações Internacionais" = "#56B4E9",
               "Políticas Públicas" = cor_destaque2, "Defesa e Segurança" = "#D55E00",
               "Outros" = "grey75")

p5 <- ggplot(sub_serie, aes(ano, pct, fill = subarea_nome)) +
  geom_area(position = "stack", alpha = 0.92) +
  scale_fill_manual(values = cores_sub, guide = "none") +
  scale_x_continuous(breaks = seq(1995, 2024, 5), expand = expansion(mult = c(0.01, 0.42))) +
  scale_y_continuous(labels = pct_ptbr_slide(accuracy = 1), expand = expansion(mult = c(0, 0.02))) +
  labs(subtitle = "Composição percentual dos títulos por subárea, 1995–2024",
       x = NULL, y = "% dos títulos do ano")

# rótulos diretos no fim das faixas (posição = ponto médio acumulado de cada faixa em 2024)
lab_pos <- ultimo_sub %>%
  arrange(desc(subarea_nome)) %>%
  mutate(topo = cumsum(pct), base = topo - pct, y_lab = (topo + base) / 2)
p5 <- p5 + geom_text(data = lab_pos, aes(x = 2024.5, y = y_lab,
                     label = paste0(subarea_nome, ": ", scales::percent(pct, accuracy = 0.1, decimal.mark = ",")),
                     colour = subarea_nome), inherit.aes = FALSE, hjust = 0, size = 4.0, fontface = "bold") +
  scale_colour_manual(values = cores_sub, guide = "none") +
  coord_cartesian(clip = "off")
salva_fig_slide(p5, file.path(dir_slides, "slide_08_composicao_area39.png"), largura = 11.5, altura = 5.8)
salva_fig_slide(p5, file.path(dir_slides, "slide_08_composicao_area39.pdf"), largura = 11.5, altura = 5.8)

# -----------------------------------------------------------------------------
# 6. Evolução temática (slope chart 1980-1999 -> 2020-2024), substitui heatmap
# -----------------------------------------------------------------------------
rotulos_curtos <- c(
  "T1: Direitos Humanos, Gênero e Segurança Pública" = "Direitos, gênero e segurança",
  "T2: Relações Internacionais, Política Externa e Cooperação" = "Relações internacionais",
  "T3: Políticas Públicas, Saúde e Educação" = "Políticas públicas e saúde",
  "T4: Eleições, Partidos e Instituições Representativas" = "Eleições e partidos",
  "T5: Corpus em espanhol (artefato de idioma)" = "Corpus em espanhol (artefato)",
  "T6: Teoria Política e Pensamento Político" = "Teoria política",
  "T7: Corpus em inglês (BPSR)" = "Corpus em inglês (artefato)",
  "T8: Opinião Pública, Comunicação e Participação" = "Opinião pública e comunicação"
)
stm_dec <- readRDS(file.path(dir_processed, "stm_evolucao_decada.rds")) %>%
  filter(decada %in% c("1980-1999", "2020-2024")) %>%
  mutate(decada = factor(decada, levels = c("1980-1999", "2020-2024")),
         status = case_when(
           grepl("artefato de idioma|Corpus em inglês", topico) ~ "artefato",
           grepl("Teoria Política", topico) ~ "queda",
           TRUE ~ "outros"
         ),
         rotulo = unname(rotulos_curtos[topico]))
p6 <- ggplot(stm_dec, aes(decada, prevalencia, group = topico, colour = status)) +
  geom_line(linewidth = 1.1, alpha = 0.85) +
  geom_point(size = 3.2) +
  ggrepel::geom_text_repel(data = stm_dec %>% filter(decada == "2020-2024"),
                            aes(label = rotulo),
                            hjust = 0, nudge_x = 0.12, direction = "y", size = 4.6,
                            segment.size = 0.3, show.legend = FALSE, min.segment.length = 0,
                            box.padding = 0.3, force = 2) +
  scale_colour_manual(values = c(outros = cor_cp_ri, queda = "#D42B2B", artefato = "grey75"), guide = "none") +
  scale_y_continuous(labels = pct_ptbr_slide(accuracy = 1)) +
  scale_x_discrete(expand = expansion(mult = c(0.08, 0.85))) +
  labs(subtitle = "Prevalência média dos 8 tópicos do STM, 1980–1999 vs. 2020–2024\nVermelho = única categoria em queda · Cinza = artefato de idioma",
       x = NULL, y = "Prevalência média") +
  coord_cartesian(clip = "off")
salva_fig_slide(p6, file.path(dir_slides, "slide_10_evolucao_tematica.png"), largura = 12.5, altura = 6.2)
salva_fig_slide(p6, file.path(dir_slides, "slide_10_evolucao_tematica.pdf"), largura = 12.5, altura = 6.2)

# -----------------------------------------------------------------------------
# 7. Associações científicas — redesenho de fig18c, barras horizontais
# -----------------------------------------------------------------------------
assoc <- read_csv(file.path(dir_tabelas, "tabela_associacoes_consolidada.csv"), show_col_types = FALSE) %>%
  filter(!is.na(participantes)) %>%
  group_by(associacao) %>% slice_max(ano, n = 1, with_ties = FALSE) %>% ungroup() %>%
  mutate(rotulo = paste0(associacao, " (", ano, ")"),
         rotulo = forcats::fct_reorder(rotulo, participantes),
         destaque = associacao == "ABCP")

p7 <- ggplot(assoc, aes(participantes, rotulo, fill = destaque)) +
  geom_col(width = 0.66) +
  geom_text(aes(label = num_ptbr_slide()(participantes)), hjust = -0.2, size = 5.2, fontface = "bold", colour = "grey15") +
  scale_fill_manual(values = c(`TRUE` = cor_cp_ri, `FALSE` = "grey72"), guide = "none") +
  scale_x_continuous(labels = num_ptbr_slide(), expand = expansion(mult = c(0, 0.16))) +
  labs(subtitle = "Participantes no encontro mais recente com dado disponível, por associação",
       x = NULL, y = NULL)
salva_fig_slide(p7, file.path(dir_slides, "slide_11_associacoes.png"), largura = 9.5, altura = 5.5)
salva_fig_slide(p7, file.path(dir_slides, "slide_11_associacoes.pdf"), largura = 9.5, altura = 5.5)

# -----------------------------------------------------------------------------
# 8. Mapa de evolução espacial dos PPGs — redesenho para slide (theme_slides)
# -----------------------------------------------------------------------------
mapa_cache_path <- file.path(dir_processed, "mapa_evolucao_ppg_cache.rds")
if (file.exists(mapa_cache_path)) {
  mc <- readRDS(mapa_cache_path)
  p8 <- ggplot() +
    geom_sf(data = mc$ufs_sf, fill = "#E4E9EF", colour = "#FCFCFA", linewidth = 0.4) +
    geom_sf(data = mc$d_mapa_ord, aes(size = n_prog),
            fill = cor_cp_ri, colour = "white", shape = 21, stroke = 0.5, alpha = 0.94) +
    ggrepel::geom_label_repel(
      data = mc$labels_mapa, aes(x = x, y = y, label = mun),
      size = 4.6, colour = "#0B1E33", fontface = "bold",
      fill = "#FCFCFA", label.size = 0, label.padding = unit(0.22, "lines"),
      segment.size = 0.35, segment.colour = "grey45", min.segment.length = 0,
      seed = 20260828, max.overlaps = Inf, box.padding = 0.5, force = 6
    ) +
    scale_size_area(max_size = 16, breaks = c(1, 3, 6, 9, 11),
                    name = "Programas por município", guide = guide_legend(nrow = 1)) +
    facet_wrap(~ ano, ncol = 2, labeller = labeller(ano = setNames(mc$tot_ano$lab, mc$tot_ano$ano))) +
    coord_sf(crs = mc$crs_albers) +
    labs(x = NULL, y = NULL,
         subtitle = "Programas ativos por município, 2013 vs. 2024 (círculo proporcional ao número de programas)") +
    theme_slides_mapa() +
    theme(
      legend.position = "bottom",
      legend.key.size = unit(0.7, "cm"),
      strip.text = element_text(size = rel(1.15), face = "bold", colour = "#0B1E33"),
      panel.spacing = unit(1.6, "lines")
    )
  salva_fig_slide(p8, file.path(dir_slides, "slide_04_mapa_evolucao.png"), largura = 13, altura = 6.6)
  salva_fig_slide(p8, file.path(dir_slides, "slide_04_mapa_evolucao.pdf"), largura = 13, altura = 6.6)
} else {
  warning("mapa_evolucao_ppg_cache.rds não encontrado — rode 07_analise_geografica_redes.R antes.")
}

# -----------------------------------------------------------------------------
# 9. Linha do tempo — "As Três Idades da Ciência Política Brasileira"
#    (Referencial Teórico do artigo, §2.1). Marcos institucionais citados no
#    texto, sintetizados de Forjaz (1997) e Lamounier (1989); datas de
#    fundação dos programas conferidas no ciclo de auditoria de 29/08/2026
#    (ver AUDITORIA.md, seção de cronologia).
# -----------------------------------------------------------------------------
eras <- tribble(
  ~era, ~inicio, ~fim, ~cor,
  "Criação e Filiação",                     1966, 1979, "#0072B2",
  "Expansão Institucional",                 1980, 1999, "#E69F00",
  "Profissionalização e\nInternacionalização", 2000, 2025, "#009E73"
)
marcos <- tribble(
  ~ano, ~rotulo,                          ~lado,
  1967, "UFMG\n(1ª metade)",              1,
  1969, "IUPERJ",                         -1,
  1971, "USP",                            1,
  1973, "UFRGS",                          -1,
  1977, "ANPOCS",                         1,
  1984, "UnB\n(mestrado CP/RI)",          -1,
  1996, "ABCP",                           1,
  2007, "BPSR\n(internacionalização)",    -1
)

p9 <- ggplot() +
  geom_rect(data = eras, aes(xmin = inicio, xmax = fim, ymin = -1, ymax = 1, fill = cor),
            alpha = 0.13, colour = NA) +
  geom_hline(yintercept = 0, colour = "grey55", linewidth = 0.6) +
  geom_segment(data = marcos, aes(x = ano, xend = ano, y = 0, yend = lado * 0.35),
               colour = "grey45", linewidth = 0.4) +
  geom_point(data = marcos, aes(x = ano, y = 0), size = 3, colour = "#0B1E33") +
  geom_text(data = marcos, aes(x = ano, y = lado * 0.42, label = paste0(ano, "\n", rotulo),
                                vjust = ifelse(lado > 0, 0, 1)),
            size = 4.4, fontface = "bold", colour = "#0B1E33", lineheight = 0.9) +
  geom_text(data = eras, aes(x = (inicio + fim) / 2, y = 0.92, label = era, colour = cor),
            size = 5, fontface = "bold") +
  scale_fill_identity() + scale_colour_identity() +
  scale_x_continuous(breaks = seq(1965, 2025, 10), limits = c(1964, 2027)) +
  scale_y_continuous(limits = c(-1, 1.05)) +
  labs(x = NULL, y = NULL, subtitle = "Marcos institucionais citados no Referencial Teórico, 1966–2025") +
  theme_slides() +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(), axis.line.y = element_blank(),
        panel.grid.major.y = element_blank(), panel.grid.major.x = element_line(colour = "grey90", linewidth = 0.3))
salva_fig_slide(p9, file.path(dir_slides, "slide_03_tres_idades.png"), largura = 13, altura = 5.8)
salva_fig_slide(p9, file.path(dir_slides, "slide_03_tres_idades.pdf"), largura = 13, altura = 5.8)

cat(">>> figuras de slide geradas em", dir_slides, "\n")
