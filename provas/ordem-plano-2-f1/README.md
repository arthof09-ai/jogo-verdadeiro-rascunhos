# Provas da ORDEM-PLANO-2-F1 — a batalha que se vê (D-AUD-05, D-AUD-12, D-AUD-15)

Estado: **PARCIAL** (ver `ESTADO-FINAL-ORDEM-PLANO-2-F1-PARCIAL.md` na raiz). Falta a batalha de bancada **com vídeo dos dois
ecrãs na ponta actual**: precisa da janela do PC, e a janela estava fechada na retoma de 26/11.

| Pasta / ficheiro | O que prova | Código |
|---|---|---|
| `suites.sh` | O guião das suites e das 3 mutações (padrão B3: ficheiro mutado, log com o comando e o diff, reposto com `git checkout`). | — |
| `suites/` | Os logs das suites e das mutações; `suites/resumo.txt` tem os exits e as contagens. | a ponta `279f0d7` + o caso 10 do `camera_segue` |
| `dados/dados-justos.md`, `.json` | D-AUD-15: reprodução 6/6 da sequência registada e a distribuição das faces em N = 2 000 000 × 2 séries. | a ponta (26/11) |
| `dados/dados-26-11.log` | A saída inteira da corrida de 26/11, com a linha `# comando:`. | a ponta (26/11) |
| `dados/24-11/` | A mesma corrida em 24/11, sobre o journal da auditoria (a série 1..N é igual byte a byte à de 26/11). | `4739849` |
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
