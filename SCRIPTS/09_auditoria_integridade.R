#!/usr/bin/env Rscript
# ==============================================================================
# 09_auditoria_integridade.R — Auditoria de integridade das bases processadas
# Projeto: História, Expansão e Institucionalização da Ciência Política no Brasil
#
# Roda APENAS sobre os arquivos em DADOS/processed/ (sem rede).
# Replica as verificações centrais do relatório AUDITORIA.md:
#   1. Totais e anos das séries CAPES / Sucupira / OpenAlex
#   2. Contaminação do filtro CAPES (registros fora da área 39)
#   3. Colapso de DOIs ausentes no OpenAlex (distinct(doi) com NA)
#   4. Tipos de documento no OpenAlex (artigos vs editoriais etc.)
#   5. Correspondência rótulo x termos FREX do modelo STM
# ==============================================================================

source(here::here("SCRIPTS", "00_setup.R"))

dir_processed <- here::here("DADOS", "processed")
cat("================================================================\n")
cat("AUDITORIA DE INTEGRIDADE — DADOS PROCESSADOS\n")
cat("Data:", Sys.Date(), "\n")
cat("================================================================\n\n")

# -----------------------------------------------------------------------------
# 1. CAPES
# -----------------------------------------------------------------------------
capes <- readRDS(file.path(dir_processed, "capes_cp_1987_2024.rds"))
n_antigo <- sum(!is.na(capes$ano_base)); n_novo <- sum(!is.na(capes$an_base))
cat("== 1. CAPES (", nrow(capes), " registros) ==\n")
cat("  Layout antigo (1987-2012):", n_antigo, "| Layout novo (2013-2024):", n_novo, "\n")
cat("  Soma (deve ser igual a nrow):", n_antigo + n_novo, "\n")

# Contaminação: registros antigos com área de avaliação fora da 39
if ("area_avaliacao" %in% names(capes)) {
  antigo <- capes %>% filter(!is.na(ano_base))
  fora39 <- antigo %>%
    filter(!grepl("CIÊNCIA POLÍTICA E RELAÇÕES INTERNACIONAIS", area_avaliacao, ignore.case = TRUE))
  cat("  Layout antigo fora da área 39:", nrow(fora39), "de", nrow(antigo),
      "(", round(100 * nrow(fora39) / nrow(antigo), 2), "%)\n")
}

# Contaminação no layout novo: âncora administrativa direta (nm_area_avaliacao)
# vs. crosswalk de códigos de programa via Sucupira (checagem cruzada).
prog <- readRDS(file.path(dir_processed, "sucupira_programas_cp_2013_2024.rds"))
suc_cod <- unique(prog$cd_programa_ies)
novo <- capes %>% filter(!is.na(an_base))
via_area <- !is.na(novo$nm_area_avaliacao) &
  novo$nm_area_avaliacao == "CIÊNCIA POLÍTICA E RELAÇÕES INTERNACIONAIS"
via_crosswalk <- novo$cd_programa %in% suc_cod
fora39_novo <- sum(!(via_area | via_crosswalk))
cat("  Layout novo fora da área 39 (área de avaliação OU crosswalk Sucupira):", fora39_novo, "de", nrow(novo),
    "(", round(100 * fora39_novo / nrow(novo), 2), "%)\n")
cat("  Discordância área de avaliação x crosswalk Sucupira:", sum(via_area != via_crosswalk), "registros\n\n")

# -----------------------------------------------------------------------------
# 2. Sucupira
# -----------------------------------------------------------------------------
docs <- readRDS(file.path(dir_processed, "sucupira_docentes_cp_2013_2024.rds"))
cat("== 2. SUCUPIRA ==\n")
cat("  Programas únicos (2013-2024):", n_distinct(prog$cd_programa_ies),
    "| máx por ano:", max(prog %>% count(ano_base) %>% pull(n)), "\n")
cat("  Docentes: vínculos =", nrow(docs), "| id_pessoa únicos =", n_distinct(docs$id_pessoa),
    "| nm_docente únicos =", n_distinct(docs$nm_docente), "\n\n")

# -----------------------------------------------------------------------------
# 3. OpenAlex: totens, DOIs e tipos
# -----------------------------------------------------------------------------
oa <- readRDS(file.path(dir_processed, "artigos_periodicos_openalex.rds"))
cat("== 3. OPENALEX ==\n")
cat("  Registros:", nrow(oa), "| artigos de pesquisa ≤ 2024 (sem front matter):",
    sum(oa$ano <= 2024 & !oa$front_matter, na.rm = TRUE), "\n")
cat("  Duplicatas por id_openalex (deve ser 0):", nrow(oa) - n_distinct(oa$id_openalex), "\n")
cat("  Obras sem DOI (preservadas pela correção; antes colapsavam em 1 linha):",
    sum(is.na(oa$doi)), "\n")
cat("  Front matter sinalizado:", sum(oa$front_matter), "\n")
cat("  Tipos de documento (≤2024):\n")
print(oa %>% filter(ano <= 2024) %>% count(tipo, sort = TRUE))
cat("  Artigos de pesquisa (type=article, sem front matter, ≤2024):",
    sum(oa$tipo == "article" & oa$ano <= 2024 & !oa$front_matter, na.rm = TRUE), "\n\n")

# -----------------------------------------------------------------------------
# 4. STM: rótulos vs termos FREX
# -----------------------------------------------------------------------------
cat("== 4. STM (rótulos x termos FREX) ==\n")
if (file.exists(file.path(dir_processed, "stm_model_k8.rds"))) {
  suppressPackageStartupMessages(library(stm))
  m <- readRDS(file.path(dir_processed, "stm_model_k8.rds"))
  cat("  Documentos no modelo:", nrow(m$theta), "| K =", m$settings$dim$K, "\n")
  lt <- labelTopics(m, n = 6)
  nomes <- readRDS(file.path(dir_processed, "stm_topicos_nomes.rds"))
  for (k in 1:m$settings$dim$K) {
    cat("  ", nomes[k], "\n      FREX:", paste(lt$frex[k, ], collapse = ", "), "\n")
  }
  cat("  ATENÇÃO: confira se o rótulo descreve os termos FREX (auditoria de 2026-08-29\n")
  cat("  encontrou T1<->T2, T3<->T4 trocados e T6/T7 como artefatos de idioma).\n")
}

cat("\n================================================================\n")
cat("FIM DA AUDITORIA.\n")
