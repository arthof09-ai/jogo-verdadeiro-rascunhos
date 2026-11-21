# ESTADO-FINAL — ORDEM-PROVAS-MAPA-CORR9-CORRECOES (conta 1 · Opus · 21/11/2026)

**Objecto:** as correcções da sentença da CORR9 (FUNDE COM CORRECÇÕES, 890/1000): B1, B2, B3, N2 a N6, e o registo
de N1.
**Ramo:** `claude1/provas-mapa-corr9`. Os commits novos vão sobre `29e9215` (a base continua `b7ecadd`). **SEM fusão.**
- `a588a2e`: as correcções (comparador, controlos, patch, relatório, `repeticao-pc.md` re-gerado);
- o commit seguinte: este ficheiro.

`fable/integracao-50` continua em `b7ecadd` (`git ls-remote`).
**Regra dura:** `git diff --stat b7ecadd HEAD -- rascunhos .github` está vazio. Nenhuma linha do jogo nem do
`testes.yml` mudou. Só mudaram as ferramentas de comparação, o patch do CI e o relatório.
**Não se correram as provas outra vez.** O comparador foi re-corrido sobre as corridas 1, 2 e 3 que já estavam
cometidas.

## Leia primeiro
- **Repetição com o comparador corrigido: 461/461 números e 73/73 bits, `REPETE-SE`, saída 0.** Antes eram 419 + 73.
  Entraram 42 números da floresta.
- **Controlo negativo (B2):** mudei um número numa cópia da corrida 1. O comparador deu `NÃO SE REPETE`, com saída 1 e
  exactamente uma linha «NÃO». Há mais 8 controlos e os 9 dão o esperado.
- **O import do job passa a falhar o job (B3).** O patch foi regenerado e `git apply --check` confirma que aplica na
  ponta. Não o apliquei nem o empurrei: isso cabe ao coordenador, depois da fusão.
- **CI na ponta `a588a2e`:** 8 de 9 jobs verdes. O `retoma-pc` está vermelho por causa da base. A sonda está verde.

---

## As 9 correcções, uma a uma

### B1 — A sequência da floresta entra no portão: FEITO e VERIFICADO
- **O que mudou:** `comparar-corridas.mjs` lê agora os três registos de cada corrida:
  - `provar-terreno-servidor.log`;
  - `provar-terreno-servidor-adaptada.log`;
  - `bancada-jogadora.log`.

  Em cada linha `[floresta] pronta …`, tira o campo `casas_bloqueadas` do JSON e compara-o carga a carga. Junta mais
  dois números por registo: o número de cargas e cada carga. Ficam 42 números novos no portão:
  - ferramenta original: 1 + 18;
  - ferramenta adaptada: 1 + 18;
  - bancada: 1 + 3.

  Uma linha `[floresta]` sem JSON legível conta como «(ilegível)». Assim não passa calada.
- **Porquê também a adaptada:** a sentença pede 18 cargas na prova 1. A prova 1 tem duas ferramentas e cada uma
  carrega a floresta 18 vezes, por isso entram as duas.
- **Re-corrida sobre as corridas cometidas:**
  ```
  node provas/ordem-provas-mapa-corr9/ferramentas/comparar-corridas.mjs --bits --md=provas/ordem-provas-mapa-corr9/repeticao-pc.md \
    corrida-1=provas/ordem-mapa-jogavel/provas-bancada corrida-2=provas/ordem-provas-mapa-corr9/corrida-2 corrida-3=provas/ordem-provas-mapa-corr9/corrida-3
  → REPETE-SE — corrida-1 × corrida-2 × corrida-3: números 461/461 iguais, bits 73/73 iguais (bits no portão)   · saída 0
  ```
  `repeticao-pc.md` foi re-gerado e tem 534 linhas «sim» (461 + 73) e 0 «NÃO».

  As sequências são iguais nas três corridas:
  - original e adaptada: `173 146 128 173 164 188 141 204 125 157 88 88 88 151 141 122 133 91`;
  - bancada: `173 88 88`.
- **Relatório:** na tabela, as duas linhas da floresta estão agora marcadas «no portão desde a CORR9-C».

### B2 — O controlo negativo, registado: FEITO e VERIFICADO
O guião `ferramentas/controlo-comparador.mjs` faz três coisas em cada controlo:
- copia a corrida 1 para uma pasta temporária;
- muda uma só coisa;
- corre o comparador e confere a saída e o número de linhas «NÃO».

O registo está em `registos/controlo-comparador.log`. A saída do guião foi 0.

| controlo | mudança | esperado | obtido |
|---|---|---|---|
| K0 positivo | nenhuma (a corrida 1 contra si) | saída 0, 0 «NÃO» | `REPETE-SE`, 461/461, 73/73, saída 0 |
| **K1 número** (o pedido em B2) | grelha 11 original, `casasBloqueadas` 156 → 157 | saída 1, 1 «NÃO» | **`NÃO SE REPETE`, 460/461, saída 1**, a linha `original g11 bloq. srv \| 156 \| 157 \| **NÃO**` |
| K2 floresta | carga 11 da original, `casas_bloqueadas` 88 → 89, só no `.log` | saída 1, 1 «NÃO» | `NÃO SE REPETE`, 460/461, saída 1 |
| K3 floresta | a 3.ª linha `[floresta]` da bancada apagada | saída 1, 2 «NÃO» | `NÃO SE REPETE`, 459/461: «cargas 3 → 2» e «carga 03 (falta)» |
| K4 bits | `desenhadaY` da 1.ª figura da g11 + 0,5 m, com `--bits` | saída 1, 1 «NÃO» | `NÃO SE REPETE`, bits 72/73, saída 1 |
| K5 bits sem portão | a mesma mudança, sem `--bits` (como no CI) | saída 0, 1 «NÃO» | `REPETE-SE`, bits 72/73 (só registados), saída 0 |
| K6 dentro/fora (N3) | desvio de altura 0,01/0 contra 0/0,01 (o `max()` dava o mesmo) | saída 1, 1 «NÃO» | `NÃO SE REPETE`, 460/461, saída 1 |
| K7 marcos por outra ordem (N2) | `marcos` da g11 invertidos | saída 0, 0 «NÃO» | `REPETE-SE`, saída 0 |
| K8 marco mudado (N2) | `servidor.alturaM` do 1.º marco da g11 + 0,5 m | saída 1, 1 «NÃO» | `NÃO SE REPETE`, bits 72/73, saída 1 |

Isto bate com o que o C2 da bancada mediu por si:
- números 418/419;
- bits 72/73;
- uma linha «NÃO» em cada caso.

Os totais agora são 460/461 e 72/73, porque o portão tem mais 42 números.

### B3 — O `|| true` sai do import do job, e o §2a fica preciso: FEITO
- **No patch** (`ci-job-provas-mapa.patch`), o passo «Importar o projeto do cliente» passa a ser:
  ```
  run: |
    set -o pipefail
    timeout 300 "$GODOT" --headless --path . --import 2>&1 | tail -20
  ```
  - O `set -o pipefail` é preciso. O `run:` sem `shell:` corre em `bash -e`, sem pipefail. Só a tirar o `|| true`, o
    código de saída seria o do `tail`, e o import continuaria a não falhar o job.
  - É a forma que o job `godot-cliente` já usa no seu passo «Importar o projeto (--headless --import)», sem
    `|| true`, e esse job está verde.
  - O job leva um comentário com isto. O patch tem 47 linhas acrescentadas (antes 42) e continua a só acrescentar o
    job `provas-mapa` ao `testes.yml`.
- **Como o patch foi refeito:** numa worktree temporária na ponta, `git am` do patch antigo, a edição,
  `git commit --amend` e `git format-patch -1`. A worktree foi apagada a seguir.
  `git apply --check` do patch novo em `a588a2e`: **aplica**.
- **§2a do relatório:** agora diz que o SHA-256 do zip é «impresso no registo, não comparado com um valor esperado
  (como nos jobs existentes)». Diz também que o import falha o job quando falha.
- **Limite:** o patch nunca correu em Linux (S1 é do coordenador). Não sei se o `--import` do Godot 4.7.2 sai com 0
  num clone limpo neste job. O passo igual do `godot-cliente` sai com 0, e é tudo o que sei.

### N1 — O SHA-256 do Godot: REGISTADO, não feito (regra da ordem)
Fica como a sentença decidiu. Se o juiz quiser verificar o SHA, isso é uma mudança em todos os jobs. Aqui só se
corrigiu a frase (B3).

### N2 — O hash dos marcos ordenado: FEITO e VERIFICADO
O campo `marcos (casa, alturas)` passa a fazer `.sort(cmpStr)` antes do SHA, como o das figuras. Os controlos provam
as duas coisas:
- K7: com os marcos por outra ordem, dá igual;
- K8: com um marco mudado, ainda morde.

Os valores do hash mudaram (por exemplo, g11 `bc6f6dcbb6e63dea`), mas são iguais nas três corridas: 73/73.

### N3 — O limite do `max()` de dentro/fora: FEITO (comparação em separado) e VERIFICADO
- O campo passou de `desvio altura / pé / figuras (m)` com `max(dentro, fora)` para
  `desvio altura dentro/fora · pé dentro/fora · figuras (m)`, com os quatro valores à vista. Em todas as grelhas das
  três corridas dá `0/0 · 0/0 · 0`.
- O número de campos é o mesmo, um por grelha.
- O K6 prova que o comparador agora vê uma troca entre dentro e fora que o `max()` escondia.
- O relatório (§1a) regista o limite que havia antes.

### N4 — A explicação da duração: MEDIDA, e a explicação sem medida RETIRADA
Os registos têm `# início` / `# fim` e o `carga_ms` de cada carga da floresta. Medi:

| | corrida 1 (20/11) | corrida 2 | corrida 3 |
|---|---|---|---|
| original: duração total | 84 s | 61 s | 61 s |
| original: soma dos `carga_ms` (18 cargas) | 62,2 s | 48,7 s | 49,8 s |
| adaptada: duração total | 80 s | 60 s | 61 s |
| adaptada: soma dos `carga_ms` | 60,3 s | 47,9 s | 49,1 s |

- Cerca de 12 a 13 s da diferença (20 a 23 s) estão nas cargas da floresta.
- Os outros 8 a 10 s por ferramenta estão fora dessas cargas, e não os medi.
- **Não sei porque é que as cargas foram mais rápidas.** A frase «noutro regime de carga» foi retirada do relatório e
  ficou só a medida.
- A duração não entra no portão.

### N5 — O apontador da reparação das listas: FEITO
O relatório (leia primeiro, ponto 5, e §7) aponta agora para os dois ramos:
- `claude1/provas-mapa-corr7` @ `e140dfc` («Listas da retoma refeitas…»);
- `claude1/provas-mapa-corr8` @ `d39f9fa` (a primeira reparação foi `726ad85`).

Os dois SHA foram conferidos por `git ls-remote` e `git log`. O relatório diz também a ordem das fusões: CORR7, CORR8,
CORR9.

### N6 — O enquadramento das três corridas: FEITO
- O relatório diz agora, no ponto 2 do «leia primeiro» e no §7: «uma corrida original (a da ORDEM-PROVAS-MAPA, 20/11)
  e duas re-corridas no mesmo PC, na mesma sessão, com o mesmo Godot e o mesmo Node». Acrescenta: «não são três
  confirmações independentes: provam que a prova é determinística neste PC, não que se repete noutra máquina».
- Uma nota no topo do relatório lista as frases mudadas. Cada uma está marcada «[CORR9-C …]».

## CI — VERIFICADO (na ponta `a588a2e`)
- **Testes dos rascunhos, run 44872875410:** 8 de 9 jobs verdes (protocolo, servidor, godot-cliente, validador-glb,
  cliente, foto-mestre, motor-real e ponta-a-ponta).
  - O `retoma-pc` está vermelho, com `CLONE DIFERENTE: rascunhos/cliente/cenas/arena/ferramentas/provar_terreno_servidor.gd`.
  - É a mesma falha da base (run 44862505065) e da ponta anterior (44870256933), e era o esperado.
- **Sonda de privacidade, run 44872875426:** verde.
- O job `provas-mapa` não está neste CI, porque o patch não foi aplicado (regra da ordem).

## O que não se fez (regras da ordem)
- Não apliquei nem empurrei o patch do CI.
- Não mudei o `|| true` dos outros jobs (S2).
- Não repeti a reparação das listas.
- Não corri as provas outra vez.
- Não verifiquei o SHA do Godot (N1).
- Não fiz nenhuma fusão.

## Nota de execução
- Trabalhei no clone que já existia, `ordem-provas-mapa-corr9/repo`, no mesmo ramo. Não fiz clone novo na sede.
- Os `.uid` que o `--import` gerou antes continuam fora dos commits.
- Na sede há uma cópia deste ficheiro e outra do patch novo.
