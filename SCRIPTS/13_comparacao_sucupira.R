#!/usr/bin/env Rscript
# ==============================================================================
# 13_comparacao_sucupira.R — Estrutura comparada da pós-graduação
# ==============================================================================
# Reutiliza os microdados Sucupira já baixados para comparar Economia (28),
# Sociologia (34), Antropologia/Arqueologia (35), Geografia (36),
# Ciência Política e RI (39) e História (40), entre 2013 e 2024.
#
# CORREÇÃO 2026-09-02 (P0, REVISAO_CRITICA F01): a versão anterior deste script
# usava os códigos 36/38/39/40/41/42. Conferido contra `NM_AREA_AVALIACAO` nos
# 12 arquivos brutos `sucupira_prog_20XX.csv`, esses códigos correspondem, na
# verdade, a Geografia (36), EDUCAÇÃO (38), CP/RI (39), HISTÓRIA (40),
# LETRAS/LINGUÍSTICA — depois LINGUÍSTICA E LITERATURA (41) e CIÊNCIAS
# AGRÁRIAS I (42). Os rótulos de quatro das seis áreas comparadas estavam,
# portanto, trocados. Os códigos abaixo foram verificados como ESTÁVEIS em
# todas as safras 2013–2024 (ver asserção `checar_codigos_area()`), o que
# permite manter o código numérico como chave; a asserção falha se a
# numeração mudar em alguma safra futura.
#
# Unidades de análise:
# - Programas: programa-ano, deduplicado pelo código do programa;
# - Docentes: docente-programa-ano, deduplicado por ID_PESSOA;
# - Conceitos: programa-ano com conceito numérico válido (o valor "A",
#   atribuído a programas novos, é reportado à parte, não como NA silencioso).
# ==============================================================================

source(here::here("SCRIPTS", "00_setup.R"))

areas_alvo <- c(
  "28" = "Economia",
  "34" = "Sociologia",
  "35" = "Antropologia / Arqueologia",
  "36" = "Geografia",
  "39" = "Ciência Política / RI",
  "40" = "História"
)
# Padrão esperado em NM_AREA_AVALIACAO para cada código (asserção de safra).
padrao_area <- c(
  "28" = "ECONOMIA", "34" = "SOCIOLOGIA", "35" = "ANTROPOLOGIA",
  "36" = "GEOGRAFIA", "39" = "CI.NCIA POL.TICA", "40" = "HIST.RIA"
)
ordem_areas <- unname(areas_alvo)

raw_dir <- here::here("DADOS", "raw", "sucupira_ppgs")
tab_dir <- here::here("TABELAS")
fig_dir <- here::here("FIGURAS")
proc_dir <- here::here("DADOS", "processed")
dir.create(tab_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(proc_dir, recursive = TRUE, showWarnings = FALSE)

# Dados Sucupira têm campos que variam um pouco entre safras. Esta função usa
# apenas colunas presentes e padroniza as que sustentam indicadores comparáveis.
ler_csv_sucupira <- function(path) {
  suppressWarnings(
    read_delim(path, delim = ";", locale = locale(encoding = "Latin1"),
               show_col_types = FALSE, guess_max = 100000)
  ) %>% clean_names()
}

pegar <- function(df, col, default = NA_character_) {
  if (col %in% names(df)) as.character(df[[col]]) else rep(default, nrow(df))
}

# Asserção de estabilidade da numeração das áreas de avaliação. Falha alto e
# cedo se a CAPES renumerar uma área em alguma safra — nesse caso o script deve
# passar a usar `nm_area_avaliacao` (texto) em vez do código.
checar_codigos_area <- function(df, ano) {
  if (!all(c("cd_area_avaliacao", "nm_area_avaliacao") %in% names(df))) {
    stop("Safra ", ano, " sem cd/nm_area_avaliacao — impossível validar códigos.")
  }
  chk <- df %>%
    transmute(cd = as.character(cd_area_avaliacao),
              nm = toupper(as.character(nm_area_avaliacao))) %>%
    filter(cd %in% names(areas_alvo)) %>%
    distinct()
  for (cd in names(padrao_area)) {
    nms <- chk$nm[chk$cd == cd]
    if (length(nms) == 0L) stop("Safra ", ano, ": código de área ", cd, " ausente.")
    if (!all(grepl(padrao_area[[cd]], nms))) {
      stop("Safra ", ano, ": código ", cd, " esperava /", padrao_area[[cd]],
           "/ mas encontrou '", paste(nms, collapse = "; "), "'.")
    }
  }
  invisible(TRUE)
}

padronizar_programas <- function(ano) {
  path <- file.path(raw_dir, paste0("sucupira_prog_", ano, ".csv"))
  if (!file.exists(path)) return(NULL)
  df <- ler_csv_sucupira(path)
  checar_codigos_area(df, ano)
  df %>%
    transmute(
      ano = suppressWarnings(as.integer(pegar(df, "an_base", ano))),
      area_codigo = pegar(df, "cd_area_avaliacao"),
      area_nome = unname(areas_alvo[pegar(df, "cd_area_avaliacao")]),
      programa = pegar(df, "cd_programa_ies"),
      nome_programa = pegar(df, "nm_programa_ies"),
      ies = pegar(df, "sg_entidade_ensino"),
      nome_ies = pegar(df, "nm_entidade_ensino"),
      uf = pegar(df, "sg_uf_programa"),
      regiao = pegar(df, "nm_regiao"),
      modalidade = pegar(df, "nm_modalidade_programa"),
      grau = pegar(df, "nm_grau_programa"),
      conceito_raw = pegar(df, "cd_conceito_programa"),
      conceito = suppressWarnings(as.numeric(pegar(df, "cd_conceito_programa"))),
      ano_inicio = suppressWarnings(as.integer(coalesce(
        na_if(pegar(df, "an_inicio_programa"), ""),
        na_if(pegar(df, "ano_inicio_programa"), "")
      ))),
      situacao = pegar(df, "ds_situacao_programa")
    ) %>%
    filter(!is.na(area_nome), !is.na(programa), programa != "") %>%
    distinct(ano, programa, .keep_all = TRUE)
}

padronizar_docentes <- function(ano) {
  path <- file.path(raw_dir, paste0("sucupira_doc_", ano, ".csv"))
  if (!file.exists(path)) return(NULL)
  df <- ler_csv_sucupira(path)
  df %>%
    transmute(
      ano = suppressWarnings(as.integer(pegar(df, "an_base", ano))),
      area_codigo = pegar(df, "cd_area_avaliacao"),
      area_nome = unname(areas_alvo[pegar(df, "cd_area_avaliacao")]),
      programa = pegar(df, "cd_programa_ies"),
      docente_id = pegar(df, "id_pessoa"),
      categoria = pegar(df, "ds_categoria_docente"),
      vinculo = pegar(df, "ds_tipo_vinculo_docente_ies"),
      regime = pegar(df, "ds_regime_trabalho"),
      doutor = pegar(df, "in_doutor"),
      ano_titulacao = suppressWarnings(as.integer(pegar(df, "an_titulacao"))),
      grau_titulacao = pegar(df, "nm_grau_titulacao"),
      pais_titulacao = pegar(df, "nm_pais_ies_titulacao")
    ) %>%
    filter(!is.na(area_nome), !is.na(programa), programa != "", !is.na(docente_id), docente_id != "") %>%
    distinct(ano, area_nome, programa, docente_id, .keep_all = TRUE)
}

anos <- 2013:2024
programas <- purrr::map(anos, padronizar_programas) %>% compact() %>% bind_rows()
docentes <- purrr::map(anos, padronizar_docentes) %>% compact() %>% bind_rows()

if (nrow(programas) == 0L) stop("Não foi possível ler programas Sucupira.")

# Exclui programas com situação "EM DESATIVACAO" (impacto mínimo, mas
# fecha o item de auditoria sobre desativação contada como ativa).
programas <- programas %>% filter(is.na(situacao) | situacao != "EM DESATIVACAO")
# Modalidade normalizada (F02): o campo bruto traz "ACADÊMICO"/"PROFISSIONAL"
# com variações de acento entre safras.
programas <- programas %>%
  mutate(
    area_nome = factor(area_nome, levels = ordem_areas),
    modalidade_norm = if_else(grepl("PROFISSIONAL",
                                    toupper(iconv(modalidade, to = "ASCII//TRANSLIT", sub = ""))),
                              "PROFISSIONAL", "ACADEMICO"),
    grau_norm = toupper(iconv(grau, to = "ASCII//TRANSLIT", sub = ""))
  )
docentes <- docentes %>% mutate(area_nome = factor(area_nome, levels = ordem_areas))

# 1. Programas e composição institucional anual
programas_ano <- programas %>%
  group_by(ano, area_nome) %>%
  summarise(
    programas_ativos = n_distinct(programa),
    ies = n_distinct(ies[!is.na(ies) & ies != ""], na.rm = TRUE),
    ufs = n_distinct(uf[!is.na(uf) & uf != ""], na.rm = TRUE),
    programas_mestrado = sum(grepl("MESTR", grau_norm), na.rm = TRUE),
    programas_doutorado = sum(grepl("DOUTOR", grau_norm), na.rm = TRUE),
    programas_academicos = sum(modalidade_norm == "ACADEMICO", na.rm = TRUE),
    programas_profissionais = sum(modalidade_norm == "PROFISSIONAL", na.rm = TRUE),
    pct_profissionais = 100 * programas_profissionais / programas_ativos,
    conceito_medio = mean(conceito, na.rm = TRUE),
    conceito_mediano = median(conceito, na.rm = TRUE),
    .groups = "drop"
  )

# 1b. Modalidade e grau: tabelas longas área × ano × categoria (F02)
modalidade_ano <- programas %>%
  count(ano, area_nome, modalidade = modalidade_norm, name = "programas") %>%
  group_by(ano, area_nome) %>%
  mutate(participacao = programas / sum(programas)) %>%
  ungroup()

grau_ano <- programas %>%
  count(ano, area_nome, grau = grau_norm, name = "programas") %>%
  group_by(ano, area_nome) %>%
  mutate(participacao = programas / sum(programas)) %>%
  ungroup()

# 2. Docentes: únicas pessoas e vínculos programa-docente-ano
docentes_ano <- docentes %>%
  group_by(ano, area_nome) %>%
  summarise(
    docentes_unicos = n_distinct(docente_id),
    vinculos_docente_programa = n(),
    docentes_permanentes = n_distinct(docente_id[grepl("PERMANENTE", toupper(categoria))]),
    proporcao_doutores = mean(toupper(doutor) %in% c("S", "SIM", "YES"), na.rm = TRUE),
    .groups = "drop"
  )

# 3. Normalização dos indicadores: não infere qualidade; descreve capacidade
#    relativa. A métrica padrão CAPES é o corpo docente PERMANENTE (F11); o
#    total (todas as categorias) fica em coluna separada, não é o indicador
#    principal. Denominadores em programas ACADÊMICOS ficam à parte (F02).
indicadores_ano <- programas_ano %>%
  left_join(docentes_ano, by = c("ano", "area_nome")) %>%
  mutate(
    docentes_por_programa = docentes_permanentes / programas_ativos,
    docentes_totais_por_programa = docentes_unicos / programas_ativos,
    docentes_perm_por_programa_academico = docentes_permanentes /
      dplyr::na_if(programas_academicos, 0L),
    vinculos_por_programa = vinculos_docente_programa / programas_ativos
  )

# 4. Geografia e concentração institucional
geografia <- programas %>%
  count(ano, area_nome, regiao, name = "programas") %>%
  group_by(ano, area_nome) %>%
  mutate(participacao_regional = programas / sum(programas)) %>%
  ungroup()

concentracao_ies <- programas %>%
  count(ano, area_nome, ies, name = "programas_ies") %>%
  group_by(ano, area_nome) %>%
  summarise(
    programas = sum(programas_ies),
    maior_ies_programas = max(programas_ies),
    participacao_maior_ies = maior_ies_programas / programas,
    hhi_ies = sum((programas_ies / programas)^2),
    .groups = "drop"
  )

# 5. Conceitos CAPES: distribuição anual comparável.
conceitos <- programas %>%
  filter(!is.na(conceito)) %>%
  count(ano, area_nome, conceito, name = "programas") %>%
  group_by(ano, area_nome) %>%
  mutate(participacao = programas / sum(programas)) %>%
  ungroup()

# 5b. Distribuição de conceitos como perfil (F11): a média de uma escala
#     ordinal não é comparável entre áreas com distribuições distintas. Reporta
#     proporções por faixa e o n de programas com conceito "A" (programas novos,
#     sem nota numérica), que a média silenciosamente descartava.
conceitos_dist <- programas %>%
  group_by(ano, area_nome) %>%
  summarise(
    n_programas = n(),
    n_A = sum(toupper(trimws(conceito_raw)) == "A", na.rm = TRUE),
    n_conceito_numerico = sum(!is.na(conceito)),
    prop_3 = mean(conceito == 3, na.rm = TRUE),
    prop_4 = mean(conceito == 4, na.rm = TRUE),
    prop_5 = mean(conceito == 5, na.rm = TRUE),
    prop_6_7 = mean(conceito >= 6, na.rm = TRUE),
    .groups = "drop"
  )

# 6. Entradas líquidas por código de programa, observadas na janela.
entradas <- programas %>%
  distinct(area_nome, programa, ano) %>%
  group_by(area_nome, programa) %>%
  summarise(primeiro_ano_observado = min(ano), ultimo_ano_observado = max(ano), .groups = "drop") %>%
  count(area_nome, primeiro_ano_observado, name = "novos_programas_observados") %>%
  rename(ano = primeiro_ano_observado)

# Saídas tabulares
write_csv(indicadores_ano, file.path(tab_dir, "tabela_comparacao_programas_sucupira.csv"))
write_csv(geografia, file.path(tab_dir, "tabela_comparacao_geografia_sucupira.csv"))
write_csv(conceitos, file.path(tab_dir, "tabela_comparacao_conceitos_sucupira.csv"))
write_csv(conceitos_dist, file.path(tab_dir, "tabela_comparacao_conceitos_distribuicao.csv"))
write_csv(concentracao_ies, file.path(tab_dir, "tabela_comparacao_concentracao_ies.csv"))
write_csv(entradas, file.path(tab_dir, "tabela_comparacao_entradas_programas.csv"))
write_csv(modalidade_ano, file.path(tab_dir, "tabela_comparacao_modalidade.csv"))
write_csv(grau_ano, file.path(tab_dir, "tabela_comparacao_grau.csv"))
# Mantém a tabela original como compatibilidade com o manuscrito já existente.
write_csv(select(programas_ano, ano, area_nome, programas_ativos),
          file.path(tab_dir, "tabela_comparacao_areas_sucupira_prog.csv"))

# Objeto canônico da comparação. Os nomes `area`/`programas` em `$programas_ano`
# e `$modalidade` são os que `SCRIPTS/99_testes_regressao.R` verifica.
comp_obj <- list(
  programas = programas, docentes = docentes, indicadores = indicadores_ano,
  geografia = geografia, conceitos = conceitos, conceitos_dist = conceitos_dist,
  concentracao_ies = concentracao_ies,
  programas_ano = programas_ano %>%
    transmute(ano, area = as.character(area_nome), programas = programas_ativos),
  modalidade = modalidade_ano %>%
    transmute(ano, area = as.character(area_nome), modalidade, programas, participacao),
  grau = grau_ano %>%
    transmute(ano, area = as.character(area_nome), grau, programas, participacao)
)
saveRDS(comp_obj, file.path(proc_dir, "comparacao_areas_sucupira.rds"))

# -----------------------------------------------------------------------------
# Valores inline do manuscrito (substitui o órfão
# `valores_inline_comparacao_areas.rds`, que não era lido por nenhum .qmd e
# fora computado antes do filtro de desativação — ver REVISAO_CRITICA F27).
# -----------------------------------------------------------------------------
ano_max <- max(indicadores_ano$ano)
ind_max <- indicadores_ano %>% filter(ano == ano_max)
ind_min <- indicadores_ano %>% filter(ano == min(ano))
get_v <- function(df, col, area) df[[col]][as.character(df$area_nome) == area]

v_comp <- list(
  ano_inicial = min(indicadores_ano$ano),
  ano_final = ano_max,
  programas_2024 = setNames(ind_max$programas_ativos, as.character(ind_max$area_nome)),
  programas_2013 = setNames(ind_min$programas_ativos, as.character(ind_min$area_nome)),
  docentes_perm_2024 = setNames(ind_max$docentes_permanentes, as.character(ind_max$area_nome)),
  ufs_2024 = setNames(ind_max$ufs, as.character(ind_max$area_nome)),
  pct_prof_2024 = setNames(round(ind_max$pct_profissionais, 1), as.character(ind_max$area_nome)),
  pct_prof_2013 = setNames(round(ind_min$pct_profissionais, 1), as.character(ind_min$area_nome)),
  # Variação relativa de programas entre a primeira e a última safra Sucupira.
  var_programas_pct = setNames(
    round(100 * (ind_max$programas_ativos[match(as.character(ind_min$area_nome),
                                                as.character(ind_max$area_nome))] /
                   ind_min$programas_ativos - 1), 1),
    as.character(ind_min$area_nome)),
  n_areas = length(ordem_areas)
)
v_comp$posicao_area39_programas_2024 <- unname(
  rank(-v_comp$programas_2024, ties.method = "min")[["Ciência Política / RI"]])
v_comp$area_maior_crescimento <- names(which.max(v_comp$var_programas_pct))
saveRDS(v_comp, file.path(proc_dir, "valores_inline_comparacao.rds"))
# Remove o artefato órfão da rodada anterior, se ainda existir.
orfao <- file.path(proc_dir, "valores_inline_comparacao_areas.rds")
if (file.exists(orfao)) file.remove(orfao)

# Figuras: a identidade de cada área permanece constante na paleta Dark2;
# escalas e facetas evitam duplo eixo e mostram magnitude sem ocultar a CP.
p_programas <- ggplot(indicadores_ano, aes(ano, programas_ativos, colour = area_nome)) +
  geom_line(linewidth = .9) + geom_point(size = 1.4) +
  scale_x_continuous(breaks = seq(2013, 2024, 2)) +
  scale_y_continuous(limits = c(0, NA)) + scale_colour_brewer(palette = "Dark2") +
  labs(title = "Programas de Pós-Graduação por Área de Avaliação",
       subtitle = "Áreas irmãs selecionadas, 2013–2024", x = "Ano", y = "Programas ativos",
       colour = "Área", caption = "Fonte: Plataforma Sucupira/CAPES. Elaboração própria.") + theme_artigo()

ggsave(file.path(fig_dir, "fig10_comparacao_ppg_areas.png"), p_programas, width = 8.5, height = 5.2, dpi = 300)

p_docentes <- indicadores_ano %>%
  pivot_longer(c(docentes_unicos, programas_ativos), names_to = "medida", values_to = "valor") %>%
  mutate(medida = recode(medida, docentes_unicos = "Docentes únicos", programas_ativos = "Programas ativos")) %>%
  ggplot(aes(ano, valor, colour = area_nome)) +
  geom_line(linewidth = .8) + geom_point(size = 1.2) +
  facet_wrap(~medida, scales = "free_y", ncol = 1) +
  scale_x_continuous(breaks = seq(2013, 2024, 2)) + scale_colour_brewer(palette = "Dark2") +
  labs(title = "Capacidade Institucional das Áreas de Pós-Graduação",
       subtitle = "Programas e docentes únicos, 2013–2024", x = "Ano", y = NULL,
       colour = "Área", caption = "Fonte: Plataforma Sucupira/CAPES. Docentes deduplicados por ID_PESSOA em cada área-ano.") + theme_artigo()

ggsave(file.path(fig_dir, "fig12_comparacao_docentes_programas.png"), p_docentes, width = 8.5, height = 7, dpi = 300)

p_conceito <- conceitos %>%
  mutate(conceito = factor(conceito)) %>%
  ggplot(aes(ano, participacao, fill = conceito)) +
  geom_col(width = .75, colour = "white", linewidth = .25) +
  facet_wrap(~area_nome, ncol = 2) +
  scale_y_continuous(labels = scales::percent_format(), limits = c(0, 1)) +
  scale_fill_brewer(palette = "Blues", direction = 1) +
  labs(title = "Composição dos Conceitos CAPES por Área",
       subtitle = "Participação dos programas por conceito em cada ano", x = "Ano", y = "Participação",
       fill = "Conceito",
       caption = "Fonte: Plataforma Sucupira/CAPES. Programas com conceito \"A\" (nota atribuída a cursos novos, não numérica) e valores ausentes ficam fora do denominador; ver tabela_comparacao_conceitos_distribuicao.csv.") + theme_artigo()

ggsave(file.path(fig_dir, "fig13_comparacao_conceitos_capes.png"), p_conceito, width = 8.5, height = 7, dpi = 300)

p_geografia <- geografia %>%
  filter(!is.na(regiao), regiao != "") %>%
  ggplot(aes(ano, participacao_regional, fill = regiao)) +
  geom_area(position = "stack", alpha = .9) +
  facet_wrap(~area_nome, ncol = 2) +
  scale_y_continuous(labels = scales::percent_format(), limits = c(0, 1)) +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "Distribuição Regional dos Programas por Área",
       subtitle = "Composição relativa da oferta de pós-graduação, 2013–2024", x = "Ano", y = "Participação",
       fill = "Região", caption = "Fonte: Plataforma Sucupira/CAPES. Elaboração própria.") + theme_artigo()

ggsave(file.path(fig_dir, "fig14_comparacao_geografia_ppg.png"), p_geografia, width = 8.5, height = 7, dpi = 300)

cat("Comparação Sucupira concluída: ", nrow(programas), " programa-anos e ", nrow(docentes), " vínculos docente-programa-ano.\n", sep = "")
