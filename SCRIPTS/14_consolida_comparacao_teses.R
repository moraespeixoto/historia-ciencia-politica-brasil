#!/usr/bin/env Rscript
# Consolida a comparação das áreas irmãs a partir do Catálogo CAPES.
# A classificação usa primeiro os códigos de área do layout antigo e,
# no layout novo, a área de avaliação/nome do programa como fallback.
source(here::here("SCRIPTS", "00_setup.R"))

dir_raw <- here::here("DADOS", "raw", "capes_teses_comparada")
dir_processed <- here::here("DADOS", "processed")
dir_tabelas <- here::here("TABELAS")
dir_fig <- here::here("FIGURAS")

arquivos <- list.files(dir_raw, pattern = "^capes_comparada_[0-9]{4}\\.tsv$", full.names = TRUE)
if (length(arquivos) == 0) stop("Nenhum arquivo TSV encontrado.")

normaliza <- function(x) toupper(iconv(replace_na(as.character(x), ""), to = "ASCII//TRANSLIT", sub = ""))

classifica_area <- function(df) {
  codigo <- as.character(df$area_conhecimento_codigo %||% "")
  area <- normaliza(df$area_avaliacao %||% "")
  programa <- normaliza(df$nome_programa %||% "")
  # Códigos CNPq do layout 1987--2012: 7020 Sociologia, 7030
  # Antropologia, 7050 História, 7060 Geografia, 6030 Economia e
  # 7090 Ciência Política/RI. O prefixo é usado para acomodar subníveis.
  codigo_area <- case_when(
    grepl("^7020", codigo) ~ "Sociologia",
    grepl("^7030", codigo) ~ "Antropologia / Arqueologia",
    grepl("^7050", codigo) ~ "História",
    grepl("^7060", codigo) ~ "Geografia",
    grepl("^6030", codigo) ~ "Economia",
    grepl("^7090", codigo) ~ "Ciência Política / RI",
    TRUE ~ NA_character_
  )
  # No layout novo, AreaAvaliacao é a âncora administrativa. O nome do
  # programa só resolve registros sem área preenchida.
  case_when(
    !is.na(codigo_area) ~ codigo_area,
    grepl("SOCIOLOGIA", area) ~ "Sociologia",
    grepl("ANTROPOLOGIA", area) ~ "Antropologia / Arqueologia",
    grepl("HISTORIA", area) ~ "História",
    grepl("GEOGRAFIA", area) ~ "Geografia",
    grepl("ECONOMIA", area) ~ "Economia",
    grepl("CIENCIA POLITICA|RELACOES INTERNACIONAIS", area) ~ "Ciência Política / RI",
    grepl("SOCIOLOGIA", programa) & !grepl("CIENCIA POLITICA", programa) ~ "Sociologia",
    grepl("ANTROPOLOGIA", programa) ~ "Antropologia / Arqueologia",
    grepl("HISTORIA", programa) & !grepl("GEOGRAFIA|SOCIOLOGIA|FILOSOFIA", programa) ~ "História",
    grepl("GEOGRAFIA", programa) ~ "Geografia",
    grepl("ECONOMIA", programa) & !grepl("POLITICA", programa) ~ "Economia",
    grepl("CIENCIA POLITICA|RELACOES INTERNACIONAIS", programa) ~ "Ciência Política / RI",
    TRUE ~ "Não identificado"
  ) %>%
  stringr::str_replace("^Antropologia$", "Antropologia / Arqueologia")
}

ler_safra <- function(f) {
  df <- tryCatch(
    suppressWarnings(read_delim(f, delim = ";", locale = locale(encoding = "Latin1"),
                                 show_col_types = FALSE, guess_max = 100000)),
    error = function(e) NULL
  )
  if (is.null(df) || nrow(df) == 0) return(NULL)
  df <- clean_names(df)
  # Os arquivos de 1987--2012 e 2013--2024 têm layouts distintos.
  # Antes de classificá-los, criamos uma camada de nomes canônicos.
  if (!any(c("ano_base", "an_base") %in% names(df))) return(NULL)
  canonica <- tibble(
    ano = suppressWarnings(as.integer(coalesce(
      if ("ano_base" %in% names(df)) as.character(df$ano_base) else rep(NA_character_, nrow(df)),
      if ("an_base" %in% names(df)) as.character(df$an_base) else rep(NA_character_, nrow(df))
    ))),
    area_conhecimento_codigo = coalesce(
      if ("area_conhecimento_codigo" %in% names(df)) as.character(df$area_conhecimento_codigo) else rep(NA_character_, nrow(df)),
      if ("cd_area_conhecimento" %in% names(df)) as.character(df$cd_area_conhecimento) else rep(NA_character_, nrow(df))
    ),
    area_avaliacao = coalesce(
      if ("area_avaliacao" %in% names(df)) as.character(df$area_avaliacao) else rep(NA_character_, nrow(df)),
      if ("nm_area_avaliacao" %in% names(df)) as.character(df$nm_area_avaliacao) else rep(NA_character_, nrow(df))
    ),
    nome_programa = coalesce(
      if ("nome_programa" %in% names(df)) as.character(df$nome_programa) else rep(NA_character_, nrow(df)),
      if ("nm_programa" %in% names(df)) as.character(df$nm_programa) else rep(NA_character_, nrow(df))
    ),
    nivel_raw = coalesce(
      if ("nivel" %in% names(df)) as.character(df$nivel) else rep(NA_character_, nrow(df)),
      if ("nm_grau_academico" %in% names(df)) as.character(df$nm_grau_academico) else rep(NA_character_, nrow(df))
    ),
    discente_id = coalesce(
      if ("documento_discente" %in% names(df)) as.character(df$documento_discente) else rep(NA_character_, nrow(df)),
      if ("id_pessoa_discente" %in% names(df)) as.character(df$id_pessoa_discente) else rep(NA_character_, nrow(df))
    ),
    uf = coalesce(
      if ("uf" %in% names(df)) as.character(df$uf) else rep(NA_character_, nrow(df)),
      if ("sg_uf_ies" %in% names(df)) as.character(df$sg_uf_ies) else rep(NA_character_, nrow(df))
    ),
    regiao = coalesce(
      if ("regiao" %in% names(df)) as.character(df$regiao) else rep(NA_character_, nrow(df)),
      if ("nm_regiao" %in% names(df)) as.character(df$nm_regiao) else rep(NA_character_, nrow(df))
    ),
    sigla_ies = coalesce(
      if ("sigla_ies" %in% names(df)) as.character(df$sigla_ies) else rep(NA_character_, nrow(df)),
      if ("sg_entidade_ensino" %in% names(df)) as.character(df$sg_entidade_ensino) else rep(NA_character_, nrow(df))
    ),
    nome_ies = coalesce(
      if ("nome_ies" %in% names(df)) as.character(df$nome_ies) else rep(NA_character_, nrow(df)),
      if ("nm_entidade_ensino" %in% names(df)) as.character(df$nm_entidade_ensino) else rep(NA_character_, nrow(df))
    ),
    autor = coalesce(
      if ("autor" %in% names(df)) as.character(df$autor) else rep(NA_character_, nrow(df)),
      if ("nm_discente" %in% names(df)) as.character(df$nm_discente) else rep(NA_character_, nrow(df))
    ),
    titulo = coalesce(
      if ("titulo_tese" %in% names(df)) as.character(df$titulo_tese) else rep(NA_character_, nrow(df)),
      if ("nm_producao" %in% names(df)) as.character(df$nm_producao) else rep(NA_character_, nrow(df))
    )
  )
  canonica %>%
    mutate(
      area_nome = classifica_area(.),
      nivel_norm = case_when(
        grepl("DOUTOR", normaliza(nivel_raw)) ~ "Doutorado",
        grepl("MESTR", normaliza(nivel_raw)) ~ "Mestrado",
        TRUE ~ "Não informado"
      ),
      # Nas safras 1987-1995 (e em RGs mascarados de outras safras), o
      # identificador do discente vem sanitizado como sequência de dígitos
      # repetidos/asteriscos (ex.: "999*****999"), igual para todo o
      # arquivo. Usado como chave, isso colapsa cada área-ano em 1-2
      # registros. Tratamos como ausente qualquer valor sem dígitos
      # suficientes ou dominado por 9/0/asterisco e caímos na chave
      # composta (ano+IES+autor+título), que é robusta a esse problema.
      discente_id_valido = !is.na(discente_id) & discente_id != "" &
        !grepl("^[9*]+$", discente_id) & !grepl("^[0*]+$", discente_id) &
        nchar(gsub("[^0-9]", "", discente_id)) >= 6,
      chave_trabalho = if_else(discente_id_valido,
                               discente_id,
                               paste(ano, normaliza(sigla_ies), normaliza(autor),
                                     normaliza(titulo), sep = "|"))
    ) %>%
    select(ano, area_nome, nivel = nivel_norm, chave_trabalho,
           uf, regiao, sigla_ies, nome_ies, nome_programa)
}

base <- purrr::map(arquivos, ler_safra) %>% compact() %>% bind_rows() %>%
  distinct(ano, area_nome, chave_trabalho, .keep_all = TRUE)

# Série por área e grau; inclui também identificados para tornar a auditoria visível.
resumo <- base %>%
  count(ano, area_nome, nivel, name = "titulos") %>%
  arrange(ano, area_nome, nivel)
# Completa a grade área-ano-nível para que joins com Sucupira não produzam
# ausências artificiais quando uma área tem zero registros em uma safra.
resumo <- tidyr::complete(
  resumo,
  ano = 1987:2024,
  area_nome = c("Geografia", "Economia", "Ciência Política / RI", "Sociologia", "Antropologia / Arqueologia", "História", "Não identificado"),
  nivel = c("Mestrado", "Doutorado", "Não informado"),
  fill = list(titulos = 0)
)
write_csv(resumo, file.path(dir_tabelas, "tabela_comparacao_titulos_capes.csv"))
saveRDS(resumo, file.path(dir_processed, "tabela_comparacao_titulos_capes.rds"))

# Métricas acumuladas, crescimento e composição do último ano observado.
metricas <- base %>%
  filter(area_nome != "Não identificado") %>%
  count(ano, area_nome, name = "titulos") %>%
  group_by(area_nome) %>%
  summarise(
    total_1987_2024 = sum(titulos),
    primeiro_ano = min(ano), ultimo_ano = max(ano),
    titulos_primeiro_ano = titulos[which.min(ano)],
    titulos_ultimo_ano = titulos[which.max(ano)],
    crescimento_relativo = titulos_ultimo_ano / titulos_primeiro_ano - 1,
    .groups = "drop"
  ) %>% arrange(desc(total_1987_2024))
write_csv(metricas, file.path(dir_tabelas, "tabela_comparacao_metricas_capes.csv"))

# Auditoria de cobertura e registros que dependem de fallback textual.
auditoria <- base %>% count(ano, area_nome, name = "registros")
write_csv(auditoria, file.path(dir_tabelas, "tabela_auditoria_comparacao_capes.csv"))

resumo_plot <- base %>% filter(area_nome != "Não identificado") %>% count(ano, area_nome, name = "titulos")
p <- ggplot(resumo_plot, aes(x = ano, y = titulos, color = area_nome)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 1.4) +
  scale_x_continuous(breaks = seq(1987, 2024, by = 5)) +
  scale_y_continuous(labels = num_ptbr()) +
  scale_colour_brewer(palette = "Dark2", name = "Área") +
  labs(title = "Titulações na Pós-Graduação: Ciência Política e Áreas Irmãs",
       subtitle = "Total anual de mestrados e doutorados identificados no Catálogo CAPES",
       x = "Ano", y = "Títulos", color = "Área",
       caption = "Fonte: Catálogo CAPES. Classificação por códigos de área e, quando necessário, área/programa.") +
  theme_artigo()
ggsave(file.path(dir_fig, "fig11_comparacao_titulos_capes.png"), p, width = 8.5, height = 5.2, dpi = 300)

# Painel integrado com a capacidade institucional Sucupira na janela comum.
suc_path <- file.path(dir_tabelas, "tabela_comparacao_programas_sucupira.csv")
if (file.exists(suc_path)) {
  suc <- read_csv(suc_path, show_col_types = FALSE) %>%
    select(ano, area_nome, programas_ativos, docentes_unicos, docentes_por_programa,
           conceito_medio, ufs, ies)
  titulos_total <- resumo %>%
    filter(area_nome != "Não identificado", nivel != "Não informado") %>%
    group_by(ano, area_nome) %>%
    summarise(titulos = sum(titulos), .groups = "drop")
  titulos_nivel <- resumo %>%
    filter(area_nome != "Não identificado", nivel %in% c("Mestrado", "Doutorado")) %>%
    tidyr::pivot_wider(names_from = nivel, values_from = titulos, values_fill = 0)
  painel <- suc %>% left_join(titulos_total, by = c("ano", "area_nome")) %>%
    left_join(titulos_nivel, by = c("ano", "area_nome")) %>%
    mutate(titulos_por_programa = titulos / programas_ativos,
           titulos_por_docente = titulos / docentes_unicos,
           razao_doutorado_mestrado = if_else(Mestrado > 0, Doutorado / Mestrado, NA_real_))
  write_csv(painel, file.path(dir_tabelas, "tabela_comparacao_painel_integrado.csv"))

  p_nivel <- titulos_nivel %>%
    pivot_longer(c(Mestrado, Doutorado), names_to = "nivel", values_to = "titulos") %>%
    ggplot(aes(ano, titulos, colour = area_nome)) +
    geom_line(linewidth = .8) + geom_point(size = 1.1) +
    facet_wrap(~nivel, scales = "free_y", ncol = 1) +
    scale_x_continuous(breaks = seq(2013, 2024, 2)) + scale_colour_brewer(palette = "Dark2") +
    labs(title = "Mestrados e Doutorados nas Áreas Irmãs",
         subtitle = "Janela comum com os microdados de programas e docentes, 2013–2024",
         x = "Ano", y = "Títulos", colour = "Área",
         caption = "Fonte: Catálogo CAPES. Classificação por códigos de área e âncoras administrativas disponíveis.") + theme_artigo()
  ggsave(file.path(dir_fig, "fig15_comparacao_titulos_por_nivel.png"), p_nivel, width = 8.5, height = 7, dpi = 300)

  p_intensidade <- painel %>%
    ggplot(aes(ano, titulos_por_programa, colour = area_nome)) +
    geom_line(linewidth = .9) + geom_point(size = 1.3) +
    scale_x_continuous(breaks = seq(2013, 2024, 2)) + scale_colour_brewer(palette = "Dark2") +
    labs(title = "Intensidade de Titulação por Programa",
         subtitle = "Títulos registrados no Catálogo CAPES por programa ativo na Sucupira",
         x = "Ano", y = "Títulos por programa", colour = "Área",
         caption = "Fonte: CAPES/Sucupira. Indicador descritivo; não mede qualidade nem produtividade individual.") + theme_artigo()
  ggsave(file.path(dir_fig, "fig16_comparacao_intensidade_titulacao.png"), p_intensidade, width = 8.5, height = 5.2, dpi = 300)
}

print(metricas)
cat("Registros processados:", nrow(base), "\n")
