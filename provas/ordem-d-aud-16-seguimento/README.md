# Provas — ORDEM-D-AUD-16-SEGUIMENTO (o estado de ligação visível + o caminho de reversão corrido)

Todas as horas são de 24/11/2026 (-03). Os caminhos do PC estão redigidos (`<sede>` = a pasta desta ordem no PC,
`<godot>` / `<godot 4.7.2>` = o Godot 4.7.2 win64). Todos os nomes são os fictícios das fichas da bancada; o lugar da
corrida A é inventado (ficheiro `lugar.cfg` com token e sala fictícios; conteúdo:
`token-ficticio-servidor-fora`, sala `sala-ficticia`).

## 1. A1 — o estado «a ligar…» no ecrã do Mestre (servidor fora do ar, sem nunca ter estado na mesa)

| ficheiro | o que mostra |
|---|---|
| `medicao/ligacao-arranque-servidor-fora.log` | **a medição** que decidiu entre «estado visível» e «alerta ao fim de N s». O ecrã do Mestre aberto com a Rede a ligar a uma porta sem nada à escuta, durante 75 s: cada mudança da ligação, com o tempo, a frase do rótulo e os alertas. Cada tentativa fica **~30 s em `A_LIGAR`** (a ligação ao porto fechado só falha ao fim desse tempo) e só **1,1 s / 2,2 s em `A_ESPERAR`**. Comando na 1.ª linha |
| `capturas/a01-mestre-servidor-fora-a-ligar.png` | o cliente do Mestre (com janela, cena principal, `lugar.cfg` do Mestre, servidor fora do ar) aos 11 s: o ecrã dele com **«A ligar à mesa…»** por baixo da linha da sala, 0 alertas |
| `capturas/a02-mestre-servidor-fora-30s.png` | o mesmo cliente aos 34 s: **«A ligar à mesa…»** continua; por cima, «Alertas: 1 — A vista da mesa não se…», que é o alerta **pré-existente** do tecto do pedido da vista (Ordem 49), aos ~10 s — ver o ESTADO-FINAL §1.3 |
| `logs/a-godot-mestre-servidor-fora.log` | o `godot.log` desse cliente: `arranque: lugar do Mestre -> res://cenas/mestre/mestre.tscn (ORDEM-D-AUD-16)` e o aviso do tecto da vista. 0 `ERROR` / 0 `SCRIPT ERROR` |
| `capturas-a-comando.ps1.txt` | o comando de captura (corrido pelo agente da sessão 1) |
| `capturas-a-saida.txt` | **a saída desse comando, com as horas** (arranque 07:05:03, `a01` 07:05:14, `a02` 07:05:38) |

## 2. A2 — o caminho de reversão corrido uma vez (lugar do Mestre + constante em `lobby.tscn` + servidor em cima)

A constante `CENA_ARRANQUE_MESTRE` (`arena.gd:23`) foi posta em `"res://cenas/lobby/lobby.tscn"` **só na cópia de
trabalho e só durante esta corrida** (`logs/r-reversao-temporaria.diff`); a seguir, `git checkout` repô-la em
`mestre.tscn`. **Não foi cometida: a predefinição continua «directo», e a C-7 continua por decidir.**

Bancada: `bancada-rede/lancar.ps1 -SemEspera -HostServidor 127.0.0.1 -Motor auto` (fichas `canario`, porteiro com a
batalha preparada), dois clientes Godot 4.7.2 com janela em simultâneo, cada um com o seu `user://`.

| ficheiro | o que mostra |
|---|---|
| `logs/r-godot-mestre-pelo-lobby.log` | o `godot.log` do Mestre: **`arranque: lugar do Mestre -> res://cenas/lobby/lobby.tscn (ORDEM-D-AUD-16)`**, depois **`pronto`** — que só pode ser o do lobby (`lobby.gd:84`): a arena sai do `_ready` antes do dela (`arena.gd:171`) — e o `ROOM_SNAPSHOT seq=5 fase=combate`. 0 `ERROR` / 0 `SCRIPT ERROR` |
| `capturas/r02-mestre-pelo-lobby-no-ecra-dele.png` | o Mestre **no ecrã dele** (`mestre.tscn`): abas Figuras / Agir / Mesa / Ambiente / Registo / Sala, «[TESTE] Sala: em combate · Rodada 1 · vez de Heroína Teste», sem alertas e sem «A ligar à mesa…» (está na mesa). Do lobby para aqui só há um caminho: `_verificar_fase` → `_ir(CENA_MESTRE)` (`lobby.gd:294-298`) |
| `capturas/r01-jogadora-na-arena.png` | a jogadora na arena dela, como sempre («A sua vez», Ataque / Mover / Consumível / Encerrar) |
| `capturas/r03-os-dois-clientes-em-simultaneo.png` | as duas janelas no mesmo instante |
| `logs/r-godot-jogadora.log` | o `godot.log` da jogadora: `pronto` e o snapshot de combate |
| `logs/r-porteiro.log` | o porteiro: lugares guardados e «o ecrã do Mestre (Godot) entrou na sala» |
| `logs/r-reversao-temporaria.diff` | a mudança de uma linha que se corre e se desfaz |
| `capturas-r-comando.ps1.txt` / `capturas-r-saida.txt` | o comando de captura e **a saída dele, com as horas** (1.ª captura 07:07:15, deitada fora porque a janela do Mestre ficou meio fora do ecrã; 2.ª, a que está aqui, 07:07:38) |

O `servidor.log` da bancada não está aqui (traz endereços da rede local); fica em `bancada-rede/privado/registos/`, fora do Git.

## 3. F1/F4 — o rasto das provas

- Cada log em `suites/` abre com **`# comando: …`** (o directório de trabalho é exacto; o caminho do
  binário é redigido como `<godot>`, documentado no executor) e **`# hora: início …`**, e fecha com
  `# hora: fim … rc=…`. Os 3 logs de `medicao/` abrem com **`# comando: …`** (binário `godot`, sem
  caminho; directório redigido como `<tmp>`) e **`# hora: …`** (sem «início») e fecham com `# rc=0`,
  sem linha `# hora: fim`.
  O `suites/RESUMO.txt` também.
- A saída dos comandos de captura, com as horas, está em `capturas-a-saida.txt` e `capturas-r-saida.txt`.

## 4. A7 — os dois `pronto`

| ficheiro | o que mostra |
|---|---|
| `medicao/dois-pronto-1-sem-marcas.log` | o arranque da cena principal **sem lugar** (`user://` vazio), com o código desta ordem: 2 × `pronto`, como no `arranque.log` da D-AUD-16 |
| `medicao/dois-pronto-2-com-marcas.log` | o mesmo, com uma marca **temporária** em cada `print("pronto")` (desfeita com `git checkout`, não cometida): `pronto  <- arena.gd:171` e depois `pronto  <- lobby.gd:84` |

## 5. Suites

`suites/RESUMO.txt` e `suites/*.log` (ver o ESTADO-FINAL §5).
