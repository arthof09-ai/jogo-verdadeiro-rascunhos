# ESTADO FINAL — ORDEM-CAIXA-JANELA-CI (Claude conta 1, PC · 22/11/2026)

**Linha:** `fable/integracao-50`, trabalho directo, sem ramo lateral e sem fusão. Parti da ponta `a271c6d`. Fiz
`fetch` e `rebase` antes de todos os pushes. A ponta não tinha andado, por isso não houve conflito.

Commits:
1. `02267d1` — o remendo do CI, o guião da mutação, as corridas locais e o ensaio dos passos, com as listas da retoma
   sincronizadas;
2. este ESTADO-FINAL (só documento).

Este ficheiro não tem nomes verdadeiros, nem pedaços deles, nem o valor de nenhum PIN (§5).

## 1. O resultado, em curto

- **O passo novo está escrito e ensaiado, mas não está no workflow da linha.** O GitHub recusou o push do
  `testes.yml`: *«refusing to allow an OAuth App to create or update workflow `.github/workflows/testes.yml` without
  `workflow` scope»*. O token do PC tem só `gist`, `read:org` e `repo`. Fiz como a JANELA-NOMES-CORRECOES: o passo vai
  como remendo, `provas/ordem-caixa-janela-ci/remendo-ci-testes.yml.patch`, e aplica-o o coordenador (§6, ponto 1).
- **Por isso ainda não há nenhum número da `caixa_janela` medido no CI.** Não o vou inventar. O que há:
  - **local, à mão:** 78/78;
  - **o corpo exacto dos passos, corrido no PC como o runner o corre:** 78/78 e, com a mutação, 69/78;
  - **o CI da ponta `02267d1`:** verde, mas sem o passo novo.
- **A prova de disparo funciona:** a mutação dá exactamente as 9 falhas da B6, e o ficheiro fica reposto.

## 2. O passo novo (no remendo)

São três entradas no job `cliente`, logo a seguir à `caixa_jogadora`. Todas têm `if: always()`, como as vizinhas.

1. **«A janela lobby→arena e a caixa com 8, 12 e 16 figuras em ecrãs baixos (Ordem CAIXA-JANELA-CI)»**
   - Corre `timeout 120 "$GODOT" --headless --path . -s res://testes/caixa_janela.gd`, na pasta `rascunhos/cliente`.
     É o mesmo arranque que a casa usa no PC e que o CI já usa para a `caixa_jogadora`, o `hud_acoes` e o
     `canario_privacidade`. **Não precisa de ecrã nem de render:** o `--headless` chega.
   - Usa o Godot e o import que o job `cliente` já faz.
   - Falha em três casos:
     - a suite sai com código ≠ 0, ou seja, há uma verificação falhada (`set -o pipefail` com `tee`);
     - o log tem `SCRIPT ERROR`, `Parse Error` ou `Compile Error`;
     - a suite não chega à linha final `N de N verificações passaram.`, com os dois números iguais. Isto apanha uma
       suite que pare a meio com código 0.
   - Não prendi o número a 78. Se alguém juntar verificações, o passo não deve partir por isso. Todas as runs escrevem o
     número no log e no artefacto.
2. **«A caixa_janela dispara — mutação das células na cópia de trabalho, sem commit (tem de dar as 9 falhas da B6)»**
   - Corre `provas/ordem-caixa-janela-ci/ferramentas/mutacao-celulas.sh` a partir da raiz do repositório.
   - No fim confere que `git diff --exit-code -- rascunhos/cliente/hud/caixa_ordem.gd` está vazio.
3. **`actions/upload-artifact@v4`, com o nome `caixa-janela`**: leva `caixa_janela.gd.log`, `mutacao-celulas.log` e
   `mutacao-celulas.resumo.txt`.

Conferi que o YAML remendado se lê (js-yaml) e que o remendo aplica limpo sobre `02267d1` (`git apply --check`).
SHA-256 do remendo: `27951614462931ad796318d0fbea5c2bc457e64b28e274fd72343cc22adf487b`.

## 3. A prova de disparo

**A mutação** (`mutacao-celulas.sh`) muda só a cópia de trabalho, nunca se comete. Troca uma linha em
`hud/caixa_ordem.gd`:

```
-		slot.custom_minimum_size = celula
+		slot.custom_minimum_size = celula + Vector2(float(id.trim_prefix("f").to_int() % 2), 0.0)
```

Assim as células com id ímpar ficam 1 u mais largas, ou seja, alargam conforme o id.

**O que o guião exige:**
- rc ≠ 0;
- **exactamente 9 falhas, todas do assert B6** («os N slots renderizam com a largura da célula»), uma por medição:
  8, 12 e 16 figuras × 1280×720, 844×390 e 780×360;
- a linha final `69 de 78 verificações passaram.`;
- 0 erros de script.

Repõe o ficheiro com `git checkout`, também quando algo falha (`trap`), e confere que o diff ficou vazio.

**Resultado local:** rc 1, 9 falhas, todas da B6, «69 de 78», 0 erros. O ficheiro ficou reposto.

**Primeira tentativa, que deitei fora:** com +id u (f1 → +1 u, …, f16 → +16 u), a caixa crescia de mais. Com 16 figuras
em 780×360 falhava também a guarda da altura («a caixa não passa de metade da altura», 601 de 1080 u). Isso dava
**10** falhas, por isso baixei para +1 u nos ids ímpares.

**Nota sobre a B6:** o `cj-mutacao.log` da sede da PADRAO-CORRECOES (fora do repo) mostra todas as células com a mesma
largura, +2 u. Essa mutação não variava com o id. A minha varia, e o assert apanha as duas.

## 4. Os números

| corrida | onde | resultado |
|---|---|---|
| `caixa_janela`, à mão | PC (Godot 4.7.2, Windows 11), `local/caixa_janela.gd.log` | **78/78**, rc 0, 0 erros |
| mutação, à mão | PC, `local/mutacao-celulas.log` | **69/78**, rc 1, 9 falhas B6 |
| passo da suite, corpo exacto, `bash -eo pipefail` | PC, `ensaio-passos/` | **78/78**, passo verde |
| passo da mutação, corpo exacto, `bash -e` (o shell por omissão do runner) e `bash -eo pipefail` | PC, `ensaio-passos/` | **69/78**, «MUTACAO APANHADA», passo verde nos dois |
| `caixa_janela` no CI | — | **sem número: o passo não está no workflow** (§1) |
| CI da ponta `02267d1`: Testes dos rascunhos | run **45087490267** | verde, 10/10 jobs (`cliente` e `retoma-pc` incluídos) |
| CI da ponta `02267d1`: Sonda de privacidade | run **45087490221** | verde |
| CI da ponta `ff6d69f`: Testes dos rascunhos | run **45087967745** | verde, 10/10 jobs (`cliente` e `retoma-pc` incluídos) |
| CI da ponta `ff6d69f`: Sonda de privacidade | run **45087967730** | verde |

**Listas da retoma:** corri `retoma-i0004/actualizar-listas.py` antes do commit. Deu 0 novos e 0 tirados (antes.txt
37, depois.txt 416, MANIFESTO 460), o que bate certo: não mudei nada em `rascunhos/`. O `retoma-pc` passou.

**Divergência CI × local:** ainda não se pode medir. Há uma diferença conhecida entre os dois lados: o PC é Windows e o
CI é Linux, e ambos usam o Godot 4.7.2 `--headless`. As medidas da suite são em unidades de layout e não dependem da
GPU. Se o CI der outro número depois de o remendo entrar, essa diferença é o primeiro sítio onde olhar.

## 5. Privacidade: o conferidor estrito nos dois critérios

Conferidor: `provas/ordem-caixa-relato/ferramentas/conferir-registo.mjs`, critério alargado / `--velho`.

| ficheiro | alargado / antigo | nomes inteiros |
|---|---|---|
| este ESTADO-FINAL | **0 / 0** | 0 |
| `README.md`, `remendo-ci-testes.yml.patch`, `ferramentas/mutacao-celulas.sh` | **0 / 0** | 0 |
| `ensaio-passos/passo-suite.sh`, `passo-mutacao.sh`, os dois `mutacao-celulas.resumo.txt` | **0 / 0** | 0 |
| as linhas que o remendo junta ao `testes.yml` (só o `+`) | **0 / 0** | 0 |
| os 4 logs da corrida da suite, sem edição (`local/` e `ensaio-passos/`) | **3 / 2 por log** | **0** |

Os achados dos logs da corrida vêm do texto da própria suite: duas palavras correntes que partilham pedaços com os nomes
verdadeiros. São linhas que a suite imprime e que eu não escrevi. Cabem no padrão aceite para logs da corrida (4/2, 0
inteiros) — isto é, 3/2 **por log**, não no total dos 4 logs (emenda do coordenador, F6 da sentença da CAIXA-JANELA-CI). O `testes.yml` inteiro já tinha 18 achados antes desta ordem; não lhes toquei. No guião, troquei duas
palavras minhas para ele chegar a 0 / 0.

## 6. Pontos para o coordenador

1. **Aplicar o remendo** com o token que tem o âmbito `workflow`:
   `git apply provas/ordem-caixa-janela-ci/remendo-ci-testes.yml.patch`. Depois do push, a run do job `cliente` dá o
   número da `caixa_janela` no CI e o artefacto `caixa-janela`. **Só então fica cumprido o ponto «78/78 no CI»**, que
   esta entrega não pôde fechar. Se der outro número, a diferença mede-se contra os logs de `local/` e
   `ensaio-passos/`, que são as mesmas linhas pela mesma ordem.
2. **No PC não há `python3`** (só o `python.exe` do 3.12, que não está no PATH com esse nome). Por isso o guião da
   mutação usa `sed` e `grep`. No runner Ubuntu os dois existem.
3. **A guarda do fim da suite não fixa 78.** Exige «N de N», e o rc já apanha qualquer falha. Se quiseres que o CI
   prenda o número exacto, basta trocar o padrão por `^78 de 78`. Fica ao teu critério.
4. **A ordem da mutação no job:** a mutação corre depois da suite e repõe o ficheiro antes de os passos seguintes
   correrem. O `git diff --exit-code` do passo garante isso. Os passos que vêm a seguir (relato, nomes, canário,
   arranque) leem o `caixa_ordem.gd` original.

<b>Estado: NOVA</b>
