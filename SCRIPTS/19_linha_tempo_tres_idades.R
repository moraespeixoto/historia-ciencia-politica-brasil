#!/usr/bin/env Rscript
# 19_linha_tempo_tres_idades.R — Criação de programas da Área 39 e marcos
# institucionais, 1966–2024.
#
# REESCRITO em 2026-09-02 (REVISAO_CRITICA F24). A versão anterior era uma
# linha do tempo inteiramente desenhada à mão, com nove marcos escolhidos, dois
# deles cobrindo a "Idade da Expansão" inteira. Agora o corpo da figura é DADO:
# o ano de início de cada programa ativo em 2024 (`AN_INICIO_PROGRAMA`, da
# Plataforma Sucupira), colorido por subárea e distinguido por modalidade. Os
# marcos institucionais permanecem, mas apenas os que têm coluna `fonte`
# preenchida; os sem fonte primária ficam registrados como pendentes e NÃO são
# desenhados (nem citados no .qmd sem "[verificar]").
source(here::here("SCRIPTS", "00_setup.R"))
theme_set(theme_artigo())

dir_figuras   <- here::here("FIGURAS")
dir_tabelas   <- here::here("TABELAS")
dir_processed <- here::here("DADOS", "processed")

# -----------------------------------------------------------------------------
# 1. Dado: ano de início dos programas da Área 39 (Sucupira)
# -----------------------------------------------------------------------------
prog <- readRDS(file.path(dir_processed, "sucupira_programas_cp_2013_2024.rds")) %>%
  filter(is.na(ds_situacao_programa) | ds_situacao_programa != "EM DESATIVACAO")

source(here::here("SCRIPTS", "10_classificacao_subareas_fun.R"), local = TRUE)

programas_2024 <- prog %>%
  filter(ano_base == "2024") %>%
  distinct(cd_programa_ies, .keep_all = TRUE) %>%
  mutate(
    ano_inicio = suppressWarnings(as.integer(an_inicio_programa)),
    subarea = classificar_programa(nm_programa_ies),
    modalidade = if_else(grepl("PROFISSIONAL", normaliza_prog(nm_modalidade_programa)),
                         "PROFISSIONAL", "ACADEMICO")
  ) %>%
  filter(!is.na(ano_inicio), ano_inicio >= 1960, ano_inicio <= 2024)

n_sem_ano <- sum(is.na(suppressWarnings(as.integer(
  prog$an_inicio_programa[prog$ano_base == "2024" &
                            !duplicated(prog$cd_programa_ies[prog$ano_base == "2024"])]))))

criacao_ano <- programas_2024 %>%
  count(ano_inicio, subarea, modalidade, name = "programas")
write_csv(criacao_ano, file.path(dir_tabelas, "tabela_criacao_programas_area39.csv"))

# -----------------------------------------------------------------------------
# 2. Marcos institucionais — SOMENTE com fonte primária declarada
# -----------------------------------------------------------------------------
# Regra: um marco só entra na figura se a coluna `fonte` estiver preenchida.
# Os marcos sem fonte verificada nesta rodada ficam em `marcos_pendentes` e são
# gravados em TABELAS/marcos_institucionais_pendentes.csv para o autor
# resolver; enquanto isso, nenhuma data sem fonte é desenhada nem citada.
marcos <- tribble(
  ~ano, ~rotulo,                        ~fonte,
  1966, "UFMG (1ª turma 1967)",         "Forjaz (1997); página oficial do PPGCP-UFMG",
  1966, "Revista DADOS",                "IESP-UERJ, 60 anos da revista DADOS (dados.iesp.uerj.br)",
  1977, "ANPOCS",                       "Site oficial da ANPOCS (anpocs.com, histórico)",
  1996, "ABCP",                         "Site oficial da ABCP (cienciapolitica.org.br, histórico)",
  2007, "BPSR (1º número)",             "Brazilian Political Science Review, v.1 n.1 (2007), SciELO"
)
marcos_pendentes <- tribble(
  ~ano, ~rotulo,                        ~pendencia,
  1969, "IUPERJ",                       "Fundação 1969; início do mestrado 1969 ou 1970 — sem fonte primária conferida",
  1971, "USP",                          "Ano do mestrado em Ciência Política da USP — sem fonte primária conferida",
  1973, "UFRGS",                        "Marenco (2014) data o doutorado em 1996; o mestrado de 1973 carece de fonte",
  1984, "UnB (mestrado CP/RI)",         "Sem fonte primária conferida",
  1998, "1º Encontro da ABCP",          "Data citada no texto (§4.2); as fontes da tabela de encontros começam em 2008"
)
write_csv(marcos, file.path(dir_tabelas, "marcos_institucionais_com_fonte.csv"))
write_csv(marcos_pendentes, file.path(dir_tabelas, "marcos_institucionais_pendentes.csv"))
stopifnot(all(!is.na(marcos$fonte) & nzchar(marcos$fonte)))

# -----------------------------------------------------------------------------
# 3. Figura
# -----------------------------------------------------------------------------
legenda_sub <- c(CP = "Ciência Política", RI = "Relações Internacionais",
                 PP = "Políticas Públicas", DEFESA = "Defesa e Estudos Estratégicos",
                 SEGPUB = "Segurança Pública", OUTROS = "Outros / Interdisciplinares")
cores_sub <- c(CP = "#4C78A8", RI = "#54A24B", PP = "#F58518", DEFESA = "#E45756",
               SEGPUB = "#B279A2", OUTROS = "#BAB0AC")

y_max <- max(criacao_ano %>% count(ano_inicio, wt = programas) %>% pull(n))
marcos_plot <- marcos %>%
  mutate(y = y_max * c(1.30, 1.06, 1.30, 1.30, 1.30)[seq_len(n())])

p20 <- ggplot(criacao_ano, aes(x = ano_inicio, y = programas, fill = subarea)) +
  geom_col(aes(alpha = modalidade), width = 0.85) +
  geom_vline(data = marcos, aes(xintercept = ano), linetype = "dotted",
             colour = "grey55", linewidth = 0.35) +
  geom_text(data = marcos_plot, aes(x = ano, y = y, label = paste0(ano, "\n", rotulo)),
            inherit.aes = FALSE, size = 2.5, colour = "grey25", lineheight = 0.9,
            fontface = "bold", vjust = 1) +
  scale_fill_manual(values = cores_sub, labels = legenda_sub, name = "Subárea") +
  scale_alpha_manual(values = c(ACADEMICO = 1, PROFISSIONAL = 0.45),
                     labels = c(ACADEMICO = "Acadêmico", PROFISSIONAL = "Profissional"),
                     name = "Modalidade") +
  scale_x_continuous(breaks = seq(1965, 2025, 5), limits = c(1963, 2026)) +
  scale_y_continuous(name = "Programas criados no ano (ativos em 2024)",
                     breaks = scales::pretty_breaks(6),
                     expand = expansion(mult = c(0.02, 0.35))) +
  guides(fill = guide_legend(nrow = 2, byrow = TRUE, order = 1),
         alpha = guide_legend(order = 2)) +
  labs(title = "Criação de Programas da Área 39 e Marcos Institucionais, 1966–2024",
       subtitle = paste0("Ano de início dos ", nrow(programas_2024),
                         " programas ativos em 2024 com ano informado, por subárea e modalidade"),
       x = "Ano de início do programa",
       caption = paste("Fonte: Plataforma Sucupira/CAPES (AN_INICIO_PROGRAMA);",
                       "marcos institucionais com fonte primária declarada em",
                       "TABELAS/marcos_institucionais_com_fonte.csv. Elaboração própria.")) +
  theme_artigo() + theme(legend.position = "bottom")

ggsave(file.path(dir_figuras, "fig20_tres_idades.png"), p20, width = 8.5, height = 5.4, dpi = 300)
ggsave(file.path(dir_figuras, "fig20_tres_idades.pdf"), p20, width = 8.5, height = 5.4)

saveRDS(list(n_programas_com_ano = nrow(programas_2024),
             n_programas_sem_ano = n_sem_ano,
             ano_mais_antigo = min(programas_2024$ano_inicio),
             criados_ate_1999 = sum(programas_2024$ano_inicio <= 1999),
             criados_2000_2009 = sum(programas_2024$ano_inicio %in% 2000:2009),
             criados_2010_2024 = sum(programas_2024$ano_inicio >= 2010),
             marcos = marcos, marcos_pendentes = marcos_pendentes),
        file.path(dir_processed, "valores_inline_linha_tempo.rds"))

cat(">>> fig20 regenerada a partir de AN_INICIO_PROGRAMA:", nrow(programas_2024),
    "programas com ano;", n_sem_ano, "sem ano.\n")
cat(">>> Marcos com fonte:", nrow(marcos), "| pendentes (não desenhados):",
    nrow(marcos_pendentes), "\n")
