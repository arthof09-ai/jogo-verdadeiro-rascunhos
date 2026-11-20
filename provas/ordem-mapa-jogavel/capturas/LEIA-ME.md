# Capturas da grelha-mapa — ORDEM CAPTURAS-MAPA (20/11/2026)

São uma prova visual para o Mestre ver, não um teste. Foram tiradas com render real (GPU NVIDIA GeForce RTX 4060, Godot 4.7.2, 1920×1080),
a partir do head `62dfa61` de `fable/integracao-50`. Nenhum código do jogo foi alterado.

| Grelha | A arena da jogadora (o mapa todo) | A jogadora, de perto, a figura no lago | O ecrã do Mestre (aba Sala, selector da escala) |
|---|---|---|---|
| 50 × 50 @ 1,5 m | `jogadora_50x50_1,5m_1-mapa-todo.png` | `jogadora_50x50_1,5m_2-perto-no-lago.png` | `mestre_50x50_1,5m_1-ecra-mapa-todo.png` |
| 75 × 75 @ 1 m   | `jogadora_75x75_1,0m_1-mapa-todo.png` | `jogadora_75x75_1,0m_2-perto-no-lago.png` | `mestre_75x75_1,0m_1-ecra-mapa-todo.png` |
| 37 × 37 @ 2 m   | `jogadora_37x37_2,0m_1-mapa-todo.png` | `jogadora_37x37_2,0m_2-perto-no-lago.png` | `mestre_37x37_2,0m_1-ecra-mapa-todo.png` |

- **A jogadora:** a câmara está em Panorama e mostra a grelha sobre o mapa inteiro, com o lago lá dentro. Há uma figura («No lago») numa casa de
  água: (36,9), (54,14) e (27,6), as mesmas da prova do servidor. A figura não foi recusada e fica de pé, com ~0,5 m de água acima do pé.
  O snapshot só leva campos públicos, por isso não há números de monstro.
- **De perto:** a figura sai de uma casa seca da margem — (33,6), (50,10), (25,4) — e entra no lago. Houve 1 salpico ao entrar em cada grelha
  (`salpicos_ao_entrar` em `medicao.json`). Na foto vê-se a esteira na água, entre a margem e a figura.
- **O Mestre:** é a vista REAL da fixture do servidor (`dados-exemplo/mesa-mestre.json`), com o mapa trocado pela grelha-mapa. A heroína está
  na casa de água e as outras três figuras em casas secas perto do lago. As casas a arder da fixture foram tiradas, porque são de 20 × 20.
  Há 4 figuras de pé, sem recusas. O rótulo diz «Escala: X m por casa».
- **Ferramenta:** `ferramenta/foto_mapa_jogavel.gd` junta `medir_mapa_jogavel.gd` e `testes/foto_mestre.gd`. Corre a partir de uma cópia
  temporária em `cliente/cenas/arena/ferramentas/` (ver o cabeçalho), e antes é preciso `godot --headless --path cliente --import` num clone
  novo.
