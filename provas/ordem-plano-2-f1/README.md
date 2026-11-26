# Provas da ORDEM-PLANO-2-F1 — a batalha que se vê (D-AUD-05, D-AUD-12, D-AUD-15)

> **Corrigido no fecho (ORDEM-PLANO-2-F1-FECHO, F4, 26/11):** as cinco correcções da sentença da retoma estão no texto
> abaixo e em `ESTADO-FINAL-ORDEM-PLANO-2-F1-FECHO.md`. Três ficheiros são saída da ferramenta e ficam como saíram:
> `dados/dados-justos.md` (linha 63), `dados/dados-26-11.log` (linha 65) e `dados/24-11/dados-justos.md` (linha 63).
> A linha «Veredicto: suspeita AFASTADA» de cada um dos três vale como se dissesse o texto da secção
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
| `dados/recontar/` | F5 do fecho: a tabela 20×20 dos pares seguidos da série 1..N, as 20 contagens, a corrida4em6 exacta (29/80000) e um Monte Carlo com semente publicada. Tem o recontador sem a ferramenta nem o motor e a verificação por leitura de `vlab-completo.js:788-801`. Ver o `README.md` da pasta. | — |
| `dados/registados-auditoria.json` | Os 6 ataques (seq, semente, faces e recibo) tirados do journal da auditoria em 24/11. O journal privado saiu do disco nas limpezas; a ferramenta lê-os com `--registados`. | — |
| `ferramentas/dados-justos.mjs` | A ferramenta do D-AUD-15 (o caminho real do ataque: `criarSala` → `ROOM_INTENT atacar` → `Vlab.resolverAtaque`). | — |
| `ci/passo-camera-segue.patch` | O passo do `camera_segue` para o `testes.yml`. Espera **N de N genérico**: exactamente uma linha final `N de N verificações passaram.`, os dois N iguais e > 0, lidos do próprio teste (sem número cravado); o log vai para o artefacto `camera-segue`. Os 5 casos da guarda estão em `ci/guarda-n-de-n/`. Aplicado ao `testes.yml` na ORDEM-PLANO-2-F1-FECHO-VIDEO (ver o ESTADO-FINAL dessa ordem). | — |
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
- **Os três ficheiros com a linha «Veredicto: suspeita AFASTADA»** lêem-se com o texto desta secção, e não com a palavra
  «AFASTADA»: `dados/dados-justos.md` (linha 63), `dados/dados-26-11.log` (linha 65) e `dados/24-11/dados-justos.md`
  (linha 63). Os três são saída da ferramenta e ficam como saíram (ORDEM-PLANO-2-F1-F7).

### O Monte Carlo da corrida4em6 com semente publicada: o protocolo

O `dados/recontar/recontar.py` faz esta conta, mas não é preciso lê-lo. Este é o protocolo, para quem o quiser replicar
noutra máquina:

1. **A pergunta.** Em 6 lançamentos de um d20 justo, qual é a probabilidade de aparecer uma corrida de 4 ou mais faces
   iguais seguidas? Por exemplo, 7, 12, 12, 12, 12, 3. Seis faces iguais também contam.
2. **O gerador.** É o `random.Random` de Python (Mersenne Twister), criado **uma só vez** com a semente **`20261126`**
   (a data de 26/11/2026). As M tentativas tiram todas desse mesmo gerador, uma a seguir à outra. Não se volta a semear
   a cada tentativa.
3. **A face.** Cada face é `r.randrange(20)`, um inteiro de 0 a 19. A face do dado é esse número + 1, mas somar 1 não
   altera as corridas. `r.randint(1, 20)` gasta o gerador da mesma maneira e dá o mesmo resultado.
   `1 + int(r.random() * 20)` **não serve**: gasta o gerador de outra maneira e dá outro número (717).
4. **A tentativa.** São sempre **6 faces por tentativa, sem corte**. Tiram-se as 6 mesmo que a corrida de 4 já tenha
   aparecido à 4.ª ou à 5.ª face. Isto importa porque o número de faces tiradas muda o que o gerador dá nas tentativas
   seguintes: parar ao atingir a corrida dá 735, não 703. A tentativa conta como «com corrida» se a maior sequência de
   faces iguais seguidas das 6 tiver 4 ou mais.
5. **O tamanho.** São **M = 2 000 000** tentativas, ou seja, 12 000 000 faces tiradas.
6. **O resultado.** Há **703** tentativas com corrida, e 703 / 2 000 000 = **0,03515 %**. O valor exacto é
   29/80000 = 0,03625 %. A diferença é de 0,0011 pp, menos de 1 σ (σ ≈ 0,0013 pp com este M).

Em Python, o protocolo inteiro cabe nisto:

```python
import random
r = random.Random(20261126); com = 0
for _ in range(2_000_000):
    t = [r.randrange(20) for _ in range(6)]          # 6 faces, sem corte
    corr = maior = 1
    for i in range(1, 6):
        corr = corr + 1 if t[i] == t[i - 1] else 1
        maior = max(maior, corr)
    com += maior >= 4
print(com, 100 * com / 2_000_000)                    # 703 0.03515
```

Fiz uma réplica a partir só desta prosa, sem abrir o `recontar.py`, em Python 3.12.10, a 26/11, e deu 703 → 0,03515 %.
Também corri as variantes dos pontos 3 e 4: `randint(1, 20)` dá 703, `random() * 20` dá 717 e o corte dá 735.
O `randrange` de Python usa o mesmo algoritmo, `_randbelow` sobre `getrandbits`, desde a versão 3.2.
