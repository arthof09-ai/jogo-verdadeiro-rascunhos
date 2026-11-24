# Provas — ORDEM-D-AUD-16 (o cliente do Mestre abre directo no ecrã dele)

Bancada de rede verdadeira (`bancada-rede/lancar.ps1 -SemEspera -HostServidor 127.0.0.1 -Motor auto`, fichas `canario`):
o servidor de produção, o porteiro e **dois clientes Godot 4.7.2 com janela, abertos em simultâneo**, cada um com o seu
`user://`. O porteiro deixou no `lugar.cfg` de cada um o lugar dele (jogadora e Mestre). Os dois clientes arrancaram
pela **cena principal** (`project.godot` não mudou: `arena.tscn`). Capturas às 03:16:17 (-03) de 24/11/2026, na sessão 1
(o ambiente de trabalho real), com as duas janelas postas por cima das outras só durante a captura. Todos os nomes são
os fictícios das fichas da bancada.

| ficheiro | o que mostra |
|---|---|
| `capturas/c01-jogadora-abre-na-arena.png` | a **jogadora** abre na arena dela (`arena.tscn`): «A sua vez», Ataque / Mover / Consumível / Encerrar, FICHA |
| `capturas/c02-mestre-abre-no-ecra-dele.png` | o **Mestre** abre directo no ecrã dele (`mestre.tscn`): abas Figuras / Agir / Mesa / Ambiente / Registo / Sala, «Entrar na câmera livre», «Rodada 1 · vez de Heroína Teste». **Sem alertas** (sem o «A ligação caiu» do arranque, ver abaixo) |
| `capturas/c03-os-dois-clientes-em-simultaneo.png` | as duas janelas lado a lado, no mesmo instante |
| `logs/godot-mestre.log` | o `godot.log` do cliente do Mestre. Linha 4: **`arranque: lugar do Mestre -> res://cenas/mestre/mestre.tscn (ORDEM-D-AUD-16)`**. Não há `pronto` (é a linha da arena, que não chegou a montar). 0 `ERROR` / 0 `SCRIPT ERROR` |
| `logs/godot-jogadora.log` | o `godot.log` da jogadora: `pronto` (a arena, como sempre) e o snapshot de combate. Não há a linha do arranque do Mestre. 0 `ERROR` / 0 `SCRIPT ERROR` |
| `logs/porteiro.log` | o porteiro: lugares guardados (jogadora, mestre) e «o ecrã do Mestre (Godot) entrou na sala» |
| `capturas-comando.ps1.txt` | o comando que o agente da sessão 1 correu (lançar, restaurar e alinhar as janelas, capturar) |
| `suites/RESUMO.txt` e `suites/*.log` | as suites no PC, depois da correcção final (ver o ESTADO-FINAL) |

O `servidor.log` da bancada não está aqui, porque traz os IPs da rede local. Fica em `bancada-rede/privado/registos/`, fora do Git.

## Antes da correcção

O «antes» é o da INVESTIGA: `provas/ordem-d-aud-investiga/capturas/l01-mestre-abre-na-arena-da-jogadora.png` e
`i00-mestre-inicio-bancada-preparada.png`. Lá, o cliente do Mestre mostra a HUD da jogadora.

## Uma 1.ª corrida, deitada fora

A 1.ª corrida da bancada desta ordem (antes do commit `d0dfb00`) já mostrou a linha do arranque no log do Mestre. Mostrou também um defeito que a
correcção trouxe: o painel do Mestre abria com «Alertas: 1 — A ligação caiu; a tentar de novo.». No arranque directo, o
ecrã abre com a ligação ainda a abrir, e o `mestre.gd` tomava isso por uma queda. Corrigi-o (o alerta só aparece se o
Mestre já esteve na mesa), juntei um teste ao `pecas_mestre` e voltei a correr tudo. As capturas dessa 1.ª corrida
foram apagadas e não estão aqui: outra janela do ambiente de trabalho tapava parte da do Mestre.
