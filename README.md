# Sessenta Anos Depois: Teses, Programas e Agendas da Ciência Política no Brasil

Pacote de replicação e estrutura do artigo em R + Quarto.

## 📁 Estrutura do Repositório

```
trajetoria_CP_Brasil/
├── trajetoria_CP_Brasil.Rproj               # R Project
├── artigo_historia_cp_brasil.qmd           # Manuscrito principal em Quarto
├── referencias.bib                         # Base bibliográfica (.bib) com DOIs verificados
├── AUDITORIA.md                            # Relatório de auditoria de dados e referências
├── README.md                               # Guia de replicação e proveniência
├── .gitignore                              # Regras de versionamento (exclui bases pesadas)
├── DADOS/
│   ├── raw/                                # Dados brutos baixados via scripts
│   └── processed/                          # Bases harmonizadas e tratadas
├── SCRIPTS/
│   ├── 00_setup.R                          # Pacotes, semente e tema visual (theme_artigo)
│   ├── 01_coleta_capes_teses.R             # Ingestão de Teses e Dissertações da CAPES
│   ├── 02_coleta_sucupira_ppgs.R           # Ingestão de dados Sucupira / PPGs
│   ├── 03_coleta_openalex_artigos.R        # Coleta de metadados de periódicos via OpenAlex
│   ├── 04_protocolo_exploratorio.R         # Protocolo de auditoria exploratória (EDA)
│   ├── 05_analise_temporal.R               # Figuras 1–4 (séries de títulos, PPGs e artigos)
│   ├── 06_analise_tematica_stm.R           # Modelagem de tópicos (STM), Figuras 5–6
│   ├── 06b_rotulos_stm.R                   # Regenera rótulos/figuras STM sem re-estimar
│   ├── 07_analise_geografica_redes.R       # Geografia dos PPGs e redes de orientação
│   ├── 08_auditoria_series_temporais.R     # Séries unificadas e valores inline
│   ├── 09_auditoria_integridade.R          # Auditoria de integridade das bases processadas
│   ├── 10_classificacao_subareas.R         # Separação da área 39 em CP/RI/PP/DEFESA
│   ├── 12_coleta_capes_comparada.R         # Coleta das safras CAPES das áreas comparadas
│   ├── 13_comparacao_sucupira.R            # Comparação Sucupira: programas/docentes/conceitos
│   ├── 14_consolida_comparacao_teses.R     # Consolida a comparação de títulos entre áreas
│   ├── 15_associacoes_cientificas.R        # Associações científicas: dados e figuras
│   ├── 16_auditoria_pos_graduacao.R        # Segunda auditoria: microdados de pós-graduação
│   ├── 17_figuras_slides.R                 # Figuras redesenhadas para a apresentação
│   ├── 18_comparacao_marenco.R             # Validação externa: comparação com Marenco (2014)
│   ├── 19_linha_tempo_tres_idades.R        # Figura das Três Idades (versão paper)
│   ├── tema_artigo.R                       # Estilo visual ggplot2 padronizado (paper)
│   └── tema_slides.R                       # Estilo visual ggplot2 padronizado (slides)
├── PESQUISA_ASSOCIACOES/                   # Relatórios-fontes da coleta de associações
├── FIGURAS/                                # Gráficos exportados em alta resolução
│   └── slides/                             # Figuras redesenhadas para a apresentação
└── TABELAS/                                # Tabelas de modelos e descritivas
```

Artefato canônico da área 39: `DADOS/processed/capes_cp_area39.rds` (gerado pelo script 08,
já filtrado). Os scripts 06, 07 e 10 leem esse arquivo em vez de reimplementar o filtro.

## 📦 Dados brutos (não incluídos no repositório)

`DADOS/raw/` não é versionado (fontes públicas, ~1,4 GB). `DADOS/processed/` **é**
versionado (~35 MB) — as bases que o artigo e a apresentação de fato leem já
estão no repositório, então figuras/tabelas/números são reprodutíveis sem
rebaixar nada. Para reobter os brutos e refazer o pipeline desde a coleta:

- **CAPES — Catálogo de Teses e Dissertações**: [dadosabertos.capes.gov.br](https://dadosabertos.capes.gov.br/) (safras 1987–2024, dois layouts históricos — ver `SCRIPTS/01_coleta_capes_teses.R` e `SCRIPTS/12_coleta_capes_comparada.R`).
- **Plataforma Sucupira — Cursos e Docentes**: [dadosabertos.capes.gov.br](https://dadosabertos.capes.gov.br/) (`SCRIPTS/02_coleta_sucupira_ppgs.R`).
- **OpenAlex** (metadados de artigos por periódico, via API): `SCRIPTS/03_coleta_openalex_artigos.R`.
- **Associações científicas**: relatórios-fonte já reunidos em `PESQUISA_ASSOCIACOES/` (`SCRIPTS/15_associacoes_cientificas.R`).

## 🚀 Como Reproduzir

1. Abra o projeto no RStudio através do arquivo `trajetoria_CP_Brasil.Rproj` ou no terminal via R.
2. Execute o setup inicial:
   ```r
   source("SCRIPTS/00_setup.R")
   ```
3. Execute a coleta e processamento das fontes de dados em `SCRIPTS/`, na ordem numérica:
   `01` (CAPES), `02` (Sucupira), `03` (OpenAlex), `08` (séries), `10` (subáreas),
   `07` (geografia), `06` (STM, mais demorado), `05` (figuras temporais).
4. Audite a integridade das bases:
   ```r
   source("SCRIPTS/09_auditoria_integridade.R")
   ```
5. Renderize o artigo para HTML e PDF via Quarto:
   ```bash
   quarto render artigo_historia_cp_brasil.qmd
   ```

## 📊 Comparação com áreas irmãs

O módulo comparativo usa os dados CAPES/Sucupira das áreas de avaliação 38 (Economia), 39 (Ciência Política e Relações Internacionais), 40 (Sociologia), 41 (Antropologia e Arqueologia), 42 (História) e 43 (Geografia).

- `SCRIPTS/12_coleta_capes_comparada.R`: baixa as safras do Catálogo CAPES para as áreas comparadas e preserva os arquivos brutos em `DADOS/raw/capes_teses_comparada/`.
- `SCRIPTS/14_consolida_comparacao_teses.R`: harmoniza os layouts, classifica por código/área e produz séries por nível, métricas acumuladas, auditoria e painel integrado.
- `SCRIPTS/13_comparacao_sucupira.R`: calcula programas, IES, UFs, docentes, conceitos, concentração institucional, geografia e indicadores normalizados na janela 2013–2024.
- Tabelas principais: `tabela_comparacao_titulos_capes.csv`, `tabela_comparacao_metricas_capes.csv`, `tabela_comparacao_programas_sucupira.csv`, `tabela_comparacao_painel_integrado.csv` e tabelas de geografia/conceitos/concentração.
- Figuras adicionais: `fig10`–`fig16` em `FIGURAS/`.

A comparação é descritiva. Áreas de avaliação não são disciplinas perfeitamente equivalentes; os conceitos CAPES têm critérios próprios, e a ausência de informação de sexo/gênero nos microdados docentes impede inferências dessa natureza.

## 📌 Notas de proveniência (atualizadas na auditoria de 2026-08-29)

- A base CAPES combina dois layouts históricos (1987–2012 e 2013–2024). A
  identificação da área 39 usa código de área de conhecimento (layout antigo) e
  código de programa cruzado com o Sucupira (layout novo); cerca de 73 registros
  capturados por palavras-chave fora da área foram excluídos.
- A coleta OpenAlex deduplica pela chave única da obra (`id_openalex`) e mantém
  apenas artigos de pesquisa (`type == "article"`), sem front matter. A cobertura
  do OpenAlex é desigual entre periódicos (a *DADOS* aparece a partir de 1988).
- Os rótulos dos tópicos STM foram revisados na auditoria para corresponder aos
  termos FREX; tópicos em inglês/espanhol são artefatos de idioma.
- As referências foram verificadas contra Crossref/doi.org; DOIs inválidos foram
  substituídos (Leite & Codato 2013; Marenco 2014; Amorim Neto & Santos 2003;
  Biroli & Candido 2021; Candido 2023).
