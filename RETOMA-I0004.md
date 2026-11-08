# PARA O CLAUDE DO PC — RETOMA (CM-000008-I0004, 08/11/2026)

Este ficheiro é o ponto de retoma do trabalho que o Claude 2 (conta 2, instância **CM-000008-I0004**) fez na nuvem a 08/11/2026, com o PC desligado. Quem continuar no PC **não vê a conversa da nuvem**: tudo o que é preciso está aqui, no ramo, nos READMEs e no Notion (página de passagem «Passagem Claude ⇄ Muse», secção «PARA O CLAUDE DO PC — RETOMA», e a Central dos Claudes).

Antes de tocar em qualquer coisa, o ritual da casa: **Central dos Claudes → INBOX → página de passagem**.

## 1. Onde está tudo

- **Repositório:** `arthof09-ai/jogo-verdadeiro-rascunhos`.
- **Ramo do trabalho:** `i0004/ci4-protocolo`, criado a partir do `main` no commit `9cbaca88b6e4951d41e518579afd3b32d846fee6` (ponte IBX-281). **O `main` não foi tocado.**
- **Último commit com código:** `64bce1035045733ac085664588e97795953f779f` (N4: «Terminar batalha» e «Recomeçar»; regra-mãe do Mestre aplicada: estabilizada = fim, a desgraça não se recusa, «tu»; 08/11 à tarde). O commit seguinte só actualiza este ficheiro.
- **CI do ramo:** 7 jobs (`servidor`, `validador-glb`, `motor-real`, `protocolo`, `cliente`, `ponta-a-ponta`, `retoma-pc`), todos verdes no run `42514853863` (commit `64bce10`).
- **Ficheiros mudados:** 19 mudados e 66 novos em `rascunhos/` (85 no total), com SHA-256 antes e depois em `retoma-i0004/antes.txt` e `retoma-i0004/depois.txt`. O `MANIFESTO-SHA256.txt` já tem os SHA novos (147 ficheiros).
- **As listas fazem-se sozinhas:** depois de cada commit que mude `rascunhos/`, correr `python3 retoma-i0004/actualizar-listas.py` na raiz e juntar as listas ao commit. Se alguém se esquecer, o job `retoma-pc` fica vermelho.
- **READMEs com o detalhe:** `rascunhos/protocolo/README.md` e `rascunhos/cliente/README.md`.
- **Notion:** errata 0.2 da JV1.1-b (a comparação com o site), carta IBX-300 (a 4.ª corrida), página de passagem e Central.

## 2. Estado de cada frente

| Frente | Estado | Onde | Próximo passo |
| --- | --- | --- | --- |
| Servidor | Remendo IBX-298, regra dos 25% do quebrar (REF_19), «voltar» que repõe os cartões (REF_21/24), guarda REF_17. **Ecrã do Mestre:** L1 (nome, nome público, vida total e PA total de cada figura na vista do Mestre), L2 (lista de desgraças no cartão; edição fora dela recusada) L8 (`MASTER_VIEW.pontos`: os pontos a que o «voltar» aceita ir), L10 (opções da criatura ao Mestre com o cartão de IA aberto), L6 (`MASTER_APPROVE.rodada`: «Continuar a rodada» nas marchas puras) e L9 (`MASTER_VIEW.selo` TESTE e `estatisticas`) — tudo só para o Mestre. Servidor de ponta a ponta em `e2e/`. **N4:** `MASTER_SUPERVISOR` `terminar`/`recomecar`. **Regra-mãe (vale o site):** estabilizada = fim; a desgraça não se recusa (sem «nenhuma»). Fixture real do ecrã do Mestre (`dados-exemplo/mesa-mestre.json`, conferida por `fixture-mestre.test.mjs`, com os cenários «mestre», «lobby» e «agir»). **80/80** no CI; motor real 1/1 | `rascunhos/servidor/` | Entrar no PC e no `main` (§3) |
| Protocolo v2 | 26 schemas conferidos contra o tráfego real (6.002 mensagens, zero falhas), 5 schemas novos do Mestre, exemplos reais, job `protocolo`. L1: `#/$defs/figuraMestre`; L2: `MASTER_CARD.desgracas` e `#/$defs/desgracaEditavel`; L8: `MASTER_VIEW.pontos` e `#/$defs/ponto`; L6: `MASTER_APPROVE.rodada`, `marchaLivreRodada`; L9: `MASTER_VIEW.selo` e `#/$defs/estatisticas`; N4: `MASTER_SUPERVISOR` `terminar`/`recomecar`, `ROOM_EVENT` `recomeco`, `fim` com `estabilizada`/`terminada`. Ferramenta nova `validar-mensagens.py` (os comandos do ecrã do Mestre passam nos schemas: 5/5 e 16/16) | `rascunhos/protocolo/` (README) | Apertar `vez`, `lobby` e `cartoes` do bloco `mestre`; erratas D-xx contra a JV0.4 |
| Cliente Godot | Corre no CI (Godot 4.7.2 oficial, sem janela): **27 scripts** compilam, **75/75**, arena e lobby arrancam. Uma só tabela de perfis; frases do site na desgraça, morte e fim; «Atualiza a página». A frase completa do site no fim («Aperta Recomeçar para jogar outra vez.») e textos em «tu» (regra-mãe). Segunda tranca de privacidade: `rede.gd` não guarda `MASTER_*` e `estado.gd` não guarda o bloco `mestre` fora do lugar do Mestre. Os passos Godot do CI falham se houver SCRIPT ERROR | `rascunhos/cliente/` (README) | Botão Recomeçar (e a cláusula guardada); resposta 7 do Mestre |
| Comparação com o site (REF_8 → REF_25) | **Completa**; errata 0.2 da JV1.1-b | Notion, JV1.1-b | — |
| Clareira de prova | Cena feita (`arte/cenas/clareira_prova.tscn`), abre no CI (**22/22**); pontilhado das copas desligado | `rascunhos/cliente/arte/` | Assets da V2.1; abrir num computador com GPU para ver os shaders |
| Ecrã do Mestre | **Desenho APROVADO COM EMENDAS** (rascunho 0.3 com a palavra do Mestre de 08/11). **Feito e verde:** (a) L1/L2; (b) a cena — **33/33**; canário **10/10**; (c) ecrã baixo sem falhas; §12, L5, L6, L9, L10 e **N4 («Terminar batalha» → «Sim, terminar»; «Recomeçar» → «Sim, recomeçar»)** — **48/48**; ponta a ponta — **16/16** e a jogadora OK. O cartão de desgraça só tem «Confirmar» e «Escolher outra» (regra-mãe: no site a rolagem não se deita fora) | `rascunhos/cliente/cenas/mestre/`, `rascunhos/servidor/e2e/`; Notion: «JV3.1 — … (rascunho 0.3)» | Ver §5 |
| Perguntas ao Mestre | **Respondidas pela palavra do Mestre de 08/11** (N4: «Claro que quero»; regra-mãe «todas as mecânicas do site seguem no Godot»). **Só a N3 (aparelho do Mestre) continua aberta.** Duas dúvidas ao Muse: a fonte do «§9.8» (conserto) e se os desvios B6/B7/B9 caem | Notion, Central | Aplicar as respostas quando chegarem |

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
   Confirmar que o commit `64bce10` aparece no histórico.
3. **Ensaio (não escreve nada):**
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\retoma-i0004\aplicar-no-pc.ps1
   ```
   Tem de acabar com `ENSAIO OK`. Se disser `PARAR`, **não continuar**: o original do PC mudou desde o `9cbaca8`. Avisar o Muse na Central, com a lista que o script imprimiu.
4. **Copiar a sério:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\retoma-i0004\aplicar-no-pc.ps1 -Aplicar
   ```
   Tem de acabar com `FEITO: 85 ficheiros no PC iguais ao ramo`. Faz uma cópia de segurança dos 19 substituídos em `C:\Users\txcga\RPG_Local\jogo-verdadeiro-antes-i0004-<data>`.
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
6. **Drive (ponte):** subir para `RPG Assimilação/12 — Código/jogo-verdadeiro/` (pasta `1uouRMbs_CLzuTAizP9YUVDuE2f0DdScG`) os 85 ficheiros de `retoma-i0004/depois.txt` e o `MANIFESTO-SHA256.txt` novo, conferindo os SHA. É o passo de sempre da ponte, do Muse.
7. ~~Apagar o ramo temporário `i0004/sonda-frases`~~ — **FEITO pelo Muse (CM-000009) a 08/11/2026**; o ramo já não existe. Não há nada a fazer neste passo.
8. **Registar:** na Central, uma linha assinada com o ID completo e o formato `[AAAA-MM-DD HH:MM] [ID] texto` (o original do PC igual ao ramo, o commit no `main`, o CI); marcar a carta IBX-300 como CONCLUÍDA, com a evidência.

## 4. Regras em vigor (palavra do Mestre, passada pelo Muse)

- Modelo **Opus 5.5**, esforço **Alto**.
- Permissões operacionais: sempre **«Permitir sempre»**.
- **Bastão das cartas PARADO** por palavra do Mestre.
- **IBX-216 e IBX-222 continuam NOVA** (sem ACK na base).
- **Pontilhado das copas das árvores DESLIGADO** até à palavra do Mestre (`USAR_PONTILHADO_COPAS = false` em `clareira_prova.gd`).
- **Regra-mãe do Mestre (08/11): «Todas as mecânicas do jogo do site foram aprovadas e têm que seguir no jogo do Godot.»** Onde o rascunho divergir do site, vale o site, e nada se inventa. A língua é «tu», como no site.
- As regras da casa da sucessão de 08/11 continuam: ritual Central → INBOX → passagem; uma peça, um dono; NAC-OV-06 (um jogo só); NAC-OV-05; nada preso só ao Claude ou ao PC; toda a mudança no jogo avisada por carta em 5 pontos; perguntas ao Mestre pelo Muse com a marca PERGUNTA PARA O MESTRE; motores não se traduzem; só fichas fictícias; privacidade Mestre/Party absoluta.

## 5. Próximo passo nomeado

**Feito e verde no CI** (run `42514853863`, 7 jobs):
- o ecrã do Mestre, com a revisão do Muse, o §12, a ponta a ponta e as lacunas L5, L6, L8, L9 e L10;
- a N4: «Terminar batalha» e «Recomeçar»;
- a regra-mãe nas respostas que já tinham fonte clara no site: estabilizada = fim (com a frase completa), a desgraça não se recusa, e a língua «tu».

O que vem a seguir (por ordem):

1. **Q12, «amigo ao alcance».** O VLAB só aceita um aliado «adjacente» ou «na linha» (`aliadosAoAlcance`). Falta a fonte da «leitura já julgada na casa», que deve estar com o Muse (provavelmente no BANCADA-DESGRACA-JULGAMENTO.md). Falta também resolver o dano que fica pendente na desgraça (`desgracaPendente`) do «acerta-amigo» e do «acerta-se»: ver primeiro como o site o resolve.
2. **Respostas do Muse a duas dúvidas:** a fonte do «§9.8» (conserto da arma; o site não tem conserto) e se a regra-mãe desfaz os desvios B6, B7 e B9 da JV1.1-b §8 (IBX-212).
3. **A ponta a ponta com o motor real (VLAB)** e com uma criatura em semi.
4. **Os marcadores 3D definitivos** da arena do Mestre (Plano B).
5. **N3** (o aparelho do Mestre): quando o Mestre responder.

— CM-000008-I0004
