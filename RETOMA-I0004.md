# PARA O CLAUDE DO PC — RETOMA (CM-000008-I0004, 08/11/2026)

Este ficheiro é o ponto de retoma do trabalho que o Claude 2 (conta 2, instância **CM-000008-I0004**) fez na nuvem a 08/11/2026, com o PC desligado. Quem continuar no PC **não vê a conversa da nuvem**: tudo o que é preciso está aqui, no ramo, nos READMEs e no Notion (página de passagem «Passagem Claude ⇄ Muse», secção «PARA O CLAUDE DO PC — RETOMA», e a Central dos Claudes).

Antes de tocar em qualquer coisa, o ritual da casa: **Central dos Claudes → INBOX → página de passagem**.

## 1. Onde está tudo

- **Repositório:** `arthof09-ai/jogo-verdadeiro-rascunhos`.
- **Ramo do trabalho:** `i0004/ci4-protocolo`, criado a partir do `main` no commit `9cbaca88b6e4951d41e518579afd3b32d846fee6` (ponte IBX-281). **O `main` não foi tocado.**
- **Último commit com código:** `43b7cbcf8c53bf0dd4d4b0e7de42d87f324da1e0` (ecrã do Mestre, §12 do desenho: L8 no servidor, arena 3D, aba Mesa, «Voltar até aqui» e aba Agir; 08/11 à tarde). O commit seguinte só actualiza este ficheiro.
- **CI do ramo:** 6 jobs (`servidor`, `validador-glb`, `motor-real`, `protocolo`, `cliente`, `retoma-pc`), todos verdes no run `42512227636` (commit `43b7cbc`).
- **Ficheiros mudados:** 17 mudados e 62 novos em `rascunhos/` (79 no total), com SHA-256 antes e depois em `retoma-i0004/antes.txt` e `retoma-i0004/depois.txt`. O `MANIFESTO-SHA256.txt` já tem os SHA novos (143 ficheiros).
- **As listas fazem-se sozinhas:** depois de cada commit que mude `rascunhos/`, correr `python3 retoma-i0004/actualizar-listas.py` na raiz e juntar as listas ao commit. Se alguém se esquecer, o job `retoma-pc` fica vermelho.
- **READMEs com o detalhe:** `rascunhos/protocolo/README.md` e `rascunhos/cliente/README.md`.
- **Notion:** errata 0.2 da JV1.1-b (a comparação com o site), carta IBX-300 (a 4.ª corrida), página de passagem e Central.

## 2. Estado de cada frente

| Frente | Estado | Onde | Próximo passo |
| --- | --- | --- | --- |
| Servidor | Remendo IBX-298, regra dos 25% do quebrar (REF_19), «voltar» que repõe os cartões (REF_21/24), guarda REF_17. **Ecrã do Mestre:** L1 (nome, nome público, vida total e PA total de cada figura na vista do Mestre), L2 (lista de desgraças no cartão; edição fora dela recusada) e L8 (`MASTER_VIEW.pontos`: os pontos a que o «voltar» aceita ir, só para o Mestre). Fixture real do ecrã do Mestre (`dados-exemplo/mesa-mestre.json`, conferida por `fixture-mestre.test.mjs`, com os cenários «mestre», «lobby» e «agir»). **69/69** no CI; motor real 1/1 | `rascunhos/servidor/` | Entrar no PC e no `main` (§3) |
| Protocolo v2 | 26 schemas conferidos contra o tráfego real (6.002 mensagens, zero falhas), 5 schemas novos do Mestre, exemplos reais, job `protocolo`. L1: `#/$defs/figuraMestre`; L2: `MASTER_CARD.desgracas` e `#/$defs/desgracaEditavel`; L8: `MASTER_VIEW.pontos` e `#/$defs/ponto`. Ferramenta nova `validar-mensagens.py` (os comandos do ecrã do Mestre passam nos schemas: 5/5 e 9/9) | `rascunhos/protocolo/` (README) | Apertar `vez`, `lobby` e `cartoes` do bloco `mestre`; erratas D-xx contra a JV0.4 |
| Cliente Godot | Corre no CI (Godot 4.7.2 oficial, sem janela): **26 scripts** compilam, **73/73**, arena e lobby arrancam. Uma só tabela de perfis; frases do site na desgraça, morte e fim; «Atualiza a página». Segunda tranca de privacidade: `rede.gd` não guarda `MASTER_*` e `estado.gd` não guarda o bloco `mestre` fora do lugar do Mestre. Os passos Godot do CI falham se houver SCRIPT ERROR | `rascunhos/cliente/` (README) | Botão Recomeçar (e a cláusula guardada); resposta 7 do Mestre |
| Comparação com o site (REF_8 → REF_25) | **Completa**; errata 0.2 da JV1.1-b | Notion, JV1.1-b | — |
| Clareira de prova | Cena feita (`arte/cenas/clareira_prova.tscn`), abre no CI (**22/22**); pontilhado das copas desligado | `rascunhos/cliente/arte/` | Assets da V2.1; abrir num computador com GPU para ver os shaders |
| Ecrã do Mestre | **Desenho APROVADO COM EMENDAS** pelo Muse (rascunho 0.2). **Feito:** (a) L1 e L2 no servidor; (b) a cena `cenas/mestre/` (recusa noutro papel, 4 cartões com as palavras do site, nada por tempo, aviso da 1.ª entrada uma vez só) — **32/32**; canário de privacidade **10/10**; (c) ecrã baixo F5-MESTRE-01 — **45/45**, letra 13,0 px reais; **§12:** L8 no servidor, arena 3D (`arena_mestre.gd`), aba Mesa (procurar, guardar a mesa, começar, colocar), «Voltar até aqui» (pontos da L8, dois passos) e aba Agir (modo H10, mover/atacar/acções das opções do servidor) — **29/29**. Terminar/recomeçar **não existe** (`TODO(N4-TERMINAR)`, espera a N4) | `rascunhos/cliente/cenas/mestre/` (README do cliente, secção «Ecrã do Mestre»); Notion: «JV3.1 — Ecrã do Mestre no cliente: desenho aprovado com emendas (rascunho 0.2)» | Ver §5 |
| Perguntas ao Mestre | 13 perguntas na Central, com o que o jogo faz hoje, e 3 novas do desenho do ecrã do Mestre (N2–N4; a N4 com o «terminarBatalha» do site, M-014) | Notion, Central | Aplicar as respostas quando chegarem |

## 3. O passo do PC — receita completa

Objectivo: pôr o original do PC (`C:\Users\txcga\RPG_Local\jogo-verdadeiro\`) igual ao ramo e levar o ramo ao `main`.

### Avisos antes de começar

- **Os dois patches do Drive estão SUPERADOS pelo ramo: NÃO aplicar nenhum.** São `I0004-CI4-combinado-IBX298-REF19.patch` (o da carta IBX-300) e `I0004-CI4-passo2-voltar-cartoes.patch` (o do «Voltar»). No Drive ficaram com o nome começado por «SUPERADO —». O ramo leva o que eles tinham e mais.
- **Não aplicar à mão as 3 trocas da IBX-298:** já estão no ramo.
- **Com Node 22, os testes correm com `node --test testes/*.test.mjs`** (o Node 22 recusa `node --test testes/`). O CI usa Node 24. Não é preciso correr os testes no PC: o CI já os correu.
- **Regra da casa NAC-OV-05:** nada corre no PC sem pacote e Críticos. Esta receita é o pacote; só copia ficheiros e confere SHA, não corre código do jogo. O script está ensaiado num Windows pelo job `retoma-pc` do CI (incluindo o caso em que o PC divergiu e ele pára sem copiar).
- **Fins de linha:** os SHA são dos bytes do repositório. Clonar **sempre** com `-c core.autocrlf=false`, senão o Git do Windows mete CRLF e os SHA não batem.

### Passos (PowerShell)

1. **PC LIVRE.** Sem sessão do cunhado activa; nada pesado a correr.
2. **Clonar o ramo para uma pasta temporária:**
   ```powershell
   git clone -c core.autocrlf=false --branch i0004/ci4-protocolo https://github.com/arthof09-ai/jogo-verdadeiro-rascunhos "$env:TEMP\jvr-i0004"
   cd "$env:TEMP\jvr-i0004"
   git log --oneline -5
   ```
   Confirmar que o commit `43b7cbc` aparece no histórico.
3. **Ensaio (não escreve nada):**
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\retoma-i0004\aplicar-no-pc.ps1
   ```
   Tem de acabar com `ENSAIO OK`. Se disser `PARAR`, **não continuar**: o original do PC mudou desde o `9cbaca8`. Avisar o Muse na Central, com a lista que o script imprimiu.
4. **Copiar a sério:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\retoma-i0004\aplicar-no-pc.ps1 -Aplicar
   ```
   Tem de acabar com `FEITO: 79 ficheiros no PC iguais ao ramo`. Faz uma cópia de segurança dos 17 substituídos em `C:\Users\txcga\RPG_Local\jogo-verdadeiro-antes-i0004-<data>`.
5. **Levar o ramo ao `main` (em linha recta, sem fusão):**
   ```powershell
   git fetch origin main
   git rev-parse origin/main
   ```
   Tem de dar `9cbaca88b6e4951d41e518579afd3b32d846fee6`. Se der outra coisa, o `main` mexeu: **parar** e avisar o Muse. Se der esse, então:
   ```powershell
   git merge-base --is-ancestor origin/main HEAD; if ($LASTEXITCODE -eq 0) { git push origin HEAD:main } else { Write-Host 'PARAR: nao e linha recta' }
   ```
   Depois, ver o CI do `main` verde (`gh run list --branch main --limit 1`, ou a página Actions).
6. **Drive (ponte):** subir para `RPG Assimilação/12 — Código/jogo-verdadeiro/` (pasta `1uouRMbs_CLzuTAizP9YUVDuE2f0DdScG`) os 79 ficheiros de `retoma-i0004/depois.txt` e o `MANIFESTO-SHA256.txt` novo, conferindo os SHA. É o passo de sempre da ponte, do Muse.
7. ~~Apagar o ramo temporário `i0004/sonda-frases`~~ — **FEITO pelo Muse (CM-000009) a 08/11/2026**; o ramo já não existe. Não há nada a fazer neste passo.
8. **Registar:** na Central, uma linha assinada com o ID completo e o formato `[AAAA-MM-DD HH:MM] [ID] texto` (o original do PC igual ao ramo, o commit no `main`, o CI); marcar a carta IBX-300 como CONCLUÍDA, com a evidência.

## 4. Regras em vigor (palavra do Mestre, passada pelo Muse)

- Modelo **Opus 5.5**, esforço **Alto**.
- Permissões operacionais: sempre **«Permitir sempre»**.
- **Bastão das cartas PARADO** por palavra do Mestre.
- **IBX-216 e IBX-222 continuam NOVA** (sem ACK na base).
- **Pontilhado das copas das árvores DESLIGADO** até à palavra do Mestre (`USAR_PONTILHADO_COPAS = false` em `clareira_prova.gd`).
- **Frases do site aplicadas tal como estão, com «tu»**, até o Mestre responder à pergunta tu/você.
- As regras da casa da sucessão de 08/11 continuam: ritual Central → INBOX → passagem; uma peça, um dono; NAC-OV-06 (um jogo só); NAC-OV-05; nada preso só ao Claude ou ao PC; toda a mudança no jogo avisada por carta em 5 pontos; perguntas ao Mestre pelo Muse com a marca PERGUNTA PARA O MESTRE; motores não se traduzem; só fichas fictícias; privacidade Mestre/Party absoluta.

## 5. Próximo passo nomeado

O ecrã do Mestre (JV3.1) já tem tudo o que a revisão do Muse e o §12 do desenho pediram: as partes (a), (b) e (c), a L8 no servidor, a arena 3D, a aba Mesa, o «Voltar até aqui» e a aba Agir. Está verde no CI (run `42512227636`). **Terminar/recomeçar a batalha não entra** até o Mestre responder à pergunta N4.

O que falta no ecrã do Mestre (por ordem):

1. **Ver o ecrã a correr ligado ao servidor de verdade.** Uma corrida de ponta a ponta no CI: servidor Node + cliente Godot sem janela a fazer de Mestre (lobby → colocar → combate → cartão → voltar). Hoje os testes usam a fixture real, mas sem a ligação WebSocket.
2. **«Escolher outra» acção no cartão de IA.** Precisa que o servidor mande ao Mestre as opções da criatura com o cartão aberto (hoje `opcoesDoLugar` devolve null com cartão activo). É uma lacuna nova, a L10.
3. **L5 e L6.** O lote de colocação por esquema e o agrupar das marchas puras por rodada.
4. **L9.** O selo TESTE e as estatísticas, só no papel Mestre (C-28).
5. **O olho do Mestre.** A arena 3D tem marcadores provisórios; o visual é do Plano B.

As respostas do Mestre às 13 + 3 perguntas aplicam-se quando chegarem.

— CM-000008-I0004
