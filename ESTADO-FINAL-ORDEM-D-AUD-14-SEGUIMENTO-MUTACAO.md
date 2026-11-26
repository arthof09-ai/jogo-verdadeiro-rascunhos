# ESTADO-FINAL — ORDEM-D-AUD-14-SEGUIMENTO-MUTACAO (a prova de disparo do teste da largura passa a correr no CI)

**Estado: FEITA, com o passo do workflow por publicar.** B1 e B2 estão feitos. O guião do B1 está cometido e
ensaiado. O passo do CI que o chama vai no **último commit, que fica só local**: o token desta máquina não tem o âmbito
`workflow` (§5). Enquanto o coordenador não o publicar, o CI ainda não corre a mutação.

- **Executor:** Claude (opus), conta 2, PC do Pierre (DESKTOP-335QQAS). É a retoma da ordem de 24/11, porque o PC do
  cunhado está inalcançável. **Data:** 25/11/2026 (-03).
- **Linha:** `fable/integracao-50`, trabalho directo. A ponta de partida `1acf825` foi confirmada no clone antes de
  qualquer mudança. A `main` não foi tocada.
- **Commits (empurrados):**
  - `993402d` — B2, o teste;
  - `6b28532` — listas da retoma;
  - `b054044` — B1, o guião e as provas locais;
  - o commit deste ESTADO-FINAL, com o README das provas, as suites e o remendo;
  - a nota do CI.
- **Commit por publicar:** o do `testes.yml`, sozinho, por último (§5).
- **Não toquei** na regra da largura (45 %, coluna 1, tecto de 85 %) nem no `mestre.gd`: este só é mutado na cópia de
  trabalho, e reposto. Também não toquei na posição da caixa (ponto 5), na C-6 e no «na vez», no servidor, nos dados,
  na `main` nem no cliente da jogadora. Os 55 % e a coluna 1 continuam na decisão pendente do Mestre (sentença 805, C).

## 1. B1 — o passo de mutação no CI

**O guião:** `provas/ordem-d-aud-14-seguimento-mutacao/ferramentas/mutacao-largura.sh` (`b054044`), no molde do
`mutacao-celulas.sh` da CAIXA-JANELA-CI.

- **A mutação:** na cópia de trabalho, troca a linha
  `_abas.get_tab_bar().minimum_size_changed.connect(_ao_mudar_barra_abas)` do `mestre.gd` por um `pass`. Isto tira a
  correcção do `7c65fb8`.
- **O que exige:** corre o `medir_mestre.gd` e exige
  - rc = 1;
  - **exactamente 4 falhas**, uma de cada verificação do bloco da D-AUD-14;
  - `ecrã do Mestre: 4 falha(s), 0 sem medida`;
  - 0 erros de script.
- **No fim:** repõe o ficheiro e confere o `git diff` vazio.
- **As guardas e a trap** são as do precedente. Aceita CRLF e LF.

**No workflow** (job `cliente`, commit por publicar; o mesmo diff está em
`provas/ordem-d-aud-14-seguimento-mutacao/remendo-ci-testes.yml.patch`):

1. Ao passo «Ecrã do Mestre em ecrãs baixos» somam-se duas guardas, que exigem estas linhas exactas:
   - `ecrã do Mestre: 0 falha(s), 0 sem medida`;
   - `MEDIDA MESTRE-LARGURA (1600, 900) directo=864 px depois de (800, 450)=864 px`.

   É o lado «com a correcção, 0 falhas, 864 px nos dois percursos» da aceitação.
2. Passo novo, logo a seguir: **«O teste da largura do Mestre dispara — sem a correcção, na cópia de trabalho, sem
   commit (tem de dar as 4 falhas da D-AUD-14)»**.
   - Corre o guião, lê o código pelo `PIPESTATUS` e confere com `git diff --exit-code` que o `mestre.gd` ficou reposto.
   - Leva `if: always()`.
   - Os resultados vão para o artefacto `largura-mestre`.

| | com a correcção | sem a correcção (mutação) |
|---|---|---|
| falhas do `medir_mestre.gd` | **0** (saída 0) | **4**, as do bloco D-AUD-14 (saída 1) |
| tabuleiro a 1600×900, directo / depois de 800×450 | **864 / 864 px** | 880 / 712 px |
| folha (u.): directo · 800×450 · depois | 883 · 1231 · 883 | 864 · 943 · 1066 |
| guião `mutacao-largura.sh` | — | **MUTACAO APANHADA**, saída 0 |

Os números sem a correcção são, linha a linha, os do `logs/antes/medir-mestre-sem-correccao.log` da D-AUD-14-LARGURA.
A prova que só existia em cópia de trabalho reproduz-se agora a partir do `b054044` cometido, e no CI quando o passo
for publicado.

**Ensaios** (todos no PC, Godot 4.7.2 `--headless`):

- o guião na cópia CRLF: APANHADA, saída 0;
- dois controlos, ambos com saída 1:
  - um «Godot» que não falha (o caso de o teste deixar de disparar): NAO APANHADA, com o ficheiro reposto;
  - o `mestre.gd` já sujo: PARAR, sem lhe tocar;
- os **corpos exactos dos dois passos**, tirados do `testes.yml` com PyYAML, corridos com `bash -e` como no runner,
  num clone LF (`core.autocrlf=false`): os dois deram saída 0. Ficam em `logs/ensaio-passos/`.

## 2. B2 — `_folha_pedida` endurecido (feito)

`993402d`, só em `rascunhos/cliente/testes/medir_mestre.gd`.

- **Literais:** a regra deixou de se ler do objecto. `FRACAO_FOLHA = 0.45` e a letra de cada janela, `FONTE_JANELA`,
  são literais: 22 a 1600×900, 32 a 800×450, 114 a 220×220 e 22 a 2400×900.
- **A regra inteira:** o `_folha_pedida` aplica agora a regra completa, com o ramo `_encolhida` e o piso final.
- **O que continua ao vivo:** só o mínimo da barra das abas, que é o que o teste mede.
- **Os textos da D-AUD-14:** os quatro não mudaram.

| verificação nova | valor (PC = CI Linux) | mutação local que a faz falhar |
|---|---|---|
| a letra é a congelada (5×) | 22, 32, 22, 114, 22 | — |
| 1600×900 encolhida: coluna 1 + 2 margens | 330 = 330 u. | ramo com 3 margens → `341 = 330` |
| 220×220: o piso final liga (guarda) | 1710 > 1632 u. | — |
| 220×220: a folha fica no piso | 1710 = 1710 u. | sem o `maxf` do piso → `1632 = 1710` |
| 2400×900: mandam os 45 % (guarda) | 1296 > 883 u. | — |
| 2400×900: a folha é os 45 % | 1296 = 1296 u. | `FRACAO_TABULEIRO := 0.60` → `1152 = 1296` |

Cada mutação dá 1 falha, a da sua verificação: `provas/…/logs/b2/`.

**A janela 2400×900 não estava na ordem.** Juntei-a porque nas janelas da D-AUD-14 manda sempre a barra das abas. A
fracção congelada não se via: com 0.60, o teste dava 0 falhas sem esta janela, como mostra
`logs/b2/mutacao-fracao-antes-da-janela-larga.log`. As guardas «liga» e «mandam» garantem que, se a regra mudar, cada
janela continua a exercer o ramo que diz cobrir.

Nenhuma verificação nova depende da cache da barra. Por isso a mutação do B1 continua a dar **as mesmas 4 falhas**,
medido.

## 3. Suites

PC, Godot 4.7.2 `--headless`, ponta `b054044`. Logs em `provas/ordem-d-aud-14-seguimento-mutacao/logs/suites/`.

| suite | resultado |
|---|---|
| `rodar_testes.gd` | 333 de 333 |
| `abrir_scripts.gd` | 113 scripts, 0 falhas |
| `abrir_clareira.gd` | 22 de 22 |
| `medir_painel_config.gd` | 0 falhas, 0 sem medida |
| `abrir_mestre.gd` | 67 de 67 |
| `pecas_mestre.gd` | 332 de 332 |
| `medir_mestre.gd` | 0 falhas, 0 sem medida (com o B2) |
| `hud_acoes.gd` | 70 de 70 |
| `caixa_jogadora.gd` | 70 de 70 |
| `caixa_janela.gd` | 123 de 123 |
| `canario_privacidade.gd` | 10 de 10 |
| `teste_relato_caixa.gd` | 31 de 31 |
| `teste_nomes_relato.gd` | 26 de 26; o redigido é igual byte a byte ao registo limpo da COBERTURA-CORRECOES-6 |

Nenhum `SCRIPT ERROR`, `Parse Error` nem `Compile Error`. Alguns números diferem dos da D-AUD-14-LARGURA
(`abrir_scripts` 112 → 113, `pecas_mestre` 329 → 332, `hud_acoes` 50 → 70). Vêm de ordens já entradas entre o
`93853dd` e o `1acf825`, porque esta ordem só mexeu no `medir_mestre.gd`. A validação contra os schemas e as suites
node ficam com o CI.

**CI** (Linux), no `b054044`: **Testes dos rascunhos** `45743647684` success, com os 10 jobs verdes, e **Sonda de
privacidade** `45743647709` success. O mesmo resultado no `6b28532` (Testes `45743345980`, Sonda `45743346228`).

No log do `cliente` do `6b28532` aparecem as verificações novas do B2 com os mesmos valores do PC (330, 1710, 1296), e
`MEDIDA MESTRE-LARGURA (1600, 900) directo=864 px depois de (800, 450)=864 px` e `ecrã do Mestre: 0 falha(s), 0 sem
medida`. O passo da mutação ainda não aparece, porque está no commit por publicar.

## 4. Listas da retoma

`py -3 retoma-i0004/actualizar-listas.py` depois do `993402d`: 0 novos, 0 tirados; só mudou o hash do
`medir_mestre.gd` → `6b28532`. Os commits seguintes não mudam ficheiros em `rascunhos/`.

## 5. O commit do workflow (para o coordenador)

O token desta máquina (conta arthof09-ai) tem só `gist`, `read:org` e `repo`, sem `workflow`. O push de um commit que
mexa em `.github/workflows/` é recusado, como na CAIXA-JANELA-CI.

**O commit:**

- Fica local, sozinho e por último, em cima da nota do CI.
- Muda só `.github/workflows/testes.yml`: 24 linhas acrescentadas e nenhuma tirada.
- O blob do ficheiro passa de `e76ff2b` a **`15c83c4`**.
- O patch-id (`git patch-id --stable`) é **`46a3fab3c0f2`**.
- O hash do commit vai no relatório da retoma: não pode estar neste ficheiro, porque o commit é filho deste.

**Se o commit se perder,** o remendo `provas/ordem-d-aud-14-seguimento-mutacao/remendo-ci-testes.yml.patch` dá o mesmo
blob: `git apply` na ponta.

**Depois do push,** a run do job `cliente` deve mostrar:

- no passo «Ecrã do Mestre em ecrãs baixos», as duas guardas novas a passar;
- no passo novo, `MUTACAO APANHADA: 4 falhas, as quatro do bloco D-AUD-14`;
- o artefacto `largura-mestre`.

**Só então** fica cumprido o ponto da aceitação «o CI corre o teste novo contra o `mestre.gd` sem a correcção».

## Critérios da ordem

- [x] B1: o passo de mutação está escrito, cometido (o guião) e ensaiado como no runner. Exige as 4 falhas e saída 1.
  **Falta a publicação do commit do workflow (§5).**
- [x] Com a correcção, 0 falhas e 864 px nos dois percursos. No CI já se vê; a guarda que o exige vai no mesmo commit.
- [x] B2 feito: a fracção e a letra estão congeladas, e o piso final e o ramo `_encolhida` estão cobertos. Cada
  cobertura tem a mutação que a faz falhar.
- [x] Suites verdes no PC; CI verde (Testes + Sonda) no `b054044`.
- [x] O ESTADO-FINAL e as provas (README e logs) estão escritos; as listas da retoma estão sincronizadas.

## Nota

O commit `993402d` saiu com o autor `arthof09-ai <…noreply…>`, o do `7c65fb8`, porque o clone não tinha identidade.
Os restantes saíram com `Claude Pierre C2`, a identidade das ordens anteriores desta máquina. Não reescrevi o `993402d`,
que já estava empurrado.
