# Provas — ORDEM-D-AUD-04-BANCADA

A batalha medida foi a da bancada de rede verdadeira: `bancada-rede/lancar.ps1 -Fichas acertam -Modo auto`, com o
servidor de produção (`servidor-ws.js`) em 127.0.0.1:8791 e o motor real (VLAB, em cache). Correram **dois clientes
Godot 4.7.2 com janela**: o da jogadora (Arqueira de Bancada) e o **ecrã do Mestre**. O cliente headless
`e2e_mestre.gd` não foi usado. Foi a 23/11/2026, das 18:26:58 às 18:40:57 (-03), na grelha-mapa 50 × 50 de 1,5 m.
Todas as fichas são FICTÍCIAS, de bancada.

O ESTADO-FINAL está em `ESTADO-FINAL-ORDEM-D-AUD-04-BANCADA.md`, na raiz.

| pasta / ficheiro | o que prova |
| --- | --- |
| `journal/config-da-sala.json` | **a fonte do §5.3**: a config com que o servidor arrancou. A sala não tem `mapa`, por isso a grelha é a grelha-mapa da linha. O PIN e as senhas estão redigidos |
| `journal/journal-extracto.json` | o journal do servidor (Mestre-only, fora do Git), já extraído: `mapa: {largura: 50, altura: 50, casaM: 1.5}`, `fase: fim`, `desfecho: morte`, rodada 14 e os 70 eventos da batalha com o recibo do Mestre. **Não tem nenhuma semente.** Os ids estão trocados pelo fichaId fictício |
| `journal/medicoes.json` | as medições: 18 ataques (d20, total, CA, 3d6 do crítico, dano, vida do alvo antes → depois) e 10 testes de morte (dado, Constituição somada, total, CD) |
| `relato.txt` | o relato da batalha em texto, um evento por linha, com a hora e o segundo da gravação bruta |
| `capturas/c00`–`c17` | os dois ecrãs nos momentos medidos (os nomes dizem o momento) |
| `capturas/f01`–`f06` | fotogramas a 10 fps (2 s) do acerto de 8, da morte do lobo e da queda da arqueira, em cada ecrã: a animação quadro a quadro |
| `capturas/m01`, `m02` | rajadas do acerto de 8 |
| `capturas/z01` | as figuras no ecrã do Mestre ampliadas 3× (c09 → c11: morte do lobo; c14: caída, de pé; c16: morta, peão deitado) |
| `videos/v00` | a batalha inteira, a 4×, com os dois ecrãs lado a lado (jogadora à esquerda, Mestre à direita) |
| `videos/v01`–`v05` | acerto (8 no lobo); erro e os monstros a acertarem (7 e 11); morte do lobo; queda da arqueira; testes de morte até à morte (2×) |
| `logs/godot-jogadora.log`, `logs/godot-mestre.log` | os `user://logs/godot.log` dos dois clientes: Godot 4.7.2, RTX 4060, `casas: 2500` (= 50 × 50), **0 SCRIPT ERROR** |
| `logs/porteiro.log`, `logs/servidor.log` | a preparação da mesa (LOBBY_SET → START → lobo em (36,3), bruto em (41,1)). O porteiro sai quando «o ecrã do Mestre (Godot) entrou na sala» |
| `ensaios/` | os 2 ensaios **sem janelas** (`ferramentas/ensaio-rede.mjs`), que calibraram a bancada antes da batalha medida. No 1.º o bruto ficou encurralado em (34,5), e por isso foi para (41,1). O 2.º chegou à morte: 28 ataques, 18 acertos |
| `ferramentas/extracto.mjs` | gera o `journal/` a partir do journal e da config da bancada |
| `ferramentas/relato.mjs` | gera o `relato.txt` |
| `ferramentas/ensaio-rede.mjs` | o ensaio sem janelas (calibração; não é a batalha medida) |

Para refazer: `bancada-rede\correr-com-o-mestre.cmd -Fichas acertam -Modo auto`. Depois:
`node provas/ordem-d-aud-04-bancada/ferramentas/extracto.mjs bancada-rede/privado/registo-MESTRE-ONLY-bancada-rede.json bancada-rede/privado/config.json <saída>`.
