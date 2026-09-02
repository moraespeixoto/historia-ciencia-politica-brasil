# Revisão crítica — "A Trajetória da Ciência Política no Brasil" (artigo_historia_cp_brasil.qmd)

**Revisor:** parecer técnico simulado (perfil DADOS/RBCS/Opinião Pública/BPSR/RSP/Lua Nova + metodologia quantitativa/cientometria)
**Data:** 2026-09-01
**Base da revisão:** leitura integral do `.qmd`, do PDF renderizado (21 p., ~7.300 palavras incluindo `sessionInfo`), de `referencias.bib`, `AUDITORIA.md`, `README.md`, de todos os scripts de `SCRIPTS/`, das tabelas em `TABELAS/`, dos objetos em `DADOS/processed/` (inspecionados com `Rscript`) e das figuras em `FIGURAS/`. Todos os números citados abaixo foram recomputados a partir dos artefatos do projeto; onde não pude verificar, marco "[verificar]".

> Observação preliminar: o enunciado da tarefa dava como "estabelecidos" 12.485 títulos CAPES e 3.972 artigos OpenAlex. O estado atual do projeto (PDF, `valores_inline_temporal.rds`, AUDITORIA §9) é **12.661 títulos** e **4.553 artigos**. A revisão usa o estado atual; os números do enunciado correspondem a uma versão anterior do pipeline e não devem ser reintroduzidos.

---

## 1. Sumário executivo

### Veredito: **REJEITAR NA FORMA ATUAL, com convite explícito a ressubmissão** (equivale a *major revision* profunda).

O artigo tem uma infraestrutura de dados rara na área (censo CAPES 1987–2024 unificado em dois layouts, microdados Sucupira 2013–2024, OpenAlex, STM, pipeline reprodutível com valores inline) e uma tese interessante (parte da "expansão da ciência política" é expansão de campos limítrofes sob a Área 39). Porém, **o bloco comparativo com as áreas irmãs — que sustenta a segunda das "três contribuições centrais" anunciadas na introdução, o resumo, a seção 4.1.1, as Figuras 10/12/13/14, a Tabela de painel integrado e boa parte da Discussão — está construído sobre códigos de área de avaliação errados**. Quatro das seis "áreas irmãs" comparadas via Sucupira não são as áreas que o artigo diz comparar. Isso inverte o achado comparativo central. Somado a problemas de desenho (unidade de comparação, mestrados profissionais não separados, STM sem validação, corpus multilíngue, literatura com 10 referências), o texto não está em condições de ir a parecer externo antes de uma reconstrução.

### Os 5 problemas mais graves

| # | Problema | Severidade |
|---|----------|-----------|
| 1 | **Códigos de área de avaliação errados em `SCRIPTS/13_comparacao_sucupira.R`** (`areas_alvo`): 38 = EDUCAÇÃO (rotulado "Economia"), 40 = HISTÓRIA (rotulado "Sociologia"), 41 = LETRAS/LINGUÍSTICA (rotulado "Antropologia/Arqueologia"), 42 = CIÊNCIAS AGRÁRIAS I (rotulado "História"). Os códigos corretos no arquivo bruto `sucupira_prog_2024.csv` são: Economia = **28**, Sociologia = **34**, Antropologia/Arqueologia = **35**, Geografia = 36, CP/RI = 39, História = **40**. Recomputando com os códigos corretos, em 2024 a Área 39 tem **64** programas contra Geografia 80, História 80, Economia 76, **Sociologia 52, Antropologia 38**; entre 2013 e 2024 a Área 39 dobrou (32→64) enquanto Sociologia ficou estável (52→52). O artigo afirma o oposto ("o menor sistema de pós-graduação", "História 215 programas e 3.589 docentes", "Economia 192 programas e 4.656 docentes", "Antropologia 155"). | **P0** |
| 2 | **Mestrados/doutorados profissionais não são separados em nenhuma análise.** Em 2024, 20 dos 64 programas da Área 39 (31,2%) são profissionais (17 MP, 1 DP, 2 MP/DP), contra 12,5% em 2013; nas subáreas, PP tem 8 de 14 profissionais e DEFESA 5 de 10. A "expansão" da década de 2010 é, em parte relevante, expansão de mestrados profissionais — o que reforça a tese do artigo, mas não é dito, e contamina todas as razões (títulos/programa, docentes/programa, razão doutores/docentes, comparação com Marenco, que conta cursos acadêmicos). | **P0** |
| 3 | **STM sem qualquer validação e com artefatos que contaminam a leitura substantiva**: K=8 escolhido "por simplicidade"; sem `searchK`, coerência/exclusividade, sem `estimateEffect`; corpus mistura pt/en/es (T5 e T7 são "artefatos de idioma"); T7 é rotulado "Corpus em inglês (BPSR)" mas tem prevalência de 6–14% em 1995–2006, antes da BPSR existir (2007); prevalências são médias de theta por ano, sem controle de composição (fonte, subárea, idioma) — a "queda da teoria política" pode ser em parte efeito de composição (entrada de RI/PP/Defesa e de resumos em inglês). Figura 5 sai com rótulo "13% (2022" truncado e repetido nas 8 facetas e o rótulo "36% (1995-97)" está errado (valor real 38,6%). | **P0** |
| 4 | **Inconsistências internas verificáveis no texto renderizado**: 62 programas (§4.4) vs 64 (§4.1) porque a categoria OUTROS (2 programas, 2,5% dos títulos) é omitida e as porcentagens somam 97,5%; 69 "programas únicos" (Resumo, §3) inclui 2 programas EM DESATIVACAO que o próprio pipeline exclui (67); "(os dois critérios discordam em apenas 1 registro)", "Figura 4, Tabela abaixo" (não há tabela), "(Figura 4)" numerado à mão quando a figura é a 6 no PDF; "Leite (2013) demonstram" e a referência renderizada como "Leite, Adriano, Fernando e Codato. 2013" (campo `author` com "e" em vez de "and"); razões de Marenco comparadas com 1 casa decimal ("0,2 → 0,2"). | **P1** |
| 5 | **Enquadramento e literatura insuficientes para um artigo de pesquisa**: o texto se autodenomina "texto comemorativo", não formula pergunta nem hipóteses testáveis, imprime `sessionInfo()` no corpo, cita 10 referências (nenhuma de sociologia da ciência/campos, nenhuma de cientometria além de Roberts et al. 2014, nenhuma de história da pós-graduação brasileira) e omite trabalhos diretamente concorrentes/complementares (Reis 1999 [verificar], Lessa 2010/2011 [verificar], Nicolau & Oliveira 2017 [verificar], Avritzer, Milani & Braga 2016, Amorim Neto & Santos 2005/2015 [verificar], Keinert & Silva 2010 [verificar], Codato, Madeira & Bittencourt 2020 [verificar]). | **P1** |

### 5 pontos fortes

1. **Escala e abertura dos dados**: é o primeiro trabalho (que eu conheça) a unificar os dois layouts do Catálogo CAPES (1987–2012 e 2013–2024) para a Área 39 com filtro auditável, a cruzar com Sucupira programa-a-programa e a disponibilizar pipeline completo em R com valores inline — a maioria dos balanços (Forjaz 1997; Lamounier 1989; Marenco 2014; Nicolau & Oliveira 2017 [verificar]) trabalha com séries agregadas de relatórios CAPES ou com amostras de periódicos.
2. **A tese da hibridização da Área 39** (CP estrita ≈ 35% dos títulos em 2024; RI 28%; PP 23%; Defesa 11%) é original, relevante para a governança da área e diretamente verificável. Nenhum dos autores clássicos separa esses fluxos; Marenco (2014) trabalha com "ciência política estrita" sem discutir o que ficou de fora.
3. **Cultura de auditoria**: `AUDITORIA.md` documenta erros encontrados e corrigidos (sentinela `999*****999`, parser de datas, "Profissionalizante", substring em `classifica_area`), e o próprio texto reconhece limites (cobertura OpenAlex, K não validado, conceitos não comparáveis). Isso é raro e deve ser preservado — em material suplementar, não no corpo.
4. **Validação externa com Marenco (2014)** é uma boa ideia de desenho (emendar séries de fontes distintas no ponto de corte 2012/2013), ainda que a execução precise de correções (ver §5).
5. **Séries de associações científicas** compiladas de relatórios de gestão, anais e boletins com URL de fonte: é um esforço documental útil que não existe consolidado em lugar algum, mesmo que hoje seja heterogêneo demais para sustentar comparações fortes.

---

## 2. Pontos fortes (detalhados, em diálogo com a literatura)

- **Frente a Marenco (2014)**: Marenco compara CP com Sociologia e Antropologia usando relatórios CAPES até 2012, com contagens cumulativas de cursos; o artigo estende a janela a 2024, passa a "programas ativos por ano" e acrescenta Geografia, História e Economia. A extensão é valiosa **desde que** os códigos de área sejam corrigidos (P0-1) e os profissionais separados (P0-2). A razão doutores titulados/docentes permanentes (Fig. 19) é o ponto de contato mais informativo e pode virar um argumento central: com a correção, a série 2013–2024 (0,23→0,24) mostra estagnação da intensidade doutoral apesar de o número de programas ter dobrado — isso é achado, não apenas validação.
- **Frente a Forjaz (1997) e Lamounier (1989)**: o artigo reconhece que a periodização "três idades" é uma síntese própria (não está assim em Forjaz), mas deveria dizê-lo mais explicitamente e confrontá-la com a periodização de Leite & Codato (2013), que enfatiza a indução top-down via Qualis, e com a de Candido (2023), que critica as narrativas canônicas da história da disciplina. O material empírico permite testar periodizações (pontos de quebra na série de títulos e nos tópicos), o que nenhum desses autores fez.
- **Frente a Leite & Codato (2013)**: a tese da "autonomização por cima" ganha um teste indireto no artigo (a Área 39 cresce por incorporação de programas de PP/Defesa, muitos profissionais, induzidos por editais e demanda institucional — não por reprodução de CP estrita). Este é o eixo mais promissor para uma contribuição teórica, hoje subexplorado.
- **Frente a Nicolau & Oliveira (2017, "Political Science in Brazil: A Bibliometric...", [verificar]) e Avritzer, Milani & Braga (2016, *A ciência política no Brasil: 1960–2015*)**: esses trabalhos mapeiam produção em periódicos e temas por leitura/classificação; o artigo oferece STM em corpus muito maior (16.457 resumos incluindo teses), o que é um avanço se a modelagem for validada. Hoje não é citado nenhum deles.
- **Frente a Soares (2005) e Reis (1999, "Ciência política no Brasil: exercício de mapeamento" [verificar])**: o artigo é honesto ao dizer que não mede mudança metodológica. Isso é correto, mas então o "calcanhar de Aquiles" não deveria ser um dos "três eixos" da introdução.

---

## 3. Falhas

### 3(a) Factuais / históricas

| Onde | Passagem | Problema |
|---|---|---|
| §4.1.1, Fig. 10, 12, 13, 14, `comp_2024` | "História possuía 215 programas e 3.589 docentes, a Economia 192 e 4.656, ... Antropologia/Arqueologia 155 ... Sociologia 80 e 1.912" | **Falso.** São, respectivamente, Ciências Agrárias I, Educação, Letras/Linguística e História (códigos 42, 38, 41, 40 na Sucupira). Ver P0-1. |
| §4.1 | "quase dobrou, contra uma variação de 2% na História no mesmo período" | A "História" da comparação é Ciências Agrárias I. História real: 63→80 (+27%). |
| §4.1.1 | "em 2024 ela tinha o menor número de programas e de docentes entre as seis áreas comparadas" | Falso. Com códigos corretos, Sociologia (52) e Antropologia (38) são menores que CP/RI (64). |
| Resumo, Introdução, Conclusão | "a ciência política tem o menor sistema de pós-graduação" | Idem. É o **segundo** achado comparativo do artigo que se inverte após auditoria (o primeiro foi o sentinela, AUDITORIA §9). |
| §4.2 | "Os encontros da ABCP, iniciados em 1998" | [verificar] — o 1º Encontro da ABCP foi em 1998 (Rio de Janeiro)? Fontes da própria tabela começam em 2008. Citar fonte. |
| §4.2 | "SBS (1950)", "ABA (1955)", "ANPUH (1961)", "ANPEC (1973)", "ANPEGE (1994)" | Plausíveis; a ABA foi fundada em 1955 mas a 1ª Reunião Brasileira de Antropologia é de 1953 (a própria tabela registra 1953). SBS: fundada em 1950, refundada em 1985 [verificar]. Citar fonte para cada data. |
| §2.1 / Fig. 20 | "UFRGS (1973)"; "mestrado em ciência política e relações internacionais da UnB, iniciado em 1984" | [verificar] com a Sucupira (`an_inicio_programa`) e com Marenco (2014). Marenco data o 3º doutorado (UFRGS) em 1996; o mestrado UFRGS 1973 precisa de fonte. UNICAMP (1985) e UFPE [verificar] estão ausentes da "Idade da Expansão", que na Fig. 20 tem apenas dois marcos. |
| §2.1 | "programa da UFMG organizado institucionalmente em 1966 (recebendo a primeira turma do mestrado em 1967)" | Coerente com a página do PPGCP-UFMG; citar fonte formal (Forjaz 1997 diz 1966). |
| §2.1 | "IUPERJ (1969)" | Fundação do IUPERJ 1969; mestrado iniciado em 1969/1970 [verificar]. |
| §2.1 | "revista DADOS ... 1966" e §3 "DADOS só aparece a partir de 1977" no OpenAlex | Correto, mas a cobertura OpenAlex da DADOS tem **lacuna 1989–1991 (zero registros) e 1992 (2)** — não mencionado; a "série de artigos 1977–2024" não é contínua. |
| §4.5 | "Produção Científica em Periódicos de Ciência Política (1977–2024)... comportamento consolidado ao longo de mais de quatro décadas" | Com a lacuna acima e a entrada escalonada dos periódicos (Lua Nova 1984, OP/RSP 1993, RBCP 2009, BPSR 2007), o "pico em 2015" e a queda posterior são em grande parte composição/indexação. |
| §3, item 4 | "áreas de avaliação 36 (Geografia), 38 (Economia), 39, 40 (Sociologia), 41 (Antropologia e Arqueologia) e 42 (História)" | Códigos errados (ver acima). README diz Geografia = 43; também errado. |
| §2.2 | "A criação da Área 39 ... conferiu ao campo critérios próprios de produtividade, representados sobretudo pelo Qualis Periódicos" | A numeração "39" é recente (a numeração das áreas mudou ao longo do tempo); dizer "a área de avaliação de Ciência Política e Relações Internacionais". Datar a separação da área em relação à Sociologia [verificar: 1998? 2011?]. |

### 3(b) Interpretação / inferência

1. **Efeito de base apresentado como achado**: "crescimento relativo 3.754% vs 3.490% na História" a partir de 26 títulos em 1987 — a base de 1987 do Catálogo é sabidamente incompleta (o próprio §4.1 admite subregistro) e o índice é não informativo. Substituir por taxas de crescimento em janelas (CAGR por década) e por participação da Área 39 no total das seis áreas.
2. **"A superação do confinamento geográfico original demonstra a eficácia do modelo indutor da CAPES"** (Discussão): afirmação causal sem desenho causal. O artigo não tem contrafactual, não observa editais, bolsas ou avaliação. Reescrever como hipótese.
3. **"queda entre 2019 e 2020, provável efeito da pandemia"**: plausível, mas há queda equivalente em 2007 (não discutida) e a série de 2019 pode ser pico de registro; discutir defasagem de registro (`dt_titulacao` vs `an_base`).
4. **STM**: (i) "perda de dominância da teoria política" pode ser composição — T6 domina em 1995–99 quando o corpus é quase só CAPES-CP estrita + DADOS/Lua Nova; a entrada de RI/PP/Defesa e de resumos em inglês redistribui massa; (ii) rótulos de tópico atribuídos sem leitura de documentos exemplares (`findThoughts`); (iii) T1 mistura "direitos humanos, gênero, drogas, refugiados" — heterogêneo; (iv) a heatmap usa bin "1980-1999" mas o corpus começa em 1995; (v) mistura teses e artigos com pesos iguais (um resumo de tese ≠ um artigo).
5. **Subáreas por nome de programa**: a unidade é o programa, não a tese; um "Programa de Ciência Política" da UFPE titula teses de RI e vice-versa; sem validação manual (precision/recall) o 35% é estimativa com erro desconhecido. Casos concretos duvidosos em `tabela_mapeamento_programas_subareas.csv`: "SEGURANÇA PÚBLICA E CIDADANIA", "SEGURANÇA CIDADÃ" → DEFESA (segurança pública não é defesa); "SEGURANÇA DE AVIAÇÃO E AERONAVEGABILIDADE CONTINUADA" (ITA) → DEFESA; "CIÊNCIAS AEROESPACIAIS" → OUTROS (regex "AEROESPACIAL" não casa plural); "CIÊNCIA POLÍTICA E RELAÇÕES INTERNACIONAIS" → CP (é híbrido).
6. **Comparação com Marenco**: `area39_ma_2013 = n_distinct(cd_programa_ies)` conta **todos** os programas (inclusive os só-doutorado e os profissionais) e chama isso de "programas de mestrado"; Marenco conta cursos de mestrado acadêmico de CP estrita. "6 estados (2010) vs 7 (2013)" compara escopos diferentes e anos diferentes. A razão 0,11→0,21 (Marenco) vs 0,23→0,24 é interessante, mas o texto arredonda a 1 casa ("0,2 → 0,2") e perde a informação.
7. **Associações**: as métricas são incomparáveis (inscritos vs credenciados vs propostas vs aprovados; estimativas pré-evento e blogs pessoais como fonte — SBS 2023 "Blog pessoal"). A conclusão "a ciência política mobiliza a menor escala" é frágil: ABCP 2024 = 1.722 inscritos > ANPOCS 2024 = 1.193 credenciados > SBS 2023 ≈ 1.700. Aliás, o próprio §4.2 admite isso ("em patamar semelhante ao da ANPOCS e da ANPEGE"). Ou se constrói uma métrica comum (ex.: trabalhos aprovados por programa ativo da área) ou o bloco vira material suplementar.
8. **"Conceito médio 4,3 vs Economia 4,2"**: além do erro de código, `cd_conceito_programa == "A"` (programas novos) é descartado, e a média de conceitos ordinais entre áreas com distribuições distintas não é comparável (o texto diz isso e, mesmo assim, compara).
9. **Docentes por programa** usa todas as categorias (permanente, colaborador, visitante) — a métrica padrão CAPES é docentes permanentes; `docentes_permanentes` já é calculado em 13 e não é usado.

### 3(c) Inconsistências internas

| ID | Onde | Descrição |
|---|---|---|
| C1 | §4.4 vs §4.1 | 62 programas (21+17+14+10) vs 64; OUTROS (2) omitido; percentuais somam 97,5%. |
| C2 | Resumo, §3 | 69 programas únicos (`n_distinct(prog$cd_programa_ies)` sobre `prog` **não filtrado** em 08) vs 67 na tabela de mapeamento e 64 ativos. |
| C3 | §3, item 1 | "(os dois critérios discordam em apenas 1 registro)" hardcoded — existe `v_temp$n_discordantes_area39`. |
| C4 | §4.1 e §4.1.1 | "(Figura 4)" e "Figura 4, Tabela abaixo" — no PDF a figura de programas comparados é a 6; não há tabela. |
| C5 | §3.2 | "restaram 38 safras" — 1987–2024 são 38 anos, mas a série de programas é 2013–2024 (12) e a de artigos 1977–2024 com lacunas. |
| C6 | Fig. 5 (06b) | Anotação hardcoded "36% (1995-97)": valor real da média 1995–97 de T6 = 0,386. A figura renderizada mostra "13% (2022" truncado em todas as facetas. |
| C7 | Fig. 6 vs Fig. 5 | Heatmap com década "1980-1999" e série começando em 1995. |
| C8 | §4.4 | Fig. 9 "1995–2024" — por que 1995 e não 1987? (títulos 1987–1994 têm código CNPq 7090x e poderiam ser classificados). |
| C9 | §4.1.1 | História cresceu "3.490%" no texto; AUDITORIA §9 registra 3.379% (rodada anterior) — o AUDITORIA está desatualizado em relação ao pipeline. |
| C10 | `comp_metricas` | Total CP/RI 1987–2024 = 12.631 na base comparada vs 12.661 na série principal (30 registros de diferença; AUDITORIA diz "bate exatamente"). |
| C11 | `valores_inline_comparacao_areas.rds` | Arquivo órfão com 34 programas em 2013 (antes do filtro de desativação); `SCRIPTS/11_correcao_artigo.R` órfão. |
| C12 | Fig. 4 (05) | Rótulos de legenda hardcoded `c("BPSR","DADOS","Lua Nova","Opinião Pública","RBCP","RSP")` — se a ordem do fator mudar, os rótulos trocam. |
| C13 | Fig. 1 título | "Títulos ... em Ciência Política" quando a série é Área 39 (CP+RI+PP+Defesa). Idem Figs. 2, 3, 5, 7. |
| C14 | §4.5 | Texto diz que resenhas foram excluídas; o filtro em 03 é `tipo == "article"` + regex de front matter; OpenAlex classifica resenhas como "article" com frequência — não há evidência de exclusão de resenhas. |
| C15 | Apêndice | Numerado "6.1 Ambiente de Replicação" apesar de `{.unnumbered}` no título da seção (subseção herda numeração). |

### 3(d) Escrita e estrutura

- "Neste texto comemorativo" (Introdução e Discussão): incompatível com artigo de pesquisa; remover.
- A Introdução anuncia "três eixos" e "sete dimensões" e "três resultados centrais" — três esquemas sobrepostos; escolher um. Não há pergunta de pesquisa formulada como pergunta nem hipóteses.
- Resumo com 4 parágrafos e dezena de números; periódicos exigem 150–250 palavras.
- "Dados e Estratégia" contém o relato da auditoria (sentinela, parser de datas, "Profissionalizante") — isso é changelog, vai para suplementar.
- `sessionInfo()` impresso no corpo (2 páginas do PDF).
- Listas com bullets em seções analíticas (§2.1, §3.1) — em prosa, para revistas brasileiras.
- Título e subtítulo somam 30 palavras; encurtar.
- Repetições: a tese da hibridização aparece em Resumo, Introdução (2x), §4.4, Discussão e Conclusão com quase as mesmas frases.
- "A convergência de duas bases ... é um teste de robustez que os dados administrativos usados aqui superam" — frase confusa.
- Citações narrativas incorretas: "Leite (2013) demonstram"; "Soares [@soares2005calcanhar]" gera "Soares (Soares 2005)".
- Anglicismos/rótulos técnicos no corpo ("linkage", "Camada 2", "protocolo de programação científica") sem definição.

---

## 4. Dados

### 4.1 Cobertura e vieses das fontes

**Catálogo CAPES 1987–2012 (layout antigo).** 3.998 registros da Área 39, todos com código CNPq 7090x (7.09.00 CP 3.734; 7.09.05 RI 214; 7.09.03 Comportamento 50) e `area_avaliacao` = "CIÊNCIA POLÍTICA E RELAÇÕES INTERNACIONAIS". Como 100% dos registros da área têm código 7090, a âncora por código parece ter recall completo dentro do que o pré-filtro `awk` capturou — mas o pré-filtro é o gargalo: (i) o regex `ci.ncia pol.tica` em `LC_ALL=C` só casa com arquivos Latin-1 (1 byte por acento); arquivos UTF-8 não casariam por "ciência" (2 bytes), restando só o código 7090 — os logs mostram que funcionou (ex.: 2000: 116 de 23.724; 2020: 701 de 80.114), mas não há teste de recall por safra; (ii) a dependência de `/dados/classe_media/.../capes_recursos_ckan.csv` torna o passo 01 irreproduzível fora da máquina do autor. **Subregistro pré-1996** é conhecido (Catálogo é alimentado pelos programas; 27 registros em 1987 é implausível para UFMG+IUPERJ+USP+UFRGS+UnB+UNICAMP) — o texto admite genericamente, mas usa 1987 como base de crescimento.

**Catálogo CAPES 2013–2024.** 8.662 registros; 1 com `nm_area_avaliacao` NA. A âncora é a união `via_area_avaliacao | via_crosswalk_sucupira`, o que pode incluir teses de programas que **mudaram de área** (crosswalk usa a lista de códigos de programa de qualquer ano 2013–2024). Checar: programas com `nm_area_avaliacao` diferente de CP/RI em algum ano e presente na lista (ex.: programas de PP que migraram de Interdisciplinar para 39). Todos os 8.662 têm `nm_area_conhecimento = "CIÊNCIA POLÍTICA"` — indica que o catálogo novo atribui a área básica do programa, não da tese: logo, a classificação em subáreas só pode ser por programa (como feita) ou por texto (não feita).

**Sucupira 2013–2024.** 616 linhas programa-ano; 4 EM DESATIVACAO; 69 códigos únicos (67 após filtro). Modalidade profissional: 4/32 (2013) → 20/64 (2024). Graus em 2024: 30 M/D, 13 M, 17 MP, 2 MP/DP, 1 D, 1 DP. Nada disso aparece no artigo. `cd_conceito_programa == "A"` → NA (programas novos excluídos da média).

**OpenAlex.** 5.005 obras; 4.553 após `article`+`!front_matter`+`ano<=2024`. Por periódico (n, primeiro ano, % com resumo): BPSR 397 (2007, 93%), DADOS 1.074 (1977, 75%), Lua Nova 1.206 (1984, 75%), Opinião Pública 517 (1993, 99%), RBCP 468 (2001[!], 89%), RSP 891 (1993, 88%). Problemas: (i) DADOS com **zero registros em 1989–1991** e 2 em 1992; (ii) RBCP com 1 registro em 2001 (antes da fundação em 2009 — erro de atribuição de ISSN no OpenAlex); (iii) **25 duplicatas pt/en na BPSR 2007–2008** (mesmo título, dois `id_openalex`) — a deduplicação por `id_openalex` não as remove; (iv) regex de front matter exclui títulos começando com "Tendências" (13 artigos) e "Preferências" (3) — falsos positivos (`pref` e `tend[êe]ncia` no padrão); (v) 25% dos artigos de DADOS/Lua Nova sem resumo → entram no STM só se tiverem resumo (verificar o que 06 faz com NA); (vi) idioma: pt 3.663, en 533, es 342 — o corpus tem 19% de resumos não-portugueses (nos artigos), origem dos T5/T7.

**Seleção de periódicos.** Faltam justificativa e sensibilidade. Ausentes: RBCS (ANPOCS), Novos Estudos CEBRAP, Sociedade & Estado, Caderno CRH, Civitas, Política & Sociedade, Teoria & Sociedade, Revista Brasileira de Estudos Legislativos [verificar existência], e — crucial dado que RI é 28% da Área 39 — RBPI e Contexto Internacional. A escolha enviesa o corpus STM para CP estrita e contra RI/PP/Defesa nos artigos, mas não nas teses, criando assimetria entre as duas metades do corpus.

**Associações.** Tabela consolidada com métricas heterogêneas, muitas NA, fontes de qualidade variável (imprensa, blog pessoal, estimativas pré-evento). ABCP tem 4 pontos com dados. Não sustenta comparações; sustenta um quadro descritivo em suplementar.

**Marenco (2014).** Valores lidos de gráficos do artigo (o banco de replicação não resolveu). Precisa ser dito no texto (hoje só no script).

### 4.2 Unidade de análise, chaves, duplicatas

- Títulos: registro do catálogo; 2 pares duplicados por `id_producao_intelectual` (8585119, 8686426) pendentes (AUDITORIA §9).
- Programas: `cd_programa_ies`; OK. IUPERJ/UCAM vs IESP-UERJ: o texto menciona; tratar explicitamente na tabela de IES.
- Docentes: `id_pessoa`; docentes em mais de um programa contam uma vez por área-ano (correto) mas "docentes por programa" soma vínculos — explicitar.
- STM: `corpus_stm_n = modelo_docs = 16.457` (06b sobrescreve ambos com `nrow(theta)`); verificar quantos documentos foram descartados por `lower.thresh`/tamanho antes do modelo e reportar.

### 4.3 Verificações pendentes concretas (com "como")

1. **Recomputar toda a comparação Sucupira com códigos 28/34/35/36/39/40** (ver Plano, T1.1) e reescrever §4.1.1, Discussão, Resumo, Introdução, Conclusão.
2. **Separar acadêmico/profissional** em todas as contagens (Sucupira: `nm_modalidade_programa`; Catálogo novo: `nm_grau_academico`; antigo: `nivel == "Profissionalizante"`).
3. **Recall do pré-filtro**: para 3 safras (uma por década), baixar o CSV bruto completo e contar `area_avaliacao == "CIÊNCIA POLÍTICA E RELAÇÕES INTERNACIONAIS"` sem pré-filtro; comparar com `capes_cp_area39.rds`.
4. **Programas que mudaram de área** no crosswalk: `prog %>% group_by(cd_programa_ies) %>% summarise(n_distinct(cd_area_avaliacao))` no bruto Sucupira sem filtro de área; e no catálogo novo, `nm_area_avaliacao != CP/RI & via_crosswalk_sucupira`.
5. **Diferença de 30 registros** entre 12.661 (principal) e 12.631 (comparada): `anti_join` por chave composta.
6. **Duplicatas OpenAlex pt/en**: dedup adicional por (periódico, ano, título normalizado) ou por DOI base; recomputar 4.553.
7. **Front matter**: trocar `pref` por `^pref[áa]cio` e `tend[êe]ncia` por `^tend[êe]ncias( e debates)?$`-like; listar os excluídos e ler.
8. **Resenhas**: checar amostra de 100 títulos do OpenAlex classificados como `article` para estimar proporção de resenhas (títulos com "Resenha", nomes de livros, "Book review").
9. **Lacuna DADOS 1989–1992**: confrontar com sumários SciELO/site da revista; decidir se a série de artigos começa em 1993 ou se preenche via SciELO.
10. **`total_programas_unicos`**: computar sobre `prog` filtrado (67).
11. **Anotações da Fig. 5**: gerar a partir dos dados (`stm_evolucao_anual.rds`) e só no facet correto.
12. **GeoCapes**: reconciliar contagem de programas 2013–2024 da Área 39 com o painel GeoCapes (pendente desde AUDITORIA §9).

---

## 5. Metodologia

### 5.1 STM
- **K**: rodar `stm::searchK(out$documents, out$vocab, K = c(6, 8, 10, 12, 15, 20, 25), prevalence = ~ s(ano) + fonte, data = out$meta, N = floor(0.1*length(out$documents)), heldout.seed = 20260828)`; reportar held-out likelihood, semantic coherence, exclusivity, residuals; escolher K na fronteira coerência-exclusividade; testar estabilidade com 3 sementes (`stm` com `init.type="Spectral"` é determinístico, então a estabilidade se testa com `init.type="LDA"` ou perturbando o corpus).
- **Idioma**: decisão recomendada — **restringir o corpus a resumos em português** (usar `cld2`/`cld3` ou `textcat` para detectar idioma; para o catálogo, `nm_idioma`/heurística) e reportar em suplementar um modelo alternativo com o corpus completo. Alternativa inferior: manter multilíngue e excluir T5/T7 renormalizando theta (o que o artigo não faz).
- **Pré-processamento**: sem stemming; `lower.thresh = 20` sem justificativa; sem bigramas (ex.: "políticas públicas", "opinião pública" são compostos-chave). Testar `stem = TRUE` com SnowballC "portuguese" ou lematização (`udpipe`) e reportar sensibilidade.
- **Covariáveis**: usar `prevalence = ~ s(ano) + fonte + subarea` e `estimateEffect(1:K ~ s(ano) + fonte + subarea, ...)` com ICs; plotar efeitos marginais por ano **dentro** de fonte (teses vs artigos) e dentro de subárea. Isso responde diretamente se a "queda da teoria política" é composição.
- **Validação humana**: para cada tópico, ler 20 documentos com maior theta (`findThoughts`) e 20 aleatórios com theta > 0,5; dois codificadores; kappa; renomear tópicos.
- **Peso**: teses vs artigos — ou modelos separados, ou reportar prevalência por fonte.

### 5.2 Subáreas
- Manter classificação por programa, mas: (i) corrigir regex (plural "AEROESPACIAIS"; separar SEGURANÇA PÚBLICA de DEFESA — criar categoria "Segurança pública" ou juntá-la a PP); (ii) usar `nm_area_basica` e `nm_area_concentracao` da Sucupira/Catálogo como segunda fonte; (iii) **amostra estratificada de 200 teses (40 por subárea)** com leitura de título+resumo por dois codificadores → matriz de confusão, precisão/recall por classe; (iv) estender a 1987–2012 via códigos CNPq (7090x) e nome do programa (`nome_programa` existe no layout antigo).
- Reportar também a **modalidade** cruzada com subárea (PP: 8/14 profissionais; Defesa: 5/10).

### 5.3 Comparação com áreas irmãs
- Corrigir códigos; separar acadêmico/profissional; usar docentes **permanentes**; conceito: reportar distribuição (proporção 3/4/5/6/7), não média.
- Denominadores: programas ativos por ano; títulos por programa **acadêmico**; doutores/docente permanente (já feito em 18 para a Área 39 — estender às seis áreas).
- Antropologia/Arqueologia no layout antigo: incluir 7040 (Arqueologia) além de 7030.
- Concentração: HHI e participação da maior IES já calculados (`tabela_comparacao_concentracao_ies.csv`) — usar; calcular também Gini de títulos por IES e por UF, para as seis áreas, 2013 e 2024.
- Séries longas: substituir "crescimento relativo desde 1987" por CAGR por década e por participação da Área 39 no total das seis (1995–2024), com o layout antigo re-extraído via `area_avaliacao` (que existe em todas as safras antigas e evita mistura de critérios CNPq/área de avaliação).

### 5.4 Séries temporais
- Testar pontos de quebra na série de títulos (log) com `strucchange::breakpoints` ou regressão segmentada (`segmented`); comparar as quebras estimadas com a periodização "três idades" e com marcos de política (PNPG 2005–2010, 2011–2020; Reuni 2007; cortes 2015–2016; pandemia).
- Modelo de contagem: `glm(titulos ~ ano + I(ano >= 2007) ...)` é fraco; preferível painel programa-ano (Sucupira 2013–2024) com efeitos fixos de programa: títulos ~ idade do programa + modalidade + conceito + região.

### 5.5 Análises de baixo custo com os dados já existentes
1. Idade dos programas (`an_inicio_programa`) — curva de criação por ano, por subárea e modalidade (1966–2024): substitui a Fig. 20 "à mão" por dado.
2. Coorte de criação × região × modalidade.
3. Doutores/docentes permanentes para as seis áreas.
4. Rede de orientação (`rede_orientacao` já construída em 07, nunca usada): componentes, centralidade de orientadores, endogamia institucional (orientador titulado na mesma IES — `nm_pais_ies_titulacao`, `grau_titulacao` estão nos docentes).
5. Formação dos docentes no exterior (`nm_pais_ies_titulacao`) por área e ano — mede internacionalização melhor que "BPSR 2007".
6. Idioma dos artigos por periódico e ano (já em `idioma`) — internacionalização da publicação.
7. Citações (`citacoes`, `fwci`) por periódico/ano — descritivo.
8. Distribuição de páginas das teses (`nr_paginas`) por grau e época — proxy de padronização.

### 5.6 Análises que exigem novos dados
- Lattes (via `getLattes`/extrator) para trajetória de egressos; Scopus/WoS para citações comparadas; fichas de avaliação quadrienal (2013, 2017, 2021) para notas por quesito; CNPq bolsas PQ por área; **gênero por nome** (usar `genderBR` com IBGE) — ético se agregado, sem identificação individual, com nota metodológica; a frase "nenhuma dessas características é inferida por nome" pode ser mantida como escolha, mas justificar.

---

## 6. Literatura

Só 10 referências. Sugestões, **todas a confirmar** (não inserir sem checar DOI/páginas):

**(i) História da CP brasileira**
- Reis, Fábio Wanderley (1999) "Ciência política no Brasil: exercício de mapeamento", *Sociologia, Problemas e Práticas* [verificar]. — §2.1.
- Lessa, Renato (2010/2011) "O campo da ciência política no Brasil: uma aproximação construtivista", em Martins, C.B.; Lessa, R. (orgs.) *Horizontes das Ciências Sociais no Brasil: Ciência Política* (ANPOCS) [verificar]. — §2.
- Martins, Carlos Benedito; Lessa, Renato (orgs.) (2010) *Horizontes das ciências sociais no Brasil: Ciência Política*. São Paulo: ANPOCS [verificar].
- Nicolau, Jairo; Oliveira, Lilian (2017) "Political Science in Brazil: A Bibliometric Analysis of Brazilian Journals (1966–2015)", *BPSR* ou *Revista Brasileira de Ciência Política* [verificar]. — §4.5 e STM.
- Avritzer, Leonardo; Milani, Carlos R. S.; Braga, Maria do Socorro (orgs.) (2016) *A ciência política no Brasil: 1960–2015*. Rio de Janeiro: FGV Editora [verificar]. — §2 (vários capítulos por subárea).
- Amorim Neto, Octavio; Santos, Fabiano (2005) "La ciencia política en Brasil: el desafío de la expansión", *Revista de Ciencia Política* 25(1) [verificar]; (2015) "La ciencia política en Brasil en la última década..." *RCP* 35(1) [verificar]. — §2.2, comparação.
- Keinert, Fábio C.; Silva, Dimitri P. (2010) "A gênese da ciência política brasileira", *Tempo Social* 22(1) [verificar]. — §2.1.
- Codato, Adriano; Madeira, Rafael; Bittencourt, Maiane (2020) "Political Science in Latin America: a scientometric assessment", *Scientometrics* [verificar]. — §4.5/STM.
- Lamounier, Bolívar (1982) "A ciência política no Brasil: roteiro para um balanço crítico", em Lamounier (org.) *A ciência política nos anos 80*. Brasília: UnB [verificar — e conferir se `lamounier1989anos70` no .bib não é na verdade este capítulo].
- Trindade, Hélgio (org.) (2007) *As ciências sociais na América Latina em perspectiva comparada* [verificar]; Miceli, Sergio (org.) (1989/1995) *História das ciências sociais no Brasil*, 2 vols. — já parcialmente citado.
- Candido, Marcia R.; Feres Jr., João; ... (2019+) sobre gênero na CP brasileira [verificar]; já citado Candido 2023.
- Bringel, Breno; ... sobre internacionalização das ciências sociais brasileiras [verificar].

**(ii) Sociologia da ciência e dos campos**
- Bourdieu, P. (1976) "Le champ scientifique", *ARSS* 2(2-3); (1984) *Homo Academicus*. — para "hibridização" e fronteiras.
- Whitley, R. (2000) *The Intellectual and Social Organization of the Sciences*, 2ª ed. — CP como campo de "fragmented adhocracy".
- Abbott, A. (2001) *Chaos of Disciplines*. — fractalização temática (útil para STM).
- Fourcade, M. (2009) *Economists and Societies*. — comparação com Economia.
- Heilbron, J. (2014) "The social sciences as an emerging global field", *Current Sociology* 62(5).
- Beigel, F. (2013/2014) sobre circuitos periféricos e avaliação na América Latina [verificar títulos].
- Alatas, S. F. (2003) "Academic dependency and the global division of labour in the social sciences", *Current Sociology* 51(6).
- Ortiz, R. (2004) "As ciências sociais e o inglês", *RBCS* 19(54) [verificar]. — para T7.

**(iii) Cientometria / topic modeling**
- Grimmer, J.; Stewart, B. M. (2013) "Text as Data: The Promise and Pitfalls...", *Political Analysis* 21(3).
- DiMaggio, P.; Nag, M.; Blei, D. (2013) "Exploiting affinities between topic modeling and the sociological perspective on culture", *Poetics* 41(6).
- Roberts, Stewart & Tingley (2019) "stm: An R Package for Structural Topic Models", *JSS* 91(2). — citar o pacote.
- Mimno et al. (2011) sobre coerência semântica [verificar].
- Aplicações brasileiras: Codato/Madeira/Bittencourt (acima); trabalhos em *BPSR*/*Opinião Pública* com STM em resumos de teses [verificar]. — mostrar comparabilidade da escolha de K.

**(iv) História da pós-graduação brasileira**
- Balbachevsky, E. (2005) "A pós-graduação no Brasil: novos desafios para uma política bem-sucedida", em Brock & Schwartzman (orgs.) *Os desafios da educação no Brasil* [verificar].
- Schwartzman, S. (1979/2001) *Um espaço para a ciência: a formação da comunidade científica no Brasil*.
- Velloso, J. (org.) (2002–2003) *A pós-graduação no Brasil: formação e trabalho de mestres e doutores no país*, 2 vols. CAPES [verificar].
- Martins, C. B. (2018) "As origens da pós-graduação nacional (1960–1980)", *RBCS* 33(96) [verificar].
- Cury, C. R. J. (2005) "Quadragésimo ano do parecer CFE nº 977/65", *Revista Brasileira de Educação* [verificar].
- Barros, A. (2018/2020) sobre mestrados profissionais / expansão da pós [verificar].
- PNPG 2011–2020 (CAPES 2010) e Parecer Sucupira 977/1965 — documentos primários.
- CAPES (2019) *Documento de Área 39* e (2017) *Relatório da Avaliação Quadrienal* — atualizar `capes2022relatorio` com URL estável e data de acesso.

**Correções no `.bib`**
- `leite2013autonomizacao`: `author = {Leite, Fernando and Codato, Adriano}`; DOI `10.31990/10` [verificar — Agenda Política 1(1), 2013, pp. ? ]; adicionar páginas.
- `lamounier1989anos70`: conferir título do capítulo e páginas em Miceli (1989) [verificar].
- `marenco2014heels`: DOI [verificar]; título completo "The Three Achilles' Heels of Brazilian Political Science" ok.
- `capes2022relatorio`: adicionar `note = {Acesso em ...}` e `type`.
- Adicionar `roberts2019jss` (pacote), `stm` versão usada.

---

## 7. Adequação à revista

| Revista | Escopo / formato | Limite [verificar] | Observações |
|---|---|---|---|
| **DADOS** (IESP-UERJ) | ciências sociais; aceita balanços disciplinares; autor-data | ~9.000–10.000 palavras incl. notas e refs [verificar]; resumo ≤ 150 palavras; material suplementar via SciELO Data | Publicou Forjaz-like balanços; forte tradição em CP. Boa opção após correções. |
| **RBCS** (ANPOCS) | ciências sociais amplas; autor-data | ~8.000–9.000 palavras [verificar]; abstract inglês | Comparação com Sociologia/Antropologia interessa ao público; ANPOCS é objeto do artigo (conflito leve, não impeditivo). |
| **Opinião Pública** (CESOP) | comportamento, opinião, instituições; menos afeita a história disciplinar | ~10.000 palavras [verificar] | Escopo menos aderente. |
| **BPSR** (ABCP) | inglês; publicou Marenco 2014 e dossiês sobre a disciplina | 8.000–10.000 palavras [verificar]; dados de replicação obrigatórios (Dataverse) [verificar] | **Melhor destino natural**: continuidade explícita com Marenco (2014); exige tradução e depósito de dados. |
| **Revista de Sociologia e Política** (UFPR) | CP/sociologia política; autor-data | ~9.000 palavras [verificar] | Codato/Leite são da casa; bom destino para a tese da autonomização. |
| **Lua Nova** (CEDEC) | teoria política/ensaio | — | Escopo pouco aderente a artigo cientométrico. |
| **RBCP** (UnB) | CP; publicou Candido 2023 | ~10.000 palavras [verificar] | Boa alternativa; público diretamente interessado. |
| **Teoria & Sociedade** (UFMG) | sociologia/CP; UFMG é marco do artigo | [verificar] | Alternativa regional. |
| **Novos Estudos CEBRAP** | ensaio/interdisciplinar | ~8.000 [verificar] | Pouco aderente. |

**Recomendação**: (1) **BPSR** (em inglês, com replicação em Dataverse, enquadrando como "Marenco revisited, ten years later"); (2) **DADOS**; (3) **Revista de Sociologia e Política** ou **RBCP**. Em qualquer caso: cortar para ≤ 9.000 palavras, resumo ≤ 200 palavras + abstract, 5 palavras-chave, ≤ 8 figuras no corpo, restante em suplementar com DOI (Zenodo/OSF/SciELO Data).

---

## 8. Tabela consolidada de achados

| ID | Categoria | Sev. | Onde | Descrição | Correção proposta |
|---|---|---|---|---|---|
| F01 | dado | P0 | `SCRIPTS/13_comparacao_sucupira.R` `areas_alvo`; `SCRIPTS/12_coleta_capes_comparada.R` (se usa os mesmos códigos); §3 item 4; §4.1.1; Figs 10,12,13,14; `tabela_comparacao_painel_integrado.csv`; README | Códigos de área de avaliação errados (38/40/41/42 = Educação/História/Letras/Agrárias I). | Usar 28 Economia, 34 Sociologia, 35 Antropologia/Arqueologia, 36 Geografia, 39 CP/RI, 40 História; validar por `nm_area_avaliacao`; reexecutar 13→14→18; reescrever texto. |
| F02 | método | P0 | Todo o artigo; Sucupira `nm_modalidade_programa`; Catálogo `nm_grau_academico`/`nivel` | Profissionais (31% dos programas em 2024) não separados. | Reportar acadêmico/profissional em séries, subáreas, comparação e Marenco; Fig. 2 empilhada por modalidade. |
| F03 | método | P0 | §4.6, 06/06b, Figs 5–6 | STM sem searchK, sem validação humana, corpus multilíngue, prevalência sem controle de composição; T7 mal rotulado; anotações erradas/truncadas. | searchK; corpus pt; estimateEffect por fonte/subárea; validação; refazer figuras com anotações a partir dos dados. |
| F04 | dado | P1 | `08`, `v_temp$total_programas_unicos` | 69 vs 67 (não aplica filtro de desativação). | `n_distinct` sobre `prog` filtrado. |
| F05 | escrita | P1 | §4.4 | 62 vs 64 programas; % somam 97,5. | Incluir OUTROS ou dizer "dos 64, 62 classificáveis em quatro subáreas". |
| F06 | dado | P1 | `03`, regex front matter | Exclui "Tendências..." (13) e "Preferências..." (3). | Ancorar padrões: `^pref[áa]cio`, `^tend[êe]ncias e debates`. |
| F07 | dado | P1 | `03`, BPSR 2007–08 | 25 duplicatas pt/en. | Dedup por (periódico, ano, título normalizado) ou DOI. |
| F08 | dado | P1 | OpenAlex DADOS | Lacuna 1989–1992; RBCP com registro de 2001. | Documentar; iniciar série de artigos em 1993 ou completar via SciELO; remover registro espúrio. |
| F09 | método | P1 | §4.1.1, `comp_metricas` | Crescimento relativo desde base 1987 (26 títulos). | CAGR por década; participação no total das seis áreas. |
| F10 | método | P1 | `18`, §4.1.3 | "32 programas de mestrado" = todos os programas; anos diferentes (2010 vs 2013); razões a 1 decimal. | Contar cursos de mestrado acadêmico; alinhar anos; 2 decimais; discutir estagnação 0,23→0,24. |
| F11 | método | P1 | `13`, `docentes_por_programa`, `conceito_medio` | Todas as categorias docentes; média de conceitos; "A" descartado. | Permanentes; distribuição de conceitos; reportar n de "A". |
| F12 | método | P1 | `10`, `tabela_mapeamento_programas_subareas.csv` | Classificação sem validação; regex com erros; segurança pública = defesa. | Corrigir regex; categoria própria; amostra validada 200 teses. |
| F13 | fato | P1 | §4.2 | Escala das associações "menor" contradita pelos próprios dados (ABCP 1.722 > ANPOCS 1.193). | Reescrever ou mover para suplementar. |
| F14 | escrita | P1 | §1, §5 | "texto comemorativo"; sem pergunta/hipóteses; três esquemas de organização. | Reestruturar (Plano Fase 3). |
| F15 | escrita | P1 | Apêndice | `sessionInfo()` no corpo; "6.1" numerado. | Mover para suplementar; `{.unnumbered}` na subseção. |
| F16 | literatura | P1 | todo | 10 referências; ausências centrais. | Fase 4 do Plano. |
| F17 | escrita | P1 | §3 item 1, §4.1, §4.1.1 | Números/rótulos hardcoded ("1 registro", "Figura 4", "Tabela abaixo"). | Inline `v_temp$n_discordantes_area39`; `@fig-ppgs-comparada`; remover "Tabela abaixo" ou criar `@tbl-comparacao`. |
| F18 | literatura | P1 | `.bib` | `author = {Leite, Fernando e Codato, Adriano}`; DOI suspeito. | `and`; verificar DOI/páginas. |
| F19 | dado | P2 | `01` | Dependência de CSV externo; sem teste de recall. | Incluir lista de URLs CKAN no repo; teste de recall em 3 safras. |
| F20 | dado | P2 | `08` união crosswalk | Pode incluir programas que mudaram de área. | Restringir crosswalk ao mesmo `an_base`. |
| F21 | escrita | P2 | Figs 1,2,3,5,7 títulos | "Ciência Política" quando é Área 39. | "Área 39 (CP e RI)" nos títulos; padronizar legendas/fontes. |
| F22 | escrita | P2 | Fig. 5 | Título de faceta T2 truncado; anotações repetidas. | Quebrar rótulos; `annotate` só no facet alvo via data frame. |
| F23 | escrita | P2 | Fig. 6 | Bin "1980-1999" com corpus desde 1995. | "1995–1999". |
| F24 | escrita | P2 | Fig. 20 | "Idade da Expansão" com dois marcos; sem UNICAMP/UFPE/IDESP/Lua Nova/OP/RSP. | Gerar a partir de `an_inicio_programa` + marcos com fonte. |
| F25 | dado | P2 | `comp_metricas` vs `v_temp` | 12.631 vs 12.661. | `anti_join`; documentar. |
| F26 | dado | P2 | AUDITORIA §9 / README | Números desatualizados (3.379%; Geografia = 43; "DADOS a partir de 1988"). | Atualizar após reexecução. |
| F27 | dado | P2 | `valores_inline_comparacao_areas.rds`, `SCRIPTS/11_correcao_artigo.R` | Órfãos. | Remover ou documentar. |
| F28 | método | P2 | `07` `rede_orientacao` | Construída, nunca usada. | Usar (endogamia/centralidade) ou remover. |
| F29 | fato | P2 | §2.1, §4.2 | Datas institucionais sem fonte (UFRGS 1973, UnB 1984, ABCP 1998, SBS 1950). | Citar fonte primária para cada; [verificar]. |
| F30 | escrita | P2 | Resumo | 4 parágrafos, >250 palavras, número excessivo de cifras. | ≤ 200 palavras, 1 parágrafo, 3–4 números. |
| F31 | método | P2 | §4.5 | Série de artigos lida como "consolidada"; pico 2015 é composição. | Normalizar por periódico ativo; figura de artigos/periódico-ano. |
| F32 | dado | P2 | `14` layout antigo | Antropologia sem 7040 (Arqueologia). | Incluir 7040. |
| F33 | escrita | P2 | citações | "Soares [@soares2005calcanhar]" → "Soares (Soares 2005)"; "Leite (2013) demonstram". | `@soares2005calcanhar` narrativo; "Leite e Codato (2013) demonstram". |
| F34 | fato | P2 | §3 item 3 | "excluídos ... resenhas" sem evidência. | Verificar amostra; ajustar frase. |
