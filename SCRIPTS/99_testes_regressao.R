#!/usr/bin/env Rscript
# ==============================================================================
# 99_testes_regressao.R — Números canônicos do artigo
# ==============================================================================
# Trava os valores que NÃO devem mudar sem que alguém tenha decidido mudá-los,
# e os que mudaram na rodada de 2026-09-02 para um valor conhecido. Rodar
# depois de qualquer alteração no pipeline:
#
#   Rscript SCRIPTS/99_testes_regressao.R
#
# Se um teste falhar, a pergunta certa é "o que mudou no dado?", não "como
# atualizo o número esperado?". Só atualize um valor esperado com a explicação
# no comentário e o registro em AUDITORIA.md.
#
# Ordem de execução do pipeline que produz estes números:
#   03 → 08 → 10 → 10b → 07 → 05 → 13 → 14 → 20 → 21 → 15 → 06 → 06a → 06b → 06c → 18 → 19
# ==============================================================================

suppressPackageStartupMessages({
  library(here); library(dplyr); library(testthat)
})

P <- function(...) here::here("DADOS", "processed", ...)
Tb <- function(...) here::here("TABELAS", ...)

v_temp <- readRDS(P("valores_inline_temporal.rds"))
v_sub  <- readRDS(P("valores_inline_subareas.rds"))
v_comp <- readRDS(P("valores_inline_comparacao.rds"))
v_mar  <- readRDS(P("valores_inline_marenco.rds"))
v_geo  <- readRDS(P("valores_inline_geografia.rds"))
comp   <- readRDS(P("comparacao_areas_sucupira.rds"))

# ---------------------------------------------------------------------------
test_that("serie principal da Area 39 estavel", {
  expect_equal(v_temp$total_titulos_cap, 12661)
  expect_equal(v_temp$pico_titulos_val, 1002)
  expect_equal(v_temp$pico_titulos_ano, 2024)
  expect_equal(v_temp$primeiro_ano_titulos, 1987)
  expect_equal(v_temp$ultimo_ano_titulos, 2024)
  expect_equal(v_temp$max_programas_ano, 64)
  expect_equal(v_temp$n_excluidos_area39, 73)
  expect_equal(v_temp$vinculos_docentes, 11600)
  expect_equal(v_temp$docentes_unicos, 1670)
})

test_that("F04: programas unicos exclui EM DESATIVACAO", {
  # Era 69 (contava `prog` sem filtro); o valor correto é 67.
  expect_equal(v_temp$total_programas_unicos, 67)
  expect_equal(v_temp$total_programas_unicos_sem_filtro, 69)
})

test_that("F20: crosswalk restrito ao mesmo an_base nao muda nenhum registro", {
  expect_equal(v_temp$n_crosswalk_mudou_area, 0)
  expect_equal(v_temp$n_discordantes_area39, 1)
})

# ---------------------------------------------------------------------------
test_that("F01: codigos de area corretos (28/34/35/36/39/40)", {
  # Conferido contra NM_AREA_AVALIACAO nas 12 safras brutas da Sucupira.
  # Com os códigos errados (38/40/41/42) a Área 39 aparecia como a MENOR das
  # seis; com os corretos ela é a quarta de seis e a que mais cresceu.
  p24 <- comp$programas_ano %>% filter(ano == 2024)
  esperado <- c("Geografia" = 80, "História" = 80, "Economia" = 76,
                "Ciência Política / RI" = 64, "Sociologia" = 52,
                "Antropologia / Arqueologia" = 38)
  obs <- setNames(p24$programas, p24$area)[names(esperado)]
  expect_equal(obs, esperado)

  p13 <- comp$programas_ano %>% filter(ano == 2013)
  expect_equal(p13$programas[p13$area == "Ciência Política / RI"], 32)

  ufs <- c("Geografia" = 27, "História" = 25, "Sociologia" = 22,
           "Antropologia / Arqueologia" = 22, "Economia" = 20,
           "Ciência Política / RI" = 15)
  expect_equal(v_comp$ufs_2024[names(ufs)], ufs)

  # A Área 39 NÃO é a menor: é a quarta de seis em número de programas.
  expect_equal(v_comp$posicao_area39_programas_2024, 4L)
  expect_equal(v_comp$area_maior_crescimento, "Ciência Política / RI")
  expect_equal(unname(v_comp$var_programas_pct[["Ciência Política / RI"]]), 100)
  expect_equal(unname(v_comp$var_programas_pct[["Sociologia"]]), 0)
})

test_that("F02: modalidade profissional separada", {
  m24 <- comp$modalidade %>% filter(ano == 2024, area == "Ciência Política / RI")
  expect_equal(m24$programas[m24$modalidade == "PROFISSIONAL"], 20)
  expect_equal(m24$programas[m24$modalidade == "ACADEMICO"], 44)
  expect_equal(v_temp$n_programas_prof_2024, 20)
  expect_equal(v_temp$n_programas_prof_2013, 4)
  # A Área 39 tem a MAIOR proporção de programas profissionais das seis.
  expect_equal(names(which.max(v_comp$pct_prof_2024)), "Ciência Política / RI")
  expect_equal(unname(v_comp$pct_prof_2024[["Sociologia"]]), 0)
})

test_that("F11: docentes por programa usa permanentes", {
  ind <- comp$indicadores %>% filter(ano == 2024)
  expect_true(all(c("docentes_permanentes", "docentes_por_programa",
                    "docentes_totais_por_programa") %in% names(ind)))
  expect_equal(ind$docentes_por_programa,
               ind$docentes_permanentes / ind$programas_ativos)
  expect_true(all(ind$docentes_por_programa <= ind$docentes_totais_por_programa))
})

# ---------------------------------------------------------------------------
test_that("F05/F12: subareas somam 100% e 64 programas", {
  pct <- unlist(v_sub$pct_2024)
  expect_equal(sum(pct), 100, tolerance = 0.15)
  expect_equal(sum(unlist(v_sub$programas_2024)), 64)
  expect_setequal(names(v_sub$programas_2024),
                  c("CP", "RI", "PP", "DEFESA", "SEGPUB", "OUTROS"))
  # SEGPUB deixou de ser contada como DEFESA.
  expect_equal(v_sub$n_programas_2024_segpub, 2)
  expect_equal(v_sub$n_programas_2024_def, 8)
  # A série passa a cobrir 1987-2024, não só 1995-2024.
  expect_equal(v_sub$primeiro_ano_serie, 1987)
})

test_that("T2.5: validacao da classificacao de subareas existe e é honesta", {
  expect_true(!is.null(v_sub$validacao))
  val <- v_sub$validacao
  expect_equal(val$n, 240)
  expect_true(val$acuracia_amostra > 50 && val$acuracia_amostra < 100)
  expect_true(val$kappa_auto_humano > 0.4)
  # Enquanto houver um só codificador, o kappa entre humanos tem de ficar NA:
  # relatar um número aqui seria inventar uma segunda codificação.
  if (val$n_codificadores == 1L) expect_true(is.na(val$kappa_entre_codificadores))
})

# ---------------------------------------------------------------------------
test_that("F10: Marenco compara cursos academicos", {
  # Antes o script contava TODOS os 32 programas da Área 39 e chamava isso de
  # "programas de mestrado". Mestrados acadêmicos em 2013 são 28.
  expect_equal(v_mar$area39_ma_2013, 28)
  expect_lt(v_mar$area39_ma_2013, 32)
  expect_equal(v_mar$area39_phd_2013, 20)
  expect_equal(v_mar$area39_estados_phd_2013, 7)
  expect_true(!is.null(v_mar$tendencia_ratio_coef))
})

test_that("F25: reconciliacao das duas series de CP/RI documentada", {
  rec <- readRDS(P("valores_inline_comparacao_teses.rds"))
  expect_equal(rec$total_principal, 12661)
  expect_equal(rec$total_comparada, 12631)
  expect_equal(rec$diferenca_total, 30)
})

# ---------------------------------------------------------------------------
test_that("OpenAlex: filtros documentados", {
  expect_equal(v_temp$n_pre_fundacao_removidos, 1)   # RBCP com registro de 2001
  expect_gt(v_temp$n_dup_removidos, 0)               # duplicatas pt/en da BPSR
  expect_gt(v_temp$total_artigos, 4000)
  expect_lt(v_temp$total_artigos, 5200)
  expect_equal(v_temp$ultimo_ano_artigos, 2024)
  expect_true(!is.null(v_temp$idioma_resumo_artigos))
})

test_that("geografia estavel", {
  expect_equal(v_geo$total_ufs_com_ppg_2024, 15)
  expect_equal(v_geo$top_ies_nome, "USP")
  expect_equal(v_geo$top_ies_n, 1151)
})

# ---------------------------------------------------------------------------
test_that("Fase 2: STM com K justificado e corpus decidido", {
  skip_if_not(file.exists(P("stm_searchK.rds")), "searchK ainda não rodado")
  sk <- readRDS(P("stm_searchK.rds"))
  expect_true(all(c("completo (multilíngue)", "somente português") %in%
                    sk$resultados$corpus))
  v_stm <- readRDS(P("valores_inline_stm.rds"))
  expect_true(v_stm$K %in% sk$grade_K)
  expect_true(v_stm$corpus_idioma %in% c("todos", "pt"))
  # corpus_stm_n e modelo_docs são grandezas distintas.
  expect_gte(v_stm$corpus_stm_n, v_stm$modelo_docs)
  expect_equal(length(v_stm$topicos_nomes), v_stm$K)
  # Nenhum tópico pode ir para o artigo com rótulo provisório.
  expect_false(any(grepl("\\[a rotular\\]", v_stm$topicos_nomes)))
})

test_that("Fase 2: efeitos com controle de composicao", {
  skip_if_not(file.exists(P("valores_inline_stm_efeitos.rds")), "06c ainda não rodado")
  ef <- readRDS(P("valores_inline_stm_efeitos.rds"))
  expect_true(all(c("ic_disjunto", "direcao") %in% names(ef$resumo)))
  expect_equal(nrow(ef$resumo), ef$K)
  # Prevalência esperada não pode ser negativa: quando isso aparecia, era
  # artefato de extrapolação/superparametrização, não resultado.
  expect_true(all(ef$efeitos$estimativa > 0))
  # A queda da teoria política é o único movimento que sobrevive ao controle
  # de composição com ICs disjuntos. Se outro tópico passar a sobreviver, é
  # achado novo e precisa entrar no texto — não é para silenciar o teste.
  caem <- ef$resumo$topico[ef$resumo$direcao == "queda"]
  expect_true(any(grepl("Teoria", caem)))
})

test_that("Fase 2: concentracao e quebras", {
  skip_if_not(file.exists(P("valores_inline_concentracao.rds")), "20 ainda não rodado")
  cc <- readRDS(P("valores_inline_concentracao.rds"))
  # Desconcentração institucional: HHI por IES cai entre 2013 e 2024.
  expect_lt(cc$hhi_ies_39_2024, cc$hhi_ies_39_2013)
  expect_true(cc$hhi_ies_39_2024 > 0 && cc$hhi_ies_39_2024 < 1)
  qb <- readRDS(P("valores_inline_quebras.rds"))
  expect_true(nrow(qb$quebras) > 0)
})

# ---------------------------------------------------------------------------
test_that("genero: imputacao por nome, cobertura e serie estaveis", {
  skip_if_not(file.exists(P("valores_inline_genero.rds")), "22 ainda não rodado")
  vg <- readRDS(P("valores_inline_genero.rds"))

  # Escopo: a análise cobre TODOS os trabalhos titulados da Área 39, porque
  # `autor` (1987-2012) e `nm_discente` (2013-2024) são complementares. Se este
  # número cair, alguém trocou o coalesce por uma coluna só.
  expect_equal(vg$n_trabalhos, 12661)
  expect_equal(vg$ano_inicio, 1987L)
  expect_equal(vg$ano_fim, 2024L)
  expect_equal(vg$censo_ano, 2022)
  expect_equal(vg$limiar, 0.90)
  expect_equal(vg$n_nome_ausente, 0)
  expect_equal(vg$n_sem_token, 0)

  # Cobertura da classificação: 12.582 de 12.661 (99,4%), 79 não classificados.
  expect_equal(vg$n_classificado, 12582)
  expect_equal(vg$n_nao_classificado, 79)
  expect_gt(vg$taxa_classificacao, 0.99)

  # NÃO HÁ VIÉS TEMPORAL DE COBERTURA: a taxa de classificação varia menos de
  # 2 pontos entre quinquênios e a deriva por década é praticamente nula. Se
  # isto quebrar, a série deixa de ser comparável ao longo do tempo e o texto
  # precisa declarar o viés, não ignorá-lo.
  expect_lt(vg$amplitude_taxa_pp, 2)
  expect_lt(abs(vg$deriva_cobertura_pp_decada), 0.5)
  expect_gt(vg$taxa_min_quinquenio, 0.98)

  # Resultado principal: 40,3% (1987-1991) -> 49,1% (2020-2024), +8,8 pp.
  expect_equal(round(100 * vg$fem_1987_1991, 1), 40.3)
  expect_equal(round(100 * vg$fem_2020_2024, 1), 49.1)
  expect_equal(round(vg$variacao_pp, 1), 8.8)
  expect_equal(round(100 * vg$fem_geral, 1), 45.2)
  expect_gt(vg$or_decada, 1)
  expect_gt(vg$or_decada_ic[1], 1)   # IC da tendência não cruza 1

  # A série NÃO cruza a paridade com confiança estatística em ano nenhum: só
  # há maioria feminina como estimativa pontual (2017, 2019, 2023, 2024). O
  # texto não pode anunciar um "ano da virada".
  expect_false(vg$houve_maioria_fem_ic)
  expect_true(is.na(vg$primeiro_ano_maioria_fem_ic))
  expect_equal(vg$anos_maioria_fem_pontual, c(2017L, 2019L, 2023L, 2024L))
})

test_that("genero: recortes por nivel, subarea e regiao", {
  skip_if_not(file.exists(P("valores_inline_genero.rds")), "22 ainda não rodado")
  vg <- readRDS(P("valores_inline_genero.rds"))

  # Nível: o doutorado é sistematicamente menos feminino que o mestrado.
  expect_lt(vg$fem_nivel_total[["Doutorado"]], vg$fem_nivel_total[["Mestrado"]])
  expect_equal(unname(vg$n_nivel_total[["Doutorado"]] + vg$n_nivel_total[["Mestrado"]]),
               vg$n_classificado)
  expect_gt(vg$hiato_nivel_2020_2024_pp, 0)
  # Em 2020-2024 o mestrado chega à paridade (IC contém 50%: 48,6%-52,0%) e o
  # doutorado fica ABAIXO dela (IC inteiramente < 50%). O texto não pode dizer
  # que o mestrado "ultrapassou" a paridade — o IC não sustenta isso.
  expect_lt(vg$fem_mestrado_2020_2024_ic[1], 0.5)
  expect_gt(vg$fem_mestrado_2020_2024_ic[2], 0.5)
  expect_lt(vg$fem_doutorado_2020_2024_ic[2], 0.5)

  # Subáreas: PP é a mais feminina e DEFESA a menos feminina, com folga.
  expect_equal(names(which.max(vg$fem_subarea)), "PP")
  expect_equal(names(which.min(vg$fem_subarea)), "DEFESA")
  expect_gt(vg$fem_subarea[["PP"]] - vg$fem_subarea[["DEFESA"]], 0.20)
  # SEGPUB fica de fora da figura por n insuficiente (84 trabalhos).
  expect_equal(vg$subareas_n_insuficiente, "SEGPUB")
  expect_true(all(vg$n_subarea[vg$subareas_plotadas] >= vg$n_min_recorte))

  # Região só existe no layout novo: o recorte começa em 2013, não em 1987.
  expect_equal(vg$regiao_periodo_inicio, 2013L)
  expect_equal(sum(vg$n_regiao), 8609)   # classificados de 2013-2024
  expect_equal(vg$regiao_max, "NORDESTE")
  expect_equal(vg$regiao_menor_n, "NORTE")
})

test_that("genero: unidade de analise e sensibilidade da regra de nome", {
  skip_if_not(file.exists(P("valores_inline_genero.rds")), "22 ainda não rodado")
  vg <- readRDS(P("valores_inline_genero.rds"))

  # Trabalho x pessoa (só 2013-2024, onde há id_pessoa_discente): 8.663
  # trabalhos de 7.979 pessoas. A diferença na proporção feminina é menor que
  # meio ponto — a dupla titulação não distorce a série.
  expect_equal(vg$n_trabalhos_2013_2024, 8663)
  expect_equal(vg$n_pessoas_2013_2024, 7979)
  expect_equal(vg$n_pessoas_repetidas, 684)
  expect_lt(abs(vg$dif_trabalho_pessoa_pp), 0.5)

  # Sensibilidade: sem a regra de recuperação (só o primeiro token), a
  # cobertura cai de 99,4% para 97,1% e a proporção feminina global muda menos
  # de meio ponto percentual. O achado não depende da regra.
  expect_lt(vg$taxa_classificacao_sem_rec, vg$taxa_classificacao)
  expect_gt(vg$taxa_classificacao_sem_rec, 0.96)
  expect_lt(vg$dif_sensibilidade_pp, 0.5)
  expect_equal(vg$n_usou_recuperacao, 283)
})

cat("\n>>> TODOS OS TESTES DE REGRESSÃO PASSARAM.\n")
