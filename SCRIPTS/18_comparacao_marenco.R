#!/usr/bin/env Rscript
# 18_comparacao_marenco.R — Compara e amplia a série histórica de programas de
# pós-graduação em Ciência Política com os dados publicados em Marenco (2014),
# "The Three Achilles' Heels of Brazilian Political Science", BPSR 8(3).
#
# PROVENIÊNCIA DOS DADOS DE MARENCO (2014) — importante para a auditoria:
# O banco de replicação do autor está hospedado em
# bpsr.org.br/files/arquivos/Banco_Dados_Marenco.html, mas o domínio não
# resolveu de nenhum ambiente disponível nesta sessão (falha de DNS
# reproduzida em três tentativas, incluindo `curl` direto). Os valores abaixo
# foram extraídos dos GRÁFICOS do próprio artigo (via SciELO, imagens em alta
# resolução, fonte declarada "Capes" pelo autor), não do banco bruto.
# Dois critérios de inclusão:
#   (a) séries com TABELA DE VALORES impressa na própria figura (Gráficos 4 e
#       5) — reproduzidas aqui na íntegra, ano a ano;
#   (b) pontos-âncora isolados, lidos com segurança em marcos textuais do
#       artigo ou em rótulos numéricos de barras (Gráfico 3) — NÃO
#       interpolados. Não se digitalizou o Gráfico 1 (série contínua sem
#       tabela) por pixel, para não introduzir valores não verificáveis numa
#       auditoria de dados.
# O escopo de Marenco é "Ciência Política" estrita (não a Área 39 completa
# que este projeto usa, que inclui RI/Políticas Públicas/Defesa), e suas
# séries de programas são contagens CUMULATIVAS de cursos aprovados pela
# CAPES (não "programas ativos no ano", como a Plataforma Sucupira usada
# aqui) — os números não são diretamente somáveis nem substituíveis entre si.

source(here::here("SCRIPTS", "00_setup.R"))
dir_processed <- here::here("DADOS", "processed")
dir_tabelas   <- here::here("TABELAS")
dir_figuras   <- here::here("FIGURAS")

# -----------------------------------------------------------------------------
# 1. Pontos-âncora: número de programas de MA/PhD em Ciência Política estrita
#    (Marenco 2014, Gráfico 1: "The expansion of Political Science - MA and
#    PhD programmes in Brazil", cumulativo, fonte Capes; marcos citados no
#    texto do artigo e extremos lidos no eixo do gráfico)
# -----------------------------------------------------------------------------
marenco_programas <- tribble(
  ~ano, ~nivel,      ~programas, ~marco,
  1969, "Mestrado",  2,          "Primeiros mestrados (UFMG, IUPERJ)",
  1974, "Doutorado", 1,          "Primeiro doutorado (USP)",
  1980, "Doutorado", 2,          "Segundo doutorado (IUPERJ)",
  1994, "Mestrado",  10,         "10 cursos de mestrado",
  1996, "Doutorado", 3,          "Terceiro doutorado (UFRGS)",
  2004, "Doutorado", 6,          "Marco do Gráfico 2 (comparação com áreas irmãs)",
  2013, "Mestrado",  38,         "Extremo da série (fim da janela do artigo)",
  2013, "Doutorado", 17,         "Extremo da série (fim da janela do artigo)"
) %>% mutate(fonte = "Marenco (2014), Gráfico 1/2 — Ciência Política estrita")
write_csv(marenco_programas, file.path(dir_tabelas, "tabela_marenco_programas_ancoras.csv"))

# -----------------------------------------------------------------------------
# 2. Estados com programa de doutorado (Marenco 2014, Gráfico 3 — valores
#    impressos nas barras)
# -----------------------------------------------------------------------------
marenco_estados_phd <- tribble(
  ~ano, ~area,               ~n_estados,
  1980, "Ciência Política",  2,
  1990, "Ciência Política",  2,
  2000, "Ciência Política",  3,
  2010, "Ciência Política",  6,
  1980, "Sociologia",        2,
  1990, "Sociologia",        5,
  2000, "Sociologia",        11,
  2010, "Sociologia",        17,
  1980, "Antropologia",      2,
  1990, "Antropologia",      3,
  2000, "Antropologia",      4,
  2010, "Antropologia",      7
) %>% mutate(fonte = "Marenco (2014), Gráfico 3")
write_csv(marenco_estados_phd, file.path(dir_tabelas, "tabela_marenco_estados_phd.csv"))

# Comparação com nossos dados: UFs com doutorado na Área 39 completa em 2013
# (exclui programas "EM DESATIVACAO"; ver AUDITORIA.md §9)
prog <- readRDS(file.path(dir_processed, "sucupira_programas_cp_2013_2024.rds")) %>%
  filter(is.na(ds_situacao_programa) | ds_situacao_programa != "EM DESATIVACAO")
norm <- function(x) toupper(iconv(x, to = "ASCII//TRANSLIT", sub = ""))
prog <- prog %>%
  mutate(
    grau_n = norm(nm_grau_programa),
    modalidade_n = if_else(grepl("PROFISSIONAL", norm(nm_modalidade_programa)),
                           "PROFISSIONAL", "ACADEMICO"),
    tem_mestrado_acad = grepl("MESTRADO", grau_n) & modalidade_n == "ACADEMICO",
    tem_doutorado_acad = grepl("DOUTORADO", grau_n) & modalidade_n == "ACADEMICO"
  )

# F10: Marenco conta CURSOS de mestrado e de doutorado ACADÊMICOS aprovados
# (Ciência Política estrita). A versão anterior deste script comparava o total
# de PROGRAMAS da Área 39, inclusive os só-doutorado e os profissionais, e
# chamava isso de "programas de mestrado". Aqui a contagem passa a ser de
# cursos acadêmicos, o recorte comparável.
contar_cursos <- function(ano_alvo) {
  p <- prog %>% filter(ano_base == as.character(ano_alvo))
  list(
    ma = n_distinct(p$cd_programa_ies[p$tem_mestrado_acad]),
    phd = n_distinct(p$cd_programa_ies[p$tem_doutorado_acad]),
    mp = n_distinct(p$cd_programa_ies[grepl("MESTRADO", p$grau_n) & p$modalidade_n == "PROFISSIONAL"]),
    estados_phd = n_distinct(p$sg_uf_programa[p$tem_doutorado_acad]),
    ufs_phd = sort(unique(p$sg_uf_programa[p$tem_doutorado_acad])),
    total_programas = n_distinct(p$cd_programa_ies)
  )
}
c13 <- contar_cursos(2013)
c24 <- contar_cursos(2024)
p13 <- prog %>% filter(ano_base == "2013")
n_ma_area39_2013 <- c13$ma
n_phd_area39_2013 <- c13$phd
n_estados_area39_2013 <- c13$estados_phd
p13_doc <- p13 %>% filter(tem_doutorado_acad)
cat("Área 39 completa (Sucupira), UFs com doutorado em 2013:", n_estados_area39_2013,
    "—", paste(sort(unique(p13_doc$sg_uf_programa)), collapse = ", "), "\n")
cat("Ciência Política estrita (Marenco), UFs com doutorado em 2010:",
    marenco_estados_phd$n_estados[marenco_estados_phd$area == "Ciência Política" & marenco_estados_phd$ano == 2010], "\n")

# -----------------------------------------------------------------------------
# 3. Razão doutores titulados / docentes permanentes — série ANUAL EXATA
#    (Marenco 2014, Gráfico 4, tabela impressa na própria figura, 2004-2012)
#    Amplia-se com a série equivalente deste projeto (Sucupira, Área 39
#    completa, 2013-2024) — a continuidade das duas séries no ponto de corte
#    é o teste de validação externa.
# -----------------------------------------------------------------------------
marenco_ratio <- tribble(
  ~ano, ~area,                ~ratio,
  2004, "Ciência Política",   0.11, 2005, "Ciência Política", 0.22, 2006, "Ciência Política", 0.19,
  2007, "Ciência Política",   0.27, 2008, "Ciência Política", 0.21, 2009, "Ciência Política", 0.17,
  2010, "Ciência Política",   0.19, 2011, "Ciência Política", 0.22, 2012, "Ciência Política", 0.21,
  2004, "Sociologia",         0.39, 2005, "Sociologia", 0.37, 2006, "Sociologia", 0.37,
  2007, "Sociologia",         0.32, 2008, "Sociologia", 0.38, 2009, "Sociologia", 0.36,
  2010, "Sociologia",         0.34, 2011, "Sociologia", 0.34, 2012, "Sociologia", 0.33,
  2004, "Antropologia",       0.27, 2005, "Antropologia", 0.30, 2006, "Antropologia", 0.27,
  2007, "Antropologia",       0.28, 2008, "Antropologia", 0.22, 2009, "Antropologia", 0.25,
  2010, "Antropologia",       0.30, 2011, "Antropologia", 0.22, 2012, "Antropologia", 0.21,
  2004, "Sistema (média)",    0.27, 2005, "Sistema (média)", 0.27, 2006, "Sistema (média)", 0.25,
  2007, "Sistema (média)",    0.25, 2008, "Sistema (média)", 0.25, 2009, "Sistema (média)", 0.25,
  2010, "Sistema (média)",    0.24, 2011, "Sistema (média)", 0.23, 2012, "Sistema (média)", 0.23
) %>% mutate(fonte = "Marenco (2014), Gráfico 4 — tabela impressa na figura")
write_csv(marenco_ratio, file.path(dir_tabelas, "tabela_marenco_razao_doutores.csv"))

# Série equivalente deste projeto: doutores titulados no ano / docentes
# permanentes do mesmo ano, Área 39 completa, Sucupira 2013-2024.
capes_grau <- readRDS(file.path(dir_processed, "capes_titulos_por_grau_ano.rds"))
docs <- readRDS(file.path(dir_processed, "sucupira_docentes_cp_2013_2024.rds"))
perm <- docs %>% filter(grepl("PERMANENTE", toupper(ds_categoria_docente))) %>%
  group_by(ano = as.integer(ano_base)) %>% summarise(docentes_perm = n_distinct(id_pessoa), .groups = "drop")
dout <- capes_grau %>% filter(grau == "Doutorado", ano >= 2013) %>% select(ano, titulos)
razao_area39 <- dout %>% inner_join(perm, by = "ano") %>%
  mutate(area = "Área 39 completa (este estudo)", ratio = titulos / docentes_perm,
         fonte = "Este estudo — CAPES (doutores titulados) / Sucupira (docentes permanentes)") %>%
  select(ano, area, ratio, fonte)
write_csv(razao_area39, file.path(dir_tabelas, "tabela_razao_doutores_area39.csv"))

# Painel combinado (Ciência Política do Marenco 2004-2012 + Área 39 completa
# deste estudo 2013-2024) para a figura de continuidade.
painel_ratio <- bind_rows(
  marenco_ratio %>% filter(area == "Ciência Política") %>% mutate(serie = "Ciência Política estrita (Marenco 2014)") %>% select(ano, ratio, serie),
  razao_area39 %>% mutate(serie = "Área 39 completa (este estudo)") %>% select(ano, ratio, serie)
)
write_csv(painel_ratio, file.path(dir_tabelas, "tabela_painel_razao_doutores_marenco.csv"))

p_ratio <- ggplot(painel_ratio, aes(ano, ratio, colour = serie, linetype = serie)) +
  geom_vline(xintercept = 2012.5, linetype = "dotted", colour = "grey60") +
  geom_line(linewidth = 0.9) +
  geom_point(size = 1.6) +
  annotate("text", x = 2012.5, y = max(painel_ratio$ratio) * 1.02, label = "fim da janela\nde Marenco (2014)",
           size = 2.8, colour = "grey40", hjust = 1.05, vjust = 1) +
  scale_colour_manual(values = c("Ciência Política estrita (Marenco 2014)" = "#999999",
                                 "Área 39 completa (este estudo)" = "#0072B2"), name = NULL) +
  scale_linetype_manual(values = c("Ciência Política estrita (Marenco 2014)" = "dashed",
                                   "Área 39 completa (este estudo)" = "solid"), name = NULL) +
  scale_x_continuous(breaks = seq(2004, 2024, 4)) +
  scale_y_continuous(labels = num_ptbr(accuracy = 0.01)) +
  labs(title = "Razão Doutores Titulados / Docentes Permanentes: Continuidade com Marenco (2014)",
       subtitle = "Ciência Política estrita, 2004–2012 (Marenco) emendada à Área 39 completa, 2013–2024 (este estudo)",
       x = "Ano", y = "Doutores titulados / docentes permanentes",
       caption = "Fontes: Marenco (2014), Gráfico 4 (tabela impressa na figura); Catálogo CAPES e Plataforma Sucupira (este estudo). Escopos e fontes distintos — ver texto.") +
  theme_artigo()
ggsave(file.path(dir_figuras, "fig19_marenco_continuidade_razao_doutores.png"), p_ratio, width = 8.5, height = 5.2, dpi = 300)
ggsave(file.path(dir_figuras, "fig19_marenco_continuidade_razao_doutores.pdf"), p_ratio, width = 8.5, height = 5.2)

# -----------------------------------------------------------------------------
# 4. Valores inline para o artigo
# -----------------------------------------------------------------------------
# Tendência da razão doutores/docentes permanentes, 2013-2024 (F10): teste
# simples de inclinação, com IC, para não descrever como "estagnação" ou
# "crescimento" o que é ruído.
mod_tend <- lm(ratio ~ I(ano - 2013), data = razao_area39)
ic_tend <- confint(mod_tend)["I(ano - 2013)", ]

v_marenco <- list(
  marenco_ma_2013 = 38, marenco_phd_2013 = 17,
  # Cursos ACADÊMICOS na Área 39 (recorte comparável ao de Marenco).
  area39_ma_2013 = n_ma_area39_2013, area39_phd_2013 = n_phd_area39_2013,
  area39_ma_2024 = c24$ma, area39_phd_2024 = c24$phd,
  area39_mp_2013 = c13$mp, area39_mp_2024 = c24$mp,
  area39_programas_2013 = c13$total_programas, area39_programas_2024 = c24$total_programas,
  marenco_estados_phd_2010 = 6, area39_estados_phd_2013 = n_estados_area39_2013,
  area39_estados_phd_2024 = c24$estados_phd,
  marenco_ratio_2004 = 0.11, marenco_ratio_2012 = 0.21,
  area39_ratio_2013 = round(razao_area39$ratio[razao_area39$ano == 2013], 2),
  area39_ratio_2024 = round(razao_area39$ratio[razao_area39$ano == 2024], 2),
  tendencia_ratio_coef = round(unname(coef(mod_tend)[2]), 4),
  tendencia_ratio_ic_inf = round(unname(ic_tend[1]), 4),
  tendencia_ratio_ic_sup = round(unname(ic_tend[2]), 4),
  # Ano de referência de cada série: Marenco reporta estados com doutorado em
  # 2010; a Sucupira, a partir de 2013. Anos DISTINTOS, explicitados no texto.
  marenco_ano_estados = 2010, este_ano_estados = 2013,
  proveniencia = paste("Valores de Marenco (2014) lidos das figuras do artigo",
                       "(Gráficos 1-4, tabelas impressas nas próprias figuras);",
                       "o banco de replicação do autor não resolveu por DNS.")
)
saveRDS(v_marenco, file.path(dir_processed, "valores_inline_marenco.rds"))

cat("\n>>> COMPARAÇÃO COM MARENCO (2014) CONCLUÍDA\n")
cat("MA 2013: Marenco (CP estrita, cumulativo) =", v_marenco$marenco_ma_2013,
    "| Área 39 completa (ativos, Sucupira) =", v_marenco$area39_ma_2013, "\n")
cat("PhD 2013: Marenco =", v_marenco$marenco_phd_2013, "| Área 39 completa =", v_marenco$area39_phd_2013, "\n")
cat("Razão doutores/docentes: Marenco 2004→2012:", v_marenco$marenco_ratio_2004, "→", v_marenco$marenco_ratio_2012,
    "| Área 39 completa 2013→2024:", v_marenco$area39_ratio_2013, "→", v_marenco$area39_ratio_2024, "\n")
