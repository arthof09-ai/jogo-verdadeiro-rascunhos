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

1. **Primeira execução** e correção de erros de compilação. Nada foi rodado.
2. **A-1:** os nomes dos campos marcados `PROVISÓRIO` têm de ser conferidos contra o TEST34–36. São: `minhaFiguraId`, `figuraId` no WELCOME, `x`/`y` ou `casa`, `para`, `vezId`, `partes`/`tipoDano`, `vida`/`vidaMax`/`vidaFracao`, `mapa.largura`/`altura`/`casaM`, `nome` nas opções e `texto` na reação.
3. **R0 (JV0.1):** falta o ângulo exato da Fixa (aceite ±2° e ±0,05), a forma de encerrar a vez e onde ficam Defender, Desvincular e Transformar, já que a barra só tem 3 botões.
4. **JV2.2:** câmera dinâmica e retrato (M-33); medir os rostos com 24 px ou mais no Panorama.
5. **JV2.3:** a faixa, o chip e a ficha completos; a paleta dos números (V1.2); a safe-area na web por CSS `env()`.
6. **JV3.1:** o lobby de verdade. Aqui há só nome e senha. Falta também o papel Mestre (JV0.5 c).
7. **Um servidor de teste** para o aceite "conecta e desenha o `ROOM_SNAPSHOT`".
8. Os perfis gráficos segundo o `docs/orcamento-perfis.md` (Plano B, V1.1).
9. O grep de regra do aceite (JV2.1a e JV2.4) tem de ser rodado no CI.
