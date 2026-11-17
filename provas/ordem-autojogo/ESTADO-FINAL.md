# ORDEM AUTOJOGO — ESTADO FINAL (17/11/2026)

O jogo joga sozinho contra si próprio: partidas headless com sementes fixas, registo legível por partida, IA simples
**só de bancada**, corredor de N sementes com resumo. Os desequilíbrios **registam-se, não se corrigem**.

## Como correr

```
GODOT=/caminho/Godot_v4.7.2-stable_linux.x86_64 \
  rascunhos/ferramentas/correr-autojogo.sh -n 3 -s 1 -d -o ./autojogo-saida -m /caminho/vlab-completo.js
```

- Uma partida: `godot --headless --path rascunhos/cliente -s res://autojogo/autojogo.gd -- --autojogo --semente=N --registo=F`
  (o cliente lança o seu próprio servidor de bancada `rascunhos/servidor/autojogo/servidor-autojogo.mjs` e joga pela
  rede verdadeira do jogo: a `Rede` = heroína 1, sockets próprios para a heroína 2 e para o Mestre).
- `-m` = o VLAB real (`vlab-completo.js`); `-f` = motor falso, só canalização, **não** mede equilíbrio.
- `-d` = determinismo: repete a 1.ª semente e exige o mesmo registo byte a byte.
- O resumo (`resumir-autojogo.mjs`) é conferido contra cada registo (coluna «Conferência»).

## O que fica no jogo e o que não fica

- Nenhum gancho no caminho normal: a arena, o lobby e a IA das criaturas do servidor (`proporIA`) ficam intactos. A IA
  de bancada (`rascunhos/cliente/autojogo/ia_bancada.gd`) só existe com `-s res://autojogo/autojogo.gd` e só escolhe o
  que o servidor oferece (aproxima · ataca ao alcance · encerra).
- Cenário e fichas são **FICTÍCIOS de bancada** (`cenario-bancada.json`, `fichas-bancada.json`): o repo só tinha
  fichas-canário. Não são cânone. `--cenario=` aceita outro.

## Provado (nesta pasta, na árvore unida sobre fable/integracao-50 @ d433fa5)

- 3 partidas VLAB real (sementes 1, 2, 3; motor sha256 `a91c021c…`): as 3 acabaram com vencedor; resumo = registo 3/3.
- Determinismo: semente 1 repetida → o mesmo registo, sha256 `20e8d88f…` (igual também ao da corrida antes da união).
- Teste Node `rascunhos/servidor/testes/autojogo-bancada.test.mjs` (4/4); suíte do servidor 365 pass / 0 fail / 10 skip.
- Cliente: abrir_scripts 97 scripts / 0 falhas · rodar_testes 200/200 · arranque normal «pronto», 0 erros de script.
  Antes da união (ponta 652551c) passaram também canário 10/10, abrir_mestre 67/67, hud_acoes 50/50,
  pecas_mestre 286/286, abrir_clareira 22/22, painel ⚙ e ecrã do Mestre em ecrãs baixos 0 falhas.

## Desequilíbrios REGISTADOS (não corrigidos)

Com este cenário fictício e esta IA de bancada (amostra de 3 — pequena, só indicativa):
- As heroínas ganharam **3/3**; as duas criaturas caíram e morreram nas 3.
- A Arqueira (vida 22) leva **mais** dano médio (25,7) do que o Espadachim (vida 30, 15) e é a única heroína que chegou a cair (1/3). A causa não foi investigada.
- O Bruto (vida 34) cai sempre; dano sofrido médio 34,7.
Tabela completa em `resumo.md` / `resumo.json`.

## Por fazer

- Amostra maior (dezenas de sementes) para os números de equilíbrio terem peso; cenários com as fichas reais quando
  existirem no repo.
- A IA de bancada é a mais simples possível (sem defesa, sem escolha de técnica além da 1.ª da lista).
