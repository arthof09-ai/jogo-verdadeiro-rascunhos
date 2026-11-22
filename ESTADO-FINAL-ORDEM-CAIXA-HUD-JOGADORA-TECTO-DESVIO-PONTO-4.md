# ESTADO FINAL — ORDEM CAIXA-HUD-JOGADORA-TECTO-DESVIO-PONTO-4 (Claude conta 2, PC · 22/11/2026)

Ordem: fechar o D1 da conferência da MEDICAO-8-FIGURAS, pôr uma guarda no ponto 4 (a faixa continua centrada). Classe GUARDA.
Base: `fable/integracao-50` @ `4f3b5d8` (a ponta à hora do lançamento). Trabalho directo na linha, sem ramo lateral.
Este ficheiro não leva nomes verdadeiros nem o valor de nenhum PIN.

## 1. Os pontos

### B1: o tecto do desvio, por resolução. FEITO.
- `rascunhos/cliente/testes/caixa_jogadora.gd` §8, em `_medir_8`, logo a seguir à linha `REGISTO (não conta)`:
  `_ok(desvio_centro <= tecto, "... não piora (... ≤ tecto ...; não pior que hoje)")`, com o tecto tirado de
  `TECTO_DESVIO_8 = {844×390: 539.0, 780×360: 576.0, 1920×1080: 350.5}`.
- Comentário no código e no cabeçalho: «não pior que hoje». É um tripwire, não a fasquia; a fasquia do critério
  continua ≤ 1 u; quando o EXPANDE entrar, o tecto actualiza-se com a nova medição.
- A linha `REGISTO (não conta)` e as linhas `MEDIDA` ficam como estavam. Os §1–§7 não mudaram.
- Commit `762088f`.

### B2: a variante estrita reproduz 33/36, a partir de código versionado. FEITO.
- A variante está **no mesmo ficheiro cometido**, atrás de uma opção: `-- --estrita`
  (`OS.get_cmdline_user_args()`). Com ela, o ponto 4 conta com a fasquia do critério (`centrada`, ≤ 1 u) **em vez** do
  tecto. Sem ela (é assim que o CI corre), conta o tecto. Assim a variante é código versionado e o CI fica verde.
- Corrida a partir do commit `762088f`, sem mudanças locais:
  `godot --headless --path rascunhos/cliente -s res://testes/caixa_jogadora.gd -- --estrita`
  → **33 de 36, rc 1.** As 3 `FALHA` são o ponto 4 em 844×390 (539,0 u), 780×360 (576,0 u) e 1920×1080 (350,5 u).
  Log: `provas/ordem-caixa-hud-jogadora/tecto-desvio-ponto-4/variante-estrita.log`.

### B3: nova corrida, logs cometidos, CI. FEITO (o CI fica no §4).
- Godot 4.7.2 do PC (`Godot_v4.7.2-stable_win64.exe`, `4.7.2.stable.official.ed1daf0bf`), `--headless`, sem GPU.
  Primeiro `--import` do cliente (rc 0). Depois o teste, do commit `762088f`.
- **Teste com o tecto (como o CI): 36 de 36, rc 0**, 0 linhas com `FALHA`, `ERROR` ou `WARNING`. Log: `corrida-tecto.log`.
- **Extra, a sensibilidade:** o tecto 1920×1080 posto em 350,0 (era 350,5) só no ficheiro local, sem commit, e reposto logo a
  seguir (`git status` limpo depois). Resultado: **35 de 36, rc 1**, falha só esse tecto. Mostra que o tripwire dispara
  quando o desvio passa o tecto. Log: `sensibilidade.log`.
- **Os números não mudaram.** As linhas `MEDIDA` e `REGISTO` das 3 corridas são iguais, byte a byte, às do
  `medicao-8-figuras/corrida-2-final.log`. Por isso a `medicao-8-figuras/TABELA.md` **ficou como estava**.
- Pasta nova `provas/ordem-caixa-hud-jogadora/tecto-desvio-ponto-4/`: `CRITERIO.md`, `TABELA.md` e os 3 logs.
- **Não toquei na caixa:** `hud/caixa_ordem.gd`, `hud/ordem_turnos.gd`, `hud/retratos.gd`, `dados/apresentacao.gd` e
  `.github/workflows/*` ficaram intactos. O transbordo do ponto 4 não foi corrigido (é o EXPANDE).

## 2. A prova: os números por resolução

| Resolução | Desvio medido (u) | Tecto (u) | Tecto | Fasquia ≤ 1 u (estrita) | Margens esq / dir (u) |
|---|---|---|---|---|---|
| 844×390 | 539,0 | 539,0 | passa | falha | 126 / 1204 |
| 780×360 | 576,0 | 576,0 | passa | falha | 136 / 1288 |
| 1920×1080 (controlo) | 350,5 | 350,5 | passa | falha | 77 / 778 |

| Corrida | Resultado |
|---|---|
| `--import` do cliente | rc 0 |
| `variante-estrita.log` (B2, `-- --estrita`) | **33 de 36**, rc 1; as 3 falhas são o ponto 4 nas 3 resoluções |
| `corrida-tecto.log` (B3, como o CI) | **36 de 36**, rc 0 |
| `sensibilidade.log` (tecto 1920×1080 em 350,0, não cometido) | 35 de 36, rc 1; falha só esse tecto |
| linhas `MEDIDA` / `REGISTO` contra a MEDICAO-8-FIGURAS | iguais byte a byte |
| conferidor estrito (`conferir-registo.mjs`), alargado e antigo: o teste, os 3 logs, `CRITERIO.md`, `TABELA.md` | **0 / 0 achados** |
| conferidor estrito neste ESTADO-FINAL, alargado e antigo | 0 / 0 achados |

Na 1.ª redacção da `TABELA.md`, o conferidor deu 5 achados (pedaços de 4 a 6 letras de palavras correntes, 0
inteiros). Reescrevi 3 linhas, sem mudar nenhum número, e ficou 0 / 0.

## 3. Pontos para o coordenador
1. **A contagem: 36/36, não 33/33.** A ordem escreveu «33/33 com tecto». Mas o tecto é uma verificação nova, 1 por
   resolução. O teste publicado passa então a ter 18 + 3 × 6 = **36** verificações: as 33 de antes, todas iguais e a
   passar, e mais os 3 tectos. Na variante estrita a fasquia toma o lugar do tecto, e o total também é 36 (33 passam).
   Li o critério como «o tecto passa hoje, sem falhas». Está anotado no `CRITERIO.md`.
2. **A variante estrita é uma opção, não um ficheiro à parte.** `-- --estrita` no mesmo `caixa_jogadora.gd`. Assim a
   variante não diverge do teste publicado, e quando o EXPANDE entrar basta correr com a opção: se der 36/36, é a hora
   de passar a fasquia a contar e de actualizar (ou tirar) o tecto.
3. **O tecto é exacto, sem margem.** Hoje o desvio é igual ao tecto (539,0 / 576,0 / 350,5) e a comparação é `<=`.
   Os desvios são meios inteiros, por isso não há ruído de vírgula flutuante. Mas qualquer mudança que piore a
   centragem, mesmo em 0,5 u, põe o CI vermelho. É o que a ordem pede («não pior que hoje»), e a `sensibilidade.log`
   mostra-o.
4. **Fora do território, por regra da casa:** o `actualizar-listas.py` mudou a linha SHA-256 do `caixa_jogadora.gd` em
   `retoma-i0004/depois.txt` e em `MANIFESTO-SHA256.txt` (§4). É o que o job `retoma-pc` do CI exige.

## 4. Commits, listas e CI
- **`retoma-i0004/actualizar-listas.py`**, corrido na raiz do repo depois dos 2 commits do teste e das provas:
  «antes.txt: 37 · depois.txt: 415 · MANIFESTO: 459 ficheiros (0 novos, 0 tirados nesta passagem)», rc 0.
  Mudou 1 linha nos dois ficheiros: a do `caixa_jogadora.gd` (`59aa1fbb…` → `0af2deff…`).
- **Commits, directamente na linha `fable/integracao-50`:**
  - `762088f`: o teste (B1, com a opção `--estrita`);
  - `48855ed`: a pasta de provas (B2/B3);
  - `7d1e007`: as listas da retoma e este ESTADO-FINAL;
  - `411088e`: só o §5 deste ficheiro.
  Antes de publicar: `fetch` e `rebase` sobre a ponta. A ponta continuava em `4f3b5d8`: nada a rebasear, nenhum
  conflito. Depois do 3.º commit, o `actualizar-listas.py` voltou a dar 0 novos, 0 tirados, sem mudanças.
- **Publicado:** push `4f3b5d8..411088e -> fable/integracao-50`. `git ls-remote`: `fable/integracao-50` =
  `411088ed7edefdb91e9e980fe2abe2ff09c9d850`.

## 5. CI verificado no `411088e`
- No `411088e`: **Testes dos rascunhos success** (run 45072712870) e **Sonda de privacidade success**
  (run 45072712836) — 11/11 check-runs.
- No `7d1e007` também estava verde: Testes run 45072371443 e Sonda run 45072371545.
- No job `cliente`, o `caixa_jogadora.gd` dá **36 de 36**. As 3 linhas do tecto passam com os mesmos números do PC
  (539,0 / 576,0 / 350,5 u).
- §5 actualizado no commit documental da conferência (F1) para citar o CI da ponta `411088e`.
