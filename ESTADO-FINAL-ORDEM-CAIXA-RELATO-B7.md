# ESTADO-FINAL — Ordem CAIXA-RELATO-B7

`Estado.limpar()` limpa `eventos_desde_snapshot` (D4 da conferência da CAIXA-RELATO-CORRECOES; o defeito estava
latente e nunca chegou a disparar).

- **Executor:** conta 2, no PC do cunhado.
- **Base:** `0418d18`, a ponta de `fable/integracao-50` à hora do lançamento. A linha não avançou durante a ordem.
- **Ramo:** `claude2/caixa-relato-b7`, sem fusão.
- **Commits:**
  - `61f1d7c`: a correcção e o teste;
  - `8942046`: as listas da retoma (`actualizar-listas`);
  - o commit deste ESTADO-FINAL, que só acrescenta este ficheiro.

## 1. O que mudou

- **`rascunhos/cliente/estado/estado.gd`, `limpar()`:** passa a fazer `eventos_desde_snapshot = []` antes de emitir
  `snapshot_aplicado`. São 3 linhas, com o comentário. Não mexi em mais nada do Estado.
- **`provas/ordem-caixa-relato/ferramentas/teste_relato_caixa.gd`:** ganhou o caso novo `_caso_limpar` (5
  verificações) e uma linha no cabeçalho. O CI já corre este teste (passo «Relato da caixa»), por isso o workflow não
  mudou.
- **`MANIFESTO-SHA256.txt` e `retoma-i0004/depois.txt`:** o SHA novo do `estado.gd`, gerado pelo `actualizar-listas`.

### Porque escolhi corrigir o `limpar()` e não o `_registar_snapshot`

A ordem deixava escolher entre as duas correcções. Escolhi a do `limpar()` por quatro razões:

1. **O defeito está no Estado, não nas provas.** Depois de um `limpar()` o Estado diz que não tem snapshot
   (`tem_snapshot = false`), e mesmo assim guardava a lista dos eventos «desde o snapshot». Essa lista vinha de um
   snapshot que já não existe. O `limpar()` repõe todo o resto do estado (`_espera`, `_arma_de`, `caixa`…); este campo
   era o único que ficava para trás.
2. **Há um consumidor no jogo, além das provas.** O HUD repete esta lista quando nasce
   (`hud.gd` `_repetir_eventos_antes_do_hud`). O `limpar()` corre quando a jogadora sai ou muda de lugar
   (`rede.gd:152` e `rede.gd:362`). Se um HUD nascesse depois disso e antes de um snapshot novo, repetiria eventos da
   sessão de antes. Corrigir só o `_registar_snapshot` deixava este caminho aberto.
3. **O `_registar_snapshot` não está em `rascunhos/`.** Vive nas ferramentas das provas
   (`prova_caixa_jogadora.gd:245` e `prova_caixa_manequim.gd:333`), por isso seriam duas cópias a emendar.
   E ignorar o sinal deixaria o contador do relato preso ao snapshot velho, enquanto o Estado já não tem snapshot
   nenhum. As duas fontes continuariam desalinhadas, só que ao contrário.
4. **O sinal continua a ter o mesmo sentido.** `snapshot_aplicado` quer dizer «o ponto de partida mudou». Com a
   correcção, o Estado e quem o ouve recomeçam os dois do zero. A lista é limpa antes do `emit`, que é a mesma ordem
   que o `aplicar_snapshot` usa (`estado.gd:159`).

## 2. O caso reproduzido

O teste usa o Estado real (`res://estado/estado.gd`), instanciado fora da árvore, sem Rede e sem Mestre. Liga os
sinais da mesma forma que as provas: `snapshot_aplicado` chama `RelatoCaixa.novo_snap` e `evento_aplicado` chama
`RelatoCaixa.anotar_evento`. Cada passo é conferido com a verificação B2 das provas: a contagem e os tipos do relato
têm de ser iguais aos de `Estado.eventos_desde_snapshot`, pela mesma ordem.

| Passo | Relato | Estado | Antes da correcção | Depois |
|---|---|---|---|---|
| snapshot seq 1 + `movimento` + `turno` | 2 `[movimento, turno]` | 2 | ok | ok |
| `limpar()` (o Estado fica sem snapshot e sem eventos) | — | 2 → 0 | **FALHA** (ficavam 2) | ok |
| B2 depois do `limpar()`, sem snapshot novo | 0 `[]` | 2 `[movimento, turno]` → 0 | **FALHA** | ok |
| um evento chega ainda sem snapshot (fica à espera, não é aplicado) | 0 | 2 → 0 | **FALHA** | ok |
| snapshot seq 5 + `turno` | 1 `[turno]` | 1 | ok | ok |

- **Antes da correcção** (o teste novo sobre o `estado.gd` da base): **23/26**, com as 3 falhas acima.
- **Depois da correcção:** **26/26**.

As figuras do caso só têm ids opacos e o snapshot não traz `propria` nem nomes. Não há vida, alma, PA nem dados do
Mestre no teste nem no registo.

## 3. Corridas

Todas correram neste PC, sobre `61f1d7c`, com o Godot 4.7.2 (`Godot_v4.7.2-stable_win64.exe`) e o Node 26.13.0.

| Corrida | Resultado |
|---|---|
| Servidor (`node --test --test-isolation=none testes/*.test.mjs`) | **418/418** |
| Prova da caixa do servidor (`prova-servidor.mjs`) | PROVA OK |
| Teste do relato (`teste_relato_caixa.gd`) | **26/26** (eram 21; o caso B7 acrescenta 5) |
| `rodar_testes` | 290/290 |
| `caixa_janela` | 69/69 |
| `caixa_jogadora` | 18/18 |
| `canario_privacidade` | 10/10 |
| `hud_acoes` | 50/50 |
| `pecas_mestre` (chama `Estado.limpar()`) | 286/286 |
| `abrir_mestre` | 67/67 |
| `abrir_scripts` | 107 scripts, 0 falhas |

- Nenhum registo tem `SCRIPT ERROR`, `Parse Error` nem `Compile Error`.
- **CI:** 10/10 jobs verdes, incluindo o retoma-pc (ver a §5).

## 4. Pontos para o coordenador

1. **Escolhi corrigir o `limpar()`** (ver a §1). As ferramentas das provas não mudaram e continuam a ouvir
   `snapshot_aplicado`. Com a correcção, o «zero» do relato e o do Estado coincidem depois de um `limpar()`.
2. **O caminho do HUD (§1, ponto 2) também ficou fechado.** Não escrevi um teste próprio para ele, porque seria um
   teste de HUD e ficava fora da fronteira. O teste novo prova que a lista fica vazia, e é dessa lista que o HUD lê.
3. **Não toquei no HUD, nas cores nem no protocolo.** As provas vivas da caixa (HUD-JOGADORA e MANEQUIM) não voltaram
   a correr. Elas não chamam `limpar()`, por isso esta correcção não muda o que mostram.
4. **Ambiente:** este PC continua sem o `_console.exe` do Godot e com o Node 26. O servidor correu sem
   `--permission`, como nas ordens anteriores.

## 5. CI

**Verde em `8942046`** (run 44976465341 e run 44976465327):

- **Sonda de privacidade:** success.
- **Testes dos rascunhos:** os **10/10 jobs** passaram: protocolo, validador-glb, cliente, motor-real, **retoma-pc**,
  foto-mestre, provas-mapa, servidor, godot-cliente e ponta-a-ponta.
- **No registo do CI:** o servidor deu `418/418` e o teste do relato deu
  `teste do relato da caixa: 26 de 26 verificações passaram.`
