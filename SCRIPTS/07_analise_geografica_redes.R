#!/usr/bin/env Rscript
# ==============================================================================
# 07_analise_geografica_redes.R — Geografia dos PPGs e Redes de Orientação
# ==============================================================================

source(here::here("SCRIPTS", "00_setup.R"))

suppressPackageStartupMessages({
  library(sf)
  library(geobr)
  library(igraph)
  library(ggraph)
})

dir_processed <- here::here("DADOS", "processed")
dir_figuras   <- here::here("FIGURAS")
dir_tabelas   <- here::here("TABELAS")
dir.create(dir_figuras, recursive = TRUE, showWarnings = FALSE)
dir.create(dir_tabelas, recursive = TRUE, showWarnings = FALSE)

message(">>> Carregando dados para análise geográfica e de redes...")
prog  <- readRDS(file.path(dir_processed, "sucupira_programas_cp_2013_2024.rds"))
docs  <- readRDS(file.path(dir_processed, "sucupira_docentes_cp_2013_2024.rds"))
# Artefato canônico já filtrado pela área 39 (gerado por 08_auditoria_series_temporais.R).
capes <- readRDS(file.path(dir_processed, "capes_cp_area39.rds"))

# -----------------------------------------------------------------------------
# 1. ANÁLISE GEOGRÁFICA DOS PPGS (MAPA DO BRASIL VIA GEOBR)
# -----------------------------------------------------------------------------
message(">>> Baixando malha dos estados via geobr...")
ufs_sf <- geobr::read_state(year = 2020, showProgress = FALSE)

# Distribuição de PPGs únicos por UF (último ano disponível: 2024)
ppg_uf_2024 <- prog %>%
  filter(ano_base == "2024") %>%
  distinct(cd_programa_ies, .keep_all = TRUE) %>%
  count(sg_uf_programa, name = "n_ppgs")

# Distribuição de títulos CAPES históricos por UF
capes_uf <- capes %>%
  mutate(uf_clean = coalesce(sg_uf_ies, uf)) %>%
  filter(!is.na(uf_clean), uf_clean != "") %>%
  count(sg_uf_ies = uf_clean, name = "n_titulos")

# Junção com malha espacial
mapa_dados <- ufs_sf %>%
  left_join(ppg_uf_2024, by = c("abbrev_state" = "sg_uf_programa")) %>%
  left_join(capes_uf, by = c("abbrev_state" = "sg_uf_ies")) %>%
  replace_na(list(n_ppgs = 0, n_titulos = 0))

# Figura 7: Evolução espacial dos PPGs (2013 vs 2024) — círculos por município
# proporcionais ao número de programas.
message(">>> Baixando malha municipal via geobr (para a figura de evolução)...")
mun_cent <- geobr::read_municipality(year = 2020, showProgress = FALSE) %>%
  sf::st_centroid()

# Contagem de programas por município-ano (2013 e 2024).
# distinct() deve rodar DENTRO de cada ano (.by): sem isso, programas presentes
# nos dois anos são contados uma única vez, subestimando 2024.
ppg_mun <- prog %>%
  filter(ano_base %in% c("2013", "2024")) %>%
  distinct(cd_programa_ies, .keep_all = TRUE, .by = ano_base) %>%
  count(ano = as.integer(ano_base), mun = nm_municipio_programa_ies, uf = sg_uf_programa,
        name = "n_prog") %>%
  mutate(mun_key = toupper(iconv(mun, to = "ASCII//TRANSLIT", sub = "")))

mun_key <- mun_cent %>%
  mutate(mun_key = toupper(iconv(name_muni, to = "ASCII//TRANSLIT", sub = "")),
         uf = abbrev_state) %>%
  as_tibble() %>%
  select(mun_key, uf, geometry)

d_mapa <- left_join(ppg_mun, mun_key, by = c("mun_key", "uf")) %>%
  filter(!is.na(geometry)) %>%
  sf::st_as_sf()

tot_ano <- prog %>%
  filter(ano_base %in% c("2013", "2024")) %>%
  distinct(cd_programa_ies, .keep_all = TRUE, .by = ano_base) %>%
  count(ano = as.integer(ano_base), name = "total") %>%
  mutate(lab = paste0(ano, " (", total, " programas)"))

# Projeção Albers igual-área (melhor forma do Brasil) para os dois painéis
crs_albers <- "+proj=aea +lat_1=-2 +lat_2=-22 +lat_0=-12 +lon_0=-54 +x_0=0 +y_0=0 +datum=WGS84 +units=m"

# Transforma os pontos para a projeção do mapa ANTES de extrair coordenadas.
# (Bug anterior: os rótulos usavam x/y em graus, mas o coord_sf projeta em
# metros — os nomes caíam no centro do mapa, longe dos pontos.)
d_mapa <- d_mapa %>% sf::st_transform(crs_albers)

# Rótulos apenas para os maiores núcleos, com coordenadas em metros (mesma CRS
# do mapa), posicionados logo acima do ponto.
labels_mapa <- d_mapa %>%
  filter(n_prog >= 5) %>%
  mutate(x = sf::st_coordinates(.)[, 1], y = sf::st_coordinates(.)[, 2]) %>%
  sf::st_drop_geometry()

tot_ano <- prog %>%
  filter(ano_base %in% c("2013", "2024")) %>%
  distinct(cd_programa_ies, .keep_all = TRUE, .by = ano_base) %>%
  count(ano = as.integer(ano_base), name = "total") %>%
  mutate(lab = paste0(ano, " (", total, " programas)"))

# Ordena para que círculos menores fiquem por cima (núcleos vizinhos não somem)
d_mapa_ord <- d_mapa %>% arrange(ano, n_prog)

p_mapa <- ggplot() +
  geom_sf(data = ufs_sf, fill = "#E9EDF1", colour = "white", linewidth = 0.3) +
  geom_sf(data = d_mapa_ord, aes(size = n_prog),
          fill = "#1F5FA8", colour = "white", shape = 21, stroke = 0.45, alpha = 0.92) +
  ggrepel::geom_label_repel(
    data = labels_mapa, aes(x = x, y = y, label = mun),
    size = 2.8, colour = "#1A3559", fontface = "bold",
    fill = "white", alpha = 0.92, label.size = 0, label.padding = unit(0.18, "lines"),
    segment.size = 0.3, segment.colour = "grey50", min.segment.length = 0,
    seed = 20260828, max.overlaps = Inf, box.padding = 0.4,
    force = 6
  ) +
  scale_size_area(max_size = 11, breaks = c(1, 3, 6, 9, 11),
                  name = "Programas por município", guide = guide_legend(nrow = 1)) +
  facet_wrap(~ ano, ncol = 2, labeller = labeller(ano = setNames(tot_ano$lab, tot_ano$ano))) +
  coord_sf(crs = crs_albers) +
  labs(
    x = NULL, y = NULL,
    title = "Evolução da Distribuição Espacial dos Programas de Pós-Graduação em Ciência Política",
    subtitle = "Círculos proporcionais ao número de programas em cada município; rótulos apenas nos maiores núcleos",
    caption = "Fonte: Plataforma Sucupira/CAPES (área 39) e malha geobr. Projeção Albers. Elaboração própria."
  ) +
  theme_artigo(grid = "none") +
  theme(
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    axis.title = element_blank(),
    axis.line = element_blank(),
    legend.position = "bottom",
    legend.key.size = unit(0.55, "cm"),
    strip.text = element_text(size = 11, face = "bold", colour = "#1A3559"),
    panel.spacing = unit(0.8, "lines"),
    panel.border = element_blank()
  )

# Cache dos objetos do mapa para reuso sem rebaixar a malha geobr (usado pelo
# redesenho de slide em 17_figuras_slides.R).
saveRDS(list(ufs_sf = ufs_sf, d_mapa_ord = d_mapa_ord, labels_mapa = labels_mapa,
             tot_ano = tot_ano, crs_albers = crs_albers),
        file.path(dir_processed, "mapa_evolucao_ppg_cache.rds"))

ggsave(file.path(dir_figuras, "fig07_mapa_evolucao_2013_2024.png"), p_mapa, width = 10, height = 6.4, dpi = 300)
ggsave(file.path(dir_figuras, "fig07_mapa_evolucao_2013_2024.pdf"), p_mapa, width = 10, height = 6.4)

# Distribuição regional comparativa (Sudeste vs demais regiões ao longo do tempo)
prog_regiao_tempo <- prog %>%
  mutate(
    regiao_macro = case_when(
      sg_uf_programa %in% c("SP", "RJ", "MG", "ES") ~ "Sudeste",
      sg_uf_programa %in% c("RS", "PR", "SC") ~ "Sul",
      sg_uf_programa %in% c("DF", "GO", "MT", "MS") ~ "Centro-Oeste",
      sg_uf_programa %in% c("BA", "PE", "CE", "RN", "PB", "MA", "AL", "SE", "PI") ~ "Nordeste",
      TRUE ~ "Norte"
    )
  ) %>%
  group_by(ano = as.integer(ano_base), regiao_macro) %>%
  summarise(n_ppg = n_distinct(cd_programa_ies), .groups = "drop")

# Figura 8: Descentralização regional dos PPGs ao longo do tempo
# Paleta qualitativa (Okabe-Ito): regiões são categorias, não magnitudes.
p_regioes <- ggplot(prog_regiao_tempo, aes(x = ano, y = n_ppg, fill = regiao_macro)) +
  geom_col(position = "stack", width = 0.7, alpha = 0.85) +
  scale_fill_manual(values = c(Sudeste = "#0072B2", Sul = "#D55E00", "Centro-Oeste" = "#009E73",
                                        Nordeste = "#CC79A7", Norte = "#E69F00"),
                    name = "Região") +
  scale_x_continuous(breaks = seq(2013, 2024, by = 1)) +
  scale_y_continuous(breaks = scales::pretty_breaks(6), labels = num_ptbr()) +
  labs(
    title = "Evolução da Distribuição Regional dos Programas de Pós-Graduação",
    subtitle = "Composição regional dos PPGs em Ciência Política e RI (2013–2024)",
    x = "Ano",
    y = "Total de Programas Ativos",
    caption = "Fonte: Plataforma Sucupira/CAPES. Elaboração própria."
  ) +
  theme_artigo() +
  theme(legend.position = "bottom")

ggsave(file.path(dir_figuras, "fig08_descentralizacao_regional.png"), p_regioes, width = 7.5, height = 4.8, dpi = 300)
ggsave(file.path(dir_figuras, "fig08_descentralizacao_regional.pdf"), p_regioes, width = 7.5, height = 4.8)

# -----------------------------------------------------------------------------
# 2. ANÁLISE DE REDES: REDE DE ORIENTAÇÃO E INTERCÂMBIO ACADÊMICO
# -----------------------------------------------------------------------------
message(">>> Construindo rede de coautoria e colaboração entre programas...")

# Matriz de fluxo: Programa do Orientador x Programa / IES
# Usamos os dados da CAPES com orientador e instituição de titulação
capes_limpo <- capes %>%
  mutate(
    ies_clean = iconv(coalesce(sg_entidade_ensino, sigla_ies), from = "UTF-8", to = "ASCII//TRANSLIT", sub = ""),
    orientador_clean = iconv(coalesce(nm_orientador, orientador_1), from = "UTF-8", to = "ASCII//TRANSLIT", sub = "")
  ) %>%
  filter(!is.na(ies_clean), !is.na(orientador_clean), nchar(orientador_clean) > 3)

rede_orientacao <- capes_limpo %>%
  count(ies_clean, orientador_clean, name = "n_orientacoes")

# Top 15 IES com maior produção de teses/dissertações.
# (Correção de auditoria: antes o ranking usava capes_limpo, restrito a
#  registros com orientador, subestimando IES com muitos registros sem
#  orientador. Agora usa TODOS os registros com IES válida.)
top_ies_df <- capes %>%
  mutate(ies_clean = iconv(coalesce(sg_entidade_ensino, sigla_ies), from = "UTF-8", to = "ASCII//TRANSLIT", sub = "")) %>%
  filter(!is.na(ies_clean), ies_clean != "") %>%
  count(ies_clean, sort = TRUE) %>%
  slice_head(n = 15)

# Tabela resumo de dados geográficos e institucionais
tab_geografia <- mapa_dados %>%
  as_tibble() %>%
  select(Estado = name_state, UF = abbrev_state, Regiao = name_region, `PPGs (2024)` = n_ppgs, `Titulos Historicos` = n_titulos) %>%
  arrange(desc(`PPGs (2024)`), desc(`Titulos Historicos`))

write_csv(tab_geografia, file.path(dir_tabelas, "tabela_geografia_ppgs.csv"))
write_csv(top_ies_df, file.path(dir_tabelas, "tabela_top_ies_titulos.csv"))

# Valores inline geográficos
valores_geo <- list(
  total_ufs_com_ppg_2024 = sum(ppg_uf_2024$n_ppgs > 0),
  uf_lider_ppg = ppg_uf_2024$sg_uf_programa[which.max(ppg_uf_2024$n_ppgs)],
  uf_lider_ppg_n = max(ppg_uf_2024$n_ppgs),
  pct_sudeste_2013 = round(sum(prog_regiao_tempo$n_ppg[prog_regiao_tempo$ano == 2013 & prog_regiao_tempo$regiao_macro == "Sudeste"]) / sum(prog_regiao_tempo$n_ppg[prog_regiao_tempo$ano == 2013]) * 100, 1),
  pct_sudeste_2024 = round(sum(prog_regiao_tempo$n_ppg[prog_regiao_tempo$ano == 2024 & prog_regiao_tempo$regiao_macro == "Sudeste"]) / sum(prog_regiao_tempo$n_ppg[prog_regiao_tempo$ano == 2024]) * 100, 1),
  top_ies_nome = top_ies_df$ies_clean[1],
  top_ies_n = top_ies_df$n[1],
  n_municipios_2013 = n_distinct(ppg_mun$mun[ppg_mun$ano == 2013]),
  n_municipios_2024 = n_distinct(ppg_mun$mun[ppg_mun$ano == 2024])
)

saveRDS(valores_geo, file.path(dir_processed, "valores_inline_geografia.rds"))

message(">>> ANÁLISE GEOGRÁFICA E DE REDES CONCLUÍDA!")
cat("\n=== VALORES GEOGRÁFICOS ===\n")
cat("UFs com PPGs em 2024: ", valores_geo$total_ufs_com_ppg_2024, " de 27\n")
cat("UF líder: ", valores_geo$uf_lider_ppg, " (", valores_geo$uf_lider_ppg_n, " programas)\n")
cat("Concentração no Sudeste: de ", valores_geo$pct_sudeste_2013, "% em 2013 para ", valores_geo$pct_sudeste_2024, "% em 2024\n")
cat("Principal IES em titulações: ", valores_geo$top_ies_nome, " (", valores_geo$top_ies_n, " trabalhos)\n")
