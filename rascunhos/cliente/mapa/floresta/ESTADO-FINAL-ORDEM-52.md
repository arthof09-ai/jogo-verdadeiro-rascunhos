# Ordem 52: o perfil gráfico no ecrã do Mestre. ESTADO FINAL

*Conta 1, Opus, sessão única: às 08:22 de 2026-11-15 só havia um `ordem52-c1-out.txt` e nenhuma outra sessão neste
clone. Ramo `fable/mestre-perfil-52`, tirado de `8cd941d`; `main` não foi tocada. Os registos estão em
`C:\Users\txcga\fable-mapa\_tmp\o52\`. Não foi commitado o `rascunhos/servidor/dados-exemplo/mesa-mestre.json`,
que já vinha modificado por CRLF antes da sessão.*

O que mudou: o ecrã do Mestre passa a ter a mesma escolha «Gráficos» da ⚙ da jogadora. Chega pelo mesmo ficheiro,
pela mesma chave, pelo mesmo seletor e pelo mesmo `AplicadorPerfil`. A arena do Mestre obedece na densidade da relva
e nas contagens do clima. Se o Mestre não escolher nada, a arena fica como hoje, número a número: relva a 1,0 e clima
nas contagens médias. A arena do jogador não mudou nada: medi-a antes e depois e os números são iguais. Não há arte
nova; o trabalho é só canalização das definições.

## Parte A: o mapa do caminho (escrito antes de mexer: `ESTADO-ORDEM-52.md`, commit `999e1ff`)

**Jogador.** O perfil vai da escolha até à relva e ao clima por este caminho:
1. `hud/hud.gd` guarda a escolha em `user://preferencias.cfg`, secção `[pref]`, chave `perfil`. O valor por omissão
   é `"medio"`. Sem ficheiro, em `mobile`, `web_android` ou `web_ios`, passa a `"baixo"`.
2. A linha «Gráficos» da ⚙ chama `_ao_perfil(i)`, que chama `_mudar_pref`. Esta guarda e emite
   `preferencia_mudou("perfil", nome)`.
3. No arranque, `arena.gd` liga `_ao_preferencia` e chama `aplicar_preferencias_iniciais()`, que emite tudo. Por
   isso o jogador tem sempre um perfil aplicado.
4. `_aplicar_perfil` chama `AplicadorPerfil.aplicar` (o nó `Perfis`, a tabela única), que emite
   `perfil_aplicado(chave)`. Dois receptores apanham esse sinal:
   - `_ao_perfil_aplicado` faz `mapa.definir_densidade_relva(folhagem_densidade)`: baixo 0,5, medio 0,75, alto 1,0;
   - `clima.definir_perfil` põe o clima nas contagens `CONTAGEM[...][perfil]` e `VEU[perfil]`.

**Mestre, antes.** `mestre.gd` não tinha ⚙ nem `AplicadorPerfil`, e não lia `preferencias.cfg`. Em
`arena_mestre.gd`, `Clima.new()` ficava com o `perfil := "medio"` do módulo e `CampoFloresta.new()` com o
`densidade_relva = 1.0` do mapa. Nenhuma linha escrevia «1,0» nem «medio»: eram os valores por omissão dos módulos,
que nada mudava. O módulo partilhado `campo_da_mesa.gd` não tinha nada do perfil.

## A ligação (Parte B, commit `0cc49a9`)

- **Um só sítio para a escolha: `arte/perfis/escolha_perfil.gd`.** Tem a lista `PERFIS`, os nomes `NOMES`, `ARQ`,
  `SECCAO` e `CHAVE`, e quatro funções:
  - `seletor()` monta o `OptionButton` «Gráficos»;
  - `escolhido()` devolve "" quando ninguém escolheu (sem ficheiro, sem chave, ou um nome que não é perfil);
  - `guardar(nome)` escreve a mesma chave e deixa as outras preferências como estavam;
  - a lista e o ficheiro saíram do `hud.gd` sem mudar um valor, e o HUD passou a usá-los.
- **Um só sítio para perfil → relva e clima: `campo_da_mesa.gd`.**
  - `ligar_perfil(perfis, clima, mapa_de)` faz as duas ligações que viviam só em `arena.gd`, pela mesma ordem.
  - `perfil_no_mapa` e `densidade_do_perfil` fazem a mesma conta de antes.
  - `arena.gd` usa estas funções; o seu `_ao_perfil_aplicado` só delega.
- **A arena do Mestre (`arena_mestre.gd`).**
  - Ganhou o nó `Perfis` com o mesmo `AplicadorPerfil`, sem `perfil_inicial`, ligado por `ligar_perfil`.
  - Ganhou `aplicar_perfil(nome)` e `perfil_atual()`.
  - Quando o mapa se refaz (a grelha muda de tamanho), volta à densidade escolhida.
- **O ecrã do Mestre (`mestre.gd`).**
  - A aba Sala ganha a linha «Gráficos» com o mesmo seletor. Escolher um perfil chama `escolher_perfil`: a arena
    aplica-o e a escolha guarda-se na chave da ⚙.
  - Ao abrir, `_aplicar_perfil_escolhido` aplica o perfil guardado.
  - A leitura e a escrita só acontecem com `Rede.persistir`, a regra que o ecrã já usa para o `mestre.cfg`.
  - Sem escolha não se aplica nada e o seletor fica sem item marcado.

## As medições (Parte C, commit `2ec9978`)

Ferramenta: `cenas/mestre/ferramentas/medir_perfil_mestre_52.gd`, com a grelha 20 × 20 de 1,5 m. Corri a mesma
ferramenta na árvore de antes (`8cd941d`) e na de depois. Os números saem em `medir-antes.json` e
`medir-depois.json`.

O que se conta:
- **Relva:** a densidade; os tufos semeados; os tufos desenhados vistos da câmara da mesa, depois do LOD por
  distância.
- **Clima:** as contagens-alvo de gotas, flocos, salpicos e véu. Depois de 3 s, as partículas desenhadas nas
  MultiMesh conferem com o alvo em todos os casos.

| arena | relva (densidade · semeados · desenhados) | chuva fraca (gotas/salpicos) | chuva forte | neve fraca | neve forte (flocos/véu) |
|---|---|---|---|---|---|
| Mestre, ANTES (`8cd941d`) | 1,00 · 45265 · 33456 | 1600 / 120 | 5000 / 350 | 2000 | 6000 / 140 |
| Mestre, sem escolha (depois) | 1,00 · 45265 · 33456 | 1600 / 120 | 5000 / 350 | 2000 | 6000 / 140 |
| **Mestre, «Baixo» escolhido** | **0,50 · 45265 · 16741** | **900 / 0** | **2800 / 0** | **1000** | **3000 / 0** |
| Mestre, «Médio» escolhido | 0,75 · 45265 · 25100 | 1600 / 120 | 5000 / 350 | 2000 | 6000 / 140 |
| Mestre, «Alto» escolhido | 1,00 · 45265 · 33456 | 2400 / 200 | 8000 / 600 | 3000 | 9000 / 260 |
| jogador, como abre (HUD «medio»), antes = depois | 0,75 · 45265 · 25100 | 1600 / 120 | 5000 / 350 | 2000 | 6000 / 140 |
| jogador, baixo / medio / alto, antes = depois | 0,50 · 16741 / 0,75 · 25100 / 1,00 · 33456 | as do perfil | | | |

- **Com o perfil baixo**, a relva desenhada cai de 33456 para 16741 tufos (−50 %). As gotas da chuva forte caem de
  5000 para 2800, os flocos da neve forte de 6000 para 3000, e os salpicos e o véu chegam a 0.
- **Com o perfil por omissão** (sem escolha), o ecrã do Mestre fica igual ao de antes, número a número. Comparei o
  JSON chave a chave e dá igual.
- **A arena do jogador** dá igual entre antes e depois em tudo o que medi: como abre e nos três perfis. A comparação
  chave a chave do JSON inteiro dá `True`.
- **`pecas_mestre`** confere o mesmo com o ecrã inteiro. A câmara está posta pela vista da fixture, por isso os
  números de tufos são outros:
  - sem escolha, a relva fica a 1,0 com 33214 tufos desenhados, e a chuva forte pede 5000;
  - «Baixo» na linha «Gráficos» dá a relva a 0,5 com 16619 tufos, e as contagens do Baixo;
  - a escolha mantém-se quando o mapa se refaz.

## Provas do fecho

| suite | resultado |
|---|---|
| `abrir_scripts` | 69 scripts, 0 falhas (67 antes, mais os 2 novos) |
| `rodar_testes` | 176/176 |
| `pecas_mestre` | **255/255** (236 antes, mais as 19 do perfil gráfico) |
| `clima_forte` · `hud_acoes` · `abrir_clareira` · `abrir_mestre` · `canario_privacidade` | 119/119 · 32/32 · 22/22 · 57/57 · 10/10 |
| `medir_mestre`, `medir_painel_config` | saída 0 |
| arranque `--quit-after 600` | «pronto», 0 erros |
| `provar_assentamento`, `provar_terreno_servidor` | TUDO PASSOU |
| `exportar_terreno --conferir` | EM DIA (nenhuma das 5 fontes do SHA foi tocada) |
| servidor | 348/348 |
| ponta a ponta (motor falso, local) | 17/17, jogadora OK, nenhum canário do Mestre |

Antes de mexer, corri as mesmas suites numa cópia de `8cd941d`. Os números foram os mesmos: 176, 119, 236, 32, 22,
57 e 10. Nenhuma suite teve SCRIPT ERROR.

CI: ver a secção «CI» no fim.

## Resíduos nomeados

1. **«Escolha feita» quer dizer que há chave `perfil` no ficheiro.** O HUD da jogadora guarda o dicionário inteiro
   sempre que muda qualquer preferência (câmara, tela vermelha…), e o `perfil` vai junto. Num aparelho onde a ⚙ da
   jogadora já foi usada, o Mestre abre nesse perfil, por exemplo «medio» com relva 0,75, sem ter escolhido. Isto só
   acontece com as duas vistas no mesmo aparelho. Não mudei a forma como o HUD guarda, porque isso mudaria a arena do
   jogador: a regra «sem ficheiro → baixo» do telemóvel depende dela.
2. **O recuo do telemóvel não vale para o Mestre.** A regra «sem ficheiro em `mobile`/`web_*` → baixo» só existe na
   jogadora. Sem escolha, o Mestre num telemóvel fica como hoje (1,0 e médio), como a ordem pede. Fica para uma
   decisão futura.
3. **Escolher aplica o perfil inteiro, não só a relva e o clima.** No `SubViewport` do Mestre também mudam a escala
   3D (0,5 no Baixo), o MSAA, as sombras do sol, o glow, o SSAO e o contorno, como no jogador. Não fiz capturas novas
   disto: a ordem não pede arte nova e o job `foto-mestre` corre sem escolha, por isso continua a mostrar o de hoje.
   As sombras do sol mudam por `RenderingServer` (afectam o processo inteiro) e o glow/SSAO pelo grupo `ambiente`, a
   que pertencem os Ambientes das duas arenas. Por isso, quando as duas arenas estão na mesma árvore (só nas
   ferramentas de prova), um perfil aplicado mexe também nas sombras e no glow/SSAO da outra arena.
4. **Não há «voltar a sem escolha».** O seletor só tem Baixo, Médio e Alto. Depois de uma escolha, voltar
   exactamente à relva 1,0 com clima médio obriga a apagar a chave do ficheiro. «Alto» dá relva 1,0 mas clima alto.
5. **Sem disco não há escolha.** Com `Rede.persistir` falso (todos os testes, as fotos, o ponta a ponta), o Mestre não
   lê nem escreve a escolha. Por isso `escolhido`/`guardar` foram provados num ficheiro de prova, e o ficheiro
   verdadeiro ficou intacto (verificado). A leitura do `user://preferencias.cfg` verdadeiro ao abrir o ecrã não tem
   prova automática com `persistir` ligado.
6. **Ficou de fora** o ramo da Ordem 51 (`fable/toque-51`). Este ramo nasce de `8cd941d`, como a ordem manda, e não
   tem o conserto do raio da Ordem 51. Juntar os dois ramos é trabalho de integração.

## CI

Confirmado pela API do GitHub (`gh api .../actions/runs/<id>/jobs`). O push foi um ramo novo, sem `--force`.
`origin/main` ficou em `2383737`, antes e depois. Nenhum ficheiro de workflow foi tocado.

- **Ponta `490d036`:**
  - «Testes dos rascunhos», run **43709778922**, **verde nos 9 jobs**: `servidor`, `validador-glb`, `motor-real`,
    `protocolo`, `cliente`, `godot-cliente`, `ponta-a-ponta` (motor falso e VLAB real), `retoma-pc` e `foto-mestre`.
  - «Sonda de privacidade», run **43709778912**: verde.
- O commit deste parágrafo e o das listas refeitas a seguir têm o seu próprio run, conferido no fim da sessão.
