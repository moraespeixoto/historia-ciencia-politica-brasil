# Auditoria: Dados e Artigo "A Trajetória da Ciência Política no Brasil"

**Data da auditoria:** 29/08/2026
**Escopo:** todos os scripts, bases brutas/processadas, tabelas, figuras, referências e o manuscrito `artigo_historia_cp_brasil.qmd`.
**Método:** auditoria computacional interna (R) + verificação externa via APIs (OpenAlex, Crossref, doi.org) e fontes institucionais (CAPES/Sucupira, SciELO, páginas oficiais dos programas).

## 0. Correções aplicadas (mesma sessão)

Após a auditoria, foram aplicadas as seguintes correções no repositório:

1. **`referencias.bib` reescrito com DOIs verificados** (Crossref/doi.org/OpenAlex):
   - Leite & Codato (2013): corrigido para *Revista Agenda Política* 1(1), DOI 10.31990/10 (o registro anterior, com RSP 21(46) e DOI de "Recrutamento político" de Norris, era fabricado).
   - Marenco (2014): substituído o inexistente "The Three Ages of Brazilian Political Science" pelo real "The Three Achilles' Heels of Brazilian Political Science", BPSR 8(3), DOI 10.1590/1981-38212014000100019; a seção "Três Idades" foi re-fundamentada em Forjaz (1997) e Lamounier (1989), sem citação inventada.
   - Amorim Neto & Santos (2003): corrigido para "O segredo ineficiente revisto", Dados 46(4), DOI 10.1590/S0011-52582003000400002.
   - Candido & Biroli: substituído o DOI inválido pelo livro "Mulheres, poder e ciência política" (Ed. Unesp, 2021, DOI 10.7476/9786586253702) e acrescentado Candido (2023), "A ciência política é um mundo de homens?", RBCP 41.
   - Forjaz (1997): título corrigido (acrescido "acadêmica").
   - Perissinotto & Codato (BIB 79): **removida** (artigo não localizado no sumário oficial da BIB n. 79); o uso no texto foi substituído por Marenco (2014).
   - Lamounier: metadados ajustados para o volume Miceli (org.), Vértice/IDESP, 1989, v. 1 (a conferir com o volume físico).
2. **Rótulos dos tópicos STM corrigidos** (script 06, tabela, figuras 5–6): T1–T4 e T8 foram renomeados para corresponder aos termos FREX; T6/T7 marcados como artefatos de idioma (inglês/espanhol); T5 como tópico residual. Texto interpretativo do artigo reescrito com os rótulos corretos. Após a correção de dados (itens 3 e 11), o modelo foi **reestimado** (16.457 documentos): a ordem dos tópicos mudou e os rótulos foram re-verificados contra os termos FREX do novo modelo (ver `SCRIPTS/06b_rotulos_stm.R`, que regenera os artefatos sem re-estimar). O novo modelo mostra a perda de dominância do tópico de teoria política (36% nos anos 1980/90 → 13% em 2020-24) e o avanço de políticas públicas/saúde/educação (7% → 22%), relações internacionais, direitos e gênero e opinião pública.
3. **Script 03 corrigido e renomeado** (`03_coleta_openalex_artigos.R`): deduplicação por `id_openalex` (elimina o colapso de obras sem DOI), filtro `type == "article"`, flag de front matter e uma consulta por periódico com parsing otimizado. Base re-coletada da API (29/08/2026): **5.005 artigos únicos** (4.553 artigos de pesquisa até 2024), contra 4.716 registros brutos anteriores. A cobertura melhorou: *DADOS* agora aparece a partir de 1977 e *Opinião Pública* a partir de 1993.
4. **Filtro da área 39**: exclusão dos ~73 registros da CAPES fora da área de avaliação (49 no layout antigo por código CNPq ≠ 7090; 24 no layout novo por programa fora da lista Sucupira). Totais do artigo recalculados.
5. **Números hardcoded removidos**: 11.600, 1.670, 16.548 e a legenda "N = 16.589" agora vêm dos RDS (`valores_inline_temporal.rds`, `valores_inline_stm.rds`).
6. **Cronologia corrigida**: USP 1971 (não 1974); UnB reclassificada para a Idade da Expansão (mestrado iniciado em 1984); "60 anos" ancorado nos primeiros programas (meados dos anos 1960).
7. **Top IES corrigido** (script 07): ranking sem filtro de orientador.
8. **Nova análise: composição da área 39** (script `10_classificacao_subareas.R`): separação em CP/RI/PP/DEFESA/OUTROS, tabelas, Figura 9 e seção no artigo.
9. **README atualizado**; `Rplots.pdf` órfão removido.
10. **Consistência de escrita**: prosa impessoal, travessões removidos da prosa, keyword "Evolução Metodológica" → "Diversificação Temática".
11. **Correção de encoding do Catálogo CAPES (raiz)**: os arquivos brutos da CAPES estão em Latin-1/ISO-8859-1, mas eram lidos como UTF-8 (a heurística de detecção falhava), corrompendo acentos em nomes de programa, resumos e áreas. O script 01 foi corrigido (detecção por bytes via `validUTF8`) e a base `capes_cp_1987_2024.rds` foi reconstruída a partir do cache local, agora com texto limpo. Isso corrige a classificação de subáreas (que dependia do nome do programa) e melhora o corpus do STM.

Os itens a seguir (§1–§8) documentam o estado *anterior* à correção, para registro histórico.

---

## 1. Resumo executivo

O projeto é sólido em sua espinha dorsal: o pipeline é reprodutível, os totais principais conferem com os dados, e o texto demonstra honestidade analítica (caveats sobre causalidade, corte em 2024, caráter exploratório do STM). **Mas a auditoria encontrou erros críticos que precisam ser corrigidos antes de qualquer submissão:**

| # | Gravidade | Problema |
|---|-----------|----------|
| 1 | **Crítica** | **3 DOIs no `referencias.bib` apontam para artigos totalmente diferentes** (Leite & Codato; Marenco; Amorim Neto & Santos) e 1 DOI é inválido (404) (Candido & Biroli). |
| 2 | **Crítica** | **Rótulos dos 8 tópicos STM não correspondem aos termos FREX** — os rótulos T1–T4, T7 e T8 estão trocados; T6 e T7 são artefatos de idioma (inglês/espanhol). As interpretações do texto são construídas sobre rótulos errados. |
| 3 | **Alta** | **Bug de deduplicação no script 03**: `distinct(doi, .keep_all = TRUE)` colapsa todas as obras **sem DOI** em uma única linha. Só na DADOS, 250 obras sem DOI foram reduzidas a 1 (perda ≈ 8,8% do corpus total vs. a API ao vivo). |
| 4 | **Alta** | **A série de periódicos é chamada de "artigos", mas inclui 140 registros não-artigo** (editoriais 91, book reviews 34, erratas 11, etc.) e ~214 registros de front matter ("Apresentação", "[NO TITLE AVAILABLE]") até 2024 — inflando a contagem em ~5%. |
| 5 | **Alta** | **Cronologia institucional com erros**: USP "1974" (correto: 1971) e UnB listada como pioneira dos anos 1960/70 (o PPG da UnB iniciou em 1984). |
| 6 | **Média** | Números hardcoded no texto (11.600, 1.670, 16.548) e inconsistência 16.548 (texto) vs 16.589 (legenda da Figura 5). |
| 7 | **Média** | A afirmação do resumo de "núcleos persistentes de estudos ... institucionais" contradiz o dado (tópico institucional/residual caiu de ~47% para ~12%). |

Pontos fortes confirmados: totais CAPES (12.734), Sucupira (69 programas; 11.600 vínculos; 1.670 docentes), contagem de artigos ≤2024 (4.465), picos, geografia (15 UFs, RJ líder, Sudeste 47,1%→43,8%) — **todos conferem** com as bases e com fontes externas. A contaminação do filtro CAPES é pequena (~0,6%) e a referência Soares (2005) está correta.

---

## 2. Auditoria dos dados

### 2.1 Catálogo de Teses e Dissertações (CAPES, 1987–2024)

| Verificação | Resultado |
|---|---|
| Total de registros | **12.734** ✓ (confere com o texto) |
| Layout antigo (1987–2012) | 4.047 registros ✓ (confere com o texto) |
| Layout novo (2013–2024) | 8.687 registros ✓ |
| Anos fora do intervalo | 0 ✓ |
| "Mestrado > doutorado em todos os anos" | **Verdadeiro** ✓ |
| Grau não informado | 269 registros (2,1%) — excluídos da Figura 1 com transparência na legenda ✓ |

**Problema 1 — o filtro não é por "área 39", é por palavras-chave.** O script 01 usa `awk` com regex sobre a linha inteira (`ciencia politica|relacoes internacionais|estudos politicos|estudos estrategicos|7090xxxx...`). Isso captura:
- **Layout antigo:** 49 de 4.047 registros (1,2%) pertencem a **outras áreas de avaliação** (Educação 10, Sociologia 7, Direito 8, História 6, etc.). O filtro os pegou porque o texto mencionava "estudos políticos" ou afins.
- **Layout novo:** os arquivos 2013+ **não têm coluna de área de avaliação**, então a única âncora é o nome do programa. Ao cruzar com a lista oficial de programas da área 39 do Sucupira (73 linhas/69 programas), apenas **24 de 8.687 registros (0,3%)** vêm de programas fora da área 39 (Ciências Jurídicas 19, História Comparada 3, Direito 1, Educação 1). **Correção (§9, 31/08/2026): esta frase estava errada.** O layout novo *tem* a coluna `NM_AREA_AVALIACAO` (49ª coluna do header); ela virou a âncora administrativa direta do filtro, com o crosswalk Sucupira mantido como checagem de consistência (discordam em 1 registro).

Conclusão: a afirmação de "censo de trabalhos defendidos na área 39" é **quase exata** (99,4%+), mas o texto deveria descrever o filtro como *baseado em programa/área de conhecimento e palavras-chave*, não como censo administrativo por área. Recomenda-se: (a) documentar o filtro; (b) excluir os 24 registros fora da área 39; (c) nos anos 1987–2012, filtrar também por `area_avaliacao`.

**Observação substantiva:** a "área 39" da CAPES inclui muito mais que "Ciência Política e Relações Internacionais" no nome: abriga programas de Políticas Públicas, Ciências Militares, Segurança Pública, Estudos Marítimos, Defesa, Direitos Humanos, Poder Legislativo, etc. Isso é um achado em si e deveria ser discutido no artigo (a "área" é uma construção institucional, não um sinônimo de disciplina).

### 2.2 Sucupira (programas e docentes, 2013–2024)

| Verificação | Resultado |
|---|---|
| Programas por ano | 34 (2013) → **64 (2024)** ✓ |
| Programas únicos (2013–2024) | 69 ✓ |
| IES únicas | 46 em 2024 ✓ |
| Vínculos docente-programa-ano | **11.600** ✓ (confere com o texto) |
| Docentes únicos (por `id_pessoa`) | **1.670** ✓ (confere com o texto) |
| Filtro por área | Todos os 616 registros de programas com `CD_AREA_AVALIACAO == 39` ✓ |

Obs.: `nm_docente` gera 1.695 valores únicos vs. 1.670 por `id_pessoa` (25 nomes duplicados/variações) — o texto usa a métrica correta (id_pessoa), mas vale documentar.

**Problema 2 — "69 programas únicos ativos" é ambíguo.** O número 69 é o total de programas distintos **observados em qualquer ano** entre 2013 e 2024; "ativos" em 2024 são 64. O texto do resumo deveria dizer "69 programas únicos observados no período (64 ativos em 2024)".

### 2.3 OpenAlex / periódicos (1984–2024)

**Bug crítico — `distinct(doi, .keep_all = TRUE)` (script 03, linha 128).** Em `dplyr`, `NA` é tratado como um valor; todas as obras **sem DOI** são colapsadas em **uma única linha**. Verificação contra a API ao vivo (29/08/2026):

| Periódico | API OpenAlex (vivo) | Coletado | Diferença |
|---|---|---|---|
| DADOS | 1.151 | 902 | **−249** |
| Rev. Sociologia e Política | 1.041 | 939 | −102 |
| Lua Nova | 1.397 | 1.364 | −33 |
| RBCP | 560 | 511 | −49 |
| Opinião Pública | 578 | 569 | −9 |
| BPSR | 446 | 431 | −15 |
| **Total** | **5.173** | **4.716** | **−457 (−8,8%)** |

A causa é confirmada: a API reporta **250 obras da DADOS sem DOI** e a base coletada tem **apenas 1 linha sem DOI** (a famosa "Presidencialismo de coalizão", de Sérgio Abranches, DADOS 1988). Ou seja, 249 registros da DADOS foram perdidos no `distinct`. Correção: deduplicar por chave composta (`doi` após `drop_na` + `id_openalex`/`titulo`).

**Problema 3 — "artigos" incluem não-artigos e front matter (≤2024):**

| Tipo | n |
|---|---|
| article | 4.325 |
| editorial | 91 |
| book-review | 34 |
| erratum | 11 |
| outros | 4 |
| **Total ≤2024** | **4.465** |

Além disso, ~214 registros têm títulos genéricos ("Apresentação" 86, "[NO TITLE AVAILABLE]" 84, "Editorial" 34, "Errata", etc.). "Artigos de pesquisa" efetivos ≈ **4.251**, não 4.465 (inflação ≈ 5%). A Figura 3 e a contagem inline deveriam usar `tipo == "article"` e excluir front matter.

**Problema 4 — cobertura desigual por periódico (viés de cobertura, não discutido):**
- **DADOS** (fundada em 1966): OpenAlex só cobre a partir de 1988, com 1 artigo em 1988 e zeros em 1989–1993 — a série pré-2000 é **dominada por Lua Nova** (que, verificado no SciELO, de fato começou em 1984, v.1 n.1–3 — dado legítimo).
- **Opinião Pública** (fundada 1993): cobertura OpenAlex começa em 2000.
- **RBCP** (UnB, fundada 2009): 1 registro fantasma em 2001 (possível atribuição errônea).
- A série "produção em periódicos" mistura, portanto, revistas com janelas de indexação diferentes. Recomenda-se: reportar cobertura por periódico (tabela) e/ou restringir a comparação ao período em que todos os canais existem (2009–2024).

### 2.4 Modelagem de tópicos (STM)

- O modelo contém **16.548 documentos** ✓ (o "16.548" do texto confere; a legenda da Figura 5, com "N = 16.589", **não** confere).
- **Problema 5 — rótulos trocados (erro de apresentação crítico).** Comparação rótulo vs. termos FREX (do próprio `TABELAS/tabela_topicos_stm.csv`):

| Tópico (rótulo no artigo) | Termos FREX reais | Rótulo correto sugerido |
|---|---|---|
| T1 "Relações Internacionais, Política Externa e Defesa" | violência, indígenas, refugiados, drogas, gênero, polícia, justiça | **Direitos Humanos, Gênero e Segurança** |
| T2 "Políticas Públicas, Gestão e Avaliação" | comércio, cooperação, África, países, externa, Mercosul | **Relações Internacionais, Política Externa e Cooperação** |
| T3 "Teoria Política, Democracia e Pensamento Político" | eleitoral, deputados, candidatos, eleitores, parlamentares | **Eleições, Partidos e Comportamento Eleitoral** |
| T4 "Eleições, Partidos e Comportamento Eleitoral" | educação, saúde, município, gestão, públicas, serviços | **Políticas Públicas, Saúde e Educação** |
| T5 "Instituições Políticas, Executivo e Legislativo" | política, políticas, político, relação, período | **Tópico residual/geral** (baixa discriminação) |
| T6 "Movimentos Sociais, Participação e Sociedade Civil" | political, brazilian, state, international, public | **Artefato de idioma: resumos em inglês (BPSR)** |
| T7 "Federalismo, Governança Municipal e Finanças" | biblioteca, desarrollo, usuarios, nueva, información, proyecto | **Artefato de idioma: resumos em espanhol** |
| T8 "Estado, Desenvolvimento e Economia Política" | político, democrática, capítulo, trajetória, ciência, pensamento | **Teoria Política e Pensamento Político** |

O padrão de troca é sistemático (T1↔T2, T3↔T4 etc.), sugerindo rótulos atribuídos manualmente sem conferência com os termos. **As interpretações da seção de resultados e do resumo herdam esses erros** (ver §4).

**Prevalência por década (com os rótulos corrigidos):** eleições (T3) 6→11%; políticas públicas (T4) 4→23,5%; RI (T2) 8,9→18%; direitos/gênero (T1) 3,3→13,9%; residual (T5) **47,1→11,7%**; teoria (T8) estável ~15,7%; inglês/espanhol estáveis ou em queda.

---

## 3. Auditoria das referências (Crossref / doi.org / fontes externas)

| Entrada .bib | Verificação | Status |
|---|---|---|
| `leite2013autonomizacao` — DOI 10.1590/S0104-44782013000200002 | Crossref: resolve para **"Recrutamento político", de Pippa Norris** (RSP 21(46), 11–32). Não é o artigo de Leite & Codato. | ❌ **DOI errado** |
| `marenco2014three` — "The Three Ages of Brazilian Political Science", BPSR 8(2): 49–85, DOI 10.1590/1981-38212014000100011 | Crossref: DOI resolve para **"Institutionalisation, Reform and Independence of the Public Defender's Office in Brazil", de Lígia Mori Madeira** (BPSR 8(2): 48–69). Busca em Crossref/OpenAlex não encontra nenhum artigo "The Three Ages...". O artigo real de Marenco na BPSR é **"The Three Achilles' Heels of Brazilian Political Science"** (BPSR 8(3), 2014, 3–38; DOI 10.1590/1981-38212014000100019). | ❌ **Referência inexistente + DOI errado** (provável alucinação de título; a periodização em "três idades" precisa ser re-fundamentada) |
| `soares2005calcanhar` — "O calcanhar metodológico...", Sociologia, Problemas e Práticas 48 | Confirmado no [SciELO-Portugal](https://scielo.pt/scielo.php?script=sci_abstract&pid=S0873-65292005000200004&lng=es&nrm=iso&tlng=pt). | ✅ OK |
| `forjaz1997emergencia` | DOI resolve corretamente; porém o título correto é **"A emergência da Ciência Política acadêmica no Brasil: aspectos institucionais"** (faltou "acadêmica"). | ⚠️ Título incompleto |
| `perissinotto2015estudam` — BIB n. 79, 5–28, 2015 | Não localizado como artigo de BIB 79. Perissinotto & Codato organizam o livro *"Como os cientistas políticos brasileiros estudam a política?"* (Editora Unesp, 2015) e outros trabalhos. **Verificar a citação exata antes da submissão.** | ⚠️ Não confirmado |
| `lamounier1982anos70` | Capítulo real de Lamounier; o volume organizado por Miceli (*História das Ciências Sociais no Brasil*) tem edições/anos que variam conforme a fonte (Vértice/IDESP; alguns registros indicam 1989). Conferir ano/editora/páginas. | ⚠️ Conferir metadados |
| `capes2022relatorio` | Relatório quadrienal 2017–2020 da Área 39 existe; URL aponta para página genérica da CAPES. | ✅ (melhorar URL específica) |
| `amorimneto2003executivo` — DOI 10.1590/S0011-52582003000200003 | Crossref: resolve para **"A linguagem do respeito: a experiência brasileira e o sentido da cidadania nas democracias modernas", de Dominique Vidal** (Dados 46(2): 265–287). | ❌ **DOI errado** |
| `candido2021mulheres` — DOI 10.1590/0103-3352.2021.34.241517 | doi.org retorna **404**; Crossref não localiza. O livro real de Biroli & Candido é *"Mulheres, poder e ciência política: debates e trajetórias"* (Ed. Unesp, 2021, DOI 10.7476/9786586253702); o artigo de crítica à historiografia é [*"A ciência política é um mundo de homens?"*](https://www.scielo.br/j/rbcpol/a/nyC7pK7Kgy8jLZnmptQWnTG/?lang=pt) (RBCP). | ❌ **DOI inválido** |
| `roberts2014stm` | Crossref confirma título, autores e DOI 10.1111/ajps.12103. | ✅ OK |

**Resumo: 4 de 10 referências com problema grave (3 DOIs apontando para outro artigo + 1 DOI 404), 2 com metadados a conferir.** O `referencias.bib` se autodescreve como "com DOIs auditados" — a auditoria real mostra o contrário. Este é o tipo exato de falha de integridade de citação que a skill de revisão de literatura previne (anti-alucinação: DOI deve resolver para o próprio artigo).

---

## 4. Auditoria de fatos históricos e institucionais

| Afirmação no artigo | Verificação externa | Status |
|---|---|---|
| IUPERJ em 1969 | Confirmado (IESP-UERJ celebra 50 anos em 2019; [UnB-IPOL](https://ipol.unb.br/quem-somos/a-ciencia-politica-em-brasilia/) registra IUPERJ desde 1973 como instituição estabelecida). | ✅ |
| **USP em 1974** | O próprio DCP-USP celebra "50 anos do PPG" ([dcp.fflch.usp.br](https://dcp.fflch.usp.br/50-anos-do-programa-de-pos-graduacao-em-ciencia-politica-da-usp)) → **criado em 1971**. | ❌ **Corrigir para 1971** |
| **UnB como pioneira (1960/70)** | A [história do IPOL/UnB](https://ipol.unb.br/quem-somos/a-ciencia-politica-em-brasilia/) documenta: Mestrado em CP e RI iniciado em **março de 1984** (doutorado em CP só em 2008). A UnB pertence à Idade da Expansão, não à da Criação. | ❌ **Reclassificar** |
| UFMG como pioneira | Departamento criado em 1969 (50 anos em 2019, [UFMG](https://www.ufmg.br/online/arquivos/042749.shtml)); o Mestrado em CP da UFMG já formava egressos em 1969 (por relato do IPOL). Fontes situam a criação do PPG em meados da década de 1960. | ✅ (precisar o ano) |
| UFRGS | [PPG-CP da UFRGS](https://www.ufrgs.br/sncp/programa-de-pos-graduacao-em-ciencia-politica-ufrgs): "Criado em 1973, ... o terceiro mais antigo da área no país". | ✅ (não citado com ano no artigo) |
| ANPOCS (1977) e ABCP (1996) | Datas consolidadas na literatura e na [Wikipédia/ABCP](https://pt.wikipedia.org/wiki/Associa%C3%A7%C3%A3o_Brasileira_de_Ci%C3%AAncia_Pol%C3%ADtica). | ✅ |
| BPSR lançada em 2007 | Confirmado (OpenAlex: primeiro registro em 2007). | ✅ |
| "60 anos da Ciência Política no Brasil" | Requer fundamentação explícita: se ancorado no PPG da UFMG (meados 1960s), 2026 ≈ 60 anos; se ancorado no IUPERJ (1969), o sexagenário seria 2029. O texto hoje usa a expressão sem âncora. | ⚠️ **Fundamentar** |
| Periódicos: DADOS (1966), Lua Nova (1984), Opinião Pública (1993), RSP (1994), RBCP (2009) | DADOS 1966 ✓ (IUPERJ); Lua Nova v1 n1–3 publicados em 1984 ([SciELO](https://www.scielo.br/j/ln/i/1984.v1n1/)) ✓ — o dado do corpus está correto; [Opinião Pública criada em 1993](https://www.cesop.unicamp.br/eng/opiniao_publica/apresentacao) ✓; [RSP 1994](https://www.lexml.gov.br/urn/urn:lex:br:rede.virtual.bibliotecas:revista:1994;000491481) ✓. | ✅ |

---

## 5. Revisão do texto (erros, acertos e inconsistências)

### Acertos que devem ser preservados
1. **Honestidade inferencial**: "Esses dados descrevem uma expansão observada, mas não permitem atribuí-la isoladamente a uma política específica" e "sem transformar crescimento observado em efeito causal" — raro e louvável.
2. **Caveat do corte em 2024** para a indexação de periódicos e a distinção mestrado/doutorado na Figura 1.
3. **Autolimitação metodológica explícita**: o texto reconhece que mudança metodológica exigiria codificação dos desenhos (embora o título prometa "Evolução Metodológica" — ver abaixo).
4. **Transparência do STM**: "as figuras devem ser tratadas como um mapa exploratório... não como medida definitiva".
5. **Reprodutibilidade**: pipeline com seeds, cache, protocolo exploratório (Camada 2) e relatórios EDA — estrutura exemplar.

### Erros e inconsistências no texto
1. **Título x conteúdo**: o título promete "Evolução Metodológica", mas o texto (corretamente) diz que não mede métodos. Ou muda-se o título, ou acrescenta-se uma seção empírica de métodos (p.ex., análise lexical de termos metodológicos nos resumos).
2. **Números hardcoded**: `r fmt_int(11600)`, `r fmt_int(1670)`, `r fmt_int(16548)` estão fixados no .qmd em vez de virem dos RDS (a seção de dados admite que os demais valores são carregados "para garantir consistência total" — mas esses três não são).
3. **Inconsistência N**: "16.548 resumos" (texto) vs. "N = 16.589" (legenda da Figura 5). O modelo tem 16.548.
4. **"USP responsável por 1.111 trabalhos"**: 1.111 é a contagem restrita a registros **com orientador** (filtro do script 07); o total real é 1.161. Corrigir ou documentar.
5. **Interpretação dos tópicos com rótulos trocados**: "núcleos persistentes de estudos eleitorais e institucionais" — com os rótulos corretos, o núcleo institucional (T5) **caiu** de 47% para 12%; e "participação" (T6) não cresceu. A frase do resumo precisa ser reescrita com os rótulos corretos (§2.4).
6. **"Censo de trabalhos defendidos na área 39"** (§Dados): ver §2.1 — o filtro é por palavras-chave/programa; documentar e quantificar a contaminação (~0,6%).
7. **"Produção Científica em Periódicos"**: inclui editoriais/errata/front matter; reportar "artigos de pesquisa" (≈4.251 ≤2024).
8. **Seleção dos "seis periódicos canônicos"** não é justificada (critérios: Qualis? antiguidade? área?). Sem critério explícito, a amostra é arbitrária e o viés de cobertura (OpenAlex) não é discutido.
9. **Script 03** chama-se `03_coleta_scielo_artigos.R` mas consulta apenas o **OpenAlex** (nenhuma chamada ao SciELO) — renomear para refletir a fonte.
10. **README desatualizado**: lista scripts 00–04; faltam 05–09. `Rplots.pdf` órfão na raiz do projeto.
11. **IUPERJ/UCAM**: na tabela de IES, IUPERJ (346 títulos) e UCAM (42) aparecem separados embora IUPERJ seja o instituto da UCAM — fundir/nota de rodapé.
12. **Figura 7 (mapa)**: o coropleto original por UF (sem fonte/legenda para "títulos históricos") foi substituído por um mapa de evolução em dois painéis (2013 e 2024) com círculos por município proporcionais ao número de programas, com legenda de tamanho e fonte no caption (ver §7 e script 07).

---

## 6. Novas abordagens e sugestões

### 6.1 Correções de dados (P0, antes de re-renderizar)
1. **Refazer a coleta OpenAlex** com dedup por `id_openalex` (+ `doi` após `drop_na`), filtro `type:article`, exclusão de front matter, e tabela de cobertura por periódico/ano.
2. **Corrigir o .bib** com os DOIs corretos (ou remover os registros não verificáveis):
   - Leite & Codato (2013) — localizar DOI correto no SciELO/RSP (o DOI da p. 7–21 do fascículo 21(46)).
   - Marenco → "The Three Achilles' Heels of Brazilian Political Science", BPSR 8(3): 3–38, DOI 10.1590/1981-38212014000100019 (e re-fundamentar a seção "Três Idades" em outra fonte — ou reescrevê-la, pois a periodização atribuída a Marenco não está nesse artigo).
   - Amorim Neto & Santos (2003) → DOI correto em Dados 46(2): 355–388.
   - Candido & Biroli → livro *"Mulheres, poder e ciência política"* (2021) e/ou *"A ciência política é um mundo de homens?"* (RBCP).
3. **Recarregar os números inline** dos RDS (remover hardcodes) e corrigir a legenda da Figura 5 (N = 16.548).
4. **Corrigir os rótulos STM** (Tabela 1, Figuras 5–6) para os rótulos corretos (§2.4) e marcar T6/T7 como artefatos de idioma.
5. **Cronologia**: USP 1971; UnB reclassificada; fundamentar os "60 anos" (UFMG meados 1960s).

### 6.2 Análises que elevariam o artigo
1. **Validação externa da série de PPGs** contra o GeoCapes/relatórios quadrienais da área 39 (o 64 de 2024 é facilmente conferível) e contra o censo de docentes 2024 (1.243 vínculos em 64 programas).
2. **Testes de quebra estrutural / períodos** na série de títulos (1996 ABCP; 2007 BPSR; 2013 REUNI; 2020 pandemia — a queda de 969→701 entre 2019 e 2020 pede explicação, provavelmente atraso de registro, não queda real).
3. **Distinguir CP vs RI vs Políticas Públicas vs Defesa** dentro da "área 39" (dado o alcance real da área) — hoje tudo é tratado como "ciência política".
4. **Redes de orientação**: o script 07 constrói a rede mas não gera figura/tabela — completar (fluxo orientador-orientando, inter-regionalidade).
5. **Gênero/raça dos autores** usando o vínculo `id_pessoa` dos docentes (complementa Candido & Biroli com dado original).
6. **Análise de métodos**: codificar termos metodológicos (regressão, survey, qualitativo, etnografia...) nos resumos para sustentar a "evolução metodológica" do título.
7. **Séries por subárea temática** usando o theta do STM agregado por programa/IES, ligando expansão institucional a mudança de agenda.

### 6.3 Literatura e abordagem crítica (sugestões)
1. **Corrigir e ampliar o referencial da sociologia da disciplina**: além de Forjaz (1997), Lamounier (1982), Marenco e Leite & Codato, incorporar:
   - A **crítica de gênero à historiografia** (Candido, *"A ciência política é um mundo de homens?"*, RBCP; livro *"Dois gêneros, duas histórias?"*).
   - O comparativo **latino-americano** (Ravecca, *The Politics of Political Science*, 2019; trabalhos de Flavia Freidenberg e David Altman sobre a disciplina na região).
   - O debate sobre **internacionalização e dependência acadêmica** (discussões de Ricardo Silva; "Tradições Intelectuais na Ciência Política Brasileira Contemporânea", Dados, 2017).
2. **Engajar com a crítica decolonial/posicional**: o artigo celebra a CAPES como "motor de autonomização" sem discutir o custo da padronização (Qualis, produtivismo) nem as assimetrias regionais de poder — a própria escolha de "periódicos canônicos" do eixo Sul-Sudeste é uma decisão teórica que merece reflexividade.
3. **Reflexividade sobre "canônico"**: justificar a seleção de periódicos com critérios explícitos (Qualis A1/A2? Cobertura? Representatividade regional?) e reconhecer que DADOS, BPSR, OP e RBCP são hegemônicos do eixo RJ/SP/UnB.
4. **Usar a própria área 39 como objeto**: a expansão de programas de "Políticas Públicas", "Defesa" e "Segurança" dentro da área mostra como a disciplina se hibridizou com a policy science e com os estudos estratégicos — um achado que hoje passa despercebido porque tudo é agregado como "ciência política".

### 6.4 Comunicação
1. Título: ou medir métodos de verdade ou trocar "Evolução Metodológica" por "Diversificação Temática" (que o texto sustenta).
2. Tabela de cobertura OpenAlex por periódico (ano inicial, lacunas) para honestidade visual.
3. Separar "artigos de pesquisa" de "registros indexados" nas figuras 3–4.
4. Mapa com fonte e duplo painel.

---

## 7. Checklist de correções prioritárias

**P0 (bloqueiam qualquer uso do artigo):**
- [ ] Corrigir 4 DOIs (Leite & Codato; Marenco; Amorim Neto & Santos; Candido & Biroli) e conferir BIB 79 e Lamounier.
- [ ] Corrigir rótulos dos tópicos STM (tabela + figuras 5–6) e reescrever as interpretações.
- [ ] Refazer coleta OpenAlex (bug do `distinct(doi)`) e filtrar `type:article`/front matter.
- [ ] Corrigir cronologia: USP 1971; UnB fora dos pioneiros dos 60/70; fundamentar "60 anos".

**P1 (qualidade):**
- [ ] Remover hardcodes (11.600, 1.670, 16.548) e corrigir N da Figura 5 (16.548).
- [ ] Documentar o filtro CAPES e excluir os ~73 registros fora da área 39.
- [ ] Corrigir "1.111 trabalhos" da USP (1.161) ou documentar o filtro de orientador.
- [ ] Atualizar README; remover `Rplots.pdf`; renomear script 03 (OpenAlex, não SciELO).

**P2 (estratégico):**
- [ ] Justificar "periódicos canônicos" e reportar cobertura por periódico.
- [ ] Discutir o alcance real da área 39 (PP, Defesa, Segurança, RI).
- [ ] Adicionar análise de gênero/raça e comparativo latino-americano.

---

## 8. Fontes externas consultadas

- OpenAlex API (contagens ao vivo por ISSN, 29/08/2026): `api.openalex.org/works?filter=primary_location.source.issn:...`
- Crossref API (resolução e busca de DOIs): `api.crossref.org/works/...`
- doi.org (resolução de DOI: 404 para 10.1590/0103-3352.2021.34.241517)
- [SciELO-PT — Soares (2005)](https://scielo.pt/scielo.php?script=sci_abstract&pid=S0873-65292005000200004&lng=es&nrm=iso&tlng=pt)
- [IPOL/UnB — "A Ciência Política em Brasília"](https://ipol.unb.br/quem-somos/a-ciencia-politica-em-brasilia/) (PPG UnB: 1984)
- [PPGCP-UFRGS](https://www.ufrgs.br/sncp/programa-de-pos-graduacao-em-ciencia-politica-ufrgs) (criado em 1973; 3º mais antigo)
- [DCP-USP — 50 anos do PPG](https://dcp.fflch.usp.br/50-anos-do-programa-de-pos-graduacao-em-ciencia-politica-da-usp) (1971)
- [UFMG — 50 anos do DCP](https://www.ufmg.br/online/arquivos/042749.shtml) (1969)
- [SciELO — Lua Nova v1 n1 (1984)](https://www.scielo.br/j/ln/i/1984.v1n1/) e [v1 n4 (1985)](https://www.scielo.br/j/ln/i/1985.v1n4/)
- [CESOP/Unicamp — Opinião Pública (1993)](https://www.cesop.unicamp.br/eng/opiniao_publica/apresentacao)
- [LexML — Revista de Sociologia e Política (1994)](https://www.lexml.gov.br/urn/urn:lex:br:rede.virtual.bibliotecas:revista:1994;000491481)
- [SciELO RBCP — Candido, "A ciência política é um mundo de homens?"](https://www.scielo.br/j/rbcpol/a/nyC7pK7Kgy8jLZnmptQWnTG/?lang=pt)
- [IESP-UERJ — Candido, "Dois gêneros, duas histórias?"](https://iesp.uerj.br/colecao-iesp-eduerj-lanca-dois-generos-duas-historias-a-fundacao-da-ciencia-politica-no-brasil-de-marcia-rangel-candido/)
- [Crossref/Unesp — Biroli & Candido, "Mulheres, poder e ciência política" (DOI 10.7476/9786586253702)](https://doi.org/10.7476/9786586253702)
- [Redalyc/CEIPA — Marenco, "The Three Achilles' Heels of Brazilian Political Science"](https://descubridor.ceipa.edu.co/Record/ojs-redalyc-394342001001/Details)
- [Agenda Política — Leite & Codato, "Autonomização... Qualis-Capes"](https://www.agendapolitica.ufscar.br/index.php/agendapolitica/article/view/10/0)

---

## 9. Segunda auditoria — dados de pós-graduação (31/08/2026)

Auditoria focada nos microdados de pós-graduação (CAPES teses/Sucupira/comparação institucional), a pedido do autor, complementando os ciclos de 29/08 e 31/08 (que auditaram principalmente texto, referências e OpenAlex). Metodologia: leitura de código linha a linha em `SCRIPTS/`, verificação empírica direta sobre `DADOS/raw` e `DADOS/processed` (contagens, `table()`, comparações entre séries), sem recoleta de dados brutos.

| Gravidade | Problema | Ação tomada |
|---|---|---|
| **P0** | `SCRIPTS/14_consolida_comparacao_teses.R` usava `DocumentoDiscente` como chave de deduplicação; nas safras 1987–1995 esse campo vem mascarado como `999*****999` **igual para toda a safra**, colapsando cada área-ano em 1–2 registros (ex.: Ciência Política/RI em 1992: 80 títulos reais → 2 na série "comparada"). | Corrigido: valores mascarados (`^[9*]+$`, `^[0*]+$`, ou menos de 6 dígitos úteis) são tratados como ausentes; cai-se na chave composta ano+IES+autor+título já existente no código. Após a correção, a série CP/RI da base comparada bate exatamente com `capes_serie_anual.rds` em 1987–2002 e 2013–2024, com um resíduo de 15–46 títulos/ano (5–12%) em 2003–2012, ainda não explicado (ver Pendências). |
| **P0** | Paper afirmava "data de defesa ausente em cerca de 76% do layout 2013–2024". Falso: `dt_titulacao` tem 0% de NA. O parser (`SCRIPTS/04_protocolo_exploratorio.R`) usava `tryFormats = c("%d%b%Y", "%d/%m/%Y", "%Y-%m-%d")`, que não reconhece o formato SAS `ddMMMaaaa:HH:MM:SS` presente em 75,8% dos registros (mês em inglês, dois-pontos em vez de espaço antes da hora). | Corrigido: parser explícito para os três formatos observados (`%d/%m/%Y %H:%M:%S`, `%d%b%Y:%H:%M:%S`, e `%d/%b/%y` para `data_defesa` no layout antigo). 0% de NA após a correção. Bônus: o ano da data de defesa coincide com `AN_BASE` em **100%** dos registros — não há defasagem ano-base × ano-defesa nesta base, ao contrário do que se supunha. |
| **P0** | Paper afirmava "269 registros da CAPES sem informação de grau acadêmico". Os 269 são reais, mas não "sem informação": no layout antigo, `Nivel == "Profissionalizante"` (2002–2012) não casa com os regex `DOUTOR`/`MESTR` de `SCRIPTS/05_analise_temporal.R` e caía em "Grau não informado", sendo excluído da Figura 1. | Corrigido: `Profissionalizante` mapeado para Mestrado (não havia doutorado profissional na Área 39 antes de 2013). "Grau não informado" agora é 0 em toda a série. |
| **P0** | O filtro da área 39 no layout novo usava só o crosswalk com códigos de programa da Sucupira (ver §2.1), apesar de existir a âncora administrativa direta `NM_AREA_AVALIACAO` no próprio arquivo CAPES. A lógica do filtro estava, além disso, reimplementada de forma independente em `08`, `10` e `06` (haviam divergido silenciosamente se um dos três fosse editado). | Corrigido: `08_auditoria_series_temporais.R` agora usa `NM_AREA_AVALIACAO == "CIÊNCIA POLÍTICA E RELAÇÕES INTERNACIONAIS"` como critério primário (layout novo), com o crosswalk Sucupira como checagem de consistência (discordam em 1 registro de 8.663). Grava o artefato canônico `DADOS/processed/capes_cp_area39.rds`; `06`, `07`, `10` foram atualizados para lê-lo em vez de refiltrar. `07_analise_geografica_redes.R` lia a base **não filtrada**: o "principal IES" (USP) mudou de 1.161 para **1.151** trabalhos após o filtro correto. |
| P1 | `AUDITORIA.md` §2.1 (Problema 1) afirmava que o layout novo "não tem coluna de área de avaliação". Falso — ver correção acima em §2.1. | Corrigido inline em §2.1. |
| **P0** | **Bug de classificação por substring na base comparada (01/09/2026, achado do usuário ao desconfiar do mestrado de Sociologia na Figura 5).** `classifica_area()` em `SCRIPTS/14_consolida_comparacao_teses.R` usava o nome do programa como fallback (`grepl("SOCIOLOGIA", programa)`) para QUALQUER registro cuja área de avaliação não batesse com as seis áreas comparadas — inclusive quando a área de avaliação já era conhecida e simplesmente diferente (ex.: "PSICOSSOCIOLOGIA DE COMUNID.E ECOLOGIA SOCIAL", área real `PSICOLOGIA`, capturado por conter a substring "SOCIOLOGIA"; "SOCIOLOGIA E DIREITO", área real `INTERDISCIPLINAR`). Confirmado em 2024: 75 registros inflando Sociologia por esse caminho. Mesmo padrão de bug afeta potencialmente os fallbacks de História/Geografia/Economia/Antropologia. | Corrigido: o fallback por nome de programa só se aplica quando a área de avaliação está **vazia** (`area == ""`); quando a área é conhecida mas fora do escopo comparado, o registro fica "Não identificado". Sociologia: mestrado em 2024 caiu de 755 para 656 títulos (-13%); total da série 1987–2024 caiu de 25.858 para 24.651. Efeito também em História (34.943→34.377) e demais áreas, em menor grau. `fig11`, `fig15`, `fig16` e as tabelas `tabela_comparacao_*` foram regeneradas. |
| P1 | Achado novo: a comparação com áreas irmãs (1987–2024) mostra que a Área 39 continua **a menor em escala absoluta** em 2024 (64 programas, 1.114 docentes, contra 215/3.589 na História), mas — após a correção do bug do sentinela — teve o **maior crescimento relativo** entre 1987 e 2024 (26→1.002 títulos, +3.754%), maior que História (+3.379%) e Geografia (+3.493%). O texto do artigo (§"A Comparação com Áreas Irmãs") afirmava o contrário ("escala e ritmo substancialmente menores"); a frase foi reescrita para distinguir escala (menor) de ritmo (maior, efeito de base a partir de um patamar quase nulo em 1987). |
| P1 | Resíduo de ~5–12%/ano entre a série CP/RI da base "comparada" e a série principal (`capes_serie_anual.rds`) em 2003–2012 (ver primeira linha desta tabela). Não investigado a fundo por restrição de tempo. | **Pendente.** Hipótese mais provável: o pré-filtro `awk` de `SCRIPTS/12_coleta_capes_comparada.R` (regex de extração ampla) tem recall imperfeito nessas safras especificamente, ou há um segundo padrão de mascaramento de identificador nesses anos que a correção atual não cobre. Não afeta a série principal do artigo (`capes_serie_anual.rds`, usada nas Figuras 1–3, 5–9), só o painel comparativo (Figuras 4/11/15/16). |
| P2 | Duplicatas remanescentes: 2 pares em `id_producao_intelectual` (`8585119`, `8686426`) e casos equivalentes por `nm_discente`+`nm_producao`. Impacto ≤4 registros em 12.661. | Não corrigido (impacto desprezível); documentado aqui para constar que "0 duplicatas" (relatório EDA) se refere à chave OpenAlex, não à CAPES. |
| P2 | Reconciliação externa contra fontes oficiais (GeoCapes, censo docente da Área 39) para os números de 2024 (64 programas, 50 IES, 1.114 docentes). | **Não executada nesta rodada** (exigiria busca externa dedicada). Recomenda-se antes da próxima submissão. |
| P1 | **Reconciliação externa parcial concluída (01/09/2026):** comparação com @marenco2014heels ("The Three Achilles' Heels of Brazilian Political Science", BPSR 8(3), 2014), que documenta a expansão da Ciência Política (estrita) via relatórios CAPES até 2012-2013. O banco de replicação do autor (`bpsr.org.br/files/arquivos/Banco_Dados_Marenco.html`) **não resolveu por DNS** em três tentativas nesta sessão (WebFetch x2, `curl` direto); os valores usados vêm dos gráficos do próprio artigo (via SciELO, imagens em alta resolução), com dois critérios: (a) séries com tabela de valores impressa na figura (Gráficos 4 e 5 do artigo, reproduzidas ano a ano) e (b) pontos-âncora isolados e explícitos no texto/rótulos de barra (Gráfico 3), sem interpolação de pixel — ver comentário de proveniência no topo de `SCRIPTS/18_comparacao_marenco.R`. | Nova seção "Validação Externa" no artigo (após "Formação por nível e intensidade institucional"), com `fig19_marenco_continuidade_razao_doutores.png`: (1) programas MA/PhD em 2013 — Marenco (CP estrita, cumulativo) 38/17 vs. este estudo (Área 39 completa, ativos) 34/21, mesma ordem de grandeza, direção esperada; (2) estados com doutorado — 6 (Marenco, 2010) vs. 7 (este estudo, 2013), os mesmos seis + Paraná; (3) razão doutores titulados/docentes permanentes — série de Marenco (2004–2012: 0,11→0,21) emenda quase sem descontinuidade com a série equivalente deste estudo (2013–2024: 0,23→0,24), o teste mais forte de validade externa dos três. **Continua pendente:** reconciliação com GeoCapes/censo docente 2024 (linha acima) e obtenção do banco bruto de Marenco caso o domínio volte a responder. |
| P2 | Verificação de mistura de encoding dentro do mesmo arquivo bruto (1.B.2 do plano) e de recall do filtro `awk` de extração por safra (1.B.1). | **Não executada nesta rodada.** A taxa de casamento do awk por safra segue uma curva suave sem outliers visíveis (checagem superficial), o que não é garantia definitiva. |
| P2 | `CD_CONCEITO_PROGRAMA` inclui o valor `"A"` (conceito de programas novos, não numérico), que vira `NA` silencioso em `as.numeric()` no `conceito_medio` citado no texto. | **Não corrigido nesta rodada**; documentado como limitação a declarar no caption da figura de conceitos. |
| P2 | Órfãos de higiene: `DADOS/processed/valores_inline_comparacao_areas.rds` (não lido por nenhum .qmd, e sem Geografia); `SCRIPTS/11_correcao_artigo.R` (patch de uma linha já aplicado ao .bib). | Não removidos nesta rodada (baixo risco, não bloqueiam nada). |
| P2 | README lista área de avaliação da Geografia como "43"; `SCRIPTS/13_comparacao_sucupira.R` usa "36"; o paper usa "36". | Não resolvido — precisa checagem contra a tabela oficial de áreas CAPES antes de decidir qual dos dois documentos corrigir. |

**Pipeline re-executado nesta rodada, na ordem:** `08 → 10 → 07 → 05 → 13 → 14 → 15 → 06b` (04 também, para regenerar o relatório EDA com o parser de data corrigido). O modelo STM (script `06`) **não** foi reestimado — o corpus de entrada (CAPES área 39 filtrada) não mudou de tamanho após a correção do filtro (73 exclusões antes e depois), então a reestimação não traria informação nova; só os rótulos (`06b`) foram regenerados.

**Números centrais após a correção (para conferência):** CAPES área 39: 12.661 registros válidos (73 excluídos, 0,57%, 1 discordância entre os dois critérios de filtro); série principal 26 (1987) → 1.002 (2024) títulos/ano; Sucupira 69 programas históricos / 64 ativos em 2024 / 50 IES / 11.600 vínculos docente-programa-ano / 1.670 `id_pessoa` únicos; comparação institucional 2024: CP/RI 64 programas e 1.114 docentes (a menor das seis áreas em escala), com o maior crescimento relativo 1987–2024 entre as seis.
