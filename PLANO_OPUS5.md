# PLANO_OPUS5 — Plano de execução para reconstrução do artigo

**Projeto:** `/dados/historia_ciencia_politica_brasil`
**Insumo:** `REVISAO_CRITICA.md` (IDs F01–F34 referenciados abaixo)
**Executor:** Opus 5 (planeja/verifica) + Sonnet (execução mecânica de scripts e edições longas, conforme fluxo de trabalho do usuário)
**Data:** 2026-09-01

---

## Regras invioláveis

1. **Nunca escrever número no corpo do `.qmd` à mão.** Todo valor sai de `DADOS/processed/valores_inline_*.rds` ou de `TABELAS/*.csv` via `` `r ` `` inline. Se um número precisa aparecer e não existe no RDS, crie-o no script que o produz, reexecute, e só então cite.
2. **Nunca fabricar valores, datas ou referências.** Fatos históricos sem fonte primária ficam marcados `[verificar]` no `.qmd` até resolução; referências novas entram no `.bib` com `note = {[verificar]}` até que DOI/páginas sejam confirmados (`mcp__pesquisa-br__crossref_verificar` ou consulta manual).
3. **Editar apenas `.qmd`, `.R`, `.bib`, `.md`, `.csv` de insumo manual.** Nunca editar `.tex`, `.pdf`, `.html` gerados.
4. **Toda alteração em script exige reexecução em ordem de dependência e teste de regressão** (`SCRIPTS/99_testes_regressao.R`, criado na Fase 1) antes de editar o texto.
5. **Manter o rodapé de commit do repositório** (se houver git; hoje o diretório não é repositório — ver Fase 6).
6. **Ordem do pipeline** (respeitar): 01 → 02 → 03 → 04 → 05 → 07 → 08 → 10 → 12 → 13 → 14 → 15 → 18 → 19 → 06 → 06b → `.qmd`. (08 produz a base canônica que 10/13/14/18 consomem; 05 consome 03/04; 06/06b consomem 05+08.) Antes de começar, confirmar a ordem lendo o cabeçalho de cada script — se divergir, o cabeçalho manda.
7. **Render final sempre via** `~/.claude/scripts/verificar_render_qmd.sh artigo_historia_cp_brasil.qmd --to all --cache-refresh` e verificação de `NA|NaN|Inf` no texto extraído.
8. Não apagar `AUDITORIA.md`; acrescentar seção "§10 — Rodada 2026-09" com o que foi corrigido.

---

## Fase 0 — Alvo editorial e restrições (0,5 dia)

**Objetivo.** Fixar revista, idioma, limite de palavras e formato antes de reescrever.

**Passos.**
1. Decisão com o autor entre (a) BPSR (inglês; replicação obrigatória; continuidade com Marenco 2014), (b) DADOS, (c) RSP/RBCP. Registrar em `README.md` § "Alvo editorial".
2. Confirmar nos sites das revistas [verificar]: limite de palavras, formato de resumo, número de figuras, política de dados, formato de citação (todas autor-data; ABNT só em algumas revistas de educação — não é o caso).
3. Definir orçamento: ≤ 9.000 palavras (corpo + notas + refs), ≤ 8 figuras, ≤ 3 tabelas no corpo; resumo ≤ 200 palavras; abstract; 5 palavras-chave.
4. Criar `SUPLEMENTAR/` (pasta) e `suplementar.qmd` para receber: auditoria, sessionInfo, tabela de associações, mapeamento de subáreas, searchK, validação manual, figuras excedentes.

**Aceitação.** `README.md` contém revista-alvo, limites e checklist de submissão; `suplementar.qmd` renderiza (mesmo vazio).

---

## Fase 1 — Correções P0/P1 em dados e código (2–3 dias)

Ordem: T1.0 (testes) → T1.1 (13) → T1.2 (14) → T1.3 (08) → T1.4 (10) → T1.5 (03/05) → T1.6 (18) → T1.7 (15) → T1.8 (06b) → T1.9 (19) → T1.10 (bib/qmd mecânico).

### T1.0 — Testes de regressão (criar `SCRIPTS/99_testes_regressao.R`)

**Objetivo.** Fixar os números canônicos que não devem mudar e os que devem mudar para valores conhecidos.

```r
# SCRIPTS/99_testes_regressao.R
suppressPackageStartupMessages({library(here); library(dplyr); library(testthat)})
v_temp <- readRDS(here("DADOS/processed/valores_inline_temporal.rds"))
v_sub  <- readRDS(here("DADOS/processed/valores_inline_subareas.rds"))
comp   <- readRDS(here("DADOS/processed/comparacao_areas_sucupira.rds"))

test_that("serie principal Area 39 estavel", {
  expect_equal(v_temp$total_titulos, 12661)
  expect_equal(v_temp$pico_titulos, 1002); expect_equal(v_temp$ano_pico, 2024)
  expect_equal(v_temp$n_programas_2024, 64)
  expect_equal(v_temp$total_programas_unicos, 67)          # F04: era 69
})
test_that("codigos de area corretos (F01)", {
  p24 <- comp$programas %>% filter(ano == 2024)
  esperado <- c("Geografia"=80, "História"=80, "Economia"=76,
                "Ciência Política / RI"=64, "Sociologia"=52,
                "Antropologia / Arqueologia"=38)
  obs <- setNames(p24$programas, p24$area)[names(esperado)]
  expect_equal(obs, esperado)
  p13 <- comp$programas %>% filter(ano == 2013)
  expect_equal(p13$programas[p13$area == "Ciência Política / RI"], 32)
})
test_that("modalidade (F02)", {
  m24 <- comp$modalidade %>% filter(ano == 2024, area == "Ciência Política / RI")
  expect_equal(m24$programas[m24$modalidade == "PROFISSIONAL"], 20)
})
test_that("subareas somam 100% (F05)", {
  expect_equal(sum(unlist(v_sub$pct_2024[c("CP","RI","PP","DEFESA","OUTROS")])), 100, tolerance = 0.11)
  expect_equal(sum(unlist(v_sub$programas_2024)), 64)
})
```
Adicionar testes para OpenAlex (T1.5) e STM (T1.8) quando os valores novos forem conhecidos.

**Validação.** `Rscript SCRIPTS/99_testes_regressao.R` falha antes das correções (F01/F04) e passa depois.

### T1.1 — Corrigir códigos de área (F01, F11, F02) em `SCRIPTS/13_comparacao_sucupira.R`

**Passos.**
1. Substituir:
```r
areas_alvo <- c("28" = "Economia", "34" = "Sociologia",
                "35" = "Antropologia / Arqueologia", "36" = "Geografia",
                "39" = "Ciência Política / RI", "40" = "História")
```
2. Adicionar asserção logo após a leitura de cada ano:
```r
chk <- prog_raw %>% filter(cd_area_avaliacao %in% names(areas_alvo)) %>%
  distinct(cd_area_avaliacao, nm_area_avaliacao)
stopifnot(all(grepl("ECONOMIA", chk$nm_area_avaliacao[chk$cd_area_avaliacao=="28"])),
          all(grepl("SOCIOLOGIA", chk$nm_area_avaliacao[chk$cd_area_avaliacao=="34"])),
          all(grepl("ANTROPOLOGIA", chk$nm_area_avaliacao[chk$cd_area_avaliacao=="35"])),
          all(grepl("HIST", chk$nm_area_avaliacao[chk$cd_area_avaliacao=="40"])))
```
3. Excluir `ds_situacao_programa == "EM DESATIVACAO"` **antes** de qualquer contagem (já feito para 39; garantir para as seis).
4. Criar tabela `modalidade` (área × ano × `nm_modalidade_programa`) e `grau` (área × ano × `nm_grau_programa`).
5. `docentes_por_programa` com **permanentes**; manter total em coluna separada.
6. Conceito: substituir média por distribuição (`prop_3`, `prop_4`, `prop_5`, `prop_6_7`, `n_A`).
7. Salvar tudo em `comparacao_areas_sucupira.rds` (lista) e CSVs; atualizar `valores_inline_comparacao*.rds` — eliminar o órfão (F27) ou unificá-lo.

**Validação.** Testes T1.0 passam; `TABELAS/tabela_comparacao_painel_integrado.csv` 2024: Geografia 80, História 80, Economia 76, CP/RI 64, Sociologia 52, Antropologia 38; UFs: Geografia 27, História 25, Sociologia 22, Antropologia 22, Economia 20, CP/RI 15.

**Efeito no texto.** §4.1.1 inteira; Resumo ("menor sistema" → "sistema intermediário que mais cresceu, com maior peso de mestrados profissionais"); Introdução; Discussão; Conclusão; legendas Figs 10/12/13/14.

### T1.2 — `SCRIPTS/14_*` (comparação de títulos 1987–2024, F09, F25, F32)

1. Layout antigo: incluir 7040 em Antropologia; confirmar mapa de códigos CNPq×área com `area_avaliacao` textual (preferir texto quando disponível).
2. Layout novo: usar `nm_area_avaliacao` (texto) e não código.
3. Resolver diferença 12.631 vs 12.661: `anti_join(area39_principal, area39_comparada, by = chave)`; documentar em AUDITORIA §10; fazer os dois coincidirem.
4. Substituir `crescimento_relativo` por: CAGR 1995–2004, 2005–2014, 2015–2024 e `participacao_area39` = títulos 39 / soma das seis, por ano.
5. Separar `nivel`/`grau` (mestrado acadêmico, mestrado profissional, doutorado) em todas as áreas.

**Validação.** Soma das seis áreas por ano ≥ cada área; CP/RI total = 12.661; teste novo em 99.

### T1.3 — `SCRIPTS/08_auditoria_series_temporais.R` (F04, F20, F02)

1. `total_programas_unicos <- n_distinct(prog_filtrado$cd_programa_ies)` (67).
2. Crosswalk restrito ao mesmo `an_base`: `left_join(cat, prog %>% select(an_base, cd_programa_ies), by = c("an_base", "cd_programa" = "cd_programa_ies"))`; reportar quantos registros mudam (esperado ≈ 0; se > 0, listar programas e decidir).
3. Adicionar ao RDS: `n_titulos_prof_2013_2024` (MP+DP), `pct_prof_2024`, série `titulos_por_grau` (M acad., MP, D, DP) por ano.
4. `n_discordantes_area39` já existe → garantir que o `.qmd` o usa (F17).

**Validação.** 12.661 preservado; testes 99.

### T1.4 — `SCRIPTS/10_classificacao_subareas.R` (F05, F12)

1. Regex: `AEROESPACIA(L|IS)`; nova categoria `SEGPUB` para "SEGURANÇA PÚBLICA|SEGURANÇA CIDADÃ|CIDADANIA" (ou fundir a PP — decisão do autor, registrar); "SEGURANÇA DE AVIAÇÃO" → OUTROS.
2. Incluir OUTROS em todas as tabelas/valores; `programas_2024` deve somar 64.
3. Cruzar subárea × modalidade (Sucupira) e salvar `v_sub$prof_por_subarea_2024`.
4. Estender a 1987–2012: classificar por `nome_programa` do layout antigo com a mesma função; salvar série 1987–2024 (Fig. 9 passa a começar em 1987 ou justifica 1995).
5. Exportar `TABELAS/amostra_validacao_subareas.csv`: 200 títulos (40 por classe, seed fixa) com `titulo`, `resumo`, `programa`, `classe_auto`, colunas vazias `classe_cod1`, `classe_cod2` para a Fase 2.

**Validação.** `sum(pct_2024) == 100`; `sum(programas_2024) == 64`; nenhum programa em NA.

### T1.5 — `SCRIPTS/03_coleta_openalex_artigos.R` e `05_*` (F06, F07, F08, F34)

1. Regex de front matter:
```r
front_matter_re <- paste0("^(apresenta[çc][ãa]o|editorial|errata|erratum|pref[áa]cio|",
  "nota (do|da|dos|editorial)|sum[áa]rio|expediente|tribut[oe]|obitu[áa]rio|",
  "in memoriam|\\[?no title available\\]?|introdu[çc][ãa]o (ao|do) dossi[êe])")
```
   Listar os excluídos em `TABELAS/openalex_front_matter_excluidos.csv` e ler.
2. Dedup pt/en: `chave <- paste(periodico, ano, stringi::stri_trans_general(tolower(titulo), "Latin-ASCII"))`; para BPSR usar também DOI sem sufixo. Reportar n removidos.
3. Remover registros com `ano < ano_fundacao[periodico]` (tabela: DADOS 1966, Lua Nova 1984, OP 1993 [verificar], RSP 1993 [verificar], BPSR 2007, RBCP 2009).
4. Detectar idioma do resumo com `cld2::detect_language()` (instalar se ausente) → coluna `idioma_resumo`; comparar com `idioma` do OpenAlex.
5. Resenhas: amostra de 100 títulos aleatórios → `TABELAS/amostra_resenhas.csv`; se > 5% forem resenhas, adicionar filtro por padrão de título ("Resenha", "Review", "Notas bibliográficas") ou por `nr_paginas < 4` quando disponível.
6. Salvar `v_temp$n_artigos_final`, `n_dup_removidos`, `n_front_removidos`, `cobertura_resumo_por_periodico`, `lacunas` (anos com 0 registros por periódico).

**Validação.** Novo total de artigos registrado no teste 99; "Tendências…" não mais excluídos; zero registros pré-fundação.

### T1.6 — `SCRIPTS/18_comparacao_marenco.R` (F10)

1. `n_ma_area39_2013` → contar cursos de **mestrado acadêmico** (`nm_grau_programa %in% c("MESTRADO", "MESTRADO/DOUTORADO")` & modalidade ACADÊMICO); `n_phd` idem doutorado.
2. Comparar estados com Marenco no mesmo ano (2010 Marenco vs 2013 Sucupira — dizer explicitamente que são anos distintos) e, se possível, computar estados com doutorado em 2013 e 2024.
3. Razões com 2 decimais: `fmt_num(x, 2)`; adicionar série 2013–2024 completa ao RDS e um teste de tendência simples (`lm(razao ~ ano)`; reportar coeficiente e IC).
4. Adicionar no script e no texto: "valores de Marenco lidos das figuras do artigo".

**Validação.** `v_marenco$area39_ma_2013` < 32 (só acadêmicos de mestrado); 2 decimais no PDF.

### T1.7 — `SCRIPTS/15_associacoes_cientificas.R` (F13)

1. Manter coleta; adicionar coluna `metrica_comparavel` (TRUE apenas para "trabalhos aprovados" ou "inscritos" com fonte oficial).
2. Nova métrica: `trabalhos_por_programa = trabalhos / programas ativos da área no ano` (join com 13).
3. Mover Figs 18/18a/18b/18c para o suplementar; no corpo, no máximo uma frase com `[verificar]` nas datas de fundação.

**Validação.** Nenhum número de associação hardcoded no `.qmd` (grep por dígitos em §4.2).

### T1.8 — `SCRIPTS/06b_*` (F03 parcial, C6, C7, F22)

1. Anotações da Fig. 5 geradas a partir de `stm_evolucao_anual.rds`:
```r
anot <- evol %>% filter(topico == "T6", ano %in% 1995:1997) %>%
  summarise(v = mean(prevalencia)) %>% mutate(label = sprintf("%.0f%% (1995–97)", 100*v), topico = "T6")
# geom_text(data = anot, aes(...)) — só aparece no facet T6
```
   Idem para o mínimo/máximo recente de cada tópico, se desejado, com `data =` por faceta.
2. Rótulos de faceta com `labeller = label_wrap_gen(28)`.
3. Bin "1995–1999" na heatmap.
4. Rótulo T7 provisório "Corpus em inglês" (sem "BPSR") até a Fase 2 decidir o corpus.
5. `corpus_stm_n` = documentos **antes** de `prepDocuments`; `modelo_docs` = depois; reportar ambos.

**Validação.** Abrir `FIGURAS/fig05*.png` e conferir: uma anotação, no facet certo, valor igual ao RDS.

### T1.9 — `SCRIPTS/19_linha_tempo_tres_idades.R` (F24)

1. Gerar marcos de criação de programas a partir de `an_inicio_programa` (Sucupira) — incluir todos os programas ativos em 2024 com ano de início, colorido por subárea e modalidade.
2. Marcos institucionais mantidos só com fonte (coluna `fonte` na tribble); os sem fonte recebem `[verificar]` no `.qmd`.
3. Título da figura: "Criação de programas da Área 39 e marcos institucionais, 1966–2024".

**Validação.** Nenhum marco sem `fonte`.

### T1.10 — Correções mecânicas no `.qmd` e `.bib` (F15, F17, F18, F21, F33, C4, C15)

- `.bib`: `author = {Leite, Fernando and Codato, Adriano}`; conferir DOI com `crossref_verificar` [verificar]; adicionar `roberts2019jss` [verificar].
- `.qmd`: substituir "1 registro" por `` `r fmt_int(v_temp$n_discordantes_area39)` ``; "(Figura 4)" → `@fig-ppgs-comparada` (dar `label` ao chunk); remover "Tabela abaixo" ou criar `@tbl-comparacao` com `kable`; "Leite (2013) demonstram" → "@leite2013autonomizacao demonstram" já cita ambos após correção do `.bib`; "Soares [@soares2005calcanhar]" → "@soares2005calcanhar"; remover chunk `sessionInfo()` do corpo (mover para `suplementar.qmd`); `## Ambiente de Replicação {.unnumbered}`; títulos de figuras "Área 39 (Ciência Política e Relações Internacionais)".

**Aceitação da Fase 1.** `Rscript SCRIPTS/99_testes_regressao.R` passa; pipeline completo reexecutado sem erro; render OK sem NA/NaN/Inf; grep por números hardcoded em §3–§4 do `.qmd` retorna apenas anos e códigos de área.

---

## Fase 2 — Reforço metodológico (4–6 dias, pode iniciar em paralelo após T1.1)

### T2.1 — `SCRIPTS/06a_stm_searchK.R` (novo)

```r
library(stm); library(here)
out <- readRDS(here("DADOS/processed/stm_prep.rds"))   # objeto de prepDocuments
set.seed(20260828)
sk <- searchK(out$documents, out$vocab, K = c(6, 8, 10, 12, 15, 20, 25),
              prevalence = ~ s(ano) + fonte, data = out$meta,
              N = floor(0.1 * length(out$documents)), heldout.seed = 20260828,
              init.type = "Spectral", cores = 4)
saveRDS(sk, here("DADOS/processed/stm_searchK.rds"))
p <- plot(sk)   # held-out, residuals, coherence, exclusivity
```
Critério: K na fronteira coerência × exclusividade com held-out não decrescente; se K ≠ 8, reexecutar 06/06b com o novo K e renomear tópicos após leitura de `findThoughts`.

### T2.2 — Decisão de corpus (idioma)

- Rodar dois modelos: (A) só `idioma_resumo == "pt"`; (B) completo. Tabela de correspondência de tópicos (correlação entre matrizes beta via termos comuns). **Regra de decisão:** se A elimina os tópicos-artefato (T5/T7) e preserva os substantivos, A vai para o corpo e B para o suplementar.
- Documentar n descartados por idioma e por fonte.

### T2.3 — Efeitos de prevalência com controle de composição

```r
mod <- readRDS(here("DADOS/processed/stm_modelo.rds"))
ef  <- estimateEffect(1:mod$settings$dim$K ~ s(ano) + fonte + subarea,
                      mod, metadata = out$meta, uncertainty = "Global")
saveRDS(ef, here("DADOS/processed/stm_estimateEffect.rds"))
# figura: efeito marginal de ano por tópico, painel por fonte (teses vs artigos)
```
Substituir a Fig. 5 (média de theta) por esta (com IC). O texto sobre "queda da teoria política" só permanece se o efeito de `ano` for negativo dentro de `fonte` e `subarea`.

### T2.4 — Validação humana dos tópicos

- `findThoughts(mod, texts = meta$texto, n = 20, topics = k)` para cada k → `TABELAS/stm_exemplares_topico_k.csv`.
- Dois codificadores rotulam cada tópico independentemente; kappa por tópico; rótulos finais em `topicos_nomes.rds` (nunca no `.qmd`).

### T2.5 — Validação da classificação de subáreas

- Preencher `amostra_validacao_subareas.csv` (dois codificadores); `SCRIPTS/10b_validacao_subareas.R` calcula matriz de confusão, precisão/recall/F1 por classe e kappa; salva em `v_sub$validacao`.
- Reportar no texto: "precisão X, recall Y na amostra de 200".

### T2.6 — Indicadores de concentração e séries

- `SCRIPTS/16_concentracao.R` (novo ou reaproveitar 13): HHI e Gini de títulos por IES e por UF, seis áreas, 2013 e 2024; usar `tabela_comparacao_concentracao_ies.csv` já existente.
- `SCRIPTS/17_quebras_estruturais.R` (novo): `strucchange::breakpoints(log(titulos) ~ ano, h = 5)` na série 1995–2024 da Área 39 e nas seis áreas; tabela de quebras estimadas com IC; confrontar com a periodização.
- Painel programa-ano (Sucupira): `fixest::fepois(titulos ~ idade + prof + conceito | cd_programa_ies + ano)` — descritivo, com cautela na interpretação.

### T2.7 — Análises de baixo custo (escolher 2–3)

- Curva de criação de programas por ano/subárea/modalidade (`an_inicio_programa`).
- Doutores titulados / docentes permanentes para as seis áreas (estender 18).
- Formação dos docentes no exterior (`nm_pais_ies_titulacao`) por área e ano.
- Endogamia de orientação (`rede_orientacao` de 07): proporção de docentes titulados na própria IES.

**Aceitação da Fase 2.** `stm_searchK.rds` existe e a escolha de K está justificada no texto com números inline; `estimateEffect` substitui média de theta; validação de subáreas com precisão/recall inline; ao menos uma análise de concentração e o teste de quebras no corpo; testes 99 ampliados e passando.

---

## Fase 3 — Reescrita (3–4 dias; depende de Fases 1–2)

### Estrutura proposta (≤ 9.000 palavras)

1. **Introdução** (900) — pergunta: *Como se expandiu e se transformou a pós-graduação em ciência política no Brasil entre 1987 e 2024, e em que medida essa expansão foi da ciência política estrita ou de campos adjacentes abrigados na mesma área de avaliação?* Três hipóteses testáveis: H1 (hibridização — a expansão pós-2010 é majoritariamente de RI/PP/Defesa e de mestrados profissionais); H2 (desconcentração geográfica sem desconcentração institucional — Gini por UF cai, HHI por IES estável); H3 (recomposição temática — teoria política perde prevalência mesmo controlando composição). Contribuição vs Marenco (2014), Leite & Codato (2013), Nicolau & Oliveira [verificar].
2. **A disciplina e sua área de avaliação: o que a literatura diz** (1.200) — fusão dos atuais §2.1–2.2 com literatura das Fases 4(i), (ii), (iv); periodização própria explicitada como proposta.
3. **Dados e métodos** (1.300) — fontes, âncora Área 39, subáreas + validação, comparação corrigida, STM (K, corpus, estimateEffect), limites. Auditoria vai para suplementar.
4. **Resultados** (4.000)
   4.1 Expansão e modalidade (Figs. títulos por grau/modalidade; programas por modalidade).
   4.2 Área 39 frente às áreas irmãs (corrigido; CAGR; participação; doutores/permanentes; concentração).
   4.3 Geografia (mapa + Gini UF).
   4.4 Hibridização (subáreas + validação + modalidade por subárea).
   4.5 Temas (STM validado; efeitos por fonte).
   Associações e artigos por periódico: um parágrafo cada, no máximo, ou suplementar.
5. **Discussão** (900) — H1–H3 confrontadas; "modelo indutor da CAPES" como hipótese, não conclusão; diálogo com Leite & Codato (autonomização por cima) e Marenco (calcanhares).
6. **Conclusão** (500) — implicações para a avaliação da área (separar CP/RI? profissionais?), limitações, agenda.
7. Referências; Apêndice suplementar com DOI.

### Frases a corrigir (originais entre aspas)

- "Neste texto comemorativo" (Intro e Discussão) → remover.
- "Em comparação com as áreas irmãs, a ciência política tem o menor sistema de pós-graduação e a menor escala de encontros" (Resumo/Intro) → "Entre seis áreas comparadas, a Área 39 ocupa posição intermediária em tamanho, mas apresenta o maior crescimento (2013–2024) e a maior proporção de programas profissionais" (com valores inline).
- "a História possuía 215 programas e 3.589 docentes, a Economia 192 programas e 4.656 docentes ..." → substituir pelo parágrafo com valores de `comp_2024` corrigidos.
- "quase dobrou, contra uma variação de 2% na História" → recomputar; provavelmente "+100% na Área 39 contra +27% na História e 0% na Sociologia".
- "A superação do confinamento geográfico original demonstra a eficácia do modelo indutor da CAPES" → "é compatível com a hipótese de indução via política de pós-graduação (PNPG, Reuni), que estes dados não permitem testar diretamente".
- "Distribuindo os 64 programas ... 21 de Ciência Política, 17 de RI, 14 de PP e 10 de Defesa" → incluir "e 2 de outras áreas".
- "Os encontros da ABCP, iniciados em 1998" → `[verificar]` ou fonte.
- "a razão dos doutores titulados sobre os docentes permanentes ... 0,2 em 2013 para 0,2 em 2024" → 2 decimais; interpretar estagnação.
- "(os dois critérios discordam em apenas 1 registro)" → inline.
- "restaram 38 safras" → "38 anos-base (1987–2024)".
- "Corpus em inglês (BPSR)" → rótulo decidido na Fase 2.
- "Leite (2013) demonstram" → "Leite e Codato (2013) demonstram" (via `.bib`).
- Título: "A Trajetória da Ciência Política no Brasil: expansão, hibridização e concentração da pós-graduação (1987–2024)" (sugestão; ≤ 15 palavras).

### Resumo/abstract
- ≤ 200 palavras, um parágrafo: pergunta, dados (n títulos, n programas, n artigos inline), três achados, implicação. Abstract em inglês espelhado. Keywords: ciência política; pós-graduação; CAPES; cientometria; modelagem de tópicos.

**Aceitação.** Contagem `wc -w` do PDF (sem suplementar) ≤ 9.000; nenhuma das frases acima permanece; introdução contém pergunta + hipóteses; conclusão contém limitações e agenda.

---

## Fase 4 — Literatura (1–2 dias; paralela à Fase 3)

Para cada bloco de `REVISAO_CRITICA.md` §6, inserir no `.bib` **somente após verificação** (Crossref via `mcp__pesquisa-br__crossref_verificar`; se não confirmar, manter fora ou com `note={[verificar]}` e não citar no texto final).

| Referência | Parágrafo alvo |
|---|---|
| Reis 1999; Keinert & Silva 2010; Lessa 2010; Martins & Lessa 2010; Avritzer, Milani & Braga 2016 | §2 (história) |
| Amorim Neto & Santos 2005/2015; Nicolau & Oliveira 2017; Codato, Madeira & Bittencourt 2020 | §2 e §4.5 (comparação/cientometria) |
| Bourdieu 1976; Whitley 2000; Abbott 2001 | §2 e Discussão (hibridização como fronteira de campo) |
| Fourcade 2009 | §4.2 (Economia como contraste) |
| Heilbron 2014; Alatas 2003; Ortiz 2004; Beigel | §4.5 (idioma/internacionalização) |
| Grimmer & Stewart 2013; DiMaggio, Nag & Blei 2013; Roberts, Stewart & Tingley 2019 | §3 (métodos) |
| Balbachevsky 2005; Schwartzman 1979; Velloso 2002; Martins 2018; Cury 2005; PNPG 2011–2020 | §2 e Discussão (pós-graduação) |
| Documento de Área 39 (CAPES 2019) e Relatório Quadrienal 2017/2021 | §3 e Discussão |

**Aceitação.** ≥ 30 referências; todas resolvem no render (sem "???" no PDF); nenhuma com `[verificar]` citada no corpo.

---

## Fase 5 — Figuras e tabelas (1 dia)

| Figura atual | Decisão |
|---|---|
| Fig 1 (títulos/ano) | Manter; empilhar por grau/modalidade; título "Área 39". |
| Fig 2 (programas/ano) | Fundir com Fig 1 em painel A/B ou manter; cor por modalidade. |
| Fig 3 (IES) | Suplementar (substituída por HHI/Gini). |
| Fig 4 (artigos por periódico) | Suplementar ou normalizar por periódico ativo. |
| Fig 5 (STM anual) | Refazer com `estimateEffect` + IC; painel por fonte. |
| Fig 6 (heatmap décadas) | Remover (redundante) ou suplementar. |
| Fig 7 (mapa) | Manter; adicionar 2013 vs 2024 lado a lado. |
| Fig 8 (regiões) | Fundir com mapa ou suplementar. |
| Fig 9 (subáreas) | Manter; iniciar em 1987 se T1.4(4) funcionar; incluir OUTROS. |
| Figs 10, 12, 13, 14, 16 (comparação) | Refazer com códigos corretos; consolidar em 1 painel (programas, docentes permanentes, títulos/programa, % profissional). |
| Fig 11, 15, 17 | Avaliar após correção; provavelmente suplementar. |
| Figs 18, 18a–c (associações) | Suplementar. |
| Fig 19 (razão Marenco) | Manter; 2 decimais; estender às seis áreas. |
| Fig 20 (linha do tempo) | Refazer a partir de `an_inicio_programa`. |

**Padrão de legenda:** "Figura N. Título descritivo (unidade, período). Fonte: Catálogo de Teses e Dissertações CAPES (1987–2024); Plataforma Sucupira (2013–2024); OpenAlex (acesso em [data]). Elaboração própria." Todos os eixos com unidade; sem títulos dentro do gráfico quando a legenda já os traz (padrão de revista).

**Aceitação.** ≤ 8 figuras no corpo; todas legíveis a 100% em PDF; anotações geradas por dados.

---

## Fase 6 — Reprodutibilidade e suplementar (1 dia)

1. Inicializar git no projeto (se o autor concordar), `.gitignore` para `DADOS/raw/`, rodapé de commit padrão.
2. `README.md`: ordem exata do pipeline, tempo de execução, dependências (`renv::snapshot()`), como obter os brutos (URLs CKAN gravadas em `DADOS/raw/urls_ckan.csv` — remover dependência de `/dados/classe_media/...`).
3. `suplementar.qmd`: auditoria (§9–10), sessionInfo, searchK, validação humana, tabela de associações, mapeamento de subáreas, figuras excedentes, testes de recall do pré-filtro (3 safras).
4. Depósito: Zenodo ou OSF com DOI (dados processados + scripts + suplementar); citar o DOI no artigo.
5. Atualizar `AUDITORIA.md` §10 e corrigir §9 (3.379% → valor atual; Geografia = 36).

**Aceitação.** `Rscript SCRIPTS/00_run_all.R` (criar) reexecuta 01→19→render sem intervenção; DOI no texto.

---

## Fase 7 — Fechamento (0,5 dia)

1. `~/.claude/scripts/verificar_render_qmd.sh artigo_historia_cp_brasil.qmd --to all --cache-refresh`.
2. `pdftotext -layout artigo_historia_cp_brasil.pdf - | grep -nE "\bNA\b|NaN|Inf|\?\?\?"` → vazio.
3. Conferir que cada número do Resumo aparece idêntico no corpo (script rápido: extrair dígitos do resumo e procurar no corpo).
4. `Rscript SCRIPTS/99_testes_regressao.R` → passa.
5. Checklist de submissão (revista-alvo): limite de palavras, anonimização (remover nomes/afiliação e agradecimentos identificáveis), abstract/keywords, declaração de dados, figuras em 300 dpi separadas, referências no estilo da revista.

---

## Estimativa e dependências

| Fase | Esforço | Depende de |
|---|---|---|
| 0 | 0,5 d | — |
| 1 | 2–3 d | 0 |
| 2 | 4–6 d | 1 (T1.1, T1.4, T1.5) |
| 3 | 3–4 d | 1, 2 |
| 4 | 1–2 d | 0 (paralela a 2–3) |
| 5 | 1 d | 2 |
| 6 | 1 d | 1–5 |
| 7 | 0,5 d | todas |
| **Total** | **13–18 dias úteis** | |

Divisão sugerida: Opus 5 — Fases 0, 2 (desenho), 3 (argumento), 4 (curadoria) e revisão de cada PR; Sonnet — Fase 1 (edições de script conforme sketches), Fase 5 (figuras), Fase 6 (README/suplementar), com Opus verificando os testes 99 a cada etapa.
