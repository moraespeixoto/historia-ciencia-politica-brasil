#!/usr/bin/env Rscript
# ==============================================================================
# 13_comparacao_sucupira.R — Estrutura comparada da pós-graduação (áreas 38–43)
# ==============================================================================
# Reutiliza os microdados Sucupira já baixados para comparar Geografia (36),
# Economia (38), Ciência Política e RI (39), Sociologia (40),
# Antropologia/Arqueologia (41) e História (42), entre 2013 e 2024.
#
# Unidades de análise:
# - Programas: programa-ano, deduplicado pelo código do programa;
# - Docentes: docente-programa-ano, deduplicado por ID_PESSOA;
# - Conceitos: programa-ano com conceito numérico válido.
# ==============================================================================

source(here::here("SCRIPTS", "00_setup.R"))

areas_alvo <- c(
  "36" = "Geografia",
  "38" = "Economia",
  "39" = "Ciência Política / RI",
  "40" = "Sociologia",
  "41" = "Antropologia / Arqueologia",
  "42" = "História"
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

padronizar_programas <- function(ano) {
  path <- file.path(raw_dir, paste0("sucupira_prog_", ano, ".csv"))
  if (!file.exists(path)) return(NULL)
  df <- ler_csv_sucupira(path)
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
programas <- programas %>% mutate(area_nome = factor(area_nome, levels = ordem_areas))
docentes <- docentes %>% mutate(area_nome = factor(area_nome, levels = ordem_areas))

# 1. Programas e composição institucional anual
programas_ano <- programas %>%
  group_by(ano, area_nome) %>%
  summarise(
    programas_ativos = n_distinct(programa),
    ies = n_distinct(ies[!is.na(ies) & ies != ""], na.rm = TRUE),
    ufs = n_distinct(uf[!is.na(uf) & uf != ""], na.rm = TRUE),
    programas_mestrado = sum(grepl("MESTR", toupper(grau)), na.rm = TRUE),
    programas_doutorado = sum(grepl("DOUTOR", toupper(grau)), na.rm = TRUE),
    programas_profissionais = sum(grepl("PROFISSIONAL", toupper(modalidade)), na.rm = TRUE),
    conceito_medio = mean(conceito, na.rm = TRUE),
    conceito_mediano = median(conceito, na.rm = TRUE),
    .groups = "drop"
  )

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

# 3. Normalização dos indicadores: não infere qualidade; descreve capacidade relativa.
indicadores_ano <- programas_ano %>%
  left_join(docentes_ano, by = c("ano", "area_nome")) %>%
  mutate(
    docentes_por_programa = docentes_unicos / programas_ativos,
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
write_csv(concentracao_ies, file.path(tab_dir, "tabela_comparacao_concentracao_ies.csv"))
write_csv(entradas, file.path(tab_dir, "tabela_comparacao_entradas_programas.csv"))
# Mantém a tabela original como compatibilidade com o manuscrito já existente.
write_csv(select(programas_ano, ano, area_nome, programas_ativos),
          file.path(tab_dir, "tabela_comparacao_areas_sucupira_prog.csv"))

saveRDS(
  list(programas = programas, docentes = docentes, indicadores = indicadores_ano,
       geografia = geografia, conceitos = conceitos, concentracao_ies = concentracao_ies),
  file.path(proc_dir, "comparacao_areas_sucupira.rds")
)

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
       fill = "Conceito", caption = "Fonte: Plataforma Sucupira/CAPES. Valores ausentes excluídos.") + theme_artigo()

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
