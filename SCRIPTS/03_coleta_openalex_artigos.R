#!/usr/bin/env Rscript
# ==============================================================================
# 03_coleta_openalex_artigos.R — Coleta de Artigos de Periódicos CP via OpenAlex
# ==============================================================================
# Versão otimizada (auditoria 2026-08-29):
#   - Uma consulta por periódico (o OpenAlex mapeia ISSN impresso e eletrônico
#     para a mesma fonte; consultar ambos dobrava o tempo de parsing).
#   - simplifyVector = FALSE (o simplifyVector = TRUE era um gargalo enorme em
#     respostas com abstract_inverted_index aninhado e irregular).
#   - Deduplicação por id_openalex (chave única da obra); o antigo
#     distinct(doi, .keep_all=TRUE) colapsava TODAS as obras sem DOI em uma
#     única linha (perda de ~250 registros só na DADOS).
#   - Filtro por tipo "article" (exclui editorial, book-review, erratum...).
#   - Flag de front matter (Apresentação, Editorial, Errata, [NO TITLE...]).

source(here::here("SCRIPTS", "00_setup.R"))

dir_raw <- here::here("DADOS", "raw", "artigos_periodicos")
dir_processed <- here::here("DADOS", "processed")
dir.create(dir_raw, recursive = TRUE, showWarnings = FALSE)
dir.create(dir_processed, recursive = TRUE, showWarnings = FALSE)

# Lista de periódicos canônicos de Ciência Política no Brasil (ISSN eletrônico;
# o OpenAlex trata impresso e eletrônico como a mesma fonte)
issn_periodicos_cp <- tibble::tribble(
  ~periodico,                 ~issn,
  "DADOS_Revista_de_Ciencias_Sociais", "1678-4588",
  "Brazilian_Political_Science_Review", "1981-3821",
  "Opiniao_Publica",           "1807-0191",
  "RBCP_Revista_Brasileira_de_Ciencia_Politica", "2178-4884",
  "Revista_de_Sociologia_e_Politica", "1678-9873",
  "Lua_Nova",                  "1807-0175"
)

message(">>> Coletando metadados de artigos via API OpenAlex...")

# Reconstrói o resumo a partir do abstract_inverted_index (lista R pura)
reconstruir_resumo <- function(inv) {
  if (is.null(inv) || length(inv) == 0) return(NA_character_)
  pos <- list()
  for (palavra in names(inv)) {
    for (p in inv[[palavra]]) pos[[as.character(p + 1L)]] <- palavra
  }
  if (length(pos) == 0) return(NA_character_)
  ids <- as.integer(names(pos))
  paste(unlist(pos[order(ids)]), collapse = " ")
}

extrair_obra <- function(w) {
  ids <- w$ids %||% list()
  tibble::tibble(
    id_openalex = w$id %||% NA_character_,
    doi = ids$doi %||% NA_character_,
    titulo = w$display_name %||% NA_character_,
    ano = w$publication_year %||% NA_integer_,
    data_pub = w$publication_date %||% NA_character_,
    idioma = w$language %||% NA_character_,
    tipo = w$type %||% NA_character_,
    is_oa = !is.null(w$open_access$is_oa) && w$open_access$is_oa,
    citacoes = w$cited_by_count %||% NA_integer_,
    fwci = w$fwci %||% NA_real_,
    resumo = reconstruir_resumo(w$abstract_inverted_index)
  )
}

lista_artigos <- list()

for (i in seq_len(nrow(issn_periodicos_cp))) {
  per <- issn_periodicos_cp$periodico[i]
  issn <- issn_periodicos_cp$issn[i]

  url_base <- paste0(
    "https://api.openalex.org/works",
    "?filter=primary_location.source.issn:", issn,
    "&per-page=200&page="
  )

  pagina <- 1
  n_paginas <- 1
  df_paginas <- list()

  while (pagina <= n_paginas) {
    url <- paste0(url_base, pagina, "&mailto=vpeixoto@uenf.br")
    resp <- tryCatch({
      jsonlite::fromJSON(url, simplifyVector = FALSE)
    }, error = function(e) NULL)

    if (is.null(resp) || !"meta" %in% names(resp) || resp$meta$count == 0) break

    n_paginas <- ceiling(resp$meta$count / 200)
    obras <- resp$results

    if (length(obras) > 0) {
      df_parc <- purrr::map_dfr(obras, extrair_obra)
      df_parc$periodico <- per
      df_parc$issn <- issn
      df_paginas[[pagina]] <- df_parc
    }

    Sys.sleep(0.15)
    pagina <- pagina + 1
  }

  if (length(df_paginas) > 0) {
    df_final <- dplyr::bind_rows(df_paginas)
    lista_artigos[[per]] <- df_final
    message("  [", per, "] ", nrow(df_final), " artigos coletados (ISSN ", issn, ")")
  } else {
    message("  [", per, "] Nenhum trabalho encontrado para ISSN ", issn)
  }

  Sys.sleep(0.2)
}

# -----------------------------------------------------------------------------
# Consolidação (corrigida e auditada em 2026-08-29)
# -----------------------------------------------------------------------------
if (length(lista_artigos) > 0) {
  df_artigos <- dplyr::bind_rows(lista_artigos) %>%
    # (1) chave única da obra no OpenAlex (nunca NA para works válidos)
    dplyr::distinct(id_openalex, .keep_all = TRUE) %>%
    # (2) apenas artigos de pesquisa
    dplyr::filter(tipo == "article") %>%
    # (3) front matter / títulos genéricos
    dplyr::mutate(
      front_matter = grepl(
        "^(apresenta|editorial|errata|pref|nota |sum[áa]rio|expediente|tend[êe]ncia|tributo|obitu[áa]rio|\\[?no title available\\]?|introdu[çc][ãa]o do dossi[êe])",
        tolower(iconv(titulo, to = "ASCII//TRANSLIT", sub = "")),
        ignore.case = TRUE
      )
    ) %>%
    dplyr::arrange(ano)

  arq_rds <- file.path(dir_processed, "artigos_periodicos_openalex.rds")
  arq_csv <- file.path(dir_processed, "artigos_periodicos_openalex.csv")

  saveRDS(df_artigos, arq_rds)
  write_csv(df_artigos, arq_csv)

  message(">>> BASE DE ARTIGOS SALVA: ", arq_rds, " (Total de artigos únicos: ", nrow(df_artigos), ")")
  message(">>> Front matter (a excluir das análises): ", sum(df_artigos$front_matter))
} else {
  message(">>> Nenhum artigo coletado.")
}
