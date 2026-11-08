# Cliente Godot — Assimilação (missão JV2.1a)

> **Estado: RASCUNHO, NUNCA EXECUTADO.** Foi escrito no PCDANASA sob a NAC-OV-05: nada
> foi aberto no Godot, compilado nem rodado. A primeira execução (abrir no editor 4.7,
> rodar os testes sem tela, exportar) cabe a quem tiver uma janela LIVRE noutra máquina,
> ou ao CI da JV0.2.

Godot **4.7**, renderizador **Compatibility**, só GDScript.
Especificação: Plano A v1.1 (JV2.1a, JV2.2, JV2.3) e Protocolo v2 com as erratas v0.2 e v0.2.1.

**Princípio:** o cliente **nunca calcula regra**. Ele desenha o `ROOM_SNAPSHOT`, mostra o que
veio em `ROOM_OPTIONS`, envia `ROOM_INTENT` e trata recibos, recusas, `DESCONHECIDA`,
`RECEIPT_QUERY` e `ROOM_RESYNC`. As casas, os custos em metros e os alvos válidos vêm prontos do servidor.

## Arquivos

| Arquivo | O que faz |
| --- | --- |
| `project.godot` | 4.7, `gl_compatibility` (desktop e mobile), autoloads `Rede` e `Estado`, 1920×1080, stretch `canvas_items` + `expand`, paisagem no celular |
| `rede/rede.gd` | Autoload. `WebSocketPeer` para `ws://<mesma origem>/mesa` (`wss` se a página for https). Na web a origem vem de `JavaScriptBridge.eval("location.host", true)`. Reconexão com espera crescente (1 s → 30 s, com variação). `seatToken` em `user://lugar.cfg`. Ping de aplicação `"p"` a cada 20 s. Limites de 16 KB e 10 intenções por segundo. Fecho 4002 (outro aparelho) não religa sozinho |
| `rede/fila_intencoes.gd` | Estados ENVIADA, DESCONHECIDA, AGUARDANDO_MESTRE, APLICADA e RECUSADA. Ignora os recibos duplicados ou alheios. Na resposta DESCONHECIDA, reenvia o **mesmo** texto, com o mesmo `intentId`. Guarda as pendentes em `user://pendentes.json` |
| `rede/uuid.gd` | UUID v4 a partir de `Crypto.generate_random_bytes(16)` |
| `estado/estado.gd` | Autoload. Espelho do que o servidor projeta. Aplica os eventos pelo `seq` do lugar, guarda os adiantados, pede `ROOM_RESYNC` quando há um buraco (e repete aos 5 s), e o snapshot substitui tudo até ao seu `seq`. `ROOM_OPTIONS` só vale na revisão em que foi feito |
| `cenas/arena/arena.tscn`, `arena.gd` | Grelha parametrizável (20×20, 1,5 m por padrão; o `mapa` do snapshot manda). Destaca só as casas de `ROOM_OPTIONS.mover` e os alvos de `ataques`. Um toque ou clique vira intenção. Setas e Enter só no modo Mover, relativas à câmera. Perfis Baixo, Médio e Alto. Imprime `pronto` no console |
| `camera/camera_mesa.gd` | Fixa (**zoom 1,5 como padrão**), 360°, Panorama (afasta até os cantos da arena caberem no frustum), pinça (dois dedos ou gesto de trackpad), roda, arrastar |
| `hud/hud.tscn`, `hud.gd` | A barra com **Ataque · Mover · Consumível** e nada mais. A ⚙ (desenhada, sem depender de fonte) fica no canto superior esquerdo, com: gráficos, câmera, repor o zoom, tela vermelha e pulso (2 interruptores), encerrar a vez e sair da mesa. Painéis a 55%. Números de dano por tipo. Tela vermelha gradual desde 25% da vida dela. Safe-area (Android/iOS). Letra de 13 px reais ou mais |
| `testes/rodar_testes.gd` | Runner próprio (`extends SceneTree`). Testa: buraco → `ROOM_RESYNC`; recibo duplicado → ignorado (na fila e na `Rede`); evento repetido; snapshot; revisão; DESCONHECIDA; recusa repetida; UUID |

## Rodar os testes (fora do PCDANASA)

```
godot --headless --path cliente -s res://testes/rodar_testes.gd
```

O código de saída é 0 se tudo passar e 1 se alguma verificação falhar.

## Servidor (fallback fora da web)

Por ordem:

1. `godot --path cliente -- --servidor=192.168.0.10:8080 --sala=mesa`;
2. `user://rede.cfg`, secção `[servidor]`, com `host="IP:porta"` e `sala="..."`;
3. as definições `assimilacao/rede/host_padrao` e `sala_padrao` do `project.godot`.

Na web, a sala vem de `?sala=` no endereço (o QR do servidor).

## Exportar

Os presets e o CI são da **JV2.1b (Muse)**. A referência é esta:

- **Web**
  - preset Web com **Thread Support desligado** (`variant/thread_support=false`), o que dispensa COOP/COEP;
  - "VRAM Texture Compression → For Mobile" ligado, para os celulares;
  - o servidor de mesa serve o `index.html` e o `/mesa` **na mesma origem**, por http, na rede local.
- **Android**
  - permissão INTERNET;
  - arm64-v8a + x86_64;
  - keystore de release fixa num segredo do CI;
  - **a conferir:** o `ws://` em claro na rede local pode exigir `usesCleartextTraffic` ou uma `network_security_config` limitada à rede local (build Gradle).
- **Windows**
  - preset Windows Desktop x86_64, com o pck embutido;
  - num runner Windows.

## O que falta

1. ~~**Primeira execução** e correção de erros de compilação.~~ Feito no CI (08/11, ver abaixo). Falta a execução com servidor e o export.
2. **A-1:** os nomes dos campos marcados `PROVISÓRIO` têm de ser conferidos contra o TEST34–36. São: `minhaFiguraId`, `figuraId` no WELCOME, `x`/`y` ou `casa`, `para`, `vezId`, `partes`/`tipoDano`, `vida`/`vidaMax`/`vidaFracao`, `mapa.largura`/`altura`/`casaM`, `nome` nas opções e `texto` na reação.
3. **R0 (JV0.1):** falta o ângulo exato da Fixa (aceite ±2° e ±0,05), a forma de encerrar a vez e onde ficam Defender, Desvincular e Transformar, já que a barra só tem 3 botões.
4. **JV2.2:** câmera dinâmica e retrato (M-33); medir os rostos com 24 px ou mais no Panorama.
5. **JV2.3:** a faixa, o chip e a ficha completos; a paleta dos números (V1.2); a safe-area na web por CSS `env()`.
6. **JV3.1:** o lobby de verdade. Aqui há só nome e senha. Falta também o papel Mestre (JV0.5 c).
7. **Um servidor de teste** para o aceite "conecta e desenha o `ROOM_SNAPSHOT`".
8. Os perfis gráficos segundo o `docs/orcamento-perfis.md` (Plano B, V1.1).
9. O grep de regra do aceite (JV2.1a e JV2.4) tem de ser rodado no CI.

## Conferência de 08/11/2026 (CM-000008-I0004)

**Primeira execução real**, no CI do repositório (job `cliente`, Godot **4.7.2** oficial, sem janela):

- `--import` limpo;
- `testes/abrir_scripts.gd` (novo): os **11 scripts** do projeto compilam (o `gerar_rampas.gd` fica de fora: é um EditorScript, só existe no editor);
- `testes/rodar_testes.gd`: **40/40**;
- arranque da cena principal: a arena abre, vê que não há lugar e passa ao lobby; as duas imprimem `pronto`; zero `SCRIPT ERROR`.

**Textos (regra 12 e REF_22):** «Recarregue a página.» passou a «Atualiza a página.» (palavra do Mestre), no lobby e no HUD. Os outros achados de «carregar» e «press» são nomes de código (`_carregar_preferencias`, `pressed`), não texto visível.

**Achados, por resolver:**

1. ~~Falta a cena do Mestre.~~ **Feita a 08/11** (ver «Ecrã do Mestre» abaixo).
2. ~~**A desgraça e o teste de morte não aparecem à jogadora.**~~ **Resolvido (I0004, 08/11):** ver «Frases de batalha do site» abaixo.
3. ~~**Duas tabelas de perfis gráficos.**~~ **Resolvido (I0004, 08/11):** a arena passou a usar o `AplicadorPerfil` (nó `Perfis` na cena; `Sol` e `Ambiente` nos grupos `sol` e `ambiente`; o corpo das figuras no `figura`). Uma só tabela, guardada pelo teste «Uma só tabela de perfis gráficos». Muda o Baixo da arena: escala 3D de 0,75 para 0,5, como na tabela dos perfis.
4. ~~**A Clareira de prova não tem cena.**~~ **Resolvido (I0004, 08/11):** ver a secção «Clareira de prova» abaixo.
5. `docs/orcamento-perfis.md`, citado pelos perfis, não está no repositório.
6. **Registo da língua:** o cliente fala por «você» («Entre», «Escreva», «Espere», «Sua vez»); o site usa o imperativo de «tu» («aperta», «Atualiza»). Pergunta para o Mestre, pelo Muse.

## REF_18, REF_20 e REF_23 do site contra o cliente (I0004, 08/11/2026)

| REF | O site | O cliente | Pede mudança? |
| --- | --- | --- | --- |
| REF_18 (IBX-287) | Textos visíveis com «aperta» (sai «prime» e «carrega») e a família «quebrar» (sai «partir») | Nenhum texto visível tem «prime», «carrega» nem «partir»: os achados de `grep` são nomes de código (`pressed`, `_carregar_preferencias`, `_rotulo_quebrado`). O cliente não tem frases de instrução com o verbo do botão | **Não.** Fica a regra para as frases novas (desgraças, teste de morte) |
| REF_20 (IBX-290) | Painel ⚙ inutilizável em ecrãs baixos (a 844×390 só 29% visível); passou a folha lateral de duas colunas | O HUD escala por inteiro (`canvas_items` + `expand`, base 1920×1080) e a letra nunca desce de 13 px reais. **Medido no CI** (`testes/medir_painel_config.gd`, Godot 4.7.2): a 844×390 o «Fechar» acaba em 791 de 1080 unidades; a 780×360 em 830; a 1920×1080 em 605. Cabe sempre, sem rolagem | **Não.** A pendência F5-MESTRE-01 (vista do Mestre) não existe aqui porque não há cena do Mestre |
| REF_23 (IBX-295) | Limpeza visual v5: árvores pintadas como arte, chão sem malha xadrez (dither), crista limpa (anel de perto com `fAltAnel = 0,42`); palavra do Mestre «Boa. Perfeito» | A arena do cliente é provisória: chão de cor lisa (`COR_CHAO`, sem textura nem xadrez) e as linhas da grelha táctica; não há árvores, terreno nem crista. A Clareira de prova só tem primitivas | **Não, por agora.** Fica como referência aprovada pelo olho do Mestre para a Clareira final (V2.1). Atenção: a folhagem usa `usar_alpha_hash` (um pontilhado) nas copas que tapam figuras; o Mestre mandou tirar o pontilhado do chão do site, por isso o hash da folhagem tem de lhe ser mostrado antes de ficar |

## Clareira de prova (I0004, 08/11/2026)

**Abrir:** `arte/cenas/clareira_prova.tscn` no editor, ou sem janela pelo teste
`godot --headless --path cliente -s res://testes/abrir_clareira.gd`. Teclas da bancada: 1–4 (horas), P (perfil), C (ciclo), M (medição em JSON).

**O que a cena tem:**

| Nó | O que é |
| --- | --- |
| `ClareiraProva` | `Node3D` com o `clareira_prova.gd`, que monta o resto em código |
| `Ambiente` | `WorldEnvironment` (grupo `ambiente`): céu pelo `ceu_pintado.gdshader`, luz ambiente de cor (o color script escreve-a), neblina leve |
| `Sol` | `DirectionalLight3D` (grupo `sol`), com sombra, a iluminar o céu (`sky_mode` luz e céu) |
| `Camera` | `Camera3D` com o `camera_mesa.gd` (a mesma câmara da arena) |
| `Perfis` | o `AplicadorPerfil`, a mesma tabela que a arena usa |
| `Medicao/Rotulo` | rótulo com perfil, fps, chamadas, primitivas e hora |

Montado pelo script, tudo PLACEHOLDER: chão 44×44 m com textura de ruído, 6 árvores frondosas e 1 gigante, 60 arbustos numa MultiMesh, 6 rochas, 2 tochas sem sombra, 4 figuras de 1,80 m × 1,25 e a besta, com contorno.

**Pontilhado das copas (REF_23):** `USAR_PONTILHADO_COPAS = false` no `clareira_prova.gd`. As copas usam o recorte simples (alpha scissor), sem pontilhado. Ligar o pontilhado (alpha hash) nas copas que tapam figuras é **ponto para o olho do Mestre**: fica desligado até à palavra dele.

**Teste (`testes/abrir_clareira.gd`, no CI):** 22 verificações — a cena carrega e o `_ready` corre; os 5 nós existem; o céu é o shader pintado; os grupos estão cheios (1 sol, 1 ambiente, 5 figuras, 8 folhagens, 1 MultiMesh densa); o perfil médio entra no arranque; nenhuma copa tem pontilhado; as 4 horas-chave aplicam-se; Baixo tira o contorno e põe metade dos arbustos, Alto repõe; o rótulo actualiza-se.

**O que ainda lhe falta:**

1. **Os assets verdadeiros** (V2.1): FICA/LAPIDA, o T1 do chão, a Besta Cristalina, os vagalumes. Tudo o que lá está é placeholder.
2. **As rampas** (`rampa_<família>.png`): correr o `gerar_rampas.gd` no editor. Até lá, uma rampa genérica.
3. **A máscara de pincel** verdadeira (V0.1): hoje é ruído.
4. **Os shaders nunca foram compilados**: o Godot sem janela usa um renderizador vazio. Falta abrir a cena num computador com GPU (ou no telemóvel) para ver erros de shader e o aspecto.
5. **A medição de FPS** (B3) no Redmi Note 10 Pro, com os 3 perfis: só com o telemóvel.
6. **O olho do Mestre**: a luz das 4 horas, a cor das sombras e o pontilhado das copas.

## Frases de batalha do site (I0004, 08/11/2026)

As frases que a jogadora vê na desgraça, no relógio de morte e no fim são **as mesmas do site vivo**. Vieram do Muse e eu conferi-as contra o `jogo-t1/jogo.js` servido (REF_25, SHA `d022aae4…`): `vlabFraseDesgraca` (linha 1020), o relógio de morte (1083–1090) e o fim (2162–2165).

- **Onde estão:** `hud/frases_batalha.gd` (só texto, sem regra). O `estado.gd` escolhe a frase a partir do que o servidor projeta e emite `frase_batalha`; o `hud.gd` mostra-a no aviso durante 6 s.
- **Desgraça:** «Falha crítica · » + a frase do efeito. A arma é a do último `ataque` de quem falhou. «Perde um quarto da vida que tem agora.» só entra quando vem `perdeQuarto`, ou seja, só para a própria. Jogadora com artigo e no feminino («a Ong», «própria», «dela»); criatura com o nome e no masculino.
- **Relógio de morte (só dela):** ao entrar a morrer, «A Ong caiu — a batalha continua à volta dela.»; depois de cada `teste_morte`, o `estadoMorte` seguinte diz se foi «aguenta-se» (mais um sucesso) ou «piora visivelmente» (mais uma falha). A Party nunca vê a CD nem os números.
- **Fim:** morte, estabilizada e vitória. A frase de vitória não estava na lista do Muse: copiei-a do mesmo `jogo.js` (linha 2162).
- **Testes:** 18 de texto exacto contra as frases do site e 9 a partir de eventos (no `rodar_testes.gd`). O cliente está em 73/73.

**Duas diferenças conscientes:**

1. **Sem «Aperta Recomeçar para jogar outra vez.»** O site acaba as frases de fim com isto, mas o cliente não tem o botão Recomeçar, e o texto só promete o que a casca faz (a regra da REF_14). A cláusula está guardada em `CLAUSULA_RECOMECAR`; entra mudando `HA_BOTAO_RECOMECAR` para `true` quando o botão existir.
2. **«Estabilizada» como fim:** no site, estabilizar acaba a batalha; o servidor não a acaba (o `desfecho` só é `vitoria` ou `morte`), por isso a frase de fim estabilizada fica pronta mas não sai. É a pergunta 7 ao Mestre («Estabilizada é derrota?»).

**Tratamento:** as frases usam «tu», como no site. A pergunta tu/você está com o Mestre.

## Ecrã do Mestre (JV3.1, I0004, 08/11/2026)

O desenho foi aprovado com emendas pelo Muse (Notion: «JV3.1 — Ecrã do Mestre no cliente: desenho aprovado com emendas (rascunho 0.2)»). O código está em `cenas/mestre/`:

| Ficheiro | O que faz |
| --- | --- |
| `mestre.tscn`, `mestre.gd` | A cena. Recusa abrir para quem não é Mestre e volta ao lobby. À esquerda fica a arena 3D; à direita a folha do Mestre, em duas colunas: a coluna 1 é fixa (cartão activo com os botões, fila, sala, alertas, encolher); a coluna 2 tem abas que rolam por dentro. O aviso da 1.ª entrada aparece uma vez só. Nada se decide por tempo |
| `modelo_mestre.gd` | Funções puras: o texto das figuras, do ambiente, dos cartões e dos pontos de «voltar», e o comando de cada botão. A frase que a Party vai ler sai das frases do site |
| `textos_mestre.gd` | As palavras visíveis: as do site (Confirmar, Voltar, Registo da batalha, Exportar registo…) e a regra da casa. Inclui o `TODO(N4-TERMINAR)`: terminar ou recomeçar a batalha **não existe** até a resposta N4 do Mestre |
| `arena_mestre.gd` | A arena 3D num SubViewport, com a câmara da mesa. Mostra todas as figuras colocadas e um anel na figura da vez; destaca as casas que o servidor mandou e diz que casa se tocou |
| `aba_agir.gd` | O modo H10 da criatura da vez (MASTER_MODE). Mover, atacar e as acções vêm das ROOM_OPTIONS do servidor e saem como MASTER_ACT |
| `aba_mesa.gd` | Procurar fichas, «Guardar a mesa» (MASTER_LOBBY_SET), «Começar a batalha» com 2.º toque (MASTER_START) e «Colocar» a ficha numa casa (MASTER_PLACE, uma de cada vez) |
| `aba_registo.gd` | «Exportar registo» (MESTRE-ONLY no nome) e «Voltar até aqui». Os pontos vêm do servidor (L8). Escolher o ponto só pergunta; só o botão de confirmar o manda |

**Privacidade (segunda tranca):** `rede.gd` não guarda nenhum `MASTER_*` e `estado.gd` não guarda o bloco `mestre` fora do lugar do Mestre. A prova é `testes/canario_privacidade.gd`, que também varre o código.

**Testes no CI**, todos com mensagens reais do servidor (`servidor/dados-exemplo/mesa-mestre.json`):
- `abrir_mestre.gd`: recusa noutro papel, os 4 cartões, nada por tempo, a lista do «Escolher outra», as emendas 1 e 2.
- `pecas_mestre.gd`: arena 3D, «Voltar até aqui», aba Mesa, aba Agir, «Jogo eu» → aba Agir.
- `canario_privacidade.gd`.
- `medir_mestre.gd`: F5-MESTRE-01 a 844×390, 780×360 e 1920×1080.
- Os comandos que os testes montam são conferidos contra os schemas (`protocolo/ferramentas/validar-mensagens.py`).

**Por fazer:**
- «Escolher outra» acção no cartão de IA: enquanto há cartão aberto o servidor não manda opções, por isso o caminho é «Jogo eu» e depois a aba Agir.
- O lote de colocação por esquema (L5, D5) e o agrupar das marchas (L6, D4).
- O selo TESTE e as estatísticas (L9).
- Terminar ou recomeçar a batalha (N4).
- Os marcadores 3D definitivos (Plano B).
