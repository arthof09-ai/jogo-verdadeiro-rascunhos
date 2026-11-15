# ESTADO FINAL — Ordem 55 (as fases da lua no relógio do mundo)

Ramo `fable/ciclo-43`, trabalhado directamente sobre a ponta `d7b9e6c` (o ESTADO FINAL da Ordem
43), sem ramo novo. Clone em `C:\Users\txcga\fable-ciclo\repo`. `main` não foi tocado: continua em
`2383737`. Sem merges.

**Quem fez:** uma sessão só, Claude conta 1 a correr em **Opus 5.5** (`claude-opus-5-5`), como a
ordem manda.

As medidas, os números e as tabelas estão em `NOTAS-CICLO-55.md`.

## A escolha registada

- **O ciclo das fases: 28 dias do mundo.** As NOTAS-CICLO-43 não diziam outra coisa (só «a lua é
  sempre cheia»), por isso fica o número da ordem.
- **A lua não muda de sítio com a fase.** Fica oposta ao sol, como na Ordem 43. A fase muda a luz
  e o disco; não muda o caminho da lua no céu. Fazer a lua andar mudava a luz de todas as noites,
  e o equilíbrio da noite é da Ordem 43 e do olho do Mestre. Fica dito nas notas, como reserva.
- **A idade muda às 12:30**: a lua está a −52°, o sol a pino e a luz da lua é 0. Cada noite tem
  uma lua só e a mudança não se vê. O mundo abre na lua cheia.
- **Os quartos: ½ da luz da cheia**, a fracção iluminada `(1 − cos α)/2`. Sai da fase; não é um
  número escolhido. (Ao luar verdadeiro seria cerca de 1/10; fica nas notas, para o olho.)

## Prova corrida no fecho

- `provar_fases_lua.gd` (headless): **24 de 24** com `--referencia` (o `ciclo_dia.gd` de
  `d7b9e6c`). Na cheia, as **40 saídas da Ordem 43 são iguais bit a bit nos 1440 minutos**. Na lua
  nova a luz da lua é 0 em todos os minutos. Nos quartos é ½ da cheia em todos os minutos, com o
  `lua_baixa` intacto. Só as saídas da lua mudam com a fase. O relógio a andar 28 dias vira a
  idade 28 vezes, às 12:30, e volta à cheia. A troca não se vê. Nenhuma fase tem um passo por
  minuto maior que a cheia. Sem `--referencia` (como corre no CI): 22 de 22.
- `provar_ciclo_vento.gd` (a prova da Ordem 43): o `curvas_ciclo_vento.json` sai **igual byte a
  byte**.
- Render (RTX 4060, Compatibility, 1920×1080): as 4 capturas das fases correram sem erro. FPS sem
  v-sync 1236–1266, **80 chamadas em todas as fases**, luma da cena: nova 9,7 · crescente 25,2 ·
  cheia 32,7 · minguante 25,2.
- As suites, localmente, sobre a ponta:

| suite | resultado |
|---|---|
| `testes/abrir_scripts.gd` | 58 scripts, 0 falhas |
| `testes/rodar_testes.gd` | 138 de 138 |
| `testes/abrir_clareira.gd` | 22 de 22 |
| `testes/medir_painel_config.gd` | 0 falhas |
| `testes/abrir_mestre.gd` | 57 de 57 |
| `testes/pecas_mestre.gd` | 223 de 223 |
| `testes/medir_mestre.gd` | 0 falhas |
| `testes/hud_acoes.gd` | 32 de 32 |
| `testes/canario_privacidade.gd` | 10 de 10 |
| a cena `campo_floresta.tscn` em headless (300 quadros) | erros 0, carga 1452 ms |
| `provar_altura.gd` | maior 0,00002 m |
| `provar_costura.gd` | **VERMELHA**, 67/255. Já estava vermelha antes desta ordem, igual byte a byte: ver «O que falta conferir» |

- CI: corre no push do fecho. O resultado fica no commit seguinte a este.

## ESTADO FINAL — Passagem

**O que mudou** (commits, do mais antigo ao mais novo):

- `fa27197`: **a construção.**
  - `ciclo_dia.gd`: a idade da lua (28 dias, vira às 12:30); a luz da lua × a fracção iluminada;
    a API `idade_da_lua()`, `fase_da_lua()`, `lua_iluminada()`, `definir_idade_da_lua()`, as
    puras `fase_da_lua_de()`, `iluminada_de()`, `angulo_de_fase()`, e o sinal
    `fase_da_lua_mudou`; `calcular(h)` igual, com a idade opcional (cheia por omissão).
  - `ceu_ciclo.gdshader`: o disco com terminador; na cheia, o caminho de sempre.
  - `campo_floresta.gd`: repinta também quando muda a idade da lua; tecla U / Shift+U;
    `fase_da_lua()` na raiz.
- `375efaf`: `provar_fases_lua.gd` e `capturas/ciclo55/fases_lua.json`; o passo «Fases da lua no
  relógio do mundo (Ordem 55)» no job `cliente` do CI.
- `25a4610`: o modo `--fases` em `filmar_dia.gd` e as capturas: `c55_22h00_1-nova`, `2-crescente`,
  `3-cheia`, `4-minguante`, `_folha_fases.jpg` e `medicao_fases.json`. Os outros modos (`--horas`,
  `--dia`, `--vento`) ficam como estavam, painel incluído.
- `2a38a98`: `NOTAS-CICLO-55.md`. Em `NOTAS-CICLO-43.md`, a linha da API das fases e a reserva da
  lua dada por feita, a apontar para as notas novas.
- (este commit): `ESTADO-FINAL-ORDEM-55.md`.

**Onde parou:** tudo o que a ordem pede está feito e commitado, com o push feito no fecho (sem
force). Faltava ver o CI quando este ficheiro foi escrito; o resultado fica no commit seguinte.

**Próximo passo:** a conferência do coordenador e do Mestre:

1. ver `capturas/ciclo55/_folha_fases.jpg` (as 4 fases, 22:00, só a fase muda), depois as 4
   capturas em tamanho real (o disco ampliado está no canto);
2. na cena, a tecla **U** muda de fase à noite; com **P** e **,** **.** escolhe-se a hora;
3. ler as notas: «A regra» e «A noite escura».

**O que falta conferir:**

- **A noite da lua nova é escura**: luma 9,7 contra 32,7 da cheia, e 47,9 % do quadro quase
  preto. Não se mexeu em nada para a aclarar. A ordem manda deixar esta pergunta ao olho do
  Mestre. Os botões estão nas notas (`CEU_LUZ`, o piso `0,46` da luz-chave, `LUA_ENERGIA`,
  `lua_baixa`).
- **A lua não anda com a fase** (escolha dita acima). No céu verdadeiro a lua crescente põe-se à
  meia-noite e a minguante nasce à meia-noite. Se o Mestre quiser isto, mexe na luz de todas as
  noites.
- **`provar_costura.gd` está vermelha, e já estava antes desta ordem.** No fecho da Ordem 38
  (`254188c`) dava 0/255. Sobre o código da Ordem 43 (`d7b9e6c`, os ficheiros repostos só para a
  corrida) dá 67/255, e sobre a ponta desta ordem dá **o mesmo, linha a linha**. A prova esconde o
  chão largo e lê a base do anel longe por baixo das capas. Desde a 43 essa base sai `#aca168` em
  vez da cor do horizonte `#d6d0ab`. É do anel longe com a luz do ciclo, não da lua. Não se mexeu
  (é da Ordem 43, e a ordem manda não mexer no que ela entregou). A prova não está no CI e a
  Ordem 43 não a correu no fecho. Fica para o coordenador decidir se é defeito do mapa ou só
  ferramenta desactualizada (ela compara com a `COR_HORIZONTE` fixa, e desde a 43 o horizonte
  muda com a hora).
- **A âncora por render é forte só para o disco.** O render desta cena não se repete píxel a
  píxel, nem com o mesmo código (a relva e a água). Código 43 contra código novo dá diferenças
  menores do que duas corridas do mesmo código. O disco da cheia ampliado sai igual (0–1 píxel,
  máx. 1 nível). A igualdade bit a bit está provada nos números (as 40 saídas, 1440 minutos).
- **As figuras do jogo** continuam sem existir neste mapa. A DirectionalLight «Lua» segue a fase
  (apaga-se na nova), mas não foi vista a iluminar figuras.
