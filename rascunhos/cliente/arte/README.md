# Kit de shaders V1.1 — Assimilação (rascunho)

Missão V1.1 do Plano B v1.1 (Notion `410c2b324ede8137b98bf7e75afa7e89`). Godot 4.7, renderizador **Compatibility** (WebGL 2 e celular). Direção: Arcane, pintado à mão, sombras coloridas, luz de contorno, contorno na cor do albedo só nas figuras, folhagem viva.

**Estado: RASCUNHO. Ainda não foi compilado nem medido.** Foi escrito no PCDANASA sob a NAC-OV-05: nada foi executado. Tem de passar pelos Críticos e pela bancada antes de entrar no repositório.

## Arquivos

| Arquivo | O que é |
| --- | --- |
| `shaders/toon_pintado.gdshader` | Material base: rampa por família, terminador quebrado por pincel, sombra colorida em `light()`, rim, especular mínimo |
| `shaders/contorno_casca.gdshader` | Casca invertida (`cull_front, unshaded`), com espessura em píxeis de ecrã |
| `shaders/folhagem_vento.gdshader` | Alpha scissor ou hash, vento no vértice, normais de volume e a mesma sombra colorida |
| `shaders/ceu_pintado.gdshader` | `shader_type sky`: gradiente de 3 cores, sol suave e 4 horas |
| `rampas/gerar_rampas.gd` | `@tool EditorScript` que gera `rampa_<familia>.png` (256×1) das 7 famílias |
| `ambiente/color_script.gd` | `Resource` `ColorScript`: 4 horas em hex, `amostrar(hora)` e `aplicar(...)` |

## Como aplicar

1. **Projeto**
   - Renderizador `gl_compatibility`.
   - `rendering/shading/overrides/force_vertex_shading = false`. Com vertex shading, o `light()` não corre (doc do spatial shader) e a sombra colorida some.
   - Não ligar `vertex_lighting` nos materiais.
2. **Rampas.** Abrir `rampas/gerar_rampas.gd` no Script Editor e fazer File > Run (Ctrl+Shift+X). Saem 7 PNG na mesma pasta. Importar cada PNG como **Lossless, sem mipmaps**: compressão VRAM em blocos 4×4 estraga uma textura de 1 px de altura.
3. **Materiais (toon).** Um `ShaderMaterial` com `toon_pintado` por família:
   - `rampa` = PNG da família;
   - `pincel` = máscara de pincelada em cinzento, com 0,5 neutro. Sem máscara, `forca_pincel = 0`.
   - Família metal: `metalico ≤ 0,3`, porque o motor reduz a difusa por (1 − METALLIC).
4. **Contorno (só figuras).** No material toon da figura, em **Next Pass**, um `ShaderMaterial` com `contorno_casca` e a mesma `textura_albedo`, `cor_albedo` e `escala_uv`.
   - Malhas com arestas duras: gravar as normais suavizadas na cor do vértice (RGB = n·0,5+0,5) e ligar `normal_suave_em_cor`.
   - Perfil Baixo: `material.next_pass = null`.
   - Nunca pôr em cenário.
5. **Folhagem.**
   - Peso do vento:
     - `fonte_peso = 0`: cor do vértice R (0 na base, 1 na ponta). Uma malha sem cor de vértice lê branco e mexe-se inteira.
     - `1` ou `2`: UV.y ou 1 − UV.y.
   - `centro_copa` em espaço do **modelo** (o centro da massa da copa).
   - Baixo: `usar_alpha_hash = false` (scissor). Copas que tapam figuras: `usar_alpha_hash = true` e `set_instance_shader_parameter("opacidade_dither", x)` por árvore.
6. **Céu.** WorldEnvironment > Environment > Sky > `ShaderMaterial` com `ceu_pintado`. A DirectionalLight3D do sol tem de ter **Sky Mode** a incluir o céu, para preencher `LIGHT0_*`.
7. **Color script.** Criar um `.tres` do tipo `ColorScript`.
   - No arranque: `preencher_ceu(material_ceu)`.
   - Ao mudar a hora: `aplicar(hora, sol, environment, materiais_luz, materiais_contorno, material_ceu)`.
   - `aplicar` escreve:
     - `light_color` e `light_energy` do sol;
     - `ambient_light_color` (= sombra) e `fog_light_color` (= neblina);
     - `cor_sombra`, `tinta_contorno` e `hora`.
   - O `ambient_light_source` e a neblina de altura ficam configurados na cena.

## O que é PROVISÓRIO (fecha com o guia V0.1)

- Todos os hex do `color_script.gd` e as cores padrão do `ceu_pintado` (iguais às do color script).
- As horas-chave: 8 h, 15 h, 18,5 h e 22 h.
- As paradas das 7 rampas em `gerar_rampas.gd`.
- Os padrões das uniforms:
  - toon: `cor_sombra`, rim, especular, `forca_pincel`, `piso_sombra`;
  - contorno: `fator_escuro`, `saturacao`, tinta;
  - folhagem: vento, translucidez, variação.
- A máscara de pincel e a textura de pinceladas do céu: **ainda não existem**. São pedido ao Muse/V0.1.
- O `docs/orcamento-perfis.md` (saída da V1.1) **não está neste rascunho**. Fica pendente, com dono único, o Claude.

## Riscos de desempenho no celular

- **Passes de sombra.** No Compatibility, luzes com sombra usam multi-passe (doc "Renderers").
  - Só a direcional tem sombra; tochas sempre com `shadow_enabled = false`.
  - Cada divisão da sombra direcional volta a desenhar os projetores. No Médio, usar 1 ou 2 divisões e `directional_shadow/size.mobile` (padrão 2048).
  - A folhagem a projetar sombra pode dobrar as chamadas: medir com e sem, contra o p95 ≤150.
- **`light()` por píxel e por luz.**
  - Cada luz faz 1 leitura da rampa e um `pow`.
  - Manter poucas omni por malha (limite de 8). Tochas distantes: desligar pela distância.
- **MSAA.** No WebGL 2, o MSAA 3D custa banda e memória; em GPUs de mosaico, o 2× é o máximo razoável.
  - **Divergência com a B2.2:** a doc oficial diz que o Compatibility tem MSAA 3D *"but no alpha to coverage"*. O "MSAA 2× com Alpha Edge Blend no Médio" não se consegue. Proposta de errata: Médio = MSAA 2× (só para as bordas geométricas) + scissor nas folhas, e hash só nas copas que tapam figuras.
- **Alpha.**
  - Scissor e hash usam `discard`, que desliga a eficácia do pré-passe de profundidade (doc da linguagem) e custa caro em overdraw nas copas.
  - Reduzir a área transparente dos cartões (malha justa à folha).
  - O alpha hash sem TAA (inexistente no Compatibility) cintila: usar só onde a B2.2 pede.
- **Contorno.**
  - O next pass dobra as chamadas e os vértices de cada figura. Só nas figuras, e desligado no Baixo.
  - A casca é atirada para fora do recorte no `IN_SHADOW_PASS`, para não entrar na sombra.
- **Céu.**
  - Mudar uma uniform do céu obriga a refazer o cubemap de radiance.
  - Atualizar `hora` em degraus (por exemplo, a cada 5–10 s de jogo, ou ao passar 0,1 h) e usar o Sky com `radiance_size` pequeno (64 ou 128).
  - O shader não usa `TIME`, de propósito.
- **Precisão e LDR.**
  - O Compatibility é RGBA8, LDR e de precisão média. O céu limita a saída a ≤1.
  - O `TIME` grande perde precisão no `sin` do vento; o motor reinicia o TIME (time rollover). Verificar visualmente a costura.
- **Escala 3D 0,6–0,75 no Médio.** Por isso o contorno tem `largura_minima_px`; sem esse mínimo, a 1080p×0,6 ele desaparece.

## Divergências com a documentação, a levar à bancada

1. O alpha to coverage não existe no Compatibility (ver acima). Afeta a B2.2.
2. A página "Renderers" lista Decals no Compatibility com limite ("8 per surface, 64 per view"), mas a B2.2 diz "não tem decals". Conferir na 4.7 antes da V4.3 (marca de queimado em quad).
3. `force_vertex_shading`: na doc atual não aparece um override `.mobile`. Confirmar no `project.godot` que não há override.

## Verificações para a V1.1 (B3 + kit)

**Compilação e funcionamento** (bancada, fora do PCDANASA):

- [ ] Os 4 shaders compilam sem erros no Compatibility (desktop e export web).
- [ ] O `light()` corre: com `cor_sombra` = vermelho de teste, a sombra própria **e** a projetada ficam vermelhas.
- [ ] As rampas são geradas (7 PNG 256×1) e importadas como Lossless.
- [ ] O `ColorScript.amostrar` dá a mesma cor que o céu em 0, 6, 8, 12, 15, 18,5, 20, 22 e 23,9 h.
- [ ] O contorno mede 1–1,5 px a 1920×1080, e ≥ `largura_minima_px` no viewport do celular (≈873×393, a V1.0 confirma).
- [ ] O contorno só aparece nas figuras e some no Baixo.
- [ ] A folhagem alterna entre scissor e hash; o `opacidade_dither` funciona por instância.

**Métricas B3** (captura: Movie Maker `--write-movie f.png --fixed-fps 30`, câmera Fixa com zoom 1,5, a 1920×1080 e no viewport do celular, **nas 4 horas**):

- [ ] Sombra: p5 de L\* ≥15 de dia e ≥10 à noite.
- [ ] Sombra: croma ≥6, com matiz entre 230° e 320°.
- [ ] Nenhum píxel de jogo com L\* <5.
- [ ] Silhueta: contraste (L1+0,05)/(L2+0,05) entre a figura e um anel de 12 px ≥2,0 em ≥95% dos quadros, em 8 orientações (passe de depuração: figuras a branco).
- [ ] Chamadas de desenho: `RENDER_TOTAL_DRAW_CALLS_IN_FRAME` p95 ≤150, sombras e next pass incluídos.
- [ ] FPS no aparelho, pelo link da V1.0, no perfil Médio: mediana ≥30 e p5 ≥20, depois de 10 s de aquecimento.
- [ ] Teste de estátua: ≥2% dos píxeis de cada figura parada mudam em 1,2 s. O vento ajuda a folhagem; as figuras precisam de animação própria.
- [ ] Fotos lado a lado (aprovado × kit novo) na mesma câmera, para cada asset aprovado de B1. O material aprovado continua como opção na ⚙.

**Rubrica B5** (Diretor de Arte, Programador Gráfico, Fluidez):

- [ ] Sem preto puro nas sombras.
- [ ] Materiais pintados, não plástico.
- [ ] Vegetação viva.
- [ ] Legível no celular.
- [ ] Fluidez dentro do orçamento.
