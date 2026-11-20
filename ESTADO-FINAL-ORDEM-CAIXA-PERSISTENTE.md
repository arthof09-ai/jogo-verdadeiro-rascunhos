# ESTADO FINAL — ORDEM CAIXA-PERSISTENTE (Claude 2, conta 2, VM do coordenador · retoma 2, 2026-11-19)

Ordem: `ORDEM-CAIXA-PERSISTENTE.md` (commit `8f6ddf2`). Pendências (2) e (4) da Ordem HUD.
Marcas: VERIFICADO (conferido nesta sessão), PENDENTE (com a razão), [FALTA] (sem fonte).

## Sucessão
- 1.ª corrida (conta 2, 19/11 ~12:40–13:03): construiu servidor + cliente + prova do servidor + suítes, tudo em disco
  e por commitar; fez um merge local `323b726` (nunca empurrado); morreu no limite de 5 h.
- Retoma (conta 1, 21:02): não arrancou — OAuth da conta 1 expirado na VM (`corrida-caixa3.log`).
- Retoma 2 (esta, conta 2, 21:04): partiu do ponto exacto — nada descartado; o diff da 1.ª corrida foi conferido
  ficheiro a ficheiro e cometido tal como estava.

## 1. A escolha da caixa vive no servidor — VERIFICADO
- `servidor/nucleo/ordem-dinamica.js`: `MODOS_CAIXA`, `caixaMestrePadrao()` (ligada, dinâmico — a de sempre no
  cliente), `caixaBemFormada()`, `caixaParaVista()`.
- `servidor/nucleo/sala.js`: `estado.caixaMestre` ao lado da `ordemDinamica` da INICIATIVA (no journal); a
  `MASTER_VIEW` leva `caixaMestre`; `MASTER_SUPERVISOR op 'caixa'` com `caixa: {ligada, modo}` exactos →
  `escolherCaixa`. Sem evento (não é facto da batalha), sem ponto novo do «voltar», revisão igual, a Party não sabe.
  Aceite com cartão aberto e em pausa (a caixa aparece nas duas). Não se apaga no «Recomeçar» nem volta atrás no
  «voltar» (é preferência de apresentação do Mestre, não mundo).
- `servidor/nucleo/conferir-estado.js`: journals de antes abrem (sem o campo → a de omissão); `caixaMestre` estragado
  (ligada não booleana, modo desconhecido, campo a mais) não abre.
- Protocolo v2: `MASTER_SUPERVISOR.schema.json` (op `caixa` + `caixa`, exclusões com `ateSeq`/`casaM`),
  `MASTER_VIEW.schema.json` (`$defs/caixaMestre`, fora do `required`). `dados-exemplo/mesa-mestre.json` refeito.
- Cliente (mudança mínima, `cenas/mestre/mestre.gd`): `ligar_caixa` e `definir_modo_iniciativa` mandam
  `_guardar_caixa()`; `aplicar_vista` chama `_carregar_caixa_do_servidor(msg.caixaMestre)` — a vista manda,
  excepto enquanto a escolha que o Mestre acabou de fazer está em voo (`_caixa_cmd`). Vista sem o campo (servidor de
  antes) não mexe. `foto_sem_caixa.gd` e `video_ordem.gd` (sem servidor) devolvem um id fixo ao op `caixa`.
- Privacidade: só um booleano e um modo; nenhum dado de vida/alma; só na vista do Mestre.

## 2. Tabela de apresentação DADOS — VERIFICADO (aplicada onde define), PENDENTE (onde não define)
- `hud/caixa_ordem.gd`: `COR_REALCE := Apresentacao.COR_MESTRE_ANEL` (ffd28b — o mesmo literal de antes; ecrã igual).
- `hud/retratos.gd`: a cor de identificação do retrato já vinha da tabela (`PALETA_ANEIS`, pelo anel do marcador).
- PENDENTE — sem valor na tabela, fica o literal da Ordem HUD (nenhuma cor inventada):
  - `caixa_ordem.gd COR_PAINEL` = Color(0.07, 0.09, 0.12, 0.78) — fundo do painel da caixa;
  - `caixa_ordem.gd COR_MOLDURA` = Color(1, 1, 1, 0.18) — moldura;
  - `retratos.gd COR_FUNDO_PADRAO` = 27303a — fundo do retrato sem cor de identificação.
- Valores RESERVADOS À PALAVRA DO MESTRE encontrados na tabela (`apresentacao.gd PENDENCIAS` + ESTADO FINAL DADOS),
  nenhum tocado por esta ordem:
  - [FALTA] hex final dos 6 papéis da paleta: bronze, ouro, sangue, lendário, raro, mágico;
  - [FALTA] a casa: 1,0 m (a ordem DADOS) ou 1,5 m (o cliente hoje);
  - `CORES_DANO` continuam PROVISÓRIO (V1.2, Plano B).

## 3. Provas — `provas/ordem-caixa/`
- **Cliente — o Mestre sai e volta a entrar a meio de uma batalha de bancada — VERIFICADO, 23/23** (`cliente/relato.txt`,
  código de saída 0). Servidor de mesa real (`ferramentas/servidor-bancada-prova.mjs`: a sala e o WebSocket do jogo, o
  cenário e as fichas de bancada, semente 7, motor VLAB real sha256 `a91c021c…`; não fecha quando o Mestre sai) e o
  ecrã do Mestre a sério (`mestre.tscn` pela Rede do jogo, Godot 4.7.2 com render llvmpipe, 1280×720), pela
  ferramenta `ferramentas/prova_caixa_reentrar.gd` (lançador `ferramentas/correr-prova-caixa.sh`):
  0. a IA de bancada joga 3 vezes (Arqueira, Lobo, Espadachim) → ordem dinâmica de 3 no servidor; o Mestre da bancada sai;
  1. o Mestre entra: caixa como o servidor a guarda (ligada, dinâmico) — `1-entrou.png`;
  2. «Modo iniciativa» → `caixaMestre` = ligada, iniciativa na MASTER_VIEW — `2-iniciativa.png`;
  3. SAI (`Rede.sair`, ecrã fechado) e VOLTA A ENTRAR com o PIN: a caixa reconstrói-se no modo iniciativa, visível, com
     a MESMA ordem dinâmica — `3-reentrou-iniciativa.png` (vista com olhos: «Ordem de turnos · iniciativa», Bruto na vez);
  4. desliga a caixa, sai e volta a entrar: a caixa vem desligada e não aparece — `4-reentrou-desligada.png` (vista com
     olhos: sem caixa);
  5. liga e repõe o dinâmico (a sala fica como estava) — `5-religada.png`;
  nenhum comando do Mestre recusado; as duas heroínas nunca receberam `caixaMestre`.
  A sala está em `pausa` quando o Mestre volta (pausa por ausência do Mestre, regra de antes desta ordem): é «a meio da
  batalha» e a caixa aparece em pausa.
- **Servidor — VERIFICADO** (`prova-servidor.log`, `ferramentas/prova-servidor.mjs`, 1.ª corrida): omissão; escolha
  sem evento, sem ponto novo do «voltar», revisões iguais, Party 0 mensagens; sair/entrar; em pausa e com cartão aberto;
  reabrir do journal (com, sem e com campo estragado); «voltar» e «Recomeçar» não mexem na escolha; 7 formas mal
  formadas recusadas; a Party nunca vê `caixaMestre`. `PROVA OK`.
- Sha256 (16) das capturas: 1 `9becf2fc7e05cf6c` · 2 `2e94f94748301a37` · 3 `c5e626f4f98d63da` ·
  4 `aa02ad4366766a18` · 5 `304e54fe3b1c787a`.

## 4. Testes — VERIFICADO
- CI do GitHub (`testes.yml` + `privacidade.yml`) no `e97784f` (código desta ordem fundido com `9ed3d18`): **tudo
  verde** — servidor, validador-glb, motor-real, protocolo, cliente, godot-cliente, ponta-a-ponta, foto-mestre,
  retoma-pc; sonda de privacidade verde (runs 44647277322 e 44647277172).
- O CI do `38a124b` falhou só no `retoma-pc` (listas da retoma por refazer: «CLONE DIFERENTE» nos 11 ficheiros da
  ordem) — o passo de sempre, feito em `e97784f` com `retoma-i0004/actualizar-listas.py`.
- Locais (1.ª corrida, `provas/ordem-caixa/suites/`): servidor 375/375; rodar_testes 226/226; abrir_scripts 104/0
  falhas; abrir_mestre 67/67; pecas_mestre 286/286; hud_acoes 50/50; canário de privacidade 10/10; abrir_clareira
  22/22; medir_mestre e painel ⚙ 0 falhas; comandos contra os schemas 26/0 falhas; arranque «pronto».

## 5. Commits e fusão
- `8f6ddf2` ficheiro da ordem · `323b726` merge local da 1.ª corrida (integração `e09ba96`; nunca empurrado, fica na
  história) · `46baba1` o código, os schemas e as provas da 1.ª corrida · `38a124b` merge de
  `origin/fable/integracao-50` em `9ed3d18` (ÁGUA-REAÇÃO), sem conflitos · `e97784f` listas da retoma e MANIFESTO ·
  o commit deste ESTADO FINAL: a prova do cliente (`provas/ordem-caixa/cliente/`, `ferramentas/prova_caixa_reentrar.gd`,
  `ferramentas/correr-prova-caixa.sh`).
- Fusão em `fable/integracao-50`: fast-forward de `9ed3d18` para a ponta desta branch, DEPOIS do CI verde nela (a branch
  contém `9ed3d18`, por isso não há merge novo). A confirmação (`git ls-remote`) fica num commit a seguir.
- **FEITA — VERIFICADO:** CI verde no `37421e7` (Testes dos rascunhos + Sonda de privacidade, success); push
  `9ed3d18..37421e7 HEAD -> fable/integracao-50` (fast-forward); `git ls-remote`: `fable/integracao-50` =
  `claude2/caixa-persistente` = `37421e770e1a25bd314eafe7412fe4393bf43bee`. Este registo (só este ficheiro) segue no
  commit seguinte, também em fast-forward nas duas.

## Passagem
- O que mudou: a escolha da caixa do Mestre (ligada, modo) é estado do servidor (`caixaMestre`, journal, MASTER_VIEW, MASTER_SUPERVISOR op `caixa`); o cliente reconstrói a caixa com ela ao reentrar; o realce da caixa lê da tabela DADOS.
- Onde parou: provas verdes (cliente 23/23, servidor PROVA OK), CI verde, fusão fast-forward em `fable/integracao-50`.
- Próximo passo: palavra do Mestre sobre os valores [FALTA] (6 papéis da paleta, casa 1,0/1,5 m); depois disso, as 3 cores da caixa/retrato sem valor na tabela (painel, moldura, fundo do retrato) entram na tabela e ligam-se. A caixa no HUD da jogadora (o resto da pendência 2 da HUD) já tem o campo no servidor, mas não entra nesta ordem.
- O que falta conferir: o olho do Mestre nas capturas `provas/ordem-caixa/cliente/1…5`; a conferência do coordenador desta entrega (tamanho + SHA + cauda).
