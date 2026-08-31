#!/usr/bin/env Rscript
# ==============================================================================
# 04_protocolo_exploratorio.R — Protocolo Exploratório Obrigatório (Camada 2)
# Projeto: História, Expansão e Institucionalização da Ciência Política no Brasil
# ==============================================================================

source(here::here("SCRIPTS", "00_setup.R"))

dir_processed <- here::here("DADOS", "processed")
dir_relatorios <- here::here("DADOS", "processed", "relatorios_eda")
dir.create(dir_relatorios, recursive = TRUE, showWarnings = FALSE)

message(">>> Iniciando Protocolo Exploratório Completo (Camada 2)...")
message(">>> Data de execução: ", Sys.Date())

# -----------------------------------------------------------------------------
# 1. Carrega as três bases consolidadas
# -----------------------------------------------------------------------------
capes_path  <- file.path(dir_processed, "capes_cp_1987_2024.rds")
openalex_path <- file.path(dir_processed, "artigos_periodicos_openalex.rds")
prog_path   <- file.path(dir_processed, "sucupira_programas_cp_2013_2024.rds")
doc_path    <- file.path(dir_processed, "sucupira_docentes_cp_2013_2024.rds")

capes   <- tryCatch(readRDS(capes_path),   error = function(e) NULL)
openalex <- tryCatch(readRDS(openalex_path), error = function(e) NULL)
prog    <- tryCatch(readRDS(prog_path),   error = function(e) NULL)
docs    <- tryCatch(readRDS(doc_path),    error = function(e) NULL)

if (is.null(capes) || nrow(capes) == 0)   warning("BASE CAPES ausente ou vazia.")
if (is.null(openalex) || nrow(openalex) == 0) warning("BASE OPENALEX ausente ou vazia.")
if (is.null(prog) || nrow(prog) == 0)   warning("BASE SUCUPIRA PROGRAMAS ausente ou vazia.")
if (is.null(docs) || nrow(docs) == 0)   warning("BASE SUCUPIRA DOCENTES ausente ou vazia.")

# -----------------------------------------------------------------------------
# 2. Funções de auditoria por base
# -----------------------------------------------------------------------------

auditar_capes <- function(df) {
  if (is.null(df) || nrow(df) == 0) return(list())
  # Coluna ano: pode vir como "an_base" (CAPES raw) ou "ano_base" (clean_names)
  col_ano <- if ("an_base" %in% names(df)) "an_base" else if ("ano_base" %in% names(df)) "ano_base" else NULL
  if (is.null(col_ano)) {
    warning("CAPES: coluna de ano não encontrada.")
    return(list())
  }
  anos_range <- range(df[[col_ano]], na.rm = TRUE)
  message("\n>>> AUDITORIA CAPES (", nrow(df), " teses/dissertações, ", anos_range[1], "-", anos_range[2], ")")

  df <- df %>%
    mutate(
      across(any_of(c("nm_programa", "nm_area_conhecimento", "nm_area_avaliacao")), ~ replace_na(as.character(.), "")),
      # Datas vêm em formatos distintos conforme layout/campo: "dd/mm/aaaa
      # HH:MM:SS" (dt_titulacao 2013+), o formato SAS "ddMMMaaaa:HH:MM:SS"
      # (mês em inglês, dt_titulacao 2013+) e "dd/mmm/aa" com mês abreviado em
      # português (data_defesa, layout antigo). tryFormats() com %d%b%Y falha
      # nos dois primeiros em ~76% dos registros (produzia NA espúrio) e
      # levanta erro no terceiro (locale/comprimento de ano diferentes);
      # parseamos os três padrões explicitamente com format= (que retorna NA
      # em vez de erro) e combinamos.
      across(any_of(c("dt_titulacao", "dt_defesa", "data_defesa")), ~ {
        d1 <- as.Date(.x, format = "%d/%m/%Y %H:%M:%S")
        d2 <- as.Date(.x, format = "%d%b%Y:%H:%M:%S")
        d3 <- as.Date(.x, format = "%d/%b/%y")
        d4 <- as.Date(.x, format = "%Y-%m-%d")
        coalesce(d1, d2, d3, d4)
      }),
      across(any_of(c("nr_paginas", "nr_volume", "cd_programa", "cd_entidade_capes")), as.character)
    )

  # 1) Univariada por safra (ano)
  cat("--- 1. UNIVARIADA POR SAFRA (ano) ---\n")
  print(df %>% count(!!sym(col_ano)) %>% arrange(!!sym(col_ano)))

  # 2) Faltantes por variável e safra
  cat("--- 2. FALTANTES (NA) POR VARIÁVEL E SAFRA ---\n")
  vars_interesse <- intersect(c("nm_programa", "nm_area_avaliacao", "nm_area_conhecimento",
                                "nm_orientador", "nm_discente", "dt_titulacao", "nr_paginas",
                                "sg_entidade_ensino", "nm_entidade_ensino", "sg_uf_ies",
                                "nm_regiao", "cd_grau_academico", "nm_grau_academico"), names(df))
  if (length(vars_interesse) > 0) {
    na_ano <- df %>%
      group_by(!!sym(col_ano)) %>%
      summarise(across(any_of(vars_interesse), ~ mean(is.na(.))), .groups = "drop")
    print(na_ano %>% pivot_longer(-!!sym(col_ano), names_to = "variavel", values_to = "pct_na"))
  }

  # 3) Unicidade de chave
  cat("--- 3. UNICIDADE DE CHAVE ---\n")
  chaves <- intersect(c("cd_programa", "id_producao_intelectual", "id_add_producao_intelectual"), names(df))
  if (length(chaves) > 0) {
    for (c in chaves) {
      dups <- df %>% count(!!sym(c)) %>% filter(n > 1)
      cat("Chave:", c, "| Duplicatas:", nrow(dups), "| Total:", nrow(df), "\n")
    }
  }

  # 4) Sentinelas e caudas
  cat("--- 4. SENTINELAS E CAUDAS ---\n")
  if ("nr_paginas" %in% names(df)) {
    pag <- suppressWarnings(as.numeric(df$nr_paginas))
    cat("Páginas: min=", min(pag, na.rm=TRUE), " max=", max(pag, na.rm=TRUE),
        " median=", median(pag, na.rm=TRUE), " Q1=", quantile(pag, .25, na.rm=TRUE),
        " Q3=", quantile(pag, .75, na.rm=TRUE), "\n")
  }

  # 5) Bivariada: ano x área
  cat("--- 5. BIVARIADA ANO x ÁREA ---\n")
  if ("nm_area_avaliacao" %in% names(df)) {
    print(df %>% count(!!sym(col_ano), nm_area_avaliacao) %>% tidyr::pivot_wider(names_from = !!sym(col_ano), values_from = n, values_fill = 0))
  }

  # 6) Denominadores
  cat("--- 6. DENOMINADORES EXPLÍCITOS ---\n")
  cat("Total de registros:", nrow(df), "\n")
  cat("Anos cobertos:", length(unique(df[[col_ano]])), "(", anos_range[1], "-", anos_range[2], ")\n")
  cat("Programas únicos:", length(unique(df$cd_programa)), "\n")
  cat("IES únicas:", length(unique(df$cd_entidade_capes)), "\n")
  cat("Orientadores únicos:", length(unique(df$nm_orientador)), "\n")
  cat("Discentes únicos:", length(unique(df$nm_discente)), "\n")

  return(list(
    univariada_ano = df %>% count(!!sym(col_ano)),
    faltantes = na_ano,
    sentinelas = list(paginas = summary(pag)),
    denominadores = list(total = nrow(df))
  ))
}

auditar_openalex <- function(df) {
  if (is.null(df) || nrow(df) == 0) return(list())
  message("\n>>> AUDITORIA OPENALEX (", nrow(df), " artigos, ", min(df$ano, na.rm=TRUE), "-", max(df$ano, na.rm=TRUE), ")")

  cat("--- 1. UNIVARIADA POR ANO ---\n")
  print(df %>% count(ano) %>% arrange(ano))

  cat("--- 2. FALTANTES ---\n")
  vars_interesse <- intersect(c("titulo", "doi", "ano", "periodico", "issn", "idioma",
                                "citacoes", "fwci", "resumo"), names(df))
  if (length(vars_interesse) > 0) {
    na_summary <- df %>%
      summarise(across(any_of(vars_interesse), ~ mean(is.na(.)))) %>%
      pivot_longer(everything(), names_to = "variavel", values_to = "pct_na")
    print(na_summary)
  }

  cat("--- 3. UNICIDADE DOI ---\n")
  if ("doi" %in% names(df)) {
    dups <- df %>% count(doi) %>% filter(n > 1)
    cat("DOIs duplicados:", nrow(dups), "de", nrow(df), "\n")
  }

  cat("--- 4. SENTINELAS (citações, FWCI) ---\n")
  if ("citacoes" %in% names(df)) {
    cat("Citações: min=", min(df$citacoes, na.rm=TRUE), " max=", max(df$citacoes, na.rm=TRUE),
        " median=", median(df$citacoes, na.rm=TRUE), "\n")
  }
  if ("fwci" %in% names(df)) {
    cat("FWCI: min=", min(df$fwci, na.rm=TRUE), " max=", max(df$fwci, na.rm=TRUE),
        " median=", median(df$fwci, na.rm=TRUE), "\n")
  }

  cat("--- 5. PERIÓDICO x ANO ---\n")
  print(df %>% count(periodico, ano) %>% tidyr::pivot_wider(names_from = ano, values_from = n, values_fill = 0))

  cat("--- 6. DENOMINADORES ---\n")
  cat("Artigos únicos:", nrow(df), "\n")
  cat("Periódicos:", length(unique(df$periodico)), "\n")
  cat("Anos:", length(unique(df$ano)), "\n")

  return(list(univariada_ano = df %>% count(ano)))
}

auditar_sucupira <- function(prog, docs) {
  message("\n>>> AUDITORIA SUCUPIRA (Programas: ", ifelse(is.null(prog), "NA", nrow(prog)),
          " | Docentes: ", ifelse(is.null(docs), "NA", nrow(docs)), ")")

  # Detecta colunas de ano dinamicamente
  col_ano_prog <- if ("an_base" %in% names(prog)) "an_base" else if ("ano_base" %in% names(prog)) "ano_base" else NULL
  col_ano_doc  <- if ("an_base" %in% names(docs)) "an_base" else if ("ano_base" %in% names(docs)) "ano_base" else "ano_fonte"

  if (!is.null(prog) && nrow(prog) > 0) {
    cat("--- PROGRAMAS ---\n")
    anos_prog <- if (!is.null(col_ano_prog)) sort(unique(prog[[col_ano_prog]])) else "N/A"
    cat("Anos:", paste(anos_prog, collapse=", "), "\n")
    cat("Programas únicos (CD_PROGRAMA_IES):", length(unique(prog$cd_programa_ies)), "\n")
    cat("IES únicas:", length(unique(prog$cd_entidade_capes)), "\n")
    cat("Estados:", length(unique(prog$sg_uf_programa)), "\n")
    cat("Conceitos:", paste(sort(unique(prog$cd_conceito_programa)), collapse=", "), "\n")
    cat("Graus:", paste(sort(unique(prog$nm_grau_programa)), collapse=", "), "\n")
    cat("Situação:", paste(sort(unique(prog$ds_situacao_programa)), collapse=", "), "\n")

    # Faltantes
    vars_p <- intersect(c("nm_programa_ies", "nm_area_avaliacao", "cd_conceito_programa",
                          "ano_inicio_programa", "sg_uf_programa", "nm_grau_programa"), names(prog))
    if (length(vars_p) > 0) {
      print(prog %>% summarise(across(any_of(vars_p), ~ mean(is.na(.)))))
    }
  }

  if (!is.null(docs) && nrow(docs) > 0) {
    cat("--- DOCENTES ---\n")
    anos_doc <- if (col_ano_doc %in% names(docs)) sort(unique(docs[[col_ano_doc]])) else "N/A"
    cat("Anos:", paste(anos_doc, collapse=", "), "\n")
    cat("Docentes únicos:", length(unique(docs$nm_docente)), "\n")
    cat("Instituições:", length(unique(docs$sg_entidade_ensino)), "\n")
    # Categoria docente pode variar: ds_categoria_docente, nm_categoria_docente
    col_cat <- if ("ds_categoria_docente" %in% names(docs)) "ds_categoria_docente" else if ("nm_categoria_docente" %in% names(docs)) "nm_categoria_docente" else NULL
    if (!is.null(col_cat)) {
      cat("Categorias:", paste(sort(unique(docs[[col_cat]])), collapse=", "), "\n")
    } else {
      cat("Categorias: (coluna não encontrada)\n")
    }
  }

  return(list())
}

# -----------------------------------------------------------------------------
# 3. Executa auditorias (capturando a saída para o relatório; a saída também
#    segue para o console via tee)
# -----------------------------------------------------------------------------
resultados <- list()

# Captura TODA a saída (prints das funções auditar_*) em arquivo de texto
out_rds <- file.path(dir_relatorios, paste0("protocolo_eda_", Sys.Date(), ".rds"))
out_txt <- file.path(dir_relatorios, paste0("protocolo_eda_", Sys.Date(), ".txt"))

con <- file(out_txt, "wt")
sink(con, type = "output")

cat("================================================================================\n")
cat("PROTOCOLO EXPLORATÓRIO OBRIGATÓRIO — CAMADA 2\n")
cat("Projeto: História, Expansão e Institucionalização da Ciência Política no Brasil\n")
cat("Data:", as.character(Sys.Date()), "\n")
cat("================================================================================\n")

if (!is.null(capes))   resultados$capes   <- auditar_capes(capes)
if (!is.null(openalex)) resultados$openalex <- auditar_openalex(openalex)
if (!is.null(prog) || !is.null(docs)) resultados$sucupira <- auditar_sucupira(prog, docs)

cat("\n\nFIM DO RELATÓRIO.\n")
sink(type = "output")
close(con)

saveRDS(resultados, out_rds)

message(">>> RELATÓRIO SALVO EM: ", out_txt)
message(">>> PROTOCOLO CONCLUÍDO.")