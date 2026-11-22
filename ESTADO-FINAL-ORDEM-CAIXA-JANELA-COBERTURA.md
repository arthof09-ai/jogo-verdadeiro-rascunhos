# ESTADO FINAL — ORDEM CAIXA-JANELA-COBERTURA (Claude conta 2, PC · 22/11/2026)

As correcções C1–C2 da sentença da CAIXA-JANELA-NOMES-CORRECOES.

- **Ramo:** `claude2/caixa-janela-cobertura`, **não fundido**.
- **Base:** `91fcfc5`, a ponta de `fable/integracao-50` à hora do lançamento (o CM-000009 do coordenador, com o passo
  dos nomes no CI). A linha não avançou durante a ordem: conferi com `git fetch` antes do push.
- **Commits:**
  - `b8d5822`: a C1, as corridas e as mutações;
  - o commit deste ESTADO-FINAL, que só acrescenta este ficheiro.
- **A conferência:** não estava neste PC (`~/workspace/conferencias/caixa-janela-nomes-correcoes/` não existe).
  Trabalhei pelo texto da ordem e pelo §1 B7 do ESTADO-FINAL da CAIXA-JANELA-NOMES-CORRECOES.
- **Território:** só `provas/ordem-caixa-janela/` (as ferramentas, o teste, a prova viva e o `cobertura/` novo).
  `git diff 91fcfc5 -- rascunhos/ .github/` está vazio. Nada de código do jogo, de HUD nem de cores.

## 1. Ponto a ponto

### C1 — a varredura do relato por chaves proibidas

**O ajudante:** `nomes_relato.gd`, partilhado pela prova e pelo teste. Tem três peças novas:
- `CHAVES_PROIBIDAS`: `vidaActual`, `vidaTotal`, `paTotal`, `paLivre` e `alma`;
- `chaves_no_relato(relato)`: devolve «<chave> na linha <n>», só para o teste conferir o caso;
- `diagnostico_chaves(relato)`: devolve «N achado(s), linhas [..]». **Não escreve a chave achada.** O diagnóstico vai
  para o relato; se escrevesse a chave, a varredura do `fim` tropeçaria no próprio rótulo da FALHA anterior.

**O critério:** os rótulos das verificações usam «vida», «PA» e «alma» como palavras, por isso a varredura procura
chaves e não palavras.
- As 4 chaves camelCase contam **em qualquer sítio** da linha. Não aparecem em prosa.
- «alma» também é palavra portuguesa, por isso só conta:
  - em posição de chave: `"alma"`, `'alma'`, `alma:` ou `alma=`;
  - ou como início de um identificador camelCase (`almaLivre`, `almaTotal`). A forma real da chave ainda não existe
    em ficha nenhuma (ver a C2).
- Assim, «a alma do Lobo», «calma», «palma», «Alma» e «almas» passam.

**Na prova** (`prova_caixa_janela.gd`): uma verificação nova em cada passagem do `_privacidade` (1 e 2) e outra no
`_fim()`. A do `fim` é **incondicional**, como a dos nomes (B3): não precisa de canários, porque as chaves são fixas.
A prova passa de 38 para **41** verificações.

**No teste** (`teste_nomes_relato.gd`): um §5 novo com 5 verificações; o teste passa de 14 para **19**.
1. A lista são as 5 chaves.
2. O relato escrito pela fonte e o `RELATO_VELHO` inteiro, que tem os rótulos «vida, PA» em palavra, dão 0 achados.
3. **O caso da ordem:** uma linha `linha_bancada(lobo, …, {"tipo":"mover","destino":…,"paLivre":4}, "APLICADA")`,
   isto é, um passo «bancada:» com um custo de PA. Dá `["paLivre na linha 5"]` e o diagnóstico «1 achado(s), linhas
   [5]».
4. Cada uma das 5 chaves é apanhada em quatro formas: JSON, `str()` de um Dictionary do Godot, `k=` e `k:`. A estas
   somam-se `almaLivre`: 21 linhas, 21 achados.
5. As palavras em prosa não tropeçam, incluindo dois rótulos verdadeiros da prova. O diagnóstico não contém a chave.

**Fecha as faltas 1 e 2 da B7.** A falta 1 pedia uma verificação automática de vida/PA no relato. A falta 2 era a linha
«bancada:», que escreve o passo inteiro com `JSON.stringify`, de modo que um valor posto no passo entrava sem
verificação.

**As mutações, todas executadas** em cópias em `tmp/` e nenhuma cometida. Registo em
`provas/ordem-caixa-janela/cobertura/mutacoes.log`.

| Mutação | Versão | Resultado |
|---|---|---|
| **M1:** prova viva; o passo «bancada:» leva o PA livre que sobra (chave `paLivre`) | base `91fcfc5` | **38/38, rc=0: calada.** 13 linhas do relato com a chave (6, 8, …, 34) |
| | esta ordem | **38/41, rc=1:** `FALHA 1`, `FALHA 2` e `FALHA fim`, cada uma com «13 achado(s), linhas [6,8,…,34]» |
| **M2:** teste; `paLivre` tirado de `CHAVES_PROIBIDAS` | esta ordem | **17/19, rc=1:** a lista e o caso do custo de PA falham |
| **M3:** teste; «alma» procurada como texto simples, sem a posição de chave | esta ordem | **18/19, rc=1:** os rótulos em prosa tropeçam (linhas 2 e 3) |

- A M1 correu ao vivo, com o servidor de bancada real e o motor VLAB real.
- O valor escrito na M1 foi 0 em todas as linhas: a figura da vista do Mestre não traz o PA livre, e a mutação caía no
  valor por omissão. Não altera o resultado, porque a varredura procura a chave e não o valor. O registo cometido não
  traz os valores: tem só as linhas FALHA/ok e as contagens.

### C2 (condição) — o canário de alma

**A condição não se cumpre:** nenhuma ficha tem campo de alma.
- Nas fichas de bancada (`servidor/autojogo/fichas-bancada.json`), no protocolo (`protocolo/v2/*.schema.json`) e no
  servidor, nenhuma chave JSON tem «alma» no nome. Procurei com
  `grep -rnoE '"(alma[A-Za-z]*|[a-zA-Z]*Alma[A-Za-z]*)"' rascunhos`: 0 ocorrências.
- A alma só aparece em prosa: em comentários, nas descrições dos schemas («nunca vida nem alma») e num texto do HUD
  (`hud.gd:754`, «de alma livre»).
- **Não inventei** um nome de campo para o canário dos textos da caixa. Fica para a ordem das fichas reais, com os
  outros campos privados, como a ordem manda.
- **No relato, a C1 já cobre a alma:** `alma` em posição de chave e qualquer `alma…` camelCase. Quando o campo existir,
  falta só o canário de **valor** nos textos da caixa, ao lado de `vidaActual`/`vidaTotal`/`paTotal`/`paLivre` no
  `_privacidade`.

## 2. Corridas

Ambiente: PC, Godot 4.7.2 Windows `_console.exe`, Node 26.13, motor VLAB real sha256 `a91c021c…3261`, semente 7.

| Corrida | Resultado | Registo |
|---|---|---|
| Teste dos nomes do relato | **19/19** (os 14 de antes, iguais, + 5 do §5) | `provas/ordem-caixa-janela/cobertura/teste-nomes-relato.log` |
| Prova viva da caixa-janela | **41/41**, rc=0; 0 nomes verdadeiros e 0 chaves proibidas no relato | `cobertura/cliente/relato.txt` |
| Teste do relato da caixa | **30/30** | `cobertura/suites/teste_relato_caixa.log` |
| Servidor, `node --test --test-isolation=none` | **419/419**, 0 falhas | `cobertura/suites/servidor-node-test.log` |
| `prova-servidor.mjs` | **PROVA OK** | `cobertura/suites/prova-servidor.log` |
| rodar_testes · abrir_scripts | 290/290 · 107 scripts, 0 falhas | `cobertura/suites/` |
| caixa_jogadora · hud_acoes · canario_privacidade | 18/18 · 50/50 · 10/10 | `cobertura/suites/` |
| Mutações M1–M3 | ver §1 C1 | `cobertura/mutacoes.log` |
| `actualizar-listas` (retoma), depois de `b8d5822` | antes.txt 37, depois.txt 415, MANIFESTO 459; **0 novos, 0 tirados, sem diferenças** | — |

- **Capturas da prova viva** (sha256, 16 primeiros): `95903df226a9cfd0`, `00410562fefa1dbd` e `939137737ead4137`. Vi a
  de 780×360: a caixa parte em 9 + 1, com «Lobo», «Bruto», «Arqueira …» e «Espadachi…», e mostra «Lobo na vez».
- **O servidor correu sem `--permission`.** Com essa opção, o Node 26 deste PC, no Git Bash, não expandiu o glob e deu
  **0 testes** (rc=0). Não contei essa corrida. O CI corre o passo com `--permission`, verde (abaixo).
- **Um tropeço que corrigi antes do commit:** a 1.ª versão da expressão regular tinha `\s` dentro de uma string do
  GDScript, um escape inválido. O Godot headless ficou preso no erro de parse até eu o matar. Passou a `[ \t]*`.
  Nenhum registo cometido é dessa corrida.

**Listas da retoma:** não havia listas para incluir no commit. O ramo não toca em `rascunhos/`, e o `git status` ficou
limpo depois do script. O passo retoma-pc passou no CI.

## 3. CI

| Workflow | Commit | Corrida | Resultado |
|---|---|---|---|
| «Testes dos rascunhos» | `b8d5822` | 44991231481 | **verde, 10/10 jobs**: cliente, godot-cliente, servidor, protocolo, motor-real, ponta-a-ponta, foto-mestre, provas-mapa, validador-glb, **retoma-pc** |
| «Sonda de privacidade» | `b8d5822` | 44991231516 | **verde** |

No job `cliente`, o passo «Nomes do relato da caixa-janela» (o da B1, aplicado pelo coordenador) corre já o teste com
o §5: **19 de 19** no registo do CI, com as 5 verificações do §5 a «ok».

## 4. Pontos para o coordenador

1. **A ordem diz «o teste dos nomes 14/14»; agora é 19/19.** Pus o §5 da C1 no **mesmo** teste. Assim corre no passo
   do CI que já existe, sem remendo novo ao workflow, que este token não pode fazer porque não tem o âmbito
   `workflow`. Os 14 de antes estão intactos e passam. Se queriam o §5 num ficheiro à parte, tem de entrar um passo
   novo no CI.
2. **`custoPA` não está na lista.** A lista da ordem tem 5 chaves. As fichas de bancada têm `custoPA` nas técnicas. Se
   a IA ou o protocolo puserem no passo **o custo** (`custoPA`) em vez do PA livre, a varredura não o vê, e o mesmo
   vale para um `dano`. Acrescentá-los é uma linha em `CHAVES_PROIBIDAS`, mas a decisão é vossa: `custoPA` é dado da
   técnica, não da figura.
3. **A varredura continua a ser por palavras/chaves e não por valores** (R1 da RELATO-B7-CORRECOES). Um valor de vida
   sob uma chave que não esteja na lista, ou um número solto, escapa. É o passo seguinte nessa direcção, não a mudança
   de desenho.
4. **C2:** fica para a ordem das fichas reais (§1 C2). Quando houver campo de alma, junta-se o canário de valor nos
   textos da caixa. No relato, a forma de chave já está coberta.
5. O `ORDEM.md` da sede não foi mexido. Como nas ordens anteriores, a linha «Estado: NOVA» está no último ponto da
   lista e não numa linha só sua.
