# Provas da ORDEM-PLANO-2-F1 — a batalha que se vê (D-AUD-05, D-AUD-12, D-AUD-15)

> **Corrigido no fecho (ORDEM-PLANO-2-F1-FECHO, F4, 26/11):** as cinco correcções da sentença da retoma estão no texto
> abaixo e em `ESTADO-FINAL-ORDEM-PLANO-2-F1-FECHO.md`. O `dados/dados-justos.md` e o `dados/dados-26-11.log` são a saída
> da ferramenta e ficam como saíram. A linha «Veredicto: suspeita AFASTADA» deles vale como se dissesse o texto da secção
> «D-AUD-15: a leitura que vale», abaixo. A recontagem sem a ferramenta (F5) está em `dados/recontar/`.

Estado: **PARCIAL** (ver `ESTADO-FINAL-ORDEM-PLANO-2-F1-PARCIAL.md` na raiz). Falta a batalha de bancada **com vídeo dos dois
ecrãs na ponta actual**: precisa da janela do PC, e a janela estava fechada na retoma de 26/11.

| Pasta / ficheiro | O que prova | Código |
|---|---|---|
| `suites.sh` | O guião das suites e das 3 mutações (padrão B3: ficheiro mutado, log com o comando e o diff, reposto com `git checkout`). | — |
| `suites/` | Os logs das suites e das mutações; `suites/resumo.txt` tem os exits e as contagens. Inclui o `suites/servidor.log` (446/446). | `279f0d7` + o caso 10 do `camera_segue` |
| `dados/dados-justos.md`, `.json` | D-AUD-15: reprodução 6/6 da sequência registada e a distribuição das faces em N = 2 000 000 × 2 séries. | `279f0d7` + o caso 10 (26/11) |
| `dados/dados-26-11.log` | A saída inteira da corrida de 26/11, com a linha `# comando:`. | `279f0d7` + o caso 10 (26/11) |
| `dados/24-11/` | A mesma corrida em 24/11, sobre o journal da auditoria. As contagens da série 1..N são idênticas às de 26/11; os ficheiros diferem (ms, série CSPRNG, corrida4em6). | `4739849` |
| `dados/registados-auditoria.json` | Os 6 ataques (seq, semente, faces e recibo) tirados do journal da auditoria em 24/11. O journal privado saiu do disco nas limpezas; a ferramenta lê-os com `--registados`. | — |
| `ferramentas/dados-justos.mjs` | A ferramenta do D-AUD-15 (o caminho real do ataque: `criarSala` → `ROOM_INTENT atacar` → `Vlab.resolverAtaque`). | — |
| `ci/passo-camera-segue.patch` | O passo do `camera_segue` para o `testes.yml` (agora 19 de 19). Fica por aplicar: o token deste PC não tem `workflow`. | — |
| `corrida-23-11/relato-journal.md` | A batalha de bancada de 23/11 (22:04–22:10 -03), **acabada por morte** (3 falhas nos testes de morte), 0 colocações duplicadas, «Lobo 1», «Lobo 2», «Bruto 1». **Sem vídeo** (o gdigrab recusou a área). | `4739849` |
| `corrida-24-11/capturas/` | A 3.ª tentativa (24/11 01:58–02:11 -03), parada na rodada 2 pelo limite semanal: 4 capturas do «na vez» (`c01`, `c30`, jogadora e Mestre). | `e671f49` |
| `corrida-23-11/capturas/` | 11 capturas dessa corrida: arranque (`b03`), depois dos movimentos (`b10`, `b17`), tiro (`b13`), queda (`b18`), «Fim da batalha» na jogadora (`c13`), o fim no Mestre (`d01`, `d02`). | `4739849` |

## As mutações (`suites/resumo.txt`)

| Mutação | Resultado | Leitura |
|---|---|---|
| `camera_segue-SEM-FOCO-NO-EVENTO` (`if _focar_primeira_vez():` → `if false and …`) | 18 de 19 (só falha o caso 10) | Na retoma de 26/11 esta mutação dava **17 de 17** sem o caso 10: o seguir cobria a colocação fora do terço central e o «focar a primeira vez» do evento não tinha teste próprio. O caso 10 põe a colocação dela numa casa que já cai no terço central. |
| `camera_segue-SEM-SEGUIR` (`camera.focar(p)` → `pass`) | 15 de 19 | O seguir é provado pelos casos 5 e 8. |
| `d-aud-12-SEM-ORDINAL` (`return \`${texto} ${fig.ordinal}\`;` → `return texto;`) | 3 pass, 5 fail | O d-aud-12-ordinal morde. |

O contador `falhas=` do `resumo.txt` conta testes falhados, não linhas `✖`: o SEM-ORDINAL falha **5**, não 11. O guião de
26/11 contava as linhas `✖` do log do node, e havia 11: os 5 testes, o cabeçalho `✖ failing tests:` e os mesmos 5 repetidos
no fim. O `resumo.txt` já diz `falhas=5`, e o `suites.sh` passou a ler o `ℹ fail N` do node (F4 do fecho).

## Medidas das capturas de 23/11 (lidas na imagem 1280×720 da jogadora)

| Captura | Figura dela (px, aprox.) | Fracção | Terço central |
|---|---|---|---|
| `b03-jog-arranque.png` | (640, 342) | (0,50; 0,48) | sim |
| `b17-jog-depois-mov2.png` | (640, 352) | (0,50; 0,49) | sim |

O teste `camera_segue` mede o mesmo na arena a sério: «MEDIDA arranque» e «MEDIDA depois do movimento» em `suites/camera_segue.log`.

## «Na vez» da caixa contra o banner (só medir, D-AUD-03)

Medição **preliminar**, não as 20 vezes seguidas pedidas. Nas capturas de 23/11 e 24/11 há as duas coisas: concordância
(`corrida-23-11/capturas/b17-jog-depois-mov2.png`: banner «A sua vez», caixa «Arqueira… na vez») e discordância
(`corrida-24-11/capturas/c01-vez-*` e `c30-vez-*`, 24/11; as 30 amostras dessa noite são todas do mesmo momento da
rodada 2: banner «A sua vez», caixa «Bruto 1 na vez», e o Mestre a dizer «vez de Arqueira de Bancada»). A contagem das
20 vezes seguidas fica para a batalha na ponta.

## D-AUD-15: a leitura que vale (F4 do fecho)

- **A suspeita não é confirmada pela barra da ordem (±0,06 pp).** O χ² p=0,031 e os pares p=0,027 na série 1..N ficam
  registados como sinal amarelo. A série do CSPRNG deu p = 0,592 e p = 0,831.
- A reprodução da sequência registada é 6/6 (10, 18, 18, 18, 18, 19).
- Na série 1..N, as contagens de 24/11 e de 26/11 são idênticas. Os ficheiros diferem (ms, série CSPRNG, corrida4em6).
- A corrida foi sobre `279f0d7` + o caso 10. O servidor e o motor são os da ponta; o caso 10 ainda não estava cometido.
