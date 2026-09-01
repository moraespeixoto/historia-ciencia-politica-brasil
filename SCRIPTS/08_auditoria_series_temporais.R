#!/usr/bin/env Rscript
# Unifica as duas chaves anuais da CAPES, exclui anos parciais e front matter
# do OpenAlex, e grava os valores inline do manuscrito (auditado em 2026-08-29).
source(here::here("SCRIPTS", "00_setup.R"))
dir_processed <- here::here("DADOS", "processed")
dir_tabelas <- here::here("TABELAS")
capes <- readRDS(file.path(dir_processed, "capes_cp_1987_2024.rds"))
openalex <- readRDS(file.path(dir_processed, "artigos_periodicos_openalex.rds"))
prog <- readRDS(file.path(dir_processed, "sucupira_programas_cp_2013_2024.rds"))
docs <- readRDS(file.path(dir_processed, "sucupira_docentes_cp_2013_2024.rds"))

capes_unif <- capes %>% mutate(ano_unificado = as.integer(coalesce(an_base, ano_base)))
# Filtro de integridade da área 39 (auditoria): exclui registros capturados por
# palavras-chave fora da área de avaliação. No layout antigo (1987-2012), a
# âncora é o código de área do conhecimento (7090); no layout novo
# (2013-2024), a âncora administrativa direta é `nm_area_avaliacao` (existe
# em todas as safras 2013+), com o crosswalk de códigos de programa da
# Sucupira como checagem de consistência, não como critério primário --
# ambos concordam em 8.662 de 8.663 registros (1 caso com área de avaliação
# NA no bruto, mas presente no crosswalk Sucupira, é mantido).
suc_cod <- unique(prog$cd_programa_ies)
capes <- capes %>%
  mutate(
    via_area_avaliacao = !is.na(nm_area_avaliacao) &
      nm_area_avaliacao == "CIÊNCIA POLÍTICA E RELAÇÕES INTERNACIONAIS",
    via_crosswalk_sucupira = cd_programa %in% suc_cod,
    em_area39 = if_else(!is.na(an_base),
                        via_area_avaliacao | via_crosswalk_sucupira,
                        grepl("^7090", area_conhecimento_codigo))
  )
n_excluidos <- sum(!capes$em_area39)
n_discordantes_area39 <- sum(!is.na(capes$an_base) & capes$via_area_avaliacao != capes$via_crosswalk_sucupira)
capes_ok <- capes %>% filter(em_area39)

capes_unif <- capes_ok %>% mutate(ano_unificado = as.integer(coalesce(an_base, ano_base)))
# Artefato canônico: as demais rotinas (05, 06, 07, 09, 10) devem ler este
# arquivo, já filtrado pela área 39, em vez de reimplementar o filtro.
saveRDS(capes_ok, file.path(dir_processed, "capes_cp_area39.rds"))
capes_serie <- capes_unif %>% filter(!is.na(ano_unificado)) %>% count(ano = ano_unificado, name = "titulos") %>% arrange(ano) %>% mutate(titulos_acum = cumsum(titulos))
# Exclui programas com DS_SITUACAO_PROGRAMA == "EM DESATIVACAO" (impacto
# mínimo -- no máximo 2 programas em um único ano, zero em 2024 -- mas
# fecha o item de auditoria sobre programas em desativação sendo contados
# como ativos; ver AUDITORIA.md §9).
prog_serie <- prog %>% filter(!is.na(an_base), is.na(ds_situacao_programa) | ds_situacao_programa != "EM DESATIVACAO") %>%
  group_by(ano = as.integer(an_base)) %>% summarise(programas_unicos = n_distinct(cd_programa_ies), ies_unicas = n_distinct(cd_entidade_capes), .groups = "drop") %>% arrange(ano)

# OpenAlex: apenas artigos de pesquisa (type == "article") e sem front matter,
# com corte em 2024 (anos 2025-2026 têm indexação incompleta).
artigos_serie_raw <- openalex %>%
  filter(!is.na(ano), tipo == "article", !front_matter) %>%
  count(ano = as.integer(ano), name = "artigos") %>%
  arrange(ano)
artigos_serie <- artigos_serie_raw %>% filter(ano <= 2024)
artigos_ano_per <- openalex %>%
  filter(!is.na(ano), ano <= 2024, tipo == "article", !front_matter) %>%
  count(ano = as.integer(ano), periodico, name = "artigos") %>%
  arrange(ano, periodico)

saveRDS(capes_serie, file.path(dir_processed, "capes_serie_anual.rds"))
saveRDS(prog_serie, file.path(dir_processed, "prog_serie_anual.rds"))
saveRDS(artigos_serie, file.path(dir_processed, "artigos_serie_anual.rds"))
saveRDS(capes_unif, file.path(dir_processed, "capes_cp_1987_2024_unificado.rds"))

v <- list(
 total_titulos_cap = sum(capes_serie$titulos), total_titulos_com_na = nrow(capes_unif), primeiro_ano_titulos = min(capes_serie$ano), ultimo_ano_titulos = max(capes_serie$ano), pico_titulos_ano = capes_serie$ano[which.max(capes_serie$titulos)], pico_titulos_val = max(capes_serie$titulos), media_titulos_ano = round(mean(capes_serie$titulos), 1),
 primeiro_ano_ppg = min(prog_serie$ano), ultimo_ano_ppg = max(prog_serie$ano), total_programas_unicos = n_distinct(prog$cd_programa_ies), max_programas_ano = max(prog_serie$programas_unicos), max_programas_ano_ano = prog_serie$ano[which.max(prog_serie$programas_unicos)],
 total_artigos = sum(artigos_serie$artigos), total_artigos_brutos = sum(artigos_serie_raw$artigos), primeiro_ano_artigos = min(artigos_serie$ano), ultimo_ano_artigos = max(artigos_serie$ano), pico_artigos_ano = artigos_serie$ano[which.max(artigos_serie$artigos)], pico_artigos_val = max(artigos_serie$artigos), media_artigos_ano = round(mean(artigos_serie$artigos), 1),
 vinculos_docentes = nrow(docs), docentes_unicos = n_distinct(docs$id_pessoa),
 total_registros_capes = nrow(capes_ok), n_excluidos_area39 = n_excluidos,
 pct_excluidos_area39 = round(100 * n_excluidos / nrow(capes), 2),
 n_discordantes_area39 = n_discordantes_area39)
saveRDS(v, file.path(dir_processed, "valores_inline_temporal.rds"))
tab <- capes_serie %>% full_join(prog_serie, by = "ano") %>% full_join(artigos_serie, by = "ano") %>% arrange(ano) %>% replace_na(list(titulos=0, programas_unicos=0, ies_unicas=0, artigos=0))
write_csv(tab, file.path(dir_tabelas, "tabela_series_temporais.csv"))
saveRDS(tab, file.path(dir_processed, "tabela_series_temporais.rds"))
cat("CAPES:", v$total_titulos_cap, "entre", v$primeiro_ano_titulos, "e", v$ultimo_ano_titulos, "\nArtigos de pesquisa até 2024:", v$total_artigos, "\n")
