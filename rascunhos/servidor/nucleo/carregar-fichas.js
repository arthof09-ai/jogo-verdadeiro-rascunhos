// Carregador das fichas `fichas/1` (JV0.6a, com a ERRATA v0.2).
// REGRA: sem node:*. Um campo em falta é RECUSADO, nunca vira zero.
// Em erro devolve {ok:false, erros:[{arquivo, campo, motivo}]} e a sala não abre.
// Em sucesso devolve as fichas congeladas (Object.freeze profundo).

import { clonarJson, congelarProfundo } from './util.js';
import { sha256Hex } from './sha256.js';

export const FORMATO_FICHAS = 'fichas/1';

// E1: a classificação DA FICHA usa as chaves literais de K_TESTE_DE_MORTE (camelCase).
export const CLASSIFICACAO_FICHA = Object.freeze(['bronze', 'prata', 'ouro', 'ouroNegro', 'lendario']);
// E2: a classificação DA TÉCNICA usa os nomes do BANDAS_DME.
export const CLASSIFICACAO_TECNICA = Object.freeze(['Bronze', 'Prata', 'Ouro', 'Ouro Negro', 'Lendario']);
export const POSICAO_FIP = Object.freeze(['Entrada', 'Baixa', 'Media', 'Alta', 'Apice']);

// ---------------------------------------------------------------------------
// Schema (subconjunto pequeno de JSON Schema, interpretado pelo validador abaixo)
// ---------------------------------------------------------------------------

const SCHEMA_TECNICA = {
  type: 'object',
  required: ['id', 'nome', 'expressaoAtaque', 'custoPA', 'alcanceM'],
  properties: {
    id: { type: 'string', minLength: 1 },
    nome: { type: 'string' },
    expressaoAtaque: { type: 'string', minLength: 1 },
    expressaoDano: { type: 'string', minLength: 1 },
    componentes: {
      type: 'array',
      items: {
        type: 'object',
        required: ['tipo', 'expressao'],
        properties: { tipo: { type: 'string', minLength: 1 }, expressao: { type: 'string', minLength: 1 } },
      },
    },
    tipos: { type: 'array', items: { type: 'string', minLength: 1 } },
    tipo: { type: 'string', minLength: 1 },
    reparticao: { type: 'array', items: { type: 'string', minLength: 1 } }, // E3
    classificacao: { enum: CLASSIFICACAO_TECNICA }, // E2
    posicaoFIP: { enum: POSICAO_FIP }, // E2
    custoPA: { type: 'integer', minimum: 0 },
    alcanceM: { type: 'number', minimum: 0 }, // nosso, não do motor
    magia: { type: 'boolean' },
    usaArma: { type: 'boolean' },
    derruba: { type: 'boolean' },
    nomeTeste: { type: 'string' }, // E6 (opcionais novos)
    efeitoSeResistir: { enum: ['anula', 'metade', 'nenhum'] },
    textoEfeito: { type: 'string' },
    expressaoCura: { type: 'string', minLength: 1 },
    curaBloqueada: { type: 'boolean' },
  },
  // E2: o 3.º ramo (classificacao + posicaoFIP) saiu.
  anyOf: [{ required: ['expressaoDano'] }, { required: ['componentes'] }],
  // A técnica não tem additionalProperties:false no rascunho; campo desconhecido vira AVISO.
  avisarDesconhecidos: true,
};

export const SCHEMA_FICHAS_1 = Object.freeze({
  type: 'object',
  additionalProperties: false,
  // E4: `ca` e `defesaAplicavel` saíram dos obrigatórios (regra extra: pelo menos um).
  required: [
    'id', 'nome', 'papel', 'classificacao', 'vidaTotal', 'paTotal', 'rd',
    'testes', 'constituicao', 'deslocamentoBase', 'tecnicas', 'fonte',
  ],
  properties: {
    id: { type: 'string', pattern: '^[a-z0-9-]+$' },
    nome: { type: 'string', minLength: 1 },
    nomePublico: { type: 'string', minLength: 1 },
    papel: { enum: ['criatura', 'npc', 'jogadora'] },
    classificacao: { enum: CLASSIFICACAO_FICHA },
    vidaTotal: { type: 'integer', minimum: 1 },
    paTotal: { type: 'integer', minimum: 0 },
    ca: { type: 'integer' },
    defesaAplicavel: {
      type: ['object', 'null'],
      required: ['valor'],
      properties: { valor: { type: 'integer' }, nomeDaRegra: { type: 'string' }, origem: { type: 'string' } },
    },
    // E4: reacaoDefensiva SAIU da ficha (vai para o estado/contexto). Por isso é recusada aqui.
    rd: {
      type: 'object',
      required: ['geral', 'porTipo'],
      properties: {
        geral: { type: 'integer', minimum: 0 },
        porTipo: { type: 'object', additionalProperties: { type: 'integer' } },
      },
    },
    testes: {
      type: 'object',
      required: ['fortitude'], // E7: `ataque` só é obrigatório se faltar expressaoAtaque nalguma técnica
      additionalProperties: { type: 'string', minLength: 1 },
    },
    constituicao: { type: 'integer' },
    testesDeMorteDesignado: { type: 'boolean' }, // E1: booleano
    proficiencia: { type: 'integer' },
    inteligencia: { type: 'integer' },
    bonusCD: { type: 'integer' },
    expressaoForca: { type: 'string', minLength: 1 },
    contraAtaque: {
      type: ['object', 'null'],
      required: ['expressaoAtaque'],
      properties: { expressaoAtaque: { type: 'string', minLength: 1 } },
    },
    deslocamentoBase: { type: 'number', minimum: 0 }, // metros; nosso
    tecnicas: { type: 'array', minItems: 1, items: SCHEMA_TECNICA },
    consumiveis: {
      type: 'array',
      items: {
        type: 'object',
        required: ['itemId', 'quantidade'],
        properties: { itemId: { type: 'string', minLength: 1 }, quantidade: { type: 'integer', minimum: 0 } },
      },
    },
    transformacao: { type: ['object', 'null'] },
    comportamentoIA: { type: ['object', 'null'] },
    // Plano B (I0004, 08/11): enquanto não há GLB, a figura desenha-se com o marcador do site (cena.js addMarker):
    // 'marcador' (humanoide) ou 'marcador-lobo' (quadrúpede), com a altura em metros (as figuras do site já vêm ×1,25).
    visual: {
      type: 'object',
      properties: {
        glb: { type: 'string' },
        alturaM: { type: 'number', exclusiveMinimum: 0, maximum: 15 },
        marcador: { enum: ['marcador', 'marcador-lobo'] },
      },
    },
    // Ordem 13 (parte C; site jogo.js FRASES_IA, «verbos.acerto»): o verbo próprio do golpe de cada monstro, para a
    // narração («O Lobo deu uma patada a …»). Só texto: não muda mecânica nenhuma. Sem ele, a narração diz «acerta».
    verbos: {
      type: 'object',
      additionalProperties: false,
      properties: {
        acerto: { type: 'string', minLength: 1 },
        falha: { type: 'string', minLength: 1 },
      },
    },
    fonte: {
      type: 'object',
      required: ['origem', 'data'],
      properties: { origem: { type: 'string', minLength: 1 }, data: { type: 'string', minLength: 1 } },
    },
    bonusFortitude: { type: 'integer', minimum: 0 }, // E6
    reacaoRefletir: { type: 'boolean' }, // E6
    expressaoCura: { type: 'string', minLength: 1 }, // E6 (cura)
    curaBloqueada: { type: 'boolean' },
  },
});

// ---------------------------------------------------------------------------
// Validador de schema próprio (pequeno, sem dependências)
// ---------------------------------------------------------------------------

function tipoDe(v) {
  if (v === null) return 'null';
  if (Array.isArray(v)) return 'array';
  if (typeof v === 'number') return Number.isInteger(v) ? 'integer' : 'number';
  return typeof v;
}

function casaTipo(esperado, v) {
  const t = tipoDe(v);
  const lista = Array.isArray(esperado) ? esperado : [esperado];
  return lista.some((e) => e === t || (e === 'number' && t === 'integer'));
}

function junta(caminho, chave) {
  if (typeof chave === 'number') return `${caminho}[${chave}]`;
  return caminho ? `${caminho}.${chave}` : chave;
}

function emFalta(obj, chave) {
  return !Object.prototype.hasOwnProperty.call(obj, chave) || obj[chave] === undefined;
}

/**
 * Valida `valor` contra `schema`. Empurra {campo, motivo} para `erros`
 * e {campo, motivo} para `avisos`. Suporta: type, enum, pattern, minLength,
 * minimum, minItems, items, required, properties, additionalProperties, anyOf(required).
 */
export function validarSchema(schema, valor, caminho, erros, avisos = []) {
  const campo = caminho || '(raiz)';
  if (schema.type !== undefined && !casaTipo(schema.type, valor)) {
    const esp = Array.isArray(schema.type) ? schema.type.join(' ou ') : schema.type;
    erros.push({ campo, motivo: `tipo errado: esperado ${esp}, veio ${tipoDe(valor)}` });
    return;
  }
  if (schema.enum && !schema.enum.includes(valor)) {
    erros.push({ campo, motivo: `valor fora da lista (${schema.enum.join(', ')})` });
    return;
  }
  if (typeof valor === 'string') {
    if (schema.minLength !== undefined && valor.length < schema.minLength) erros.push({ campo, motivo: 'texto vazio' });
    if (schema.pattern && !new RegExp(schema.pattern).test(valor)) erros.push({ campo, motivo: `não casa com ${schema.pattern}` });
  }
  if (typeof valor === 'number') {
    if (!Number.isFinite(valor)) erros.push({ campo, motivo: 'número não finito' });
    else if (schema.minimum !== undefined && valor < schema.minimum) erros.push({ campo, motivo: `abaixo do mínimo ${schema.minimum}` });
  }
  if (Array.isArray(valor)) {
    if (schema.minItems !== undefined && valor.length < schema.minItems) {
      erros.push({ campo, motivo: `precisa de pelo menos ${schema.minItems} item(ns)` });
    }
    if (schema.items) valor.forEach((x, i) => validarSchema(schema.items, x, junta(caminho, i), erros, avisos));
    return;
  }
  if (valor !== null && typeof valor === 'object') {
    for (const r of schema.required ?? []) {
      if (emFalta(valor, r)) erros.push({ campo: junta(caminho, r), motivo: 'em falta' });
    }
    for (const [k, v] of Object.entries(valor)) {
      const sub = schema.properties?.[k];
      if (sub) validarSchema(sub, v, junta(caminho, k), erros, avisos);
      else if (schema.additionalProperties === false) erros.push({ campo: junta(caminho, k), motivo: 'campo não permitido' });
      else if (schema.additionalProperties && typeof schema.additionalProperties === 'object') {
        validarSchema(schema.additionalProperties, v, junta(caminho, k), erros, avisos);
      } else if (schema.avisarDesconhecidos) avisos.push({ campo: junta(caminho, k), motivo: 'campo desconhecido (aceite)' });
    }
    if (schema.anyOf) {
      const ok = schema.anyOf.some((alt) => (alt.required ?? []).every((r) => !emFalta(valor, r)));
      if (!ok) {
        const alternativas = schema.anyOf.map((a) => (a.required ?? []).join('+')).join(' ou ');
        erros.push({ campo, motivo: `precisa de ${alternativas}` });
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Expressões de dado
// ---------------------------------------------------------------------------

// Verificação mínima, sintática: termos NdM ou constantes, ligados por + ou −.
// TODO(JV1.x): a regra da JV0.6a §3 é "uma chamada seca do motor com semente fixa não dá erro".
// Para isso injete `opcoes.verificarExpressao(expr) → true|false` montado sobre o Dmg real
// (JV0.3). Esta expressão regular é só a rede de segurança quando o motor não é injetado.
const RE_EXPRESSAO = /^\s*[+-]?\s*(\d+|\d*[dD]\d+)(\s*[+-]\s*(\d+|\d*[dD]\d+))*\s*$/;

export function expressaoBasicaValida(expr) {
  return typeof expr === 'string' && RE_EXPRESSAO.test(expr);
}

function expressoesDaFicha(f) {
  const lista = [];
  if (f.testes && typeof f.testes === 'object') {
    for (const [k, v] of Object.entries(f.testes)) lista.push([`testes.${k}`, v]);
  }
  if (typeof f.expressaoForca === 'string') lista.push(['expressaoForca', f.expressaoForca]);
  if (typeof f.expressaoCura === 'string') lista.push(['expressaoCura', f.expressaoCura]);
  if (f.contraAtaque && typeof f.contraAtaque.expressaoAtaque === 'string') {
    lista.push(['contraAtaque.expressaoAtaque', f.contraAtaque.expressaoAtaque]);
  }
  (Array.isArray(f.tecnicas) ? f.tecnicas : []).forEach((t, i) => {
    if (!t || typeof t !== 'object') return;
    const base = `tecnicas[${i}]`;
    for (const c of ['expressaoAtaque', 'expressaoDano', 'expressaoCura']) {
      if (typeof t[c] === 'string') lista.push([`${base}.${c}`, t[c]]);
    }
    (Array.isArray(t.componentes) ? t.componentes : []).forEach((c, j) => {
      if (c && typeof c.expressao === 'string') lista.push([`${base}.componentes[${j}].expressao`, c.expressao]);
    });
    (Array.isArray(t.reparticao) ? t.reparticao : []).forEach((e, j) => {
      if (typeof e === 'string') lista.push([`${base}.reparticao[${j}]`, e]);
    });
  });
  return lista;
}

function tiposDaTecnica(t) {
  if (Array.isArray(t.tipos)) return t.tipos;
  if (typeof t.tipo === 'string') return [t.tipo];
  if (Array.isArray(t.componentes)) return t.componentes.filter((c) => c && c.tipo).map((c) => c.tipo);
  return [];
}

// ---------------------------------------------------------------------------
// Regras extra (o que o schema não cobre)
// ---------------------------------------------------------------------------

function regrasExtraDaFicha(f, erros, avisos, verificarExpressao) {
  // E4: pelo menos um dos dois, `ca` ou `defesaAplicavel.valor`.
  const temCa = Number.isInteger(f.ca);
  const temDefesa = f.defesaAplicavel && Number.isInteger(f.defesaAplicavel.valor);
  if (!temCa && !temDefesa) erros.push({ campo: 'ca', motivo: 'em falta: precisa de ca ou defesaAplicavel.valor' });

  const tecnicas = Array.isArray(f.tecnicas) ? f.tecnicas.filter((t) => t && typeof t === 'object') : [];

  // E7: testes.ataque só é obrigatório se alguma técnica não tiver expressaoAtaque.
  const todasComAtaque = tecnicas.length > 0 && tecnicas.every((t) => typeof t.expressaoAtaque === 'string');
  if (!todasComAtaque && f.testes && typeof f.testes === 'object' && emFalta(f.testes, 'ataque')) {
    erros.push({ campo: 'testes.ataque', motivo: 'em falta (há técnica sem expressaoAtaque)' });
  }

  // Ids de técnica únicos dentro da ficha.
  const vistos = new Set();
  tecnicas.forEach((t, i) => {
    if (typeof t.id !== 'string') return;
    if (vistos.has(t.id)) erros.push({ campo: `tecnicas[${i}].id`, motivo: `id repetido: ${t.id}` });
    vistos.add(t.id);
  });

  tecnicas.forEach((t, i) => {
    const base = `tecnicas[${i}]`;
    // E3: `tipos` ou `tipo`; se vierem os dois e divergirem, recusa.
    if (Array.isArray(t.tipos) && typeof t.tipo === 'string') {
      if (!(t.tipos.length === 1 && t.tipos[0] === t.tipo)) {
        erros.push({ campo: `${base}.tipo`, motivo: 'tipo e tipos divergem' });
      }
    }
    // E3: reparticao tem o mesmo comprimento de tipos.
    if (Array.isArray(t.reparticao)) {
      if (!Array.isArray(t.tipos)) erros.push({ campo: `${base}.reparticao`, motivo: 'reparticao sem tipos' });
      else if (t.reparticao.length !== t.tipos.length) {
        erros.push({ campo: `${base}.reparticao`, motivo: 'reparticao e tipos têm comprimentos diferentes' });
      }
    }
    // Componentes vazios não dão dano.
    if (Array.isArray(t.componentes) && t.componentes.length === 0 && emFalta(t, 'expressaoDano')) {
      erros.push({ campo: `${base}.componentes`, motivo: 'vazio e sem expressaoDano: a técnica não dá dano' });
    }
  });

  // E6: RD geral > 0 junto com porTipo[t] > 0 → RD_EMPILHAMENTO_SEM_DECISAO no motor.
  if (f.rd && typeof f.rd === 'object' && Number.isInteger(f.rd.geral) && f.rd.porTipo && typeof f.rd.porTipo === 'object') {
    const algumPorTipo = Object.values(f.rd.porTipo).some((v) => Number.isInteger(v) && v > 0);
    if (f.rd.geral > 0 && algumPorTipo) {
      erros.push({ campo: 'rd', motivo: 'rd.geral e rd.porTipo ativos ao mesmo tempo (RD_EMPILHAMENTO_SEM_DECISAO)' });
    }
  }

  // Expressões analisáveis.
  for (const [campo, expr] of expressoesDaFicha(f)) {
    let ok;
    try {
      ok = verificarExpressao ? verificarExpressao(expr) === true : expressaoBasicaValida(expr);
    } catch {
      ok = false;
    }
    if (!ok) erros.push({ campo, motivo: 'expressão não analisável' });
  }
}

function regrasDoConjunto(fichas, nomes, erros, avisos) {
  // Ids únicos no pacote.
  const vistos = new Map();
  fichas.forEach((f, i) => {
    if (!f || typeof f.id !== 'string') return;
    if (vistos.has(f.id)) erros.push({ arquivo: nomes[i], campo: 'id', motivo: `id repetido (também em ${vistos.get(f.id)})` });
    else vistos.set(f.id, nomes[i]);
  });

  // Todos os tipos de dano das técnicas do pacote.
  const tiposConhecidos = new Set();
  let haTecnicaMultiTipo = false;
  for (const f of fichas) {
    for (const t of Array.isArray(f?.tecnicas) ? f.tecnicas : []) {
      if (!t || typeof t !== 'object') continue;
      const tipos = tiposDaTecnica(t);
      tipos.forEach((x) => tiposConhecidos.add(x));
      if (tipos.length > 1) haTecnicaMultiTipo = true;
    }
  }

  fichas.forEach((f, i) => {
    const porTipo = f?.rd?.porTipo;
    if (porTipo && typeof porTipo === 'object') {
      // E6: as chaves de porTipo coincidem à letra com os `tipo` das técnicas.
      for (const chave of Object.keys(porTipo)) {
        if (!tiposConhecidos.has(chave)) {
          erros.push({ arquivo: nomes[i], campo: `rd.porTipo.${chave}`, motivo: 'tipo que nenhuma técnica usa (confira a grafia)' });
        }
      }
    }
    // E6: aviso RD_SEM_DISTRIBUICAO_POR_TIPO.
    const rdAtiva = f?.rd && ((f.rd.geral ?? 0) > 0 || Object.values(f.rd.porTipo ?? {}).some((v) => v > 0));
    if (rdAtiva && haTecnicaMultiTipo) {
      avisos.push({ arquivo: nomes[i], campo: 'rd', motivo: 'RD ativa e há técnicas com mais de um tipo (RD_SEM_DISTRIBUICAO_POR_TIPO)' });
    }
  });
}

// ---------------------------------------------------------------------------
// API
// ---------------------------------------------------------------------------

/**
 * Valida e congela uma lista de fichas.
 * @param {Array|{formato:string,fichas:Array}} entrada
 * @param {{nomesArquivo?:string[], verificarExpressao?:(e:string)=>boolean}} [opcoes]
 * @returns {{ok:true, fichas:Object, lista:Array, avisos:Array} | {ok:false, erros:Array, avisos:Array}}
 */
export function carregarFichas(entrada, opcoes = {}) {
  const erros = [];
  const avisos = [];
  let lista = entrada;
  if (entrada && !Array.isArray(entrada) && typeof entrada === 'object') {
    if (entrada.formato !== undefined && entrada.formato !== FORMATO_FICHAS) {
      return { ok: false, erros: [{ arquivo: '(entrada)', campo: 'formato', motivo: 'formato desconhecido' }], avisos };
    }
    lista = entrada.fichas;
  }
  if (!Array.isArray(lista) || lista.length === 0) {
    return { ok: false, erros: [{ arquivo: '(entrada)', campo: 'fichas', motivo: 'em falta ou vazio' }], avisos };
  }
  // Cópia: não congelamos o objeto do chamador, e garantimos JSON puro.
  let copia;
  try {
    copia = clonarJson(lista);
  } catch {
    return { ok: false, erros: [{ arquivo: '(entrada)', campo: 'fichas', motivo: 'não é JSON puro' }], avisos };
  }
  const nomes = copia.map((_, i) => opcoes.nomesArquivo?.[i] ?? `fichas[${i}]`);

  copia.forEach((f, i) => {
    const errosFicha = [];
    const avisosFicha = [];
    validarSchema(SCHEMA_FICHAS_1, f, '', errosFicha, avisosFicha);
    if (f && typeof f === 'object' && !Array.isArray(f)) {
      regrasExtraDaFicha(f, errosFicha, avisosFicha, opcoes.verificarExpressao);
    }
    for (const e of errosFicha) erros.push({ arquivo: nomes[i], ...e });
    for (const a of avisosFicha) avisos.push({ arquivo: nomes[i], ...a });
  });
  if (erros.length === 0) regrasDoConjunto(copia, nomes, erros, avisos);
  if (erros.length > 0) return { ok: false, erros, avisos };

  const mapa = {};
  for (const f of copia) mapa[f.id] = f;
  congelarProfundo(copia);
  congelarProfundo(mapa);
  return { ok: true, fichas: mapa, lista: copia, avisos };
}

const descodificador = new TextDecoder();

/**
 * Carrega o pacote privado do Mestre.
 * @param {{pacote:Object, arquivos:Object<string,string|Uint8Array>, hashHex?:Function, verificarExpressao?:Function}} p
 *   pacote = conteúdo de PACOTE.json: {formato:"fichas/1", criadoEm, autor, sha256:{"fichas/x.json":"<hex>", ...}}
 *   arquivos = {"fichas/x.json": bytes ou texto, "ambiente.json": ...}
 */
export function carregarPacote({ pacote, arquivos, hashHex = sha256Hex, verificarExpressao } = {}) {
  const erros = [];
  if (!pacote || typeof pacote !== 'object') {
    return { ok: false, erros: [{ arquivo: 'PACOTE.json', campo: '(raiz)', motivo: 'em falta' }], avisos: [] };
  }
  if (pacote.formato !== FORMATO_FICHAS) {
    return { ok: false, erros: [{ arquivo: 'PACOTE.json', campo: 'formato', motivo: 'formato desconhecido' }], avisos: [] };
  }
  const listados = pacote.sha256;
  if (!listados || typeof listados !== 'object' || Array.isArray(listados)) {
    return { ok: false, erros: [{ arquivo: 'PACOTE.json', campo: 'sha256', motivo: 'em falta' }], avisos: [] };
  }
  const presentes = arquivos && typeof arquivos === 'object' ? arquivos : {};
  for (const [caminho, esperado] of Object.entries(listados)) {
    if (!(caminho in presentes)) {
      erros.push({ arquivo: caminho, campo: '(arquivo)', motivo: 'em falta no pacote' });
      continue;
    }
    if (typeof esperado !== 'string' || hashHex(presentes[caminho]) !== esperado.toLowerCase()) {
      erros.push({ arquivo: caminho, campo: '(sha256)', motivo: 'SHA-256 não bate com o PACOTE.json' });
    }
  }
  for (const caminho of Object.keys(presentes)) {
    if (!(caminho in listados)) erros.push({ arquivo: caminho, campo: '(arquivo)', motivo: 'não listado no PACOTE.json' });
  }
  if (erros.length) return { ok: false, erros, avisos: [] };

  const fichas = [];
  const nomes = [];
  let ambiente = null;
  for (const caminho of Object.keys(presentes).sort()) {
    const bruto = presentes[caminho];
    const texto = typeof bruto === 'string' ? bruto : descodificador.decode(bruto);
    let json;
    try {
      json = JSON.parse(texto);
    } catch {
      erros.push({ arquivo: caminho, campo: '(json)', motivo: 'JSON inválido' });
      continue;
    }
    if (caminho === 'ambiente.json') ambiente = json; // TODO(JV1.x): schema do ambiente.json (raio, fogo...)
    else if (/^fichas\/[^/]+\.json$/.test(caminho)) {
      fichas.push(json);
      nomes.push(caminho);
    } else erros.push({ arquivo: caminho, campo: '(arquivo)', motivo: 'arquivo inesperado no pacote' });
  }
  if (erros.length) return { ok: false, erros, avisos: [] };
  const r = carregarFichas(fichas, { nomesArquivo: nomes, verificarExpressao });
  if (!r.ok) return r;
  return { ...r, ambiente: congelarProfundo(ambiente) };
}
