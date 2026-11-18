# ORDEM HUD — ESTADO FINAL (caixa da ordem de turnos + retratos) · 18/11/2026

Sessão na nuvem que cumpriu `ORDEM-CONTINUACAO.md` no ramo `claude2/hud` (ponta à chegada `80cb3e2`). Godot 4.7.2
oficial descarregado para a sessão; render por software (Mesa llvmpipe) em Xvfb; sem GPU.
Etiquetas: **VERIFICADO** = corrido/visto nesta sessão, com evidência no repo ou no CI; **RELATADO** = dito por outra
sessão, não refeito aqui; **PENDENTE** = por fazer.

## O que a missão entrega (fatias 1 e 2 da sessão anterior + esta sessão)
- `hud/ordem_turnos.gd` — o modelo: modo **dinâmico** (a ordem forma-se pelas acções e repete-se) e modo
  **iniciativa** (a ordem `iniciativa` da vista do servidor).
- `hud/caixa_ordem.gd` — a caixa: cartão de quem está na vez + fila com retratos + botão «Modo iniciativa».
- `hud/retratos.gd` — um palco (SubViewport) por figura com a CÓPIA do próprio modelo em cena, em busto, fundo = cor do
  anel de identificação escurecida.
- `cenas/mestre/mestre.gd` — a caixa sobre o tabuleiro (só em combate/pausa) e o interruptor na aba Sala;
  `arena_mestre.gd` — `modelo_da_figura`.

## Os quatro pontos da ordem

### 1. Suite verde nos dois fluxos — VERIFICADO
- **Achado à chegada:** o CI «Testes dos rascunhos» estava **vermelho** desde a fatia 2 (`1d2b724`, `2d36af0`,
  `80cb3e2`). Só um job falhava: `retoma-pc` («CLONE DIFERENTE»: `arena_mestre.gd`, `mestre.gd`, `rodar_testes.gd`).
  - Causa: a fatia 2 mudou `rascunhos/` sem correr `retoma-i0004/actualizar-listas.py`.
  - Solução: listas e MANIFESTO refeitos (`7e1d167`).
  - Prevenção: depois de cada commit que mude `rascunhos/`, correr o script. É a regra do `RETOMA-I0004.md` §1. Num
    clone raso, fazer primeiro `git fetch --unshallow`, porque o script precisa do commit base `9cbaca8`.
- `7e1d167`: Sonda de privacidade **success** (run 44225561354); Testes dos rascunhos **success, 9/9 jobs**
  (run 44225561304).
- Ponta do código `36f7ccb` (correcção da caixa + listas): Sonda **success** (run 44227043781); Testes dos rascunhos
  **success, 9/9 jobs** (run 44227043735), incluindo `medir_mestre` com as verificações novas e `foto-mestre`.
- Local, Godot 4.7.2 headless em `cd0cfb6`, com logs em `provas/ordem-hud/suites/`:
  - abrir_scripts 102 / 0 falhas;
  - rodar_testes **226/226**;
  - abrir_clareira 22/22;
  - painel ⚙ 0 falhas;
  - abrir_mestre 67/67;
  - pecas_mestre 286/286;
  - medir_mestre 0 falhas (inclui as 9 verificações novas da caixa);
  - hud_acoes 50/50;
  - canário 10/10;
  - arranque «pronto»;
  - schemas 9/9 e 26/26.

### 2. Vídeo e capturas de prova — VERIFICADO (`provas/ordem-hud/`, ver o README da pasta)
- **Ordem dinâmica a formar-se 1-2-3-monstro e a repetir:**
  - `videos/ordem-turnos.mp4` (26,6 s);
  - `capturas/caixa-dinamica.png` e `caixa-repete.png`;
  - `guiao.json`: ordem `[J1, J2, J3, Orc]` após o 4.º golpe; na segunda volta a vez passa J1 → J2 → J3 → Orc com a
    ordem igual.
  - É um guião de DEMONSTRAÇÃO (a Jogadora 3 é uma cópia «demo» da Aliada).
- **Botão de iniciativa actualiza a caixa:** `caixa-iniciativa.png`. A fila passa à `iniciativa` da vista e entra o
  Lobo, que não tinha agido. Ao desligar, volta a ordem das acções.
- **Um retrato por tipo de figura a condizer com a figura em cena:**
  - `retrato-humanoide|orc|lobo.png`;
  - `retrato-vs-cena-*.png`: o retrato ao lado da figura;
  - os modelos em cena são os marcadores do site (peão e oval do lobo) e o retrato é a cópia deles.
- **Caixa desligada = a batalha exactamente como hoje:**
  - `capturas/caixa-desligada.png`;
  - prova píxel a píxel em `comparacao/`: a foto com a caixa desligada e a da árvore de antes da missão (`cbe7729`) têm
    **o mesmo SHA-256** (0 píxeis diferentes, 4 corridas iguais);
  - controlo: com a caixa ligada diferem 54 116 píxeis, só na zona da caixa;
  - ressalvas: a aba Sala tem o botão novo, e os palcos dos retratos já criados ficam em memória.

### Defeito encontrado nas capturas e corrigido — VERIFICADO (`cd0cfb6`)
- **Problema:** com a caixa ligada, o botão «Entrar na câmera livre» ficava **tapado** (o mesmo canto do tabuleiro).
  Dentro da câmara livre, a caixa tapava o «Voltar à câmera do jogo» e a dica.
- **Causa:** a caixa era posta em `(margem×2, margem×2)`, o mesmo sítio do botão. Nenhum teste media os dois juntos.
- **Solução:** `mestre.gd` `_posicionar_caixa()`.
  - A caixa vai para baixo dos controlos de cima do tabuleiro.
  - Se, dentro da câmara livre, tocar num controlo de andar, sai de cena até o Mestre sair dela e volta sozinha. Isto
    acontece em 780×360, onde toca no seletor de velocidade.
  - A posição refaz-se ao entrar e ao sair, pelo sinal do «Entrar» em diferido.
- **Prevenção:** `testes/medir_mestre.gd` tem 3 verificações por janela (fora, dentro e de volta), em 844×390, 780×360
  e 1920×1080. Com o `mestre.gd` anterior dão **6 falhas**; agora dão 0.
- Ainda nesse commit:
  - a etiqueta do vídeo diz o nome de quem está na vez, não o id;
  - `testes/foto_sem_caixa.gd`, a ferramenta da comparação (fora do CI).

### 3. ESTADO FINAL commitado — VERIFICADO (este ficheiro)

### 4. Merge para `fable/integracao-50` — ver «Merge» no fim

## Pendências registadas (NÃO resolvidas, como a ordem manda)
- **O servidor não rola iniciativa.** Os valores vêm da configuração do Mestre (`sala.js` `iniciativaDe`, TODO JV0.6a).
  O modo iniciativa mostra a ordem da vista `iniciativa`. Rolar fica como pendência do servidor.
- **A escolha do Mestre vive só no cliente dele** (caixa ligada/desligada, modo). Para chegar aos jogadores é preciso um
  campo no servidor. A caixa ainda não está no HUD do jogador.
- **A ordem dinâmica forma-se no cliente do Mestre.** Se ele voltar a entrar a meio da batalha, recomeça vazia, porque o
  registo do servidor guarda só tipos de evento.
- **As cores da caixa e o fundo por omissão dos retratos** vão para a tabela de apresentação da ordem DADOS.
- (nova, desta sessão) Em ecrãs muito baixos (780×360), **dentro da câmara livre a caixa não aparece**, porque não há
  lugar sem tapar um controlo. Fora da câmara livre aparece sempre. A decisão de layout fica para o Mestre, se quiser
  outra coisa.

## Riscos e notas
- As provas visuais são de llvmpipe, sem GPU. Os nomes 3D grandes das figuras sobrepõem-se à caixa em zoom próximo
  (`caixa-iniciativa.png`). É o comportamento dos nomes que já existia e não se mexeu.
- Com a caixa desligada, os SubViewports dos retratos já criados ficam vivos. Não se desenham no ecrã; o custo na GPU
  não foi medido (PENDENTE, num PC com GPU).

## Ponto de retoma
Ordem cumprida. Próximo passo, fora desta ordem: o olho do Mestre sobre `provas/ordem-hud/` e a decisão sobre as
pendências acima (iniciativa no servidor; a caixa no HUD do jogador).

## Merge
- A linha `fable/integracao-50` buscada nesta sessão está em `cbe7729`, a base deste ramo. Não tem commits novos, por
  isso o merge não tem conflitos.
- Feito por último, depois deste ESTADO, como merge `--no-ff` («a caixa da ordem une-se à linha»), à maneira das ordens
  anteriores.
- O resultado do push fica na linha seguinte, num commit só de documento.
