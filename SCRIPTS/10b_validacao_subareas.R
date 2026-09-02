#!/usr/bin/env Rscript
# ==============================================================================
# 10b_validacao_subareas.R — Validação da classificação automática em subáreas
# ==============================================================================
# Fase 2, T2.5 do PLANO_OPUS5.
#
# A classificação de subáreas do artigo é feita pelo NOME DO PROGRAMA. A
# pergunta que este script responde é: quando o programa se chama "Ciência
# Política", o trabalho defendido ali é mesmo de ciência política? Sem essa
# medida, o "35% de ciência política estrita" é uma estimativa com erro
# desconhecido.
#
# Desenho: amostra estratificada de 240 títulos (40 por classe, semente
# 20260828), gravada por 10_classificacao_subareas.R em
# TABELAS/amostra_validacao_subareas.csv. Cada item foi lido (título, programa
# e, quando necessário, resumo) e recebeu uma classe de referência.
#
# LIMITE DECLARADO — leia antes de citar estes números: a codificação de
# referência disponível hoje é de UM ÚNICO codificador
# (DADOS/validacao/codificacao_subareas_cod1.csv, sessão de 2026-09-02, feita
# com base no título e no nome do programa). O desenho previsto no plano exige
# DOIS codificadores independentes e um kappa entre eles. Enquanto o segundo
# codificador não existir, este script calcula precisão, recall e F1 contra o
# codificador 1 e NÃO reporta kappa entre codificadores; a concordância
# reportada é entre a REGRA AUTOMÁTICA e o codificador humano, não entre dois
# humanos. Preencher `classe_cod2` em codificacao_subareas_cod2.csv fecha o
# item; o script detecta o arquivo sozinho.
# ==============================================================================

source(here::here("SCRIPTS", "00_setup.R"))
source(here::here("SCRIPTS", "10_classificacao_subareas_fun.R"))

dir_processed <- here::here("DADOS", "processed")
dir_tabelas   <- here::here("TABELAS")
dir_validacao <- here::here("DADOS", "validacao")

amostra <- read_csv(file.path(dir_tabelas, "amostra_validacao_subareas.csv"),
                    show_col_types = FALSE)
cod1 <- read_csv(file.path(dir_validacao, "codificacao_subareas_cod1.csv"),
                 show_col_types = FALSE)
val <- amostra %>% select(-classe_cod1, -classe_cod2) %>%
  left_join(cod1, by = "id_amostra")

f_cod2 <- file.path(dir_validacao, "codificacao_subareas_cod2.csv")
tem_cod2 <- file.exists(f_cod2)
if (tem_cod2) {
  val <- val %>% left_join(read_csv(f_cod2, show_col_types = FALSE), by = "id_amostra")
}

stopifnot(!any(is.na(val$classe_cod1)))
stopifnot(all(val$classe_cod1 %in% CLASSES), all(val$classe_auto %in% CLASSES))

# Referência: o codificador 1 (ou a concordância entre os dois, quando houver).
val <- val %>% mutate(referencia = classe_cod1)

# ---------------------------------------------------------------------------
# Matriz de confusão e métricas por classe
# ---------------------------------------------------------------------------
confusao <- table(auto = factor(val$classe_auto, CLASSES),
                  referencia = factor(val$referencia, CLASSES))
write.csv(as.data.frame.matrix(confusao),
          file.path(dir_tabelas, "tabela_validacao_confusao_subareas.csv"))

metricas <- purrr::map_dfr(CLASSES, function(k) {
  tp <- sum(val$classe_auto == k & val$referencia == k)
  fp <- sum(val$classe_auto == k & val$referencia != k)
  fn <- sum(val$classe_auto != k & val$referencia == k)
  prec <- if ((tp + fp) > 0) tp / (tp + fp) else NA_real_
  rec  <- if ((tp + fn) > 0) tp / (tp + fn) else NA_real_
  tibble(classe = k, n_auto = tp + fp, n_referencia = tp + fn,
         precisao = prec, recall = rec,
         f1 = if (is.na(prec) || is.na(rec) || (prec + rec) == 0) NA_real_ else 2 * prec * rec / (prec + rec))
})
write_csv(metricas, file.path(dir_tabelas, "tabela_validacao_metricas_subareas.csv"))

# ---------------------------------------------------------------------------
# Concordância global e kappa de Cohen (automático x humano)
# ---------------------------------------------------------------------------
kappa_cohen <- function(a, b, niveis = CLASSES) {
  tb <- table(factor(a, niveis), factor(b, niveis))
  n <- sum(tb)
  po <- sum(diag(tb)) / n
  pe <- sum(rowSums(tb) * colSums(tb)) / n^2
  (po - pe) / (1 - pe)
}
acuracia <- mean(val$classe_auto == val$referencia)
kappa_auto <- kappa_cohen(val$classe_auto, val$referencia)
kappa_humanos <- if (tem_cod2) kappa_cohen(val$classe_cod1, val$classe_cod2) else NA_real_

# A amostra é ESTRATIFICADA por classe automática (40 por classe): a acurácia
# calculada nela NÃO é a acurácia no corpus, porque as classes têm tamanhos
# muito diferentes na população. A precisão por classe, sim, é estimável
# diretamente (o estrato é definido pela predição). A acurácia ponderada
# abaixo repondera cada estrato pela frequência real da classe automática no
# corpus de 2024.
serie <- readRDS(file.path(dir_processed, "tabela_titulos_subareas.rds"))
peso <- serie %>% filter(ano == 2024) %>%
  mutate(w = titulos / sum(titulos)) %>% select(classe = subarea, w)
acuracia_ponderada <- val %>%
  group_by(classe = classe_auto) %>%
  summarise(acerto = mean(classe_auto == referencia), .groups = "drop") %>%
  left_join(peso, by = "classe") %>%
  summarise(v = sum(acerto * w, na.rm = TRUE)) %>% pull(v)

resultado <- list(
  n = nrow(val), classes = CLASSES,
  confusao = confusao, metricas = metricas,
  acuracia_amostra = round(100 * acuracia, 1),
  acuracia_ponderada_2024 = round(100 * acuracia_ponderada, 1),
  kappa_auto_humano = round(kappa_auto, 3),
  kappa_entre_codificadores = kappa_humanos,
  n_codificadores = if (tem_cod2) 2L else 1L,
  precisao_cp = round(100 * metricas$precisao[metricas$classe == "CP"], 1),
  recall_cp = round(100 * metricas$recall[metricas$classe == "CP"], 1),
  precisao_media_macro = round(100 * mean(metricas$precisao, na.rm = TRUE), 1),
  recall_medio_macro = round(100 * mean(metricas$recall, na.rm = TRUE), 1),
  nota = paste("Codificação de referência por um único codificador",
               "(sessão de 2026-09-02), com base em título e nome do programa.",
               "Um segundo codificador independente e o kappa entre humanos",
               "continuam pendentes.")
)

v_sub <- readRDS(file.path(dir_processed, "valores_inline_subareas.rds"))
v_sub$validacao <- resultado
saveRDS(v_sub, file.path(dir_processed, "valores_inline_subareas.rds"))
saveRDS(resultado, file.path(dir_processed, "validacao_subareas.rds"))

cat("=== VALIDAÇÃO DA CLASSIFICAÇÃO EM SUBÁREAS ===\n")
cat("n =", nrow(val), "| codificadores:", resultado$n_codificadores, "\n")
cat("Acurácia na amostra estratificada:", resultado$acuracia_amostra, "%\n")
cat("Acurácia reponderada pela composição de 2024:", resultado$acuracia_ponderada_2024, "%\n")
cat("Kappa (regra automática x codificador humano):", resultado$kappa_auto_humano, "\n\n")
print(metricas)
cat("\nMatriz de confusão (linhas = regra automática, colunas = referência):\n")
print(confusao)
