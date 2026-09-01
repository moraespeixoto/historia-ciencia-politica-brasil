#!/usr/bin/env Rscript
# 19_linha_tempo_tres_idades.R — Versão de paper (theme_artigo) da linha do
# tempo "As Três Idades da Ciência Política Brasileira" (Referencial
# Teórico, §2.1). Mesmos marcos institucionais da versão de slide gerada em
# 17_figuras_slides.R (theme_slides), redimensionada para largura de coluna
# de PDF acadêmico. Ver ali os comentários de proveniência de cada marco
# (Forjaz 1997; Lamounier 1989; página oficial do PPGCP-UFMG; 60 anos da
# Revista DADOS, dados.iesp.uerj.br).
source(here::here("SCRIPTS", "00_setup.R"))
suppressPackageStartupMessages(library(ggrepel))
theme_set(theme_artigo())

dir_figuras <- here::here("FIGURAS")

eras <- tribble(
  ~era, ~inicio, ~fim, ~cor,
  "Criação e Filiação",                     1966, 1979, "#0072B2",
  "Expansão Institucional",                 1980, 1999, "#E69F00",
  "Profissionalização e\nInternacionalização", 2000, 2025, "#009E73"
)
marcos <- tribble(
  ~ano, ~rotulo,                          ~lado,
  1966, "UFMG",                           1,
  1966, "DADOS\n(revista)",                -1,
  1969, "IUPERJ",                         -1,
  1971, "USP",                            1,
  1973, "UFRGS",                          -1,
  1977, "ANPOCS",                         1,
  1984, "UnB\n(mestrado CP/RI)",          -1,
  1996, "ABCP",                           1,
  2007, "BPSR\n(internacionalização)",    -1
)

p20 <- ggplot() +
  geom_rect(data = eras, aes(xmin = inicio, xmax = fim, ymin = -1, ymax = 1, fill = cor),
            alpha = 0.13, colour = NA) +
  geom_hline(yintercept = 0, colour = "grey55", linewidth = 0.4) +
  geom_point(data = marcos, aes(x = ano, y = 0), size = 1.8, colour = "grey15") +
  ggrepel::geom_text_repel(data = marcos %>% filter(lado > 0),
                            aes(x = ano, y = 0, label = paste0(ano, "\n", rotulo)),
                            size = 2.9, fontface = "bold", colour = "grey15", lineheight = 0.9,
                            direction = "x", nudge_y = 0.45, force = 4, box.padding = 0.2,
                            min.segment.length = 0, segment.size = 0.3, segment.colour = "grey50") +
  ggrepel::geom_text_repel(data = marcos %>% filter(lado < 0),
                            aes(x = ano, y = 0, label = paste0(ano, "\n", rotulo)),
                            size = 2.9, fontface = "bold", colour = "grey15", lineheight = 0.9,
                            direction = "x", nudge_y = -0.45, force = 4, box.padding = 0.2,
                            min.segment.length = 0, segment.size = 0.3, segment.colour = "grey50") +
  geom_text(data = eras, aes(x = (inicio + fim) / 2, y = 0.92, label = era, colour = cor),
            size = 3.1, fontface = "bold") +
  scale_fill_identity() + scale_colour_identity() +
  scale_x_continuous(breaks = seq(1965, 2025, 10), limits = c(1964, 2027)) +
  scale_y_continuous(limits = c(-1, 1.05)) +
  labs(title = "As Três Idades da Ciência Política Brasileira",
       subtitle = "Marcos institucionais citados no Referencial Teórico, 1966–2025",
       x = NULL, y = NULL,
       caption = "Fonte: Forjaz (1997); Lamounier (1989); PPGCP-UFMG; IESP-UERJ. Elaboração própria.") +
  theme_artigo(grid = "none") +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(), axis.line.y = element_blank())

ggsave(file.path(dir_figuras, "fig20_tres_idades.png"), p20, width = 8.5, height = 4.4, dpi = 300)
ggsave(file.path(dir_figuras, "fig20_tres_idades.pdf"), p20, width = 8.5, height = 4.4)

cat(">>> fig20_tres_idades gerada em", dir_figuras, "\n")
