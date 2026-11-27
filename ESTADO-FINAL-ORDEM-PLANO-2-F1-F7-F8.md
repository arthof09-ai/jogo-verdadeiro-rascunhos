# ESTADO FINAL — ORDEM-PLANO-2-F1 · F7 (prosa do README das provas) + F8 (detector de canários)

Linha `fable/integracao-50`, sem fusão. 26/11/2026, 20:41–21:00 -03, PC do cunhado. Origem: a conferência
ORDEM-PLANO-2-F1-F4-F5-F6, **APROVADA COM RESSALVAS — 886/1000**. A sentença não está neste PC
(`~/workspace/conferencias/…` não existe aqui), por isso segui os textos citados na ordem.

**Resumo:** a F7 e a F8 estão feitas, com push. O workflow Testes está verde na ponta `de10b86`, nos 10 jobs. A F8 levou
dois commits. O primeiro (`dd7b1ef`) pôs o Testes vermelho no job `servidor`, porque esse passo corre com `--permission`
e não deixa lançar processos. A correcção (`de10b86`) faz saltar aí os 2 testes do arnês, que correm no job `protocolo`.

## 0. Base e janela do PC

- **Ponta ao arrancar (20:46):** `git fetch` + `git ls-remote` deram `c41b6c7`. Medi-a outra vez antes de cada push.
  Nunca entrou nada de fora entre os meus commits.
- **PC livre:** medi o idle na sessão 1, o ambiente de trabalho real. Usei uma tarefa agendada `/it` com
  `GetLastInputInfo`, que já apaguei. Deu **16 156 s às 20:42**, **16 335 s às 20:45** e **17 195 s às 20:59**,
  sempre a subir. Ninguém tocou no rato nem no teclado durante o trabalho e o Daniel não voltou. Nenhum dos dois pontos
  precisou de ecrã nem de GPU.

## 1. F7 — README das provas (`70169ef`, documental, sem nova corrida)

Em `provas/ordem-plano-2-f1/README.md`:

- **(a) O protocolo do MC, em prosa:** está na secção nova «O Monte Carlo da corrida4em6 com semente publicada: o
  protocolo», dentro de «D-AUD-15: a leitura que vale». Fixa estes pontos:
  - um único `random.Random(20261126)` para as M tentativas, sem voltar a semear;
  - a face é `randrange(20)`; `randint(1,20)` dá o mesmo;
  - **6 faces por tentativa, sem corte** ao atingir a corrida de 4;
  - a tentativa conta se tiver uma corrida de 4 ou mais;
  - M = 2 000 000;
  - o resultado é **703 → 0,03515 %**, contra o exacto 29/80000 = 0,03625 %.

  Tem também o código em 10 linhas e diz o que **não** serve.
- **Réplica a partir só da prosa:** escrevi-a sem abrir o `recontar.py` e corri-a em Python 3.12.10: **703 → 0,03515 %**.
  Corri também o bloco de código do próprio README: 703. As variantes que o README cita também foram medidas:
  `randint(1,20)` dá 703, `1+int(random()*20)` dá **717** e o corte ao atingir a corrida dá **735**. Ou seja, os pontos
  «sem corte» e «randrange» mudam o número, e a prosa fixa-os.
- **(b) A nota «Veredicto»:** a nota do topo e a secção D-AUD-15 nomeiam agora os **três** ficheiros:
  `dados/dados-justos.md` (linha 63), `dados/dados-26-11.log` (linha 65) e `dados/24-11/dados-justos.md` (linha 63).
  A ordem dava a linha 63 só para o 3.º; as outras duas linhas medi-as com grep. Os três ficheiros ficam como saíram:
  `git diff --quiet -- provas/ordem-plano-2-f1/dados` deu 0.

## 2. F8 — detector de canários (`dd7b1ef` + correcção `de10b86`)

- **O que mudou no código:**
  - `rascunhos/servidor/e2e/canarios.mjs` é novo: tem o detector, separado do arnês para se poder testar.
  - `e2e/jogadora-e2e.mjs` passa a usar esse detector em cada mensagem e na rede de trás do fim, que agora confere todas
    as mensagens outra vez, uma a uma, em vez do texto todo junto.
- **(a) A mensagem acusada:** a acusação escreve cada mensagem acusada completa no log, no formato
  `mensagem acusada #i de n (canários, N caracteres): <a mensagem inteira>`. Antes escrevia só o valor do canário.
- **(b) As fronteiras:**
  - Os canários numéricos `7777` e `9137` só casam como **número inteiro**: um valor numérico JSON, ou o inteiro dentro
    de um texto com fronteiras. Não pode ter encostados uma letra, um algarismo, `_`, `-` ou um ponto decimal. Um ponto
    final de frase não bloqueia.
  - Só casam **fora dos campos de id**: `id`, `*Id`, `*Ids`.
  - Os canários de texto continuam a casar em qualquer sítio da mensagem.
- **Testes** (`testes/e2e-canarios.test.mjs`, 6 testes):
  - Há 4 testes puros, com UUID e hex com «9137» em `id`, `*Id` e `*Ids`, as fronteiras e a acusação.
  - Há **2 testes que correm o próprio arnês** contra um servidor WebSocket sintético. No primeiro, um snapshot, um
    recibo e um evento com ids hexadecimais com «9137» passam sem acusação, e depois uma mensagem com `9137` inteiro
    deixa-a **inteira** no stderr, com saída 1. No segundo, só com ids hexadecimais, o arnês não acusa nada.
  - **ANTES**, com o detector velho reposto, os 2 do arnês dão **0/2**: o detector acusa o `ROOM_SNAPSHOT` só por causa
    dos ids, e sem a mensagem.
- **Critério de aceite:**
  - (a) Cumprido: a acusação sintética deixa a mensagem no log.
  - (b) Cumprido: o id hexadecimal com «9137» não dispara o alarme.
  - (c) Cumprido: o Testes do `de10b86`, o run **45913878498**, é **success** nos 10 jobs. No job `protocolo` passaram
    459 de 459, com os 2 do arnês ✔. No job `servidor` passaram 447, falharam 0 e saltaram 12, entre eles os 2 do arnês.
    O `ponta-a-ponta` deu `[jogadora] OK: 23 mensagens, nenhum canário do Mestre` nos dois motores
    (`motor falso=0 · VLAB real=0`).
- **O vermelho pelo meio, dito às claras:** o Testes do `dd7b1ef`, o run 45913439270, falhou no job `servidor` com
  «Access to this API has been restricted. Use --allow-child-process». Corrigi-o no `de10b86` com o mesmo padrão do
  `ordem16-journal-disco`: com `process.permission` sem `child`, os testes saltam e dizem porquê. Por isso a F8 tem dois
  commits e não um.
- **Localmente** (Node 26.13.0): `node --test testes/*.test.mjs` passa 459 de 459. Com o `--permission` do CI dá 7
  falhas, todas por `--allow-net`. Já falhavam antes da F8, porque o Node 26 restringe a rede e o Node 24 do CI não; antes
  da F8 eram 9, com os meus 2. As listas da retoma foram sincronizadas nos dois commits (`actualizar-listas.py`; o
  `retoma-pc` ficou verde).

## 3. Commits (push a cada passo)

| commit | ponto | CI |
|---|---|---|
| `70169ef` | F7: o protocolo do MC + os 3 ficheiros «AFASTADA» | Testes 45913067303 ✔ · Sonda ✔ |
| `dd7b1ef` | F8: o detector (mensagem acusada + fronteiras), os testes, as listas | Testes 45913439270 ✘ (job `servidor`, `--allow-child-process`) · Sonda ✔ · Aparelhos ✔ |
| `de10b86` | F8 (correcção): os testes do arnês saltam no passo `--permission` e correm no `protocolo` | **Testes 45913878498 ✔ (10/10)** · Sonda 45913878576 ✔ · Aparelhos a correr quando escrevi isto |
| este | o ESTADO-FINAL | — |

O F1, o F2 e o F3 da `ordem-plano-2-f1-fecho-video.md` não eram desta ordem e não lhes mexi. O commit F3 2/2
(`b54ba87`, `testes.yml`) continua pendente do âmbito `workflow`.
