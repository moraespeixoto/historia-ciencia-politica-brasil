# Correções planejadas — revisão de fechamento (minha leitura direta)

Fonte: leitura linha a linha de artigo_historia_cp_brasil.qmd (280 linhas) em 31/08/2026.
A mesclar com as 4 lentes (estrutura, prosa, método, figuras) quando chegarem.

## Sérias (afetam coerência/alegações)
1. **"três fontes primárias" mas 4 itens** (linha 107): o texto diz "três fontes primárias" e lista 4 (CAPES, Sucupira, OpenAlex, Comparação institucional). Corrigir para "quatro fontes" ou reestruturar (a comparação institucional é derivada das duas primeiras — pode virar subitem).
2. **Contradição métodos**: Discussão (linha 258) afirma "inflexão metodológica clara: a queda acentuada da Teoria Política..." e Conclusão (268) "sofisticação empírica" / "desenhos focados em...", mas a Introdução (73) e a própria Discussão advertem que mudança METODOLÓGICA não é medida (só temática). Corrigir: "inflexão temática", "sofisticação analítica/empírica" → qualificar como tema, não método.
3. **Subseção "Formação por nível e intensidade institucional"** (linha 217-225) aninhada sob "A Produção em Periódicos Canônicos" — trata de áreas irmãs, não de periódicos. Reparentar (mover para junto da comparação com áreas irmãs, ex.: subseção de "O Tamanho da Ciência Política...").
4. **Frase deslocada no STM** (linha 248): "A comparação administrativa acrescenta uma dimensão que o STM não captura: o crescimento da CP/RI ocorreu em uma estrutura menor..." — ponto de área-irmã, não de tópicos; repetitivo com a seção de áreas irmãs. Remover ou mover.
5. **K=8 sem justificativa** (linha 231): escolha de K não é defendida (sem coherence/exclusivity ou referência). Acrescentar 1 frase de justificação (exploratório; K=8 testado; verificação humana posterior).
6. **Frases-monstro com valores inline**: linhas 143, 155, 157 (comparação de programas/docentes/conceitos por área, com 6+ valores inline encadeados). Quebrar em frases/parágrafos com conectivos.

## Médias
7. **Travessões na prosa** (regra absoluta): linhas 67, 97, 256, 268 ("— ... —"). Substituir por vírgulas/parênteses.
8. **Números hardcoded** na seção de associações (169, 171, 173) e "27 títulos em 1987" (137), "34 em 2013" (143), "64 programas" (173): ou wire inline (v_temp; tabela consolidada) ou aceitar como descritivos com a tabela como fonte. Pelo menos 64 e 34/27 via inline.
9. **"não permitem atribuí-la isoladamente"** ✓ ok (mantém).
10. **Line 143**: "expansão de programas de simples crescimento" (219) — gramática ambígua; reescrever.
11. **"enumerou as fragilidades"** (101) — Marenco: suavizar para "apontou as fragilidades" (verificado: abstract não enumera explicitamente).
12. **Soares (2005) e Marenco (2014)** na prosa da Discussão (258) sem @cite — padronizar com citações do .bib.
13. **Resumo** (55): parágrafo único longo com muitos parênteses; quebrar em frases curtas liderando pelo achado.
14. **"texto comemorativo"** repetido (69 e 254).
15. **comp_prog carregado mas não usado** no setup (47) — remover ou usar.
16. **"na última década"** (149) vago — precisar (2013-2024).
17. **FREX transliterado sem acento** na tabela de tópicos — nota de rodapé no caption ("termos transliterados do corpus").

## Menores
18. "escala e ritmo substancialmente menores" (147) — concordância.
19. "compromisso imperativo" (268) — adjetivo vazio.
20. "pujança bibliométrica" (260) — coloquialismo; reescrever.
21. Captions de figuras descritivos → mini-abstract (o que compara, unidade, período, leitura) — ver lente de figuras.
22. "hiper-especializada" (256) — hífen ok; verificar estilo.

## Build (já verificado)
- 0 refs quebradas; 0 citações órfãs; sem vazamento inline; 14 figuras referenciadas existem; tabelas renderizam.

## Correções aplicadas (31/08/2026) — consolidado das 4 lentes + revisão própria

### Estrutura/roteiro (lente 1)
- Resumo reescrito: frases curtas, 4 fontes declaradas, achados de escala incluídos, "Área 39 (Ciência Política e Relações Internacionais)" glosada, pico qualificado ("último ano da série").
- Introdução: Movimento 1 (tensão: expansão mascara campos limítrofes), Movimento 3 (três achados com magnitude), Movimento 4 (frase de contribuição); ponte "três eixos → sete dimensões".
- Subseção "Formação por nível e intensidade" movida de Periódicos para a comparação com áreas irmãs; fig15/16 movidas ao Apêndice ("Figuras Complementares").
- "A Expansão e Descentralização da Pós-Graduação" → "A Expansão da Pós-Graduação".
- Discussão reescrita como implicações (escala, temática, composição); Conclusão enxugada (síntese, sem números novos).

### Prosa (lente 2)
- 4 pares de travessões eliminados (intro, referencial, discussão, conclusão); 2 travessões de títulos do .bib limpos.
- "separar essas águas" → "separar esses fluxos"; "vertiginoso"→"muito maior"; tríades/adjetivos vazios cortados ("robusto"→"claro", "imperativo", "triunfalista", "drasticamente").
- Enumerações-cadeia (programas/docentes por área) quebradas em frases com a área-foco em destaque + remissão à figura.
- Glosas de estreia: STM, front matter, linkage, FREX; padronização "Área 39".
- "6 mil a 8 mil" → "6.000 a 8.000"; "alavanca"→"instrumento"; "E as séries..."→"As séries também..."; "expansão de programas de simples crescimento"→"distinguir a expansão dos programas do simples crescimento".

### Método (lente 3)
- Taxa de aprovação ANPOCS corrigida: 20%–44% → 16%–44% (verificado 15,7%–44,4%); "único indicador diretamente comparável" → "o menos incomparável".
- "Menor escala do conjunto" re-qualificada (menor que SBS/ABA/ANPUH; patamar semelhante a ANPOCS/ANPEGE).
- ANPOCS "estabilizou-se entre 1.200 e 1.400" → "oscilou entre cerca de 1.200 e 1.500" (2010 = 1.487).
- Comparação seletiva corrigida (História incluída: 16,7 docentes/programa).
- Estimando declarado: "títulos registrados no catálogo" (não defendidos), com nota de data de defesa ausente em ~76% do layout 2013+; queda 2019–2020 comentada; pico qualificado.
- STM: ausência de inferência formal declarada; K=8 sem validação declarado; plano de validação (leitura humana, estabilidade, K alternativos) explicitado; frase deslocada (comparação administrativa) removida; parágrafo dividido.
- "Seis periódicos canônicos" → "seis revistas selecionadas" com critério declarado.
- Protocolo exploratório: relatório EDA agora captura a auditoria real (153 linhas); achados-chave citados no artigo (269 sem grau, 76% sem data, 0 duplicatas OpenAlex, 456 sem DOI).
- Células da tabela de associações marcadas: ABA "†derivada", ANPUH "2013 previsto"; ANPOCS tabela usa 2024.
- Nota IUPERJ/UCAM adicionada.

### Figuras (lente 4)
- Formato numérico PT-BR (num_ptbr/pct_ptbr) em fig01–05, fig08, fig11, fig18.
- fig06: título honesto ("Prevalência Média dos Tópicos por Década"), paleta sequencial clara, texto escuro legível.
- fig08: paleta qualitativa Okabe-Ito (regiões são categorias).
- fig11: linha da CP/RI destacada (técnica de highlighting), irmãs em cinza.
- fig05: anotação da queda da teoria política (36%→13%) que o free_y escondia; título/subtítulo encurtados (sem overflow).
- fig18: legenda de séries adicionada (era legend.position="none" com 2 séries por painel).
- fig18c (participantes recentes) adicionada ao artigo; seleção restrita a dados realizados (≤2024).
- fig15/16 movidas ao apêndice.

### Build
- 19 páginas; 0 refs quebradas; 0 travessões em prosa; 0 primeira pessoa; sem vazamento inline; 14 figuras referenciadas existem.
