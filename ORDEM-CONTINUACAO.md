# ORDEM DE CONTINUAÇÃO — MISSÃO HUD (caixa de ordem de turnos + retratos)

Sessão na nuvem que continua a missão neste ramo `claude2/hud` (ponta 2d36af0 à data da ordem). Modelo: Opus. Trabalha por fatias com commits frequentes.

## Já feito
- Fatia 1 — modelo `hud/ordem_turnos.gd` + 13 testes em `rodar_testes.gd` (suite 199/199 à data).
- Fatia 2 — `hud/retratos.gd` (palco SubViewport por figura com CÓPIA do seu próprio modelo, busto, fundo = cor do anel de ID escurecida); `hud/caixa_ordem.gd` (cartão da figura activa + fila com retratos + botão «Modo iniciativa»); integração em `mestre.gd` (a caixa sobre o tabuleiro, interruptor no separador Sala) e `arena_mestre.gd` (`modelo_da_figura`); ferramenta de prova `testes/video_ordem.gd`.

## Falta
1. Suite verde nos dois fluxos.
2. Vídeo/capturas de prova: a ordem dinâmica a formar-se 1-2-3-monstro e a repetir; o botão de iniciativa a actualizar a caixa; um retrato por tipo de figura a condizer com a figura da cena; caixa desligada = batalha exactamente como hoje.
3. ESTADO FINAL commitado no repositório.
4. POR ÚLTIMO, depois de buscar a linha junta: merge para `fable/integracao-50`. Se o ambiente web não conseguir empurrar o merge, deixa o ramo completo e diz isso no ESTADO FINAL.

## Pendências registadas (NÃO resolver, só registar)
- O servidor não rola iniciativa — os valores vêm da configuração do Mestre (sala.js iniciativaDe, TODO JV0.6a); o modo iniciativa mostra a ordem da vista `iniciativa`; rolar = pendência do servidor.
- A escolha do Mestre (caixa ligada/desligada, modo) vive só no cliente dele; levá-la aos jogadores precisa de um campo no servidor; a caixa ainda não está no HUD do jogador.
- A ordem dinâmica forma-se no cliente do Mestre; se ele voltar a entrar a meio da batalha, recomeça vazia (o registo do servidor guarda só tipos de evento).
- Cores da caixa + fundo por omissão dos retratos → tabela de apresentação da ordem DADOS.
