# ESTADO FINAL — ORDEM CAIXA-RELATO-CORRECOES-2 (Claude conta 1, PC · 21/11/2026)

**Ramo:** `claude1/caixa-relato-correcoes-2` · **base:** `0418d18` (ponta de `fable/integracao-50` no lançamento; não
avançou durante a ordem) · **commit do trabalho:** `7f2adc4` · **não fundido.**

## 1. O que mudou, ponto a ponto

- **B1 (Privacidade D1) — os nomes do relato passam a `nomePublico` e o canário estende-se ao relato (as duas coisas).**
  - `_nome()` (`prova_caixa_jogadora.gd`, `prova_caixa_manequim.gd`) e a linha «bancada: …» de `_jogar_vez()` liam o
    `nome` da vista do Mestre. Agora lêem o `nomePublico` por um ajudante novo, `_nome_publico(f, id)`, que devolve o
    id quando não há nome público. No relato novo lê-se «Bruto» e «Lobo», e não «Bruto de Bancada» nem «Lobo de Bancada».
  - O canário: em cada `_privacidade` (§1, §4, §5), uma verificação nova confere que nenhuma linha do relato escrita até
    ali traz um nome verdadeiro (os que diferem do `nomePublico` na vista do Mestre) e que há pelo menos um canário. Em
    `_fim()`, outra confere o relato inteiro. Só os nomes entram nesta varredura: vida e PA são números pequenos que o
    relato tem por outras razões (coordenadas, seq, revisões), e esses continuam a ser procurados nos textos da caixa,
    como antes. São 4 verificações novas por prova.
  - **Mutação ao vivo:** com `_nome_publico` a ler `nome`, a prova HUD deu **39/43**. As 4 verificações novas falharam,
    com as linhas exactas («Lobo de Bancada na linha 6», …). Reverti a mutação.
- **B2 (Privacidade D2) — o teste varre as 6 linhas.** As duas linhas do caso da hora (`lh1`, `lh2`) entram em `linhas`,
  e a asserção passou a «6 linhas, 5 JSON actual». **Mutação:** uma fuga («nome ») só nas linhas de seq 13 (as do caso
  da hora) dá 22/23 no teste novo e passava **21/21 no teste da base**.
- **B3 (Privacidade D3) — proibidas:** `+ "master", "caixaMestre", "pa"`. O `"pa"` vai sozinho: nenhuma palavra fixa
  da linha o contém, e os ids são hexadecimais. **Mutações:** `(caixaMestre)`, `(master)` e `(PA 3)` na origem da
  linha dão 22/23 cada uma.
- **B4 (Mecânica D1) — a comparação ao píxel tem método cometido e os intervalos foram emendados nos dois sítios.**
  - Script novo: `provas/ordem-caixa-relato/ferramentas/comparar_capturas.gd`. Corre com
    `godot --headless -s … -- <pasta-a> <pasta-b> [--limiar=0.06] [--metodo=canal|soma]` e não precisa de projecto.
    Conta um píxel quando algum canal R, G ou B difere mais de 0,06.
  - Reproduz ao décimo os números da conferência: HUD **43,9 / 36,7 / 35,3 / 35,3 / 36,3 %**; manequim
    **19,0 / 4,7 / 2,4 / 2,6 / 13,5 %** (`provas/ordem-caixa-relato/correcoes-2/comparacao-capturas.log`).
  - Emendas: ESTADO-FINAL-ORDEM-CAIXA-RELATO-CORRECOES §4.2 e README B5 dizem agora **35–44 % / 2–19 %**, com uma nota
    de emenda.
  - **De onde vinham os 54–65 % e 7–38 %:** encontrei o script não cometido do executor anterior
    (`ordem-caixa-relato-correcoes/tmp/comparar.gd`, na sede dele). Contava um píxel quando a **soma** |ΔR|+|ΔG|+|ΔB|
    passava 0,06. Com `--metodo=soma`, o script cometido dá exactamente 54,3–64,9 % e 7,0–37,9 %
    (`correcoes-2/comparacao-capturas-soma.log`).
  - Os «2,7 % no §4» (contra a corrida CAIXA-RELATO das 21:02, cujas capturas estão na pasta tmp da sede, fora do ramo)
    também eram da soma. Pelo método da conferência dão **1,0 %**, e emendei esse número também.
- **B5 (Mecânica D2) — caso da hora.** `OS.delay_msec(20)` em vez de 5. A hora de cada `novo_snap` (HH:MM:SS) tem de
  cair entre `Time.get_time_string_from_system()` (hora local) lida antes e depois da chamada. **Mutação** `bias` → 0
  em `hora_ms()`: **22/23** neste PC (02:01:50 ∉ [23:01:50, 23:01:50]). Reverti a mutação.
- **B6 (Mecânica D3) — um `estado` no §4 do teste** (`{"tipo":"estado","dados":{"figuraId": lobo}}`, depois do
  `dano`, como o do caso vivo). Agora são 7 eventos, 3 de actor, e há uma asserção nova: `actor_do_evento(estado) == ""`.
  **Mutação** «contar `estado` como de actor» em `anotar_evento`: **21/23** (a contagem exacta e a linha do §4).

Ficheiros: `provas/ordem-caixa-relato/ferramentas/{teste_relato_caixa.gd, comparar_capturas.gd (novo)}`,
`provas/ordem-caixa-hud-jogadora/ferramentas/prova_caixa_jogadora.gd`,
`provas/ordem-caixa-manequim/ferramentas/prova_caixa_manequim.gd`, `provas/ordem-caixa-relato/README.md`,
`ESTADO-FINAL-ORDEM-CAIXA-RELATO-CORRECOES.md` (só o §4.2), `provas/ordem-caixa-relato/correcoes-2/` (as corridas).
O `relato_caixa.gd` não mudou.

## 2. Corridas (PC, Godot 4.7.2 Windows `Godot_v4.7.2-stable_win64.exe`; motor VLAB real sha256 `a91c021c…3261`; semente 7) — VERIFICADO

| Corrida | Resultado | Registo |
|---|---|---|
| Teste do relato | **23/23** (eram 21) | `correcoes-2/teste-relato.log` |
| Prova HUD-JOGADORA | **43/43** (eram 39; +4 do canário do relato) | `correcoes-2/cliente-hud/relato.txt` |
| Prova MANEQUIM | **53/53** (eram 49; +4) | `correcoes-2/cliente-manequim/relato.txt` |
| Servidor (`node --test`) | 418/418 | `correcoes-2/suites/servidor.log` |
| Prova da caixa do servidor | PROVA OK | `correcoes-2/suites/prova-caixa-servidor.log` |
| rodar_testes | 290/290 | `correcoes-2/suites/rodar_testes.log` |
| caixa_jogadora / caixa_janela / hud_acoes / canario_privacidade | 18/18 · 69/69 · 50/50 · 10/10 | `correcoes-2/suites/` |
| abrir_scripts | 107 scripts, 0 falhas | `correcoes-2/suites/abrir_scripts.log` |
| Comparação ao píxel | HUD 35,3–43,9 % · manequim 2,4–19,0 % | `correcoes-2/comparacao-capturas*.log` |
| `actualizar-listas` (retoma) | 0 novos, 0 tirados: sem diferenças, porque o ramo não toca em `rascunhos/` | — |

Mutações (todas revertidas, `git status` limpo depois): ver §1. Teste: bias 0 → 22/23; `estado` de actor → 21/23;
`caixaMestre`, `master` e `PA` → 22/23 cada; fuga só nas linhas da hora → 22/23 (a base dava 21/21). Prova viva:
`nome` em vez de `nomePublico` → 39/43.

## 3. Commits e CI

- `7f2adc4` — as correcções B1–B6 e as corridas.
- O commit deste ESTADO-FINAL vem a seguir. CI: ver §5.

## 4. Para o coordenador

1. **Os relatos já cometidos continuam a ter os nomes verdadeiros.** São estes: `provas/ordem-caixa-hud-jogadora/cliente/`,
   `ordem-caixa-manequim/cliente/`, `ordem-caixa-janela/cliente/`, `ordem-caixa-relato/{cliente-hud,cliente-manequim}/`
   e `ordem-caixa-relato/correcoes/…/relato.txt`. Não os reescrevi, porque são o registo do que se viu em cada ordem e
   estão no histórico de qualquer forma. Os nomes são de bancada (fictícios). Se a decisão for limpá-los, é uma ordem
   à parte, e o histórico do git continua a tê-los.
2. **A prova da CAIXA-JANELA (`provas/ordem-caixa-janela/ferramentas/prova_caixa_janela.gd:141`) tem o mesmo `_nome()`**,
   que lê o `nome` da vista do Mestre e por isso põe os mesmos nomes no relato dela. Ficou fora da fronteira desta ordem
   (não usa o relato da caixa) e não lhe mexi. Pede a mesma correcção antes de correr sobre fichas reais.
3. **Mexi outra vez nas duas ferramentas das provas vivas**, fora de `provas/ordem-caixa-relato/`. O B1 vive nelas: é
   lá que o `_nome()` e o canário estão. Também emendei o §4.2 do ESTADO-FINAL da ordem anterior, como o B4 pedia.
   Não toquei em código do jogo, em `rascunhos/`, no HUD nem nas cores.
4. **O B5 só morde fora de UTC.** Os runners do CI são UTC: aí `bias` é 0 e a mutação «`bias` a zero» não se distingue
   da hora certa. A asserção passa nos dois casos, e só um PC com fuso (como este, UTC−3) apanha o defeito. Fica
   escrito para que ninguém conte com o CI para isso.
5. **O executor anterior tinha os números da soma dos canais** (§1, B4). A conclusão dele não muda: as capturas antigas
   já não são a caixa de hoje. Os números é que eram de outro critério, e o «limiar 0,06 RGB» não dizia qual.
6. **Neste PC continua a não haver o `_console.exe` do Godot.** Corri tudo com o `Godot_v4.7.2-stable_win64.exe`. O
   servidor correu sem `--permission`, como nas ordens anteriores.
7. **O `ORDEM.md` da sede não foi mexido.** A última linha dele é o ponto da lista que contém `<b>Estado: NOVA</b>`,
   e não uma linha só com isso.

## 5. Resultado do CI

CI do `7f2adc4` (corrida 44974405902): **verde, 10/10 jobs**: ponta-a-ponta, cliente, protocolo, foto-mestre,
validador-glb, godot-cliente, servidor, **retoma-pc**, motor-real e provas-mapa. A sonda de privacidade (corrida
44974405983) também passou. No CI, o passo «Relato da caixa» dá **23 de 23**.
