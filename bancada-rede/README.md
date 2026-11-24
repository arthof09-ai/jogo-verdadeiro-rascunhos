# Bancada de rede verdadeira (ORDEM-CORR10-PREP)

O servidor do jogo, arrancado como em produção, e os **clientes Godot verdadeiros** (o projecto `rascunhos/cliente`,
cena principal, com janela), ligados em rede local neste PC e já dentro da mesma sala. A grelha é a da linha: a
grelha-mapa de 50 × 50 casas de 1,5 m sobre o terreno da floresta.

**Duplo clique:** `correr-com-o-mestre.cmd`. **Parar:** Enter na janela do lançador, ou `parar-bancada.cmd`.

| peça | o que faz |
| --- | --- |
| `correr-com-o-mestre.cmd` | chama o `lancar.ps1` (as opções passam): `-Aliada` (uma 2.ª jogadora, 3.º cliente), `-SoLobby` (sem preparar a batalha), `-Motor auto\|real\|falso`, `-Modo manual\|semi\|auto` (o modo dos monstros), `-Fichas canario\|acertam` (ver abaixo), `-Porta 8790`, `-HostServidor 0.0.0.0`, `-Godot <exe>` |
| `lancar.ps1` | pára a corrida anterior e arquiva-lhe os registos → `preparar.mjs` → import do cliente (só a 1.ª vez) → servidor → porteiro → clientes Godot lado a lado → painel com o registo do servidor |
| `preparar.mjs` | escreve `privado/config.json` para `rascunhos/servidor/adaptadores/node/servidor-ws.js` (o arranque de produção), as fichas fictícias e o motor: o VLAB real do site, embrulhado por `motores/embrulhar.mjs` como no CI (fica em cache), ou o motor falso dos testes se não houver rede |
| `porteiro.mjs` | entra na sala pela rede com as credenciais de cada lugar, prepara a batalha (LOBBY_SET → START → orc no lago; com `-Fichas acertam`, o lobo e o bruto de bancada em terra) e deixa o `seatToken` no `user://lugar.cfg` de cada cliente, que entra sozinho ao abrir |
| `parar-bancada.cmd` | fecha os processos de `privado/pids.txt` |

Cada cliente tem o seu `APPDATA` (`privado/clientes/<lugar>/AppData`), e por isso o seu `user://`: dois clientes no
mesmo PC não partilham o `lugar.cfg`. Tudo o que a bancada escreve fica em `privado/`, fora do Git.

Credenciais (fictícias, as dos testes do servidor), para entrar à mão noutro aparelho:
- Mestre: PIN `90210777`;
- Heroína Teste: senha `CANARIO-SENHA-H`;
- Aliada Teste (com `-Aliada`): senha `CANARIO-SENHA-A`.

## Os dois jogos de fichas (`-Fichas`, ORDEM-D-AUD-04-BANCADA)

| `-Fichas` | fichas | o que se pode medir |
| --- | --- | --- |
| `canario` (de origem) | as dos testes do servidor (Heroína/Aliada Teste contra o orc-teste no lago), com números **canário** (CA 5551/9137, vida 5150…) | rede, movimento, HUD, Registo; **nenhum ataque acerta** (D-AUD-04) |
| `acertam` | as FICTÍCIAS de bancada da Ordem AUTOJOGO (`rascunhos/servidor/autojogo/fichas-bancada.json`): a Arqueira de Bancada em (38,4) (e, com `-Aliada`, a Espadachim de Bancada em (38,3)) contra o Lobo de Bancada em (36,3) e o Bruto de Bancada em (41,1), todos em terra a norte do lago. CA 12–14, vida 16–34 | acertos, dano, queda a 0, testes de morte, morte e fim da batalha, nos dois ecrãs |

`-Fichas acertam` não muda nada no jogo. Só mudam o ficheiro das fichas, os lugares, a iniciativa e as criaturas que o
porteiro põe na mesa (`bancada.criaturas` na config; o servidor não lê essa chave). A grelha continua a ser a
grelha-mapa da linha: sem `sala.mapa`, 50 × 50 casas de 1,5 m. As senhas fictícias das duas heroínas estão em
`rascunhos/servidor/autojogo/cenario-bancada.json`. O PIN do Mestre é o de cima. Com `-Fichas canario`, a config e as
fichas saem byte a byte iguais às de antes, fora a chave nova `bancada`.
