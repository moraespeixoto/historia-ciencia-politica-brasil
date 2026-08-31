# ============================================================================
# tema_artigo.R — casa de estilo de figuras para artigos quantitativos
# ----------------------------------------------------------------------------
# Objetivo: figuras limpas, instrutivas e com credibilidade acadêmica —
# SEM o fundo cinza e SEM as caixas cinza de faceta do default do ggplot2.
#
# Uso no .qmd (chunk de setup, uma única vez):
#     source("R/tema_artigo.R")          # ou o caminho onde você salvar
#     theme_set(theme_artigo())           # todas as figuras herdam o tema
#     usa_locale_ptbr()                    # vírgula decimal / ponto de milhar
#
# Depende só de: ggplot2, scales. Paletas e fontes são opcionais e degradam
# com elegância se o pacote/fonte não existir.
# ============================================================================

library(ggplot2)
library(scales)

# ----------------------------------------------------------------------------
# 1. O TEMA — theme_artigo()
# ----------------------------------------------------------------------------
# Decisões que matam o "cinza feio" e passam credibilidade:
#   * panel.background BRANCO (não cinza) e sem borda redundante;
#   * grade MÍNIMA: só as horizontais maiores, finíssimas (grey92);
#     linhas verticais e menores REMOVIDAS (viram ruído);
#   * faceta SEM caixa cinza (strip.background em branco), rótulo em negrito;
#   * título alinhado à margem do PLOT (não do painel), peso claro, subtítulo
#     e caption em cinza discreto — hierarquia tipográfica, não decoração;
#   * legenda no topo, sem caixa, encostada no título — o olho não caça.
#
# base_family: deixe "" para usar a fonte do device (mais portável). Para casar
# com o manuscrito, passe a família (requer a fonte instalada + showtext/
# systemfonts). Ex.: theme_artigo(base_family = "Source Sans Pro").
theme_artigo <- function(base_size = 11, base_family = "",
                         grid = c("y", "x", "both", "none")) {
  grid <- match.arg(grid)
  meia_tinta <- "grey30"   # texto secundário
  linha_grade <- "grey92"  # grade quase imperceptível

  th <- theme_minimal(base_size = base_size, base_family = base_family) +
    theme(
      # --- fundo: branco, nunca cinza ---
      plot.background  = element_rect(fill = "white", colour = NA),
      panel.background = element_rect(fill = "white", colour = NA),
      panel.border     = element_blank(),

      # --- grade mínima (ajustada por `grid` abaixo) ---
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = linha_grade, linewidth = 0.3),

      # --- eixos: linha base fina, ticks discretos ---
      axis.line   = element_line(colour = "grey40", linewidth = 0.3),
      axis.ticks  = element_line(colour = "grey40", linewidth = 0.3),
      axis.title  = element_text(colour = "grey20"),
      axis.text   = element_text(colour = meia_tinta),
      axis.title.x = element_text(margin = margin(t = 6)),
      axis.title.y = element_text(margin = margin(r = 6)),

      # --- facetas: SEM caixa cinza ---
      strip.background = element_rect(fill = "white", colour = NA),
      strip.text      = element_text(face = "bold", colour = "grey15",
                                     hjust = 0, size = rel(0.95),
                                     margin = margin(b = 4, t = 2)),
      panel.spacing   = unit(1.1, "lines"),

      # --- títulos: alinhados ao plot, hierarquia por peso e cor ---
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.title    = element_text(face = "bold", size = rel(1.15),
                                   colour = "grey10",
                                   margin = margin(b = 3)),
      plot.subtitle = element_text(colour = meia_tinta, size = rel(1.0),
                                   margin = margin(b = 10)),
      plot.caption  = element_text(colour = "grey45", size = rel(0.8),
                                   hjust = 0, margin = margin(t = 10)),

      # --- legenda: no topo, sem caixa, discreta ---
      legend.position   = "top",
      legend.title      = element_text(colour = "grey20", size = rel(0.9)),
      legend.text       = element_text(colour = meia_tinta, size = rel(0.9)),
      legend.key        = element_blank(),
      legend.background = element_blank(),
      legend.margin     = margin(0, 0, 4, 0),
      legend.justification = "left",

      plot.margin = margin(10, 14, 8, 10)
    )

  # grade só onde ajuda a leitura (padrão: horizontais, para barras/coefplot)
  th <- th + switch(grid,
    y    = theme(panel.grid.major.x = element_blank()),
    x    = theme(panel.grid.major.y = element_blank()),
    both = theme(),  # dispersão: mantém as duas
    none = theme(panel.grid.major = element_blank())
  )
  th
}

# Variante para MAPAS: sem eixos, sem grade, sem ticks (coordenadas não são dado)
theme_artigo_mapa <- function(base_size = 11, base_family = "") {
  theme_artigo(base_size, base_family, grid = "none") +
    theme(
      axis.line = element_blank(), axis.ticks = element_blank(),
      axis.text = element_blank(), axis.title = element_blank(),
      panel.grid = element_blank()
    )
}

# ----------------------------------------------------------------------------
# 2. PALETAS — seguras para daltonismo e escala de cinza
# ----------------------------------------------------------------------------
# Qualitativa (categorias sem ordem): Okabe-Ito, segura para daltonismo.
# Nomeie os valores no seu projeto para travar o mapeamento semântico
# (ex.: cor_grupo <- c("Nascimento" = okabe_ito[["azul"]], ...)).
okabe_ito <- c(
  preto    = "#000000", laranja  = "#E69F00", azul_claro = "#56B4E9",
  verde    = "#009E73", amarelo  = "#F0E442", azul       = "#0072B2",
  vermelho = "#D55E00", rosa     = "#CC79A7", cinza      = "#999999"
)

# Duas cores de destaque para o contraste mais comum (tratamento vs. controle,
# antes vs. depois). Distinguíveis em P&B pela luminância.
cor_destaque   <- okabe_ito[["azul"]]    # o que importa
cor_referencia <- "grey60"                 # o fundo/comparação

# Sequencial (magnitude) e divergente (desvio de um centro): use viridis/scico.
# Instale scico para paletas perceptualmente uniformes:
#   scale_fill_viridis_c(option = "mako")           # sequencial
#   scico::scale_fill_scico(palette = "vik", midpoint = 0)  # divergente no 0

# scale_* de conveniência (qualitativa Okabe-Ito, sem nomes)
# Okabe-Ito tem 9 cores; acima disso NENHUMA paleta qualitativa é legível —
# repense a codificação (facetas, destaque + cinza, agrupar categorias).
pal_okabe_ito <- function(n) {
  if (n > length(okabe_ito)) {
    warning("Okabe-Ito tem ", length(okabe_ito), " cores; pediu ", n,
            ". Acima de ~7 categorias, troque cor por facetas ou destaque.")
  }
  unname(okabe_ito[seq_len(n)])
}
scale_colour_artigo <- function(...) {
  discrete_scale("colour", palette = pal_okabe_ito, ...)
}
scale_color_artigo <- scale_colour_artigo
scale_fill_artigo <- function(...) {
  discrete_scale("fill", palette = pal_okabe_ito, ...)
}

# ----------------------------------------------------------------------------
# 3. LOCALE PT-BR — vírgula decimal, ponto de milhar
# ----------------------------------------------------------------------------
# Aplica formatação PT-BR como padrão dos eixos contínuos. Chame uma vez no
# setup. Depois, nos eixos, use os helpers abaixo em scale_*_continuous(labels=).
usa_locale_ptbr <- function() {
  options(
    ggplot2.continuous.colour = "viridis",
    ggplot2.continuous.fill   = "viridis",
    OutDec = ","
  )
  invisible(TRUE)
}

num_ptbr <- function(accuracy = NULL, ...) {
  scales::label_number(accuracy = accuracy, decimal.mark = ",",
                       big.mark = ".", ...)
}
pct_ptbr <- function(accuracy = 1, ...) {
  scales::label_percent(accuracy = accuracy, decimal.mark = ",",
                        big.mark = ".", suffix = "%", ...)
}
# pontos percentuais (pp): número com sufixo " pp"
pp_ptbr <- function(accuracy = 0.1, ...) {
  scales::label_number(accuracy = accuracy, decimal.mark = ",",
                       big.mark = ".", suffix = " pp", ...)
}

# ----------------------------------------------------------------------------
# 4. SALVAR — defaults sensatos (vetorial p/ PDF, largura de coluna)
# ----------------------------------------------------------------------------
# No Quarto, prefira controlar dimensões pelas opções do chunk
# (#| fig-width, #| fig-height, #| fig-dpi) — território da programacao-
# cientifica. Este helper é para exportar avulso (slides, preprint, apêndice).
#   COL_WIDTH ~ largura de UMA coluna; PAGE_WIDTH ~ página inteira (em polegadas)
COL_WIDTH  <- 3.4
PAGE_WIDTH <- 6.9

salva_fig <- function(plot, arquivo, largura = COL_WIDTH, altura = largura * 0.72,
                      dpi = 300, ...) {
  # PDF via cairo_pdf: acentos PT-BR corretos e fontes embutidas (o device
  # pdf() default quebra "ç/ã" fora do Latin-1 e não embute fontes).
  extras <- list(...)
  if (grepl("\\.pdf$", arquivo, ignore.case = TRUE) && is.null(extras$device)) {
    extras$device <- grDevices::cairo_pdf
  }
  do.call(ggplot2::ggsave, c(list(arquivo, plot = plot, width = largura,
                                  height = altura, units = "in", dpi = dpi,
                                  bg = "white"), extras))
}

# ============================================================================
# Ativação típica no setup do .qmd:
#   theme_set(theme_artigo())
#   usa_locale_ptbr()
#   update_geom_defaults("point", list(colour = cor_destaque))  # opcional
# ============================================================================
