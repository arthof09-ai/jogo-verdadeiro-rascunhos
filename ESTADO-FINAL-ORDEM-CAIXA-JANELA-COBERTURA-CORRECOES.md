# ESTADO FINAL — ORDEM CAIXA-JANELA-COBERTURA-CORRECOES (Claude conta 2, PC · 22/11/2026)

As correcções B1–B6 da sentença da CAIXA-JANELA-COBERTURA.

- **Ramo:** `claude2/caixa-janela-cobertura-correcoes`, **não fundido**.
- **Base:** `b36566d`, a ponta de `fable/integracao-50` à hora do lançamento. **A linha avançou durante a ordem**, para
  `da6683e` (3 commits da CAIXA-RELATO-B7-CORRECOES-2). Não mudei de base:
  - nenhum desses commits toca em `rascunhos/`, nas listas da retoma ou em `provas/ordem-caixa-janela/`;
  - `git merge-tree` entre este ramo e `da6683e` sai limpo.
- **Commits:**
  - `9b7ec0f`: a B1–B4, as corridas e as mutações;
  - o commit deste ESTADO-FINAL, que junta o artefacto do `actualizar-listas` (B5) e este ficheiro.
- **A conferência:** não está neste PC (`~/workspace/conferencias/caixa-janela-cobertura/` não existe). Trabalhei pelo
  texto da ordem, que traz os pontos da sentença.
- **Território:** só `provas/ordem-caixa-janela/` e este ESTADO-FINAL. `git diff b36566d HEAD -- rascunhos/ .github/` está
  vazio (está registado em `cobertura-correcoes/actualizar-listas.log`). Nada de código do jogo, de HUD nem de cores.
- **Privacidade:** os únicos valores nos registos cometidos são valores-canário de bancada (`custoPA` 0/2 das fichas
  fictícias e `paGasto` 0.0). Nenhum ficheiro novo traz um nome verdadeiro de bancada. Conferi com `grep` sobre o
  commit: só os rótulos antigos do teste, que já estavam cometidos.

Abaixo, as pastas são relativas a `provas/ordem-caixa-janela/`.

## 1. Ponto a ponto

### B1 — as 12 chaves (obrigatória)

**A lista.** `CHAVES_PROIBIDAS` (`ferramentas/nomes_relato.gd`) passa de 5 para 12 chaves:
- as 5 de antes: `vidaActual`, `vidaTotal`, `paTotal`, `paLivre`, `alma`;
- as 7 novas: `paGasto`, `estadoMorte`, `armaCaida`, `armaQuebrada`, `corpoPartido`, `custoPA`, `dano`.

**De onde vêm.** São as chaves que o servidor guarda por figura e só o Mestre vê:
- `sala.js:549` cria a figura com `vidaActual`, `paGasto`, `estadoMorte`, …;
- `projecao.js:216-226` monta a `propria` com `armaCaida`, `armaQuebrada`, `corpoPartido`;
- o `custoPA` é das técnicas, e o `dano` também entra.

O `paGasto` é a chave de PA que a vista do Mestre traz de facto (`MASTER_VIEW.json`). A chave `paLivre` só existe na
`propria`.

**O `dano` é tratado como a `alma`.** Só conta em forma de chave, nunca como texto simples. A MT4 prova a diferença:
com `dano` como texto simples, os «números de dano» em prosa tropeçam (ver a B2).

**O §5 do teste** (`ferramentas/teste_nomes_relato.gd`):
- A lista são as 12 chaves.
- **O caso testa o CUSTO**, numa verificação para cada chave. Uma linha
  `linha_bancada(lobo, …, {"tipo":"atacar", …, k: 2}, "APLICADA")`, com `k` = `custoPA` e depois `k` = `paGasto`,
  dá `["<k> na linha 5"]` e o diagnóstico «1 achado(s), linhas [5]», sem a chave. O `paLivre` já não faz de «custo».
- **As formas:** 12 chaves × 4 formas (JSON, `str()` de Dictionary, `k=`, `k:`) + `almaLivre` dão **49 linhas e 49
  achados**. O teste confere também que são 49.
- A prosa «5 chaves» deu lugar a «12 chaves proibidas» nos rótulos. Os rótulos novos dizem «chave privada do Mestre»,
  porque a lista já não é só vida/PA/alma.

**Atenuante, confirmada:** não havia fuga viva. A prova viva desta ordem, com as 12 chaves, dá **0 achados** no relato
(passagem 1, passagem 2 e fim). O buraco era latente.

**A frase errada da ordem anterior.** O ESTADO-FINAL da CAIXA-JANELA-COBERTURA diz «Fecha as faltas 1 e 2 da B7». Com a
lista de 5 isso **não era verdade**: os dois exemplos da própria B7, «um custo de PA» e «um dano», eram justamente as
chaves que faltavam (`custoPA`/`paGasto` e `dano`). Não emendo esse ESTADO-FINAL, que é registo histórico. A frase só
fica verdadeira **com esta ordem**: as 12 chaves apanham os dois exemplos, e a M1b mostra-o ao vivo.

### B2 — a regex da `alma` (e da `dano`); a lookbehind; os limites

As 12 chaves dividem-se em duas famílias, em `_re_chave`.

**As 10 camelCase:** `(?i)(?<![A-Za-z0-9_])<chave>`.
- Contam em qualquer sítio da linha, mas não a meio de outra palavra.
- A lookbehind mata o excesso de antes: `capaLivre`, `escapaTotal`, `mapaGasto` e `recustoPA` passam.
- Prova: a MT3 tira a lookbehind, e a prosa do §5 dá «4 achado(s), linhas [6]».

**«alma» e «dano»** (`CHAVES_PALAVRA`) contam só em forma de chave:
- `"k"`, `'k'`, `k:` / `k=` (de antes);
- `kCamel` (`almaLivre`, `danoTotal`);
- **`k_snake`** (`alma_livre`, `dano_total`), forma nova e segura, porque a prosa não tem `_`;
- **`k` nua seguida de um número** (`alma 3`, `alma -1`, `dano 7`), também nova.

Tudo isto com `(?<![A-Za-z0-9_])` à frente e com as maiúsculas como estão.

**As verificações de prosa no §5.** Estas linhas não tropeçam:
- «a alma do Lobo, com calma, na palma da mão; Alma; almas»;
- «os números de dano do Lobo; o dano, 3 vezes; danos; abandono; Dano; dano (2d8+3)»;
- «a alma, 3 vezes»;
- os rótulos verdadeiros da prova, os de antes (5 chaves) e os de agora (12 chaves).

Outra verificação confirma as 10 formas de chave de alma/dano (10 de 10).

**Os limites que ficam.** Estão escritos no cabeçalho de `CHAVES_PROIBIDAS`, em `nomes_relato.gd`, e **fixados** por uma
verificação do §5 («limites registados — 6 formas escapam por desenho»). Para mudarem, alguém tem de mudar o teste de
propósito:
1. «alma»/«dano» com maiúscula inicial em posição de chave (`{"Alma":3}`, `Dano: 4`). A casa escreve as chaves em
   camelCase com minúscula, e «Alma»/«Dano» em início de frase são prosa.
2. «alma»/«dano» seguidos de pontuação e de um número (`alma, 3`; `dano (2d8)`). É a forma da prosa.
3. As camelCase coladas a um prefixo (`figuraPaLivre`, `max_paGasto`). É o preço da lookbehind.
4. Um valor sob uma chave que não está na lista (`{"valor":16}`), ou um número solto. É o R1, decidido na B6.

### B3 — a M1b com valor real, e a «linha +1» da M1

**A mutação** é a mesma nas duas cópias (diffs em `cobertura-correcoes/m1b/`). Em `_jogar_vez`, o passo escrito na
linha «bancada:» leva:
- `paGasto`: o valor da figura **na vista do Mestre**;
- `custoPA`: o da **técnica** do passo, lido das fichas de bancada. Sem técnica no passo, leva o maior `custoPA` da ficha.

O «encerrar» fica como está.

**Os valores ficam visíveis em três sítios:**
- no relato mutado, cometido inteiro;
- no `mutacoes.log`, com as 13 linhas;
- no resumo do stdout:

| Valores postos (13 passos) | Vezes |
|---|---|
| `paGasto=0.0`, `custoPA=2` da técnica (`tiro-certeiro-bancada`, Arqueira) | 1 |
| `paGasto=0.0`, `custoPA=2`, o maior da ficha (Arqueira e Espadachim a mover) | 2 |
| `paGasto=0.0`, `custoPA=0` da técnica (`mordida-bancada`) | 2 |
| `paGasto=0.0`, `custoPA=0`, o maior da ficha (Lobo e Bruto a mover) | 8 |

O `paGasto` é 0.0 em todos os passos, e é o valor real: o servidor só debita o PA das heroínas, ao Confirmar uma
técnica, e a vista é lida antes do passo. O `custoPA` = 2 é o valor real das técnicas das heroínas.

**As corridas.** Servidor de bancada real, motor VLAB real, semente 7:

| Versão | Resultado | Relato mutado inteiro |
|---|---|---|
| base `b36566d` (5 chaves) | **41/41, rc=0: calada.** 13 linhas «bancada:» com `custoPA` e `paGasto`, 0 achados | `m1b/relato-mutado-base.txt` |
| esta ordem (12 chaves) | **38/41, rc=1:** `FALHA 1` (47 linhas), `FALHA 2` (76) e `FALHA fim` (78), cada uma com «26 achado(s), linhas [5,7,9,11,13,15,17,19,21,23,29,31,33]» (13 linhas × 2 chaves) | `m1b/relato-mutado-esta-ordem.txt` |

**A «linha +1» da M1 está explicada.** A cópia mutada da M1 escrevia uma linha a mais **no relato**: o marcador
`_linha("MUTACAO C1: …")`, logo a seguir ao cabeçalho. Por isso:
- o relato mutado tinha 48/77/79 linhas e o real 47/76/78;
- todos os achados vinham deslocados de 1 (linhas 6, 8, …, 34).

Na M1b, o marcador vai para o **stdout** e não para o relato. As contagens são as do relato real (47/76/78), e os achados
caem nas linhas 5, 7, …, 33: as mesmas linhas «bancada:» da M1 (6, 8, …, 34), menos 1. Tirando os passos, `diff`
entre o relato mutado da base e o desta ordem dá vazio.

### B4 — `(?i)` nas regexes de substring

As 10 regexes camelCase (as 4 de antes e as 6 novas) levam `(?i)`. No §5, 6 de 6 formas são apanhadas: `VidaActual`,
`vidaactual`, `PALIVRE`, `CustoPa`, `PaGasto` e `EstadoMorte`. Na MT2 (sem `(?i)`) o teste dá 22/23, com «0 de 6».

As de «alma»/«dano» **não** levam `(?i)` de propósito: «Alma»/«Dano» são início de frase (limite 1 da B2).

### B5 — o artefacto do `actualizar-listas`

`cobertura-correcoes/actualizar-listas.log` está cometido. Corri o script sobre `9b7ec0f` e o registo guarda:
- os SHA-256 das 3 listas antes e depois, iguais:
  - `antes.txt` `cf3b16fa…`;
  - `depois.txt` `4fd4320f…`;
  - `MANIFESTO-SHA256.txt` `cb15041a…`;
- a saída do script: «antes.txt: 37 · depois.txt: 415 · MANIFESTO: 459 ficheiros (0 novos, 0 tirados)», rc=0;
- o `git status`, vazio;
- `git diff --stat b36566d HEAD -- rascunhos/ .github/`, também vazio.

**Não havia listas a sincronizar:** o ramo não toca em `rascunhos/`. A evidência é este artefacto **e** o job `retoma-pc`
do CI (§3).

### B6 — o limite R1 (decisão registada)

**O limite.** A varredura do relato é por **nomes de chave**, não por **valores**. Um valor privado escapa em dois casos:
- sob uma chave genérica (`"valor"`, `"pv"`, `"total"`);
- como número solto (`… ficou com 16`).

Não é listável:
- `valor` e as chaves deste tipo são genéricas e aparecem em passos e protocolos legítimos;
- os valores de bancada (vida 16/22/30/34, PA 0/2/6) confundem-se com coordenadas, seq, medidas e px do próprio relato;
- uma lista de valores daria falsos alarmes em todas as corridas.

Está fixado como limite 4 da B2, no §5.

**A decisão:** a varredura por chaves fica como está, com 12 chaves, e o R1 fica aceite como limite conhecido até ao
passo seguinte.

**O passo seguinte:** um **canário de valor no relato**, na **ordem das fichas reais**, a mesma que já tem a condição C2.
1. Dar às fichas de bancada valores privados **inconfundíveis** (p. ex. vida e PA com 4 ou mais dígitos, que nenhuma
   coordenada, seq ou medida da prova atinge).
2. Juntar à prova uma varredura do relato por esses valores, nas passagens 1 e 2 e no fim, como a dos nomes.

Tem de mexer em `rascunhos/servidor/autojogo/fichas-bancada.json`, que está fora do território desta ordem, e por isso é
uma ordem própria.

Fica **assim fechado como decisão**, e não como ponto aberto do §4.

## 2. Corridas

Ambiente: PC, Godot 4.7.2 Windows `_console.exe`, Node 26, motor VLAB real sha256 `a91c021c…3261`, semente 7.

| Corrida | Resultado | Registo |
|---|---|---|
| Teste dos nomes do relato | **23/23**, rc=0. Os 14 de antes, iguais, + 9 do §5 (eram 5) | `cobertura-correcoes/teste-nomes-relato.log` |
| Prova viva da caixa-janela | **41/41**, rc=0, 0 SCRIPT ERROR. No relato: 0 nomes verdadeiros e 0 das 12 chaves (1, 2 e fim) | `cobertura-correcoes/cliente/relato.txt` |
| M1b, base / esta ordem | 41/41 rc=0 (calada) / **38/41 rc=1** (FALHA 1, 2 e fim) | `cobertura-correcoes/mutacoes.log`, `m1b/` |
| MT1 (lista de volta a 5) | 17/23, rc=1 | `mutacoes.log` |
| MT2 (sem `(?i)`) | 22/23, rc=1 | `mutacoes.log` |
| MT3 (sem lookbehind) | 21/23, rc=1 (prosa: `capaLivre`…; limites) | `mutacoes.log` |
| MT4 (`dano` como texto simples) | 21/23, rc=1 (prosa: «números de dano»; limites) | `mutacoes.log` |
| `actualizar-listas` | 0 novos, 0 tirados, sem diferenças | `cobertura-correcoes/actualizar-listas.log` |

- **Capturas da prova viva** (sha256, 16 primeiros): `88c434c6d428352c`, `f9c92f6d42f8c7fc` e `8fcff83eae9c3f93`. Vi a
  de 780×360: a caixa parte em 9 + 1 e mostra «Lobo na vez», como antes.
- **Um tropeço, corrigido antes de qualquer registo cometido:** a 1.ª corrida viva neste clone novo ficou presa, com
  `Could not find type "AplicadorPerfil"`. O clone não tinha a cache das classes do Godot (`.godot/`, ignorada pelo git).
  1. Matei essa corrida e só ela: confirmei os PIDs pela linha de comando.
  2. Corri `godot --headless --path rascunhos/cliente --import` (rc=0, 0 SCRIPT ERROR).
  3. Corri de novo a prova e as duas M1b, 0 SCRIPT ERROR em todas.

  O teste dos nomes não usa classes globais, por isso deu 23/23 antes e depois do import. O registo cometido é o de
  depois.
- Não corri as suites largas (servidor, rodar_testes…): esta ordem só muda as três ferramentas da prova, e o CI corre-as
  (§3).

## 3. CI

| Workflow | Commit | Corrida | Resultado |
|---|---|---|---|
| «Testes dos rascunhos» | `9b7ec0f` | 44997177699 | **verde, 10/10 jobs**: cliente, godot-cliente, servidor, protocolo, motor-real, ponta-a-ponta, foto-mestre, provas-mapa, validador-glb, **retoma-pc** |
| «Sonda de privacidade» | `9b7ec0f` | 44997177643 | **verde** |

No job `cliente`, o passo «Nomes do relato da caixa-janela» corre o teste com o §5 novo e dá **23 de 23** no registo do
CI: «as 12 privadas», «49 linhas (esperadas 49 = 12×4+1), 49 achado(s)» e as maiúsculas «6 de 6», todas a «ok».

O commit final (este ESTADO-FINAL e o `actualizar-listas.log`) só junta 2 ficheiros de texto fora de `rascunhos/`. Não
esperei pelo CI dele.

## 4. Pontos para o coordenador

1. **A base avançou** durante a ordem, de `b36566d` para `da6683e` (CAIXA-RELATO-B7-CORRECOES-2). Não há ficheiros em
   comum, e `git merge-tree` sai limpo.
2. **O teste dos nomes passa de 19/19 para 23/23.** O §5 tem agora 9 verificações:
   - a lista;
   - os relatos limpos;
   - o caso do custo, 2 verificações (`custoPA` e `paGasto`);
   - as 49 formas;
   - a prosa;
   - as formas de chave de alma/dano (B2);
   - as maiúsculas (B4);
   - os limites fixados (B2/B6).
   Os 14 de antes estão intactos. Continua no mesmo ficheiro e no passo do CI que já existe.
3. **A prova viva continua com 41 verificações.** A B1 alarga a lista, mas não acrescenta verificações: as 3 da C1 (1, 2
   e fim) agora varrem 12 chaves.
4. **C2 e o canário de valor**, sem mudança. Quando houver campo de alma nas fichas reais, o canário de valor senta-se ao
   lado das 12 chaves. O passo seguinte do R1 (B6) pode ir na mesma ordem das fichas reais.
5. O `ORDEM.md` da sede não foi mexido. Termina na linha «- O ficheiro da ordem termina com a linha exacta:
   <b>Estado: NOVA</b>», que é o último ponto da lista e não uma linha só sua, como nas ordens anteriores.
