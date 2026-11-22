# ESTADO FINAL — ORDEM CAIXA-JANELA-NOMES (Claude conta 1, PC · 21/11/2026)

**Ramo:** `claude1/caixa-janela-nomes` · **base:** `0418d18` (ponta de `fable/integracao-50` no lançamento; não avançou
durante a ordem) · **commit do trabalho:** `25c97ae` · **não fundido.**

## 1. O que mudou

O relato da prova da caixa-janela (`provas/ordem-caixa-janela/cliente/relato.txt`) trazia os nomes verdadeiros das
criaturas de bancada: 22 ocorrências de «Lobo de Bancada» e «Bruto de Bancada». Havia duas fontes, ambas a ler o `nome`
da vista do Mestre: o `_nome()` (`prova_caixa_janela.gd:141`, usado na linha «a batalha a meio … ordem dinâmica») e a
linha «bancada: …» de `_jogar_vez()` (`:173`). O canário só varria os textos da caixa, por isso não apanhava nenhuma das
duas.

**A escolha: as duas metades, como no padrão (B1 da CAIXA-RELATO-CORRECOES-2).** Porque são as duas que dão certeza:
- **A fonte passa ao nome público.** Isto fecha a causa. Sem isto o relato continuava a trazer os nomes, e um canário
  sozinho só transformava a fuga numa prova vermelha.
- **O canário estende-se ao relato.** Isto apanha qualquer caminho que reabra a fuga: uma linha nova, um `get("nome")`
  noutro sítio, ou um ajudante mudado. A fonte sozinha não se defende a si própria.
- Nesta prova, os nomes que o relato escreve vêm de três sítios: `_nome()`, a linha «bancada:» e `_estado.nome_de()`. O
  terceiro já era público (`estado.gd:352` lê `nomePublico`). Pus os dois primeiros num ajudante novo e partilhado,
  `provas/ordem-caixa-janela/ferramentas/nomes_relato.gd`, com `nome_publico`, `nome`, `linha_bancada`,
  `nomes_verdadeiros` e `no_relato`. Assim o teste exercita o mesmo código que a prova corre, e não uma cópia.

Ficheiros:
- `ferramentas/nomes_relato.gd` (novo): o nome público (sem ele, o id, nunca o `nome`), os canários (nomes que diferem
  do público, sem repetidos) e a varredura do relato («<nome> na linha <n>»).
- `ferramentas/prova_caixa_janela.gd`:
  - `_nome()` e a linha «bancada:» passam pelo ajudante.
  - Em `_privacidade` («1» e «2») há uma verificação nova: «nenhum nome verdadeiro no relato». Exige pelo menos 1
    canário, para que uma vista sem canários não passe às cegas.
  - Em `_fim()` há outra verificação: o relato inteiro, contra todos os canários vistos.
  - O canário dos textos da caixa usa agora `nomes_verdadeiros()` (o mesmo critério de antes, sem repetidos).
  - Vida e PA ficam fora da varredura do relato, como no padrão. São números pequenos que o relato tem por outras razões
    (coordenadas, seq, medidas). Continuam procurados nos textos da caixa, como antes.
- `ferramentas/teste_nomes_relato.gd` (novo): o teste, sem servidor nem ecrã, com as fichas de bancada reais
  (`rascunhos/servidor/autojogo/fichas-bancada.json`).
- `ferramentas/correr-prova-caixa-janela.sh`: um 4.º argumento opcional, a pasta de saída. Sem ele o comportamento é o
  de antes. Servia para não reescrever o registo da ordem anterior.
- `README.md` (secção `nomes/`) e as corridas em `provas/ordem-caixa-janela/nomes/`.

Não toquei em `rascunhos/`, no HUD, nas cores nem no servidor.

## 2. O caso reproduzido

O teste (`teste_nomes_relato.gd`) reproduz o caso de duas maneiras:
- **§3:** um relato limpo, escrito pela fonte, passa. O mesmo relato com
  `  bancada: Bruto de Bancada → {"tipo":"encerrar"} (APLICADA)` dá `["Bruto de Bancada na linha 5"]`, ou seja, o
  canário falha. Também apanha «Lobo de Bancada» dentro de JSON.
- **§4 (o caso medido):** corre o canário sobre o relato cometido da CAIXA-JANELA (`cliente/relato.txt`, a corrida de
  antes desta ordem) e encontra **22 nomes verdadeiros**, o 1.º «Lobo de Bancada na linha 7».

Mutações, todas revertidas (o `git status` ficou limpo antes do commit):

| Mutação | Teste | Prova viva |
|---|---|---|
| `nome_publico` lê `nome` em vez de `nomePublico` (a fuga de volta) | **8/14** (6 falhas, §2 e §3) | **35/38**: as 3 novas falham («Lobo de Bancada na linha 7», …) |
| canário cego (`no_relato` nunca acha nada) | **11/14** (§3 sujo, §3 JSON, §4) | — (a fonte limpa passaria; é o teste que o apanha) |

## 3. Corridas (PC, Godot 4.7.2 Windows `Godot_v4.7.2-stable_win64_console.exe`; motor VLAB real sha256 `a91c021c…3261`; semente 7)

| Corrida | Resultado | Registo |
|---|---|---|
| Teste dos nomes do relato (novo) | **14/14** | `provas/ordem-caixa-janela/nomes/teste-nomes-relato.log` |
| Prova viva da caixa-janela | **38/38** (eram 35; +3 do canário do relato); 0 «Lobo/Bruto de Bancada» no relato | `nomes/cliente/relato.txt` |
| rodar_testes | 290/290 | `nomes/suites/rodar_testes.log` |
| abrir_scripts | 107 scripts, 0 falhas | `nomes/suites/abrir_scripts.log` |
| caixa_janela · caixa_jogadora · hud_acoes · canario_privacidade | 69/69 · 18/18 · 50/50 · 10/10 | `nomes/suites/` |
| teste_relato_caixa (o passo «Relato da caixa» do CI) | 21/21 | `nomes/suites/teste_relato_caixa.log` |
| `actualizar-listas` (retoma) | 0 novos, 0 tirados, sem diferenças (o ramo não toca em `rascunhos/`) | — |

Capturas da prova viva (sha256, 16 primeiros): `13ea9aa6ade3a432`, `9125924cc4b1e23e` e `b4d327e1b0c34764`. Vi a de
780×360: a caixa mostra «Lobo» e «Bruto», partida em 9 + 1.

Não corri as suites do servidor (`node --test`), porque nenhum ficheiro do servidor mudou. O CI corre-as.

## 4. Commits e CI

- `25c97ae`: o trabalho, as corridas e o README.
- O commit deste ESTADO-FINAL vem a seguir.
- CI do `25c97ae`: ver §6.

## 5. Para o coordenador

1. **O teste novo não está no CI.** A fronteira era a prova e o seu teste, e `.github/workflows/` ficou fora. Para o CI o
   correr, basta um passo igual ao «Relato da caixa» (`testes.yml:157-162`) com
   `provas/ordem-caixa-janela/ferramentas/teste_nomes_relato.gd`.
2. **O relato antigo (`provas/ordem-caixa-janela/cliente/relato.txt`) continua com os nomes verdadeiros.** Não o
   reescrevi, como no padrão: é o registo da Ordem CAIXA-JANELA, e o histórico do git tem-no de qualquer forma. O §4 do
   teste usa-o como o caso medido. **Se uma ordem de limpeza o reescrever, o §4 passa a falhar** e tem de mudar para um
   relato fixo dentro do teste. Fica dito para quem a fizer.
3. O `_console.exe` do Godot **existe** neste PC, em `C:\Users\txcga\RPG_Local\ferramentas\Godot_4.7.2\`. Corri tudo com
   ele. O ESTADO-FINAL da CAIXA-RELATO-CORRECOES-2 diz que não havia; procurou, possivelmente, noutra pasta
   (`C:\Users\txcga\godot-472\` só tem o `win64.exe`).
4. A prova viva corre na bancada (fichas fictícias). Antes de correr sobre fichas reais, a varredura do relato é só de
   nomes. Se um dia o relato tiver de provar também a ausência de vida e PA, é preciso um critério que não confunda esses
   números com coordenadas.
5. O `ORDEM.md` da sede não foi mexido. A linha «Estado: NOVA» está no ponto da lista da ordem, e não numa linha só sua
   no fim. Fica para o coordenador.

## 6. Resultado do CI

CI do `25c97ae` (corrida 44976530472): **verde, 10/10 jobs**: cliente, provas-mapa, ponta-a-ponta, protocolo,
**retoma-pc**, godot-cliente, servidor, motor-real, validador-glb e foto-mestre. A sonda de privacidade (corrida
44976530476) também passou.
