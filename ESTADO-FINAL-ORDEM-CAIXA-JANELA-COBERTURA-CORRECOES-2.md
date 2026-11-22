# ESTADO FINAL — ORDEM CAIXA-JANELA-COBERTURA-CORRECOES-2 (Claude conta 1, PC · 22/11/2026)

As correcções B1–B5 da sentença da CAIXA-JANELA-COBERTURA-CORRECOES.

- **Ramo:** `claude1/caixa-janela-cobertura-correcoes-2`, **não fundido**.
- **Base:** `ed3ae11`, a ponta de `fable/integracao-50` à hora do lançamento.
- **Commits:**
  - `ce3d677`: B1, B2, B3 e B5, as corridas e as mutações;
  - o commit deste ESTADO-FINAL, que junta o artefacto do `actualizar-listas` (B4) e este ficheiro.
- **A conferência:** não está neste PC (`~/workspace/conferencias/caixa-janela-cobertura-correcoes/` não existe, nem
  está no repositório). Trabalhei pelo texto da ordem, que traz os pontos da sentença.
- **Território:** só `provas/ordem-caixa-janela/` e este ESTADO-FINAL. `git diff --stat ed3ae11 HEAD -- rascunhos/
  .github/` está vazio, com a saída capturada em `cobertura-correcoes-2/actualizar-listas.log`. Nada de código do jogo,
  de HUD nem de cores.
- **Privacidade:** os únicos valores nos registos novos são valores-canário de bancada: o `custoM` 4.5–12.0 m que o
  servidor de bancada deu em `opcoes.mover` (M1c), e os nomes públicos e de bancada que os relatos já traziam. A sonda de
  privacidade do CI passou em `ce3d677`.

Abaixo, as pastas são relativas a `provas/ordem-caixa-janela/`.

## 1. Ponto a ponto

### B1 — as 17 chaves (obrigatória)

**A lista.** `CHAVES_PROIBIDAS` (`ferramentas/nomes_relato.gd`) passa de 12 para 17 chaves. As 5 novas, e de onde vêm:

| Chave | Onde o servidor a guarda | Só o Mestre vê |
|---|---|---|
| `custoM` | `projecao.js:25`, `propria` do evento `movimento`; também cada casa de `opcoes.mover` (`sala.js:889`) | sim |
| `reservaM` | `projecao.js:25`, `propria` do `movimento` | sim |
| `perdeQuarto` | `projecao.js:38`, `propria` da `desgraca` | sim |
| `reacaoDisponivel` | por figura, `sala.js:551` | sim |
| `defendendo` | por figura, `sala.js:551` | sim |

**Duas decisões de forma**, ambas fixadas no §5 e por mutação:
- `custoM`/`reservaM` acabam no sufixo de unidade `M` (metros). A regex é `(?<![A-Za-z0-9_])(?i:custo)M`: o radical conta
  com qualquer mistura de maiúsculas (`CUSTOM`, `ReservaM` são apanhadas), o `M` final só maiúsculo. Assim o verbo
  «reservam» e o «custom» não tropeçam. Com a família `(?i)` inteira (MT6), a prosa «as figuras reservam 3 m; custom»
  dá 2 achados.
- `defendendo` também é palavra (gerúndio de «defender»), e vai para a família de «alma»/«dano»: só conta em forma de
  chave. Os valores são booleanos, e as formas em que chegam (`"defendendo":true`, `defendendo=false`,
  `{ "defendendo": true }`, `'defendendo'`) são todas apanhadas. Como substring (MT7), a prosa «a Arqueira está
  defendendo» tropeça.

**O §5 do teste** (`ferramentas/teste_nomes_relato.gd`):
- a lista são as 17 chaves;
- **o caso do custo** passa a 3 verificações: `custoPA`, `paGasto` e agora `custoM`. Cada uma dá `["<k> na linha 5"]`
  e «1 achado(s), linhas [5]», sem a chave no diagnóstico;
- **as formas:** 17 chaves × 4 formas (JSON, `str()` de Dictionary, `k=`, `k:`) + `almaLivre` dão **69 linhas e 69
  achados**, e o teste confere que são 69;
- a prosa ganhou duas linhas (`reservam`, `custom`, «o custo em m», «perde um quarto», «reacção disponível»,
  «defendendo», `incustoM`, `areservaM`), e passa;
- as formas de chave de palavra são agora 14 (+4 de `defendendo`), e as maiúsculas 10 (+ `CUSTOM`, `ReservaM`,
  `PERDEQUARTO`, `reacaodisponivel`).

**A mutação com `custoM`, executada (M1c).** Os diffs estão em `cobertura-correcoes-2/m1c/`. Em `_jogar_vez`, o passo
«mover» escrito na linha «bancada:» leva o `custoM` **real** da casa de destino. É o valor que o servidor deu em
`opcoes.mover` a esse lugar, lido antes do passo. Os 10 passos «mover» levam 4.5, 6.0 (×4), 7.5, 9.0 (×2) e 12.0 (×2),
iguais nas duas versões. O marcador vai para o stdout, não para o relato.

| Versão | Resultado | Relato mutado inteiro |
|---|---|---|
| base `ed3ae11` (12 chaves) | **41/41, rc=0: calada.** 10 linhas «bancada:» com `custoM`, 0 achados | `m1c/relato-mutado-base.txt` |
| esta ordem (17 chaves) | **38/41, rc=1:** `FALHA 1` (47 linhas), `FALHA 2` (76) e `FALHA fim` (78), cada uma com «10 achado(s), linhas [5,7,9,11,13,15,17,19,21,23]» | `m1c/relato-mutado-esta-ordem.txt` |

0 SCRIPT ERROR nas duas. Isto confirma o crítico de privacidade: com as 17 chaves, o relato vivo dá 0 achados (§2), a
prosa 0, e as formas todas são apanhadas.

**Latente, não vivo:** a prova viva desta ordem, com as 17 chaves, dá **0 achados** no relato (1, 2 e fim). A frase
«Fecha as faltas 1 e 2 da B7» fica verdadeira com as 12, como a sentença registou. Não lhe toquei.

### B2 — os limites novos, registados

Estão escritos no cabeçalho de `CHAVES_PROIBIDAS` (`nomes_relato.gd`) e **fixados** na verificação «limites
registados» do §5, que passa de 6 para **13 formas que escapam por desenho**:
1. **`modo` (H10, só do Mestre) não é listável.** A linha legítima da prova «caixa da jogadora ao abrir: visível=true
   modo=dinamico …» traz `modo=`, que é a forma de chave. Listar `modo` faria a prova tropeçar em todas as corridas.
   O §5 fixa a própria linha e `{"modo":"dinamico"}` como formas que escapam.
2. **Kebab `alma-total`/`dano-total` escapam.** A casa não escreve chaves em kebab, e o hífen é o da prosa composta.
   A forma `alma -1` (nua + número negativo) continua apanhada.
3. **`custoM`/`reservaM` com o `m` minúsculo** (`reservam=3`, `custom: 1`) escapam: é o preço de não tropeçar no
   verbo (B1).
4. **`defendendo` nua seguida de booleano** (`defendendo true`) escapa: é a forma da prosa.

Os limites de antes (valor genérico/R1, «Alma»/«Dano» maiúsculos, palavra + pontuação, chave com prefixo) ficam como
estavam, também no §5.

### B3 — a frase dos relatos mutados

A frase errada do ESTADO-FINAL da CAIXA-JANELA-COBERTURA-CORRECOES (B3 de lá) é: «Tirando os passos, `diff` entre o
relato mutado da base e o desta ordem dá vazio.»

**É falsa.** Os dois relatos da M1b diferem em **4 linhas**: as 3 verificações (1, 2 e fim) e o total. Conferi com
`diff m1b/relato-mutado-base.txt m1b/relato-mutado-esta-ordem.txt`, que dá as linhas 48, 77, 79 e 81 (rc=1).

**A frase correcta:** tirando os passos e as 4 linhas de veredicto, `diff` entre o relato mutado da base e o desta ordem
dá vazio. (Os passos, de facto, também são iguais nas duas versões. O que difere são só as 4 linhas.)

Esse ESTADO-FINAL é registo histórico, já fundido, e não o emendo. A correcção fica aqui. A mesma conta está feita e
**capturada** para a M1c desta ordem, no fim da secção M1c de `cobertura-correcoes-2/mutacoes.log`: o `diff` dá as
mesmas 4 linhas (48, 77, 79, 81) e rc=1.

### B4 — a saída real no artefacto do `actualizar-listas`

O `cobertura-correcoes/actualizar-listas.log` da ordem anterior tinha os cabeçalhos de `git status` e `git diff` sem
saída nenhuma por baixo. Não se distinguia «saída vazia» de «comando não corrido».

O artefacto novo, `cobertura-correcoes-2/actualizar-listas.log`, corre cada comando por uma função que escreve:
- o comando (`$ …`);
- a saída tal como saiu, ou «(saída vazia: 0 bytes)» quando é mesmo vazia;
- o `rc`.

Corrido sobre `ce3d677`, mostra:
- os SHA-256 das 3 listas antes e depois, iguais: `antes.txt` `cf3b16fa…`, `depois.txt` `2da80f0e…`,
  `MANIFESTO-SHA256.txt` `bfde904b…`;
- o script: «antes.txt: 37 · depois.txt: 415 · MANIFESTO: 459 ficheiros (0 novos, 0 tirados nesta passagem)», rc=0;
- `git status --short --untracked-files=all retoma-i0004 MANIFESTO-SHA256.txt`: saída vazia, rc=0;
- `git diff --stat -- retoma-i0004 MANIFESTO-SHA256.txt`: saída vazia, rc=0;
- `git diff --stat ed3ae11 HEAD -- rascunhos/ .github/`: saída vazia, rc=0;
- `git diff --stat ed3ae11 HEAD`: os 20 ficheiros do ramo, todos em `provas/ordem-caixa-janela/`.

**Não havia listas a sincronizar:** o script só olha para `rascunhos/`, e o ramo não lhe toca. O commit final leva o
artefacto, e o job `retoma-pc` do CI confere o resto (§3).

O log antigo fica como está, porque é registo histórico.

### B5 — a prosa «a alma 3 vezes», presa

Uma verificação nova no §5 fixa o comportamento: as linhas «a alma 3 vezes» e «o dano 3 vezes» (sem vírgula) **são
apanhadas**, com `["alma na linha 1", "dano na linha 2"]` e «2 achado(s), linhas [1,2]».

É um falso alarme aceite, que falha para o lado seguro: `alma 3` é uma forma de chave (B2 da ordem anterior). A prosa
da casa escreve «a alma, 3 vezes», com vírgula, e essa continua a passar na verificação da prosa. Está escrito também no
cabeçalho de `CHAVES_PROIBIDAS`.

A MT8 tira a forma «k nua + número» e a verificação B5 cai («0 achado(s)»), junto com a das formas de chave (11 de 14).

## 2. Corridas

Ambiente: PC, Godot 4.7.2 Windows `_console.exe`, Node, motor VLAB real sha256 `a91c021c…3261`, semente 7. Antes de
tudo, `godot --headless --path rascunhos/cliente --import` no clone novo (rc=0, 0 SCRIPT ERROR), para não repetir o
tropeço da ordem anterior.

| Corrida | Resultado | Registo |
|---|---|---|
| Teste dos nomes do relato | **25/25**, rc=0. Os 14 de antes, iguais, + 11 do §5 (eram 9: + o caso do `custoM`, + o falso alarme B5) | `cobertura-correcoes-2/teste-nomes-relato.log` |
| Prova viva da caixa-janela | **41/41**, rc=0, 0 SCRIPT ERROR. No relato: 0 nomes verdadeiros e 0 das 17 chaves (1, 2 e fim) | `cobertura-correcoes-2/cliente/relato.txt` |
| M1c, base / esta ordem | 41/41 rc=0 (calada) / **38/41 rc=1** (FALHA 1, 2 e fim, 10 achados) | `cobertura-correcoes-2/mutacoes.log`, `m1c/` |
| MT5 (lista de volta a 12) | 20/25, rc=1 (lista, caso `custoM`, 49 de 69 formas, palavra 10 de 14, maiúsculas 6 de 10) | `mutacoes.log`, `mt5-lista-12.diff` |
| MT6 (`custoM`/`reservaM` com `(?i)` inteiro) | 23/25, rc=1 (prosa: `reservam`, `custom`; limites) | `mutacoes.log`, `mt6-sem-sufixo.diff` |
| MT7 (`defendendo` como substring) | 23/25, rc=1 (prosa: «está defendendo»; limites) | `mutacoes.log`, `mt7-defendendo-texto.diff` |
| MT8 (sem «k nua + número») | 23/25, rc=1 (formas de palavra 11 de 14; B5) | `mutacoes.log`, `mt8-sem-nua-numero.diff` |
| `actualizar-listas` | 0 novos, 0 tirados, listas iguais, saídas capturadas | `cobertura-correcoes-2/actualizar-listas.log` |

- **Capturas da prova viva** (sha256, 16 primeiros): `28a15fedf11d2e9e`, `4053e9acff9e21be` e `875701c2187f2a0e`.
- **A prova viva continua com 41 verificações.** A B1 alarga a lista, mas as 3 verificações da C1 (1, 2 e fim) são as
  mesmas; agora varrem 17 chaves. `prova_caixa_janela.gd` só muda num comentário: o rótulo conta as chaves de
  `NomesRelato.CHAVES_PROIBIDAS`.
- Não corri as suites largas (servidor, rodar_testes…): esta ordem só muda as três ferramentas da prova, e o CI corre-as
  (§3).

## 3. CI

| Workflow | Commit | Corrida | Resultado |
|---|---|---|---|
| «Testes dos rascunhos» | `ce3d677` | 45001276037 | **verde, 10/10 jobs**: cliente, godot-cliente, servidor, protocolo, motor-real, ponta-a-ponta, foto-mestre, provas-mapa, validador-glb, **retoma-pc** |
| «Sonda de privacidade» | `ce3d677` | 45001276084 | **verde** |

No job `cliente`, o passo «Nomes do relato da caixa-janela» dá **25 de 25** no registo do CI, com «as 17 privadas» e
«69 linhas (esperadas 69 = 17×4+1), 69 achado(s)», todas a «ok».

O commit final (este ESTADO-FINAL e o `actualizar-listas.log`) só junta 2 ficheiros de texto fora de `rascunhos/`; o
seu CI fica para o coordenador conferir na página do ramo.

## 4. Pontos para o coordenador

1. **O teste dos nomes passa de 23/23 para 25/25.** Os 14 de antes estão intactos. O §5 tem agora 11 verificações:
   - a lista;
   - os relatos limpos;
   - o caso do custo, em 3 verificações (`custoPA`, `paGasto`, `custoM`);
   - as 69 formas;
   - a prosa;
   - as formas de chave de palavra;
   - as maiúsculas;
   - os limites (13 formas);
   - o falso alarme B5.
   Continua no mesmo ficheiro e no passo do CI que já existe.
2. **Duas decisões de forma minhas, na B1**, que a ordem não pedia por letra: o `M` final só maiúsculo em
   `custoM`/`reservaM`, e `defendendo` na família de palavra. Ambas existem para a prosa portuguesa não tropeçar
   («reservam», «defendendo»). Ambas trazem um limite registado (o `m` minúsculo; `defendendo` + booleano) e uma
   mutação que mostra o que acontecia sem elas (MT6, MT7). Se preferires a família `(?i)` simples para as 5, é trocar
   duas constantes. Nesse caso, a prosa do §5 tem de perder essas palavras.
3. **A B3 não emenda o ESTADO-FINAL anterior**, que é registo histórico. A frase correcta está aqui (§1, B3) e a conta
   capturada está no `mutacoes.log` desta ordem.
4. **O total de verificações** continua sem ser afirmado em lado nenhum do código, como a sentença registou. Aqui só
   está nos registos das corridas.
5. **C2, o R1 e o canário de valor:** sem mudança, ficam para a ordem das fichas reais.
6. **A base não avançou** durante a ordem: `origin/fable/integracao-50` continua em `ed3ae11` à hora do commit final.
7. O `ORDEM.md` da sede não foi mexido. Termina na linha «- O ficheiro da ordem termina com a linha exacta:
   <b>Estado: NOVA</b>», que é o último ponto da lista e não uma linha só sua, como nas ordens anteriores.
