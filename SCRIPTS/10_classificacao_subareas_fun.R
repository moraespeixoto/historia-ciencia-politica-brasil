#!/usr/bin/env Rscript
# ==============================================================================
# 10_classificacao_subareas_fun.R — Regras de classificação em subáreas
# ==============================================================================
# Extraído de 10_classificacao_subareas.R em 2026-09-02 para que a MESMA regra
# seja usada por 10 (títulos e programas) e por 19 (linha do tempo de criação
# de programas), em vez de duas cópias que podem divergir silenciosamente.
#
# Classes (mutuamente exclusivas), em ordem de prioridade:
#   CP      — Ciência Política (incl. comportamento político, estudos legislativos)
#   SEGPUB  — Segurança pública / cidadã / ciências policiais
#   DEFESA  — Defesa, estudos estratégicos, militares, marítimos, aeroespaciais
#   RI      — Relações Internacionais, política externa, integração regional
#   PP      — Políticas Públicas, gestão e avaliação
#   OUTROS  — residual
#
# Correções 2026-09-02 (REVISAO_CRITICA F12):
#  - "AEROESPACIA(L|IS)": o padrão anterior ("AEROESPACIAL") não casava com
#    "CIÊNCIAS AEROESPACIAIS" (plural), que caía em OUTROS;
#  - "SEGURANÇA DE AVIAÇÃO E AERONAVEGABILIDADE CONTINUADA" (ITA) é engenharia
#    aeronáutica, não defesa: excluída de DEFESA;
#  - SEGURANÇA PÚBLICA / SEGURANÇA CIDADÃ deixam de ser classificadas como
#    DEFESA e ganham categoria própria (SEGPUB). A alternativa (fundi-las a PP)
#    é decisão do autor; a categoria separada é reversível, a fusão não.
# ==============================================================================

re_defesa <- paste0("ESTRATEGIC|MILITAR|AEROESPACIA(L|IS)|MARITIMO|DEFESA|",
                    "SEGURANCA (INTERNACIONAL|NACIONAL)")
re_defesa_excl <- "SEGURANCA DE AVIACAO|AERONAVEGABILIDADE"
re_segpub <- "SEGURANCA PUBLICA|SEGURANCA CIDADA|POLICIA|CIENCIAS POLICIAIS"
re_ri <- paste0("RELACOES INTERNACIONAIS|POLITICA INTERNACIONAL|",
                "ECONOMIA POLITICA INTERNACIONAL|GOVERNANCA GLOBAL|",
                "INTEGRACAO CONTEMPORANEA|INTEGRACAO LATINO|LATINO-AMERICANA|",
                "LATINO AMERICANA|DIPLOMACIA|",
                "ANALISE E GESTAO DE POLITICAS INTERNACIONAIS|INTERNACIONAIS$")
re_pp <- paste0("POLITICAS PUBLICAS|GESTAO DE POLITICAS|AVALIACAO E MONITORAMENTO|",
                "GOVERNANCA E DESENVOLVIMENTO")
re_cp <- "CIENCIA POLITICA|COMPORTAMENTO POLITICO|PODER LEGISLATIVO"

CLASSES <- c("CP", "RI", "PP", "DEFESA", "SEGPUB", "OUTROS")

normaliza_prog <- function(x) toupper(iconv(x, to = "ASCII//TRANSLIT", sub = ""))

classificar_programa <- function(prog) {
  p <- normaliza_prog(prog)
  dplyr::case_when(
    grepl(re_cp, p) ~ "CP",
    grepl(re_segpub, p) ~ "SEGPUB",
    grepl(re_defesa, p, perl = TRUE) & !grepl(re_defesa_excl, p) ~ "DEFESA",
    grepl(re_ri, p) ~ "RI",
    grepl(re_pp, p) ~ "PP",
    TRUE ~ "OUTROS"
  )
}
