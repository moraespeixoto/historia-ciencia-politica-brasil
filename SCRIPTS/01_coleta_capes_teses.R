#!/usr/bin/env Rscript
# ==============================================================================
# 01_coleta_capes_teses.R — Extração Completa do Catálogo CAPES para CP & RI
# ==============================================================================

source(here::here("SCRIPTS", "00_setup.R"))

dir_raw <- here::here("DADOS", "raw", "capes_teses")
dir_processed <- here::here("DADOS", "processed")
dir.create(dir_raw, recursive = TRUE, showWarnings = FALSE)
dir.create(dir_processed, recursive = TRUE, showWarnings = FALSE)

ckan_csv <- "/dados/classe_media/data/processed/busca/capes/capes_recursos_ckan.csv"
if (!file.exists(ckan_csv)) {
  stop("Arquivo de recursos CKAN não encontrado em: ", ckan_csv)
}

recursos <- read_csv(ckan_csv, show_col_types = FALSE) %>%
  filter(!is.na(ano), !is.na(url)) %>%
  arrange(ano)

message(">>> Total de safras anuais disponíveis no CKAN: ", nrow(recursos), " (", min(recursos$ano), " a ", max(recursos$ano), ")")

# -----------------------------------------------------------------------------
# Programa AWK gravado em arquivo temporário (evita o quote-hell do sprintf).
# IGNORECASE cobre grafias com/sem acento; o código CNPq 7090xxxx é sentinela.
# -----------------------------------------------------------------------------
awk_prog <- 'BEGIN { IGNORECASE = 1 } NR == 1 { print; next } { total++ } $0 ~ /(7090[0-9]{4}|ciencia politica|cincia poltica|ci.ncia pol.tica|relacoes internacionais|relaes internacionais|relac.es internacionais|estudos politicos|estudos estrat.gicos)/ { casou++; print } END { printf("TOTAL=%d\\nCASOU=%d\\n", total, casou) > "/dev/stderr" }'
awk_prog_path <- file.path(tempdir(), "capes_filtro_cp.awk")
writeLines(awk_prog, awk_prog_path)

# Lê o denominador e o numerador do log de erro gerado pelo AWK
ler_contagem <- function(log_path) {
  if (!file.exists(log_path)) return(tibble::tibble(total = NA_integer_, casou = NA_integer_))
  linhas <- readLines(log_path, warn = FALSE)
  total <- as.integer(sub("TOTAL=", "", linhas[grepl("TOTAL=", linhas)]))
  casou <- as.integer(sub("CASOU=", "", linhas[grepl("CASOU=", linhas)]))
  tibble::tibble(total = total, casou = casou)
}

extrair_ano_cp <- function(url, ano, tentativas = 5) {
  dest_tsv <- file.path(dir_raw, paste0("capes_cp_", ano, ".tsv"))
  dest_log <- file.path(dir_raw, paste0("capes_cp_", ano, ".log"))

  if (file.exists(dest_tsv) && file.info(dest_tsv)$size > 610) {
    message("  [Cache] Safra ", ano, " já processada (", dest_tsv, ")")
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
    warning("  [Falha] Safra ", ano, " após ", tentativas, " tentativas (rede/processamento).")
    if (file.exists(dest_tsv)) unlink(dest_tsv)
    return(NULL)
  }

  cnt <- ler_contagem(dest_log)
  message("  [Sucesso] Safra ", ano, ": ", cnt$casou, " de ", cnt$total, " trabalhos casaram com CP/RI.")
  return(dest_tsv)
}

# Executa extração ano a ano
arquivos_gerados <- purrr::map2(recursos$url, recursos$ano, extrair_ano_cp)

message(">>> Consolidando base histórica...")
lista_df <- list()

# Detecta o encoding de um arquivo pelos primeiros bytes (CAPES publica em
# Latin-1/ISO-8859-1; a heurística anterior, baseada em marcadores de mojibake
# na primeira linha, falhava e gerava acentos corrompidos na base consolidada).
detectar_encoding <- function(f) {
  con <- file(f, "rb")
  on.exit(close(con))
  chunk <- readBin(con, "raw", n = 16384)
  txt <- rawToChar(chunk)
  if (validUTF8(txt)) "UTF-8" else "Latin1"
}

for (ano in recursos$ano) {
  f <- file.path(dir_raw, paste0("capes_cp_", ano, ".tsv"))
  if (file.exists(f) && file.info(f)$size > 610) {
    df_ano <- tryCatch({
      enc <- detectar_encoding(f)
      df <- suppressWarnings(read_delim(f, delim = ";", locale = locale(encoding = enc),
                                        show_col_types = FALSE, guess_max = 5000))
      df %>% clean_names() %>% mutate(across(everything(), as.character))
    }, error = function(e) {
      warning("Erro ao ler ", f, ": ", e$message)
      NULL
    })
    if (!is.null(df_ano) && nrow(df_ano) > 0) {
      lista_df[[as.character(ano)]] <- df_ano
    }
  }
}

if (length(lista_df) > 0) {
  df_consolidado <- bind_rows(lista_df)
  out_rds <- file.path(dir_processed, "capes_cp_1987_2024.rds")
  saveRDS(df_consolidado, out_rds)
  message(">>> BASE CONSOLIDADA SALVA EM: ", out_rds, " (Total de registros: ", nrow(df_consolidado), ")")
} else {
  message(">>> Nenhum dado consolidado ainda.")
}
