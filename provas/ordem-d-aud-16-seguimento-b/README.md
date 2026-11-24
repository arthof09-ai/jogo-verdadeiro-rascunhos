# Provas — ORDEM-D-AUD-16-SEGUIMENTO-B (os 3 defeitos conhecidos da secção B da sentença 870)

Todas as horas são de 24/11/2026 (-03). Os caminhos do PC estão redigidos: `<sede>` é a pasta desta ordem no PC,
`<godot>` / `<godot 4.7.2>` é o Godot 4.7.2 win64. O lugar do Mestre usado nas corridas B e C é inventado: um
`lugar.cfg` com o servidor `ws://127.0.0.1:8790/ws`, a sala `sala-ficticia`, o lugar `lugar-ficticio`, o token
`token-ficticio-seguimento-b` e o papel `mestre`. É o mesmo arranque da D-AUD-16-SEGUIMENTO: cena principal, lugar do
Mestre e arranque directo.

As capturas foram tiradas pelo agente da sessão 1 (uma tarefa agendada, `DAud16SegB`, que já foi apagada). Cada PNG
traz um bloco `tEXt` `Creation Time` com a hora da saída do comando e um bloco `Source` que diz de que saída vem.

## 1. B-1: a `PARADA` por rejeição de versão, antes do primeiro WELCOME (servidor em cima)

**Bancada.** O servidor real do jogo estava em cima em `127.0.0.1:8790`, com a configuração da bancada
(`node bancada-rede/preparar.mjs --porta=8790 --host=127.0.0.1 --motor=auto --modo=manual --fichas=canario`, e depois
`node rascunhos/servidor/adaptadores/node/servidor-ws.js <config da bancada>`). **O servidor não mudou.** Para o servidor
rejeitar a versão, o cliente mandou `v=3`: a constante `PROTOCOLO` da `rede.gd` passou a 3 **só na cópia de trabalho e
só durante a corrida** (`logs/b-versao-temporaria.diff`). No fim, foi reposta a `2` e **não foi cometida**. Com isso, o
servidor responde ao `ROOM_JOIN` com `ERRO` `versao` (`sala.js` `entrar`), **antes** de qualquer WELCOME.

| ficheiro | o que mostra |
|---|---|
| `capturas/b01-mestre-versao-rejeitada-10s.png` | o ecrã do Mestre aos 10 s. Tem **«Alertas: 1 — Há uma versão nova do jogo. Atualize a página.»** e, por baixo, o rótulo da ligação com **«Ligação parada: há uma versão nova do jogo. Atualize a página.»**, as duas frases inteiras. Antes desta ordem o ecrã ficava calado: sem alerta e sem estado |
| `capturas/b02-mestre-versao-rejeitada-25s.png` | o mesmo aos 25 s: a mensagem continua lá. A Rede está `PARADA` e não tenta de novo, por isso não aparece o «a tentar de novo» |
| `logs/b-godot-mestre-versao-rejeitada.log` | o `godot.log` desse cliente. Tem `arranque: lugar do Mestre -> res://cenas/mestre/mestre.tscn` e depois **`ecrã do Mestre: o servidor não aceita esta versão do jogo (ligação PARADA)`**. 0 `ERROR` / 0 `SCRIPT ERROR` |
| `logs/b-versao-temporaria.diff` | a mudança de uma linha que se corre e se desfaz |
| `capturas-b-comando.ps1.txt` / `capturas-b-saida.txt` | o comando de captura e **a saída dele, com as horas**. Arranque às 08:45:12; `b01` às 08:45:22; `b02` às 08:45:37 |

A corrida B foi feita **duas vezes**. A 1.ª, às 08:44:17, deu as mesmas duas imagens, mas o `godot.log` não tinha
nenhuma linha sobre a rejeição. Por isso juntei o `print` do `_ao_erro` e corri outra vez. Ficam aqui as capturas, o
log e a saída da 2.ª corrida; as da 1.ª foram deitadas fora.

## 2. B-2: o alerta da vista sem rede (servidor fora do ar) e o texto que cabe

| ficheiro | o que mostra |
|---|---|
| `capturas/c01-mestre-servidor-fora-13s.png` | o ecrã do Mestre aos 13 s, com o servidor **fora do ar** e sem nunca ter estado na mesa: **«A ligar à mesa…»** e **0 alertas**. Na D-AUD-16-SEGUIMENTO, aos ~10 s, aparecia o alerta da vista (Ordem 49), cortado em «A vista da mesa não se» (`provas/ordem-d-aud-16-seguimento/capturas/a02-…`) |
| `capturas/c02-mestre-servidor-fora-35s.png` | o mesmo aos 35 s: continua com **0 alertas** e com «A ligar à mesa…» |
| `logs/c-godot-mestre-servidor-fora.log` | o `godot.log` dessa corrida. **Não tem o `WARNING: MASTER_VIEW: vista_sem_pedido`**, que estava no log da corrida igual da D-AUD-16-SEGUIMENTO (`logs/a-godot-mestre-servidor-fora.log` dela) |
| `capturas-c-comando.ps1.txt` / `capturas-c-saida.txt` | o comando e a saída com as horas. Arranque às 08:43:06; `c01` às 08:43:19; `c02` às 08:43:41 |
| `capturas/v01-mestre-alerta-da-vista-inteiro.png` | o único caso em que o alerta da vista ainda aparece: **na mesa**, com o pedido da vista a não sair até ao tecto (40 tentativas). O texto está **inteiro**: «Alertas: 1 / A vista da mesa não se / pediu (40 tentativas). Toque / em «Atualizar».» — 4 linhas, e o limite é agora de 6 |
| `ferramentas/foto_alerta_vista.gd.txt` | o script dessa captura (com janela, 960×540, não é suite). Põe a Rede em `NA_MESA` e o pedido da vista a falhar sempre, e anda o relógio à mão até ao tecto |
| `logs/v-saida-foto-alerta-vista.log` | a saída do script: `pedidos=40`, o alerta, e **`rótulo dos alertas: linhas=4 visíveis=4 máximo=6`** |
| `logs/v-erros-foto-alerta-vista.log` | o `WARNING: MASTER_VIEW: vista_sem_pedido` da Ordem 49, que neste caso é o esperado |
| `capturas-v-comando.ps1.txt` / `capturas-v-saida.txt` | o comando e a saída com as horas (`v01` às 08:46:14) |

## 3. B-3: o `A_ENTRAR`

O B-3 não precisa de bancada: a prova são as 3 verificações novas do `_arranque_a_ligar` no
`suites/pecas_mestre.log`, as linhas que começam por `B-3:`.

## 4. Suites

Ver `suites/RESUMO.txt` e `suites/*.log`, e também o ESTADO-FINAL, §4. Cada log abre com `# comando: …` e
`# hora: início …` e fecha com `# hora: fim … rc=…`. O executor está em `suites-executor.sh.txt`.
