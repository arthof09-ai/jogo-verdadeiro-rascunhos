#!/usr/bin/env node
/**
 * validar-glb-jogo.mjs — Validador do contrato GLB-JOGO-v1 (missão O1.1, RPG "Assimilação").
 *
 * Especificação: Notion "O1.1 — Contrato GLB-JOGO-v1 e validador (rascunho 0.1, 06/11/2026)",
 * página 410c2b324ede8190b790c902206e0494. Verificações V01–V18 do §7.
 *
 * ERRATA PROPOSTA À O1.1: o contrato pedia Python só com a biblioteca padrão. Este validador é
 * JavaScript (Node >= 18, ESM) e usa SÓ node:fs, node:crypto e node:path, para correr no PC,
 * no CI do jogo e na VM do Muse sem instalar nada.
 *
 * Uso:
 *   node validar-glb-jogo.mjs <arquivo.glb> [--ossos ossos-ual1.json] [--compacto]
 *   node validar-glb-jogo.mjs --extrair-ossos-ual1 <UAL1_Standard.glb>   (imprime o JSON da lista de ossos, com SHA)
 *
 * Saída: JSON {contrato, arquivo, sha256, veredito, falhas[], avisos[], medidas{}} no stdout.
 * Código de saída: 0 = APROVADO, 1 = REPROVADO (ou erro de uso/leitura).
 *
 * ESTADO: rascunho 0.1, escrito sem execução (regra NAC-OV-05 no PCDANASA). Tem de correr os
 * testes (testes/validar.test.mjs) num pacote NAC-OV-05 antes de entrar no repositório.
 */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

export const CONTRATO = 'GLB-JOGO-v1';
export const VERSAO_VALIDADOR = '0.1.0-rascunho';

// ---------------------------------------------------------------------------------------------
// Constantes do contrato
// ---------------------------------------------------------------------------------------------

/** §1: as únicas extensões que podem aparecer em extensionsRequired. */
const EXTENSOES_PERMITIDAS = new Set(['KHR_texture_transform', 'KHR_materials_emissive_strength']);
/** §1: compressão proibida na v1 (o Godot web tem de importar sem surpresa). */
const EXTENSOES_PROIBIDAS = new Set([
  'KHR_draco_mesh_compression',
  'EXT_meshopt_compression',
  'KHR_meshopt_compression',
]);

/** §5.1: ossos obrigatórios do humanoide UAL1 (nomes exatos, padrão UE). */
export const OSSOS_OBRIGATORIOS_UAL1 = Object.freeze([
  'root', 'pelvis', 'spine_01', 'spine_02', 'spine_03', 'neck_01', 'Head',
  'clavicle_l', 'clavicle_r', 'upperarm_l', 'upperarm_r', 'lowerarm_l', 'lowerarm_r',
  'hand_l', 'hand_r', 'thigh_l', 'thigh_r', 'calf_l', 'calf_r', 'foot_l', 'foot_r',
  'ball_l', 'ball_r',
]);

/** Tolerâncias (§2, §5.3 e §3). */
const TOL = {
  alturaRelativa: 0.02, // ±2% da extras.alturaM
  yMin: 0.01, // |Ymin| <= 1 cm
  centroXZ: 0.05, // centro XZ a <= 5 cm da origem
  frenteGraus: 5, // ±5°
  transformacao: 1e-4, // escala 1 e rotação 0 ("exato", com folga de arredondamento float32)
  somaPesos: 1e-4, // soma das influências = 1 ± 1e-4
  uv: 1e-4, // UV em [0,1] com folga de arredondamento
};

/** §4, perfil Alto (o validador confere o Alto). PROVISÓRIO até a V1.1. */
const TETO_TRIANGULOS = { personagem: 40000, criatura_grande: 60000 };
const TEXTURA_MAX = 2048;
const TEXTURA_MIN_ESPERADA = 1024; // §3 diz "1024 ou 2048"; menos que isso é só aviso
const MAX_INFLUENCIAS = 4;

/** V10: na v1 é aviso; na v2 do contrato passa a reprovar. */
const V10_REPROVA = false;

/** §6: nomes de clips. Os de laço levam o sufixo _loop no GLB. */
const CLIPS_LACO = new Set(['parado', 'andar', 'correr']);
const CLIPS_SEM_LACO = new Set(['atacar', 'golpe', 'morrer', 'conjurar', 'cair', 'levantar', 'conjurar_cajado']);
const CLIPS_LOCOMOCAO = new Set(['andar', 'correr']);
const FPS_ESPERADO = 30;

/** §6: dica de renomeação dos clips nativos do UAL1 (e do Mixamo) para os nomes do jogo. */
const DICA_CLIP = {
  Idle: 'parado_loop',
  Idle_Loop: 'parado_loop',
  Walk_Loop: 'andar_loop',
  Jog_Fwd_Loop: 'correr_loop',
  Sprint_Loop: 'correr_loop',
  Sword_Attack: 'atacar',
  Hit_Chest: 'golpe',
  Death01: 'morrer',
};

/** §6 "Mínimo por papel" (extras.papel). */
const CLIPS_COMBATE = ['parado', 'andar', 'correr', 'atacar', 'golpe', 'cair', 'levantar', 'morrer'];
const PAPEIS = {
  combate: { clips: CLIPS_COMBATE, esqueleto: true },
  conjurador: { clips: CLIPS_COMBATE, umDe: ['conjurar', 'conjurar_cajado'], esqueleto: true },
  quadrupede: { clips: ['parado', 'andar', 'correr', 'atacar', 'golpe', 'morrer'], esqueleto: true },
  objeto: { clips: [], esqueleto: false },
};
/** Sinónimos aceites para extras.papel (o contrato diz "personagem jogável ou NPC de combate"). */
const SINONIMOS_PAPEL = { jogavel: 'combate', npc_combate: 'combate', personagem: 'combate' };

/** §3: valores aceites de extras.anexo. */
const ANEXOS_VALIDOS = new Set(['mao_r', 'mao_l']);
/** V16 (heurística): ossos de mão onde uma arma fundida costuma ficar presa. */
const OSSOS_MAO = new Set(['hand_l', 'hand_r', 'DEF-hand.L', 'DEF-hand.R']);
const ARMA_FUNDIDA_COMPRIMENTO_MIN = 0.25; // metros
const ARMA_FUNDIDA_PESO_MIN = 0.99;

/** V06: pares (pé → ponta do pé) usados para achar a frente. */
const PARES_PE = [
  ['foot_l', 'ball_l'],
  ['foot_r', 'ball_r'],
  ['DEF-foot.L', 'DEF-toe.L'],
  ['DEF-foot.R', 'DEF-toe.R'],
];

/** §1: nome do arquivo <id>__v<NN>.glb, id em minúsculas e '-'. */
const PADRAO_NOME = /^[a-z0-9]+(?:-[a-z0-9]+)*__v\d{2}\.glb$/;

// ---------------------------------------------------------------------------------------------
// Utilitários gerais
// ---------------------------------------------------------------------------------------------

const arred = (x, casas = 4) => (Number.isFinite(x) ? Math.round(x * 10 ** casas) / 10 ** casas : null);
const graus = (rad) => (rad * 180) / Math.PI;
const potenciaDe2 = (n) => Number.isInteger(n) && n > 0 && (n & (n - 1)) === 0;
const listaCurta = (arr, max = 12) =>
  arr.length <= max ? arr.join(', ') : `${arr.slice(0, max).join(', ')} … (+${arr.length - max})`;

/** Converte um URL file:// num caminho do sistema (sem node:url, que não está na lista). */
export function caminhoDeUrl(u) {
  let p = decodeURIComponent(new URL(u).pathname);
  if (/^\/[A-Za-z]:\//.test(p)) p = p.slice(1); // Windows: "/C:/..." → "C:/..."
  return path.resolve(p);
}

/** Verdadeiro quando o módulo foi chamado direto pela linha de comando (e não importado). */
export function ehScriptPrincipal(metaUrl) {
  if (!process.argv[1]) return false;
  const a = caminhoDeUrl(metaUrl);
  const b = path.resolve(process.argv[1]);
  return process.platform === 'win32' ? a.toLowerCase() === b.toLowerCase() : a === b;
}

// ---------------------------------------------------------------------------------------------
// Matrizes 4x4 (coluna-maior, como no glTF)
// ---------------------------------------------------------------------------------------------

const IDENTIDADE = Object.freeze([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);

function multiplicar(a, b) {
  const o = new Array(16);
  for (let c = 0; c < 4; c++) {
    for (let r = 0; r < 4; r++) {
      let s = 0;
      for (let k = 0; k < 4; k++) s += a[k * 4 + r] * b[c * 4 + k];
      o[c * 4 + r] = s;
    }
  }
  return o;
}

/** Matriz de translação · rotação (quaternião x,y,z,w) · escala. */
function deTRS(t, q, s) {
  const [x, y, z, w] = q;
  const [sx, sy, sz] = s;
  const xx = x * x, yy = y * y, zz = z * z;
  const xy = x * y, xz = x * z, yz = y * z;
  const wx = w * x, wy = w * y, wz = w * z;
  return [
    (1 - 2 * (yy + zz)) * sx, 2 * (xy + wz) * sx, 2 * (xz - wy) * sx, 0,
    2 * (xy - wz) * sy, (1 - 2 * (xx + zz)) * sy, 2 * (yz + wx) * sy, 0,
    2 * (xz + wy) * sz, 2 * (yz - wx) * sz, (1 - 2 * (xx + yy)) * sz, 0,
    t[0], t[1], t[2], 1,
  ];
}

function aplicarPonto(m, p) {
  const [x, y, z] = p;
  return [
    m[0] * x + m[4] * y + m[8] * z + m[12],
    m[1] * x + m[5] * y + m[9] * z + m[13],
    m[2] * x + m[6] * y + m[10] * z + m[14],
  ];
}

function matrizLocal(no) {
  if (Array.isArray(no.matrix) && no.matrix.length === 16) return no.matrix.slice();
  return deTRS(no.translation || [0, 0, 0], no.rotation || [0, 0, 0, 1], no.scale || [1, 1, 1]);
}

// ---------------------------------------------------------------------------------------------
// Leitura do GLB (V01)
// ---------------------------------------------------------------------------------------------

const MAGIA_GLTF = 0x46546c67; // "glTF"
const CHUNK_JSON = 0x4e4f534a; // "JSON"
const CHUNK_BIN = 0x004e4942; // "BIN\0"

/**
 * Lê o contêiner GLB v2: cabeçalho de 12 bytes, chunk JSON e chunk BIN opcional.
 * Lança Error com mensagem em português quando o arquivo é inválido.
 */
export function lerGlb(buffer) {
  const buf = Buffer.isBuffer(buffer) ? buffer : Buffer.from(buffer);
  if (buf.length < 20) throw new Error(`arquivo curto demais (${buf.length} bytes) para um GLB`);
  if (buf.readUInt32LE(0) !== MAGIA_GLTF) throw new Error('assinatura "glTF" ausente: não é um GLB');
  const versao = buf.readUInt32LE(4);
  if (versao !== 2) throw new Error(`versão do contêiner GLB = ${versao} (esperado 2)`);
  const total = buf.readUInt32LE(8);
  if (total !== buf.length) throw new Error(`comprimento declarado no cabeçalho (${total}) ≠ tamanho real (${buf.length})`);

  let p = 12;
  const lenJson = buf.readUInt32LE(p);
  const tipoJson = buf.readUInt32LE(p + 4);
  if (tipoJson !== CHUNK_JSON) throw new Error('o primeiro chunk não é JSON');
  if (p + 8 + lenJson > total) throw new Error('o chunk JSON ultrapassa o fim do arquivo');
  // O contrato do glTF manda preencher com espaços; aceita-se também \0 no fim, por tolerância.
  const textoJson = buf.subarray(p + 8, p + 8 + lenJson).toString('utf8').replace(/[\u0000\s]+$/, '');
  p += 8 + lenJson;

  let bin = null;
  while (p + 8 <= total) {
    const len = buf.readUInt32LE(p);
    const tipo = buf.readUInt32LE(p + 4);
    if (p + 8 + len > total) throw new Error(`chunk no byte ${p} ultrapassa o fim do arquivo`);
    if (tipo === CHUNK_BIN) {
      if (bin) throw new Error('mais de um chunk BIN');
      bin = buf.subarray(p + 8, p + 8 + len);
    }
    p += 8 + len; // chunks desconhecidos são ignorados, como manda o glTF
  }

  let json;
  try {
    json = JSON.parse(textoJson);
  } catch (e) {
    throw new Error(`JSON inválido: ${e.message}`);
  }
  if (!json || typeof json !== 'object' || Array.isArray(json)) throw new Error('o JSON do glTF não é um objeto');
  if (!json.asset || typeof json.asset.version !== 'string' || !json.asset.version.startsWith('2.')) {
    throw new Error('asset.version ausente ou diferente de 2.x');
  }
  return { json, bin };
}

// ---------------------------------------------------------------------------------------------
// Contexto: acesso aos buffers, accessors, nós e primitivas
// ---------------------------------------------------------------------------------------------

function criarContexto(glb, opcoes) {
  const nos = glb.json.nodes || [];
  const pai = new Array(nos.length);
  nos.forEach((no, i) => {
    for (const c of (no && no.children) || []) pai[c] = i;
  });
  return {
    json: glb.json,
    bin: glb.bin,
    nomeArquivo: opcoes.nomeArquivo || null,
    ossosUal1: opcoes.ossosUal1 || null,
    pai,
    buffers: [],
    cacheAcessores: new Map(),
    mundo: new Map(),
    prims: null,
  };
}

function extrasAsset(ctx) {
  const ex = ctx.json.asset && ctx.json.asset.extras;
  return ex && typeof ex === 'object' ? ex : {};
}

function normalizarPapel(p) {
  if (typeof p !== 'string') return null;
  const s = p.trim().toLowerCase();
  return SINONIMOS_PAPEL[s] || s;
}

function dadosDoBuffer(ctx, i) {
  if (ctx.buffers[i]) return ctx.buffers[i];
  const b = ctx.json.buffers && ctx.json.buffers[i];
  if (!b) throw new Error(`buffer #${i} não existe`);
  let dados;
  if (b.uri === undefined) {
    if (i !== 0 || !ctx.bin) throw new Error(`buffer #${i} sem uri e sem chunk BIN`);
    dados = ctx.bin;
  } else if (typeof b.uri === 'string' && b.uri.startsWith('data:')) {
    const virgula = b.uri.indexOf(',');
    if (virgula < 0 || !b.uri.slice(0, virgula).endsWith(';base64')) throw new Error(`buffer #${i}: data URI não é base64`);
    dados = Buffer.from(b.uri.slice(virgula + 1), 'base64');
  } else {
    throw new Error(`buffer #${i} aponta para arquivo externo (${b.uri}); o GLB tem de ser autocontido`);
  }
  if (dados.length < (b.byteLength || 0)) throw new Error(`buffer #${i}: byteLength ${b.byteLength} > dados disponíveis ${dados.length}`);
  ctx.buffers[i] = dados;
  return dados;
}

function fatiaBufferView(ctx, i) {
  const bv = ctx.json.bufferViews && ctx.json.bufferViews[i];
  if (!bv) throw new Error(`bufferView #${i} não existe`);
  const buf = dadosDoBuffer(ctx, bv.buffer);
  const ini = bv.byteOffset || 0;
  const fim = ini + bv.byteLength;
  if (!Number.isInteger(fim) || fim > buf.length) throw new Error(`bufferView #${i} ultrapassa o buffer #${bv.buffer}`);
  return { dados: buf.subarray(ini, fim), stride: bv.byteStride };
}

const BYTES_COMPONENTE = { 5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4 };
const COMPONENTES = { SCALAR: 1, VEC2: 2, VEC3: 3, VEC4: 4, MAT2: 4, MAT3: 9, MAT4: 16 };
const MAX_INTEIRO = { 5120: 127, 5121: 255, 5122: 32767, 5123: 65535 };

function lerComponente(buf, off, tipo) {
  switch (tipo) {
    case 5120: return buf.readInt8(off);
    case 5121: return buf.readUInt8(off);
    case 5122: return buf.readInt16LE(off);
    case 5123: return buf.readUInt16LE(off);
    case 5125: return buf.readUInt32LE(off);
    case 5126: return buf.readFloatLE(off);
    default: throw new Error(`componentType desconhecido: ${tipo}`);
  }
}

function normalizarInteiro(v, tipo) {
  const m = MAX_INTEIRO[tipo];
  if (!m) return v;
  return tipo === 5120 || tipo === 5122 ? Math.max(v / m, -1) : v / m;
}

/**
 * Lê um accessor inteiro para um Float64Array (count * componentes).
 * Trata byteStride, byteOffset, normalized e sparse. (MAT2/MAT3 com componentes de 1–2 bytes têm
 * preenchimento de coluna no glTF; não são usados nas verificações e não são tratados aqui.)
 */
export function lerAcessor(ctx, indice, opcoes = {}) {
  const chave = `${indice}|${opcoes.normalizar ? 1 : 0}`;
  if (ctx.cacheAcessores.has(chave)) return ctx.cacheAcessores.get(chave);
  const acc = ctx.json.accessors && ctx.json.accessors[indice];
  if (!acc) throw new Error(`accessor #${indice} não existe`);
  const n = COMPONENTES[acc.type];
  const tb = BYTES_COMPONENTE[acc.componentType];
  if (!n || !tb) throw new Error(`accessor #${indice}: tipo inválido (${acc.type}/${acc.componentType})`);
  const count = acc.count;
  if (!Number.isInteger(count) || count < 0) throw new Error(`accessor #${indice}: count inválido`);
  const normalizar = Boolean(acc.normalized || opcoes.normalizar) && MAX_INTEIRO[acc.componentType] !== undefined;
  const valores = new Float64Array(count * n);

  if (acc.bufferView !== undefined) {
    const { dados, stride } = fatiaBufferView(ctx, acc.bufferView);
    const tamElemento = n * tb;
    const passo = stride || tamElemento;
    const base = acc.byteOffset || 0;
    if (count > 0 && base + (count - 1) * passo + tamElemento > dados.length) {
      throw new Error(`accessor #${indice} ultrapassa o bufferView #${acc.bufferView}`);
    }
    for (let i = 0; i < count; i++) {
      const o = base + i * passo;
      for (let c = 0; c < n; c++) {
        const v = lerComponente(dados, o + c * tb, acc.componentType);
        valores[i * n + c] = normalizar ? normalizarInteiro(v, acc.componentType) : v;
      }
    }
  }

  if (acc.sparse) {
    const sp = acc.sparse;
    const di = fatiaBufferView(ctx, sp.indices.bufferView).dados;
    const dv = fatiaBufferView(ctx, sp.values.bufferView).dados;
    const tbi = BYTES_COMPONENTE[sp.indices.componentType];
    for (let s = 0; s < sp.count; s++) {
      const alvo = lerComponente(di, (sp.indices.byteOffset || 0) + s * tbi, sp.indices.componentType);
      if (alvo >= count) throw new Error(`accessor #${indice}: índice sparse ${alvo} fora do count`);
      for (let c = 0; c < n; c++) {
        const v = lerComponente(dv, (sp.values.byteOffset || 0) + (s * n + c) * tb, acc.componentType);
        valores[alvo * n + c] = normalizar ? normalizarInteiro(v, acc.componentType) : v;
      }
    }
  }

  const r = { valores, n, count, acc };
  ctx.cacheAcessores.set(chave, r);
  return r;
}

/** min/max de um accessor VEC3 (do JSON quando existe; senão, lido do BIN). */
function minMaxAcessor(ctx, indice) {
  const acc = ctx.json.accessors && ctx.json.accessors[indice];
  if (!acc) throw new Error(`accessor #${indice} não existe`);
  if (Array.isArray(acc.min) && Array.isArray(acc.max) && acc.min.length >= 3 && acc.max.length >= 3 && !acc.sparse) {
    return [acc.min.slice(0, 3), acc.max.slice(0, 3)];
  }
  const { valores, n, count } = lerAcessor(ctx, indice);
  const mn = [Infinity, Infinity, Infinity];
  const mx = [-Infinity, -Infinity, -Infinity];
  for (let i = 0; i < count; i++) {
    for (let c = 0; c < 3; c++) {
      const v = valores[i * n + c];
      if (v < mn[c]) mn[c] = v;
      if (v > mx[c]) mx[c] = v;
    }
  }
  return [mn, mx];
}

function cenaRaizes(ctx) {
  const j = ctx.json;
  const cenas = j.scenes || [];
  const ci = j.scene !== undefined ? j.scene : 0;
  if (cenas[ci] && Array.isArray(cenas[ci].nodes)) return cenas[ci].nodes;
  // Sem cena: usa os nós que não são filhos de ninguém.
  return (j.nodes || []).map((_, i) => i).filter((i) => ctx.pai[i] === undefined);
}

function matrizMundo(ctx, i) {
  if (ctx.mundo.has(i)) return ctx.mundo.get(i);
  const cadeia = [];
  const vistos = new Set();
  for (let k = i; k !== undefined; k = ctx.pai[k]) {
    if (vistos.has(k)) throw new Error('ciclo na hierarquia de nós');
    vistos.add(k);
    cadeia.push(k);
  }
  let m = IDENTIDADE;
  for (let c = cadeia.length - 1; c >= 0; c--) {
    const no = ctx.json.nodes[cadeia[c]];
    if (!no) throw new Error(`nó #${cadeia[c]} não existe`);
    m = multiplicar(m, matrizLocal(no));
  }
  ctx.mundo.set(i, m);
  return m;
}

const posicaoMundo = (ctx, i) => {
  const m = matrizMundo(ctx, i);
  return [m[12], m[13], m[14]];
};

/**
 * Todas as primitivas de malha alcançáveis pela cena, com o nó, a malha e o anexo.
 * "Corpo" = primitiva sem extras.anexo (no nó, na malha ou na própria primitiva).
 */
function primitivasDe(ctx) {
  if (ctx.prims) return ctx.prims;
  const nos = ctx.json.nodes || [];
  const malhas = ctx.json.meshes || [];
  const lista = [];
  const visitados = new Set();
  const pilha = [...cenaRaizes(ctx)].reverse();
  while (pilha.length) {
    const i = pilha.pop();
    if (visitados.has(i)) continue;
    visitados.add(i);
    const no = nos[i];
    if (!no) throw new Error(`nó #${i} não existe`);
    if (no.mesh !== undefined) {
      const malha = malhas[no.mesh];
      if (!malha) throw new Error(`malha #${no.mesh} não existe`);
      const anexoNo = (no.extras && no.extras.anexo) ?? (malha.extras && malha.extras.anexo);
      (malha.primitives || []).forEach((prim, k) => {
        const anexo = anexoNo ?? (prim.extras && prim.extras.anexo);
        lista.push({
          indiceNo: i,
          no,
          indiceMalha: no.mesh,
          malha,
          indicePrim: k,
          prim,
          anexo,
          anexoNo,
          ehCorpo: anexo === undefined,
          skinned: no.skin !== undefined,
        });
      });
    }
    for (const c of [...(no.children || [])].reverse()) pilha.push(c);
  }
  ctx.prims = lista;
  return lista;
}

const rotulo = (p) => `nó "${p.no.name ?? '#' + p.indiceNo}" (malha ${p.indiceMalha}, primitiva ${p.indicePrim})`;

/** Ossos (nós de skins[*].joints): lista [{indiceNo, nome}] sem repetição. */
function ossosDoArquivo(ctx) {
  const vistos = new Set();
  const lista = [];
  for (const skin of ctx.json.skins || []) {
    for (const j of skin.joints || []) {
      if (vistos.has(j)) continue;
      vistos.add(j);
      const no = ctx.json.nodes && ctx.json.nodes[j];
      lista.push({ indiceNo: j, nome: (no && no.name) || `#${j}` });
    }
  }
  return lista;
}

const ossosPorNome = (ctx) => new Map(ossosDoArquivo(ctx).map((o) => [o.nome, o.indiceNo]));

const ehOssoProibido = (nome) => /^mixamorig/i.test(nome) || nome.startsWith('ORG-') || nome.startsWith('MCH-');

function tipoEsqueleto(ctx, nomes) {
  const ex = extrasAsset(ctx);
  if (ex.esqueleto === 'ual1' || ex.esqueleto === 'rigify') return ex.esqueleto;
  if (normalizarPapel(ex.papel) === 'quadrupede') return 'rigify';
  return nomes.some((n) => n.startsWith('DEF-')) ? 'rigify' : 'ual1';
}

/**
 * Lê JOINTS_n/WEIGHTS_n de uma primitiva. Os pesos inteiros são sempre normalizados.
 * Devolve [{j, w}] (um por conjunto de 4 influências).
 */
function lerInfluencias(ctx, prim) {
  const at = prim.attributes || {};
  const conjuntos = [];
  for (let k = 0; at[`JOINTS_${k}`] !== undefined || at[`WEIGHTS_${k}`] !== undefined; k++) {
    if (at[`JOINTS_${k}`] === undefined || at[`WEIGHTS_${k}`] === undefined) {
      throw new Error(`JOINTS_${k} e WEIGHTS_${k} têm de vir em par`);
    }
    const j = lerAcessor(ctx, at[`JOINTS_${k}`]);
    const w = lerAcessor(ctx, at[`WEIGHTS_${k}`], { normalizar: true });
    if (j.n !== 4 || w.n !== 4) throw new Error(`JOINTS_${k}/WEIGHTS_${k} têm de ser VEC4`);
    if (j.count !== w.count) throw new Error(`JOINTS_${k} e WEIGHTS_${k} com contagens diferentes`);
    conjuntos.push({ j, w });
  }
  return conjuntos;
}

/** Osso dominante (maior peso) de cada vértice. */
function dominantes(conjuntos, count) {
  const indice = new Int32Array(count).fill(-1);
  const peso = new Float64Array(count);
  for (let v = 0; v < count; v++) {
    for (const { j, w } of conjuntos) {
      for (let c = 0; c < 4; c++) {
        const wv = w.valores[v * 4 + c];
        if (wv > peso[v]) {
          peso[v] = wv;
          indice[v] = j.valores[v * 4 + c];
        }
      }
    }
  }
  return { indice, peso };
}

// ---------------------------------------------------------------------------------------------
// Dimensões de imagens (V09) — lidas do cabeçalho, sem descomprimir
// ---------------------------------------------------------------------------------------------

const ASSINATURA_PNG = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

/** PNG: largura/altura do IHDR; alfa pelo tipo de cor (4 ou 6) ou por um chunk tRNS. */
export function dimensoesPng(b) {
  if (!b || b.length < 33) return null;
  for (let i = 0; i < 8; i++) if (b[i] !== ASSINATURA_PNG[i]) return null;
  if (b.toString('ascii', 12, 16) !== 'IHDR') return null;
  const largura = b.readUInt32BE(16);
  const altura = b.readUInt32BE(20);
  const tipoCor = b[25];
  let alfa = tipoCor === 4 || tipoCor === 6;
  let p = 8;
  while (!alfa && p + 8 <= b.length) {
    const len = b.readUInt32BE(p);
    const tipo = b.toString('ascii', p + 4, p + 8);
    if (tipo === 'tRNS') alfa = true;
    if (tipo === 'IDAT' || tipo === 'IEND') break;
    p += 12 + len;
  }
  return { formato: 'png', largura, altura, alfa };
}

/** JPEG: percorre os marcadores até um SOF (C0–CF, menos C4, C8 e CC) e lê altura e largura. */
export function dimensoesJpeg(b) {
  if (!b || b.length < 4 || b[0] !== 0xff || b[1] !== 0xd8) return null;
  let p = 2;
  while (p + 3 < b.length) {
    if (b[p] !== 0xff) {
      p++;
      continue;
    }
    const m = b[p + 1];
    if (m === 0xff) {
      p++; // byte de preenchimento
      continue;
    }
    if (m === 0xd8 || m === 0x01 || (m >= 0xd0 && m <= 0xd7)) {
      p += 2; // marcadores sem comprimento
      continue;
    }
    if (m === 0xd9 || m === 0xda) break; // EOI ou início do scan: não há SOF antes
    const len = b.readUInt16BE(p + 2);
    if (m >= 0xc0 && m <= 0xcf && m !== 0xc4 && m !== 0xc8 && m !== 0xcc) {
      if (p + 9 > b.length) return null;
      return { formato: 'jpeg', altura: b.readUInt16BE(p + 5), largura: b.readUInt16BE(p + 7), alfa: false };
    }
    p += 2 + len;
  }
  return null;
}

function bytesImagem(ctx, img) {
  if (img.bufferView !== undefined) return fatiaBufferView(ctx, img.bufferView).dados;
  if (typeof img.uri === 'string' && img.uri.startsWith('data:')) {
    const virgula = img.uri.indexOf(',');
    if (virgula < 0 || !img.uri.slice(0, virgula).endsWith(';base64')) throw new Error('data URI de imagem não é base64');
    return Buffer.from(img.uri.slice(virgula + 1), 'base64');
  }
  throw new Error(img.uri ? `imagem externa (${img.uri}): o GLB tem de embutir as texturas` : 'imagem sem bufferView nem uri');
}

// ---------------------------------------------------------------------------------------------
// Relatório
// ---------------------------------------------------------------------------------------------

const CODIGOS = Array.from({ length: 18 }, (_, i) => `V${String(i + 1).padStart(2, '0')}`);

class Relatorio {
  constructor() {
    this.falhas = [];
    this.avisos = [];
    this.medidas = {};
    this.naoAplicavel = new Set();
  }
  falha(codigo, mensagem) {
    this.falhas.push({ codigo, mensagem });
  }
  aviso(codigo, mensagem) {
    this.avisos.push({ codigo, mensagem });
  }
  na(codigo) {
    this.naoAplicavel.add(codigo);
  }
  /** Estado de cada verificação: ok | aviso | falha | nao_aplicavel | nao_executada. */
  resumo(executou) {
    const r = {};
    for (const c of CODIGOS) {
      if (this.falhas.some((f) => f.codigo === c)) r[c] = 'falha';
      else if (!executou && c !== 'V01' && c !== 'V18') r[c] = 'nao_executada';
      else if (this.avisos.some((a) => a.codigo === c)) r[c] = 'aviso';
      else if (this.naoAplicavel.has(c)) r[c] = 'nao_aplicavel';
      else r[c] = 'ok';
    }
    return r;
  }
}

// ---------------------------------------------------------------------------------------------
// As verificações V02–V17 (V01 é a leitura; V18 é o SHA-256)
// ---------------------------------------------------------------------------------------------

/** V01 (complemento): o GLB tem de ser autocontido. */
function v01Autocontido(ctx, rel) {
  (ctx.json.buffers || []).forEach((b, i) => {
    if (b.uri !== undefined && !(typeof b.uri === 'string' && b.uri.startsWith('data:'))) {
      rel.falha('V01', `buffer #${i} aponta para arquivo externo (${b.uri}); o GLB tem de ser autocontido`);
    }
  });
  if ((ctx.json.buffers || []).length && ctx.json.buffers[0].uri === undefined && !ctx.bin) {
    rel.falha('V01', 'buffer #0 sem uri e sem chunk BIN');
  }
}

/** V02: extensionsRequired só com as do §1; nada de Draco nem meshopt. */
function v02(ctx, rel) {
  const req = ctx.json.extensionsRequired || [];
  const usadas = ctx.json.extensionsUsed || [];
  for (const e of req) {
    if (!EXTENSOES_PERMITIDAS.has(e)) rel.falha('V02', `extensão obrigatória fora da lista do §1: ${e}`);
  }
  for (const e of usadas) {
    if (EXTENSOES_PROIBIDAS.has(e)) {
      if (!req.includes(e)) rel.falha('V02', `compressão proibida na v1: ${e}`);
    } else if (!EXTENSOES_PERMITIDAS.has(e)) {
      rel.aviso('V02', `extensão usada fora da lista do §1 (opcional; o jogo pode ignorá-la): ${e}`);
    }
  }
  rel.medidas.extensoes = { obrigatorias: req, usadas };
}

/** V03: asset.extras.contrato e asset.extras.origem; nome do arquivo (aviso). */
function v03(ctx, rel) {
  const ex = extrasAsset(ctx);
  if (ex.contrato !== CONTRATO) {
    rel.falha('V03', ex.contrato === undefined
      ? `asset.extras.contrato ausente (esperado "${CONTRATO}")`
      : `asset.extras.contrato = "${ex.contrato}" (esperado "${CONTRATO}")`);
  }
  const o = ex.origem;
  if (!o || typeof o !== 'object') {
    rel.falha('V03', 'asset.extras.origem ausente (esperado {rota, referenciaSha, oficinaJob, data})');
  } else {
    for (const campo of ['rota', 'referenciaSha', 'oficinaJob', 'data']) {
      if (o[campo] === undefined || o[campo] === null || o[campo] === '') rel.falha('V03', `asset.extras.origem.${campo} ausente`);
    }
    if (typeof o.referenciaSha === 'string' && !/^[0-9a-f]{64}$/i.test(o.referenciaSha)) {
      rel.aviso('V03', 'asset.extras.origem.referenciaSha não parece um SHA-256 (64 hexadecimais)');
    }
  }
  if (ctx.nomeArquivo) {
    const base = path.basename(ctx.nomeArquivo);
    if (!PADRAO_NOME.test(base)) rel.aviso('V03', `nome do arquivo "${base}" fora do padrão <id>__v<NN>.glb (§1)`);
  }
}

/** Caixa do corpo (sem peças com extras.anexo), no espaço do mundo, a partir de accessor.min/max. */
function caixaCorpo(ctx) {
  if (ctx.caixa !== undefined) return ctx.caixa;
  const mn = [Infinity, Infinity, Infinity];
  const mx = [-Infinity, -Infinity, -Infinity];
  let algum = false;
  for (const p of primitivasDe(ctx)) {
    if (!p.ehCorpo) continue;
    const ia = p.prim.attributes && p.prim.attributes.POSITION;
    if (ia === undefined) continue;
    const [a, b] = minMaxAcessor(ctx, ia);
    // Malha com skin: o glTF manda IGNORAR a transformação do nó da malha (só contam os ossos);
    // na pose de descanso as posições do POSITION já são as do mundo. Sem skin: matriz do nó.
    const m = p.skinned ? null : matrizMundo(ctx, p.indiceNo);
    for (let k = 0; k < 8; k++) {
      const canto = [k & 1 ? b[0] : a[0], k & 2 ? b[1] : a[1], k & 4 ? b[2] : a[2]];
      const q = m ? aplicarPonto(m, canto) : canto;
      for (let c = 0; c < 3; c++) {
        if (q[c] < mn[c]) mn[c] = q[c];
        if (q[c] > mx[c]) mx[c] = q[c];
      }
    }
    algum = true;
  }
  ctx.caixa = algum ? { min: mn, max: mx } : null;
  return ctx.caixa;
}

/** V04: altura da caixa contra extras.alturaM (±2%). */
function v04(ctx, rel) {
  const ex = extrasAsset(ctx);
  const caixa = caixaCorpo(ctx);
  if (!caixa) {
    rel.falha('V04', 'não há malha de corpo com POSITION para medir a altura');
    return;
  }
  const altura = caixa.max[1] - caixa.min[1];
  rel.medidas.alturaM = arred(altura);
  rel.medidas.caixa = { min: caixa.min.map((v) => arred(v)), max: caixa.max.map((v) => arred(v)) };
  const decl = ex.alturaM;
  if (typeof decl !== 'number' || !(decl > 0)) {
    const msg = 'asset.extras.alturaM ausente ou inválida';
    if (normalizarPapel(ex.papel) === 'objeto') rel.aviso('V04', msg);
    else rel.falha('V04', msg);
    return;
  }
  rel.medidas.alturaDeclaradaM = decl;
  const desvio = Math.abs(altura - decl) / decl;
  rel.medidas.alturaDesvioPct = arred(desvio * 100, 3);
  if (desvio > TOL.alturaRelativa) {
    const razao = altura / decl;
    let dica = '';
    if (razao > 50 && razao < 200) dica = ' — parece escala ×100 (centímetros em vez de metros)';
    else if (razao > 0.005 && razao < 0.02) dica = ' — parece escala ×0,01';
    rel.falha('V04', `altura ${altura.toFixed(4)} m fora de ±2% de extras.alturaM = ${decl} m (desvio ${(desvio * 100).toFixed(2)}%)${dica}`);
  }
}

/** V05: pivô no chão entre os pés (|Ymin| <= 1 cm; centro XZ a <= 5 cm da origem). */
function v05(ctx, rel) {
  const caixa = caixaCorpo(ctx);
  if (!caixa) {
    rel.falha('V05', 'não há malha de corpo com POSITION para medir o pivô');
    return;
  }
  const yMin = caixa.min[1];
  const cx = (caixa.min[0] + caixa.max[0]) / 2;
  const cz = (caixa.min[2] + caixa.max[2]) / 2;
  const dist = Math.hypot(cx, cz);
  rel.medidas.pivo = { yMinM: arred(yMin), centroXZ: [arred(cx), arred(cz)], distanciaCentroM: arred(dist) };
  if (Math.abs(yMin) > TOL.yMin) {
    const dica = yMin < -0.2 ? ' — o pivô parece estar no meio do corpo (umbigo?), e não no chão' : '';
    rel.falha('V05', `Y mínimo da malha = ${yMin.toFixed(4)} m (máximo ±0,01 m)${dica}`);
  }
  if (dist > TOL.centroXZ) {
    rel.falha('V05', `centro XZ a ${dist.toFixed(4)} m da origem (máximo 0,05 m)`);
  }
}

/** V06 (heurística b): média das normais dos vértices dominados pelo osso Head. */
function frentePelaCabeca(ctx) {
  let sx = 0, sz = 0, n = 0;
  for (const p of primitivasDe(ctx)) {
    if (!p.ehCorpo || !p.skinned) continue;
    const at = p.prim.attributes || {};
    if (at.NORMAL === undefined) continue;
    const conj = lerInfluencias(ctx, p.prim);
    if (!conj.length) continue;
    const nor = lerAcessor(ctx, at.NORMAL);
    const dom = dominantes(conj, nor.count);
    const joints = (ctx.json.skins[p.no.skin] || {}).joints || [];
    for (let v = 0; v < nor.count; v++) {
      const ji = dom.indice[v];
      if (ji < 0) continue;
      const no = ctx.json.nodes[joints[ji]];
      if (!no || no.name !== 'Head') continue;
      sx += nor.valores[v * 3];
      sz += nor.valores[v * 3 + 2];
      n++;
    }
  }
  if (!n) return null;
  return { angulo: graus(Math.atan2(sx, sz)), forca: Math.hypot(sx, sz) / n, vertices: n };
}

/**
 * V06: a frente é +Z.
 * Método a (decisivo): vetor pé → ponta do pé (foot → ball) dos dois lados, projetado em XZ.
 * Método b (só aviso): normais da cabeça. Sem osso Head: aviso, como manda o §7.
 */
function v06(ctx, rel) {
  if (!(ctx.json.skins || []).length) {
    rel.aviso('V06', 'sem esqueleto: frente não verificada (objeto)');
    return;
  }
  const ossos = ossosPorNome(ctx);
  const nomes = [...ossos.keys()];
  const tipo = tipoEsqueleto(ctx, nomes);
  const temHead = ossos.has('Head');
  if (!temHead && tipo === 'ual1') rel.aviso('V06', 'não há osso Head: a frente pela cabeça não pode ser conferida');

  let sx = 0, sz = 0, usados = 0;
  for (const [a, b] of PARES_PE) {
    if (!ossos.has(a) || !ossos.has(b)) continue;
    const pa = posicaoMundo(ctx, ossos.get(a));
    const pb = posicaoMundo(ctx, ossos.get(b));
    sx += pb[0] - pa[0];
    sz += pb[2] - pa[2];
    usados++;
  }
  if (usados && Math.hypot(sx, sz) > 1e-6) {
    const ang = graus(Math.atan2(sx, sz));
    rel.medidas.frente = { metodo: 'ossos dos pés (pé → ponta)', pares: usados, desvioGraus: arred(ang, 2) };
    if (Math.abs(ang) > TOL.frenteGraus) {
      const dica = Math.abs(ang) > 135 ? ' — o modelo olha para −Z' : '';
      rel.falha('V06', `frente a ${ang.toFixed(1)}° de +Z (máximo ±5°)${dica}`);
    }
    return;
  }
  if (temHead) {
    const r = frentePelaCabeca(ctx);
    if (!r || r.forca < 0.05) {
      rel.aviso('V06', 'sem ossos dos pés; as normais da cabeça não dão uma direção clara (frente não verificada)');
      return;
    }
    rel.medidas.frente = { metodo: 'normais da cabeça (heurística)', vertices: r.vertices, desvioGraus: arred(r.angulo, 2) };
    rel.aviso('V06', `frente estimada pelas normais da cabeça (heurística): ${r.angulo.toFixed(1)}° de +Z` +
      (Math.abs(r.angulo) > TOL.frenteGraus ? ' — confira à mão' : ''));
    return;
  }
  rel.aviso('V06', 'sem ossos dos pés nem Head reconhecidos: frente não verificada');
}

function problemaDeTransformacao(no) {
  const t = TOL.transformacao;
  const probs = [];
  if (Array.isArray(no.matrix)) {
    const m = no.matrix;
    const diag = [m[0], m[5], m[10]];
    const fora = [m[1], m[2], m[4], m[6], m[8], m[9]];
    if (diag.some((d) => Math.abs(d - 1) > t) || fora.some((f) => Math.abs(f) > t)) probs.push('matrix com rotação ou escala');
  }
  if (Array.isArray(no.scale) && no.scale.some((s) => Math.abs(s - 1) > t)) {
    probs.push(`escala [${no.scale.map((v) => arred(v)).join(', ')}]`);
  }
  if (Array.isArray(no.rotation)) {
    const [x, y, z] = no.rotation;
    if (Math.abs(x) > t || Math.abs(y) > t || Math.abs(z) > t) probs.push(`rotação [${no.rotation.map((v) => arred(v)).join(', ')}]`);
  }
  return probs.length ? probs.join(' e ') : null;
}

/** V07: o nó da malha (e os seus ancestrais) com escala 1 e rotação 0. */
function v07(ctx, rel) {
  const vistos = new Set();
  for (const p of primitivasDe(ctx)) {
    for (let k = p.indiceNo; k !== undefined && !vistos.has(k); k = ctx.pai[k]) {
      vistos.add(k);
      const no = ctx.json.nodes[k];
      const prob = problemaDeTransformacao(no);
      if (prob) {
        const papel = k === p.indiceNo ? 'nó da malha' : 'ancestral do nó da malha';
        rel.falha('V07', `${papel} "${no.name ?? '#' + k}": ${prob}; aplique as transformações (Ctrl+A no Blender)`);
      }
    }
  }
}

function contarDegeneradas(ctx, prim) {
  const pos = lerAcessor(ctx, prim.attributes.POSITION);
  const idx = prim.indices !== undefined ? lerAcessor(ctx, prim.indices).valores : null;
  const n = idx ? idx.length : pos.count;
  const P = pos.valores;
  let deg = 0;
  for (let t = 0; t + 2 < n; t += 3) {
    const a = idx ? idx[t] : t;
    const b = idx ? idx[t + 1] : t + 1;
    const c = idx ? idx[t + 2] : t + 2;
    if (a >= pos.count || b >= pos.count || c >= pos.count) throw new Error(`índice ${Math.max(a, b, c)} fora do POSITION (${pos.count})`);
    if (a === b || b === c || a === c) {
      deg++;
      continue;
    }
    const ux = P[b * 3] - P[a * 3], uy = P[b * 3 + 1] - P[a * 3 + 1], uz = P[b * 3 + 2] - P[a * 3 + 2];
    const vx = P[c * 3] - P[a * 3], vy = P[c * 3 + 1] - P[a * 3 + 1], vz = P[c * 3 + 2] - P[a * 3 + 2];
    const cx = uy * vz - uz * vy, cy = uz * vx - ux * vz, cz = ux * vy - uy * vx;
    if (cx * cx + cy * cy + cz * cz < 1e-24) deg++;
  }
  return deg;
}

/** V08: triângulos (pelos índices) <= teto do perfil Alto. Normais e faces degeneradas: aviso. */
function v08(ctx, rel) {
  const ex = extrasAsset(ctx);
  const tipo = ex.tipo === 'criatura_grande' ? 'criatura_grande' : 'personagem';
  const teto = TETO_TRIANGULOS[tipo];
  let tri = 0;
  let degeneradas = 0;
  for (const p of primitivasDe(ctx)) {
    const at = p.prim.attributes || {};
    const modo = p.prim.mode !== undefined ? p.prim.mode : 4;
    let n;
    if (p.prim.indices !== undefined) n = ctx.json.accessors[p.prim.indices].count;
    else if (at.POSITION !== undefined) n = ctx.json.accessors[at.POSITION].count;
    else n = 0;
    if (modo === 4) tri += Math.floor(n / 3);
    else if (modo === 5 || modo === 6) tri += Math.max(0, n - 2);
    else rel.aviso('V08', `${rotulo(p)}: modo ${modo} (pontos ou linhas), não conta como triângulos`);
    if (at.NORMAL === undefined) rel.aviso('V08', `${rotulo(p)}: sem NORMAL (o §3 pede normais presentes)`);
    if (modo === 4 && at.POSITION !== undefined) degeneradas += contarDegeneradas(ctx, p.prim);
  }
  rel.medidas.triangulos = tri;
  rel.medidas.tetoTriangulos = { tipo, perfil: 'Alto', teto };
  if (degeneradas) rel.aviso('V08', `${degeneradas} face(s) degenerada(s) (área nula ou índice repetido)`);
  if (tri > teto) rel.falha('V08', `${tri} triângulos acima do teto do perfil Alto para ${tipo} (${teto})`);
}

/** V09: texturas PNG ou JPEG, quadradas, potência de 2, <= 2048. */
function v09(ctx, rel) {
  const imagens = ctx.json.images || [];
  const materiais = ctx.json.materials || [];
  const fonteDaTextura = (ti) => {
    const t = ctx.json.textures && ctx.json.textures[ti];
    return t ? t.source : undefined;
  };
  // imagem → pode ter alfa? (só albedo de material com alphaMode MASK)
  const albedos = new Map();
  for (const m of materiais) {
    const bt = m.pbrMetallicRoughness && m.pbrMetallicRoughness.baseColorTexture;
    if (!bt) continue;
    const im = fonteDaTextura(bt.index);
    if (im === undefined) continue;
    albedos.set(im, Boolean(albedos.get(im)) || m.alphaMode === 'MASK');
  }
  const medidas = [];
  imagens.forEach((img, i) => {
    const nome = img.name ? `imagem #${i} "${img.name}"` : `imagem #${i}`;
    let bytes;
    try {
      bytes = bytesImagem(ctx, img);
    } catch (e) {
      rel.falha('V09', `${nome}: ${e.message}`);
      return;
    }
    const dims = dimensoesPng(bytes) || dimensoesJpeg(bytes);
    if (!dims) {
      rel.falha('V09', `${nome}: formato não reconhecido (só PNG ou JPEG)${img.mimeType ? `; mimeType ${img.mimeType}` : ''}`);
      return;
    }
    const { largura: w, altura: h } = dims;
    medidas.push({ indice: i, formato: dims.formato, largura: w, altura: h, alfa: dims.alfa });
    if (w !== h) rel.falha('V09', `${nome}: ${w}×${h} não é quadrada`);
    if (!potenciaDe2(w) || !potenciaDe2(h)) rel.falha('V09', `${nome}: ${w}×${h} não é potência de 2`);
    if (Math.max(w, h) > TEXTURA_MAX) rel.falha('V09', `${nome}: ${w}×${h} acima de ${TEXTURA_MAX}`);
    else if (Math.max(w, h) < TEXTURA_MIN_ESPERADA) rel.aviso('V09', `${nome}: ${w}×${h} abaixo de ${TEXTURA_MIN_ESPERADA} (o §3 pede 1024 ou 2048)`);
    if (dims.alfa && albedos.has(i) && !albedos.get(i)) {
      rel.aviso('V09', `${nome}: albedo com canal alfa num material sem alphaMode MASK (o §3 só permite alfa em cabelo e folhagem)`);
    }
  });
  rel.medidas.texturas = medidas;
}

/** V10: material pbrMetallicRoughness com albedo pintado, metal <= 0,1, rugosidade >= 0,7. */
function v10(ctx, rel) {
  const marcar = (msg) => (V10_REPROVA ? rel.falha('V10', msg) : rel.aviso('V10', msg));
  (ctx.json.materials || []).forEach((m, i) => {
    const nome = `material "${m.name ?? '#' + i}"`;
    const pbr = m.pbrMetallicRoughness;
    if (!pbr) {
      marcar(`${nome}: sem pbrMetallicRoughness`);
      return;
    }
    if (!pbr.baseColorTexture) marcar(`${nome}: sem baseColorTexture (o §3 pede albedo pintado)`);
    const metal = pbr.metallicFactor !== undefined ? pbr.metallicFactor : 1; // padrão do glTF = 1
    const rug = pbr.roughnessFactor !== undefined ? pbr.roughnessFactor : 1;
    if (metal > 0.1) marcar(`${nome}: metallicFactor ${metal} > 0,1`);
    if (rug < 0.7) marcar(`${nome}: roughnessFactor ${rug} < 0,7`);
    if (m.occlusionTexture) rel.aviso('V10', `${nome}: occlusionTexture presente (o §3 evita luz cozida forte)`);
    if (m.alphaMode === 'BLEND') rel.aviso('V10', `${nome}: alphaMode BLEND (o §3 pede MASK)`);
  });
}

/** V11: ossos obrigatórios do UAL1, ou só DEF-* no Rigify; nada de mixamorig, ORG-, MCH-. */
function v11(ctx, rel) {
  const ex = extrasAsset(ctx);
  const papel = normalizarPapel(ex.papel);
  if (!(ctx.json.skins || []).length) {
    if (papel && PAPEIS[papel] && PAPEIS[papel].esqueleto) rel.falha('V11', `papel "${papel}" exige esqueleto, e o GLB não tem skins`);
    else rel.na('V11');
    return;
  }
  const ossos = ossosDoArquivo(ctx);
  const nomes = ossos.map((o) => o.nome);
  const conjunto = new Set(nomes);
  const tipo = tipoEsqueleto(ctx, nomes);
  rel.medidas.esqueleto = { tipo, ossos: nomes.length };

  const mixamo = nomes.filter((n) => /^mixamorig/i.test(n));
  const orgMch = nomes.filter((n) => n.startsWith('ORG-') || n.startsWith('MCH-'));
  if (mixamo.length) rel.falha('V11', `${mixamo.length} osso(s) mixamorig:* (o Mixamo só entra por retarget, O7.1b): ${listaCurta(mixamo, 6)}`);
  if (orgMch.length) rel.falha('V11', `${orgMch.length} osso(s) ORG-/MCH- (só DEF-* vão para o jogo): ${listaCurta(orgMch, 6)}`);

  if (tipo === 'ual1') {
    const faltam = OSSOS_OBRIGATORIOS_UAL1.filter((o) => !conjunto.has(o));
    if (faltam.length) rel.falha('V11', `faltam ossos obrigatórios do UAL1 (§5.1): ${faltam.join(', ')}`);
  } else {
    if (!conjunto.has('root')) rel.falha('V11', 'Rigify: falta o osso "root" no topo');
    const controle = nomes.filter((n) => !n.startsWith('DEF-') && n !== 'root' && !n.startsWith('x_') && !ehOssoProibido(n));
    if (controle.length) rel.falha('V11', `Rigify: ossos que não são DEF-* (controle?): ${listaCurta(controle, 8)}`);
  }
}

/** V12: ossos fora do esqueleto base só com o prefixo x_, filhos (diretos ou em cadeia x_) de um osso base. */
function v12(ctx, rel) {
  if (!(ctx.json.skins || []).length) {
    rel.na('V12');
    return;
  }
  const ossos = ossosDoArquivo(ctx);
  const nomes = ossos.map((o) => o.nome);
  const tipo = tipoEsqueleto(ctx, nomes);
  const completa = ctx.ossosUal1 && Array.isArray(ctx.ossosUal1.completa) ? ctx.ossosUal1.completa : null;

  if (tipo === 'ual1') {
    if (!completa) {
      rel.aviso('V12', 'lista completa dos ossos do UAL1 (ossos-ual1.json) não carregada: só os obrigatórios contam como base');
    } else if (!(ctx.ossosUal1.fonte && ctx.ossosUal1.fonte.sha256)) {
      rel.aviso('V12', 'ossos-ual1.json sem SHA-256 do UAL1_Standard.glb confirmado (regenere com --extrair-ossos-ual1)');
    }
  }
  const base = new Set(tipo === 'ual1' ? (completa || OSSOS_OBRIGATORIOS_UAL1) : []);
  const ehBase = (nome) => (tipo === 'ual1' ? base.has(nome) : nome.startsWith('DEF-') || nome === 'root');

  const fora = [];
  let extras = 0;
  for (const { indiceNo, nome } of ossos) {
    if (ehOssoProibido(nome)) continue; // já reprovado na V11
    if (ehBase(nome)) continue;
    if (nome.startsWith('x_')) {
      extras++;
      let p = ctx.pai[indiceNo];
      while (p !== undefined && ((ctx.json.nodes[p] || {}).name || '').startsWith('x_')) p = ctx.pai[p];
      const nomePai = p !== undefined ? (ctx.json.nodes[p] || {}).name : undefined;
      if (!nomePai || !ehBase(nomePai)) {
        rel.falha('V12', `osso extra "${nome}" não descende de um osso do esqueleto base (pai: ${nomePai ?? 'nenhum'})`);
      }
      continue;
    }
    if (tipo === 'rigify') continue; // já reprovado na V11 como osso de controle
    fora.push(nome);
  }
  if (fora.length) rel.falha('V12', `ossos fora da lista do UAL1 sem prefixo x_: ${listaCurta(fora, 10)}`);
  rel.medidas.ossosExtras = extras;

  if (tipo === 'ual1' && completa) {
    const presentes = new Set(nomes);
    const faltando = completa.filter((n) => !presentes.has(n) && !OSSOS_OBRIGATORIOS_UAL1.includes(n));
    if (faltando.length) rel.aviso('V12', `faltam ${faltando.length} osso(s) não obrigatório(s) do UAL1 (dedos?): ${listaCurta(faltando, 8)}`);
  }
}

/** V13: no máximo 4 influências, soma = 1 ± 1e-4, nenhum vértice sem peso, índices de osso válidos. */
function v13(ctx, rel) {
  const skinned = primitivasDe(ctx).filter((p) => p.skinned);
  if (!skinned.length) {
    rel.na('V13');
    return;
  }
  let influenciasMax = 0;
  let verticesTotal = 0;
  for (const p of skinned) {
    const skin = ctx.json.skins[p.no.skin];
    if (!skin) {
      rel.falha('V13', `${rotulo(p)}: skin #${p.no.skin} não existe`);
      continue;
    }
    const conj = lerInfluencias(ctx, p.prim);
    if (!conj.length) {
      rel.falha('V13', `${rotulo(p)}: malha com skin sem JOINTS_0/WEIGHTS_0`);
      continue;
    }
    const at = p.prim.attributes;
    const nv = conj[0].j.count;
    if (at.POSITION !== undefined && ctx.json.accessors[at.POSITION].count !== nv) {
      rel.falha('V13', `${rotulo(p)}: JOINTS/WEIGHTS com ${nv} vértices, POSITION com ${ctx.json.accessors[at.POSITION].count}`);
    }
    // Tolerância da soma: 1e-4 em float; com inteiros normalizados, meio degrau por influência.
    const tipoPeso = conj[0].w.acc.componentType;
    const tol = tipoPeso === 5126 ? TOL.somaPesos : Math.max(TOL.somaPesos, (4 * conj.length) / (2 * MAX_INTEIRO[tipoPeso]));
    const nJoints = (skin.joints || []).length;
    let maisDe4 = 0, semPeso = 0, naoNormalizados = 0, negativos = 0, ossoInvalido = 0;
    let exMaisDe4 = -1, exSemPeso = -1, exNaoNorm = -1, piorSoma = 1;
    for (let v = 0; v < nv; v++) {
      let soma = 0;
      let inf = 0;
      for (const { j, w } of conj) {
        for (let c = 0; c < 4; c++) {
          const wv = w.valores[v * 4 + c];
          if (wv < 0) negativos++;
          if (wv > 0) {
            inf++;
            soma += wv;
            const ji = j.valores[v * 4 + c];
            if (!Number.isInteger(ji) || ji < 0 || ji >= nJoints) ossoInvalido++;
          }
        }
      }
      if (inf > influenciasMax) influenciasMax = inf;
      if (inf > MAX_INFLUENCIAS) {
        maisDe4++;
        if (exMaisDe4 < 0) exMaisDe4 = v;
      }
      if (inf === 0) {
        semPeso++;
        if (exSemPeso < 0) exSemPeso = v;
      } else if (Math.abs(soma - 1) > tol) {
        naoNormalizados++;
        if (exNaoNorm < 0) exNaoNorm = v;
        if (Math.abs(soma - 1) > Math.abs(piorSoma - 1)) piorSoma = soma;
      }
    }
    verticesTotal += nv;
    if (maisDe4) rel.falha('V13', `${rotulo(p)}: ${maisDe4} vértice(s) com mais de ${MAX_INFLUENCIAS} influências (ex.: vértice ${exMaisDe4})`);
    if (semPeso) rel.falha('V13', `${rotulo(p)}: ${semPeso} vértice(s) sem peso (ex.: vértice ${exSemPeso})`);
    if (naoNormalizados) rel.falha('V13', `${rotulo(p)}: ${naoNormalizados} vértice(s) com soma de pesos ≠ 1 (pior soma ${piorSoma.toFixed(6)}; ex.: vértice ${exNaoNorm})`);
    if (negativos) rel.falha('V13', `${rotulo(p)}: ${negativos} peso(s) negativo(s)`);
    if (ossoInvalido) rel.falha('V13', `${rotulo(p)}: ${ossoInvalido} influência(s) com índice de osso fora de skins[${p.no.skin}].joints`);
  }
  rel.medidas.pesos = { verticesComSkin: verticesTotal, influenciasMax };
}

/** Nome-base de um clip: sem o sufixo _loop. */
function baseDoClip(nome) {
  return nome.endsWith('_loop') ? nome.slice(0, -5) : nome;
}

/** V14: clips mínimos do papel (extras.papel). */
function v14(ctx, rel) {
  const ex = extrasAsset(ctx);
  const temSkin = (ctx.json.skins || []).length > 0;
  if (ex.papel === undefined) {
    if (temSkin) rel.falha('V14', 'asset.extras.papel ausente (combate, conjurador, quadrupede ou objeto)');
    else {
      rel.aviso('V14', 'asset.extras.papel ausente; sem esqueleto, tratado como objeto');
      rel.na('V14');
    }
    return;
  }
  const papel = normalizarPapel(ex.papel);
  const req = PAPEIS[papel];
  if (!req) {
    rel.falha('V14', `papel desconhecido: "${ex.papel}" (combate, conjurador, quadrupede ou objeto)`);
    return;
  }
  rel.medidas.papel = papel;
  const bases = new Set();
  for (const a of ctx.json.animations || []) {
    if (typeof a.name !== 'string') continue;
    const b = baseDoClip(a.name);
    if (CLIPS_LACO.has(b) || CLIPS_SEM_LACO.has(b)) bases.add(b);
  }
  const faltam = req.clips.filter((c) => !bases.has(c));
  if (req.umDe && !req.umDe.some((c) => bases.has(c))) faltam.push(req.umDe.join(' ou '));
  if (faltam.length) rel.falha('V14', `faltam clips para o papel "${papel}": ${faltam.join(', ')}`);
}

/** Passo mediano entre keyframes do sampler com mais chaves (para conferir os 30 FPS). */
function passoDoClip(ctx, anim) {
  let melhor = null;
  for (const s of anim.samplers || []) {
    const acc = ctx.json.accessors && ctx.json.accessors[s.input];
    if (acc && (!melhor || acc.count > melhor.count)) melhor = { count: acc.count, input: s.input };
  }
  if (!melhor || melhor.count < 3) return null;
  const t = lerAcessor(ctx, melhor.input).valores;
  const deltas = [];
  for (let i = 1; i < t.length; i++) deltas.push(t[i] - t[i - 1]);
  deltas.sort((a, b) => a - b);
  return deltas[Math.floor(deltas.length / 2)];
}

/** V15: nomes dos clips pela tabela do §6, sufixo _loop só nos de laço. */
function v15(ctx, rel) {
  const anims = ctx.json.animations || [];
  if (!anims.length) {
    rel.na('V15');
    rel.medidas.clips = [];
    return;
  }
  const vistos = new Set();
  anims.forEach((a, i) => {
    const nome = a.name;
    if (typeof nome !== 'string' || !nome) {
      rel.falha('V15', `animação #${i} sem nome`);
      return;
    }
    if (vistos.has(nome)) rel.falha('V15', `clip "${nome}" repetido`);
    vistos.add(nome);
    const comSufixo = nome.endsWith('_loop');
    const base = baseDoClip(nome);
    if (CLIPS_LACO.has(base)) {
      if (!comSufixo) rel.falha('V15', `clip de laço "${nome}" sem o sufixo _loop (use "${base}_loop")`);
    } else if (CLIPS_SEM_LACO.has(base)) {
      if (comSufixo) rel.falha('V15', `clip "${nome}" não é de laço; tire o sufixo _loop (use "${base}")`);
    } else {
      let dica = DICA_CLIP[nome];
      if (!dica && nome.startsWith('Spell_Simple_')) dica = 'conjurar';
      rel.falha('V15', `nome de clip fora da tabela do §6: "${nome}"${dica ? ` (renomeie para "${dica}")` : ''}`);
      return;
    }
    const ex = a.extras && typeof a.extras === 'object' ? a.extras : {};
    if (ex.origem === undefined) rel.aviso('V15', `clip "${nome}": sem extras.origem (ual1, ou mixamo com o link)`);
    if (CLIPS_LOCOMOCAO.has(base) && typeof ex.velocidadeMs !== 'number') rel.aviso('V15', `clip "${nome}": sem extras.velocidadeMs (clip de locomoção)`);
    const passo = passoDoClip(ctx, a);
    if (passo !== null && Math.abs(passo - 1 / FPS_ESPERADO) > 1e-3) {
      rel.aviso('V15', `clip "${nome}": passo de ${passo.toFixed(4)} s (≈${(1 / passo).toFixed(1)} FPS); o §6 pede 30 FPS sem redução de keyframes`);
    }
  });
  rel.medidas.clips = anims.map((a) => a.name ?? null);
}

/**
 * V16 (heurística geométrica): procura, dentro das primitivas do corpo, uma ilha de geometria
 * (componente ligada, com solda por posição) presa só a um osso de mão e comprida demais
 * para ser a mão: é o retrato de uma arma fundida no corpo.
 */
function ilhasRigidasNaMao(ctx, p) {
  const at = p.prim.attributes || {};
  if (at.POSITION === undefined) return [];
  const modo = p.prim.mode !== undefined ? p.prim.mode : 4;
  if (modo !== 4) return [];
  const conj = lerInfluencias(ctx, p.prim);
  if (!conj.length) return [];
  const pos = lerAcessor(ctx, at.POSITION);
  const nv = pos.count;
  const P = pos.valores;
  const dom = dominantes(conj, nv);
  const joints = (ctx.json.skins[p.no.skin] || {}).joints || [];
  const nomeDoJoint = (k) => ((ctx.json.nodes[joints[k]] || {}).name);

  // União-busca sobre os vértices.
  const raiz = new Int32Array(nv);
  for (let i = 0; i < nv; i++) raiz[i] = i;
  const achar = (x) => {
    while (raiz[x] !== x) {
      raiz[x] = raiz[raiz[x]];
      x = raiz[x];
    }
    return x;
  };
  const unir = (a, b) => {
    const ra = achar(a), rb = achar(b);
    if (ra !== rb) raiz[ra] = rb;
  };
  const idx = p.prim.indices !== undefined ? lerAcessor(ctx, p.prim.indices).valores : null;
  const n = idx ? idx.length : nv;
  for (let t = 0; t + 2 < n; t += 3) {
    const a = idx ? idx[t] : t, b = idx ? idx[t + 1] : t + 1, c = idx ? idx[t + 2] : t + 2;
    if (a >= nv || b >= nv || c >= nv) continue;
    unir(a, b);
    unir(b, c);
  }
  // Solda por posição (costuras de UV e de normais duplicam vértices).
  const mapa = new Map();
  for (let v = 0; v < nv; v++) {
    const chave = `${Math.round(P[v * 3] * 1e5)},${Math.round(P[v * 3 + 1] * 1e5)},${Math.round(P[v * 3 + 2] * 1e5)}`;
    const outro = mapa.get(chave);
    if (outro === undefined) mapa.set(chave, v);
    else unir(v, outro);
  }
  // Agrega por componente.
  const comps = new Map();
  for (let v = 0; v < nv; v++) {
    const r = achar(v);
    let c = comps.get(r);
    if (!c) {
      c = { n: 0, osso: dom.indice[v], pesoMin: Infinity, min: [Infinity, Infinity, Infinity], max: [-Infinity, -Infinity, -Infinity] };
      comps.set(r, c);
    }
    c.n++;
    if (c.osso !== dom.indice[v]) c.osso = -1;
    if (dom.peso[v] < c.pesoMin) c.pesoMin = dom.peso[v];
    for (let k = 0; k < 3; k++) {
      const x = P[v * 3 + k];
      if (x < c.min[k]) c.min[k] = x;
      if (x > c.max[k]) c.max[k] = x;
    }
  }
  const suspeitas = [];
  for (const c of comps.values()) {
    if (c.osso < 0) continue;
    const nomeOsso = nomeDoJoint(c.osso);
    if (!OSSOS_MAO.has(nomeOsso) || c.pesoMin < ARMA_FUNDIDA_PESO_MIN) continue;
    const comprimento = Math.max(c.max[0] - c.min[0], c.max[1] - c.min[1], c.max[2] - c.min[2]);
    if (comprimento > ARMA_FUNDIDA_COMPRIMENTO_MIN) suspeitas.push({ osso: nomeOsso, vertices: c.n, comprimento });
  }
  return suspeitas;
}

/** V16: peça com extras.anexo separada; arma fundida no corpo reprova. */
function v16(ctx, rel) {
  const prims = primitivasDe(ctx);
  // 1) valores de extras.anexo em qualquer nó, malha ou primitiva
  const conferir = (onde, v) => {
    if (v !== undefined && !ANEXOS_VALIDOS.has(v)) rel.falha('V16', `${onde}: extras.anexo = "${v}" (esperado "mao_r" ou "mao_l")`);
  };
  (ctx.json.nodes || []).forEach((no, i) => conferir(`nó "${no.name ?? '#' + i}"`, no.extras && no.extras.anexo));
  (ctx.json.meshes || []).forEach((m, i) => {
    conferir(`malha "${m.name ?? '#' + i}"`, m.extras && m.extras.anexo);
    (m.primitives || []).forEach((pr, k) => conferir(`malha "${m.name ?? '#' + i}" primitiva ${k}`, pr.extras && pr.extras.anexo));
  });
  // 2) a mesma malha usada pelo corpo e pela peça anexa = mesma primitiva
  const usos = new Map();
  for (const p of prims) {
    const u = usos.get(p.indiceMalha) || { comAnexo: false, semAnexo: false };
    if (p.anexoNo !== undefined) u.comAnexo = true;
    else u.semAnexo = true;
    usos.set(p.indiceMalha, u);
  }
  for (const [m, u] of usos) {
    if (u.comAnexo && u.semAnexo) rel.falha('V16', `malha #${m} usada pelo corpo e pela peça com extras.anexo (mesma primitiva)`);
  }
  // 3) heurística: ilha rígida e comprida presa à mão dentro do corpo
  for (const p of prims) {
    if (!p.ehCorpo || !p.skinned) continue;
    for (const s of ilhasRigidasNaMao(ctx, p)) {
      rel.falha('V16', `${rotulo(p)}: ilha de ${s.vertices} vértices presa só a "${s.osso}", com ${s.comprimento.toFixed(2)} m, ` +
        'dentro da malha do corpo — arma fundida? Separe-a num nó com extras.anexo = "mao_r"/"mao_l" (heurística)');
    }
  }
  rel.medidas.pecasAnexas = [...new Set(prims.filter((p) => !p.ehCorpo).map((p) => `${p.no.name ?? '#' + p.indiceNo}:${p.anexo}`))];
}

/** V17: UV (TEXCOORD_0) em [0,1] no corpo. Peças anexas fora de [0,1]: aviso. */
function v17(ctx, rel) {
  let umin = Infinity, umax = -Infinity, vmin = Infinity, vmax = -Infinity;
  for (const p of primitivasDe(ctx)) {
    const ia = p.prim.attributes && p.prim.attributes.TEXCOORD_0;
    if (ia === undefined) {
      if (p.ehCorpo) rel.falha('V17', `${rotulo(p)}: sem TEXCOORD_0 (o albedo pintado precisa de UV)`);
      continue;
    }
    const uv = lerAcessor(ctx, ia);
    let fora = 0;
    for (let i = 0; i < uv.count; i++) {
      const u = uv.valores[i * uv.n];
      const v = uv.valores[i * uv.n + 1];
      if (u < umin) umin = u;
      if (u > umax) umax = u;
      if (v < vmin) vmin = v;
      if (v > vmax) vmax = v;
      if (u < -TOL.uv || u > 1 + TOL.uv || v < -TOL.uv || v > 1 + TOL.uv) fora++;
    }
    if (fora) {
      const msg = `${rotulo(p)}: ${fora} vértice(s) com UV fora de [0,1]`;
      if (p.ehCorpo) rel.falha('V17', msg);
      else rel.aviso('V17', msg);
    }
  }
  if (Number.isFinite(umin)) rel.medidas.uv = { u: [arred(umin), arred(umax)], v: [arred(vmin), arred(vmax)] };
}

const VERIFICACOES = [
  ['V01', v01Autocontido],
  ['V02', v02],
  ['V03', v03],
  ['V04', v04],
  ['V05', v05],
  ['V06', v06],
  ['V07', v07],
  ['V08', v08],
  ['V09', v09],
  ['V10', v10],
  ['V11', v11],
  ['V12', v12],
  ['V13', v13],
  ['V14', v14],
  ['V15', v15],
  ['V16', v16],
  ['V17', v17],
];

// ---------------------------------------------------------------------------------------------
// Lista de ossos do UAL1
// ---------------------------------------------------------------------------------------------

const URL_OSSOS_PADRAO = new URL('./ossos-ual1.json', import.meta.url);

/** Carrega ossos-ual1.json (caminho ou URL file://). */
export function carregarOssosUal1(caminhoOuUrl = URL_OSSOS_PADRAO) {
  const dados = JSON.parse(fs.readFileSync(caminhoOuUrl, 'utf8'));
  if (!Array.isArray(dados.completa) || !dados.completa.every((n) => typeof n === 'string')) {
    throw new Error('ossos-ual1.json sem a lista "completa" de nomes');
  }
  return dados;
}

/** Extrai a lista completa de ossos (skins[0].joints → nomes) de um UAL1_Standard.glb, com o SHA. */
export function extrairOssosUal1(buffer, caminho = null) {
  const buf = Buffer.isBuffer(buffer) ? buffer : Buffer.from(buffer);
  const { json } = lerGlb(buf);
  const skin = json.skins && json.skins[0];
  if (!skin) throw new Error('o GLB não tem skins[0]');
  const completa = skin.joints.map((j) => (json.nodes[j] && json.nodes[j].name) || `#${j}`);
  return {
    descricao: 'Ossos do esqueleto UAL1 (humanoide do GLB-JOGO-v1, §5.1).',
    contrato: `${CONTRATO} §5.1`,
    obrigatorios: [...OSSOS_OBRIGATORIOS_UAL1],
    completa,
    fonte: {
      arquivo: caminho ? path.basename(caminho) : null,
      caminhoOriginal: caminho,
      gerador: (json.asset && json.asset.generator) || null,
      metodo: 'validar-glb-jogo.mjs --extrair-ossos-ual1: skins[0].joints → nodes[].name, na ordem de joints',
      sha256: crypto.createHash('sha256').update(buf).digest('hex'),
      bytes: buf.length,
      contagem: completa.length,
    },
    faltamObrigatorios: OSSOS_OBRIGATORIOS_UAL1.filter((o) => !completa.includes(o)),
  };
}

// ---------------------------------------------------------------------------------------------
// API principal
// ---------------------------------------------------------------------------------------------

/**
 * Valida um GLB em memória.
 * @param {Buffer|Uint8Array} buffer  o arquivo .glb inteiro
 * @param {{nomeArquivo?: string, ossosUal1?: object|null}} opcoes
 *   ossosUal1: undefined = tenta carregar ossos-ual1.json ao lado deste script; null = sem lista.
 */
export function validarGlb(buffer, opcoes = {}) {
  const buf = Buffer.isBuffer(buffer) ? buffer : Buffer.from(buffer);
  const sha256 = crypto.createHash('sha256').update(buf).digest('hex'); // V18: sempre registado
  const rel = new Relatorio();
  rel.medidas.validador = VERSAO_VALIDADOR;
  rel.medidas.bytes = buf.length;

  let ossosUal1 = opcoes.ossosUal1;
  if (ossosUal1 === undefined) {
    try {
      ossosUal1 = carregarOssosUal1();
    } catch (e) {
      ossosUal1 = null;
      rel.aviso('V12', `não foi possível carregar ossos-ual1.json: ${e.message}`);
    }
  }

  let glb = null;
  try {
    glb = lerGlb(buf);
  } catch (e) {
    rel.falha('V01', e.message);
  }

  if (glb) {
    const ctx = criarContexto(glb, { nomeArquivo: opcoes.nomeArquivo, ossosUal1 });
    for (const [codigo, fn] of VERIFICACOES) {
      try {
        fn(ctx, rel);
      } catch (e) {
        rel.falha(codigo, `erro ao verificar: ${e.message}`);
      }
    }
  }
  rel.medidas.verificacoes = rel.resumo(Boolean(glb));

  return {
    contrato: CONTRATO,
    arquivo: opcoes.nomeArquivo ? path.basename(opcoes.nomeArquivo) : null,
    sha256,
    veredito: rel.falhas.length ? 'REPROVADO' : 'APROVADO',
    falhas: rel.falhas,
    avisos: rel.avisos,
    medidas: rel.medidas,
  };
}

/** Valida um arquivo do disco. */
export function validarArquivo(caminho, opcoes = {}) {
  return validarGlb(fs.readFileSync(caminho), { ...opcoes, nomeArquivo: caminho });
}

// ---------------------------------------------------------------------------------------------
// Linha de comando
// ---------------------------------------------------------------------------------------------

const USO = `uso:
  node validar-glb-jogo.mjs <arquivo.glb> [--ossos ossos-ual1.json] [--compacto]
  node validar-glb-jogo.mjs --extrair-ossos-ual1 <UAL1_Standard.glb>`;

export function principal(argv = process.argv) {
  const args = argv.slice(2);
  let arquivo = null, caminhoOssos = null, extrair = null, compacto = false;
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === '--ossos') caminhoOssos = args[++i];
    else if (a === '--extrair-ossos-ual1') extrair = args[++i];
    else if (a === '--compacto') compacto = true;
    else if (a === '--ajuda' || a === '-h') {
      process.stdout.write(`${USO}\n`);
      return 0;
    } else arquivo = a;
  }

  if (extrair) {
    const r = extrairOssosUal1(fs.readFileSync(extrair), extrair);
    process.stdout.write(`${JSON.stringify(r, null, 2)}\n`);
    return r.faltamObrigatorios.length ? 1 : 0;
  }
  if (!arquivo) {
    process.stderr.write(`${USO}\n`);
    return 1;
  }

  let buf;
  try {
    buf = fs.readFileSync(arquivo);
  } catch (e) {
    const r = {
      contrato: CONTRATO,
      arquivo: path.basename(arquivo),
      sha256: null,
      veredito: 'REPROVADO',
      falhas: [{ codigo: 'V01', mensagem: `não foi possível ler o arquivo: ${e.message}` }],
      avisos: [],
      medidas: { validador: VERSAO_VALIDADOR },
    };
    process.stdout.write(`${JSON.stringify(r, null, compacto ? 0 : 2)}\n`);
    return 1;
  }

  let ossosUal1;
  if (caminhoOssos) ossosUal1 = carregarOssosUal1(caminhoOssos); // erro explícito se o caminho dado falhar
  const r = validarGlb(buf, { nomeArquivo: arquivo, ossosUal1 });
  process.stdout.write(`${JSON.stringify(r, null, compacto ? 0 : 2)}\n`);
  return r.veredito === 'APROVADO' ? 0 : 1;
}

if (ehScriptPrincipal(import.meta.url)) {
  try {
    process.exitCode = principal(process.argv);
  } catch (e) {
    process.stderr.write(`erro: ${e.message}\n`);
    process.exitCode = 1;
  }
}
