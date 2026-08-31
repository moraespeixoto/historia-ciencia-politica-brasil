# ==============================================================================
# 00_setup.R — Configuração Geral e Ambiente Reprodutível
# Projeto: História, Expansão e Institucionalização da Ciência Política no Brasil
# ==============================================================================

# 1. Carregamento de pacotes essenciais
pacotes <- c(
  "here",          # Caminhos relativos à raiz do .Rproj
  "tidyverse",     # Manipulação de dados e ggplot2
  "janitor",       # Limpeza de nomes de colunas
  "lubridate",     # Tratamento de datas
  "scales",        # Formatação de escalas
  "knitr",         # Renderização de tabelas e chunks
  "kableExtra",    # Formatação avançada de tabelas
  "modelsummary",  # Resumos de modelos e estatísticas descritivas
  "tidytext",      # Mineração de texto e NLP
  "igraph",        # Análise de redes
  "ggraph"         # Visualização de redes
)

novos_pacotes <- pacotes[!(pacotes %in% installed.packages()[, "Package"])]
if (length(novos_pacotes) > 0) {
  install.packages(novos_pacotes, dependencies = TRUE)
}

invisible(lapply(pacotes, library, character.only = TRUE))

# 2. Semente determinística
set.seed(20260828)

# 3. Importação do tema visual do paper (visualizacao-cientifica)
source(here::here("SCRIPTS", "tema_artigo.R"))
theme_set(theme_artigo())
if (exists("usa_locale_ptbr")) usa_locale_ptbr()

# 4. Helpers de formatação escalar para inline text (programacao-cientifica)
fmt_num <- function(x, digits = 1) {
  if (is.na(x) || length(x) != 1) return("---")
  format(round(x, digits), nsmall = digits, big.mark = ".", decimal.mark = ",")
}

fmt_pct <- function(x, digits = 1) {
  if (is.na(x) || length(x) != 1) return("---")
  paste0(fmt_num(x * 100, digits), "%")
}

fmt_int <- function(x) {
  if (is.na(x) || length(x) != 1) return("---")
  format(as.integer(x), big.mark = ".")
}

message("Ambiente configurado com sucesso! Semente: 20260828.")
