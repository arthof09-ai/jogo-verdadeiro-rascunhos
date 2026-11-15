# Ordem 52: o perfil gráfico no ecrã do Mestre. Estado da ordem (escrito à medida)

*Conta 1, Opus, sessão única (às 08:22 de 2026-11-15 só havia um `ordem52-c1-out.txt`; nenhuma outra sessão
neste clone). Ramo `fable/mestre-perfil-52`, tirado de `8cd941d` (ponta da Ordem 45). Rascunhos e registos em
`C:\Users\txcga\fable-mapa\_tmp\o52\`. O `rascunhos/servidor/dados-exemplo/mesa-mestre.json` aparece modificado
(artefacto CRLF de antes da sessão): não se commita nem se mexe.*

## Parte A: o caminho de hoje (lido em `8cd941d`, antes de mexer)

### A arena do jogador: da ⚙ até à relva e ao clima

1. **A escolha guardada.** `hud/hud.gd`:
   - `pref` (l. 72) começa com `"perfil": "medio"`.
   - `_carregar_preferencias()` (l. 892–900) lê `user://preferencias.cfg`, secção `pref`, chave `perfil`. Sem
     ficheiro, em `mobile`, `web_android` ou `web_ios`, o perfil passa a `"baixo"` e nada se escreve.
   - A lista é `PERFIS = ["baixo", "medio", "alto"]` e os nomes são `NOMES_PERFIS = ["Baixo", "Médio", "Alto"]`
     (l. 28–29). O ficheiro é `ARQ_PREF` (l. 20).
2. **A ⚙.** `_montar_config()` (l. 283–288) põe a linha «Gráficos» com um `OptionButton` dos três perfis.
   `_ao_perfil(i)` (l. 765) chama `_mudar_pref("perfil", PERFIS[i])` (l. 785). Essa função guarda o dicionário
   `pref` inteiro no ficheiro e emite `preferencia_mudou("perfil", nome)`.
3. **No arranque.** `cenas/arena/arena.gd` `_ready`: `hud.preferencia_mudou.connect(_ao_preferencia)` (l. 136),
   depois `hud.aplicar_preferencias_iniciais()` (l. 137). Esta emite TODAS as preferências, por isso o jogador
   tem sempre um perfil aplicado (por omissão `medio`).
4. **A aplicação.** `_ao_preferencia("perfil", v)` (l. 719) chama `_aplicar_perfil(v)` (l. 736). Esta chama
   `_perfis.aplicar(v)` e cai para `"medio"` se o nome não existe. `_perfis` é o nó `Perfis` de `arena.tscn` com o
   `AplicadorPerfil` (`arte/perfis/aplicar_perfil.gd`), a tabela única dos perfis. `aplicar` mexe:
   - na escala 3D, no MSAA, no LOD e nas sombras do sol;
   - no glow e no SSAO;
   - no contorno das figuras;
   - nos grupos `folhagem`/`folhagem_densa`.
   No fim emite `perfil_aplicado(chave)`.
5. **Relva e clima.** Dois receptores de `perfil_aplicado`, ligados em `arena.gd` `_ready`:
   - `_ao_perfil_aplicado` (l. 123 → l. 744) faz `mapa.definir_densidade_relva(folhagem_densidade)`. Na tabela:
     baixo 0,5, medio 0,75, alto 1,0. A relva do mapa tem LOD próprio e não está no grupo `folhagem_densa`.
     `_garantir_mapa` (l. 211–219) reaplica a densidade quando o mapa se refaz.
   - `clima.definir_perfil` (l. 127): o clima passa a usar as contagens `CONTAGEM[...][perfil]` e
     `VEU[perfil]` (`arte/clima/clima.gd` l. 54–69).

### O ecrã do Mestre hoje: onde ficam a densidade 1,0 e as contagens médias

- `cenas/mestre/mestre.gd` `_montar()` (l. 913, arena em l. 924) cria um `SubViewport` com a `ArenaMestre`. O ecrã
  não tem ⚙ nem `AplicadorPerfil`, não lê `user://preferencias.cfg` e não tem a linha «Gráficos». As definições do
  ecrã ficam na aba **Sala** (l. 993–1009: Terminar, Recomeçar, Pausar, Continuar, Atualizar, Som, escala). O
  ficheiro próprio do Mestre é `user://mestre.cfg`: só o aviso da primeira entrada, e só com `Rede.persistir`.
- `cenas/mestre/arena_mestre.gd` `_ready`: `clima = Clima.new()` (l. 137), sem `definir_perfil`. Fica o valor por
  omissão do módulo, `var perfil := "medio"` (`clima.gd` l. 138): **contagens médias**.
- `arena_mestre.gd` `_garantir_mapa` (l. 194–200) chama `CampoDaMesa.montar_mapa`, que faz `CampoFloresta.new()`
  sem densidade. Fica o valor por omissão `densidade_relva = 1.0` (`mapa/floresta/campo_floresta.gd` l. 93),
  posto na sementeira (l. 1233): **relva a 1,0**.
- Nenhuma linha escreve «1,0» ou «medio» no ecrã do Mestre: são os valores por omissão dos dois módulos, que nada
  muda. O resto do perfil também nunca se aplica no Mestre (escala 3D, MSAA, sombras, contorno): o `SubViewport`
  fica com os valores por omissão do Godot.
- O módulo partilhado `cenas/arena/campo_da_mesa.gd` (Ordem 45) monta o mapa e liga o clima nas duas arenas. Não
  tem nada do perfil: a ligação perfil → relva vive só em `arena.gd` (`_ao_perfil_aplicado`).

### O plano da ligação (Parte B)

- **Um só sítio para a escolha.** `arte/perfis/escolha_perfil.gd` junta a lista, os nomes, o ficheiro, a secção,
  a chave e a construção do `OptionButton` «Gráficos». Tudo isto sai do `hud.gd` sem mudar um valor. O HUD passa a
  usá-lo e o Mestre também: o mesmo ficheiro, a mesma chave, o mesmo seletor. A escolha não é copiada.
- **Um só sítio para perfil → relva e clima.** `CampoDaMesa.ligar_perfil(perfis, clima, mapa_de)` faz as duas
  ligações de `perfil_aplicado`. `CampoDaMesa.densidade_do_perfil(perfis, nome)` dá o número da tabela do
  `AplicadorPerfil`. As duas arenas usam estas funções, e a do jogador faz o mesmo que antes.
- **O Mestre.** A `ArenaMestre` ganha um nó `Perfis` (o mesmo `AplicadorPerfil`) e `aplicar_perfil(nome)`. A aba
  Sala ganha a linha «Gráficos» (o mesmo seletor). Escolher um perfil guarda-o em `user://preferencias.cfg` [pref]
  perfil, como a ⚙ do jogador, e aplica-o.
- **Sem escolha, nada muda.** Se o ficheiro não tem a chave `perfil`, ou se `Rede.persistir` é falso, o Mestre não
  aplica perfil nenhum. A relva fica a 1,0, o clima fica em `medio` e o seletor fica sem item marcado.
  `Rede.persistir` falso é a regra do próprio ecrã do Mestre para o `mestre.cfg`, e é assim em todos os testes.

## Parte B: a ligação (commit `0cc49a9`)

Feita como o plano diz. Ficheiros mudados:
- `arte/perfis/escolha_perfil.gd` (novo);
- `hud/hud.gd`: as constantes e o seletor passam a vir do módulo novo, com os mesmos valores;
- `cenas/arena/campo_da_mesa.gd`: `ligar_perfil`, `perfil_no_mapa`, `densidade_do_perfil`;
- `cenas/arena/arena.gd`: usa `ligar_perfil`, e `_ao_perfil_aplicado` delega;
- `cenas/mestre/arena_mestre.gd`: nó `Perfis`, `aplicar_perfil`, `perfil_atual`, e a densidade reaplicada quando o
  mapa se refaz;
- `cenas/mestre/mestre.gd`: linha «Gráficos» na aba Sala, `_aplicar_perfil_escolhido` ao abrir, `escolher_perfil`;
- `cenas/mestre/textos_mestre.gd`: `GRAFICOS`;
- `testes/rodar_testes.gd`: a verificação da lista da ⚙ lê-a no sítio novo.

## Parte C: provas (commit `2ec9978`)

- `pecas_mestre` 255/255 (236 antes, mais as 19 de `_perfil_grafico`).
- Medição com `cenas/mestre/ferramentas/medir_perfil_mestre_52.gd`, na árvore de antes (`8cd941d`) e na de depois.
  O ecrã do Mestre «sem escolha» e a arena do jogador (como abre, baixo, medio, alto) ficam **iguais ao número**
  entre antes e depois: os dois JSON comparados chave a chave são iguais.
- (as suites completas, o ponta a ponta e o CI: a seguir)
