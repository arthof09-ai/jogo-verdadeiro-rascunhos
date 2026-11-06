#!/usr/bin/env node
/**
 * gerar-iscas.mjs — Gera GLB mínimos sintéticos (JS puro) para o aceite da O1.1 (§8):
 * um GLB correto mínimo e as 8 iscas, cada uma com UM defeito:
 *   escala ×100, pivô no umbigo, sem Head, ossos mixamorig:*, clip "Idle",
 *   5 influências num vértice, textura 1000×1000, arma fundida.
 *
 * Também deriva um GLB do UAL1_Standard.glb real, com os clips renomeados pela tabela do §6
 * (opção --ual1), sem Blender: só reescreve o JSON e mantém o BIN.
 *
 * Uso:
 *   node gerar-iscas.mjs [--saida <pasta>] [--ual1 <UAL1_Standard.glb>]
 *   (por omissão escreve em ./iscas/ ao lado deste script, mais um manifesto.json)
 *
 * Os testes (testes/validar.test.mjs) usam as funções em memória e não escrevem nada no disco.
 * ESTADO: rascunho 0.1, escrito sem execução (NAC-OV-05).
 */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { lerGlb, ehScriptPrincipal, caminhoDeUrl, CONTRATO } from './validar-glb-jogo.mjs';

const DATA = '2026-11-06'; // data fixa: os arquivos gerados são sempre os mesmos bytes
const F32 = 5126;
const U16 = 5123;
const ARRAY_BUFFER = 34962;
const ELEMENT_ARRAY_BUFFER = 34963;

// ---------------------------------------------------------------------------------------------
// PNG sem dependências: deflate "stored" (sem compressão) + CRC-32 + Adler-32
// ---------------------------------------------------------------------------------------------

const TABELA_CRC = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c >>> 0;
  }
  return t;
})();

function crc32(buf) {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) c = TABELA_CRC[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

function adler32(buf) {
  let a = 1, b = 0;
  for (let i = 0; i < buf.length; i++) {
    a = (a + buf[i]) % 65521;
    b = (b + a) % 65521;
  }
  return ((b << 16) | a) >>> 0;
}

/** Fluxo zlib com blocos deflate "stored" (BTYPE=00), até 65535 bytes cada. */
function zlibArmazenado(dados) {
  const partes = [Buffer.from([0x78, 0x01])]; // CMF/FLG válidos: (0x78*256+0x01) % 31 === 0
  const MAX = 65535;
  let p = 0;
  do {
    const fim = Math.min(p + MAX, dados.length);
    const final = fim >= dados.length ? 1 : 0;
    const cab = Buffer.alloc(5);
    cab[0] = final; // BFINAL no bit 0, BTYPE=00; o resto do byte é preenchimento
    cab.writeUInt16LE(fim - p, 1);
    cab.writeUInt16LE(~(fim - p) & 0xffff, 3);
    partes.push(cab, dados.subarray(p, fim));
    p = fim;
  } while (p < dados.length);
  const ad = Buffer.alloc(4);
  ad.writeUInt32BE(adler32(dados));
  partes.push(ad);
  return Buffer.concat(partes);
}

function chunkPng(tipo, dados) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(dados.length);
  const t = Buffer.from(tipo, 'ascii');
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(Buffer.concat([t, dados])));
  return Buffer.concat([len, t, dados, crc]);
}

const cachePng = new Map();

/** PNG válido em tons de cinza (8 bits, sem alfa), com um xadrez de 32 px. */
export function pngCinza(largura, altura) {
  const chave = `${largura}x${altura}`;
  if (cachePng.has(chave)) return cachePng.get(chave);
  const linha = largura + 1; // 1 byte de filtro (0 = nenhum) por linha
  const cru = Buffer.alloc(linha * altura);
  for (let y = 0; y < altura; y++) {
    cru[y * linha] = 0;
    for (let x = 0; x < largura; x++) cru[y * linha + 1 + x] = ((x >> 5) ^ (y >> 5)) & 1 ? 200 : 120;
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(largura, 0);
  ihdr.writeUInt32BE(altura, 4);
  ihdr[8] = 8; // profundidade
  ihdr[9] = 0; // tipo de cor: cinza
  ihdr[10] = 0; // compressão
  ihdr[11] = 0; // filtro
  ihdr[12] = 0; // sem entrelaçamento
  const png = Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunkPng('IHDR', ihdr),
    chunkPng('IDAT', zlibArmazenado(cru)),
    chunkPng('IEND', Buffer.alloc(0)),
  ]);
  cachePng.set(chave, png);
  return png;
}

// ---------------------------------------------------------------------------------------------
// Montador de GLB
// ---------------------------------------------------------------------------------------------

const COMPONENTES = { SCALAR: 1, VEC2: 2, VEC3: 3, VEC4: 4, MAT4: 16 };

class ConstrutorGlb {
  constructor() {
    this.pedacos = [];
    this.tamanho = 0;
    this.bufferViews = [];
    this.accessors = [];
  }

  alinhar() {
    const pad = (4 - (this.tamanho % 4)) % 4;
    if (pad) {
      this.pedacos.push(Buffer.alloc(pad));
      this.tamanho += pad;
    }
  }

  /** Acrescenta bytes ao BIN e devolve o índice do bufferView. */
  vista(bytes, alvo) {
    this.alinhar();
    const bv = { buffer: 0, byteOffset: this.tamanho, byteLength: bytes.length };
    if (alvo) bv.target = alvo;
    this.pedacos.push(bytes);
    this.tamanho += bytes.length;
    this.bufferViews.push(bv);
    return this.bufferViews.length - 1;
  }

  /** Acrescenta um accessor (com min/max opcional, obrigatório no POSITION e nas entradas de animação). */
  acessor(tipado, componentType, type, { alvo, minmax = false } = {}) {
    const bytes = Buffer.from(tipado.buffer, tipado.byteOffset, tipado.byteLength);
    const bufferView = this.vista(bytes, alvo);
    const n = COMPONENTES[type];
    const acc = { bufferView, componentType, count: tipado.length / n, type };
    if (minmax) {
      const mn = new Array(n).fill(Infinity);
      const mx = new Array(n).fill(-Infinity);
      for (let i = 0; i < tipado.length; i++) {
        const c = i % n;
        if (tipado[i] < mn[c]) mn[c] = tipado[i];
        if (tipado[i] > mx[c]) mx[c] = tipado[i];
      }
      acc.min = mn;
      acc.max = mx;
    }
    this.accessors.push(acc);
    return this.accessors.length - 1;
  }

  /** Fecha o BIN, aplica a mutação opcional ao JSON e devolve o GLB. */
  montar(json, mutar) {
    this.alinhar();
    const bin = Buffer.concat(this.pedacos);
    json.buffers = [{ byteLength: bin.length }];
    json.bufferViews = this.bufferViews;
    json.accessors = this.accessors;
    if (mutar) mutar(json);
    return montarGlbBruto(json, bin);
  }
}

/** Junta JSON e BIN num contêiner GLB v2 (JSON preenchido com espaços, BIN com zeros). */
export function montarGlbBruto(json, bin) {
  let txt = Buffer.from(JSON.stringify(json), 'utf8');
  const padJ = (4 - (txt.length % 4)) % 4;
  if (padJ) txt = Buffer.concat([txt, Buffer.alloc(padJ, 0x20)]);
  const partes = [];
  const cab = Buffer.alloc(12);
  const temBin = bin && bin.length > 0;
  let binPad = null;
  if (temBin) {
    const padB = (4 - (bin.length % 4)) % 4;
    binPad = padB ? Buffer.concat([bin, Buffer.alloc(padB)]) : bin;
  }
  const total = 12 + 8 + txt.length + (temBin ? 8 + binPad.length : 0);
  cab.writeUInt32LE(0x46546c67, 0);
  cab.writeUInt32LE(2, 4);
  cab.writeUInt32LE(total, 8);
  partes.push(cab);
  const cj = Buffer.alloc(8);
  cj.writeUInt32LE(txt.length, 0);
  cj.writeUInt32LE(0x4e4f534a, 4);
  partes.push(cj, txt);
  if (temBin) {
    const cb = Buffer.alloc(8);
    cb.writeUInt32LE(binPad.length, 0);
    cb.writeUInt32LE(0x004e4942, 4);
    partes.push(cb, binPad);
  }
  return Buffer.concat(partes);
}

// ---------------------------------------------------------------------------------------------
// Geometria: caixas com normais por face e UV em [0,1]
// ---------------------------------------------------------------------------------------------

// Cada face: normal n e eixos u, v com u × v = n (cantos em sentido anti-horário vistos de fora).
const FACES = [
  { n: [1, 0, 0], u: [0, 0, -1], v: [0, 1, 0] },
  { n: [-1, 0, 0], u: [0, 0, 1], v: [0, 1, 0] },
  { n: [0, 1, 0], u: [1, 0, 0], v: [0, 0, -1] },
  { n: [0, -1, 0], u: [1, 0, 0], v: [0, 0, 1] },
  { n: [0, 0, 1], u: [1, 0, 0], v: [0, 1, 0] },
  { n: [0, 0, -1], u: [-1, 0, 0], v: [0, 1, 0] },
];
const CANTOS = [
  [-1, -1, 0, 0],
  [1, -1, 1, 0],
  [1, 1, 1, 1],
  [-1, 1, 0, 1],
];

function caixa(min, max) {
  const c = [0, 1, 2].map((k) => (min[k] + max[k]) / 2);
  const h = [0, 1, 2].map((k) => (max[k] - min[k]) / 2);
  const out = { posicoes: [], normais: [], uvs: [], indices: [] };
  for (const f of FACES) {
    const b = out.posicoes.length / 3;
    for (const [su, sv, uu, vv] of CANTOS) {
      for (let k = 0; k < 3; k++) out.posicoes.push(c[k] + (f.n[k] + su * f.u[k] + sv * f.v[k]) * h[k]);
      out.normais.push(...f.n);
      out.uvs.push(uu, 1 - vv);
    }
    out.indices.push(b, b + 1, b + 2, b, b + 2, b + 3);
  }
  return out;
}

function anexarCaixa(geo, cx, influenciasDe) {
  const base = geo.pos.length / 3;
  const nv = cx.posicoes.length / 3;
  for (let v = 0; v < nv; v++) {
    const p = cx.posicoes.slice(v * 3, v * 3 + 3);
    geo.pos.push(...p);
    geo.nor.push(...cx.normais.slice(v * 3, v * 3 + 3));
    geo.uv.push(...cx.uvs.slice(v * 2, v * 2 + 2));
    geo.infl.push(influenciasDe(p));
  }
  for (const i of cx.indices) geo.ind.push(base + i);
}

// ---------------------------------------------------------------------------------------------
// Esqueleto sintético: os 23 ossos obrigatórios do UAL1, frente +Z, esquerda em +X (glTF)
// ---------------------------------------------------------------------------------------------

/** [chave, pai, posição no mundo em metros, na pose de descanso] */
const ESQUELETO = [
  ['root', null, [0, 0, 0]],
  ['pelvis', 'root', [0, 1.0, 0]],
  ['spine_01', 'pelvis', [0, 1.1, 0]],
  ['spine_02', 'spine_01', [0, 1.25, 0]],
  ['spine_03', 'spine_02', [0, 1.4, 0]],
  ['neck_01', 'spine_03', [0, 1.55, 0]],
  ['Head', 'neck_01', [0, 1.65, 0]],
  ['clavicle_l', 'spine_03', [0.05, 1.45, 0]],
  ['upperarm_l', 'clavicle_l', [0.2, 1.45, 0]],
  ['lowerarm_l', 'upperarm_l', [0.45, 1.45, 0]],
  ['hand_l', 'lowerarm_l', [0.7, 1.45, 0]],
  ['clavicle_r', 'spine_03', [-0.05, 1.45, 0]],
  ['upperarm_r', 'clavicle_r', [-0.2, 1.45, 0]],
  ['lowerarm_r', 'upperarm_r', [-0.45, 1.45, 0]],
  ['hand_r', 'lowerarm_r', [-0.7, 1.45, 0]],
  ['thigh_l', 'pelvis', [0.1, 0.95, 0]],
  ['calf_l', 'thigh_l', [0.1, 0.5, 0]],
  ['foot_l', 'calf_l', [0.1, 0.08, 0]],
  ['ball_l', 'foot_l', [0.1, 0.02, 0.12]],
  ['thigh_r', 'pelvis', [-0.1, 0.95, 0]],
  ['calf_r', 'thigh_r', [-0.1, 0.5, 0]],
  ['foot_r', 'calf_r', [-0.1, 0.08, 0]],
  ['ball_r', 'foot_r', [-0.1, 0.02, 0.12]],
];

/** Nomes do Mixamo para a isca mixamorig ("Root" não existe no Mixamo; fica só para manter a hierarquia). */
const NOMES_MIXAMO = {
  root: 'mixamorig:Root', pelvis: 'mixamorig:Hips', spine_01: 'mixamorig:Spine', spine_02: 'mixamorig:Spine1',
  spine_03: 'mixamorig:Spine2', neck_01: 'mixamorig:Neck', Head: 'mixamorig:Head',
  clavicle_l: 'mixamorig:LeftShoulder', upperarm_l: 'mixamorig:LeftArm', lowerarm_l: 'mixamorig:LeftForeArm', hand_l: 'mixamorig:LeftHand',
  clavicle_r: 'mixamorig:RightShoulder', upperarm_r: 'mixamorig:RightArm', lowerarm_r: 'mixamorig:RightForeArm', hand_r: 'mixamorig:RightHand',
  thigh_l: 'mixamorig:LeftUpLeg', calf_l: 'mixamorig:LeftLeg', foot_l: 'mixamorig:LeftFoot', ball_l: 'mixamorig:LeftToeBase',
  thigh_r: 'mixamorig:RightUpLeg', calf_r: 'mixamorig:RightLeg', foot_r: 'mixamorig:RightFoot', ball_r: 'mixamorig:RightToeBase',
};

const ORIGEM_MIXAMO = { fonte: 'mixamo', link: 'https://www.mixamo.com/' };
/** Clips mínimos do papel "combate" (§6), já com os nomes do jogo. */
const CLIPS_CORRETOS = [
  { nome: 'parado_loop', origem: 'ual1' },
  { nome: 'andar_loop', origem: 'ual1', velocidadeMs: 1.4 },
  { nome: 'correr_loop', origem: 'ual1', velocidadeMs: 3.5 },
  { nome: 'atacar', origem: 'ual1' },
  { nome: 'golpe', origem: 'ual1' },
  { nome: 'cair', origem: ORIGEM_MIXAMO },
  { nome: 'levantar', origem: ORIGEM_MIXAMO },
  { nome: 'morrer', origem: 'ual1' },
];

// ---------------------------------------------------------------------------------------------
// Gerador
// ---------------------------------------------------------------------------------------------

/**
 * Gera um GLB sintético. Sem opções = o GLB correto mínimo (deve sair APROVADO).
 * @param {object} opcoes
 *   escala (1), deslocY (0), semHead, mixamo, clipExtra (nome), cincoInfluencias,
 *   ladoTextura (1024), armaFundida, extras (mescla em asset.extras), mutarJson(json)
 */
export function gerarGlb(opcoes = {}) {
  const op = {
    escala: 1,
    deslocY: 0,
    semHead: false,
    mixamo: false,
    clipExtra: null,
    cincoInfluencias: false,
    ladoTextura: 1024,
    armaFundida: false,
    extras: {},
    mutarJson: null,
    ...opcoes,
  };
  const tp = ([x, y, z]) => [x * op.escala, y * op.escala + op.deslocY, z * op.escala];

  // 1) Esqueleto (nós 0..B-1, na mesma ordem de skins[0].joints)
  const ossos = ESQUELETO.filter(([chave]) => !(op.semHead && chave === 'Head'));
  const idx = new Map(ossos.map(([chave], i) => [chave, i]));
  const posMundo = new Map(ossos.map(([chave, , p]) => [chave, tp(p)]));
  const nos = ossos.map(([chave, pai]) => {
    const p = posMundo.get(chave);
    const pp = pai ? posMundo.get(pai) : [0, 0, 0];
    const no = { name: op.mixamo ? NOMES_MIXAMO[chave] : chave, translation: [p[0] - pp[0], p[1] - pp[1], p[2] - pp[2]] };
    const filhos = ossos.filter(([, paiDoOutro]) => paiDoOutro === chave).map(([c]) => idx.get(c));
    if (filhos.length) no.children = filhos;
    return no;
  });

  // 2) Corpo: uma caixa em T (1,80 m de altura, pés em Y = 0, centrada em XZ)
  const geo = { pos: [], nor: [], uv: [], ind: [], infl: [] };
  anexarCaixa(geo, caixa([-0.9, 0, -0.15], [0.9, 1.8, 0.15]), (p) =>
    p[1] > 0.9 ? [['spine_03', 0.5], ['neck_01', 0.5]] : [['pelvis', 1]]);
  if (op.armaFundida) {
    // Isca: a espada (0,85 m) colada à mão direita, DENTRO da mesma primitiva do corpo.
    const mao = ESQUELETO.find(([c]) => c === 'hand_r')[2];
    anexarCaixa(geo, caixa([mao[0] - 0.03, 0.6, -0.03], [mao[0] + 0.03, mao[1], 0.03]), () => [['hand_r', 1]]);
  }
  const nv = geo.pos.length / 3;
  const POS = new Float32Array(nv * 3);
  for (let v = 0; v < nv; v++) POS.set(tp([geo.pos[v * 3], geo.pos[v * 3 + 1], geo.pos[v * 3 + 2]]), v * 3);
  const NOR = new Float32Array(geo.nor);
  const UV = new Float32Array(geo.uv);
  const IND = new Uint16Array(geo.ind);
  const J0 = new Uint16Array(nv * 4);
  const W0 = new Float32Array(nv * 4);
  for (let v = 0; v < nv; v++) {
    geo.infl[v].forEach(([chave, w], c) => {
      J0[v * 4 + c] = idx.get(chave);
      W0[v * 4 + c] = w;
    });
  }
  let J1 = null, W1 = null;
  if (op.cincoInfluencias) {
    // Isca: o vértice 0 com 5 influências de 0,2 (soma 1, mas 5 > 4).
    J1 = new Uint16Array(nv * 4);
    W1 = new Float32Array(nv * 4);
    const cinco = ['pelvis', 'spine_01', 'spine_02', 'spine_03', 'neck_01'];
    for (let c = 0; c < 4; c++) {
      J0[c] = idx.get(cinco[c]);
      W0[c] = 0.2;
    }
    J1[0] = idx.get(cinco[4]);
    W1[0] = 0.2;
  }

  const g = new ConstrutorGlb();
  const atributos = {
    POSITION: g.acessor(POS, F32, 'VEC3', { alvo: ARRAY_BUFFER, minmax: true }),
    NORMAL: g.acessor(NOR, F32, 'VEC3', { alvo: ARRAY_BUFFER }),
    TEXCOORD_0: g.acessor(UV, F32, 'VEC2', { alvo: ARRAY_BUFFER }),
    JOINTS_0: g.acessor(J0, U16, 'VEC4', { alvo: ARRAY_BUFFER }),
    WEIGHTS_0: g.acessor(W0, F32, 'VEC4', { alvo: ARRAY_BUFFER }),
  };
  if (J1) {
    atributos.JOINTS_1 = g.acessor(J1, U16, 'VEC4', { alvo: ARRAY_BUFFER });
    atributos.WEIGHTS_1 = g.acessor(W1, F32, 'VEC4', { alvo: ARRAY_BUFFER });
  }
  const indCorpo = g.acessor(IND, U16, 'SCALAR', { alvo: ELEMENT_ARRAY_BUFFER });

  // 3) Matrizes de bind inversas (o esqueleto só tem translações: IBM = translação por −posição)
  const IBM = new Float32Array(16 * ossos.length);
  ossos.forEach(([chave], i) => {
    const p = posMundo.get(chave);
    IBM.set([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -p[0], -p[1], -p[2], 1], i * 16);
  });
  const aIbm = g.acessor(IBM, F32, 'MAT4');

  const meshes = [{ name: 'corpo', primitives: [{ attributes: atributos, indices: indCorpo, material: 0 }] }];

  // 4) Arma separada (no GLB correto): nó próprio, sem skin, com extras.anexo = "mao_r"
  if (!op.armaFundida) {
    const esp = { pos: [], nor: [], uv: [], ind: [], infl: [] };
    anexarCaixa(esp, caixa([-0.03, -0.85, -0.03], [0.03, 0, 0.03]), () => []);
    meshes.push({
      name: 'espada',
      primitives: [{
        attributes: {
          POSITION: g.acessor(new Float32Array(esp.pos), F32, 'VEC3', { alvo: ARRAY_BUFFER, minmax: true }),
          NORMAL: g.acessor(new Float32Array(esp.nor), F32, 'VEC3', { alvo: ARRAY_BUFFER }),
          TEXCOORD_0: g.acessor(new Float32Array(esp.uv), F32, 'VEC2', { alvo: ARRAY_BUFFER }),
        },
        indices: g.acessor(new Uint16Array(esp.ind), U16, 'SCALAR', { alvo: ELEMENT_ARRAY_BUFFER }),
        material: 1,
      }],
    });
  }

  // 5) Textura do albedo
  const vImg = g.vista(pngCinza(op.ladoTextura, op.ladoTextura));

  // 6) Animações: um canal de translação na pélvis, 3 chaves a 30 FPS
  const aT = g.acessor(new Float32Array([0, 1 / 30, 2 / 30]), F32, 'SCALAR', { minmax: true });
  const tp0 = nos[idx.get('pelvis')].translation;
  const aS = g.acessor(new Float32Array([...tp0, tp0[0], tp0[1] + 0.01 * op.escala, tp0[2], ...tp0]), F32, 'VEC3');
  const clips = [...CLIPS_CORRETOS];
  if (op.clipExtra) clips.push({ nome: op.clipExtra, origem: 'ual1' });
  const animations = clips.map((c) => ({
    name: c.nome,
    channels: [{ sampler: 0, target: { node: idx.get('pelvis'), path: 'translation' } }],
    samplers: [{ input: aT, output: aS, interpolation: 'LINEAR' }],
    extras: c.velocidadeMs ? { origem: c.origem, velocidadeMs: c.velocidadeMs } : { origem: c.origem },
  }));

  // 7) Nós da cena
  const iCorpo = nos.length;
  nos.push({ name: 'corpo', mesh: 0, skin: 0 });
  const raizes = [idx.get('root'), iCorpo];
  if (!op.armaFundida) {
    const iEsp = nos.length;
    nos.push({ name: 'espada', mesh: 1, translation: posMundo.get('hand_r'), extras: { anexo: 'mao_r' } });
    raizes.push(iEsp);
  }

  const json = {
    asset: {
      version: '2.0',
      generator: 'gerar-iscas.mjs (RPG Assimilação, O1.1)',
      extras: {
        contrato: CONTRATO,
        origem: { rota: 'sintetica', referenciaSha: '0'.repeat(64), oficinaJob: 'gerar-iscas', data: DATA },
        alturaM: 1.8,
        papel: 'combate',
        esqueleto: 'ual1',
        tipo: 'personagem',
        ...op.extras,
      },
    },
    scene: 0,
    scenes: [{ name: 'Cena', nodes: raizes }],
    nodes: nos,
    meshes,
    skins: [{ name: 'Armature', inverseBindMatrices: aIbm, joints: ossos.map((_, i) => i), skeleton: idx.get('root') }],
    materials: [
      { name: 'M_Corpo', pbrMetallicRoughness: { baseColorTexture: { index: 0 }, metallicFactor: 0, roughnessFactor: 0.9 } },
      { name: 'M_Espada', pbrMetallicRoughness: { baseColorTexture: { index: 0 }, metallicFactor: 0.05, roughnessFactor: 0.8 } },
    ],
    samplers: [{ magFilter: 9729, minFilter: 9987, wrapS: 10497, wrapT: 10497 }],
    textures: [{ sampler: 0, source: 0 }],
    images: [{ name: 'albedo', mimeType: 'image/png', bufferView: vImg }],
    animations,
  };
  return g.montar(json, op.mutarJson);
}

/** As iscas do §8: nome → opções do gerador e a falha que TEM de aparecer. */
export const ISCAS = Object.freeze({
  'isca-escala-x100': { opcoes: { escala: 100 }, falha: 'V04', descricao: 'malha em centímetros (×100)' },
  'isca-pivo-umbigo': { opcoes: { deslocY: -1.0 }, falha: 'V05', descricao: 'origem no umbigo, a 1 m do chão' },
  'isca-sem-head': { opcoes: { semHead: true }, falha: 'V11', descricao: 'falta o osso Head' },
  'isca-mixamorig': { opcoes: { mixamo: true }, falha: 'V11', descricao: 'ossos mixamorig:*' },
  'isca-clip-idle': { opcoes: { clipExtra: 'Idle' }, falha: 'V15', descricao: 'um clip chamado "Idle"' },
  'isca-cinco-influencias': { opcoes: { cincoInfluencias: true }, falha: 'V13', descricao: '5 influências num vértice' },
  'isca-textura-1000': { opcoes: { ladoTextura: 1000 }, falha: 'V09', descricao: 'textura 1000×1000' },
  'isca-arma-fundida': { opcoes: { armaFundida: true }, falha: 'V16', descricao: 'espada na mesma primitiva do corpo' },
});

// ---------------------------------------------------------------------------------------------
// GLB derivado do UAL1_Standard.glb real (aceite §8.2), só com reescrita do JSON
// ---------------------------------------------------------------------------------------------

/** Clip nativo do UAL1 → nome no jogo (§6). */
const RENOMEAR_UAL1 = {
  Idle_Loop: 'parado_loop',
  Walk_Loop: 'andar_loop',
  Jog_Fwd_Loop: 'correr_loop',
  Sword_Attack: 'atacar',
  Hit_Chest: 'golpe',
  Death01: 'morrer',
  Spell_Simple_Shoot: 'conjurar',
};

/**
 * Deriva um GLB do UAL1: mantém só os clips da tabela do §6 (renomeados), põe asset.extras.
 * Os clips cair/levantar vêm do Mixamo por retarget (O7.1b) e ainda NÃO existem: este GLB
 * deve reprovar só na V14 até lá. Os accessors dos clips descartados ficam órfãos (válido no glTF).
 */
export function derivarDeUal1(bufferUal1) {
  const buf = Buffer.isBuffer(bufferUal1) ? bufferUal1 : Buffer.from(bufferUal1);
  const { json, bin } = lerGlb(buf);
  const sha = crypto.createHash('sha256').update(buf).digest('hex');
  json.animations = (json.animations || [])
    .filter((a) => RENOMEAR_UAL1[a.name])
    .map((a) => ({ ...a, name: RENOMEAR_UAL1[a.name], extras: { ...(a.extras || {}), origem: 'ual1', clipNativo: a.name } }));
  let yMin = Infinity, yMax = -Infinity;
  for (const m of json.meshes || []) {
    for (const p of m.primitives || []) {
      const acc = json.accessors[p.attributes.POSITION];
      if (acc && acc.min && acc.max) {
        yMin = Math.min(yMin, acc.min[1]);
        yMax = Math.max(yMax, acc.max[1]);
      }
    }
  }
  json.asset.extras = {
    contrato: CONTRATO,
    origem: { rota: 'ual1-derivado', referenciaSha: sha, oficinaJob: 'gerar-iscas --ual1', data: DATA },
    alturaM: Math.round((yMax - yMin) * 10000) / 10000, // medida do próprio UAL1 (≈ 1,8292 m)
    papel: 'combate',
    esqueleto: 'ual1',
    tipo: 'personagem',
  };
  return montarGlbBruto(json, bin);
}

// ---------------------------------------------------------------------------------------------
// Linha de comando: escreve os arquivos e um manifesto
// ---------------------------------------------------------------------------------------------

function principal(argv) {
  const args = argv.slice(2);
  let saida = path.join(path.dirname(caminhoDeUrl(import.meta.url)), 'iscas');
  let ual1 = null;
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--saida') saida = path.resolve(args[++i]);
    else if (args[i] === '--ual1') ual1 = args[++i];
  }
  fs.mkdirSync(saida, { recursive: true });
  const manifesto = { contrato: CONTRATO, gerado: DATA, gerador: 'gerar-iscas.mjs', arquivos: [] };
  const escrever = (nome, buf, falhaEsperada, descricao) => {
    fs.writeFileSync(path.join(saida, nome), buf);
    manifesto.arquivos.push({
      arquivo: nome,
      bytes: buf.length,
      sha256: crypto.createHash('sha256').update(buf).digest('hex'),
      vereditoEsperado: falhaEsperada ? 'REPROVADO' : 'APROVADO',
      falhaEsperada,
      descricao,
    });
  };
  escrever('correto-minimo__v01.glb', gerarGlb(), null, 'GLB correto mínimo sintético');
  for (const [nome, isca] of Object.entries(ISCAS)) escrever(`${nome}__v01.glb`, gerarGlb(isca.opcoes), isca.falha, isca.descricao);
  if (ual1) {
    escrever('ual1-derivado__v01.glb', derivarDeUal1(fs.readFileSync(ual1)), 'V14',
      'UAL1 com clips renomeados (§6); reprova na V14 até cair/levantar chegarem do Mixamo (O7.1b)');
  }
  fs.writeFileSync(path.join(saida, 'manifesto.json'), `${JSON.stringify(manifesto, null, 2)}\n`);
  process.stdout.write(`${manifesto.arquivos.length} arquivo(s) em ${saida}\n`);
  return 0;
}

if (ehScriptPrincipal(import.meta.url)) {
  try {
    process.exitCode = principal(process.argv);
  } catch (e) {
    process.stderr.write(`erro: ${e.message}\n`);
    process.exitCode = 1;
  }
}
