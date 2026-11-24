# Provas — ORDEM-D-AUD-16-SEGUIMENTO-B1 (a corrida viva do ramo `DESLIGADA` → lobby do `mestre.gd`)

Todas as horas são de 24/11/2026 (-03). Os caminhos do PC estão redigidos: `<sede>` é a pasta desta ordem no PC,
`<godot 4.7.2>` é o Godot 4.7.2 win64. Os lugares usados são inventados (`sala-ficticia`, `lugar-ficticio`,
`token-ficticio-seguimento-b1`); estão em `logs/a-lugar.cfg.txt` e `logs/b-lugar.cfg.txt`.

As capturas foram tiradas pelo agente da sessão 1 (o mesmo `s1-agente.ps1` da D-AUD-16-SEGUIMENTO-B, numa tarefa
agendada `DAud16SegB1`, que já foi apagada). Cada PNG traz um bloco `tEXt` `Creation Time` com a hora da saída do
comando e um bloco `Source` que diz de que saída vem. O agente corre com a janela escondida e, por isso, a janela do
Godot nasce minimizada; o comando repõe-na (`ShowWindow`) antes de capturar. Não há input nenhum: só se olha.

## Resumo

**O arranque que a ordem descreve (lugar de papel mestre sem token) não chega ao ramo.** O lobby aparece, mas pelo
caminho da arena, não pelo `mestre.gd`: o `Rede.papel_do_arranque()` só devolve `"mestre"` quando o lugar tem token
(`rede.gd:724–730`, `papel_do_lugar`: «sem token a Rede pede a entrada: o arranque fica o de sempre»). Sem token, a
arena não chama o `_abrir_no_mestre()`, monta-se como a cena da jogadora, chama o `Rede.iniciar()`, a Rede pede a
entrada e a arena muda para o lobby (`arena.gd:166` liga o `precisa_entrar`; `arena.gd:186–190` muda de cena). O ecrã do Mestre nunca abre e a linha
`ecrã do Mestre aberto sem ligação (estado 0)` não aparece (corrida A).

**O ramo corre vivo** com a única origem real da `DESLIGADA` antes da cena: a guarda da rede local do Android
(`rede.gd:426–431`). No PC essa guarda só dispara com `OS.has_feature("android")` forçado a verdadeiro, **só na cópia
de trabalho e só durante a corrida** (`logs/b-guarda-android-temporaria.diff`, uma linha; o mesmo processo do
`b-versao-temporaria.diff` da D-AUD-16-SEGUIMENTO-B). Com um lugar de papel mestre **com** token e um servidor fora
da rede local, a arena vai ao Mestre, o `_ligar()` pára na guarda com a Rede `DESLIGADA`, o ecrã do Mestre abre,
escreve `ecrã do Mestre aberto sem ligação (estado 0): para o lobby` e muda para o lobby, que mostra o motivo
(corrida B). No fim o diff foi desfeito (`git checkout`); nenhum commit desta ordem toca em `rascunhos/`.

## 1. Corrida A — o recipe da ordem: lugar de papel mestre **sem token**, código sem mudanças

`lugar.cfg`: servidor `ws://127.0.0.1:8790/ws`, `seatToken=""`, papel `mestre`. Servidor fora do ar. Arranque directo
(cena principal = `arena.tscn`), com janela 960×540, `-- --servidor=127.0.0.1:8790`.

| ficheiro | o que mostra |
|---|---|
| `capturas/a01-lobby-pela-arena-sem-token-12s.png` | aos 12 s: o lobby, **no modo da jogadora** («Entre com o nome da sua personagem e a senha.», «Sou o Mestre»), sem motivo |
| `capturas/a02-lobby-pela-arena-sem-token-25s.png` | o mesmo aos 25 s |
| `logs/a-godot-arranque-mestre-sem-token.log` | o `godot.log`: a floresta da arena, depois `pronto` (arena, `arena.gd:171`) e `pronto` (lobby). **Não tem** `arranque: lugar do Mestre -> …` nem `ecrã do Mestre aberto sem ligação`. É igual ao arranque sem lugar nenhum |
| `logs/ah-godot-headless-sem-token.log` | a mesma corrida, sem janela (`--headless --quit-after 300`), antes da corrida com janela: as mesmas linhas |
| `capturas-a-comando.ps1.txt` / `capturas-a-saida.txt` | o comando e a saída com as horas. Arranque 12:06:18; `a01` 12:06:30; `a02` 12:06:43 |

## 2. Corrida B — o ramo vivo: lugar de papel mestre **com** token, a guarda do Android a parar a ligação

`lugar.cfg`: servidor `ws://servidor-de-fora.example:8790/ws` (fora da rede local; a guarda pára antes de qualquer
DNS ou socket), `seatToken="token-ficticio-seguimento-b1"`, papel `mestre`. Arranque directo, janela 960×540,
`-- --servidor=servidor-de-fora.example:8790`. `logs/b-guarda-android-temporaria.diff` aplicado só durante a corrida.

| ficheiro | o que mostra |
|---|---|
| `capturas/b01-lobby-pelo-ramo-do-mestre-12s.png` | aos 12 s: o lobby **no modo do Mestre** («Entre com o PIN do Mestre.», «Entrar como Mestre»), com o motivo da Rede em amarelo: **«Este endereço não é da rede de casa. Peça ao Mestre o link certo.»** (`Rede.motivo_entrada = "rede_local"`, `lobby.gd:38`) |
| `capturas/b02-lobby-pelo-ramo-do-mestre-25s.png` | o mesmo aos 25 s: fica no lobby, sem voltar ao Mestre |
| `logs/b-godot-arranque-mestre-guarda-android.log` | o `godot.log`: **`arranque: lugar do Mestre -> res://cenas/mestre/mestre.tscn (ORDEM-D-AUD-16)`**, depois **`ecrã do Mestre aberto sem ligação (estado 0): para o lobby`** (`mestre.gd:222`), depois `pronto` (lobby). Sem a floresta da arena (a arena não se monta), 0 `ERROR` |
| `logs/bh-godot-headless-guarda-android.log` | a mesma corrida sem janela, antes: as mesmas 3 linhas |
| `logs/b-guarda-android-temporaria.diff` | a mudança de uma linha que se aplica e se desfaz |
| `capturas-b-comando.ps1.txt` / `capturas-b-saida.txt` | o comando e a saída com as horas. Arranque 12:06:59; `b01` 12:07:12; `b02` 12:07:25 |

A corrida B com janela foi feita **duas vezes**. A 1.ª (12:04:45) deu as mesmas imagens e o mesmo log, mas o comando
tinha um erro no nome dos ficheiros das capturas (faltava a barra antes de `b01`); corrigi o comando e repeti, para
o comando cometido ser exactamente o que correu. Ficam as provas da 2.ª. Antes disso houve três ensaios que não
capturaram nada (a janela minimizada, ver acima).

## 3. Suites

Ver `suites/RESUMO.txt` e `suites/*.log`. Cada log abre com `# comando: …` e `# hora: início …` e fecha com
`# hora: fim … rc=…`. O executor está em `suites-executor.sh.txt`. O código não mudou nesta ordem: as suites correm
para confirmar a linha no estado em que fica.
