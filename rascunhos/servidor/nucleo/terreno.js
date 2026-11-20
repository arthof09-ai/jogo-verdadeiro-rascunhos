// terreno.js — Ordens 44 e 48: o TERRENO DO MAPA no servidor, para QUALQUER tamanho de grelha.
//
// O servidor conhece o relevo e os obstáculos do mapa da floresta, casa a casa. Os números NÃO se escrevem aqui nem
// à mão: vêm do pacote `dados/terreno-floresta.json`, que o cliente gera com as mesmas funções com que desenha
// (cliente/cenas/arena/ferramentas/exportar_terreno.gd → assentamento.gd, Relevo, grelha do mapa).
// Uma só fonte de verdade: o cliente desenha, o exportador escreve, o servidor lê e RECORTA.
//
// Ordem 48: o pacote leva o MAPA INTEIRO, não grelhas feitas (formato terreno/2):
//   escalas   por escala (1 / 1,5 / 2 m), a origem no mapa (canto NO) da grelha de 1, 2, 3, … casas de lado — a regra
//             da arena tabelada. Um lado maior do que a tabela não cabe no mapa.
//   redes     as alturas das maiores grelhas que cabem no mapa (uma por escala e por «fase» da origem). Toda a grelha
//             que cabe é um recorte exacto de uma rede: os mesmos centros de casa, os mesmos doubles. Por casa
//             alturaM (o relevo no centro) e peM (a base de uma figura, Ordem 44 parte B), em base64 dos doubles; por
//             coluna e por linha, a casa do mapa (50 × 50 de 1,5 m) que contém o centro.
//   mapa      as 50 × 50 casas do mapa: bloqueadas (0/1), cobertura (0/1/2), motivos ("coluna,linha" → o que bloqueia),
//             lidos do mapa construído para uma zona maior do que ele (nada do que a zona tira chega lá).
// O que bloqueia uma casa DENTRO da zona jogável não depende da zona (ver o exportador): recorta-se. A COBERTURA de uma
// casa perto da borda pode vir de coisas que o cliente planta FORA da zona, e essas dependem da zona: nas casas cuja
// casa do mapa tem o centro a `bordaCoberturaM` ou menos da borda, o servidor só afirma a cobertura total (2: no mapa a
// cobertura só sobe) e, abaixo disso, diz que não sabe (null) — nunca um número errado. Fora da faixa é a do cliente.
//
// Ordem 59: a FRONTEIRA DO MAPA julga-se com a régua do interior. Um lado da zona a `folgaFonteCoberturaM` ou menos da
// fronteira do mapa está FECHADO: o que dá cobertura e muda com a zona só conta dentro do mapa e só sobrevive a mais
// dessa folga fora da zona (ver o exportador), logo desse lado não vem cobertura nenhuma de fora. A faixa da borda é
// só a dos lados ABERTOS: uma casa cujo centro (da casa do mapa) só está perto de lados fechados tem a cobertura do
// mapa, como longe da borda. Um pacote sem `folgaFonteCoberturaM` (anterior à Ordem 59) não fecha lado nenhum: a faixa
// é a de sempre (calar é o lado seguro).
//
// FALHA FECHADO, SEMPRE COM NOME:
//   - um pacote com forma desconhecida não se prepara (TypeError: a sala não abre com um terreno a meias);
//   - uma grelha que o pacote não consegue servir (lado maior do que o mapa, escala sem tabela) NÃO vira «tudo se pisa»:
//     `motivoSemGrelha` diz porquê (TERRENO_GRELHA_FORA_DO_MAPA / TERRENO_ESCALA_SEM_TABELA) e `para` lança esse erro.
//
// O núcleo não importa node:* (o adaptador lê o ficheiro e passa o objecto já lido); o base64 lê-se com `atob`.

const FORMATO = 'terreno/2';
/**
 * ORDEM MAPA-JOGÁVEL (palavra do Mestre, 20/11/2026: «Eu quero que todo o mapa seja jogável» — água incluída): os
 * motivos do pacote que são ÁGUA. O pacote (gerado pelo cliente, preso por SHA) continua a marcar o lago como casas
 * bloqueadas por «água funda» — não se refaz aqui (outra ordem). O servidor lê-as como CASAS DE ÁGUA: entram-se,
 * ocupam-se e atravessam-se; `bloqueada` deixa de as contar e `agua(x, y)` diz que são de água.
 * O custo de entrar na água é o MESMO que em seco (o cânone não tem regra de água: [FALTA] na Passagem da ordem).
 * O cliente tem a mesma lista (campo_da_mesa.gd MOTIVOS_DE_AGUA), amarrada a esta por teste.
 */
export const MOTIVOS_DE_AGUA = Object.freeze(['água funda']);
export const TERRENO_GRELHA_FORA_DO_MAPA = 'TERRENO_GRELHA_FORA_DO_MAPA';
export const TERRENO_ESCALA_SEM_TABELA = 'TERRENO_ESCALA_SEM_TABELA';

function erro(texto) {
  return new TypeError('terreno: ' + texto);
}

/** Mesma escala (as escalas valem 1 / 1,5 / 2 m; a comparação aceita o arredondamento do JSON). */
function mesmaEscala(a, b) {
  return Math.abs(a - b) < 1e-9;
}

/** Os doubles (IEEE-754, little-endian) de um texto base64; null se o texto não for base64 de doubles. */
function doubles(b64) {
  if (typeof b64 !== 'string') return null;
  let bin;
  try {
    bin = atob(b64);
  } catch {
    return null;
  }
  if (bin.length % 8 !== 0) return null;
  const vista = new DataView(new ArrayBuffer(bin.length));
  for (let i = 0; i < bin.length; i++) vista.setUint8(i, bin.charCodeAt(i));
  const r = new Float64Array(bin.length / 8);
  for (let i = 0; i < r.length; i++) r[i] = vista.getFloat64(i * 8, true);
  return r;
}

const inteiroEntre = (v, lo, hi) => Number.isInteger(v) && v >= lo && v < hi;

function prepararMapa(m, cab) {
  const casas = cab.casasDoMapa;
  if (!casas || !Number.isInteger(casas.lado) || casas.lado < 1 || !(casas.casaM > 0) || !Array.isArray(casas.origemM) || casas.origemM.length !== 2) {
    throw erro('cabecalho.casasDoMapa inválido');
  }
  if (!(typeof cab.bordaCoberturaM === 'number' && cab.bordaCoberturaM >= 0)) throw erro('cabecalho.bordaCoberturaM inválida');
  const temFolga = cab.folgaFonteCoberturaM !== undefined;
  if (temFolga && !(typeof cab.folgaFonteCoberturaM === 'number' && cab.folgaFonteCoberturaM >= 0)) {
    throw erro('cabecalho.folgaFonteCoberturaM inválida');
  }
  const lado = casas.lado;
  const n = lado * lado;
  if (!m || typeof m !== 'object' || m.lado !== lado) throw erro(`mapa: tem de ter ${lado} × ${lado} casas`);
  for (const campo of ['bloqueadas', 'cobertura']) {
    if (!Array.isArray(m[campo]) || m[campo].length !== n) throw erro(`mapa.${campo} tem de ter ${n} casas`);
  }
  if (!m.bloqueadas.every((v) => v === 0 || v === 1)) throw erro('mapa.bloqueadas: só 0 ou 1');
  if (!m.cobertura.every((v) => v === 0 || v === 1 || v === 2)) throw erro('mapa.cobertura: só 0, 1 ou 2');
  const motivos = m.motivos && typeof m.motivos === 'object' ? m.motivos : {};
  for (let k = 0; k < n; k++) {
    const chave = `${k % lado},${Math.floor(k / lado)}`;
    if (m.bloqueadas[k] === 1 && typeof motivos[chave] !== 'string') throw erro(`mapa: casa ${chave} bloqueada sem motivo`);
  }
  return Object.freeze({
    lado, casaM: casas.casaM, origemM: Object.freeze([...casas.origemM]), borda: cab.bordaCoberturaM,
    folgaFonte: temFolga ? cab.folgaFonteCoberturaM : null,
    bloq: Uint8Array.from(m.bloqueadas), cob: Uint8Array.from(m.cobertura), motivos: Object.freeze({ ...motivos }),
  });
}

function prepararRede(r, i, lado) {
  const onde = `redes[${i}]`;
  if (!r || typeof r !== 'object') throw erro(`${onde} não é um objecto`);
  const { largura, altura, casaM } = r;
  if (!Number.isInteger(largura) || largura < 1 || !Number.isInteger(altura) || altura < 1) throw erro(`${onde}: largura/altura inválidas`);
  if (typeof casaM !== 'number' || !(casaM > 0)) throw erro(`${onde}: casaM inválida`);
  if (!Array.isArray(r.origemM) || r.origemM.length !== 2 || !r.origemM.every(Number.isFinite)) throw erro(`${onde}: origemM inválida`);
  if (!Array.isArray(r.colunaMapa) || r.colunaMapa.length !== largura || !r.colunaMapa.every((v) => inteiroEntre(v, 0, lado))) {
    throw erro(`${onde}.colunaMapa tem de ter ${largura} casas do mapa`);
  }
  if (!Array.isArray(r.linhaMapa) || r.linhaMapa.length !== altura || !r.linhaMapa.every((v) => inteiroEntre(v, 0, lado))) {
    throw erro(`${onde}.linhaMapa tem de ter ${altura} casas do mapa`);
  }
  const n = largura * altura;
  const campos = {};
  for (const campo of ['alturaM', 'peM']) {
    const v = doubles(r[campo]);
    if (!v || v.length !== n) throw erro(`${onde}.${campo} tem de ter ${n} casas (base64 de doubles)`);
    if (!v.every(Number.isFinite)) throw erro(`${onde}.${campo}: número inválido`);
    campos[campo] = v;
  }
  return Object.freeze({
    largura, altura, casaM, origemM: Object.freeze([...r.origemM]), colunaMapa: Object.freeze([...r.colunaMapa]),
    linhaMapa: Object.freeze([...r.linhaMapa]), alturaM: campos.alturaM, peM: campos.peM,
  });
}

/** Onde uma grelha de `n` casas com origem `o` encaixa na rede (eixo x ou z): o deslocamento em casas, ou -1. */
function encaixe(o, n, oRede, nRede, casaM) {
  const k = (o - oRede) / casaM;
  return Number.isInteger(k) && k >= 0 && k + n <= nRede ? k : -1;
}

/**
 * Prepara o pacote do terreno (o objecto lido de dados/terreno-floresta.json). Falha fechado: um pacote com forma
 * desconhecida lança TypeError (a sala não abre com um terreno a meias) — incluindo um pacote cuja tabela promete uma
 * grelha que nenhuma rede serve.
 * Devolve { formato, mapa, fontes, escalas: [{casaM, ladoMax}], motivoSemGrelha(l, a, casaM) → null | texto,
 *           para(l, a, casaM) → grelha (lança TypeError nomeado se não houver) }.
 */
export function prepararTerreno(pacote) {
  if (!pacote || typeof pacote !== 'object') throw erro('pacote em falta');
  const cab = pacote.cabecalho;
  if (!cab || cab.formato !== FORMATO) throw erro(`formato desconhecido (esperado ${FORMATO})`);
  const mapa = prepararMapa(pacote.mapa, cab);
  if (!Array.isArray(pacote.escalas) || !pacote.escalas.length) throw erro('sem escalas');
  const escalas = pacote.escalas.map((e, i) => {
    if (!e || !(typeof e.casaM === 'number' && e.casaM > 0)) throw erro(`escalas[${i}]: casaM inválida`);
    if (!Array.isArray(e.origensM) || !e.origensM.length || !e.origensM.every(Number.isFinite)) throw erro(`escalas[${i}].origensM inválidas`);
    return Object.freeze({ casaM: e.casaM, origensM: Object.freeze([...e.origensM]) });
  });
  if (!Array.isArray(pacote.redes) || !pacote.redes.length) throw erro('sem redes');
  const redes = pacote.redes.map((r, i) => prepararRede(r, i, mapa.lado));

  const escalaDe = (casaM) => escalas.find((e) => mesmaEscala(e.casaM, casaM)) ?? null;
  /** A rede e o deslocamento onde a grelha encaixa, ou null. */
  function achar(l, a, casaM) {
    const e = escalaDe(casaM);
    if (!e || !Number.isInteger(l) || !Number.isInteger(a) || l < 1 || a < 1 || l > e.origensM.length || a > e.origensM.length) return null;
    const ox = e.origensM[l - 1];
    const oz = e.origensM[a - 1];
    for (const r of redes) {
      if (!mesmaEscala(r.casaM, casaM)) continue;
      const kx = encaixe(ox, l, r.origemM[0], r.largura, r.casaM);
      const kz = encaixe(oz, a, r.origemM[1], r.altura, r.casaM);
      if (kx >= 0 && kz >= 0) return { rede: r, kx, kz, ox, oz, casaM: r.casaM };
    }
    return null;
  }
  function motivoSemGrelha(l, a, casaM) {
    const e = escalaDe(casaM);
    if (!e) {
      return `${TERRENO_ESCALA_SEM_TABELA}: o terreno do mapa não tem a escala de ${casaM} m por casa (tem ${escalas.map((x) => x.casaM).join(' / ')} m)`;
    }
    if (achar(l, a, casaM)) return null;
    const max = e.origensM.length;
    return `${TERRENO_GRELHA_FORA_DO_MAPA}: a grelha ${l}x${a} de ${e.casaM} m não cabe no mapa da floresta`
      + ` (${mapa.lado} x ${mapa.lado} casas de ${mapa.casaM} m); nesta escala cabem até ${max}x${max}`;
  }
  // Falha fechado já ao preparar: cada grelha que a tabela promete (todos os pares de lados) tem de encaixar numa rede.
  for (const e of escalas) {
    const max = e.origensM.length;
    for (let l = 1; l <= max; l++) {
      for (let a = 1; a <= max; a++) if (!achar(l, a, e.casaM)) throw erro(`a grelha ${l}x${a} de ${e.casaM} m não encaixa em nenhuma rede`);
    }
  }

  const feitas = new Map();
  return Object.freeze({
    formato: cab.formato,
    mapa: typeof cab.mapa === 'string' ? cab.mapa : null,
    fontes: Object.freeze({ ...(cab.fontes ?? {}) }),
    escalas: Object.freeze(escalas.map((e) => Object.freeze({ casaM: e.casaM, ladoMax: e.origensM.length }))),
    /** null se o pacote serve esta grelha; senão o porquê, nomeado. */
    motivoSemGrelha,
    /** A grelha deste tamanho e escala, recortada do mapa inteiro. Lança TypeError nomeado se não couber: nunca null. */
    para(l, a, casaM) {
      const chave = `${l}x${a}@${casaM}`;
      if (!feitas.has(chave)) {
        const e = achar(l, a, casaM);
        if (!e) throw erro(motivoSemGrelha(l, a, casaM));
        feitas.set(chave, Object.freeze(recortar(mapa, e, l, a)));
      }
      return feitas.get(chave);
    },
  });
}

/** A grelha viva (l × a) recortada da rede `e.rede` no deslocamento (e.kx, e.kz), com o bloqueio do mapa. */
function recortar(mapa, e, largura, altura) {
  const { rede, kx, kz, ox, oz, casaM } = e;
  const fimX = ox + largura * casaM;
  const fimZ = oz + altura * casaM;
  const indice = (x, y) => (Number.isInteger(x) && Number.isInteger(y) && x >= 0 && y >= 0 && x < largura && y < altura ? (kz + y) * rede.largura + kx + x : -1);
  /** A casa do mapa debaixo do centro da casa (x, y) do jogo, como índice no mapa, ou -1. */
  const casaMapa = (x, y) => (indice(x, y) < 0 ? -1 : rede.linhaMapa[kz + y] * mapa.lado + rede.colunaMapa[kx + x]);
  // ORDEM MAPA-JOGÁVEL: a casa do mapa que o pacote bloqueia por água é uma casa de ÁGUA, que se pisa.
  const deAgua = (k) => k >= 0 && mapa.bloq[k] === 1 && MOTIVOS_DE_AGUA.includes(mapa.motivos[`${k % mapa.lado},${Math.floor(k / mapa.lado)}`]);
  const bloqueada = (x, y) => { const k = casaMapa(x, y); return k >= 0 && mapa.bloq[k] === 1 && !deAgua(k); };
  // Ordem 59: os lados [oeste, este, norte, sul] da zona que estão ABERTOS (com mapa para lá da folga das fontes de
  // cobertura). Os fechados (na fronteira do mapa) não contam para a faixa da borda. Sem folga no pacote: todos abertos.
  const mapaFimX = mapa.origemM[0] + mapa.lado * mapa.casaM;
  const mapaFimZ = mapa.origemM[1] + mapa.lado * mapa.casaM;
  const aberto = [ox - mapa.origemM[0], mapaFimX - fimX, oz - mapa.origemM[1], mapaFimZ - fimZ]
    .map((folga) => mapa.folgaFonte === null || folga > mapa.folgaFonte);
  /** O centro da casa do mapa `k` está a mais de bordaCoberturaM de todos os lados ABERTOS da zona? (cobertura do mapa) */
  const longeDaBorda = (k) => {
    const mx = mapa.origemM[0] + ((k % mapa.lado) + 0.5) * mapa.casaM;
    const mz = mapa.origemM[1] + (Math.floor(k / mapa.lado) + 0.5) * mapa.casaM;
    return [mx - ox, fimX - mx, mz - oz, fimZ - mz].every((d, i) => !aberto[i] || d > mapa.borda);
  };
  let bloqueadas = 0;
  let agua = 0;
  for (let y = 0; y < altura; y++) {
    for (let x = 0; x < largura; x++) {
      bloqueadas += bloqueada(x, y) ? 1 : 0;
      agua += deAgua(casaMapa(x, y)) ? 1 : 0;
    }
  }
  return {
    largura, altura, casaM, origemM: Object.freeze([ox, oz]),
    /** Ordem 59: os lados da zona na fronteira do mapa (não trazem cobertura de fora: a faixa deles julga-se como o interior). */
    ladosNaFronteira: Object.freeze(['oeste', 'este', 'norte', 'sul'].filter((_, i) => !aberto[i])),
    alturaM: (x, y) => { const k = indice(x, y); return k < 0 ? null : rede.alturaM[k]; },
    peM: (x, y) => { const k = indice(x, y); return k < 0 ? null : rede.peM[k]; },
    bloqueada,
    motivo: (x, y) => {
      const k = casaMapa(x, y);
      return k >= 0 && mapa.bloq[k] === 1 && !deAgua(k) ? mapa.motivos[`${k % mapa.lado},${Math.floor(k / mapa.lado)}`] ?? null : null;
    },
    /** ORDEM MAPA-JOGÁVEL: a casa (x, y) do jogo é de água (o lago)? Entra-se nela; false fora da grelha. */
    agua: (x, y) => deAgua(casaMapa(x, y)),
    /**
     * 0 nenhuma, 1 meia, 2 total. Na faixa da borda o que o cliente planta fora da zona pode SUBIR a cobertura (nunca a
     * baixa: no mapa a cobertura só sobe), logo 2 é 2; abaixo de 2 o servidor não sabe: null. null fora da grelha.
     * Ordem 59: a faixa é só a dos lados abertos — junto à fronteira do mapa não há fonte de fora e serve-se o mapa.
     */
    cobertura: (x, y) => {
      const k = casaMapa(x, y);
      if (k < 0) return null;
      return longeDaBorda(k) || mapa.cob[k] === 2 ? mapa.cob[k] : null;
    },
    /** A casa do mapa (coluna, linha) debaixo do centro da casa do jogo, ou null fora da grelha. */
    casaDoMapa: (x, y) => { const k = casaMapa(x, y); return k < 0 ? null : { coluna: k % mapa.lado, linha: Math.floor(k / mapa.lado) }; },
    casasBloqueadas: () => bloqueadas,
    /** ORDEM MAPA-JOGÁVEL: quantas casas desta grelha são de água. */
    casasDeAgua: () => agua,
  };
}
