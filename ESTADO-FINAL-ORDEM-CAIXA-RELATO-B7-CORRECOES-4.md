# ESTADO-FINAL — Ordem CAIXA-RELATO-B7-CORRECOES-4

As correcções B1–B5 da sentença da conferência da CAIXA-RELATO-B7-CORRECOES-3. Mudaram só o teste do registo, o script
novo de mutações, o lançador das provas, o README e as corridas em `provas/ordem-caixa-relato/`. **Nada do código do
jogo mudou** (`git diff c847966 -- rascunhos/` vazio).

- **Executor:** conta 1, no PC.
- **Base:** `c847966`, a ponta de `fable/integracao-50` à hora do lançamento. Na hora do push ainda era a ponta.
- **Ramo:** `claude1/caixa-relato-b7-correcoes-4`, **sem fusão**.
- **Commits:**
  - `a110820`: as correcções, o script de mutações, o README e as corridas;
  - o commit deste ESTADO-FINAL, que só junta este ficheiro.
- **A conferência:** não está neste PC (`~/workspace/conferencias/` não existe). Trabalhei pelo texto da ordem.

**Versões que as mutações correm.** O «teste novo» é o desta ordem. O «teste antigo» é o de `c847966`, igual ao da
B7-CORRECOES-3 (`9a980a0`): o ficheiro não mudou entre os dois. O teste «r1» é o de `a12b905`, de antes da
B7-CORRECOES-3, e só corre o controlo e a reprodução do R1.

## 1. Ponto a ponto

### B1 (D1) — a forma dos valores

**Feito**, em `provas/ordem-caixa-relato/ferramentas/teste_relato_caixa.gd`.

- **O limite está registado ao lado de `CHAVES_PERMITIDAS`.** Uma chave estar na lista não diz nada do valor. Até aqui,
  um valor feito só de palavras permitidas, ou um número, debaixo de uma chave permitida, passava e ecoava.
- **Fecha-se com `_forma_fora`**, que entra em `_achados_em`, e por isso nas duas verificações de privacidade, sem
  `_ok` novo. Cada objecto JSON de topo da linha lê-se com `JSON.parse_string` e percorre-se:
  - em cima, só `ligada` (booleano), `ordemPor` (só `"dinamico"`) e `ordemDinamica` (objecto);
  - dentro da `ordemDinamica`, só `ordem` (lista de ids de 17 hex), `fechada` (booleano) e `ultimo` (id de 17 hex);
  - também contam: uma chave permitida no nível errado, um objecto que não se lê, e uma chave «"k":» que não esteja
    dentro de nenhum objecto lido.
- **Só se imprime a contagem**, por exemplo `RETIDA (não se imprime; tem ["valor(es) fora da forma: 2"])`. O valor
  nunca sai.
- **A forma é a das linhas deste teste** (ids de 17 hex, modo dinâmico), e fica escrito. Uma linha real com
  `"ultimo": null` ou `"ordemPor": "iniciativa"` ficaria retida. Alargar a forma é uma mudança que a conferência vê.
- **O total continua 31.**

As mutações, todas na caixa do snapshot do caso do `limpar()` (linhas B7-1 e B7-4):

| Mutação | Teste antigo (`c847966`) | Teste novo |
|---|---|---|
| `"ultimo": "turno"` | 31/31, código 0, **2 ecos** | **30/31, código 1, 0 ecos** |
| `"ultimo": 42` | 31/31, código 0, **2 ecos** | **30/31, código 1, 0 ecos** |
| `"ligada": "turno"` | 31/31, código 0, **3 ecos** | **30/31, código 1, 0 ecos** |
| `"fechada": 0` | 31/31, código 0, **2 ecos** | **30/31, código 1, 0 ecos** |
| `"ordemPor": "turno"` | 31/31, código 0, **3 ecos** | **30/31, código 1, 0 ecos** |
| `"ordem": [a, "dinamico"]` | 31/31, código 0, **8 ecos** | **30/31, código 1, 0 ecos** |

Os registos estão em `b7-correcoes-4/mutacoes/b1-*.log`. Na mutação `"fechada": 0`, o `relato_caixa.gd` (que não
mudou) escreve `SCRIPT ERROR: Invalid operands 'int' and 'bool'` ao comparar `0 == true`, e o teste continua. Isto
acontece nos dois testes e é efeito da mutação.

**A reprodução do R1, executada antes e depois:**

| | Teste de `a12b905` | Ponta `c847966` (antes desta ordem) | Teste novo |
|---|---|---|---|
| `"alcunha": "Canario-R1"` | **31/31**, código 0, **2 ecos** | 30/31, código 1, 0 ecos | 30/31, código 1, 0 ecos |

- **Antes:** corri o script da B7-CORRECOES-3, sobre a árvore sem mudanças, com as bases `c847966` e `a12b905`
  (`b7-correcoes-4/antes/mutacoes-script-b7c3-base-*.log`).
- **Depois:** o script novo (`mutacoes/r1-alcunha-teste-{r1,antigo,novo}.log`).

### B2 (D2) — o limite dos 17 hex

**Registado ao lado de `RE_ID`.** A regra é a forma de um id, não a lista dos ids do teste. Qualquer 17-hex passa por
id, como palavra solta e como valor de `ordem`/`ultimo`. Não o fechei, como pedia a ordem. A mutação
`"ultimo": "0123456789abcdef0"` dá **31/31, código 0, 2 ecos nos dois testes**: o limite continua lá, executado
(`mutacoes/b2-ultimo-17hex-*.log`).

### B3 (D3) — o PIN não volta a ser cometido

**Feito, com uma mudança no lançador.** O `ferramentas/correr-prova-caixa-relato.sh` deixou de copiar
`servidor-info.json` e `servidor.log` para a pasta de saída. Ficam na pasta tmp da sede.

- `b7-correcoes-4/cliente-hud/` e `b7-correcoes-4/cliente-manequim/` têm só o `relato.txt`.
- Conferi: os PINs das duas corridas desta ordem (8 dígitos cada) aparecem em **0** ficheiros de `b7-correcoes-4/`
  e de `ferramentas/`, e a chave `"pin"` também em **0**.
- Os ficheiros das ordens anteriores (até `correcoes-5/`) ficam como estavam: são pré-existentes, de um servidor
  efémero.

### B4 (D4) — o script de mutações

**Novo:** `ferramentas/correr-mutacoes-b7-correcoes-4.sh`. O da B7-CORRECOES-3 fica como estava, porque é o registo
dessa ordem.

- **Uma cópia por corrida.** Cada corrida trabalha numa pasta sua, `mktemp -d`, com a cópia mutada do teste e o
  `relato_caixa.gd` da mesma versão ao lado. A pasta apaga-se no fim (`trap`), e nada se escreve em `ferramentas/`.
  - **Executado:** duas corridas ao mesmo tempo (`…pQlmqy` e `…cb68UI`) acabaram as duas com código 0 e 0
    discrepâncias.
  - Os logs das duas diferem só no caminho temporário e nas horas.
- **O código de saída é fiel.** Cada mutação tem o resultado esperado: o código do Godot, se o canário ecoa ou não e,
  nas sondas de acentos, se a `PROIBIDAS` o nomeia. Cada linha do `mutacoes.log` diz `BATE` ou `NAO-BATE`.
  - O script sai com **0** só se todas baterem e com **1** se alguma não bater.
  - Sai com 2–9 se a própria corrida falhar: argumentos, git, node, ou uma âncora que não é única.
  - **Executado:** na primeira corrida, o canário de `b1-ordem-palavra` (`"turno"]`) aparecia também nos tipos dos
    eventos, que os nomes das verificações imprimem. O script marcou `NAO-BATE` e saiu com **1**
    (`b7-correcoes-4/antes/b4-codigo-de-saida-1.log`).
  - Troquei esse canário por `"dinamico"]`, que não aparece em mais nenhum sítio, e a corrida final saiu com **0**.
- **Não tem `cut`.**

### B5 (D5) — os acentos

**Fiz as duas coisas: completei o mapa e documentei a lista permitida como rede de segurança.**

- **O `_SEM_ACENTO` ganhou o resto do latim-1** (`ø æ œ ß ð þ`) **e o latim alargado A** (U+0100–U+017F, com o s
  longo `ſ` → `s`).
- **As marcas combinantes caem em 5 blocos:** U+0300–036F, 1AB0–1AFF, 1DC0–1DFF, 20D0–20FF e FE20–FE2F.
- **Não é uma normalização Unicode completa**, e fica escrito no teste. O GDScript não tem NFKD. Letras de outros
  blocos (o «о» cirílico, as de largura dupla, o «ȷ» U+0237) não se traduzem.
- **Um buraco pequeno, achado e fechado.** O separador de palavras era `[^a-z0-9_]+`, e qualquer carácter não-ASCII
  que `_normal` não traduzisse servia de separador: «1ȷe» dava «1» e «e», as duas permitidas, e a linha ecoava.
  - Agora separam só o ASCII que não é letra nem dígito, e o «—» e o «·» das palavras fixas.
  - Um carácter não-ASCII que sobre fica dentro da palavra, e essa palavra retém a linha.

| Sonda | Teste antigo | Teste novo |
|---|---|---|
| chave `"maſter"` (U+017F) | 30/31, 0 ecos, retida **só pelas listas** (a `PROIBIDAS` não a nomeia) | 30/31, 0 ecos, a `PROIBIDAS` **nomeia `master`** |
| chave `"pro⃐pria"` (U+20D0) | 30/31, 0 ecos, retida **só pelas listas** | 30/31, 0 ecos, a `PROIBIDAS` **nomeia `propria`** |
| rótulo `1ȷe` (U+0237) | **31/31, código 0, 1 eco** | **30/31, código 1, 0 ecos**; a linha sai como `n.º 1` |
| `"própria"` pré-composta / com U+0301 (regressão) | 30/31, 0 ecos, nomeia `propria` | 30/31, 0 ecos, nomeia `propria` |

As duas primeiras linhas confirmam o que diz a sentença: no teste antigo, a lista permitida já retinha as duas sondas
(«provado inofensivo»). Agora, além disso, a `PROIBIDAS` nomeia-as.

## 2. Corridas

Neste PC, sobre a árvore de `a110820`, com o Godot 4.7.2 (`Godot_v4.7.2-stable_win64_console.exe`), o motor VLAB real
sha256 `a91c021c…3261` e a semente 7. Os registos estão em `provas/ordem-caixa-relato/b7-correcoes-4/`.

| Corrida | Resultado | Registo |
|---|---|---|
| Teste do relato (`teste_relato_caixa.gd`), antes das mudanças | **31/31**, código 0 | `antes/teste-relato-ponta-c847966.log` |
| Teste do relato, depois | **31/31**, código 0 | `teste-relato.log` |
| Prova viva HUD-JOGADORA (`prova_caixa_jogadora.gd`) | **43/43**, código 0, 68 linhas | `cliente-hud/relato.txt` |
| Prova viva MANEQUIM (`prova_caixa_manequim.gd`) | **53/53**, código 0, 78 linhas | `cliente-manequim/relato.txt` |
| Mutações (34 corridas: 16 novo + 16 antigo + 2 r1) | **34/34 batem**, script com código 0 | `mutacoes/mutacoes.log` |

- **Os números das provas vivas são iguais aos de `correcoes-5/`:** 43/43 em 68 linhas e 53/53 em 78. Nada nas provas
  vivas mudou nesta ordem.
- **Com o `conferir-registo.mjs`:**
  - o `mutacoes.log` dá **0 achados**;
  - o `teste-relato.log` dá 2 achados (pedaços de 4 letras) na linha 38. É falso positivo antigo: os registos
    cometidos `b7-correcoes-3/teste-relato.log` e `correcoes-5/teste-relato.log` dão os mesmos 2, na mesma linha;
  - nos relatos vivos dá 48 e 46 achados, iguais aos de `correcoes-5/`. São os nomes públicos curtos, como diz o
    README.
- **As regressões da B7-CORRECOES-3 continuam iguais:**
  - B5, sem uma verificação: 30 de 30 e código 1, nos dois testes;
  - B4, o passo 3 igual ao 2: 31/31 nos dois testes. É um limite inerente.
- **`actualizar-listas`:** corri-o depois do commit `a110820`. Deu `antes.txt` 37, `depois.txt` 415, MANIFESTO 459,
  **0 novos e 0 tirados**, e nenhum ficheiro mudou. Nada em `rascunhos/` mudou, por isso não há listas a cometer.
- **O lançador das provas** recebeu a pasta de saída em caminho absoluto. As capturas, o info e o log do servidor
  ficaram na pasta tmp da sede, e nada caiu em `rascunhos/`.

## 3. CI

**Verde em `a110820`:**

- **Testes dos rascunhos** (run 45011009664): **10/10 jobs**. São eles protocolo, validador-glb, cliente, motor-real,
  provas-mapa, godot-cliente, ponta-a-ponta, **retoma-pc**, foto-mestre e servidor.
- **Sonda de privacidade** (run 45011009569): success.
- **No registo do CI:**
  - teste do relato: `teste do relato da caixa: 31 de 31 verificações passaram.`, sem `FALHA o total`;
  - protocolo: 420 testes, 420 passaram;
  - prova da caixa do servidor: `PROVA OK`;
  - retoma-pc: `FEITO: 415 ficheiros no PC iguais ao ramo (SHA conferido).`

O CI do commit deste ESTADO-FINAL, que só junta este ficheiro, corre a seguir ao push.

## 4. Pontos para o coordenador

1. **B1 está fechado pela forma, mas a forma é a deste teste.** `ultimo` null (o servidor manda null antes da
   primeira vez) e `ordemPor` `"iniciativa"` são valores reais que hoje ficariam retidos. Se um dia o teste gerar
   linhas assim, a forma alarga-se em `_andar_forma`, à vista da conferência.
2. **B2 continua só registado.** Para o fechar, teria de se trocar a forma de um id pela lista dos ids que o teste
   monta. Não o fiz, porque a ordem pede só o registo.
3. **B5 trouxe uma correcção a mais, que a sentença não pedia:** o resíduo não-ASCII deixou de servir de separador.
   Achei-a ao documentar a rede de segurança e provei-a com a sonda `1ȷe`. A sonda está no rótulo, que é do próprio
   teste, por isso o alcance real era baixo.
4. **B3:** mudei o lançador (`correr-prova-caixa-relato.sh`) para o info e o log do servidor não voltarem a cair na
   pasta que se comete. Os ficheiros das ordens anteriores com o PIN ficam no ramo. Apagá-los é decisão tua.
5. **Os logs de mutação levam o caminho da pasta temporária** (`C:/Users/txcga/AppData/Local/Temp/…`) nos rastos de
   erro do Godot. Isto acontece só nos 2 logs da `b1-fechada-numero`. O ramo já tem 36 ficheiros em `provas/` com
   caminhos `C:/Users/txcga`.
6. **Os valores nos logs são canários de bancada, fictícios:** `Canario-R1`, `turno`, `42`, `0123456789abcdef0`, `1ȷe`
   e as chaves `alcunha`, `própria` e `maſter`. Aparecem só onde o resultado esperado é o eco, ou seja, no teste
   antigo e no limite B2. No teste novo, os de B1, B5 e R1 aparecem 0 vezes.
7. **A fronteira:** só mudaram `provas/ordem-caixa-relato/` e este ESTADO-FINAL. Não mexi em `rascunhos/`, no HUD, nas
   cores nem no workflow.
8. **Não mexi no `ORDEM.md` da sede**, como nas ordens anteriores. A marca de estado é tua.
