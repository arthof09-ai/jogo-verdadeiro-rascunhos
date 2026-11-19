# Provas da Ordem INICIATIVA NO SERVIDOR (19/11/2026)

Corridas na sessão da nuvem sobre a árvore FUNDIDA (`claude2/iniciativa-servidor` com `fable/integracao-50` @ `58b39d9`).
Node 22.23.5 (o CI usa 24 no servidor); Godot 4.7.2 oficial (zip com SHA-256 `cadd3204…29e4`), headless.

- `prova-servidor.log` — `ferramentas/prova-servidor.mjs`: a sala real com o motor falso dos testes. Ordem inicial igual
  para Mestre, duas jogadoras e espectador; ordem dinâmica a formar-se e a fechar; Mestre sai e volta a entrar a meio
  da batalha (igual); sala reaberta do journal (igual); o atraso; o «voltar»; sem chaves de vida/alma; a Party nunca
  recebe `ordemDinamica`. Corre com `node provas/ordem-iniciativa/ferramentas/prova-servidor.mjs` (o caminho do
  repositório está escrito no topo do ficheiro: `/home/user/jogo-verdadeiro-rascunhos/`).
- `prova-reentrada-godot.log` — `ferramentas/prova_reentrada.gd`: o ecrã do Mestre real (`mestre.tscn`). A caixa
  formada por eventos numa sessão; um ecrã NOVO (o Mestre que voltou a entrar), sem eventos, só com a MASTER_VIEW do
  servidor, mostra a mesma caixa e a mesma vez. Corre com
  `godot --headless --path rascunhos/cliente -s <caminho absoluto>/prova_reentrada.gd`.
- `suites/` — as suites do CI corridas cá: servidor 375/375 (um só processo), conferência dos schemas contra o
  tráfego (0 falhas nas mensagens que saem), abrir_scripts 104/0, rodar_testes 226/226, abrir_mestre 67/67,
  pecas_mestre 286/286, medir_mestre 0 falhas, hud_acoes 50/50, canário 10/10, painel ⚙ 0 falhas,
  abrir_clareira 22/22, arranque «pronto», ponta a ponta (motor falso) 17/17 com a jogadora OK (`suites/e2e/`).
