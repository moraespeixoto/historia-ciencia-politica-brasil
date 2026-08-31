#!/usr/bin/env Rscript
# 16_auditoria_pos_graduacao.R — Segunda auditoria (31/08/2026), focada nos
# microdados de pós-graduação (CAPES/Sucupira/comparação institucional).
# Não recoleta dados; roda só sobre DADOS/raw e DADOS/processed já
# existentes, e reproduz os achados registrados em AUDITORIA.md §9.
# Requer que 08, 10, 07, 05, 13, 14 e 15 já tenham sido executados nesta sessão.
source(here::here("SCRIPTS", "00_setup.R"))
dir_processed <- here::here("DADOS", "processed")
dir_relatorios <- file.path(dir_processed, "relatorios_eda")
dir.create(dir_relatorios, recursive = TRUE, showWarnings = FALSE)

log <- character()
add <- function(...) { linha <- paste0(...); log <<- c(log, linha); cat(linha, "\n") }

add("================================================================")
add("SEGUNDA AUDITORIA — DADOS DE PÓS-GRADUAÇÃO (", as.character(Sys.Date()), ")")
add("================================================================\n")

# -----------------------------------------------------------------------------
# 1. Bug do sentinela "999*****999" (chave de deduplicação da base comparada)
# -----------------------------------------------------------------------------
add("--- 1. Reconciliação: série CP/RI (comparada) x série principal ---")
principal <- readRDS(file.path(dir_processed, "capes_serie_anual.rds")) %>%
  select(ano, titulos_principal = titulos)
comp_path <- file.path(dir_processed, "tabela_comparacao_titulos_capes.rds")
if (file.exists(comp_path)) {
  comp_cp <- readRDS(comp_path) %>%
    filter(area_nome == "Ciência Política / RI", nivel != "Não informado") %>%
    group_by(ano) %>% summarise(titulos_comparada = sum(titulos), .groups = "drop")
  m <- principal %>% left_join(comp_cp, by = "ano") %>%
    mutate(dif_pct = round(100 * (titulos_comparada - titulos_principal) / titulos_principal, 1))
  add("  Anos com divergência > 5%: ", sum(abs(m$dif_pct) > 5, na.rm = TRUE), " de ", nrow(m))
  divergentes <- m %>% filter(abs(dif_pct) > 5)
  if (nrow(divergentes) > 0) {
    add("  Anos divergentes: ", paste(divergentes$ano, collapse = ", "))
    add("  (2003-2012 é resíduo conhecido e não investigado a fundo — ver AUDITORIA.md §9;")
    add("   qualquer divergência em 1987-1995 ou 2013+ voltaria a indicar o bug do sentinela.)")
  } else {
    add("  Nenhuma divergência relevante.")
  }
} else {
  add("  AVISO: tabela_comparacao_titulos_capes.rds não encontrada — rode o script 14 antes.")
}

# -----------------------------------------------------------------------------
# 2. Data de titulação: 0% de NA esperado no layout 2013+ com o parser corrigido
# -----------------------------------------------------------------------------
add("\n--- 2. Parser de dt_titulacao (layout 2013-2024) ---")
capes <- readRDS(file.path(dir_processed, "capes_cp_1987_2024.rds"))
novo <- capes %>% filter(!is.na(an_base))
d1 <- as.Date(novo$dt_titulacao, format = "%d/%m/%Y %H:%M:%S")
d2 <- as.Date(novo$dt_titulacao, format = "%d%b%Y:%H:%M:%S")
dt <- coalesce(d1, d2)
pct_na <- round(100 * mean(is.na(dt)), 1)
add("  % de NA após parser explícito: ", pct_na, "% (era ~76% com tryFormats() genérico)")
ano_defesa <- as.integer(format(dt, "%Y"))
pct_dif_ano <- round(100 * mean(ano_defesa != as.integer(novo$an_base), na.rm = TRUE), 1)
add("  % com ano de defesa != AN_BASE: ", pct_dif_ano, "%")

# -----------------------------------------------------------------------------
# 3. Grau acadêmico "Profissionalizante" (layout antigo)
# -----------------------------------------------------------------------------
add("\n--- 3. Registros com grau 'Profissionalizante' (layout 1987-2012) ---")
antigo <- capes %>% filter(!is.na(ano_base))
n_prof <- sum(antigo$nivel == "Profissionalizante", na.rm = TRUE)
add("  N = ", n_prof, " (reclassificados como Mestrado em 05_analise_temporal.R)")
grau_ano <- readRDS(file.path(dir_processed, "capes_titulos_por_grau_ano.rds"))
n_sem_grau <- sum(grau_ano$titulos[grau_ano$grau == "Grau não informado"])
add("  'Grau não informado' após correção: ", n_sem_grau, " (deve ser 0)")

# -----------------------------------------------------------------------------
# 4. Filtro área 39: âncora administrativa x crosswalk Sucupira
# -----------------------------------------------------------------------------
add("\n--- 4. Filtro área 39, layout novo: área de avaliação x crosswalk ---")
prog <- readRDS(file.path(dir_processed, "sucupira_programas_cp_2013_2024.rds"))
suc_cod <- unique(prog$cd_programa_ies)
via_area <- !is.na(novo$nm_area_avaliacao) &
  novo$nm_area_avaliacao == "CIÊNCIA POLÍTICA E RELAÇÕES INTERNACIONAIS"
via_crosswalk <- novo$cd_programa %in% suc_cod
add("  Via área de avaliação: ", sum(via_area), " | via crosswalk Sucupira: ", sum(via_crosswalk))
add("  Discordância: ", sum(via_area != via_crosswalk), " registro(s) de ", nrow(novo))

# -----------------------------------------------------------------------------
# 5. Duplicatas remanescentes (impacto documentado, não corrigido)
# -----------------------------------------------------------------------------
add("\n--- 5. Duplicatas remanescentes (CAPES) ---")
if ("id_producao_intelectual" %in% names(capes)) {
  dup_id <- capes %>% filter(!is.na(id_producao_intelectual)) %>%
    count(id_producao_intelectual) %>% filter(n > 1)
  add("  Duplicatas em id_producao_intelectual: ", nrow(dup_id), " grupo(s)")
}

add("\n>>> AUDITORIA CONCLUÍDA. Achados completos e ações tomadas em AUDITORIA.md §9.")

writeLines(log, file.path(dir_relatorios, paste0("auditoria_pos_graduacao_", Sys.Date(), ".txt")))
cat("\n>>> RELATÓRIO SALVO EM:", file.path(dir_relatorios, paste0("auditoria_pos_graduacao_", Sys.Date(), ".txt")), "\n")
