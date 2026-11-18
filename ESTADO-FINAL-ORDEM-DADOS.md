# ORDEM DADOS DE APRESENTAÇÃO — ESTADO FINAL (18/11/2026)

Sessão na nuvem (Claude Code, Opus) que cumpriu `ORDEM-CONTINUACAO.md` no ramo `claude1/dados-apresentacao`.
Marcas: VERIFICADO (conferido nesta sessão), RECUPERADO (lido nos commits/ficheiros), PENDENTE.

## O que a ordem entrega

- **Fatia 1** (`3110347`) — RECUPERADO: `rascunhos/cliente/dados/apresentacao.gd`, a tabela única de apresentação
  do cliente (anéis, 5 raridades, 8 escolas de dano, papéis de interface, tamanhos da mesa, ecrã e letra, câmara).
  Cada valor é o literal que já estava no código em `fable/integracao-50 @ cbe7729`. Nada de combate.
- **Fatia 2** (`82b45e5`) — RECUPERADO: HUD, lobby, Mestre, arenas, campo da mesa, marcador, câmara e clareira lêem da
  tabela, sem mudar valor nenhum.
- **Fatia 2b** (`4ad7dfd`) e listas (`7f5bbdd`) — RECUPERADO: dois reverts ditados pela CI (run 230 falhou na `82b45e5`):
  - `grelha_floresta.gd` e `relevo_floresta.gd` voltam ao original. São fontes do terreno do servidor, conferidas por SHA.
  - As listas do `retoma-pc` (`retoma-i0004/depois.txt`) e o `MANIFESTO-SHA256.txt` foram refeitos na ponta.

## Regras duras: cumpridas (VERIFICADO na tabela, `PENDENCIAS`)

- Papéis bronze, ouro, sangue, lendário, raro e mágico ficam **sem hex**, registados como pendência. Nenhum hex inventado.
- A casa fica em **1,5 m** (grelha_floresta, relevo_floresta, arena, arena_mestre, clareira_prova). A pendência está
  registada com o número: a ordem diz 1,0 m e o cliente usa 1,5 m. Não se mudou.
- Ainda pendentes na tabela:
  - a casa do mapa, que só se religa quando o terreno se refizer;
  - o degrau, que não tem tamanho de apresentação;
  - as alturas por tipo de GLB, porque não há importação que escale modelos;
  - as `CORES_DANO`, que continuam PROVISÓRIO.

## 1. Suite verde nos dois fluxos — VERIFICADO

Ponta `5471387` (a mesma árvore de código de `7f5bbdd`, mais a ordem):
- **Sonda de privacidade**, run 44220760315: success.
- **Testes dos rascunhos**, run 44220760425: os 9 jobs passaram (success):
  - servidor, validador-glb, motor-real, protocolo;
  - cliente, godot-cliente (`200 de 200 verificações passaram.`);
  - ponta-a-ponta (motor falso e VLAB real), foto-mestre, retoma-pc.

Depois da linha junta (secção 3), a CI corre outra vez na ponta: merge da Ordem HUD + listas refeitas + este `.md`. A CI
dele corre no push. O resultado fica no Actions do ramo e no merge.

## 2. ESTADO FINAL commitado — VERIFICADO

É este ficheiro, `ESTADO-FINAL-ORDEM-DADOS.md`, na raiz do ramo.

## 3. Merge para `fable/integracao-50`

### Erro resolvido: a linha andou durante a sessão

- **Problema** (VERIFICADO): no início da sessão, `fable/integracao-50` estava em `cbe7729`. A primeira versão deste
  ficheiro (`bdcefe5`) dava por isso o merge como *fast-forward*. Na busca feita POR ÚLTIMO, a linha já estava em
  `9e92de3`: a Ordem HUD (`claude2/hud`, `a85d104` + `9e92de3`) tinha entrado entretanto. O fast-forward deixou de
  ser possível e **não se empurrou nada** para a linha nesse momento.
- **Causa:** duas ordens em paralelo sobre a mesma linha. O estado da linha foi lido no início, não no momento do merge.
- **Solução:** a linha `9e92de3` entrou neste ramo com um merge a sério (`46308f7`).
  - Conflitos só em `MANIFESTO-SHA256.txt`, `retoma-i0004/depois.txt` e `ORDEM-CONTINUACAO.md` (os dois ramos
    criaram-no).
  - O código juntou-se sem conflito: `mestre.gd`, `arena_mestre.gd`, `medir_mestre.gd` e `rodar_testes.gd`. A tabela
    manteve os nomes das constantes (`COR_LINHAS`, `FONTE_BASE`…), por isso a caixa da ordem e os retratos não
    precisam de mudar. Não há declarações repetidas.
  - As listas foram refeitas com `retoma-i0004/actualizar-listas.py`: depois.txt = 402, MANIFESTO = 447 (5 novos).
    Os SHA de `mestre.gd` e `hud.gd` foram conferidos à mão contra a árvore.
  - A ordem de continuação da HUD foi arquivada, sem perda, em `ORDEM-CONTINUACAO-HUD.md`.
- **Prevenção:** buscar a linha imediatamente antes de empurrar e empurrar só se ela for antepassada. Foi o que
  impediu o erro de chegar à linha.

### O merge

- **Por último:** com a CI verde na ponta deste ramo (merge + listas + este ficheiro), `fable/integracao-50`
  avança para essa ponta. É um fast-forward a partir de `9e92de3`, que já é antepassado.
- **Prova:** `git rev-parse origin/fable/integracao-50` tem de dar a ponta deste ramo.
- **Se o push falhar:** um commit a seguir regista-o aqui. Nesse caso o ramo fica completo à espera do merge.

## Próximo passo (PENDENTE, reservado ao Mestre)

Dar hex final aos 6 papéis da paleta e decidir a casa (1,0 m ou 1,5 m). Se a casa mudar, o terreno do servidor tem de
ser refeito com `exportar_terreno.gd`, e grelha e relevo passam então a ler da tabela.
