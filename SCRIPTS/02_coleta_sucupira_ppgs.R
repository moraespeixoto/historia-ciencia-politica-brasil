#!/usr/bin/env Rscript
# ==============================================================================
# 02_coleta_sucupira_ppgs.R — Sucupira/CAPES: Programas e Docentes de CP & RI
# ==============================================================================

source(here::here("SCRIPTS", "00_setup.R"))

dir_raw <- here::here("DADOS", "raw", "sucupira_ppgs")
dir_processed <- here::here("DADOS", "processed")
dir.create(dir_raw, recursive = TRUE, showWarnings = FALSE)
dir.create(dir_processed, recursive = TRUE, showWarnings = FALSE)

message(">>> Iniciando rotina de coleta Sucupira/CAPES (Programas e Docentes CP&RI)...")

# -----------------------------------------------------------------------------
# 1. Recursos CKAN mapeados (URLs fixas, consultadas em 2026-08-29)
# -----------------------------------------------------------------------------
# Programas PPG (colunas-chave: AN_BASE, NM_AREA_AVALIACAO, CD_PROGRAMA_IES,
# NM_PROGRAMA_IES, SG_UF_PROGRAMA, CD_CONCEITO_PROGRAMA, ANO_INICIO_PROGRAMA,
# NM_GRAU_PROGRAMA, DS_SITUACAO_PROGRAMA)
urls_prog <- c(
  "https://dadosabertos.capes.gov.br/dataset/122620f6-47dc-4363-9d63-130c8a386af6/resource/62f82787-3f45-4b9e-8457-3366f60c264b/download/br-capes-colsucup-prog-2013a2016-2020-06-12_2013.csv",
  "https://dadosabertos.capes.gov.br/dataset/122620f6-47dc-4363-9d63-130c8a386af6/resource/338666fe-c9ad-4c3b-9c44-d347c8426920/download/br-capes-colsucup-prog-2013a2016-2020-06-12_2014.csv",
  "https://dadosabertos.capes.gov.br/dataset/122620f6-47dc-4363-9d63-130c8a386af6/resource/4f9372b5-72f6-48e0-9e7c-64bd30563955/download/br-capes-colsucup-prog-2013a2016-2020-06-12_2015.csv",
  "https://dadosabertos.capes.gov.br/dataset/122620f6-47dc-4363-9d63-130c8a386af6/resource/4af2ed1b-5822-4d2d-acdd-c460d70a06b9/download/br-capes-colsucup-prog-2013a2016-2020-06-12_2016.csv",
  "https://dadosabertos.capes.gov.br/dataset/903b4215-ea91-4927-8975-d1484891374f/resource/9835dd45-d4e7-4b1f-b550-eb9b049bacac/download/br-capes-colsucup-prog-2017-2021-11-10.csv",
  "https://dadosabertos.capes.gov.br/dataset/903b4215-ea91-4927-8975-d1484891374f/resource/f21e8124-d246-4ba3-abfb-cb74fc23ccb5/download/br-capes-colsucup-prog-2018-2021-11-10.csv",
  "https://dadosabertos.capes.gov.br/dataset/903b4215-ea91-4927-8975-d1484891374f/resource/62f615b8-66d1-4f9b-9014-6ec27687e2d1/download/br-capes-colsucup-prog-2019-2021-11-10.csv",
  "https://dadosabertos.capes.gov.br/dataset/903b4215-ea91-4927-8975-d1484891374f/resource/ee284b2d-0c33-459d-856b-0a2c055d327c/download/br-capes-colsucup-prog-2020-2021-11-10.csv",
  "https://dadosabertos.capes.gov.br/dataset/414275c0-2056-4a12-b1a6-b525b74850d5/resource/21be9dd6-d4fa-470e-a5b9-b59c20879f10/download/br-capes-colsucup-prog-2021-2025-03-31.csv",
  "https://dadosabertos.capes.gov.br/dataset/414275c0-2056-4a12-b1a6-b525b74850d5/resource/ead1fb95-dce7-46da-b253-998dddc3f448/download/br-capes-colsucup-prog-2022-2025-03-31.csv",
  "https://dadosabertos.capes.gov.br/dataset/414275c0-2056-4a12-b1a6-b525b74850d5/resource/ddff2931-c0df-4bf8-a0fc-a97ad9cd74a0/download/br-capes-colsucup-prog-2023-2025-03-31.csv",
  "https://dadosabertos.capes.gov.br/dataset/414275c0-2056-4a12-b1a6-b525b74850d5/resource/76ccbd76-7f3a-40c3-a4dc-7d6f65858db8/download/br-capes-colsucup-prog-2024-2025-12-01.csv"
)

# Docentes PPG (2013-2016, 2017-2020, 2021-2024) — para análise de coautoria
urls_docente <- c(
  "https://dadosabertos.capes.gov.br/dataset/35eab2f8-5a64-4619-b3f1-63a2e6690cfa/resource/72582076-d83f-4427-95f8-94247eb5dfda/download/br-capes-colsucup-docente-2013-2023-08-01.csv",
  "https://dadosabertos.capes.gov.br/dataset/35eab2f8-5a64-4619-b3f1-63a2e6690cfa/resource/3adbdc71-dbfa-4186-a975-31d59ebc5735/download/br-capes-colsucup-docente-2014-2023-08-01.csv",
  "https://dadosabertos.capes.gov.br/dataset/35eab2f8-5a64-4619-b3f1-63a2e6690cfa/resource/750d1748-218d-4cc8-a435-06a9c882bc74/download/br-capes-colsucup-docente-2015-2023-08-01.csv",
  "https://dadosabertos.capes.gov.br/dataset/35eab2f8-5a64-4619-b3f1-63a2e6690cfa/resource/f3328f37-e1b5-47da-bc01-ae88a5d3a68c/download/br-capes-colsucup-docente-2016-2023-08-01.csv",
  "https://dadosabertos.capes.gov.br/dataset/57f86b23-e751-4834-8537-e9d33bd608b6/resource/89662c04-3451-45cd-b2e8-ae430bc6e00f/download/br-capes-colsucup-docente-2017-2021-11-10.csv",
  "https://dadosabertos.capes.gov.br/dataset/57f86b23-e751-4834-8537-e9d33bd608b6/resource/7777b5e7-3754-4d9f-83a7-bab568edee93/download/br-capes-colsucup-docente-2018-2021-11-10.csv",
  "https://dadosabertos.capes.gov.br/dataset/57f86b23-e751-4834-8537-e9d33bd608b6/resource/57469ecf-c018-4ed1-b68e-06cec87599a8/download/br-capes-colsucup-docente-2019-2021-11-10.csv",
  "https://dadosabertos.capes.gov.br/dataset/57f86b23-e751-4834-8537-e9d33bd608b6/resource/72ab509c-4ca8-452c-9768-b591194f96e1/download/br-capes-colsucup-docente-2020-2021-11-10.csv",
  "https://dadosabertos.capes.gov.br/dataset/0be9cfba-56e8-4da1-b3cc-0a05412eba3d/resource/cb95cea4-e4a8-4249-a58c-bc14d57f9889/download/br-capes-colsucup-docente-2021-2025-03-31.csv",
  "https://dadosabertos.capes.gov.br/dataset/0be9cfba-56e8-4da1-b3cc-0a05412eba3d/resource/644b4e6a-f158-4bb7-9287-a5cd786989d7/download/br-capes-colsucup-docente-2022-2025-03-31.csv",
  "https://dadosabertos.capes.gov.br/dataset/0be9cfba-56e8-4da1-b3cc-0a05412eba3d/resource/c4481fda-3e65-4dcc-9222-6b0c3d64daa7/download/br-capes-colsucup-docente-2023-2025-03-31.csv",
  "https://dadosabertos.capes.gov.br/dataset/0be9cfba-56e8-4da1-b3cc-0a05412eba3d/resource/4b256d1c-9448-4598-bf1d-9d8d8df633de/download/br-capes-colsucup-docente-2024-2025-12-01.csv"
)

# -----------------------------------------------------------------------------
# 2. Download em CSV bruto (Latin-1, como publicado) para DADOS/raw/
# -----------------------------------------------------------------------------
baixar_csv <- function(url, nome) {
  dest <- file.path(dir_raw, nome)
  if (file.exists(dest) && file.info(dest)$size > 10000) {
    message("  [Cache] ", nome)
    return(dest)
  }
  message("  [Download] ", nome, " ...")
  status <- system(sprintf(
    "curl -sSL --fail --max-time 1800 --retry 3 --retry-delay 5 -o '%s' '%s'",
    dest, url
  ))
  if (status != 0 || !file.exists(dest)) {
    warning("Falha no download de ", nome)
    return(NULL)
  }
  message("  [OK] ", nome, " (", round(file.info(dest)$size / 1e6, 1), " MB)")
  dest
}

# -----------------------------------------------------------------------------
# 3. Filtro por área de avaliação 39 (Ciência Política e Relações Internacionais)
#    Os arquivos vêm em Latin-1 (ISO-8859-1)
# -----------------------------------------------------------------------------
filtrar_cp <- function(caminho, tipo) {
  # Lê com encoding Latin-1 e identifica programas/linhas de CP&RI.
  # Âncora primária: código da área de avaliação 39 (único para a área);
  # âncora secundária (fallback): nomes em colunas de área/conhecimento.
  df <- read_delim(caminho, delim = ";", locale = locale(encoding = "Latin1"),
                   show_col_types = FALSE, guess_max = 100000)
  nomes <- names(df)

  cond <- rep(FALSE, nrow(df))

  col_cod <- grep("^CD_AREA_AVALIACAO$", nomes, value = TRUE)
  if (length(col_cod) == 1) {
    cond <- cond | (as.character(df[[col_cod]]) == "39")
  }

  col_area <- grep("NM_AREA_AVALIACAO|NM_AREA_CONHECIMENTO", nomes, value = TRUE)
  if (length(col_area) > 0) {
    df_txt <- df %>%
      mutate(across(any_of(col_area), ~ replace_na(as.character(.), "")))
    cond_txt <- Reduce(`|`, lapply(col_area, function(c) {
      grepl("CIÊNCIA POLÍTICA|CIENCIA POLITICA|RELAÇÕES INTERNACIONAIS|RELACOES INTERNACIONAIS|ESTUDOS ESTRATÉGICOS|ESTUDOS ESTRATEGICOS",
            df_txt[[c]], ignore.case = TRUE)
    }))
    cond <- cond | cond_txt
  }

  df[cond, ]
}

extrair_ano <- function(url, ano, tipo) {
  nome <- paste0("sucupira_", tipo, "_", ano, ".csv")
  caminho <- baixar_csv(url, nome)
  if (is.null(caminho)) return(NULL)
  filtrado <- tryCatch(filtrar_cp(caminho, tipo), error = function(e) {
    warning("Erro ao filtrar ", nome, ": ", e$message)
    NULL
  })
  if (!is.null(filtrado) && nrow(filtrado) > 0) {
    message("  [Filtro] ", ano, " (", tipo, "): ", nrow(filtrado), " registros de CP&RI")
    filtrado$ANO_FONTE <- ano
    filtrado$TIPO_FONTE <- tipo
  }
  # Padroniza tipos: tudo character antes de devolver para evitar conflito no bind_rows
  if (!is.null(filtrado)) filtrado %>% mutate(across(everything(), as.character)) else NULL
}

anos_prog <- 2013:2024
anos_doc <- 2013:2024

# Baixa e filtra programas
message(">>> --- PROGRAMAS PPG (", length(urls_prog), " arquivos) ---")
lista_prog <- purrr::map2(urls_prog, anos_prog, ~ extrair_ano(.x, .y, "prog"))

# Baixa e filtra docentes
message(">>> --- DOCENTES PPG (", length(urls_docente), " arquivos) ---")
lista_doc <- purrr::map2(urls_docente, anos_doc, ~ extrair_ano(.x, .y, "doc"))

# Consolida e converte TUDO para character IMEDIATAMENTE após bind_rows
progs <- purrr::compact(lista_prog) %>% bind_rows() %>% mutate(across(everything(), as.character))
docs  <- purrr::compact(lista_doc) %>% bind_rows() %>% mutate(across(everything(), as.character))

message(">>> Programas CP&RI consolidados: ", nrow(progs))
message(">>> Docentes CP&RI consolidados: ", nrow(docs))

if (nrow(progs) > 0) {
  progs_pad <- progs %>%
    clean_names() %>%
    mutate(across(where(is.character), ~ iconv(.x, from = "UTF-8", to = "UTF-8", sub = ""))) %>%
    rename_with(~ str_replace_all(.x, " ", "_")) %>%
    mutate(ano_base = ano_fonte)
  saveRDS(progs_pad, file.path(dir_processed, "sucupira_programas_cp_2013_2024.rds"))
  write_csv(progs_pad, file.path(dir_processed, "sucupira_programas_cp_2013_2024.csv"))
}

if (nrow(docs) > 0) {
  docs_pad <- docs %>%
    clean_names() %>%
    mutate(across(where(is.character), ~ iconv(.x, from = "UTF-8", to = "UTF-8", sub = ""))) %>%
    rename_with(~ str_replace_all(.x, " ", "_")) %>%
    mutate(ano_base = ano_fonte)
  saveRDS(docs_pad, file.path(dir_processed, "sucupira_docentes_cp_2013_2024.rds"))
  write_csv(docs_pad, file.path(dir_processed, "sucupira_docentes_cp_2013_2024.csv"))
}

message(">>> SUCUPIRA CONCLUÍDO.")