#!/usr/bin/env Rscript
# ==============================================================================
# 22_genero_autoria.R — Composição de gênero da autoria de teses e dissertações
# Projeto: História, Expansão e Institucionalização da Ciência Política no Brasil
#
# NOME DO ARQUIVO: a tarefa pedia `20_genero_autoria.R`, mas 20 e 21 já estão
# ocupados (`20_concentracao.R`, `21_quebras_estruturais.R`). Para não criar
# dois scripts com o mesmo prefixo, este é o 22. Mesma razão para a figura:
# fig21 e fig22 já existem, então a figura desta análise é a fig23.
#
# O QUE FAZ
#   Imputa gênero (binário) a cada trabalho titulado da Área 39 a partir do
#   PRIMEIRO NOME do discente, usando genderBR::get_gender() — que compara o
#   primeiro nome com as frequências por sexo do Censo Demográfico do IBGE.
#   NÃO é medida de identidade de gênero (ver §7 e SECAO_GENERO.md).
#
# DECISÃO DE COLUNA DE NOME (documentada; ver AUDITORIA.md)
#   `autor` e `nm_discente` são COMPLEMENTARES, não redundantes:
#     layout antigo (1987-2012, an_base NA): autor 3.998/3.998, nm_discente 0
#     layout novo   (2013-2024, an_base ok): autor 0,           nm_discente 8.663
#   Nenhum registro tem as duas preenchidas. Logo, a única escolha correta é
#   coalesce(nm_discente, autor) — usar só uma delas truncaria a série pela
#   metade. O script TESTA essa disjunção e falha se ela deixar de valer.
#
# SAÍDAS
#   DADOS/processed/genero_autoria_registros.rds   (registro x gênero imputado)
#   DADOS/processed/genero_serie_anual.rds         (ano x n x prop fem x IC)
#   DADOS/processed/valores_inline_genero.rds      (números citados no texto)
#   TABELAS/tabela_genero_serie_anual.csv
#   TABELAS/tabela_genero_por_nivel.csv
#   TABELAS/tabela_genero_por_subarea.csv
#   TABELAS/tabela_genero_por_regiao.csv
#   TABELAS/tabela_genero_cobertura_periodo.csv
#   FIGURAS/fig23_genero_temporal.png/.pdf         (corpo do artigo)
#   FIGURAS/fig23b_genero_subarea.png/.pdf         (apêndice)
# ==============================================================================

source(here::here("SCRIPTS", "00_setup.R"))

if (!requireNamespace("genderBR", quietly = TRUE)) {
  stop("genderBR não instalado. install.packages('genderBR')")
}
library(genderBR)

dir_processed <- here::here("DADOS", "processed")
dir_figuras   <- here::here("FIGURAS")
dir_tabelas   <- here::here("TABELAS")
dir.create(dir_figuras, recursive = TRUE, showWarnings = FALSE)
dir.create(dir_tabelas, recursive = TRUE, showWarnings = FALSE)

# Parâmetros da imputação (travados aqui, citados no texto e testados no 99).
LIMIAR_PROB  <- 0.90   # threshold do genderBR: |p_fem| >= 0.9 ou <= 0.1
CENSO_ANO    <- 2022   # base de frequências do genderBR (Censo IBGE 2022)
N_MIN_RECORTE <- 200   # abaixo disso um recorte não é plotado (ruído)

# -----------------------------------------------------------------------------
# 1. Base e ano unificado (mesma lógica de 08_auditoria_series_temporais.R)
# -----------------------------------------------------------------------------
capes <- readRDS(file.path(dir_processed, "capes_cp_area39.rds")) %>%
  mutate(
    ano_unificado = as.integer(coalesce(an_base, ano_base)),
    layout = if_else(!is.na(an_base), "novo (2013-2024)", "antigo (1987-2012)")
  )

preenchido <- function(x) !is.na(x) & trimws(x) != ""
stopifnot(
  # Disjunção das duas colunas de nome: se isto quebrar, a regra de coalesce
  # precisa ser reexaminada antes de qualquer número ir para o texto.
  sum(preenchido(capes$autor) & preenchido(capes$nm_discente)) == 0
)

cobertura_nome <- capes %>%
  group_by(layout) %>%
  summarise(
    registros = n(),
    autor_preenchido = sum(preenchido(autor)),
    nm_discente_preenchido = sum(preenchido(nm_discente)),
    id_pessoa_preenchido = sum(!is.na(id_pessoa_discente)),
    .groups = "drop"
  )
message(">>> Cobertura das colunas de nome por layout:")
print(cobertura_nome)

# -----------------------------------------------------------------------------
# 2. Normalização do nome e extração do primeiro nome
# -----------------------------------------------------------------------------
# Os nomes vêm em caixa alta no layout antigo e em caixa mista no novo, com
# acentos, abreviaturas com ponto ("FERNANDO A.FARIAS"), preposições e, em uma
# minoria dos registros de 1987-2012, ordem invertida (sobrenome primeiro:
# "MENEGUELLO RACHEL"). A normalização abaixo remove acentos e pontuação,
# padroniza caixa e descarta partículas e iniciais de uma letra.
PARTICULAS <- c("DE", "DA", "DO", "DAS", "DOS", "E", "DI", "DEL", "DELLA",
                "LA", "LE", "LO", "VON", "VAN", "DER", "Y", "DU", "D",
                "JUNIOR", "JR", "FILHO", "NETO", "SOBRINHO", "SEGUNDO")

normaliza_nome <- function(x) {
  x <- iconv(x, to = "ASCII//TRANSLIT", sub = " ")
  x <- toupper(x)
  x <- gsub("[^A-Z ]", " ", x)      # ponto de abreviatura, hífen, apóstrofo
  trimws(gsub(" +", " ", x))
}

capes <- capes %>%
  mutate(
    nome_bruto = coalesce(nm_discente, autor),
    nome_norm  = normaliza_nome(nome_bruto)
  )

tokens_nome <- strsplit(capes$nome_norm, " ", fixed = TRUE)
tokens_nome <- lapply(tokens_nome, function(t) {
  t <- t[nchar(t) > 1 & !(t %in% PARTICULAS)]
  t
})
capes$n_tokens <- lengths(tokens_nome)
capes$primeiro_nome <- vapply(tokens_nome,
                              function(t) if (length(t)) t[1] else NA_character_,
                              character(1))

n_nome_ausente <- sum(!preenchido(capes$nome_bruto))
n_sem_token <- sum(capes$n_tokens == 0)
message(">>> Nomes ausentes/vazios: ", n_nome_ausente,
        " | sem token utilizável após limpeza: ", n_sem_token)

# -----------------------------------------------------------------------------
# 3. Imputação de gênero com genderBR
# -----------------------------------------------------------------------------
# get_gender(prob = TRUE) devolve a probabilidade de o nome ser feminino no
# Censo do IBGE; a decisão binária é feita aqui para deixar o limiar explícito
# e para distinguir DOIS tipos de não classificação:
#   - "ausente"  : primeiro nome não consta na base do Censo (prob = NA);
#   - "ambiguo"  : consta, mas 0,1 < p_fem < 0,9 (nome unissex).
tokens_unicos <- sort(unique(unlist(tokens_nome)))
message(">>> Consultando genderBR para ", length(tokens_unicos), " nomes únicos...")
prob_fem_tok <- genderBR::get_gender(tokens_unicos, prob = TRUE,
                                     internal = TRUE, year = CENSO_ANO)
names(prob_fem_tok) <- tokens_unicos

classifica <- function(p) {
  dplyr::case_when(
    is.na(p)            ~ NA_character_,
    p >= LIMIAR_PROB    ~ "Feminino",
    p <= 1 - LIMIAR_PROB ~ "Masculino",
    TRUE                ~ NA_character_
  )
}

capes$prob_fem_primeiro <- unname(prob_fem_tok[capes$primeiro_nome])
capes$genero_primeiro   <- classifica(capes$prob_fem_primeiro)

# Regra de recuperação (série principal): quando o PRIMEIRO token não decide,
# percorre os tokens seguintes e usa o primeiro que decidir. Isso recupera os
# registros de 1987-2012 com ordem invertida ("CRUZ SEBASTIAO CARLOS VELASCO",
# "SAMIOS EVA MACHADO BARBOSA", "MENEGUELLO RACHEL") e os nomes compostos cujo
# primeiro elemento é um sobrenome. O custo é que, quando o token inicial é de
# fato um sobrenome que também é nome próprio, a regra pode fixar o gênero pelo
# token errado — por isso a série sem recuperação é preservada e reportada como
# sensibilidade (§6), e as duas diferem por menos de meio ponto percentual.
genero_rec <- capes$genero_primeiro
token_usado <- capes$primeiro_nome
idx_pendente <- which(is.na(genero_rec))
for (i in idx_pendente) {
  tt <- tokens_nome[[i]]
  if (length(tt) < 2) next
  for (j in 2:length(tt)) {
    g <- classifica(unname(prob_fem_tok[tt[j]]))
    if (!is.na(g)) { genero_rec[i] <- g; token_usado[i] <- tt[j]; break }
  }
}
capes$genero <- genero_rec
capes$token_classificador <- token_usado
capes$usou_recuperacao <- !is.na(capes$genero) & is.na(capes$genero_primeiro)

capes$motivo_nao_classificado <- dplyr::case_when(
  !is.na(capes$genero) ~ NA_character_,
  capes$n_tokens == 0 ~ "nome ausente ou ilegível",
  is.na(capes$prob_fem_primeiro) ~ "nome fora da base do Censo",
  TRUE ~ "nome unissex (probabilidade intermediária)"
)

message(">>> Distribuição do gênero imputado:")
print(table(capes$genero, useNA = "ifany"))

capes_ano <- capes %>% filter(!is.na(ano_unificado))
stopifnot(nrow(capes_ano) == nrow(capes))   # a base canônica não tem ano NA

# -----------------------------------------------------------------------------
# 4. Nível e subárea
# -----------------------------------------------------------------------------
# Nível: mesma leitura de grau do 08 (o layout antigo só tem o rótulo genérico
# "Profissionalizante", tratado como mestrado profissional).
capes_ano <- capes_ano %>%
  mutate(
    grau_raw = toupper(if_else(!is.na(an_base), nm_grau_academico, nivel)),
    nivel_2 = case_when(
      grepl("DOUTORADO", grau_raw) ~ "Doutorado",
      grepl("MESTRADO|PROFISSIONALIZANTE", grau_raw) ~ "Mestrado",
      TRUE ~ NA_character_
    )
  )
stopifnot(!any(is.na(capes_ano$nivel_2)))

# Subárea: reutiliza EXATAMENTE as regras de 10_classificacao_subareas_fun.R.
source(here::here("SCRIPTS", "10_classificacao_subareas_fun.R"))
classificar_capes <- function(df) {
  code <- df$area_conhecimento_codigo
  sub <- rep(NA_character_, nrow(df))
  sub <- ifelse(grepl("^7090", code) & !grepl("^70905", code), "CP", sub)
  sub <- ifelse(grepl("^70905", code), "RI", sub)
  prog <- ifelse(!is.na(df$an_base), df$nm_programa, df$nome_programa)
  por_nome <- classificar_programa(normaliza_prog(prog))
  sub <- ifelse(por_nome != "OUTROS", por_nome, sub)
  sub[is.na(sub)] <- "OUTROS"
  sub
}
capes_ano$subarea <- classificar_capes(capes_ano)

# Checagem de consistência: a classificação aqui tem de reproduzir, registro a
# registro, a série ano x subárea gravada pelo script 10. Se divergir, uma das
# duas está errada e nenhum número deve ir para o texto.
if (file.exists(file.path(dir_processed, "tabela_titulos_subareas.rds"))) {
  ref10 <- readRDS(file.path(dir_processed, "tabela_titulos_subareas.rds"))
  aqui <- capes_ano %>% count(ano = ano_unificado, subarea, name = "titulos")
  conf <- ref10 %>% filter(titulos > 0) %>%
    left_join(aqui, by = c("ano", "subarea"), suffix = c("_10", "_22"))
  stopifnot(identical(conf$titulos_10, conf$titulos_22))
  message(">>> Subáreas reproduzem a série do script 10.")
}

# Região/UF: existem apenas no layout novo (2013-2024). O recorte geográfico é,
# portanto, restrito a esse período — declarado no texto, não silenciado.
capes_ano$regiao <- capes_ano$nm_regiao

# -----------------------------------------------------------------------------
# 5. Séries com intervalo de confiança binomial (Wilson)
# -----------------------------------------------------------------------------
ic_wilson <- function(x, n, conf = 0.95) {
  z <- stats::qnorm(1 - (1 - conf) / 2)
  p <- x / n
  d <- 1 + z^2 / n
  centro <- (p + z^2 / (2 * n)) / d
  meio <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / d
  tibble(prop = p, ic_inf = pmax(0, centro - meio), ic_sup = pmin(1, centro + meio))
}

resume_genero <- function(df, ...) {
  df %>%
    group_by(...) %>%
    summarise(
      n_total = n(),
      n_classificado = sum(!is.na(genero)),
      n_fem = sum(genero == "Feminino", na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      taxa_classificacao = n_classificado / n_total,
      bind_cols(ic_wilson(n_fem, n_classificado))
    )
}

serie_anual <- resume_genero(capes_ano, ano = ano_unificado) %>% arrange(ano)
serie_nivel <- resume_genero(capes_ano, ano = ano_unificado, nivel = nivel_2) %>%
  arrange(ano, nivel)
por_nivel_total <- resume_genero(capes_ano, nivel = nivel_2)

# Subárea: por quinquênio, para não plotar ruído ano a ano.
capes_ano <- capes_ano %>%
  mutate(quinquenio = 5L * (ano_unificado %/% 5L),
         quinquenio_rot = paste0(quinquenio, "-", quinquenio + 4L))
por_subarea_quin <- resume_genero(capes_ano, quinquenio, quinquenio_rot, subarea) %>%
  arrange(quinquenio, subarea)
por_subarea_total <- resume_genero(capes_ano, subarea) %>% arrange(desc(n_total))

# Região: só 2013-2024.
por_regiao <- capes_ano %>%
  filter(!is.na(regiao)) %>%
  resume_genero(regiao) %>%
  arrange(desc(n_total))
por_regiao_periodo <- capes_ano %>%
  filter(!is.na(regiao)) %>%
  mutate(periodo = if_else(ano_unificado <= 2018, "2013-2018", "2019-2024")) %>%
  resume_genero(regiao, periodo) %>%
  arrange(regiao, periodo)

# Cobertura da classificação por período — o teste do viés temporal.
cobertura_periodo <- capes_ano %>%
  resume_genero(quinquenio, quinquenio_rot) %>%
  arrange(quinquenio) %>%
  select(quinquenio, quinquenio_rot, n_total, n_classificado, taxa_classificacao)

motivos <- capes_ano %>%
  filter(is.na(genero)) %>%
  count(motivo = motivo_nao_classificado, name = "n") %>%
  arrange(desc(n))

# Deriva temporal da taxa de classificação: regressão da taxa anual no ano.
mod_cob <- lm(taxa_classificacao ~ ano, data = serie_anual)
deriva_cob_pp_decada <- unname(coef(mod_cob)[["ano"]]) * 10 * 100

# -----------------------------------------------------------------------------
# 6. Unidade de análise: trabalho x pessoa, e sensibilidade da regra
# -----------------------------------------------------------------------------
# A unidade principal é o TRABALHO TITULADO. A mesma pessoa pode aparecer duas
# vezes (mestrado e doutorado). `id_pessoa_discente` só existe em 2013-2024, de
# modo que a contagem por pessoa é possível apenas nesse período.
novo <- capes_ano %>% filter(!is.na(id_pessoa_discente))
pessoas <- novo %>%
  arrange(ano_unificado) %>%
  distinct(id_pessoa_discente, .keep_all = TRUE)
n_trabalhos_novo <- nrow(novo)
n_pessoas_novo <- nrow(pessoas)
n_pessoas_repetidas <- n_trabalhos_novo - n_pessoas_novo
fem_trabalho_novo <- mean(novo$genero == "Feminino", na.rm = TRUE)
fem_pessoa_novo   <- mean(pessoas$genero == "Feminino", na.rm = TRUE)

# Sensibilidade: série sem a regra de recuperação (só primeiro token).
serie_anual_sem_rec <- capes_ano %>%
  group_by(ano = ano_unificado) %>%
  summarise(n_cls = sum(!is.na(genero_primeiro)),
            prop_sem_rec = mean(genero_primeiro == "Feminino", na.rm = TRUE),
            .groups = "drop")
serie_anual <- serie_anual %>% left_join(serie_anual_sem_rec, by = "ano")
dif_max_sensibilidade <- max(abs(serie_anual$prop - serie_anual$prop_sem_rec)) * 100
fem_geral <- mean(capes_ano$genero == "Feminino", na.rm = TRUE)
fem_geral_sem_rec <- mean(capes_ano$genero_primeiro == "Feminino", na.rm = TRUE)

# Tendência: regressão logística da probabilidade de autoria feminina no ano.
mod_tend <- glm(I(genero == "Feminino") ~ I(ano_unificado - 1987),
                family = binomial(), data = filter(capes_ano, !is.na(genero)))
or_decada <- exp(unname(coef(mod_tend)[2]) * 10)
ic_or_decada <- exp(confint.default(mod_tend)[2, ] * 10)

# -----------------------------------------------------------------------------
# 7. Figuras
# -----------------------------------------------------------------------------
library(patchwork)

# Quebra manual de linha: os textos longos do subtítulo e da nota estouram a
# largura de 8,5 pol se ficarem numa linha só.
quebra <- function(txt, largura = 105) paste(strwrap(txt, largura), collapse = "\n")

cores_nivel <- c("Mestrado" = okabe_ito[["laranja"]],
                 "Doutorado" = okabe_ito[["verde"]])

# --- Painel A: série anual do total, com IC ---------------------------------
# O total é a única série com n suficiente para leitura ANO A ANO em toda a
# janela (26 trabalhos em 1987 é pouco, e o IC mostra isso).
pA <- ggplot(serie_anual, aes(ano, prop)) +
  geom_hline(yintercept = 0.5, linetype = "dashed", colour = "grey55",
             linewidth = 0.35) +
  geom_ribbon(aes(ymin = ic_inf, ymax = ic_sup), fill = okabe_ito[["azul"]],
              alpha = 0.18) +
  geom_line(colour = okabe_ito[["azul"]], linewidth = 0.85) +
  geom_point(colour = okabe_ito[["azul"]], size = 1.1) +
  scale_y_continuous(labels = pct_ptbr(accuracy = 1),
                     limits = c(0.15, 0.72), breaks = seq(0.2, 0.7, 0.1)) +
  # Ano não leva separador de milhar: `num_ptbr()` fixa big.mark = "." e é
  # usado nos eixos de contagem, não no eixo de tempo.
  scale_x_continuous(breaks = seq(1990, 2024, 5),
                     labels = function(x) as.character(as.integer(x))) +
  labs(subtitle = "(a) Todos os trabalhos, por ano de titulação",
       x = "Ano de titulação", y = "Proporção de autoria feminina")

# --- Painel B: mestrado x doutorado, por quinquênio -------------------------
# POR QUE QUINQUÊNIO E NÃO ANO: até 2004 o doutorado da área tinha entre 2 e 28
# titulados por ano. A série anual por nível oscilava entre 0% e 67% só por
# tamanho de amostra. Agregar em quinquênios é preferível a plotar esse ruído.
serie_nivel_quin <- resume_genero(capes_ano, quinquenio, quinquenio_rot,
                                  nivel = nivel_2) %>%
  arrange(quinquenio, nivel)

# Além do quinquênio, um piso de 30 trabalhos classificados por ponto: o
# doutorado da área só passa desse patamar a partir do segundo quinquênio.
serie_nivel_plot <- serie_nivel_quin %>%
  filter(n_classificado >= 30) %>%
  mutate(nivel = factor(nivel, levels = names(cores_nivel)))

pB <- ggplot(serie_nivel_plot, aes(quinquenio, prop, colour = nivel)) +
  geom_hline(yintercept = 0.5, linetype = "dashed", colour = "grey55",
             linewidth = 0.35) +
  geom_linerange(aes(ymin = ic_inf, ymax = ic_sup), alpha = 0.35,
                 linewidth = 0.6) +
  geom_line(linewidth = 0.85) +
  geom_point(size = 1.4) +
  scale_colour_manual(values = cores_nivel, name = NULL) +
  scale_y_continuous(labels = pct_ptbr(accuracy = 1),
                     limits = c(0.15, 0.72), breaks = seq(0.2, 0.7, 0.1)) +
  scale_x_continuous(breaks = sort(unique(serie_nivel_plot$quinquenio)),
                     labels = function(x) paste0(x, "-", x + 4)) +
  labs(subtitle = "(b) Por nível, por quinquênio (barras: IC 95%)",
       x = "Quinquênio de titulação", y = NULL) +
  theme(axis.text.x = element_text(angle = 35, hjust = 1))

p_gen <- (pA | pB) +
  plot_annotation(
    title = "Participação feminina na autoria de teses e dissertações da Área 39",
    subtitle = quebra(paste0(
      "Proporção de trabalhos titulados cujo primeiro nome é classificado como ",
      "feminino. Faixa e barras: intervalo de confiança binomial de 95% (Wilson). ",
      "Linha tracejada: paridade.")),
    caption = quebra(paste0(
      "Fonte: Catálogo de Teses e Dissertações da CAPES, Área 39, 1987-2024 (",
      format(nrow(capes_ano), big.mark = "."), " trabalhos; ",
      format(sum(!is.na(capes_ano$genero)), big.mark = "."),
      " com gênero imputado). Imputação pelo primeiro nome com o pacote genderBR ",
      "(frequências por sexo do Censo Demográfico ", CENSO_ANO,
      ", IBGE), limiar de ", sub("\\.", ",", LIMIAR_PROB),
      ". É uma imputação probabilística e binária por construção do método: ",
      "não mede identidade de gênero.")),
    theme = theme_artigo()
  )

ggsave(file.path(dir_figuras, "fig23_genero_temporal.png"), p_gen,
       width = 8.5, height = 4.9, dpi = 300, bg = "white")
ggsave(file.path(dir_figuras, "fig23_genero_temporal.pdf"), p_gen,
       width = 8.5, height = 4.9, device = grDevices::cairo_pdf, bg = "white")

# Apêndice: subáreas substantivas com n suficiente, por quinquênio. OUTROS é
# categoria residual (programas interdisciplinares heterogêneos) e não é
# plotada mesmo tendo n acima do piso: a média de um resíduo não é grandeza
# interpretável. SEGPUB fica de fora por n insuficiente.
sub_ok <- por_subarea_total$subarea[por_subarea_total$n_total >= N_MIN_RECORTE &
                                      por_subarea_total$subarea != "OUTROS"]
sub_por_n <- setdiff(por_subarea_total$subarea[por_subarea_total$n_total < N_MIN_RECORTE],
                     "OUTROS")
sub_excluidas <- setdiff(por_subarea_total$subarea, sub_ok)
dados_sub <- por_subarea_quin %>%
  filter(subarea %in% sub_ok, n_classificado >= 30)

p_sub <- ggplot(dados_sub, aes(quinquenio, prop, colour = subarea)) +
  geom_hline(yintercept = 0.5, linetype = "dashed", colour = "grey55",
             linewidth = 0.35) +
  geom_linerange(aes(ymin = ic_inf, ymax = ic_sup), alpha = 0.35,
                 linewidth = 0.6) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.4) +
  scale_colour_manual(values = unname(okabe_ito[c(6, 2, 4, 7, 8, 9)]),
                      name = NULL) +
  scale_y_continuous(labels = pct_ptbr(accuracy = 1),
                     limits = c(0.18, 0.72), breaks = seq(0.2, 0.7, 0.1)) +
  scale_x_continuous(breaks = sort(unique(dados_sub$quinquenio)),
                     labels = function(x) paste0(x, "-", x + 4)) +
  labs(
    title = "Autoria feminina por subárea da Área 39",
    subtitle = quebra(paste0("Quinquênios com pelo menos 30 trabalhos ",
                             "classificados; barras verticais: IC 95% (Wilson)")),
    x = "Quinquênio de titulação", y = "Proporção de autoria feminina",
    caption = quebra(paste0(
      "Fonte: Catálogo de Teses e Dissertações da CAPES, Área 39. Subáreas pela ",
      "regra de 10_classificacao_subareas_fun.R. Não plotadas: a categoria ",
      "residual OUTROS e as subáreas com menos de ",
      format(N_MIN_RECORTE, big.mark = "."), " trabalhos na série",
      if (length(sub_por_n)) paste0(" (", paste(sub_por_n, collapse = ", "), ")") else "",
      "."))
  ) +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))

ggsave(file.path(dir_figuras, "fig23b_genero_subarea.png"), p_sub,
       width = 8.5, height = 4.9, dpi = 300, bg = "white")
ggsave(file.path(dir_figuras, "fig23b_genero_subarea.pdf"), p_sub,
       width = 8.5, height = 4.9, device = grDevices::cairo_pdf, bg = "white")

# -----------------------------------------------------------------------------
# 8. Tabelas e artefatos
# -----------------------------------------------------------------------------
registros_out <- capes_ano %>%
  select(ano = ano_unificado, layout, nivel = nivel_2, subarea, regiao,
         nome_bruto, primeiro_nome, token_classificador, prob_fem_primeiro,
         genero, genero_primeiro, usou_recuperacao, motivo_nao_classificado,
         id_pessoa_discente)
saveRDS(registros_out, file.path(dir_processed, "genero_autoria_registros.rds"))
saveRDS(serie_anual, file.path(dir_processed, "genero_serie_anual.rds"))

write_csv(serie_anual, file.path(dir_tabelas, "tabela_genero_serie_anual.csv"))
write_csv(serie_nivel, file.path(dir_tabelas, "tabela_genero_por_nivel.csv"))
write_csv(por_subarea_quin, file.path(dir_tabelas, "tabela_genero_por_subarea.csv"))
write_csv(por_regiao_periodo, file.path(dir_tabelas, "tabela_genero_por_regiao.csv"))
write_csv(cobertura_periodo, file.path(dir_tabelas, "tabela_genero_cobertura_periodo.csv"))

# -----------------------------------------------------------------------------
# 9. Valores inline
# -----------------------------------------------------------------------------
ano_ini <- min(serie_anual$ano); ano_fim <- max(serie_anual$ano)
lin_ini <- serie_anual %>% filter(ano == ano_ini)
lin_fim <- serie_anual %>% filter(ano == ano_fim)
# Primeiro quinquênio vs. último: base mais estável que um ano isolado.
q_ini <- capes_ano %>% filter(ano_unificado <= 1991) %>% resume_genero()
q_fim <- capes_ano %>% filter(ano_unificado >= 2020) %>% resume_genero()
ano_paridade <- serie_anual %>% filter(ic_inf > 0.5) %>% slice_head(n = 1)

nivel_fim <- capes_ano %>% filter(ano_unificado >= 2020) %>% resume_genero(nivel = nivel_2)
nivel_ini <- capes_ano %>% filter(ano_unificado <= 1999) %>% resume_genero(nivel = nivel_2)

valores <- list(
  # --- escopo e método ---
  n_trabalhos = nrow(capes_ano),
  ano_inicio = ano_ini,
  ano_fim = ano_fim,
  pacote = "genderBR",
  pacote_versao = as.character(utils::packageVersion("genderBR")),
  censo_ano = CENSO_ANO,
  limiar = LIMIAR_PROB,
  coluna_nome = "coalesce(nm_discente, autor)",
  cobertura_nome = cobertura_nome,
  n_nome_ausente = n_nome_ausente,
  n_sem_token = n_sem_token,
  n_nomes_unicos_consultados = length(tokens_unicos),

  # --- cobertura da classificação ---
  n_classificado = sum(!is.na(capes_ano$genero)),
  n_nao_classificado = sum(is.na(capes_ano$genero)),
  taxa_classificacao = mean(!is.na(capes_ano$genero)),
  taxa_classificacao_sem_rec = mean(!is.na(capes_ano$genero_primeiro)),
  taxa_min_quinquenio = min(cobertura_periodo$taxa_classificacao),
  taxa_max_quinquenio = max(cobertura_periodo$taxa_classificacao),
  quinq_taxa_min = cobertura_periodo$quinquenio_rot[which.min(cobertura_periodo$taxa_classificacao)],
  amplitude_taxa_pp = 100 * (max(cobertura_periodo$taxa_classificacao) -
                               min(cobertura_periodo$taxa_classificacao)),
  deriva_cobertura_pp_decada = deriva_cob_pp_decada,
  cobertura_periodo = cobertura_periodo,
  motivos_nao_classificacao = motivos,
  n_usou_recuperacao = sum(capes_ano$usou_recuperacao),

  # --- resultado principal ---
  fem_geral = fem_geral,
  fem_ano_inicio = lin_ini$prop,
  n_ano_inicio = lin_ini$n_classificado,
  fem_ano_fim = lin_fim$prop,
  fem_ano_fim_ic = c(lin_fim$ic_inf, lin_fim$ic_sup),
  n_ano_fim = lin_fim$n_classificado,
  fem_1987_1991 = q_ini$prop,
  n_1987_1991 = q_ini$n_classificado,
  fem_2020_2024 = q_fim$prop,
  n_2020_2024 = q_fim$n_classificado,
  variacao_pp = 100 * (q_fim$prop - q_ini$prop),
  # Nenhum ano da série tem IC 95% inteiramente acima de 50%: a paridade é
  # alcançada como estimativa pontual em alguns anos, não com confiança
  # estatística. Os dois campos abaixo existem para que o texto diga isso, e
  # não invente um "ano da virada".
  primeiro_ano_maioria_fem_ic = if (nrow(ano_paridade)) ano_paridade$ano else NA_integer_,
  houve_maioria_fem_ic = nrow(ano_paridade) > 0,
  anos_maioria_fem_pontual = serie_anual$ano[serie_anual$prop > 0.5],
  n_anos_maioria_fem_pontual = sum(serie_anual$prop > 0.5),
  or_decada = or_decada,
  or_decada_ic = ic_or_decada,

  # --- nível ---
  serie_nivel = serie_nivel,
  serie_nivel_quinquenio = serie_nivel_quin,
  fem_nivel_total = setNames(por_nivel_total$prop, por_nivel_total$nivel),
  n_nivel_total = setNames(por_nivel_total$n_classificado, por_nivel_total$nivel),
  fem_mestrado_2020_2024 = nivel_fim$prop[nivel_fim$nivel == "Mestrado"],
  fem_mestrado_2020_2024_ic = c(nivel_fim$ic_inf[nivel_fim$nivel == "Mestrado"],
                                nivel_fim$ic_sup[nivel_fim$nivel == "Mestrado"]),
  fem_doutorado_2020_2024 = nivel_fim$prop[nivel_fim$nivel == "Doutorado"],
  fem_doutorado_2020_2024_ic = c(nivel_fim$ic_inf[nivel_fim$nivel == "Doutorado"],
                                 nivel_fim$ic_sup[nivel_fim$nivel == "Doutorado"]),
  n_mestrado_2020_2024 = nivel_fim$n_classificado[nivel_fim$nivel == "Mestrado"],
  n_doutorado_2020_2024 = nivel_fim$n_classificado[nivel_fim$nivel == "Doutorado"],
  fem_mestrado_1987_1999 = nivel_ini$prop[nivel_ini$nivel == "Mestrado"],
  fem_doutorado_1987_1999 = nivel_ini$prop[nivel_ini$nivel == "Doutorado"],
  hiato_nivel_2020_2024_pp = 100 * (nivel_fim$prop[nivel_fim$nivel == "Mestrado"] -
                                      nivel_fim$prop[nivel_fim$nivel == "Doutorado"]),

  # --- subárea ---
  por_subarea_total = por_subarea_total,
  fem_subarea = setNames(por_subarea_total$prop, por_subarea_total$subarea),
  n_subarea = setNames(por_subarea_total$n_classificado, por_subarea_total$subarea),
  subareas_plotadas = sub_ok,
  subareas_nao_plotadas = sub_excluidas,
  subareas_n_insuficiente = sub_por_n,
  n_subarea_insuficiente = por_subarea_total$n_total[por_subarea_total$subarea %in% sub_por_n],
  n_min_recorte = N_MIN_RECORTE,

  # --- região (2013-2024) ---
  por_regiao = por_regiao,
  regiao_periodo_inicio = 2013L,
  fem_regiao = setNames(por_regiao$prop, por_regiao$regiao),
  n_regiao = setNames(por_regiao$n_classificado, por_regiao$regiao),
  regiao_max = por_regiao$regiao[which.max(por_regiao$prop)],
  regiao_max_prop = max(por_regiao$prop),
  regiao_min = por_regiao$regiao[which.min(por_regiao$prop)],
  regiao_min_prop = min(por_regiao$prop),
  regiao_menor_n = por_regiao$regiao[which.min(por_regiao$n_total)],
  regiao_menor_n_val = min(por_regiao$n_total),

  # --- trabalho x pessoa ---
  n_trabalhos_2013_2024 = n_trabalhos_novo,
  n_pessoas_2013_2024 = n_pessoas_novo,
  n_pessoas_repetidas = n_pessoas_repetidas,
  fem_trabalho_2013_2024 = fem_trabalho_novo,
  fem_pessoa_2013_2024 = fem_pessoa_novo,
  dif_trabalho_pessoa_pp = 100 * (fem_trabalho_novo - fem_pessoa_novo),

  # --- sensibilidade ---
  fem_geral_sem_recuperacao = fem_geral_sem_rec,
  dif_sensibilidade_pp = 100 * abs(fem_geral - fem_geral_sem_rec),
  dif_max_sensibilidade_pp = dif_max_sensibilidade
)
saveRDS(valores, file.path(dir_processed, "valores_inline_genero.rds"))

cat("\n=== GÊNERO NA AUTORIA — RESUMO ===\n")
cat("Trabalhos:", valores$n_trabalhos,
    "| classificados:", valores$n_classificado,
    sprintf("(%.1f%%)", 100 * valores$taxa_classificacao), "\n")
cat("Taxa por quinquênio: min", sprintf("%.1f%%", 100 * valores$taxa_min_quinquenio),
    "max", sprintf("%.1f%%", 100 * valores$taxa_max_quinquenio),
    "| deriva", sprintf("%.2f pp/década", valores$deriva_cobertura_pp_decada), "\n")
cat("Feminino 1987-1991:", sprintf("%.1f%%", 100 * valores$fem_1987_1991),
    "-> 2020-2024:", sprintf("%.1f%%", 100 * valores$fem_2020_2024),
    sprintf("(+%.1f pp)", valores$variacao_pp), "\n")
cat("OR por década:", sprintf("%.3f", valores$or_decada), "\n")
cat("Primeiro ano com maioria feminina (IC>50%):", valores$primeiro_ano_maioria_fem, "\n")
print(por_nivel_total)
print(por_subarea_total)
print(por_regiao)
cat("\n>>> ANÁLISE DE GÊNERO CONCLUÍDA!\n")
