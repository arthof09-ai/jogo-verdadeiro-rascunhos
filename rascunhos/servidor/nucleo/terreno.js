// terreno.js — Ordem 44 (parte A): o TERRENO DO MAPA no servidor.
//
// O servidor passa a conhecer o relevo e os obstáculos do mapa da floresta, casa a casa. Os números NÃO se
// escrevem aqui nem à mão: vêm do pacote `dados/terreno-floresta.json`, que o cliente gera com as mesmas funções
// com que desenha (cliente/cenas/arena/ferramentas/exportar_terreno.gd → assentamento.gd, Relevo, grelha do mapa).
// Uma só fonte de verdade: o cliente desenha, o exportador escreve, o servidor lê.
//
// O pacote tem uma grelha por tamanho e escala (largura × altura × casaM). Por casa (linha a linha, de cima para
// baixo, x a crescer para leste):
//   alturaM     altura do relevo no centro da casa (m)
//   peM         altura da base de uma figura nessa casa (m; a base inclinada da Ordem 44, parte B)
//   bloqueadas  1 = a casa não se pisa nem se ocupa (menir, santuário, rocha, tronco, água funda, escarpa…)
//   cobertura   0 nenhuma, 1 meia, 2 total
//   motivos     "x,y" → o que bloqueia
//
// O núcleo não importa node:* (o adaptador lê o ficheiro e passa o objecto já lido).

const FORMATO = 'terreno/1';

function erro(texto) {
  return new TypeError('terreno: ' + texto);
}

function conferirGrelha(g, i) {
  const onde = `grelhas[${i}]`;
  if (!g || typeof g !== 'object') throw erro(`${onde} não é um objecto`);
  const { largura, altura, casaM } = g;
  if (!Number.isInteger(largura) || largura < 1 || !Number.isInteger(altura) || altura < 1) throw erro(`${onde}: largura/altura inválidas`);
  if (typeof casaM !== 'number' || !(casaM > 0)) throw erro(`${onde}: casaM inválida`);
  const n = largura * altura;
  for (const campo of ['alturaM', 'peM', 'bloqueadas', 'cobertura']) {
    if (!Array.isArray(g[campo]) || g[campo].length !== n) throw erro(`${onde}.${campo} tem de ter ${n} casas`);
  }
  for (const campo of ['alturaM', 'peM']) {
    if (!g[campo].every((v) => typeof v === 'number' && Number.isFinite(v))) throw erro(`${onde}.${campo}: número inválido`);
  }
  if (!g.bloqueadas.every((v) => v === 0 || v === 1)) throw erro(`${onde}.bloqueadas: só 0 ou 1`);
  if (!g.cobertura.every((v) => v === 0 || v === 1 || v === 2)) throw erro(`${onde}.cobertura: só 0, 1 ou 2`);
  const motivos = g.motivos && typeof g.motivos === 'object' ? g.motivos : {};
  for (let k = 0; k < n; k++) {
    const chave = `${k % largura},${Math.floor(k / largura)}`;
    if (g.bloqueadas[k] === 1 && typeof motivos[chave] !== 'string') throw erro(`${onde}: casa ${chave} bloqueada sem motivo`);
  }
}

/** Mesma escala (as escalas valem 1 / 1,5 / 2 m; a comparação aceita o arredondamento do JSON). */
function mesmaEscala(a, b) {
  return Math.abs(a - b) < 1e-9;
}

/**
 * Prepara o pacote do terreno (o objecto lido de dados/terreno-floresta.json). Falha fechado: um pacote com forma
 * desconhecida lança TypeError (a sala não abre com um terreno a meias).
 * Devolve { formato, mapa, fontes, grelhas: [{largura, altura, casaM}], para(largura, altura, casaM) → grelha | null }.
 */
export function prepararTerreno(pacote) {
  if (!pacote || typeof pacote !== 'object') throw erro('pacote em falta');
  const cab = pacote.cabecalho;
  if (!cab || cab.formato !== FORMATO) throw erro(`formato desconhecido (esperado ${FORMATO})`);
  if (!Array.isArray(pacote.grelhas) || !pacote.grelhas.length) throw erro('sem grelhas');
  pacote.grelhas.forEach(conferirGrelha);
  const grelhas = pacote.grelhas.map((g) => Object.freeze(criarGrelha(g)));
  return Object.freeze({
    formato: cab.formato,
    mapa: typeof cab.mapa === 'string' ? cab.mapa : null,
    fontes: Object.freeze({ ...(cab.fontes ?? {}) }),
    grelhas: Object.freeze(grelhas.map((g) => Object.freeze({ largura: g.largura, altura: g.altura, casaM: g.casaM }))),
    /** A grelha deste tamanho e escala, ou null se o pacote não a tem. */
    para(largura, altura, casaM) {
      return grelhas.find((g) => g.largura === largura && g.altura === altura && mesmaEscala(g.casaM, casaM)) ?? null;
    },
  });
}

function criarGrelha(g) {
  const { largura, altura, casaM } = g;
  const alturaM = Float64Array.from(g.alturaM);
  const peM = Float64Array.from(g.peM);
  const bloq = Uint8Array.from(g.bloqueadas);
  const cob = Uint8Array.from(g.cobertura);
  const motivos = Object.freeze({ ...(g.motivos ?? {}) });
  const origemM = Array.isArray(g.origemM) ? Object.freeze(g.origemM.slice(0, 2)) : null;
  const indice = (x, y) => (Number.isInteger(x) && Number.isInteger(y) && x >= 0 && y >= 0 && x < largura && y < altura ? y * largura + x : -1);
  return {
    largura, altura, casaM, origemM,
    alturaM: (x, y) => { const k = indice(x, y); return k < 0 ? null : alturaM[k]; },
    peM: (x, y) => { const k = indice(x, y); return k < 0 ? null : peM[k]; },
    bloqueada: (x, y) => { const k = indice(x, y); return k >= 0 && bloq[k] === 1; },
    motivo: (x, y) => (indice(x, y) >= 0 ? motivos[`${x},${y}`] ?? null : null),
    cobertura: (x, y) => { const k = indice(x, y); return k < 0 ? 0 : cob[k]; },
    casasBloqueadas: () => bloq.reduce((a, v) => a + v, 0),
  };
}
