# Provas — ORDEM-D-AUD-14-SEGUIMENTO-MUTACAO (B1: a mutação da largura no CI; B2: o `_folha_pedida` endurecido)

Godot 4.7.2 (win64, `--headless`), PC do Pierre, 25/11/2026 (-03). Ponta de partida `1acf825`. Seguimento da sentença
805 (D-AUD-14-LARGURA), achados 1 e 4.

## Ferramenta

`ferramentas/mutacao-largura.sh` — a prova de que o teste da largura do Mestre dispara, feita para correr no CI.
É o molde do `provas/ordem-caixa-janela-ci/ferramentas/mutacao-celulas.sh`:

    bash provas/ordem-d-aud-14-seguimento-mutacao/ferramentas/mutacao-largura.sh "$GODOT" <ficheiro-de-log>

Corre na raiz do repositório. Na cópia de trabalho (nunca se comete), troca no `mestre.gd` a linha

    _abas.get_tab_bar().minimum_size_changed.connect(_ao_mudar_barra_abas)

por um `pass`. Isso tira a correcção do `7c65fb8`: sem a ligação, a folha não volta a medir-se quando a letra nova
chega à barra das abas. O resto da correcção fica inerte (`_abas_medidas` é escrito mas ninguém o lê). A seguir corre
`medir_mestre.gd` e exige:

- código de saída 1;
- **exactamente 4 falhas**, uma de cada uma das quatro verificações do bloco da D-AUD-14. Os textos são os mesmos do
  `logs/antes/medir-mestre-sem-correccao.log` da D-AUD-14-LARGURA;
- a linha final `ecrã do Mestre: 4 falha(s), 0 sem medida`;
- 0 erros de script.

Repõe o ficheiro com `git checkout`, mesmo que algo falhe, e confere que o `git diff` ficou vazio. Tal como o
precedente, pára sem tocar em nada se o `mestre.gd` já tiver alterações por cometer, ou se a linha a mutar não
aparecer exactamente uma vez. Aceita CRLF (a cópia do PC, com `core.autocrlf`) e LF (o runner).

A mutação reproduz os números do log de antes da D-AUD-14-LARGURA: `directo=880 px depois de (800, 450)=712 px`, com
folhas de 864/943/1066 unidades em vez de 883/1231/883.

## Passos no CI (`remendo-ci-testes.yml.patch`)

São duas mudanças no job `cliente` do `testes.yml`, que vão num commit à parte, o último (ver o ESTADO-FINAL):

1. No passo «Ecrã do Mestre em ecrãs baixos» entram duas guardas a seguir às que já lá estavam: `ecrã do Mestre: 0
   falha(s), 0 sem medida` e `  MEDIDA MESTRE-LARGURA (1600, 900) directo=864 px depois de (800, 450)=864 px`. Ambas
   usam `grep -xF` sobre o log, depois de passado por `tr -d '\r'`.
2. Passo novo, logo a seguir: «O teste da largura do Mestre dispara — sem a correcção, na cópia de trabalho, sem
   commit (tem de dar as 4 falhas da D-AUD-14)». Corre o guião com `tee`, lê o código do `PIPESTATUS` e faz `git diff
   --exit-code` ao `mestre.gd`. O artefacto `largura-mestre` leva o log e o resumo. Tem `if: always()` e
   `working-directory: ${{ github.workspace }}`, como o passo da `caixa_janela`.

O `testes.yml` com o remendo tem o blob `15c83c4` (antes: `e76ff2b`). O YAML foi lido com PyYAML: os passos ficam
nos índices 10, 11 e 12 do job `cliente`.

## B2 — o teste endurecido (`rascunhos/cliente/testes/medir_mestre.gd`, `993402d`)

O `_folha_pedida(m, janela, encolhida)` deixou de ler `m.FRACAO_TABULEIRO` e `m._fonte` do objecto. Agora usa literais:
`FRACAO_FOLHA = 0.45` e `FONTE_JANELA` = {1600×900: 22, 800×450: 32, 220×220: 114, 2400×900: 22}. Aplica a regra
inteira do `_ao_redimensionar`: os 45 %, a barra das abas, o tecto de 85 %, o ramo `_encolhida` e o piso final. Só o
mínimo da barra das abas continua a ser lido ao vivo, porque é a grandeza que o teste mede. Os quatro textos do bloco
da D-AUD-14 não mudaram, e por isso o guião do B1 continua a contá-los.

Verificações novas:

| verificação | valor (PC e CI Linux, iguais) |
|---|---|
| em cada passo, a letra é a congelada | 22, 32, 22, 114, 22 |
| 1600×900 encolhida: a folha é a coluna 1 + 2 margens (ramo `_encolhida`) | 330 = 330 u. |
| 220×220: o piso final liga mesmo (guarda: coluna 1 + 2 margens > tecto de 85 %) | 1710 > 1632 u. |
| 220×220: a folha fica no piso final | 1710 = 1710 u. |
| 2400×900: mandam os 45 % (guarda: 45 % > o que a barra das abas pede) | 1296 > 883 u. |
| 2400×900: a folha é os 45 % da área (a fracção congelada) | 1296 = 1296 u. |

A janela de 2400×900 não estava na ordem. Entrou porque nas janelas da D-AUD-14 (1600×900 e 800×450) é sempre a
barra das abas que manda, nunca os 45 %. Sem ela, mudar a fracção não fazia o teste falhar: medido, a `FRACAO_TABULEIRO`
0.60 dava 0 falhas antes desta janela (`logs/b2/mutacao-fracao-antes-da-janela-larga.log`, a versão intermédia do teste). Nenhuma das verificações novas depende do mínimo da barra em cache. Por isso,
sem a correcção, continuam a passar, e a mutação do B1 dá as mesmas 4 falhas de antes.

A mutação intermédia foi FRACAO_TABULEIRO 0.55 → 0.60 no mestre.gd; o log mutacao-fracao-antes-da-janela-larga.log correu sob essa mutação e deu 0 falhas, 0 sem medida (saída 0).

As medidas `MEDIDA MESTRE-*` fora do bloco D-AUD-14 variam ±1 px entre PC e CI (tabuleiro 866 vs 867 px a 780×360); as linhas do bloco são byte-idênticas.

## Logs

- `logs/b1/mutacao-largura.resumo.txt` e `mutacao-largura.log` — o guião no PC, na cópia CRLF: **MUTACAO APANHADA**,
  saída 0. O `mestre.gd` ficou reposto.
- `logs/b1/controlos.txt` — dois controlos:
  1. um «Godot» falso que sai 0 sem falhas (o caso de o teste deixar de disparar): **MUTACAO NAO APANHADA**, saída
     1, `mestre.gd` reposto;
  2. o `mestre.gd` já tinha uma alteração alheia: **PARAR**, saída 1, a alteração ficou intacta.
- `logs/b2/com-correccao.log` — o `medir_mestre.gd` endurecido, com a correcção: 0 falhas, saída 0.
- `logs/b2/mutacao-*.log` e `.diff` — três mutações locais do `mestre.gd`, uma para cada verificação nova. Os `.diff`
  mostram a linha mutada. Em todas o ficheiro foi reposto a seguir.
  - `mutacao-sem-piso`: sem o `maxf` do piso final → 1 falha, `(220, 220): a folha fica no piso final (1632 = 1710)`;
  - `mutacao-encolhida`: ramo `_encolhida` com 3 margens → 1 falha, `(1600, 900) encolhida … (341 = 330)`;
  - `mutacao-fracao`: `FRACAO_TABULEIRO := 0.60` → 1 falha, `(2400, 900): a folha é os 45 % da área (1152 = 1296)`.
- `logs/ensaio-passos/` — os corpos exactos dos dois passos, tirados do `testes.yml` com PyYAML e corridos com
  `bash -e` como no runner (sem `shell:`, logo sem pipefail). Correram num clone com `core.autocrlf=false` (LF, como no
  runner), em `rascunhos/cliente` e na raiz, com o `RUNNER_TEMP` numa pasta temporária. Os dois deram saída 0:
  `passo-medir-mestre.out` e `passo-mutacao-largura.out`, e ainda os ficheiros que o passo escreve em
  `$RUNNER_TEMP/largura-mestre/`.
- `logs/suites/*.log` — as 13 suites Godot que o CI corre, na ponta `b054044` (todas saída 0; ver o ESTADO-FINAL §3).
  `redigir-nomes-comparacao.txt` é a comparação byte a byte do canário redigido.

Nos logs, o caminho temporário aparece como `<temp>` e a raiz do repositório como `<raiz>`. Tirei as linhas
`[floresta] pronta em …` (um JSON longo, igual em todas as corridas), como na D-AUD-14-LARGURA.
