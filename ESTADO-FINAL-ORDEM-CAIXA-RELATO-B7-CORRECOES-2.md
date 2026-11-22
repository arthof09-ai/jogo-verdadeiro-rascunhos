# ESTADO-FINAL — Ordem CAIXA-RELATO-B7-CORRECOES-2

As correcções B1–B4 da sentença da conferência da CAIXA-RELATO-B7-CORRECOES. Só o teste do registo e registo:
**nada do código do jogo mudou** (`git diff f747427 -- rascunhos/` vazio).

- **Executor:** conta 2, no PC do cunhado.
- **Base:** `f747427`, a ponta de `fable/integracao-50` à hora do lançamento. Voltei a conferir antes do commit
  (`git fetch`, 05:02 UTC) e depois do CI: a ponta continuava `f747427`.
- **Ramo:** `claude2/caixa-relato-b7-correcoes-2`, **sem fusão**.
- **Commits:**
  - `65a96d2`: as correcções, o teste, o README e as corridas;
  - o commit deste ESTADO-FINAL, que só acrescenta este ficheiro.
- **A conferência:** não está neste PC (`~/workspace/conferencias/caixa-relato-b7-correcoes/` não existe). Trabalhei
  pelo texto da ordem.

## 1. Ponto a ponto

### B1 — `"propria"` na lista `PROIBIDAS`

**Acrescentada** (`provas/ordem-caixa-relato/ferramentas/teste_relato_caixa.gd`, `PROIBIDAS`).

- **A investigação: nenhuma linha legítima traz `propria`.** A varredura lê só as linhas de `relato_caixa.linha()`.
  Essas linhas são feitas de:
  - as palavras fixas de `linha()` e `_origem()` (`relato_caixa.gd:105-117`);
  - os rótulos do teste (`1`, `x`, `e`, `4`, `B7-1`…`B7-4`) e os tipos de evento (`movimento`, `turno`, `ataque`,
    `dano`, `estado`);
  - os campos da caixa (`ligada`, `ordemPor`, `ordemDinamica`, `ordem`, `fechada`, `ultimo`) e ids hexadecimais.

  Nenhum destes tem `propria`. O teste com a palavra na lista dá **30/30**.
- **O único «própria» nos relatos cometidos** está nas provas vivas: «1: a própria jogadora está na ordem». Não é uma
  linha de `linha()`, por isso a lista do teste não a lê. Além disso, com o acento não contém `propria`.
- **A prova de que a palavra é apanhada.** Mutação: `"propria": {"figuraId": a}` na caixa do snapshot do caso do
  `limpar()`.
  - Teste novo: **29/30**. A varredura acusa `["propria", "propria"]`, nas linhas B7-1 e B7-4
    (`b7-correcoes-2/mutacao-1-propria.log`).
  - Teste antigo com a mesma mutação: **30/30**; a fuga passava (`mutacao-1-propria-teste-antigo.log`).
- O comentário do caso (`:209`) diz agora que «não traz `propria`» se confere nas linhas, não só na montagem.

### B2 — nenhuma linha ecoada antes da varredura

**Corrigido no caso do `limpar()` e também no §B6.**

- **Função nova `_ecoar(linhas)`, chamada só depois de cada varredura.**
  - Uma linha limpa imprime-se inteira.
  - Uma linha com palavras proibidas **não se imprime**. Sai só `linha <rótulo>: RETIDA (não se imprime; tem [...])`;
    o rótulo é o texto antes do primeiro «:», e é do teste.
- **O §B6 tinha o mesmo defeito.** Três ecos (§1/§5, o `encerrar` e o §4) saíam antes da varredura do §B6. Passaram
  para depois dela, pelo mesmo `_ecoar`; agora ecoam-se as 6 linhas varridas. A ordem só nomeia o caso do `limpar()`;
  estendi a correcção porque o defeito é o mesmo e está no mesmo ficheiro.
- **A prova.** Mutação: `"nome": "Canario-Bancada"` na caixa do snapshot do caso (o valor-canário de bancada da
  B7-CORRECOES).
  - Teste novo: **29/30**, e o valor aparece **0 vezes** no log. As linhas B7-1 e B7-4 saem RETIDAS
    (`b7-correcoes-2/mutacao-2-canario-eco.log`).
  - Teste antigo: **29/30**, e o valor aparece **2 vezes**, nas linhas 35 e 38 do log, antes da FALHA na linha 40
    (`mutacao-2-canario-eco-teste-antigo.log`). É o defeito da sentença, reproduzido.

### B3 — o cabeçalho do ESTADO-FINAL da B7-CORRECOES

**Corrigido** (`ESTADO-FINAL-ORDEM-CAIXA-RELATO-B7-CORRECOES.md`, linha «Base»): risquei a frase e escrevi o que
aconteceu.

- **A linha andou `15eab43` → `f049089` dentro da janela da ordem.** Os três commits da CAIXA-TESTES-CORRECOES-3
  entraram em `fable/integracao-50` às **00:45:29–00:45:30** (−03:00; data de commit 03:45:29–30 UTC): `8870275`,
  `ae62dd9` e `f049089`.
- **A janela da ordem:** o commit das correcções é das 00:44:25 e o do ESTADO-FINAL é das 00:48:00.
- **O ramo foi reposto na integração:** `5ac2253` → `d7ea743` e `b4b51c2` → `f747427`. `git range-diff` dá os dois
  patches iguais (`=`), conferido contra o repo da sede anterior.
- **Os números daquele ESTADO-FINAL são os da `15eab43` + `5ac2253`.** Ficou escrito assim.

### B4 — a B7-1 presa na verificação de cobertura

**Presa** (mesma verificação, sem `_ok` novo; o teste continua **30/30**).

- **Cada uma das 4 linhas tem de começar pelo seu rótulo** (`B7-1:`…`B7-4:`) **e trazer a sua origem:**
  `seq 1,`, `seq 0,`, `seq 0,` e `seq 5,`. A vírgula impede que `seq 1` case com `seq 10`.
- **A B7-2 e a B7-3 são idênticas tirando o rótulo**, porque o evento à espera não muda nada. Não lhes inventei uma
  âncora: o rótulo distingue-as, e a verificação confere as duas coisas (rótulos diferentes, corpo igual). A limitação
  fica escrita: o corpo não distingue a B7-2 da B7-3, e a ordem das duas lê-se só pelo rótulo.
- **A prova.** Mutação: a linha «antes do `limpar()`» não é gerada e a última repete-se. Ficam 4 linhas, a [1] com
  `seq 0` e a [3] com `seq 5`.
  - Teste novo: **29/30** (`b7-correcoes-2/mutacao-3-sem-B7-1.log`).
  - Teste antigo: **30/30**; a verificação de cobertura não dava pela falta da B7-1
    (`mutacao-3-sem-B7-1-teste-antigo.log`).

## 2. Corridas

Neste PC, sobre `65a96d2` (a `f747427` + o teste alterado), com o Godot 4.7.2 (`Godot_v4.7.2-stable_win64_console.exe`),
o Node 26.13.0 e o motor VLAB real sha256 `a91c021c…3261`, semente 7. Os registos estão em
`provas/ordem-caixa-relato/b7-correcoes-2/`.

| Corrida | Resultado | Registo |
|---|---|---|
| Teste do relato (`teste_relato_caixa.gd`) | **30/30** | `teste-relato.log` |
| Prova viva HUD-JOGADORA (`prova_caixa_jogadora.gd`) | **43/43** | `cliente-hud/relato.txt` |
| Prova viva MANEQUIM (`prova_caixa_manequim.gd`) | **53/53** | `cliente-manequim/relato.txt` |
| Suite do servidor (`node --test`, 418 testes) | **418/418**, 0 falhas, 0 saltados | `suites/servidor.log` |
| Prova da caixa do servidor (`prova-servidor.mjs`) | **PROVA OK** | `suites/prova-servidor.log` |
| Mutação 1 «`propria` no caso»: teste novo / antigo | **29/30** / 30/30 | `mutacao-1-propria*.log` |
| Mutação 2 «nome-canário»: teste novo / antigo | **29/30, 0 ecos** / 29/30, 2 ecos | `mutacao-2-canario-eco*.log` |
| Mutação 3 «sem a B7-1»: teste novo / antigo | **29/30** / 30/30 | `mutacao-3-sem-B7-1*.log` |

- **As provas vivas** acabam com a varredura do relato inteiro sem nomes verdadeiros (65 e 75 linhas).
- **O lançador** recebeu a pasta de saída em caminho **absoluto**, como o README pede; nada caiu em `rascunhos/`.
  As capturas ficaram na pasta tmp da sede.
- **As mutações** foram feitas com cópias do teste em `ferramentas/` (o teste carrega o `relato_caixa.gd` da própria
  pasta). As cópias foram apagadas antes do commit; o `git status` estava limpo fora de `b7-correcoes-2/`.
- **`actualizar-listas`:** corri-o depois do `65a96d2`. Deu `antes.txt` 37, `depois.txt` 415, MANIFESTO 459,
  **0 novos, 0 tirados**, e nenhum ficheiro mudou. Nada em `rascunhos/` mudou, por isso não há listas a cometer.

## 3. CI

**Verde em `65a96d2`** (runs 44987654112 e 44987654142):

- **Sonda de privacidade:** success.
- **Testes dos rascunhos:** **10/10 jobs**: ponta-a-ponta, motor-real, servidor, protocolo, **retoma-pc**
  («FEITO: 415 ficheiros no PC iguais ao ramo»), godot-cliente, foto-mestre, validador-glb, cliente e provas-mapa.
- **No registo do CI:**
  - teste do relato: `teste do relato da caixa: 30 de 30 verificações passaram.`, com a verificação B4 nova;
  - `pecas_mestre`: `286 de 286`;
  - servidor: 418 testes, 408 passaram e **10 saltados** no Linux (aqui no PC, 418/418, 0 saltados);
  - prova da caixa do servidor: PROVA OK.

## 4. Pontos para o coordenador

1. **B2 foi além do caso.** Os três ecos do §B6 tinham o mesmo defeito (impressos antes da varredura do §B6) e
   ficaram corrigidos pelo mesmo `_ecoar`. Agora as 6 linhas do §B6 ecoam-se depois da varredura (antes ecoavam-se 3).
   Se a sentença queria só o caso, é desfazer as três remoções de `print` no `_init`.
2. **A retenção segue a varredura por palavras (R1).** Uma linha só fica RETIDA se tiver uma palavra de `PROIBIDAS`.
   Um valor sem chave proibida ao lado passaria e seria ecoado. É o limite da varredura por palavras, e a mudança de
   desenho é a ordem futura do R1; não lhe mexi.
3. **O log da mutação 2 com o teste antigo traz o valor-canário de bancada** (`Canario-Bancada`, fictício), duas vezes.
   É a prova do defeito, e o mesmo valor já está cometido em `b7-correcoes/mutacao-2-canario.log`. No log com o teste
   novo o valor não aparece.
4. **B4: a B7-2 e a B7-3 não se distinguem pelo corpo.** Distinguem-se só pelo rótulo. Está escrito no teste e acima;
   não inventei uma âncora.
5. **A conferência não está neste PC.** Trabalhei pelo texto da ordem.
6. **A fronteira:** só mudaram o teste e o README de `provas/ordem-caixa-relato/`, as corridas novas em
   `provas/ordem-caixa-relato/b7-correcoes-2/` e a linha «Base» do ESTADO-FINAL da B7-CORRECOES (que é o B3). Não
   mexi em `rascunhos/`, no HUD, nas cores nem em `provas/ordem-caixa-janela/`.
7. **Não mexi no `ORDEM.md` da sede**, como nas ordens anteriores. A última linha dele é o próprio item da ordem
   que cita `<b>Estado: NOVA</b>`; a marca de estado é do coordenador.
