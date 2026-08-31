#!/usr/bin/env Rscript
# ==============================================================================
# 12_coleta_capes_comparada.R — Coleta de teses das áreas irmãs (Comparação)
# Projeto: História, Expansão e Institucionalização da Ciência Política no Brasil
# ==============================================================================
# Baixa e processa teses/dissertações da CAPES para:
# - Sociologia
# - Antropologia
# - História
# - Geografia
# - Economia
# Usado para contextualizar comparativamente o atraso e tamanho da Ciência Política.

source(here::here("SCRIPTS", "00_setup.R"))

dir_raw <- here::here("DADOS", "raw", "capes_teses_comparada")
dir_processed <- here::here("DADOS", "processed")
dir.create(dir_raw, recursive = TRUE, showWarnings = FALSE)

ckan_csv <- "/dados/classe_media/data/processed/busca/capes/capes_recursos_ckan.csv"
if (!file.exists(ckan_csv)) {
  stop("Arquivo de recursos CKAN não encontrado em: ", ckan_csv)
}

recursos <- read_csv(ckan_csv, show_col_types = FALSE) %>%
  filter(!is.na(ano), !is.na(url)) %>%
  arrange(ano)

message(">>> Total de safras anuais disponíveis no CKAN: ", nrow(recursos), " (", min(recursos$ano), " a ", max(recursos$ano), ")")

# -----------------------------------------------------------------------------
# Filtro AWK abrangendo as áreas irmãs.
# Códigos CNPq (layout antigo):
# 7090 - Ciência Política (já temos, mas pegamos de novo pra consolidar)
# 7020 - Sociologia
# 7030 - Antropologia
# 7050 - História
# 7060 - Geografia
# 6030 - Economia / 7010 - Filosofia (se quisermos)
# Layout novo: buscamos pelos nomes das áreas
# -----------------------------------------------------------------------------
awk_prog <- 'BEGIN { IGNORECASE = 1 } 
NR == 1 { print; next } 
{ total++ } 
$0 ~ /(7020[0-9]{4}|7030[0-9]{4}|7050[0-9]{4}|7060[0-9]{4}|6030[0-9]{4}|7090[0-9]{4}|sociologia|antropologia|hist.ria|geografia|economia|ci.ncia pol.tica)/ { casou++; print } 
END { printf("TOTAL=%d\\nCASOU=%d\\n", total, casou) > "/dev/stderr" }'

awk_prog_path <- file.path(tempdir(), "capes_filtro_comparado.awk")
writeLines(awk_prog, awk_prog_path)

ler_contagem <- function(log_path) {
  if (!file.exists(log_path)) return(tibble::tibble(total = NA_integer_, casou = NA_integer_))
  linhas <- readLines(log_path, warn = FALSE)
  total <- as.integer(sub("TOTAL=", "", linhas[grepl("TOTAL=", linhas)]))
  casou <- as.integer(sub("CASOU=", "", linhas[grepl("CASOU=", linhas)]))
  tibble::tibble(total = total, casou = casou)
}

extrair_ano_comparado <- function(url, ano, tentativas = 5) {
  dest_tsv <- file.path(dir_raw, paste0("capes_comparada_", ano, ".tsv"))
  dest_log <- file.path(dir_raw, paste0("capes_comparada_", ano, ".log"))

  if (file.exists(dest_tsv) && file.info(dest_tsv)$size > 610) {
    message("  [Cache] Safra ", ano, " já processada.")
    return(dest_tsv)
  }

  message("  [Download & Filtro] Processando safra ", ano, "...")
  cmd <- sprintf(
    "bash -o pipefail -c \"LC_ALL=C curl -sSL --fail --max-time 1800 --retry 3 --retry-delay 5 %s | gawk -f %s > %s 2> %s\"",
    shQuote(url), shQuote(awk_prog_path), shQuote(dest_tsv), shQuote(dest_log)
  )

  status <- 1
  for (t in seq_len(tentativas)) {
    status <- system(cmd)
    if (status == 0 && file.exists(dest_tsv) && file.info(dest_tsv)$size > 610) break
    Sys.sleep(5 * t)
  }

  if (status != 0 || !file.exists(dest_tsv) || file.info(dest_tsv)$size <= 610) {
    warning("  [Falha] Safra ", ano)
    if (file.exists(dest_tsv)) unlink(dest_tsv)
    return(NULL)
  }

  cnt <- ler_contagem(dest_log)
  message("  [Sucesso] Safra ", ano, ": ", cnt$casou, " casamentos.")
  return(dest_tsv)
}

# Aqui rodam os downloads e extrações com awk. É demorado, vou rodar em background.
arquivos_gerados <- purrr::map2(recursos$url, recursos$ano, extrair_ano_comparado)
message("Coleta finalizada.")
