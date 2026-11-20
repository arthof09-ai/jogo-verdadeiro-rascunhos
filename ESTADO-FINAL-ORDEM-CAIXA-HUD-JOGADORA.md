# ESTADO FINAL — ORDEM CAIXA-HUD-JOGADORA (Claude conta 1, PC · 20/11/2026)

Ordem: a caixa do Mestre no HUD da JOGADORA — a outra metade declarada na Passagem da CAIXA-PERSISTENTE.
Base: `fable/integracao-50` @ `f8f0c83`. Marcas: VERIFICADO (conferido nesta sessão), PENDENTE (com a razão), [FALTA] (sem fonte).

## 1. O que mudou

### Servidor — VERIFICADO
- `nucleo/projecao.js`: o ROOM_SNAPSHOT da Party (jogadoras e espectadores) leva `caixa` =
  `{ligada, ordemPor: 'dinamico'|'iniciativa', ordemDinamica: {ordem, fechada, ultimo}}`. O Mestre não o recebe
  (tem a `caixaMestre` na MASTER_VIEW). A sala de espera não o recebe (`mundoDeEspera` marca `salaDeEspera`).
- O campo chama-se `ordemPor` e não `modo`: a sonda de canários do servidor (testes/privacidade) falhou com `modo`,
  que é chave PROIBIDA à Party (o modo H10 das figuras, E-P11). A sonda mandou e cumpriu-se.
- **Privacidade — a ordem dinâmica DA PARTY** (`nucleo/ordem-dinamica.js caixaParaParty`; `sala.js
  estado.ordemDinamicaParty`): a do Mestre conta os `acao` (correr, defender, apanhar a arma…), que não saem para a
  Party. A da Party forma-se com as MESMAS regras, mas só pelos eventos TAL COMO A PARTY OS RECEBE (`finalizar` regista a
  projecção do evento para um espectador). Nada nela se deriva do que a jogadora não vê. Está no journal
  (`conferir-estado.js`: opcional, a mesma forma), nos pontos do «voltar» (`CHAVES_MUNDO`), limpa no `MASTER_START` e no
  «Recomeçar». Diferença assumida: uma figura que só agiu por um `acao` (ex.: só defendeu) está na caixa do Mestre e
  não na da jogadora até agir de forma visível.
- `escolherCaixa` (MASTER_SUPERVISOR op `caixa`): marca `snapshotsParty` → a Party recebe um ROOM_SNAPSHOT novo com a
  caixa (com `seqSnapshot`, como o anúncio da pausa V30: quem voltar recebe-o outra vez). O Mestre não recebe nada novo.
- `snapshotParaRevisao`: a `caixa` fica FORA do hash — mudar a caixa não sobe a revisão nem recusa uma intenção em voo
  por `revisao_antiga` (provado no teste: a jogadora move com a revisão de antes da escolha e é APLICADA).
- Protocolo v2: `ROOM_SNAPSHOT.schema.json` `$defs/caixaParty` (fora do `required`) em `paraJogadora` e `paraEspectador`.
- `dados-exemplo/mesa-mestre.json` refeito (`ESCREVER_FIXTURE=1`).

### Cliente Godot — VERIFICADO
- `hud/hud.gd`: a caixa no HUD da jogadora — as MESMAS peças do ecrã do Mestre (`hud/caixa_ordem.gd`,
  `hud/ordem_turnos.gd`, `hud/retratos.gd`), sem o botão «Modo iniciativa» (a escolha é do Mestre). Lê `Estado.caixa`
  no snapshot (e no `_ready`, porque o snapshot chega antes de a arena abrir — defeito apanhado pela prova); os eventos
  que ela recebe adiantam a ordem com as mesmas regras; modo iniciativa = `iniciativa` + `vezId`. Só aparece com a
  caixa ligada, na mesa, em combate (e em pausa). Sítio: canto de cima, à DIREITA (à esquerda estão a ⚙ e a ficha; em
  baixo a barra); a faixa e o aviso de cima encolhem dos dois lados por igual, continuam centrados.
- `estado/estado.gd`: `caixa` (do snapshot; limpa em `limpar`). `cenas/arena/arena.gd`: `modelo_da_figura(id)` (o
  retrato é a cópia da figura em cena, como no Mestre).
- **Tabela de apresentação:** o realce lê `Apresentacao.COR_MESTRE_ANEL` (já em `caixa_ordem.gd`); as cores das figuras
  nos retratos são as da tabela (`COR_FIGURA_*`, pela própria figura em cena). **As 3 cores sem valor ficam POR LIGAR**
  (literais da Ordem HUD, intocados): `caixa_ordem.gd COR_PAINEL`, `COR_MOLDURA`, `retratos.gd COR_FUNDO_PADRAO`.
  Nenhuma cor inventada.
- Biblioteca (regra permanente): a bib 5 (molduras Kenney Fantasy UI Borders) foi considerada; a caixa já existia no
  cliente e reutilizou-se, e a moldura é uma das cores [FALTA] — nenhum ficheiro da biblioteca foi pedido nem usado.

## 2. Provas — `provas/ordem-caixa-hud-jogadora/` (README com tudo)
- **Cliente — a jogadora entra a meio de uma batalha de bancada — VERIFICADO, 36/36** (`cliente/relato.txt`, rc 0).
  Servidor de mesa real (sala + WebSocket do jogo, cenário de bancada, semente 7, motor VLAB real `a91c021c…`), o
  cliente da jogadora a sério (`arena.tscn` + HUD pela Rede), Godot 4.7.2 Windows, render NVIDIA RTX 4060. Capturas
  VISTAS COM OLHOS:
  1. `1-entrou-dinamica.png` — a Espadachim entra: caixa ligada, dinâmica, Arqueira → Lobo → Espadachim, ela na vez;
  2. `2-iniciativa.png` — o Mestre escolhe «Modo iniciativa»: a caixa dela passa à iniciativa, Bruto na vez;
  3. `3-desligada.png` — o Mestre desliga: a caixa sai do HUD dela;
  4. `4-religada-avancou.png` — religada; Bruto e Arqueira jogam: a volta fecha pelos eventos, igual ao servidor;
  5. `5-reentrou.png` — ela sai e volta a entrar: a caixa reconstrói-se do snapshot, igual.
  Em 1, 4 e 5: nenhuma mensagem do Mestre chegou ao aparelho dela; a caixa só tem ligada/ordemPor/ordemDinamica; os
  textos da caixa não têm nome verdadeiro, vida nem PA (mostra «Lobo», «Bruto»; o Mestre vê «… de Bancada»).
- **Servidor — VERIFICADO** `rascunhos/servidor/testes/caixa-hud-jogadora.test.mjs` (5): omissão na Party e não no
  Mestre; escolha → 1 snapshot à Party, 0 ao Mestre, revisões iguais, intenção de antes vale; o defender entra na ordem
  do Mestre e não na da Party, e a da Party é exactamente a que o espectador forma com o que recebeu; canários; journal
  (com, sem e com o campo estragado), sala de espera sem caixa, «Recomeçar» limpa.
- **Cliente sem ecrã — VERIFICADO** `rascunhos/cliente/testes/caixa_jogadora.gd` 16/16: snapshot antes do HUD, eventos,
  iniciativa e `turno`, desligada, sem campo, lobby, MASTER_VIEW ignorada, e o sítio em 1920×1080, 1280×720, 844×390 e
  780×360 sem tapar a ⚙/ficha, a barra nem a faixa.

## 3. Testes
- Locais (PC, `provas/ordem-caixa-hud-jogadora/suites/`) — VERIFICADO: servidor **380/380**; schemas (tráfego dos testes)
  **0 falhas** nas mensagens que saem; abrir_scripts 105/0 falhas; rodar_testes 243/243; caixa_jogadora 16/16;
  hud_acoes 50/50; canário de privacidade 10/10; medir_painel_config 0 falhas; abrir_clareira 22/22; abrir_mestre
  67/67; pecas_mestre 286/286; medir_mestre 0 falhas; arranque «pronto». Sonda de privacidade (e-mails) limpa.
- CI do GitHub: ver §5.

## 4. Commits e fusão
- `fd7f978` código, schema, testes e provas · `0000a1a` listas da retoma e MANIFESTO (`actualizar-listas.py`).
- Ramo de CI `claude1/caixa-hud-jogadora` (os mesmos commits, por cima de `f8f0c83`); a fusão é fast-forward de
  `fable/integracao-50` depois do CI verde (o padrão da CAIXA). Ver §5.

## 5. CI e fusão — VERIFICADO
- CI do GitHub no `0000a1a` (ramo `claude1/caixa-hud-jogadora`): **Testes dos rascunhos success** (run 44785268944:
  servidor, validador-glb, motor-real, protocolo, cliente, godot-cliente, ponta-a-ponta, foto-mestre, retoma-pc — todos
  success) e **Sonda de privacidade success** (run 44785268838).
- O 1.º push foi recusado pelo GitHub: o token do PC não tem o âmbito `workflow` e o commit mexia no
  `.github/workflows/testes.yml` (o passo do `caixa_jogadora.gd`). Os commits ainda eram só locais: refiz-os sem essa
  mudança (o passo fica PENDENTE, YAML no fim). Nada foi forçado.
- **Fusão FEITA:** push fast-forward `f8f0c83..0000a1a -> fable/integracao-50`, depois do CI verde. `git ls-remote`:
  `fable/integracao-50` = `claude1/caixa-hud-jogadora` = `0000a1aec8a9e46bcb434d793d5786428dab3816`. Este ESTADO FINAL
  (só este ficheiro, fora de `rascunhos/`) segue no commit seguinte, também em fast-forward nas duas.

## Passagem
- **O que mudou:** a jogadora vê a caixa da ordem de turnos no HUD dela com a escolha do Mestre (ligada/desligada,
  dinâmico/iniciativa) lida do servidor (ROOM_SNAPSHOT `caixa`); a ordem dinâmica dela é formada só do que ela vê; a
  escolha do Mestre chega-lhe na hora, sem mexer na revisão.
- **Onde parou:** ordem cumprida — provas verdes (cliente 36/36, servidor 5/5, cliente sem ecrã 16/16), CI verde em
  `0000a1a`, fusão fast-forward em `fable/integracao-50` feita e confirmada.
- **Próximo passo:** (1) a palavra do Mestre sobre os [FALTA] — os 6 papéis da paleta e a casa 1,0/1,5 m; depois disso,
  as 3 cores (painel, moldura, fundo do retrato) entram na tabela DADOS e ligam-se nos dois ecrãs (Mestre e jogadora) de
  uma vez; (2) pôr o passo do `caixa_jogadora.gd` no CI (YAML abaixo) — precisa de um token com o âmbito `workflow`.
- **O que falta conferir:**
  - o olho do Mestre nas 5 capturas (`provas/ordem-caixa-hud-jogadora/cliente/`): o sítio (canto de cima à direita,
    por cima do lago nesta câmara) e o tamanho;
  - se a diferença assumida da ordem dinâmica (quem só agiu por um `acao`, ex.: só defendeu, não entra na caixa da
    jogadora) é a que o Mestre quer — a alternativa (a mesma ordem do Mestre) mostra à jogadora um facto que hoje o
    servidor não lhe dá (fail-closed: `acao` fora de CAMPOS_PERMITIDOS);
  - a conferência do coordenador desta entrega (tamanho + SHA + cauda).
- **Riscos registados:**
  - batalhas cheias em ecrãs muito baixos: a caixa cresce com o número de figuras (≈ 2,9 letras por figura) e a faixa
    de cima encolhe; com 2–4 figuras está medido e cabe (844×390, 780×360); com 8+ não foi medido (PENDENTE);
  - eventos que cheguem entre o snapshot e a abertura da arena não adiantam a caixa até ao snapshot seguinte (janela
    curta do lobby → arena);
  - a prova da CAIXA-PERSISTENTE (`provas/ordem-caixa/ferramentas/prova-servidor.mjs`, fora do CI) dizia «a Party não
    recebeu nenhuma mensagem» no op `caixa`: deixou de ser verdade por desenho desta ordem (agora recebe 1 snapshot);
    não se mexeu na prova antiga;
  - o `servidor-bancada-prova.mjs` da CAIXA não corre no Windows (caminhos `URL.pathname`); esta ordem usa uma cópia
    portátil em `provas/ordem-caixa-hud-jogadora/ferramentas/`; a antiga ficou intacta.

### O passo do CI por pôr (`.github/workflows/testes.yml`, job `cliente`, antes do «Canário de privacidade»)
```yaml
      - name: A caixa da ordem de turnos no HUD da jogadora (Ordem CAIXA-HUD-JOGADORA)
        if: always()
        run: |
          set -o pipefail
          timeout 120 "$GODOT" --headless --path . -s res://testes/caixa_jogadora.gd 2>&1 | tee "$RUNNER_TEMP/caixa_jogadora.gd.log"
          ! grep -E "SCRIPT ERROR|Parse Error|Compile Error" "$RUNNER_TEMP/caixa_jogadora.gd.log"
```
