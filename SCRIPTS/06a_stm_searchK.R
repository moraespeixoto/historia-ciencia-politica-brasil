#!/usr/bin/env Rscript
# ==============================================================================
# 06a_stm_searchK.R — Diagnóstico do número de tópicos (K) e do corpus
# ==============================================================================
# Fase 2, T2.1 e T2.2 do PLANO_OPUS5.
#
# A versão anterior do artigo declarava "K = 8 estimado por simplicidade", sem
# nenhum procedimento formal de seleção. Este script roda `stm::searchK` sobre
# o objeto de `prepDocuments` gravado por 06 e reporta, para cada K:
#   - coerência semântica  (quão bem os termos de um tópico coocorrem)
#   - exclusividade FREX   (quão pouco os termos são compartilhados entre tópicos)
#   - held-out likelihood  (ajuste fora da amostra)
#   - resíduos             (dispersão excessiva = K pequeno demais)
#
# Roda o diagnóstico DUAS VEZES: no corpus completo (multilíngue) e no corpus
# restrito a resumos em português. A comparação é o insumo da decisão de corpus.
#
# Uso: Rscript SCRIPTS/06a_stm_searchK.R [--rapido]
#   --rapido usa uma grade menor de K (para testar o encanamento).
# ==============================================================================

source(here::here("SCRIPTS", "00_setup.R"))
suppressPackageStartupMessages(library(stm))

dir_processed <- here::here("DADOS", "processed")
dir_figuras   <- here::here("FIGURAS")
dir_tabelas   <- here::here("TABELAS")

args <- commandArgs(trailingOnly = TRUE)
grade_K <- if ("--rapido" %in% args) c(6, 8, 10) else c(6, 8, 10, 12, 15, 20, 25)
n_cores <- max(1L, min(4L, parallel::detectCores() - 1L))

prep <- readRDS(file.path(dir_processed, "stm_prep.rds"))

# ---------------------------------------------------------------------------
# Reconstrói o objeto de entrada para um recorte de idioma dado. Refazer
# prepDocuments para o subcorpus em português é obrigatório: o vocabulário e o
# limiar `lower.thresh` mudam quando 9% dos documentos saem.
# ---------------------------------------------------------------------------
preparar <- function(idioma) {
  meta <- prep$meta
  idx <- if (identical(idioma, "pt")) which(!is.na(meta$idioma_resumo) & meta$idioma_resumo == "pt")
         else seq_len(nrow(meta))
  docs <- prep$documents[idx]
  m <- meta[idx, , drop = FALSE]
  out <- prepDocuments(docs, prep$vocab, m, lower.thresh = 20, verbose = FALSE)
  out
}

rodar_searchK <- function(out, etiqueta) {
  message(">>> searchK [", etiqueta, "]: ", length(out$documents), " documentos, ",
          length(out$vocab), " termos, K em {", paste(grade_K, collapse = ", "), "}")
  set.seed(20260828)
  sk <- searchK(out$documents, out$vocab, K = grade_K,
                prevalence = ~ s(ano) + fonte, data = out$meta,
                N = floor(0.1 * length(out$documents)),
                heldout.seed = 20260828, init.type = "Spectral",
                cores = n_cores)
  res <- as.data.frame(lapply(sk$results, unlist))
  res$corpus <- etiqueta
  res
}

out_todos <- preparar("todos")
out_pt    <- preparar("pt")

res <- bind_rows(
  rodar_searchK(out_todos, "completo (multilíngue)"),
  rodar_searchK(out_pt, "somente português")
)

write_csv(res, file.path(dir_tabelas, "tabela_stm_searchK.csv"))
saveRDS(list(resultados = res, grade_K = grade_K,
             n_docs_todos = length(out_todos$documents),
             n_docs_pt = length(out_pt$documents)),
        file.path(dir_processed, "stm_searchK.rds"))

# ---------------------------------------------------------------------------
# Figura de diagnóstico: fronteira coerência x exclusividade e held-out
# ---------------------------------------------------------------------------
p_diag <- res %>%
  select(corpus, K, semcoh, exclus, heldout, residual) %>%
  pivot_longer(c(semcoh, exclus, heldout, residual),
               names_to = "metrica", values_to = "valor") %>%
  mutate(metrica = recode(metrica,
                          semcoh = "Coerência semântica",
                          exclus = "Exclusividade (FREX)",
                          heldout = "Verossimilhança held-out",
                          residual = "Resíduos")) %>%
  ggplot(aes(K, valor, colour = corpus)) +
  geom_line(linewidth = .8) + geom_point(size = 1.6) +
  facet_wrap(~metrica, scales = "free_y") +
  scale_x_continuous(breaks = grade_K) +
  scale_colour_manual(values = c("completo (multilíngue)" = "#999999",
                                 "somente português" = "#0072B2"), name = NULL) +
  labs(title = "Diagnóstico do número de tópicos (searchK)",
       subtitle = "Corpus completo e corpus restrito a resumos em português",
       x = "K (número de tópicos)", y = NULL,
       caption = "Fonte: stm::searchK sobre o corpus integrado CAPES/OpenAlex. Elaboração própria.") +
  theme_artigo() + theme(legend.position = "bottom")
ggsave(file.path(dir_figuras, "figA1_stm_searchK.png"), p_diag, width = 8.5, height = 5.6, dpi = 300)
ggsave(file.path(dir_figuras, "figA1_stm_searchK.pdf"), p_diag, width = 8.5, height = 5.6)

p_front <- res %>%
  ggplot(aes(semcoh, exclus, colour = corpus)) +
  geom_path(alpha = .5) + geom_point(size = 2) +
  ggrepel::geom_text_repel(aes(label = K), size = 3, show.legend = FALSE) +
  scale_colour_manual(values = c("completo (multilíngue)" = "#999999",
                                 "somente português" = "#0072B2"), name = NULL) +
  labs(title = "Fronteira coerência semântica x exclusividade",
       subtitle = "Cada ponto é um valor de K; o canto superior direito é o melhor compromisso",
       x = "Coerência semântica", y = "Exclusividade (FREX)",
       caption = "Fonte: stm::searchK. Elaboração própria.") +
  theme_artigo() + theme(legend.position = "bottom")
ggsave(file.path(dir_figuras, "figA2_stm_fronteira.png"), p_front, width = 7.5, height = 5, dpi = 300)

print(res %>% select(corpus, K, semcoh, exclus, heldout, residual) %>% arrange(corpus, K))
cat("\n>>> searchK concluído. Escreva a decisão em stm_config.rds e reexecute 06.\n")
