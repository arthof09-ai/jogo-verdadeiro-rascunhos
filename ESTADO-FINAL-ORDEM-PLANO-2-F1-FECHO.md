# ESTADO FINAL — ORDEM-PLANO-2-F1-FECHO · F4 (correcções documentais) + F5 (D-AUD-15 endurecido) + F6 (PANORAMA)

Dono: Muse (CM-000009). Linha `fable/integracao-50`, sem fusão. 26/11/2026, PC do cunhado. **Sem corrida nova**: não houve
bancada nem nova corrida da ferramenta com 2M.
Sentença de origem: a conferência da retoma da F1, **APROVADA COM RESSALVAS (entrega parcial), 817/1000**, follow-ups
F4–F6. Este ESTADO-FINAL não fecha a F1 inteira: a batalha de bancada na ponta, com vídeo, continua por fazer
(`ESTADO-FINAL-ORDEM-PLANO-2-F1-PARCIAL.md` §5).

## 0. Base

`git fetch` + `git ls-remote` ao arrancar: `fable/integracao-50` →
`c169e6c44a576a1a7837dccfcb40c1ec623a2829` (a nota do CI da ADENDA). Fiz um clone novo dessa ponta.

## 1. F4 — correcções documentais

As cinco correcções valem para este ESTADO-FINAL e foram escritas também no `ESTADO-FINAL-ORDEM-PLANO-2-F1-PARCIAL.md` e no
`provas/ordem-plano-2-f1/README.md`, cada um com uma nota no topo que as lista.

| | Antes | Agora (texto da sentença) | Onde está | Conferido |
|---|---|---|---|---|
| (a) | «igual byte a byte» | **as contagens da série 1..N são idênticas; os ficheiros diferem (ms, série CSPRNG, corrida4em6)** | PARCIAL §2.3; README, linha `dados/24-11/` | `cmp`: os dois `dados-justos.json` diferem na linha 64. As 20 contagens, o χ² (31,9714) e o χ² dos pares (455,2544) da série 1..N são iguais. Diferem `ms` (2569 / 1262), as 20 contagens da série CSPRNG e a `corrida4em6` (0,0003525 / 0,00037). |
| (b) | «Suspeita AFASTADA» | **suspeita não confirmada pela barra da ordem (±0,06 pp); χ² p=0,031 e pares p=0,027 na série 1..N ficam registados como sinal amarelo** | PARCIAL §2.3; README, secção «D-AUD-15: a leitura que vale» | O `dados-justos.md` e o `dados-26-11.log` são a saída da ferramenta e ficam como saíram. O README diz que a linha «Veredicto» deles se lê com este texto. |
| (c) | «19 de 19 na ponta», «corrida de dados na ponta» | **`279f0d7` + o caso 10** (o caso 10 é o `4caa2f1`, cometido depois das corridas) | PARCIAL §2.1 e o título do §2.3; README, as linhas `suites/`, `dados-justos` e `dados-26-11.log` | `dados-26-11.log`, linha 2: `# commit: 279f0d71… (+ o teste da câmara por cometer…)`; `resumo.txt`, linha 1: `# commit: 279f0d71…`. |
| (d) | `resumo.txt`: `d-aud-12-SEM-ORDINAL … falhas=11` | **o contador de falhas conta testes falhados, não linhas `✖`: o SEM-ORDINAL falha 5, não 11** | `suites/resumo.txt` (agora `falhas=5`, com uma linha `#` que o explica); `suites.sh` (função `falhas`); PARCIAL §3; README, as mutações | No log há 11 linhas `✖`: os 5 testes, o cabeçalho `✖ failing tests:` e os mesmos 5 repetidos. O node diz `ℹ fail 5`. O contador novo, corrido sobre os logs de 26/11, dá SEM-ORDINAL 5, SEM-FOCO 1, SEM-SEGUIR 4, servidor 0 e camera_segue 0. |
| (e) | o `servidor.log` sem menção no pacote | **o `servidor.log` (446/446) está no pacote de provas** | `provas/ordem-plano-2-f1/suites/servidor.log`, versionado desde o `5227011`; o README e o PARCIAL §3 citam-no agora | `ℹ tests 446 · ℹ pass 446 · ℹ fail 0`, 456 linhas, SHA-256 `008d5428325c52b2f2af7177cf8cb7b8b3e26b4addb8479232d3e516b2816f61`. |
