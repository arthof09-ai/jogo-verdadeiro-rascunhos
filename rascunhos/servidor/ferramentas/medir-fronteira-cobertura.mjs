// medir-fronteira-cobertura.mjs — Ordem 59. Mede a COBERTURA que o SERVIDOR serve na faixa da borda, separando os
// lados da zona que estão na FRONTEIRA DO MAPA dos que estão no interior dele.
//
//   node ferramentas/medir-fronteira-cobertura.mjs [--json=caminho]
//
// Para cada grelha corre o servidor de verdade (ferramentas/juizo-terreno.mjs: núcleo sala.js com o pacote
// dados/terreno-floresta.json) e conta, casa a casa do juízo:
//   faixa            casas cuja casa do mapa tem o centro a bordaCoberturaM ou menos de algum lado da zona;
//   faixaFronteira   … em que TODOS os lados a essa distância estão na fronteira do mapa (lado «fechado»: entre ele e
//                    a fronteira não cabe nada que dê cobertura e mude com a zona, ver nucleo/terreno.js);
//   faixaInterior    … em que algum desses lados está no interior do mapa (lado «aberto»);
//   nulas*           as que o servidor devolve com cobertura null, em cada uma dessas partes;
//   sha256           o SHA-256 do JSON do juízo inteiro (alturas, pés, bloqueio, motivo, cobertura), para comparar
//                    duas versões do servidor grelha a grelha.
// Um lado está fechado se a folga entre ele e a fronteira do mapa é de no máximo folgaFonteCoberturaM (do cabeçalho
// do pacote; um pacote anterior à Ordem 59 não o tem e a medição usa 0,70 m, o mesmo número).
// Só fichas fictícias (as dos testes); nada do Mestre real.
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { prepararTerreno } from '../nucleo/terreno.js';

const PACOTE = JSON.parse(readFileSync(new URL('../dados/terreno-floresta.json', import.meta.url), 'utf8'));
const CAB = PACOTE.cabecalho;
const FOLGA = typeof CAB.folgaFonteCoberturaM === 'number' ? CAB.folgaFonteCoberturaM : 0.7;
const T = prepararTerreno(PACOTE);
const JUIZO = fileURLToPath(new URL('./juizo-terreno.mjs', import.meta.url));

/** [largura, altura, casaM]: as 12 grelhas da prova da Ordem 48 e as que tocam a fronteira do mapa. */
export const GRELHAS = [
  [30, 30, 1.5], [30, 30, 2], [20, 20, 1.5], [25, 25, 1.5], [25, 25, 1], [25, 25, 2], [21, 17, 1], [33, 27, 2],
  [44, 20, 1.5], [50, 50, 1.5], [50, 50, 1], [37, 37, 2],
  [49, 49, 1.5], [50, 20, 1.5], [20, 50, 1.5], [49, 30, 1.5], [37, 20, 2], [20, 37, 2], [36, 36, 2], [48, 48, 1.5],
  [35, 37, 2],
];

/** As folgas (m) entre cada lado da zona e a fronteira do mapa: [oeste, este, norte, sul]. */
export function folgas(g) {
  const m = CAB.casasDoMapa;
  const fim = [m.origemM[0] + m.lado * m.casaM, m.origemM[1] + m.lado * m.casaM];
  const [ox, oz] = g.origemM;
  return [ox - m.origemM[0], fim[0] - (ox + g.largura * g.casaM), oz - m.origemM[1], fim[1] - (oz + g.altura * g.casaM)];
}

function medir([l, a, s]) {
  const args = [JUIZO, String(l), String(a)];
  if (s !== 1.5) args.push(`--escala=${s}`);
  const texto = execFileSync(process.execPath, args, { encoding: 'utf8', maxBuffer: 1 << 28 });
  const linhas = texto.trim().split('\n');
  const saida = JSON.parse(linhas[linhas.length - 1]);
  const j = saida.juizo;
  const g = T.para(l, a, s);
  const fol = folgas(g);
  const fechado = fol.map((f) => f <= FOLGA);
  const borda = CAB.bordaCoberturaM;
  const m = CAB.casasDoMapa;
  const r = {
    grelha: `${l}x${a}@${s}`, largura: l, altura: a, casaM: s, origemM: [...g.origemM], folgasM: fol,
    ladosNaFronteira: ['oeste', 'este', 'norte', 'sul'].filter((_, i) => fechado[i]),
    casas: j.casas.length, faixa: 0, faixaFronteira: 0, faixaInterior: 0, nulas: 0, nulasFronteira: 0, nulasInterior: 0,
    nulasForaDaFaixa: 0, cobertura: { 0: 0, 1: 0, 2: 0, null: 0 },
    sha256: createHash('sha256').update(JSON.stringify(j)).digest('hex'),
  };
  for (const c of j.casas) {
    const cm = g.casaDoMapa(c.x, c.y);
    const mx = m.origemM[0] + (cm.coluna + 0.5) * m.casaM;
    const mz = m.origemM[1] + (cm.linha + 0.5) * m.casaM;
    const [ox, oz] = g.origemM;
    const d = [mx - ox, ox + l * s - mx, mz - oz, oz + a * s - mz];
    const perto = d.map((v) => v <= borda);
    const naFaixa = perto.some(Boolean);
    const soFronteira = naFaixa && perto.every((p, i) => !p || fechado[i]);
    r.cobertura[c.cobertura === null ? 'null' : c.cobertura] += 1;
    if (naFaixa) {
      r.faixa += 1;
      r[soFronteira ? 'faixaFronteira' : 'faixaInterior'] += 1;
    }
    if (c.cobertura === null) {
      r.nulas += 1;
      if (!naFaixa) r.nulasForaDaFaixa += 1;
      else r[soFronteira ? 'nulasFronteira' : 'nulasInterior'] += 1;
    }
  }
  return r;
}

const resultados = GRELHAS.map(medir);
for (const r of resultados) {
  console.log(`${r.grelha.padEnd(11)} fronteira [${r.ladosNaFronteira.join(',') || '-'}] casas ${r.casas}; faixa ${r.faixa}`
    + ` (fronteira ${r.faixaFronteira}, interior ${r.faixaInterior}); null ${r.nulas} (fronteira ${r.nulasFronteira},`
    + ` interior ${r.nulasInterior}, fora da faixa ${r.nulasForaDaFaixa}); ${r.sha256.slice(0, 12)}`);
}
const tot = (k) => resultados.reduce((s, r) => s + r[k], 0);
console.log(`total: ${resultados.length} grelhas; null na faixa da fronteira ${tot('nulasFronteira')}, no interior ${tot('nulasInterior')}, fora da faixa ${tot('nulasForaDaFaixa')}`);
const json = process.argv.find((x) => x.startsWith('--json='))?.slice(7);
if (json) {
  writeFileSync(json, JSON.stringify({
    ordem: 59, ferramenta: 'servidor/ferramentas/medir-fronteira-cobertura.mjs', bordaCoberturaM: CAB.bordaCoberturaM,
    folgaFonteCoberturaM: FOLGA, folgaNoPacote: typeof CAB.folgaFonteCoberturaM === 'number',
    fontesDoPacote: CAB.fontes, grelhas: resultados,
  }, null, 1) + '\n');
}
