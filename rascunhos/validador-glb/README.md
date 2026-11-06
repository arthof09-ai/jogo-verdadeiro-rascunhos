# Validador GLB-JOGO-v1 (O1.1): rascunho 0.1

Validador único do contrato **O1.1 — GLB-JOGO-v1** (Notion `410c2b324ede8190b790c902206e0494`).
O app da Oficina e o CI do jogo chamam-no. Ele diz se um `.glb` **pode** entrar no jogo, e não se está bonito.

## Estado (06/11/2026)

- **Escrito, mas NUNCA executado.** Foi feito no PCDANASA sob a regra NAC-OV-05: nada se executa sem Críticos. Por isso nenhum teste correu ainda.
- O primeiro passo é um **pacote NAC-OV-05** que rode os testes e traga o resultado para a bancada (ver "Como rodar").
- `ossos-ual1.json` tem a lista **completa** dos 65 ossos, lida do JSON do `UAL1_Standard.glb`. Falta o **SHA-256** desse arquivo, porque calculá-lo exige executar código. O mesmo pacote resolve isso.

| Arquivo | O que é |
| --- | --- |
| `validar-glb-jogo.mjs` | Validador: CLI e biblioteca (V01–V18). Só usa `node:fs`, `node:crypto` e `node:path`. |
| `ossos-ual1.json` | 23 ossos obrigatórios (§5.1), a lista completa de 65 (`skins[0].joints` → `nodes[].name`) e a fonte declarada. |
| `gerar-iscas.mjs` | Gera em JS puro o GLB correto mínimo, as 8 iscas do §8 e, se receber o UAL1, um GLB derivado dele. |
| `testes/validar.test.mjs` | Testes `node:test`. Cada isca tem de reprovar com a falha certa, e só com ela. O correto tem de ser aprovado. |

## Como rodar (conteúdo do futuro pacote NAC-OV-05)

Precisa de Node ≥ 18. Não há nada para instalar.

```bat
cd C:\Users\txcga\RPG_Local\jogo-verdadeiro\rascunhos\validador-glb

# 1. testes (tudo em memória, não escreve nada)
node --test testes/validar.test.mjs

# 2. testes com o UAL1 real (lista de ossos e GLB derivado)
set UAL1_GLB=C:\Users\txcga\RPG_Local\Oficina3D\staging-mixamo\ual1\Universal Animation Library[Standard]\Unreal-Godot\UAL1_Standard.glb
node --test testes/validar.test.mjs

# 3. regravar ossos-ual1.json, agora com o SHA-256
node validar-glb-jogo.mjs --extrair-ossos-ual1 "%UAL1_GLB%" > ossos-ual1.json

# 4. gerar os arquivos-isca no disco (pasta iscas\ e manifesto.json com os SHA)
node gerar-iscas.mjs --ual1 "%UAL1_GLB%"

# 5. validar um arquivo
node validar-glb-jogo.mjs iscas\correto-minimo__v01.glb
```

A saída é um JSON: `{contrato, arquivo, sha256, veredito, falhas[], avisos[], medidas{}}`.
O código de saída é **0** quando sai APROVADO e **1** quando sai REPROVADO ou há erro.
`medidas.verificacoes` dá o estado de cada V (ok, aviso, falha, nao_aplicavel ou nao_executada).
O campo `arquivo` leva só o nome-base. Assim o PC, o CI e a VM dão o mesmo JSON para os mesmos bytes (§8.3).

Atenção: o passo 3 regrava o `ossos-ual1.json` só com os campos que o extrator conhece e perde `hierarquia` e `medidasDeReferencia`. Se quiser mantê-los, copie à mão apenas `fonte.sha256` e `fonte.bytes`.

## Errata proposta à O1.1 (§7): Python → Node

> **Onde se lê** "Python só com a biblioteca padrão", **leia-se** "JavaScript (Node ≥ 18, ESM) só com `node:fs`, `node:crypto` e `node:path`".

Motivo: o PC tem Node e não tem Python, e o CI e a VM também têm Node. O critério "sem dependências pesadas" continua cumprido. Os testes usam ainda `node:test` e `node:assert`, que vêm com o Node.

## Como cada verificação foi feita

| V | Implementação |
| --- | --- |
| V01 | Cabeçalho `glTF` v2, comprimento, chunk JSON, chunk BIN e `asset.version` 2.x. O GLB tem de ser autocontido (sem buffers externos). |
| V02 | `extensionsRequired` só com `KHR_texture_transform` e `KHR_materials_emissive_strength`. Draco ou meshopt em `extensionsUsed` também reprova; outras extensões usadas dão aviso. |
| V03 | `asset.extras.contrato` e `asset.extras.origem{rota, referenciaSha, oficinaJob, data}`. Nome fora de `<id>__v<NN>.glb` dá aviso. |
| V04 | Altura pelos `accessor.min/max` do POSITION, nos 8 cantos transformados pela matriz do nó. **Malha com skin:** o glTF manda ignorar a transformação do nó, então usam-se as posições de descanso. Peças com `extras.anexo` não entram na medida. A mensagem acusa ×100 ou ×0,01. |
| V05 | A mesma caixa: \|Ymin\| ≤ 1 cm e centro XZ a ≤ 5 cm. A mensagem acusa um pivô no meio do corpo. |
| V06 | **a)** Decide: vetor `foot → ball` dos dois pés (ou `DEF-foot → DEF-toe`), na pose de descanso e projetado em XZ; desvio > 5° reprova. **b)** Sem pés: média das normais dos vértices dominados por `Head`, que só dá **aviso** (heurística). Sem `Head`: aviso, como diz o §7. |
| V07 | Nó da malha e ancestrais: `scale` = 1 e `rotation` = 0 (tolerância 1e-4), e `matrix` sem rotação nem escala. |
| V08 | Triângulos pelo `count` dos índices (TRIANGLES /3; STRIP e FAN n−2), por instância. Teto do Alto: 40 000, ou 60 000 com `extras.tipo = "criatura_grande"`. Falta de NORMAL e faces degeneradas dão aviso. |
| V09 | PNG: largura e altura do IHDR, alfa pelo tipo de cor ou por um tRNS. JPEG: marcadores até um SOF (C0–CF, menos C4, C8 e CC). A textura tem de ser quadrada, potência de 2 e ≤ 2048; abaixo de 1024 dá aviso. Alfa num albedo sem MASK dá aviso. |
| V10 | `baseColorTexture`, `metallicFactor` ≤ 0,1 e `roughnessFactor` ≥ 0,7 (os valores padrão do glTF são 1). Na v1 só dá **aviso**; a constante `V10_REPROVA` liga a reprovação da v2. |
| V11 | Nomes de `skins[].joints`. UAL1: os 23 obrigatórios. Rigify: só `DEF-*` e `root`. `mixamorig*`, `ORG-*` e `MCH-*` reprovam. O tipo vem de `extras.esqueleto`; se faltar, deduz-se pelo papel e pelos nomes. |
| V12 | Ossos fora da lista completa (`ossos-ual1.json`) só com o prefixo `x_`, descendendo (direto ou numa cadeia `x_`) de um osso base. Faltar dedos dá aviso. |
| V13 | Lê os floats (ou os inteiros normalizados) de `JOINTS_n` e `WEIGHTS_n` no BIN. Reprova: mais de 4 influências > 0, soma ≠ 1 ± 1e-4, vértice sem peso, peso negativo ou índice de osso inválido. |
| V14 | Clips mínimos por `extras.papel`: `combate` (ou `jogavel`, `npc_combate`), `conjurador`, `quadrupede` ou `objeto`. |
| V15 | Nomes da tabela do §6, com `_loop` só em `parado`, `andar` e `correr`. Dá a dica do nome nativo (ex.: `Idle_Loop → parado_loop`). Falta de `extras.origem` ou de `velocidadeMs`, ou passo ≠ 1/30 s, dá aviso. |
| V16 | Três regras: `extras.anexo` ∈ {`mao_r`, `mao_l`}; a mesma malha não pode servir ao corpo e à peça anexa; e uma **heurística geométrica**. A heurística procura, dentro do corpo, uma ilha ligada (com solda por posição) presa ≥ 99% a um osso de mão e com mais de 0,25 m: isso é arma fundida. |
| V17 | TEXCOORD_0 em [0,1] (tolerância 1e-4) nas primitivas do corpo. A falta de UV no corpo reprova; UV fora de [0,1] numa peça anexa dá aviso. |
| V18 | SHA-256 do arquivo inteiro, sempre no relatório. |

### Campos de `asset.extras` que o validador lê (proposta de detalhe para a O1.1)

| Campo | Valores |
| --- | --- |
| `contrato` | `GLB-JOGO-v1` |
| `origem` | `{rota, referenciaSha, oficinaJob, data}` |
| `alturaM` | número, em metros |
| `papel` | `combate`, `conjurador`, `quadrupede` ou `objeto` |
| `esqueleto` | `ual1` ou `rigify` (opcional) |
| `tipo` | `personagem` ou `criatura_grande` (escolhe o teto da V08) |

O §1–§7 não fixava os valores de `papel`, `esqueleto` e `tipo`. Esta proposta tem de entrar por errata.

## As iscas (§8.1)

Cada isca é o GLB correto mínimo com **um** defeito. O teste exige que o conjunto de falhas seja exatamente o esperado.

| Isca | Defeito | Falha |
| --- | --- | --- |
| `isca-escala-x100` | vértices e ossos ×100 | V04 |
| `isca-pivo-umbigo` | tudo 1 m abaixo (Ymin = −1) | V05 |
| `isca-sem-head` | sem o osso `Head` | V11 (e aviso na V06) |
| `isca-mixamorig` | ossos `mixamorig:*` | V11 |
| `isca-clip-idle` | clip extra `Idle` | V15 |
| `isca-cinco-influencias` | vértice 0 com 5 × 0,2 | V13 |
| `isca-textura-1000` | PNG 1000×1000 | V09 |
| `isca-arma-fundida` | espada na primitiva do corpo, 100% em `hand_r` | V16 |

O correto mínimo é uma "caixa em T" de 1,80 m com os 23 ossos obrigatórios e pés que apontam para +Z. Tem uma espada num nó próprio (`extras.anexo = "mao_r"`), um PNG de 1024 válido (deflate sem compressão) e os 8 clips do papel `combate` a 30 FPS. Espera-se que saia **APROVADO**, com avisos na V12: faltam os dedos e a lista ainda não tem SHA.

## O que ficou por fazer

1. **Rodar os testes** (pacote NAC-OV-05) e corrigir o que falhar. O código foi escrito sem execução.
2. **SHA-256 do `UAL1_Standard.glb`** em `ossos-ual1.json` (passo 3 de "Como rodar").
3. **§8.2, GLB correto feito do UAL1:** o `gerar-iscas.mjs --ual1` já renomeia os clips pela tabela do §6. Mesmo assim, deve reprovar na **V14** até `cair` e `levantar` chegarem do Mixamo por retarget (O7.1b). Também não tem textura pintada, então a V10 dá aviso.
4. **§8.3:** rodar no CI do jogo e na VM do Muse e comparar o veredito e o SHA.
5. Partes do contrato que **não** são verificadas:
   - UV sem sobreposição no corpo;
   - malha fechada e soldada a 1e-6;
   - peso em osso `x_` que não seja da sua peça (§5.3);
   - o efeito de `KHR_texture_transform` sobre a V17.
6. **V06:** confirmar no UAL1 real que os pés apontam para +Z e que o importador do Godot respeita isso (pendência do §9).
7. **V15:** confirmar que o Godot 4.7.2 reconhece o sufixo `_loop` (pendência do §9).
8. **Críticos:** Programador e Pipeline 3D (§8.4).
