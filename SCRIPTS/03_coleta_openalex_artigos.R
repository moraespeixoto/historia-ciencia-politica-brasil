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
suppressPackageStartupMessages(library(stringi))

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
  dir_tabelas <- here::here("TABELAS")
  dir.create(dir_tabelas, recursive = TRUE, showWarnings = FALSE)

  # Ano de fundação de cada periódico. Registros anteriores à fundação são
  # erros de atribuição de ISSN no OpenAlex (caso conhecido: 1 registro da RBCP
  # datado de 2001, oito anos antes da fundação da revista). Fontes: páginas
  # oficiais/SciELO das revistas. [verificar] para Opinião Pública e RSP.
  ano_fundacao <- c(
    DADOS_Revista_de_Ciencias_Sociais = 1966,
    Lua_Nova = 1984,
    Opiniao_Publica = 1993,
    Revista_de_Sociologia_e_Politica = 1993,
    Brazilian_Political_Science_Review = 2007,
    RBCP_Revista_Brasileira_de_Ciencia_Politica = 2009
  )

  # F06: padrões ANCORADOS. A versão anterior usava "pref" e "tend[êe]ncia"
  # soltos, o que excluía como front matter 13 artigos começando por
  # "Tendências..." e 3 por "Preferências...". Cada exclusão é gravada em
  # TABELAS/openalex_front_matter_excluidos.csv para leitura.
  front_matter_re <- paste0(
    "^(apresenta[cC][aA]o|editorial|errata|erratum|prefacio|",
    "nota (do|da|dos|editorial)|sumario|expediente|tribut[oe]|obituario|",
    "in memoriam|\\[?no title available\\]?|",
    "introdu[cC][aA]o (ao|do|a) dossi[eE]|",
    "tendencias e debates)"
  )
  ascii_lower <- function(x) tolower(iconv(x, to = "ASCII//TRANSLIT", sub = ""))
  # Chave de deduplicação pt/en: mesmo periódico, mesmo ano, mesmo título
  # normalizado. F07: a BPSR publica versões pt e en da mesma obra com
  # `id_openalex` distintos, que `distinct(id_openalex)` não remove.
  norm_titulo <- function(x) {
    x <- stringi::stri_trans_general(tolower(replace_na(x, "")), "Latin-ASCII")
    str_squish(gsub("[^a-z0-9 ]", " ", x))
  }
  # DOI sem sufixo de versão/idioma (…-en, …x2) para o caso BPSR.
  doi_base <- function(x) {
    x <- tolower(replace_na(x, ""))
    x <- sub("^https?://(dx\\.)?doi\\.org/", "", x)
    sub("(-en|-pt|x[0-9])$", "", x)
  }

  bruto <- dplyr::bind_rows(lista_artigos) %>%
    dplyr::distinct(id_openalex, .keep_all = TRUE)
  n_bruto <- nrow(bruto)
  tab_tipos <- bruto %>% dplyr::count(tipo, sort = TRUE)

  df_artigos <- bruto %>%
    dplyr::filter(tipo == "article") %>%
    dplyr::mutate(
      front_matter = grepl(front_matter_re, ascii_lower(titulo)),
      titulo_norm = norm_titulo(titulo),
      doi_norm = doi_base(doi),
      antes_da_fundacao = !is.na(ano) & ano < ano_fundacao[periodico]
    )
  n_pos_article <- nrow(df_artigos)

  # Registros anteriores à fundação
  pre_fundacao <- df_artigos %>% dplyr::filter(antes_da_fundacao)
  write_csv(pre_fundacao %>% select(periodico, ano, titulo, doi, id_openalex),
            file.path(dir_tabelas, "openalex_pre_fundacao_excluidos.csv"))
  df_artigos <- df_artigos %>% dplyr::filter(!antes_da_fundacao)
  n_pre_fund <- nrow(pre_fundacao)

  # Deduplicação pt/en (mantém o registro com resumo, e entre esses o de maior
  # contagem de citações, para não perder o registro mais completo).
  # Duas passadas. A primeira remove reedições que compartilham DOI base. A
  # segunda usa (periódico, ano, título normalizado): é ela que pega o caso
  # BPSR 2007-2008, em que a MESMA obra aparece com dois `id_openalex` e dois
  # DOIs SciELO distintos, diferindo apenas na caixa do título. Deduplicar só
  # por DOI (como uma primeira versão fazia) não remove nada nesse caso.
  antes_dedup <- nrow(df_artigos)
  ordenar <- function(d) dplyr::arrange(d, is.na(resumo), dplyr::desc(citacoes))
  df_artigos <- df_artigos %>%
    dplyr::mutate(tem_doi = doi_norm != "") %>%
    ordenar() %>%
    dplyr::group_by(doi_norm) %>%
    dplyr::filter(!tem_doi | dplyr::row_number() == 1L) %>%
    dplyr::ungroup()
  n_dup_doi <- antes_dedup - nrow(df_artigos)
  apos_doi <- nrow(df_artigos)
  df_artigos <- df_artigos %>%
    ordenar() %>%
    dplyr::distinct(periodico, ano, titulo_norm, .keep_all = TRUE) %>%
    dplyr::select(-tem_doi)
  n_dup_titulo <- apos_doi - nrow(df_artigos)
  n_dup_removidos <- antes_dedup - nrow(df_artigos)

  # Idioma do resumo detectado (cld2), comparado ao campo `idioma` do OpenAlex.
  if (requireNamespace("cld2", quietly = TRUE)) {
    df_artigos$idioma_resumo <- cld2::detect_language(df_artigos$resumo)
  } else {
    warning("cld2 ausente: idioma_resumo não detectado.")
    df_artigos$idioma_resumo <- NA_character_
  }

  df_artigos <- df_artigos %>% dplyr::arrange(ano)

  # Front matter excluído, para leitura e auditoria.
  write_csv(
    df_artigos %>% dplyr::filter(front_matter) %>%
      select(periodico, ano, titulo, tipo, doi, id_openalex),
    file.path(dir_tabelas, "openalex_front_matter_excluidos.csv"))

  # Amostra aleatória de 100 títulos classificados como `article` para estimar a
  # proporção de resenhas que o OpenAlex não rotula como book-review (F34/C14).
  set.seed(20260828)
  write_csv(
    df_artigos %>% dplyr::filter(!front_matter) %>% dplyr::slice_sample(n = min(100, nrow(.))) %>%
      select(periodico, ano, titulo, doi) %>% mutate(e_resenha = NA_character_),
    file.path(dir_tabelas, "amostra_resenhas.csv"))

  # Cobertura de resumo e lacunas anuais por periódico.
  cobertura <- df_artigos %>%
    dplyr::filter(!front_matter, ano <= 2024) %>%
    dplyr::group_by(periodico) %>%
    dplyr::summarise(n = dplyr::n(), primeiro_ano = min(ano, na.rm = TRUE),
                     pct_com_resumo = round(100 * mean(!is.na(resumo)), 1),
                     .groups = "drop")
  lacunas <- df_artigos %>%
    dplyr::filter(!front_matter, ano <= 2024) %>%
    dplyr::count(periodico, ano) %>%
    tidyr::complete(tidyr::nesting(periodico), ano = 1966:2024, fill = list(n = 0)) %>%
    dplyr::group_by(periodico) %>%
    dplyr::filter(ano >= min(ano[n > 0]), n == 0) %>%
    dplyr::ungroup()
  write_csv(cobertura, file.path(dir_tabelas, "openalex_cobertura_periodicos.csv"))
  write_csv(lacunas, file.path(dir_tabelas, "openalex_lacunas_anuais.csv"))

  arq_rds <- file.path(dir_processed, "artigos_periodicos_openalex.rds")
  arq_csv <- file.path(dir_processed, "artigos_periodicos_openalex.csv")

  saveRDS(df_artigos, arq_rds)
  write_csv(df_artigos, arq_csv)
  saveRDS(list(n_bruto = n_bruto, n_pos_article = n_pos_article,
               n_pre_fundacao_removidos = n_pre_fund,
               n_dup_removidos = n_dup_removidos,
               n_dup_doi = n_dup_doi, n_dup_titulo = n_dup_titulo,
               n_front_matter = sum(df_artigos$front_matter),
               tipos = tab_tipos, cobertura = cobertura, lacunas = lacunas),
          file.path(dir_processed, "openalex_auditoria_coleta.rds"))

  message(">>> BASE DE ARTIGOS SALVA: ", arq_rds, " (obras únicas: ", nrow(df_artigos), ")")
  message(">>> Bruto: ", n_bruto, " | article: ", n_pos_article,
          " | pré-fundação removidos: ", n_pre_fund,
          " | duplicatas pt/en removidas: ", n_dup_removidos,
          " | front matter sinalizado: ", sum(df_artigos$front_matter))
  print(cobertura)
} else {
  message(">>> Nenhum artigo coletado.")
}
