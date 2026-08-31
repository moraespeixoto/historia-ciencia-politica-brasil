# Prepara edição do Quarto
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(stringr))
source(here::here("SCRIPTS", "00_setup.R"))

# Atualiza referências
ref <- readLines(here::here("referencias.bib"))
ref <- str_replace_all(ref, "Leite, Fernando and Codato, Adriano", "Leite, Fernando e Codato, Adriano")
writeLines(ref, here::here("referencias.bib"))
