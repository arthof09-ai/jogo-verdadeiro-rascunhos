# Ordem 62: o servidor na mudança de escala (reserva 2 da Ordem 58). ESTADO FINAL

*Fecho da ordem, 2026-11-15, Claude conta 2 (Opus 5.5), uma só sessão. Godot 4.7.2 e Node, nesta máquina.
Trabalhei directamente na linha `fable/integracao-50` (ponta de partida `7310391`), no clone `fable-mapa/repo`, sem
ramo novo. Os registos brutos ficaram em `fable-mapa/_tmp/o62/`, fora do repositório. A `mesa-mestre.json` (o «M» do
CRLF local) não entrou em commit nenhum. Não toquei no visual (relva, água, neve), no relógio do mundo nem no mapa.*

## Resumo

**O buraco reproduz-se, e está fechado.** Antes, a mudança de escala guardava as posições em casas e não voltava a
conferir o terreno: 4 das 6 mudanças possíveis deixavam figuras em casas bloqueadas, 34 figuras ao todo, e o
«Recomeçar» feito depois de uma mudança de escala deixava mais 1. Agora o servidor aplica à mudança de escala a
regra da colocação. Cada figura colocada é conferida contra os bloqueios da grelha nova, e se alguma cair numa casa
bloqueada, a mudança é recusada com o nome de cada figura. O resultado é 0 figuras em casas bloqueadas, nos mesmos
casos.

## 1. A medição de antes

A prova é `provas/ordem-62-escala/medir-escala-bloqueadas.mjs`, que só lê o servidor (a `montarMesa` dos testes,
com o terreno de verdade). Corri-a em `7310391` e guardei a saída em `medicao-antes.txt` (commit `61f5350`, antes da
correcção).

**A) As 6 mudanças de escala.** A grelha é 30 × 30, com uma criatura de 2 em 2 casas, como na sonda da Ordem 58. O
servidor já recusa as casas bloqueadas na colocação, por isso todas começam em casas livres.

| mudança | figuras | recibo | em casas bloqueadas depois |
|---|---|---|---|
| 1,5 → 2 m | 215 | APLICADA | **7**: (6,4) menir, (22,4), (24,4) e (24,6) água funda, (22,22) e (28,24) escarpa, (6,28) tronco tombado |
| 1,5 → 1 m | 215 | APLICADA | 0 |
| 1 → 1,5 m | 225 | APLICADA | **10**: (26,0), (28,0), (26,2) e (28,2) água funda, (0,4) e (2,4) menir, (26,24), (24,26) e (24,28) escarpa, (28,28) santuário |
| 1 → 2 m | 225 | APLICADA | **8**: as 7 do 1,5 → 2 m, mais (24,28) escarpa |
| 2 → 1,5 m | 217 | APLICADA | **9** |
| 2 → 1 m | 217 | APLICADA | 0 |

O caso 1,5 → 2 m é exactamente o da sonda da Ordem 58, com as mesmas 7 casas.

**B) O «Recomeçar» depois da escala.** A heroína é colocada em (6,4), que está livre com 1,5 m e é menir com 2 m.
Anda para (7,4), e a escala passa a 2 m, aceite porque nesse momento ninguém está numa casa bloqueada. Depois o
«Recomeçar» devolve cada figura à casa onde foi colocada (a regra D-1), e a heroína volta a (6,4), em cima do menir:
**mais 1**. É o mesmo buraco por outra porta, porque a casa de colocação foi validada na escala antiga.

**Total de antes: 35 figuras em casas bloqueadas** (34 pela escala e 1 pelo «Recomeçar»).

## 2. O que mudou

### O comportamento que já existia na colocação

No servidor, `MASTER_PLACE` numa casa bloqueada é **recusado**. A figura não entra, e o porquê vai só ao Mestre, no
evento interno `recusa`: `CASA_BLOQUEADA: (x,y) motivo` (Ordem 44). A Party vê só a recusa fixa de sempre (E-P7).
O servidor nunca muda uma figura de casa por conta própria: a posição é dele e só o jogo a muda. A recusa da Ordem 48
(a grelha que não cabe no mapa na escala nova) segue o mesmo padrão: a escala não muda e o porquê vai nomeado.

### A extensão (`rascunhos/servidor/nucleo/sala.js`)

- **`mudarEscala`.** Depois da conferência da Ordem 48, cada figura colocada é conferida contra a grelha da escala
  nova (`terrenos.para(largura, altura, casaM)`). Se alguma cair numa casa bloqueada, a mudança é **recusada
  inteira**: a sala fica na escala em que estava e nada mexe. O detalhe é
  `ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS: N figuras ficavam em casas que o mapa bloqueia com X m por casa — <id>
  CASA_BLOQUEADA: (x,y) motivo; …`, com cada figura no mesmo texto do `MASTER_PLACE`.
- **`destinosDoRecomeco`.** Uma casa de colocação bloqueada na escala viva é mais um caso que a D-1 não cobre (a
  casa não está ocupada, é o mapa que a bloqueia). Como os outros casos (N34-2), o «Recomeçar» é recusado sem mexer
  em nada: `RECOMECAR_SEM_CASA: 1 figura voltava a uma casa de colocação que o mapa bloqueia com 2 m por casa — <id>
  CASA_BLOQUEADA: (6,4) menir`.
- **A lista para o ecrã.** `ErroRecusa` ganhou um terceiro campo opcional, `figuras`. Quando existe, o evento
  `recusa` leva `soMestre.figuras` (`[{figuraId, x, y, motivo}]`), só para o Mestre. As outras recusas ficam
  iguais, byte a byte: o campo só aparece quando há figuras a nomear.
- **Não inventei um segundo sistema.** Os textos saem de uma só função, `casaBloqueada`, que o `MASTER_PLACE`
  também passou a usar. A conferência usa o `bloqueada`/`motivo` do terreno, o mesmo do `passavel`.

### A recusa continua nomeada e visível

- **Nomeada.** O nome de cada figura e de cada casa vai no detalhe ao Mestre, como no `MASTER_PLACE`.
- **Visível.** No ecrã do Mestre, o recibo recusado já dava «O servidor não aceitou: Essa acção não é possível.».
  Agora o evento `recusa` com lista dá também um alerta que diz quem, onde e porquê (`mestre.gd`,
  `_avisar_figuras_bloqueadas` e `texto_figuras_bloqueadas`; os textos estão em `textos_mestre.gd`):
  - «A escala não mudou — o mapa bloqueia, na escala nova, a casa de: «Orc» (6,4) menir; … Primeiro, tire do
    caminho quem lá está.»
  - ««Recomeçar» não se fez — nesta escala o mapa bloqueia a casa de colocação de: «Heroína Teste» (6,4) menir.»

  Há um alerta por evento, e o mesmo `seq` repetido no fio não o repete. O alerta não leva nada técnico, nem os
  códigos nem `CASA_BLOQUEADA`.
- **A Ordem 60 fica como estava.** A marca na casa e o aviso nas duas arenas continuam a valer para qualquer figura
  que chegue a uma casa bloqueada por outro caminho (um snapshot, ou um journal gravado antes desta ordem).
- **Documentação.** O README do terreno (`servidor/dados/README.md`) e a descrição do schema `MASTER_SUPERVISOR`
  ganharam a regra. O schema em si não mudou: o `soMestre` do evento `recusa` já era um objecto livre.

## 3. Provas

| prova | antes | depois |
|---|---|---|
| `provas/ordem-62-escala/medir-escala-bloqueadas.mjs` | `medicao-antes.txt`: **35** figuras em casas bloqueadas | `medicao-depois.txt`: **0**. As 4 mudanças que deixavam figuras são recusadas com o porquê; 1,5 → 1 m e 2 → 1 m continuam APLICADA; o «Recomeçar» é recusado |
| `servidor/testes/ordem62-escala-bloqueadas.test.mjs` (6 testes) | `teste-ordem62-antes.txt`: **4 de 6 falham** com o `sala.js` de `7310391` | `teste-ordem62-depois.txt`: **6 de 6** passam, em 0,6 s |
| `pecas_mestre.gd`, secção «ordem 62» (8 verificações) | — | todas ok. O alerta nomeia cada figura, sem nada técnico; não se repete; uma recusa sem lista não o dá; o «Recomeçar» tem o seu texto |

O teste do servidor usa, em cada mudança, só as casas da grelha de 2 em 2 que a escala nova bloqueia, mais 6
livres. Assim cabe no limite de 30 s por teste do CI. A grelha inteira (215 a 225 figuras, cerca de 90 s) corre na
medição.

O que os 6 testes verificam:

1. A sonda da Ordem 58 é recusada, e a escala, as figuras e o mapa não mexem. As 7 figuras vão nomeadas no detalhe
   e na lista, e cada entrada da lista bate com a casa da figura.
2. Nas 6 mudanças, nenhuma deixa figuras em casas bloqueadas. As que não bloqueiam ninguém continuam a passar.
3. Tirada a figura do caminho, ou escolhida outra escala, a escala muda. A recusa não prende o Mestre.
4. A Party não vê o detalhe nem a lista.
5. O «Recomeçar» depois da escala é recusado com o nome. Ao voltar à escala da colocação, passa.
6. Sem terreno, a escala é como sempre.

## 4. As suites da linha

Corri tudo localmente sobre `58da89c`, com os scripts `_tmp/o62/servidor.sh` e `_tmp/o62/suites.sh` (os da Ordem
61, a apontar para `o62`). Todas as suites ficaram verdes.

| suite | resultado |
|---|---|
| servidor (`node --test`, com `--permission`) | **371 testes**: 361 passam, 10 são saltados, 0 falham. São os 365 da linha mais os 6 novos. |
| protocolo (tráfego dos testes) · schemas · terreno · validador-glb | saída 0 em todos |
| `abrir_scripts` | 83 scripts, 0 falhas |
| `rodar_testes` | 177 de 177 |
| `clima_forte` | 119 de 119 |
| `pecas_mestre` | **284 de 284**: os 276 da linha mais as 8 da Ordem 62 |
| `hud_acoes` | 50 de 50 |
| `abrir_clareira` · `abrir_mestre` · `canario_privacidade` | 22 de 22 · 67 de 67 · 10 de 10 |
| `medir_mestre` · `medir_painel_config` | 0 falhas, 0 sem medida |
| `provar_assentamento` · `provar_terreno_servidor` · `exportar_terreno --conferir` | TUDO PASSOU · TUDO PASSOU · terreno EM DIA |
| `provar_molde_54` | 0 falhas (retrato com 188 linhas) |
| `provar_mestre_no_relevo` · `provar_pes_bloqueadas` · `provar_recusa_no_ecra` | TUDO PASSOU (54, 59 e 62 ok) |
| arranque | «pronto» |

Nenhum registo tem SCRIPT ERROR, Parse Error ou Compile Error. O resultado do CI na ponta final vem no fim deste
documento.

## 5. Os commits

| commit | o quê |
|---|---|
| `61f5350` | A medição de antes (o script e `medicao-antes.txt`), sem código. |
| `58da89c` | A correcção (`sala.js`), o alerta do Mestre, o teste novo do servidor, as 8 verificações do `pecas_mestre`, o README do terreno, a descrição do schema, a medição de depois e os registos dos testes. |
| (este) | Este ESTADO. |
| (a seguir) | As listas da retoma e o MANIFESTO refeitos pelo gerador. |

## Fica de fora, sem rodeios

1. **Salas gravadas antes desta ordem.** O restauro carrega o estado tal como está, sem re-executar comandos. Uma
   sala gravada com figuras já em casas bloqueadas (pelo buraco antigo) abre assim. O servidor não as conserta: a
   arena marca-as e avisa, pela Ordem 60. Daí em diante, a escala dessa sala só muda para uma grelha em que
   nenhuma figura fique bloqueada.
2. **Recusar, não mover.** A Ordem 58 deixou duas saídas em aberto: recusar com nome, ou mover para a casa livre
   mais próxima. Segui a da colocação, que recusa. Mover seria regra nova (quem decide a casa, e o que acontece à
   reserva da vez), e isso é palavra do Mestre.
3. **O «Recomeçar» recusado** obriga o Mestre a voltar à escala da colocação (ou a terminar e começar de novo).
   Tratar a casa bloqueada como uma casa ocupada da D-1 (a «casa livre mais próxima») também seria regra nova.
4. **O alerta do Mestre fica cortado na coluna 1**, como na reserva 1 da Ordem 60 (`max_lines_visible = 2`). Com
   muitas figuras, a lista completa fica em `alertas` e no detalhe do registo.
5. **A recusa genérica continua lá.** O recibo recusado dá também «O servidor não aceitou: Essa acção não é
   possível.», como em todas as recusas. Ficam dois alertas por recusa de escala: o genérico e o que diz porquê.
6. **O `MASTER_PLACE` numa casa bloqueada** continua a dar só o alerta genérico no ecrã do Mestre (o porquê vai ao
   registo), como antes desta ordem. A recusa do `MASTER_PLACE` não traz lista. Não a mudei, porque a ordem é a da
   escala. Para lhe dar o mesmo alerta, bastaria passar a lista de uma figura no `recusaCasa`.

## CI

- **`58da89c` (a correcção, publicada antes deste ESTADO).** O run `43762547245` deu 8 de 9 jobs verdes: servidor,
  protocolo, validador-glb, motor-real, cliente, godot-cliente, ponta-a-ponta e foto-mestre. A sonda de privacidade
  (`43762547216`) ficou verde. O job `retoma-pc` falhou como era de esperar: «CLONE DIFERENTE» nos 6 ficheiros
  mudados, porque as listas da retoma (`retoma-i0004/depois.txt`) só se refazem depois do commit, pelo gerador.
- **Ponta final.** Depois deste ESTADO vem o commit das listas e do MANIFESTO, feito pelo gerador, e é esse que
  repõe o `retoma-pc`. O resultado do CI nessa ponta não pode estar escrito no próprio commit: fica no relatório de
  fecho ao coordenador.
