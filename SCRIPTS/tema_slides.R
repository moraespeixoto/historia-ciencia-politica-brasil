# ============================================================================
# tema_slides.R — casa de estilo para figuras de apresentação (revealjs)
# ----------------------------------------------------------------------------
# Irmão de tema_artigo.R, mas calibrado para tela/projeção, não para coluna de
# PDF acadêmico: tipografia maior, grade mais grossa, sem legenda em caixa
# (preferir rotulagem direta), caption suprimido por padrão (a fonte vai no
# rodapé do slide). Não altera tema_artigo.R — o paper continua intocado.
#
# Uso no .qmd de slides (chunk de setup):
#     source("SCRIPTS/tema_slides.R")
#     theme_set(theme_slides())
# ============================================================================

library(ggplot2)
library(scales)

theme_slides <- function(base_size = 16, base_family = "") {
  meia_tinta  <- "grey35"
  linha_grade <- "grey85"

  theme_minimal(base_size = base_size, base_family = base_family) +
    theme(
      plot.background  = element_rect(fill = "#FCFCFA", colour = NA),
      panel.background = element_rect(fill = "#FCFCFA", colour = NA),
      panel.border     = element_blank(),

      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_line(colour = linha_grade, linewidth = 0.45),

      axis.line   = element_line(colour = "grey40", linewidth = 0.4),
      axis.ticks  = element_line(colour = "grey40", linewidth = 0.4),
      axis.title  = element_text(colour = "grey20"),
      axis.text   = element_text(colour = meia_tinta, size = rel(0.95)),
      axis.title.x = element_text(margin = margin(t = 8)),
      axis.title.y = element_text(margin = margin(r = 8)),

      strip.background = element_rect(fill = "#FCFCFA", colour = NA),
      strip.text      = element_text(face = "bold", colour = "grey15",
                                     hjust = 0, size = rel(1.0),
                                     margin = margin(b = 6, t = 2)),
      panel.spacing   = unit(1.4, "lines"),

      plot.title.position = "plot",
      plot.title    = element_text(face = "bold", size = rel(1.3),
                                   colour = "grey10", margin = margin(b = 5)),
      plot.subtitle = element_text(colour = meia_tinta, size = rel(1.05),
                                   margin = margin(b = 14)),
      # Caption suprimido por padrão: a fonte vai no rodapé revealjs, não na
      # figura (em slide, texto pequeno dentro da figura fica ilegível).
      plot.caption  = element_blank(),

      # Rotulagem direta é a norma em slide; legenda só quando indispensável.
      legend.position   = "none",
      legend.title      = element_text(colour = "grey20", size = rel(0.95)),
      legend.text       = element_text(colour = meia_tinta, size = rel(0.95)),
      legend.key        = element_blank(),
      legend.background = element_blank(),

      plot.margin = margin(14, 18, 10, 14)
    )
}

# Paleta semântica travada: mesma cor para "Ciência Política / RI" em todos
# os slides; demais áreas em cinza, exceto quando a comparação é o ponto.
cor_cp_ri     <- "#0072B2"   # azul Okabe-Ito (mesmo tom do paper)
cor_destaque2 <- "#E69F00"   # laranja Okabe-Ito, para um segundo destaque
cor_irmãs     <- "grey72"

cores_areas_slides <- c(
  "Ciência Política / RI"      = cor_cp_ri,
  "História"                   = cor_irmãs,
  "Economia"                   = cor_irmãs,
  "Sociologia"                 = cor_irmãs,
  "Geografia"                  = cor_irmãs,
  "Antropologia / Arqueologia" = cor_irmãs
)

# Sequencial para composição/fluxo dentro da Área 39 (nunca "Blues" claro
# demais para projetor): usa viridis "mako" por padrão.
scale_fill_slides_seq <- function(...) scale_fill_viridis_c(option = "mako", ...)
scale_fill_slides_seq_d <- function(...) scale_fill_viridis_d(option = "mako", ...)

# Variante para mapas: sem eixos/grade (coordenadas não são dado).
theme_slides_mapa <- function(base_size = 16, base_family = "") {
  theme_slides(base_size, base_family) +
    theme(
      axis.line = element_blank(), axis.ticks = element_blank(),
      axis.text = element_blank(), axis.title = element_blank(),
      panel.grid = element_blank()
    )
}

num_ptbr_slide <- function(accuracy = NULL, ...) {
  scales::label_number(accuracy = accuracy, decimal.mark = ",", big.mark = ".", ...)
}
pct_ptbr_slide <- function(accuracy = 1, ...) {
  scales::label_percent(accuracy = accuracy, decimal.mark = ",", big.mark = ".", suffix = "%", ...)
}

salva_fig_slide <- function(plot, arquivo, largura = 8, altura = 4.5, dpi = 200, ...) {
  extras <- list(...)
  if (grepl("\\.pdf$", arquivo, ignore.case = TRUE) && is.null(extras$device)) {
    extras$device <- grDevices::cairo_pdf
  }
  do.call(ggplot2::ggsave, c(list(arquivo, plot = plot, width = largura,
                                  height = altura, units = "in", dpi = dpi,
                                  bg = "#FCFCFA"), extras))
}
