#!/usr/bin/env Rscript
# 19_linha_tempo_tres_idades.R — Versão de paper (theme_artigo) da linha do
# tempo "As Três Idades da Ciência Política Brasileira" (Referencial
# Teórico, §2.1). Mesmos marcos institucionais da versão de slide gerada em
# 17_figuras_slides.R (theme_slides), redimensionada para largura de coluna
# de PDF acadêmico. Ver ali os comentários de proveniência de cada marco
# (Forjaz 1997; Lamounier 1989; página oficial do PPGCP-UFMG; 60 anos da
# Revista DADOS, dados.iesp.uerj.br).
source(here::here("SCRIPTS", "00_setup.R"))
theme_set(theme_artigo())

dir_figuras <- here::here("FIGURAS")

eras <- tribble(
  ~era, ~inicio, ~fim, ~cor,
  "Criação e Filiação",                     1966, 1979, "#0072B2",
  "Expansão Institucional",                 1980, 1999, "#E69F00",
  "Profissionalização e\nInternacionalização", 2000, 2025, "#009E73"
)
# Alturas escalonadas (tier 1 = perto do eixo, tier 2 = longe) em vez de
# deslocamento horizontal: garante linhas de chamada retas (verticais),
# alternando a distância dentro de cada lado para marcos próximos no tempo
# não colidirem. Mesmo esquema da versão de slide (17_figuras_slides.R).
marcos <- tribble(
  ~ano, ~rotulo,                          ~lado, ~tier,
  1966, "UFMG",                           1,     1,
  1966, "DADOS\n(revista)",                -1,    1,
  1969, "IUPERJ",                         -1,    2,
  1971, "USP",                            1,     2,
  1973, "UFRGS",                          -1,    1,
  1977, "ANPOCS",                         1,     1,
  1984, "UnB\n(mestrado CP/RI)",          -1,    2,
  1996, "ABCP",                           1,     2,
  2007, "BPSR\n(internacionalização)",    -1,    1
) %>% mutate(dist = if_else(tier == 1, 0.42, 0.85), y_lab = lado * dist)

p20 <- ggplot() +
  geom_rect(data = eras, aes(xmin = inicio, xmax = fim, ymin = -1.35, ymax = 1.35, fill = cor),
            alpha = 0.13, colour = NA) +
  geom_hline(yintercept = 0, colour = "grey55", linewidth = 0.4) +
  geom_segment(data = marcos, aes(x = ano, xend = ano, y = 0, yend = y_lab),
               colour = "grey60", linewidth = 0.3) +
  geom_point(data = marcos, aes(x = ano, y = 0), size = 1.8, colour = "grey15") +
  geom_text(data = marcos, aes(x = ano, y = y_lab, label = paste0(ano, "\n", rotulo),
                                vjust = ifelse(lado > 0, 0, 1)),
            size = 2.9, fontface = "bold", colour = "grey15", lineheight = 0.9) +
  geom_text(data = eras, aes(x = (inicio + fim) / 2, y = 1.25, label = era, colour = cor),
            size = 3.1, fontface = "bold") +
  scale_fill_identity() + scale_colour_identity() +
  scale_x_continuous(breaks = seq(1965, 2025, 10), limits = c(1964, 2027)) +
  scale_y_continuous(limits = c(-1.4, 1.4)) +
  labs(title = "As Três Idades da Ciência Política Brasileira",
       subtitle = "Marcos institucionais citados no Referencial Teórico, 1966–2025",
       x = NULL, y = NULL,
       caption = "Fonte: Forjaz (1997); Lamounier (1989); PPGCP-UFMG; IESP-UERJ. Elaboração própria.") +
  theme_artigo(grid = "none") +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(), axis.line.y = element_blank())

ggsave(file.path(dir_figuras, "fig20_tres_idades.png"), p20, width = 8.5, height = 4.9, dpi = 300)
ggsave(file.path(dir_figuras, "fig20_tres_idades.pdf"), p20, width = 8.5, height = 4.9)

cat(">>> fig20_tres_idades gerada em", dir_figuras, "\n")
