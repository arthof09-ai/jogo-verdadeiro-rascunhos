# ORDEM INICIATIVA NO SERVIDOR — ESTADO FINAL · 19/11/2026

Sessão na nuvem (conta 2) que cumpriu `ORDEM-INICIATIVA-SERVIDOR.md` no ramo `claude2/iniciativa-servidor` (base `ba3b16c`).
Etiquetas: **VERIFICADO** = corrido/visto nesta sessão, com evidência no repo ou no CI; **PENDENTE** = por fazer.

## Resumo
- **Ponto 2 (lançar a iniciativa): PARADO, como a ordem manda.** Não existe regra de lançamento nas fontes (ver abaixo).
  Fica como **PENDÊNCIA DO MESTRE**.
- **Pontos 1, 3, 4 e 5: feitos.** O servidor passa a ser o dono da ordem. Guarda a ordem dinâmica (entradas, saídas,
  atrasos) no estado da sala e manda-a ao Mestre. A caixa do Mestre volta igual quando ele reentra a meio da batalha.
- A linha `fable/integracao-50` andou durante a sessão (`ba3b16c` → `58b39d9`, Ordem NADO). Foi buscada e fundida no
  ramo antes das provas. As provas e o CI são da árvore fundida.

## O que foi feito

### 1. O servidor é o dono da ordem de turno — VERIFICADO
- A **ordem de iniciativa** (`estado.ordem`) já era do servidor. Forma-se em `MASTER_START` e no «Recomeçar» por
  `ordenarPorIniciativa` sobre `iniciativaDe`. Vai a todos no snapshot como `iniciativa`: só a ORDEM, nunca os valores.
  Não se mexeu nisto.
- A **ordem dinâmica** (a da caixa do Mestre, Ordem HUD) passa a viver também no servidor:
  - `rascunhos/servidor/nucleo/ordem-dinamica.js` (novo, puro, sem `node:*`). São as regras de
    `cliente/hud/ordem_turnos.gd` passadas para o servidor **sem regra nova**:
    - conta como «agiu» o mesmo de lá: `movimento`, `ataque` que não é de oportunidade, `cura`, `consumivel` e `acao`
      da vez (nunca `sem_desgraca`);
    - várias acções seguidas da mesma figura contam como uma vez;
    - a 1.ª acção de uma figura **entra** no fim;
    - quando alguém repete, a volta fecha;
    - fora da sequência (**atraso**/adiantamento ditado pelo Mestre), a figura passa para depois de quem agiu antes;
    - o «Recomeçar» limpa.
  - `sala.js`:
    - `estado.ordemDinamica = {ordem, fechada, ultimo, vezes}` nasce vazia e volta a vazia a cada `MASTER_START`;
    - regista-se em `finalizar`, pelos eventos de cada transacção, pela ordem em que aconteceram;
    - está em `CHAVES_MUNDO`, por isso vai no journal (sobrevive ao reinício do servidor) e nos pontos do «voltar»:
      voltar a um ponto repõe a ordem desse ponto;
    - a `MASTER_VIEW` leva `ordemDinamica: {ordem, fechada, ultimo}`. Na `ordem` só ficam figuras **colocadas**:
      quem **sai** da batalha não aparece.
  - `conferir-estado.js`: no restauro confere a forma e as referências de `ordemDinamica` (ids de figuras que existem,
    booleano, contador). Pode faltar nos journals de antes desta ordem.
  - Protocolo `MASTER_VIEW.schema.json`: campo `ordemDinamica` com `additionalProperties: false`. É opcional, para as
    vistas de antes.
- **Diferença assumida face ao cliente de antes:** no «Voltar até aqui», o cliente limpava a caixa porque não tinha
  como a refazer. Agora o servidor repõe a ordem do ponto a que se volta, com o resto do mundo.

### 2. Lançamento da iniciativa — PARADO (PENDÊNCIA DO MESTRE)
**PENDÊNCIA DO MESTRE — regra de lançamento da iniciativa não existe nas fontes.**

Procurei em todo o repositório: código, notas, ESTADOS, README do servidor, protocolo, fichas e cenários. O que existe:
- `sala.js` `iniciativaDe`: `// TODO(JV0.6a errata): iniciativa ainda não é campo da ficha; vem da config do Mestre.`
  Devolve o valor da config, ou 0.
- `servidor/README.md`: «Iniciativa: ainda não é campo da ficha. Hoje vem da config do Mestre e precisa de errata à
  JV0.6a.»
- `ROOM_SNAPSHOT.schema.json`: `iniciativa` é a ORDEM, nunca os valores.
- `autojogo/cenario-bancada.json` e os testes têm valores fixos na config (ex.: 16/14/12/10; 973/971/…).
- As fichas têm `testes` (ataque, fortitude, percepção) e **nenhum** teste de iniciativa.

Nenhuma fonte diz que dado, quantas faces, nem o que se soma. Por isso não se inventou fórmula nem dado. A ordem
continua a sair dos valores da config do Mestre, e um lançamento entra quando o Mestre escrever a regra.

### 3. Ordem dinâmica no servidor e reentrada do Mestre — VERIFICADO
`provas/ordem-iniciativa/prova-servidor.log` (sala real, motor falso dos testes):
- **A ordem inicial é igual para todos:** `iniciativa` igual no Mestre, nas duas jogadoras e no espectador, que voltam
  a entrar depois do START.
- **Volta e fecho:** a ordem forma-se Heroína → Aliada → Lobo → Orc. A Heroína age outra vez e a volta fecha.
- **Entrada a meio:** um bandido é posto a meio da batalha.
- **Reentrada:** o Mestre **sai e volta a entrar** e a `ordemDinamica` vem igual (ordem, fechada, última).
- **Journal:** a sala reaberta do journal (`exportar` → `criarSala({restaurarDe})`) dá a mesma `ordemDinamica`.
- **Atraso** (o exemplo do Mestre, 16/11): j1 → j3 → j2 → m.
- **«Voltar»** ao ponto em que a Aliada andou: Heroína → Aliada, por fechar.

`provas/ordem-iniciativa/prova-reentrada-godot.log` (o `mestre.tscn` real, Godot 4.7.2):
- a caixa formada por eventos numa sessão do ecrã;
- um ecrã **novo** que só recebe a MASTER_VIEW com a ordem do servidor mostra a **mesma caixa e a mesma vez** (3/3);
- controlo: com a ordem vazia do servidor, a caixa fica vazia.

### 4. Mudança mínima no cliente — VERIFICADO
- `hud/ordem_turnos.gd`: `carregar_do_servidor(d)` põe a ordem do servidor por cima da que se formou. Se a vista não
  a traz, não mexe.
- `cenas/mestre/mestre.gd`: uma linha em `aplicar_vista`.
- Os eventos continuam a adiantar a caixa até à vista seguinte, com as mesmas regras e o mesmo resultado. Também servem
  um servidor de antes.
- `testes/video_ordem.gd` (ferramenta de vídeo, fora do CI): tira `ordemDinamica` da fixture. O guião inventa os
  eventos sem servidor.
- A fixture `servidor/dados-exemplo/mesa-mestre.json` foi regenerada pelo próprio teste (`ESCREVER_FIXTURE=1`). Só
  ganhou o campo novo, vazio.

### 5. Sem campos novos de vida/alma — VERIFICADO
- `ordemDinamica` tem só `ordem` (ids), `fechada` (booleano), `ultimo` (id ou null) e, no estado, `vezes` (contador).
  A prova lista as chaves.
- Vai **só** na MASTER_VIEW (o lugar do Mestre). A prova confirma que nenhuma mensagem da heroína, da aliada ou do
  espectador contém `ordemDinamica`.
- O canário de privacidade do cliente fica 10/10.

## Prova da construção

### Local — VERIFICADO
Árvore fundida; logs em `provas/ordem-iniciativa/suites/`.
- **Servidor:** 375/375. Correu num só processo com o Node 22, opção `--experimental-test-isolation=none`.
- **Schemas:** conferência contra o tráfego real com **0 falhas** nas mensagens que saem; as 406 MASTER_VIEW levam
  `ordemDinamica`.
- **Godot 4.7.2:**
  - abrir_scripts 104/0;
  - rodar_testes 226/226;
  - abrir_mestre 67/67;
  - pecas_mestre 286/286;
  - medir_mestre 0 falhas;
  - hud_acoes 50/50;
  - canário 10/10;
  - painel ⚙ 0 falhas;
  - abrir_clareira 22/22;
  - comandos do Mestre contra os schemas 9/0 e 26/0;
  - **arranque «pronto»**.
- **Ponta a ponta** (servidor Node + jogadora + Mestre Godot, motor falso): **17/17**, jogadora OK.

### CI — ver «CI» no fim

## Pendências nomeadas
- **PENDÊNCIA DO MESTRE — regra de lançamento da iniciativa não existe nas fontes.** Que dado, quantas faces, o que se
  soma, desempates. Com a regra escrita, o lançamento entra em `MASTER_START` e no «Recomeçar», sobre `iniciativaDe`.
- A escolha do modo da caixa (dinâmico/iniciativa) e o ligar/desligar continuam só no cliente do Mestre. A ordem não
  pedia isto, e a caixa não está no HUD da jogadora. Vem da Ordem HUD, sem mudança.
- `servidor/README.md` não foi actualizado com `ordemDinamica`. Fica para o coordenador, junto com os testes formais
  desta ordem, que a ordem reserva para ele.
- Os pontos do «voltar» de um journal restaurado continuam a ser só os que vêm depois do restauro (TODO JV1.x de
  antes). Até lá, a ordem dinâmica volta pelo journal, não pelos pontos.

## Ficheiros
- **Servidor:**
  - `rascunhos/servidor/nucleo/ordem-dinamica.js` (novo);
  - `nucleo/sala.js`;
  - `nucleo/conferir-estado.js`;
  - `dados-exemplo/mesa-mestre.json` (regenerado).
- **Protocolo:** `rascunhos/protocolo/v2/MASTER_VIEW.schema.json`.
- **Cliente:**
  - `rascunhos/cliente/hud/ordem_turnos.gd`;
  - `cenas/mestre/mestre.gd`;
  - `testes/video_ordem.gd`.
- **Listas:** `MANIFESTO-SHA256.txt` e `retoma-i0004/depois.txt`, refeitas com `actualizar-listas.py` na árvore
  fundida.
- **Provas:** `provas/ordem-iniciativa/`.

## CI — VERIFICADO
O código é `5e3104f`: o ramo com a linha `fable/integracao-50` @ `58b39d9` já fundida.
- **Testes dos rascunhos:** **success, 9/9 jobs** (run 44554890527). Os jobs são servidor, validador-glb, motor-real,
  protocolo, cliente, godot-cliente, ponta-a-ponta, foto-mestre e retoma-pc.
- **Sonda de privacidade:** **success** (run 44554890601).

## Fusão em `fable/integracao-50`
- **Procedimento:**
  1. Este ESTADO e as provas entram por último no ramo.
  2. A linha é buscada outra vez.
  3. Se ainda estiver em `58b39d9`, que já está dentro do ramo, a fusão é um **fast-forward** da linha para a ponta do
     ramo, à maneira das ordens DADOS e NADO.
- O resultado e a confirmação por `git ls-remote` ficam no fim deste ficheiro.
