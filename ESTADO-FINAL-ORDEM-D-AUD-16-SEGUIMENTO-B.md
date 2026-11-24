# ESTADO-FINAL — ORDEM-D-AUD-16-SEGUIMENTO-B (os 3 defeitos conhecidos da secção B da sentença 870)

**Estado: FEITA** (o resultado do CI fica na nota do fim). Os 3 itens da secção B:

1. **B-1:** a `PARADA` por rejeição de versão já não deixa o ecrã do Mestre calado nem preso. O `mestre.gd` passou a
   escutar `erro_recebido`. O ecrã mostra um alerta e um estado: «Há uma versão nova do jogo. Atualize a página.» e
   «Ligação parada: …». A prova está na bancada (o servidor real em cima a rejeitar a versão antes do 1.º WELCOME)
   e em 8 verificações novas.
2. **B-2:** com o servidor fora do ar, o alerta da vista já não aparece. O pedido da vista fica parado enquanto a
   Rede liga, e o rótulo da ligação diz a causa. O `_alerta` passou de 2 para 6 linhas e o `_ligacao` de 2 para 4:
   «Toque em «Atualizar».» cabe inteiro. A prova está em 3 capturas e em 6 verificações novas.
3. **B-3:** o `A_ENTRAR` sem mesa passou a ter teste: 3 `_ok` novos no `_arranque_a_ligar`.

- **Executor:** Claude (opus), PC, conta 2. **Data:** 24/11/2026, ~08:35–08:55 (-03).
- **Linha:** `fable/integracao-50`, trabalho directo. **Ponta de partida:** `980b5ba`. A `main` não foi tocada.
- **A C-7 não foi decidida.** A predefinição continua «directo» (`arena.gd:23`, sem mudança; o teste
  «predefinição: o Mestre abre directo em mestre.tscn» do `rodar_testes` passou).
- **Não toquei** no servidor, nos workflows, nos dados, na `main`, no `arena.gd`, no `lobby.gd` nem no cliente da
  jogadora. Na `rede.gd` entrou **só** o campo `motivo_parada` (+6 linhas, ver §1.2).

## 1. B-1: a `PARADA` por versão

### 1.1 O defeito

`_parar_por_versao` fecha o socket, põe a ligação em `PARADA` e emite só `erro_recebido("versao")`. Antes desta ordem
o `mestre.gd` não escutava esse sinal, e o `texto_ligacao` dava `""` para a `PARADA`. Quando o servidor rejeitava a
versão antes do 1.º WELCOME, o rótulo «A ligar à mesa…» desaparecia e o ecrã ficava sem nenhuma mensagem. A Rede
também não voltava a tentar, por isso o ecrã ficava preso.

### 1.2 A correcção

| ficheiro | mudança |
|---|---|
| `rascunhos/cliente/rede/rede.gd` | `var motivo_parada` (`"versao"` / `"outro_aparelho"` / `""`). Fica definida antes de cada `_mudar_estado(PARADA)` e é limpa em `_ligar()`. Não muda mais nada: nem os estados, nem os sinais, nem o protocolo |
| `rascunhos/cliente/cenas/mestre/mestre.gd` | `Rede.erro_recebido.connect(_ao_erro)`. O `_ao_erro("versao")` deixa uma linha no registo do Godot, junta o alerta **uma vez** e actualiza o rótulo; os outros códigos não aparecem, como no lobby e no HUD («nada técnico»). O `texto_ligacao(estado, ja_esteve, motivo_parada)` dá a frase da versão para a `PARADA` por versão, **tenha ou não** o Mestre estado na mesa. O `_ao_ligacao` já não junta «A ligação caiu; **a tentar de novo**» numa `PARADA`, porque aí a Rede não volta a tentar |
| idem, `_ready` + `abre_sem_saida()` | **«o mesmo vale, em menor grau, para a `DESLIGADA`»**: o ecrã do Mestre que abre **como cena principal** com a Rede `DESLIGADA`, ou `PARADA` por outro aparelho, vai ao lobby. Nesses casos a Rede já emitiu `precisa_entrar` antes de a cena existir; um caso real é a guarda da rede local do Android, no arranque directo. O lobby chama o `Rede.iniciar()` e mostra o `Rede.motivo_entrada`. A `PARADA` por versão **fica** no ecrã do Mestre, com o rótulo a dizer o que fazer: o lobby não a mostraria, porque o `_ao_erro` dele só ouve o sinal e o sinal já passou. Nos testes de ecrã a cena não é a principal, por isso não sai |
| `rascunhos/cliente/cenas/mestre/textos_mestre.gd` | `LIGACAO["versao"]` e `ALERTA["versao"]`. A frase do alerta é a mesma do lobby e do HUD |

### 1.3 A bancada (o servidor em cima a rejeitar a versão antes do 1.º WELCOME)

O servidor real do jogo correu em `127.0.0.1:8790`, com a configuração da bancada (`preparar.mjs`, fichas
`canario`), **sem mudanças**. O cliente do Mestre correu com janela, pela cena principal, com um `lugar.cfg` fictício
do Mestre. Para o servidor rejeitar a versão, o `PROTOCOLO` da `rede.gd` passou a `3` **só na cópia de trabalho e só
durante a corrida** (`logs/b-versao-temporaria.diff`). Assim o servidor responde ao `ROOM_JOIN` com `ERRO versao`
(`sala.js` `entrar`). No fim o `PROTOCOLO` voltou a `2`, e o `git diff` do commit `31b3f1a` não lhe toca.

- `b01` (08:45:22, t = 10 s) e `b02` (08:45:37, t = 25 s): **«Alertas: 1 — Há uma versão nova do jogo. Atualize a
  página.»** e, por baixo, **«Ligação parada: há uma versão nova do jogo. Atualize a página.»**. Os dois textos estão
  inteiros e continuam lá aos 25 s.
- No `godot.log`: `arranque: lugar do Mestre -> res://cenas/mestre/mestre.tscn (ORDEM-D-AUD-16)` e depois
  `ecrã do Mestre: o servidor não aceita esta versão do jogo (ligação PARADA)`. 0 `ERROR`.
- A corrida foi feita duas vezes. A 1.ª, às 08:44:17, deu as mesmas imagens, mas o log não tinha a linha da
  rejeição. Por isso juntei o `print` e repeti; ficam as provas da 2.ª (README das provas, §1).

**Não fiz bancada** do caminho `DESLIGADA` → lobby: esse caminho está coberto só pela verificação pura do
`abre_sem_saida` (§4, item 8). A troca de cena usa o mesmo `get_tree().current_scene == self` →
`change_scene_to_file.call_deferred(CENA_LOBBY)` do `recusar()`. A corrida viva do B-1 (24/11/2026) provou que
o arranque directo com um `lugar.cfg` de papel mestre sem token NÃO chega ao ramo: sem token o
`papel_do_arranque()` devolve `""` (`rede.gd:727`) e a arena abre o lobby pela jogadora, sem o ecrã do Mestre.
A frase original deste §1.3 («no PC não há maneira de o provocar sem mexer no código») estava certa para o
código desta linha. O ramo correu vivo na mesma ordem, mas só com uma linha temporária a forçar a guarda do
Android (`rede.gd:426`), desfeita a seguir e nunca cometida. Falta uma prova viva sem mexer no código: um APK
num Android real, ou um gancho de teste no código (sentença da B1, secção B).

## 2. B-2: o alerta da vista sem rede, e o limite de linhas

### 2.1 A correcção

- **Calar enquanto a Rede não está na mesa:** o `_tentar_vista`, quando o pedido não sai **e** a Rede está a
  ligar, a entrar, à espera de tentar de novo ou parada (`vista_espera_pela_ligacao()`), deixa o pedido parado
  (`_espera_vista = -1`), zera a conta e **não alerta**. Quando a ligação chega à mesa, o `_ao_ligacao` já arma um
  pedido novo com a conta do zero (Ordem 49, sem mudança). Assim, sem rede, a causa é dita pelo rótulo «A ligar à
  mesa…» (D-AUD-16-SEGUIMENTO).
  **Na mesa fica tudo como estava:** o tecto de 40 tentativas e o alerta «Toque em «Atualizar».», que na mesa é o
  conselho certo. Com a Rede `DESLIGADA` (o estado dos testes de ecrã) também não muda nada: os testes da Ordem 49 no
  `abrir_mestre` passam iguais (67 / 67).
- **O limite de linhas:** o `_alerta` passou de 2 para `LINHAS_ALERTA = 6` (a linha «Alertas: N» mais até 5 do texto)
  e o `_ligacao` de 2 para `LINHAS_LIGACAO = 4`. A coluna 1 tem 14 letras de largura. O alerta da vista ocupa 4 linhas
  com a conta; as frases «a esperar» e «versão» do rótulo ocupam 3 cada uma, e com 2 também ficavam cortadas. **O
  teste novo apanhou isto:** a 1.ª corrida deu `3/2 linhas` no rótulo da ligação.

### 2.2 As capturas

- `c01` (08:43:19, t = 13 s) e `c02` (08:43:41, t = 35 s): o cliente do Mestre com o servidor **fora do ar** mostra
  «A ligar à mesa…» e **0 alertas**. Na D-AUD-16-SEGUIMENTO, aos ~10 s, aparecia «Alertas: 1 — A vista da mesa não
  se». O `godot.log` já não tem o `WARNING: MASTER_VIEW: vista_sem_pedido`, que estava na corrida igual dessa ordem.
- `v01` (08:46:14): o único caso em que o alerta da vista ainda aparece, **na mesa** com o pedido a não sair até
  ao tecto. O texto está inteiro: «Alertas: 1 / A vista da mesa não se / pediu (40 tentativas). Toque / em
  «Atualizar».». A saída do script dá `linhas=4 visíveis=4 máximo=6`. O script está em
  `provas/…/ferramentas/foto_alerta_vista.gd.txt` (não é suite e não entrou em `rascunhos/`).

## 3. B-3: o `A_ENTRAR` no teste

São 3 verificações novas no `_arranque_a_ligar` do `pecas_mestre`:
- Rede em `A_ENTRAR` com `_ja_esteve_na_mesa = false`: o ecrã mostra «A ligar à mesa…»;
- no mesmo caso, **0 alertas falsos**;
- **um ecrã que abre com a Rede já em `A_ENTRAR`** mostra logo «A ligar à mesa…» e tem 0 alertas.

## 4. As verificações novas do `pecas_mestre` (307 → 325, +18)

O B-3 tem 3 verificações (§3). O `_seguimento_b` é novo e tem 15:

1. o caminho real da Rede: o `_ao_erro({"codigo": "versao"})` em `A_ENTRAR` deixa a Rede em `PARADA`, com o motivo `versao`;
2. o rótulo mostra «Ligação parada: …»;
3. aparece um alerta «Há uma versão nova do jogo. Atualize a página.»;
4. o alerta e o rótulo cabem inteiros: as linhas visíveis são todas as linhas;
5. o `ERRO versao` repetido não repete o alerta;
6. os outros `ERRO` não aparecem;
7. já tendo estado na mesa, a `PARADA` por versão mostra a frase e **não** «A ligação caiu; a tentar de novo.»;
8. `abre_sem_saida`: com `DESLIGADA` e com `PARADA`/outro aparelho vai ao lobby; com `A_LIGAR`, `A_ENTRAR`,
   `A_ESPERAR`, `NA_MESA` e `PARADA`/versão fica;
9. B-2: um ecrã novo com o pedido da vista sempre a falhar e 31 s de relógio a alternar `A_LIGAR`/`A_ESPERAR` fica
   com **0 alertas**, sem falha e sem pedido à espera;
10. fora da mesa o pedido não se repete: só o 1.º, quando o ecrã abre;
11. vê-se o rótulo da ligação, inteiro;
12. na mesa, o tecto da Ordem 49 continua igual: 40 pedidos e um alerta;
13. o texto do alerta da vista cabe inteiro, incluindo «Toque em «Atualizar».»;
14. com o alerta maior, o «◂» ainda cabe na coluna 1;
15. de volta ao estado do teste, o rótulo some.

## 5. Suites no PC (Godot 4.7.2, `--headless`; Node), de 08:46:47 a 08:48:56

| suite | resultado | antes (D-AUD-16-SEGUIMENTO) |
|---|---|---|
| `abrir_scripts` | 112 scripts, 0 falhas | 112 |
| `rodar_testes` | 333 / 333 (inclui «predefinição: o Mestre abre directo em mestre.tscn») | 333 |
| `abrir_clareira` | 22 / 22 | 22 |
| `medir_painel_config` | 0 falhas, 0 sem medida | igual |
| `abrir_mestre` | 67 / 67 (os testes do tecto da Ordem 49 passam iguais) | 67 |
| `pecas_mestre` | **325 / 325** (+18, §4) | 307 |
| `medir_mestre` | 0 falhas, 0 sem medida. Tirando os comentários `#` e a linha de tempo da floresta, a saída é **igual, linha a linha**, à da D-AUD-16-SEGUIMENTO | igual |
| `hud_acoes` | 50 / 50 | 50 |
| `caixa_jogadora` | 70 / 70 | 70 |
| `caixa_janela` | 123 / 123 | 123 |
| `canario_privacidade` | 10 / 10 | 10 |
| `camera_segue` | 17 / 17 | 17 |
| arranque da cena principal (sem lugar) | 2 × `pronto` (D-AUD-16-SEGUIMENTO §4), 0 `SCRIPT ERROR` | igual |
| servidor (`node --test testes/*.test.mjs`) | 442 / 442 (o servidor não mudou) | 442 |

Nenhuma suite tem `SCRIPT ERROR`, `Parse Error` ou `Compile Error`. Os logs estão em
`provas/ordem-d-aud-16-seguimento-b/suites/` e cada um abre com `# comando:` e `# hora:`. O executor está em
`suites-executor.sh.txt`.

**Fecho da bancada:** o servidor (`node`, porta 8790) foi parado. Ficaram 0 processos Godot e a porta 8790 sem
ninguém à escuta. O agente da sessão 1 foi parado e a tarefa agendada `DAud16SegB` foi **apagada**.

## 6. Critérios da ordem

- [x] B-1 provado com bancada e teste novo: o ecrã tem estado e alerta na rejeição de versão antes do WELCOME (§1.3, §4).
- [x] B-2 provado com captura: sem rede o alerta da vista fica calado, e quando aparece o texto vê-se inteiro (§2.2).
- [x] B-3 provado com os `_ok` novos a passar (§3).
- [x] Suites verdes (§5).
- [x] CI verde (Testes + Sonda): ver a nota do CI.
- [x] ESTADO-FINAL com os números e os commits (§7).
- [x] A C-7 não foi decidida. Não toquei no servidor, nos workflows, nos dados nem na `main`.

## 7. Commits

| commit | o quê |
|---|---|
| `31b3f1a` | B-1/B-2/B-3: `mestre.gd`, `textos_mestre.gd`, `rede.gd` (`motivo_parada`) e `pecas_mestre.gd` |
| `5163106` | as listas da retoma sincronizadas depois de `31b3f1a` (`actualizar-listas`: 0 novos, 0 tirados; só os SHAs) |
| `52ad009` | as provas (`provas/ordem-d-aud-16-seguimento-b/`) e este ESTADO-FINAL |

O `actualizar-listas.py` correu com `python` (o Python 3.12 do PC). O commit das provas não muda `rascunhos/`, por
isso as listas não precisam de nova passagem.

## Nota do CI

No `52ad009` (o código, as listas, as provas e este ESTADO-FINAL), os dois workflows deram `success`:
- **Testes dos rascunhos 45387917813:** os 10 jobs passaram — `motor-real`, `foto-mestre`, `cliente`, `servidor`,
  `validador-glb`, `retoma-pc`, `protocolo`, `ponta-a-ponta`, `godot-cliente` e `provas-mapa`. O `ponta-a-ponta` (o
  Mestre Godot sem janela, pela ligação real) e o `foto-mestre` passaram com as mudanças desta ordem;
- **Sonda de privacidade 45387917574.**

Depois do `52ad009` entrou o `dd7d00c`, de outra ordem: só um README de provas da F4-PARCIAL-A7. Nesse commit os dois
workflows também deram `success` (45388031925 + 45388031992).

Depois do `dacf670` (erratas E-1 + E-2 da conferência desta ordem, sentença 885), os dois workflows também
deram `success` (45396760140 + 45396760024): os 10 jobs dos Testes passaram, e a Sonda passou.
