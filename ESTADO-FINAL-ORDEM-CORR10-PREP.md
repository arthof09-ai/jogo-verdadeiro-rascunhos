# ESTADO FINAL — ORDEM-CORR10-PREP (a bancada de rede com ecrãs verdadeiros)

Executor: Claude da conta 1, neste PC (Opus, esforço médio). 21/11/2026.

- **Ramo:** `claude1/corr10-prep`, sobre `ed395bb` (a ponta da `fable/integracao-50`). **Sem fusão.** Commit `1754a62`, já
  empurrado. `fable/integracao-50` continua em `ed395bb`.
- **Jogo intacto:** `git diff --stat ed395bb HEAD -- rascunhos .github` está vazio. Tudo o que é novo está em
  `bancada-rede/`, na raiz do repo.
- **Clone de trabalho:** `ordem-corr10-prep/repo`.

## 1. Como se corre

**Duplo clique em `ordem-corr10-prep\correr-com-o-mestre.cmd`.** Este ficheiro chama
`repo\bancada-rede\correr-com-o-mestre.cmd`, que chama o `lancar.ps1`. Abre-se uma janela de consola (o painel) e,
uns segundos depois, abrem-se **dois clientes Godot lado a lado, já na sala e com a batalha começada**:

- **à esquerda, a Jogadora (Heroína Teste)**, na arena. A vez é dela: pode mexer a figura;
- **à direita, o Mestre**, no ecrã do Mestre. Vê a heroína e o orc, e muda a escala com os botões de escala do ecrã
  dele (1 / 1,5 / 2 m).

Para parar: **Enter no painel**, ou `repo\bancada-rede\parar-bancada.cmd` se o painel foi fechado.

Na primeira vez, o lançador importa o projecto do cliente (`--headless --import`), o que leva um minuto. O
`host 0.0.0.0` pode fazer o Windows perguntar uma vez se deixa o `node` usar a rede local.

Opções (servem para os dois `.cmd`):

| opção | efeito |
| --- | --- |
| `-Aliada` | uma 2.ª jogadora (Aliada Teste) num 3.º cliente Godot. As duas jogadoras ficam empilhadas à esquerda e o Mestre à direita |
| `-SoLobby` | não prepara a batalha. O Mestre fá-lo no ecrã dele |
| `-Motor auto\|real\|falso` | `auto` (omissão): o VLAB real, se se baixar; se não, o falso |
| `-Modo manual\|semi\|auto` | o modo dos monstros (omissão `manual`, como nas bancadas) |
| `-Porta 8790` · `-HostServidor 0.0.0.0` · `-Godot <exe>` | a porta, o host onde o servidor escuta e o Godot (omissão: `C:\Users\txcga\godot-472\Godot_v4.7.2-stable_win64.exe`, ou a variável `GODOT`) |

## 2. O que foi construído e onde está (`repo/bancada-rede/`)

| peça | o que faz |
| --- | --- |
| `correr-com-o-mestre.cmd` | o duplo clique: `powershell -ExecutionPolicy Bypass -File lancar.ps1 %*` |
| `lancar.ps1` | **(1)** pára a corrida anterior pelos pids e arquiva os registos e o journal dela em `privado/anteriores/<data>/`; **(2)** corre `preparar.mjs`; **(3)** importa o cliente se faltar `.godot/imported`; **(4)** levanta o servidor; **(5)** corre o porteiro; **(6)** abre os clientes Godot; **(7)** mostra o registo do servidor até ao Enter e depois fecha tudo |
| `preparar.mjs` | escreve `privado/config.json`, `fichas.json` e `motores.mjs` |
| `porteiro.mjs` | entra na sala e entrega a cada cliente o seu lugar (§3) |
| `parar-bancada.cmd` | `taskkill` dos pids de `privado/pids.txt` |
| `README.md`, `.gitignore` | o resumo para quem abre a pasta. O `privado/` fica fora do Git |

**Onde fica cada coisa durante a corrida** (tudo em `bancada-rede/privado/`):
- `registos/`: `servidor.log`, `servidor-erros.log`, `porteiro.log`, `preparar.log` e `import.log`;
- `registo-MESTRE-ONLY-bancada-rede.json`: o journal da sala, gravado pelo servidor a cada commit;
- `clientes/<jogadora|mestre|aliada>/AppData/Godot/app_userdata/Assimilação/`: o `user://` de cada cliente, com o
  `lugar.cfg`, as preferências e o **`logs/godot.log` desse cliente**.

## 3. As escolhas

1. **O servidor é o arranque de produção, sem bancada no meio.** Corre
   `node rascunhos/servidor/adaptadores/node/servidor-ws.js privado/config.json` (o `principal()` que o Mestre usa),
   com o terreno da linha, o journal em disco e a fila de alertas. As bancadas PROVAS-MAPA montavam a sala num guião
   próprio; esta não.
2. **A grelha e a escala são as da linha.** A sala nasce **sem `mapa`** na config, com `terreno-floresta.json`. É a
   grelha-mapa: 50 × 50 casas de 1,5 m (o Mestre confirmou-o no arranque: `mapa {50, 50, 1.5}`). A heroína fica em
   terra a norte do lago (38,4) e o orc dentro do lago (38,11), as mesmas casas das bancadas PROVAS-MAPA.
3. **Os clientes são o cliente verdadeiro, como em produção.** O comando é
   `Godot --path rascunhos/cliente --windowed -- --servidor=127.0.0.1:8790`. Abre a cena principal (arena → lobby), com
   GPU e janela. Não há guião `-s` nem cena de prova. Os dois clientes ligam ao servidor por WebSocket, como dois
   aparelhos na rede.
4. **Entram já ligados, pelo porteiro e sem mudar o cliente.** O `seatToken` é do servidor e roda a cada entrada, por
   isso não se pode escrever de antemão. O porteiro:
   - entra pela rede com as credenciais de cada lugar (o PIN do Mestre, o nome e a senha da jogadora);
   - escreve o `lugar.cfg` exactamente como o `rede.gd` `_guardar_lugar()` o escreve.

   Ao abrir, o lobby encontra o lugar e entra sozinho (`Rede.iniciar()`: «com token guardado, entra sozinha»). Daí
   vai para a arena (jogadora em combate) ou para o ecrã do Mestre. É o que a Mestre e a jogadora fariam ao escrever
   as credenciais no formulário.

   Há dois cuidados de rede:
   - **A ligação da jogadora fecha logo a seguir ao WELCOME.** Se ficasse aberta, o cliente Godot seria «outro
     aparelho» (4002) e o Mestre receberia o alerta `segunda_ligacao`.
   - **A ligação do Mestre fica aberta até o ecrã do Mestre entrar.** O porteiro vê o token do `lugar.cfg` do Mestre
     mudar quando a Rede o regrava no WELCOME. Se fechasse antes, a sala ficaria sem Mestre ligado e **pausava**
     (E-C4, `mestre_desconectado`). Ao fim de 180 s sem o ecrã do Mestre, fecha na mesma e o Mestre retoma com
     «Continuar».
5. **Cada cliente tem o seu `user://`.** O `user://` é por projecto e por utilizador do Windows, por isso dois clientes
   no mesmo PC partilhariam o `lugar.cfg`: o segundo pisava o lugar do primeiro. O lançador dá a cada processo Godot o
   seu `APPDATA`. O Godot 4.7.2 no Windows respeita-o, e os dois `user://` apareceram em
   `privado/clientes/<lugar>/AppData/Godot/app_userdata/Assimilação/`.
6. **A batalha vem pronta, porque o Mestre se senta para ver a rede e não para montar.** O porteiro, como Mestre, faz
   `MASTER_LOBBY_SET` (orc disponível), `MASTER_START` e `MASTER_PLACE` (o orc no lago). Com `-SoLobby`, a batalha
   fica por montar no ecrã do Mestre.
7. **O motor real por omissão.** O VLAB é baixado do mesmo endereço do job `motor-real` e embrulhado pelo
   `motores/embrulhar.mjs`, sem mudar uma linha. Fica em cache em `privado/motores.mjs`; o desta corrida tem SHA-256
   `a91c021c…3261`. Sem rede, usa o motor falso dos testes, que dá sempre falha crítica (cada golpe abre um cartão),
   e o painel diz qual dos dois está em uso.
8. **As fichas e as credenciais são fictícias**, as dos testes do servidor: `fichas-ficticias.json`, o PIN `90210777`
   e as senhas `CANARIO-SENHA-*`. A sala tem `teste: true`, o selo de sala de teste que só o Mestre vê.
9. **O servidor escuta em `0.0.0.0` por omissão**, para que um telemóvel ou outro PC na rede também possa entrar. O
   painel mostra o IP da rede local. Os clientes da bancada ligam por `127.0.0.1`.
10. **Cada corrida é uma sala nova.** O journal anterior é arquivado e não é restaurado, porque o porteiro prepara a
    batalha a partir do lobby.

## 4. O que vi a correr (só o arranque; a prova dura é da conferência)

Corri uma vez `lancar.ps1 -HostServidor 127.0.0.1 -SemEspera` neste PC:
- **import:** feito;
- **servidor:** `sala nova` e `servidor de mesa pronto`;
- **porteiro:** LOBBY_SET, START e PLACE com `APLICADA`, os dois lugares guardados, e depois «o ecrã do Mestre
  (Godot) entrou na sala; o porteiro sai»;
- **os dois clientes Godot** (OpenGL 3.3, RTX 4060) carregaram a floresta, imprimiram `pronto` duas vezes (lobby e
  depois arena ou ecrã do Mestre) e deram **0 `SCRIPT ERROR`**;
- **o journal:** não tem evento `pausa`, o que confirma que o Mestre nunca ficou sem ligação;
- **`parar-bancada.cmd`:** fechou os 4 processos.

**Não vi os ecrãs.** A sessão em que corri não tem ambiente de trabalho visível: o ecrã virtual é de 1024 × 768 e a
captura falhou. Não confirmei com os olhos:
- a disposição lado a lado num monitor verdadeiro;
- uma figura a mexer-se num cliente e a aparecer no outro;
- a mudança de escala pedida no ecrã do Mestre.

Tudo isto fica para a conferência.

## 5. Notas para a conferência (sem mudar nada)

- **Um deslize meu, a registar.** Ao limpar o servidor do primeiro ensaio, corri
  `taskkill /F /IM node.exe /FI "WINDOWTITLE eq *"`. É um filtro largo demais e **pode ter fechado outros processos
  `node.exe` deste PC** nesse instante (por volta da primeira corrida do porteiro). Os `claude.exe` e o `node` do
  runtime do Codex estavam vivos logo a seguir. Depois disso só fechei processos pelo PID. Se algum serviço com
  `node` caiu hoje a meio da tarde, pode ter sido isto.
- **O import deixou ~140 ficheiros `*.uid` por cometer** em `rascunhos/cliente/` no clone. É o Godot 4.7 a gerá-los
  no import. Não os cometi (não mudam o jogo e estão fora da regra desta ordem). No PC do Mestre vão aparecer também
  no primeiro import. Decidir se entram no repo ou no `.gitignore` é para a conferência.
- **O jogo (anotado, não mexido):**
  - os dois clientes têm o mesmo título de janela («Assimilação»). Na bancada distinguem-se pela posição, Jogadora à
    esquerda e Mestre à direita;
  - o cliente guarda o lugar num `user://` único por máquina, por isso dois jogadores no mesmo PC precisam de
    `APPDATA` separado. Em produção é um aparelho por pessoa e isto não é defeito, mas fica registado.
- **Ficou de fora:** o cliente web (o servidor serve `pastaEstatica`) não entra, porque não há export Web na linha.
  Por isso a config não tem `pastaEstatica`.
