#!/usr/bin/env Rscript
# 05_analise_temporal.R — Série Temporal: PPGs, Títulos e Artigos (unificada)
source(here::here("SCRIPTS", "00_setup.R"))
dir_processed <- here::here("DADOS", "processed")
dir_figuras   <- here::here("FIGURAS")
dir_tabelas   <- here::here("TABELAS")
dir.create(dir_figuras, recursive = TRUE, showWarnings = FALSE)
dir.create(dir_tabelas, recursive = TRUE, showWarnings = FALSE)

# A base CAPES possui dois layouts históricos. O arquivo unificado harmoniza
# `ano_base` (1987–2012) e `an_base` (2013–2024) em `ano_unificado`.
capes_unif <- readRDS(file.path(dir_processed, "capes_cp_1987_2024_unificado.rds"))
capes_serie <- readRDS(file.path(dir_processed, "capes_serie_anual.rds"))
prog_serie  <- readRDS(file.path(dir_processed, "prog_serie_anual.rds"))
artigos_serie <- readRDS(file.path(dir_processed, "artigos_serie_anual.rds"))
# Gera distribuição por periódico a partir da base consolidada
# (apenas artigos de pesquisa, sem front matter, até 2024)
openalex <- readRDS(file.path(dir_processed, "artigos_periodicos_openalex.rds"))
artigos_ano_per <- openalex %>%
  filter(!is.na(ano), ano <= 2024, tipo == "article", !front_matter) %>%
  count(ano = as.integer(ano), periodico, name = "artigos") %>%
  arrange(ano, periodico)

# Figura 1: Títulos CAPES separados por grau acadêmico.
# Mestrado profissional é mantido junto ao mestrado; doutorado profissional junto
# ao doutorado. Todos os registros têm uma categoria explícita antes da agregação.
capes_grau_ano <- capes_unif %>%
  filter(!is.na(ano_unificado)) %>%
  mutate(
    # 1987–2012: `nivel`; 2013–2024: `nm_grau_academico`.
    # Não se deve usar coalesce sem condicionar ao layout, pois as colunas têm
    # NA estrutural no layout em que não existem.
    grau_raw = if_else(!is.na(an_base), nm_grau_academico, nivel),
    grau_raw = toupper(grau_raw),
    grau = case_when(
      str_detect(grau_raw, "DOUTOR") ~ "Doutorado",
      str_detect(grau_raw, "MESTR") ~ "Mestrado",
      # No layout 1987-2012, mestrados profissionais foram registrados sob o
      # valor genérico "Profissionalizante" (2002-2012, 269 registros), sem
      # distinguir grau. Não havia doutorado profissional nessa janela
      # (instituído oficialmente só a partir de 2013), então tratamos como
      # mestrado, coerente com o mestrado profissional do layout novo.
      str_detect(grau_raw, "PROFISSIONALIZANTE") ~ "Mestrado",
      TRUE ~ "Grau não informado"
    )
  ) %>%
  count(ano = ano_unificado, grau, name = "titulos") %>%
  complete(ano = seq(min(ano), max(ano)), grau = c("Mestrado", "Doutorado", "Grau não informado"), fill = list(titulos = 0)) %>%
  mutate(grau = factor(grau, levels = c("Mestrado", "Doutorado", "Grau não informado")))

saveRDS(capes_grau_ano, file.path(dir_processed, "capes_titulos_por_grau_ano.rds"))
write_csv(capes_grau_ano, file.path(dir_tabelas, "tabela_titulos_por_grau_ano.csv"))

# Séries são o objeto da figura; linhas permitem comparar diretamente as trajetórias
# de mestrado e doutorado sem a ambiguidade de barras empilhadas.
p1 <- ggplot(capes_grau_ano %>% filter(grau != "Grau não informado"), aes(x = ano, y = titulos, colour = grau, linetype = grau)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.1, fill = "white", shape = 21, stroke = 0.65) +
  scale_colour_manual(
    values = c("Mestrado" = "#4C78A8", "Doutorado" = "#E45756"),
    name = "Grau acadêmico"
  ) +
  scale_linetype_manual(values = c("Mestrado" = "solid", "Doutorado" = "dashed"), name = "Grau acadêmico") +
  scale_y_continuous(name = "Títulos concedidos", breaks = scales::pretty_breaks(6), labels = num_ptbr(), expand = expansion(mult = c(0.02, 0.08))) +
  scale_x_continuous(breaks = seq(1985, 2025, by = 5)) +
  labs(title = "Títulos de Pós-Graduação em Ciência Política, por Grau Acadêmico",
       subtitle = "Mestrados e doutorados concedidos anualmente, 1987–2024",
       x = "Ano", caption = "Fonte: Catálogo de Teses e Dissertações CAPES (área 39). Registros de grau não informado não são exibidos. Elaboração própria.") +
  theme_artigo() + theme(legend.position = "top")
ggsave(file.path(dir_figuras, "fig01_titulos_temporal.png"), p1, width = 7.5, height = 4.8, dpi = 300)
ggsave(file.path(dir_figuras, "fig01_titulos_temporal.pdf"), p1, width = 7.5, height = 4.8)

# Figura 2: PPG
p2 <- ggplot(prog_serie, aes(x = ano)) +
  geom_col(aes(y = programas_unicos), fill = "#54A24B", alpha = 0.8, width = 0.5, position = position_nudge(x = -0.15)) +
  geom_col(aes(y = ies_unicas), fill = "#E45756", alpha = 0.8, width = 0.5, position = position_nudge(x = 0.15)) +
  geom_text(aes(y = programas_unicos, label = programas_unicos), vjust = -0.3, size = 3, position = position_nudge(x = -0.15)) +
  geom_text(aes(y = ies_unicas, label = ies_unicas), vjust = -0.3, size = 3, position = position_nudge(x = 0.15)) +
  scale_y_continuous(name = "Quantidade", breaks = scales::pretty_breaks(6), labels = num_ptbr()) +
  scale_x_continuous(breaks = seq(2013, 2024, by = 1)) +
  labs(title = "Expansão dos Programas de Pós-Graduação em Ciência Política",
       subtitle = "Verde: programas únicos (CD_PROGRAMA_IES) | Vermelho: IES únicas por ano",
       x = "Ano", caption = "Fonte: Plataforma Sucupira/CAPES (área 39). Elaboração própria.") +
  theme_artigo()
ggsave(file.path(dir_figuras, "fig02_ppg_temporal.png"), p2, width = 7, height = 4.5, dpi = 300)
ggsave(file.path(dir_figuras, "fig02_ppg_temporal.pdf"), p2, width = 7, height = 4.5)

# Figura 3: Artigos OpenAlex (até 2024)
p3 <- ggplot(artigos_serie, aes(x = ano)) +
  geom_col(aes(y = artigos), fill = "#72B7B2", alpha = 0.8, width = 0.7) +
  scale_y_continuous(name = "Artigos publicados", breaks = scales::pretty_breaks(6), labels = num_ptbr()) +
  scale_x_continuous(breaks = seq(1985, 2025, by = 5)) +
  labs(title = "Produção Científica em Periódicos Brasileiros de Ciência Política",
       subtitle = "Artigos de pesquisa indexados no OpenAlex (6 periódicos canônicos, corte até 2024)",
       x = "Ano", caption = "Fonte: OpenAlex (corte até 2024 para evitar anos parciais). Elaboração própria.") +
  theme_artigo()
ggsave(file.path(dir_figuras, "fig03_artigos_temporal.png"), p3, width = 7, height = 4.5, dpi = 300)
ggsave(file.path(dir_figuras, "fig03_artigos_temporal.pdf"), p3, width = 7, height = 4.5)

# Figura 4: Por periódico
# C12: os rótulos da legenda saem de um mapa nome-técnico -> nome de exibição,
# não de um vetor posicional (que trocaria os rótulos se a ordem do fator
# mudasse).
rotulos_periodico <- c(
  Brazilian_Political_Science_Review = "BPSR",
  DADOS_Revista_de_Ciencias_Sociais = "DADOS",
  Lua_Nova = "Lua Nova",
  Opiniao_Publica = "Opinião Pública",
  RBCP_Revista_Brasileira_de_Ciencia_Politica = "RBCP",
  Revista_de_Sociologia_e_Politica = "RSP"
)
stopifnot(all(unique(artigos_ano_per$periodico) %in% names(rotulos_periodico)))

p4 <- ggplot(artigos_ano_per, aes(x = ano, y = artigos, fill = periodico)) +
  geom_area(alpha = 0.7, position = "stack") +
  scale_fill_brewer(palette = "Set2", name = "Periódico",
                    labels = function(x) unname(rotulos_periodico[x])) +
  guides(fill = guide_legend(nrow = 2, byrow = TRUE)) +
  scale_y_continuous(name = "Artigos por ano", breaks = scales::pretty_breaks(6), labels = num_ptbr()) +
  scale_x_continuous(breaks = seq(1985, 2025, by = 5)) +
  labs(title = "Distribuição da Produção por Periódico ao Longo do Tempo",
       subtitle = "Áreas empilhadas mostram a participação relativa de cada periódico",
       x = "Ano", caption = "Fonte: OpenAlex (corte até 2024). Elaboração própria.") +
  theme_artigo() + theme(legend.position = "bottom")
ggsave(file.path(dir_figuras, "fig04_artigos_por_periodico.png"), p4, width = 7, height = 5, dpi = 300)
ggsave(file.path(dir_figuras, "fig04_artigos_por_periodico.pdf"), p4, width = 7, height = 5)

# Valores inline atualizados
v <- readRDS(file.path(dir_processed, "valores_inline_temporal.rds"))
cat("=== VALORES ATUALIZADOS ===\n")
cat("CAPES:", v$total_titulos_cap, "títulos (", v$primeiro_ano_titulos, "-", v$ultimo_ano_titulos, ")\n")
cat("  Pico:", v$pico_titulos_ano, "(", v$pico_titulos_val, ")\n")
cat("Artigos (≤2024):", v$total_artigos, "(", v$primeiro_ano_artigos, "-", v$ultimo_ano_artigos, ")\n")
cat("  Pico:", v$pico_artigos_ano, "(", v$pico_artigos_val, ")\n")
