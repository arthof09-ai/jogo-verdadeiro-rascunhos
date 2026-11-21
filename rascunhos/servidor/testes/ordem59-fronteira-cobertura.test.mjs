// Ordem 59: a cobertura na faixa da FRONTEIRA DO MAPA julga-se com a régua do interior.
// Reserva da Ordem 48: na faixa da borda (1,35 m) o servidor calava (null) toda a cobertura abaixo de 2, também nos
// lados da zona encostados à fronteira do mapa — onde não há nada lá fora que dê cobertura (as fontes só contam dentro
// do mapa e só sobrevivem a mais de folgaFonteCoberturaM fora da zona: ver exportar_terreno.gd). Agora a faixa é só a
// dos lados ABERTOS; junto à fronteira serve-se a cobertura do mapa. A prova cliente↔servidor (cliente desenha, servidor
// julga) é a do cliente: cliente/cenas/arena/ferramentas/provar_terreno_servidor.gd; a medição antes/depois é
// ferramentas/medir-fronteira-cobertura.mjs.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { prepararTerreno } from '../nucleo/terreno.js';
import { montarMesa } from './ajudantes.mjs';

const PACOTE = JSON.parse(readFileSync(new URL('../dados/terreno-floresta.json', import.meta.url), 'utf8'));
const T = prepararTerreno(PACOTE);
const CAB = PACOTE.cabecalho;
const M = CAB.casasDoMapa;
/** O mesmo pacote com outro cabeçalho (o resto partilhado: prepararTerreno não o muda). */
const comCabecalho = (mudar) => {
  const cab = { ...CAB };
  mudar(cab);
  return { ...PACOTE, cabecalho: cab };
};
/** A cobertura do mapa de referência debaixo da casa (x, y) da grelha `g`. */
const doMapa = (g, x, y) => { const k = g.casaDoMapa(x, y); return PACOTE.mapa.cobertura[k.linha * M.lado + k.coluna]; };
/** As distâncias [oeste, este, norte, sul] do centro da casa do mapa debaixo de (x, y) aos lados da zona de `g`. */
const distancias = (g, x, y) => {
  const k = g.casaDoMapa(x, y);
  const mx = M.origemM[0] + (k.coluna + 0.5) * M.casaM;
  const mz = M.origemM[1] + (k.linha + 0.5) * M.casaM;
  const [ox, oz] = g.origemM;
  return [mx - ox, ox + g.largura * g.casaM - mx, mz - oz, oz + g.altura * g.casaM - mz];
};
const LADOS = ['oeste', 'este', 'norte', 'sul'];

test('o pacote diz até que folga um lado da zona está na fronteira (0,70 m, do exportador)', () => {
  assert.equal(CAB.folgaFonteCoberturaM, 0.7);
  assert.equal(CAB.bordaCoberturaM, 1.35);
});

test('50 × 50 de 1,5 m (o mapa inteiro, os quatro lados na fronteira): nenhuma casa sem cobertura, toda a do mapa', () => {
  const g = T.para(50, 50, 1.5);
  assert.deepEqual([...g.ladosNaFronteira], LADOS);
  for (let y = 0; y < 50; y++) for (let x = 0; x < 50; x++) assert.equal(g.cobertura(x, y), doMapa(g, x, y), `(${x},${y})`);
  // o juízo da sala (o que vai ao Mestre e à prova) leva o mesmo
  const m = montarMesa({ terreno: PACOTE, mapa: { largura: 50, altura: 50 } });
  m.entrarTodos();
  const j = m.sala.depuracao.juizoTerreno();
  assert.equal(j.casas.length, 2500);
  assert.equal(j.casas.filter((c) => c.cobertura === null).length, 0);
});

for (const [l, a, s, fronteira, nulasFronteiraAntes] of [
  [49, 30, 1.5, ['este'], 28], [50, 20, 1.5, ['oeste', 'este'], 36], [49, 49, 1.5, ['este', 'sul'], 95],
  [37, 20, 2, ['oeste', 'este'], 18], [35, 37, 2, ['norte', 'sul'], 33], [37, 37, 2, LADOS, 73],
]) {
  test(`${l} × ${a} de ${s} m (fronteira a ${fronteira.join(', ')}): a faixa da fronteira serve o mapa; a dos lados abertos fica como estava`, () => {
    const g = T.para(l, a, s);
    assert.deepEqual([...g.ladosNaFronteira], fronteira);
    const antigo = prepararTerreno(comCabecalho((c) => delete c.folgaFonteCoberturaM)).para(l, a, s);
    assert.deepEqual([...antigo.ladosNaFronteira], [], 'um pacote sem a folga não fecha lado nenhum');
    let naFronteira = 0;
    for (let y = 0; y < a; y++) {
      for (let x = 0; x < l; x++) {
        const perto = distancias(g, x, y).map((d) => d <= CAB.bordaCoberturaM);
        const soFronteira = perto.some(Boolean) && perto.every((p, i) => !p || fronteira.includes(LADOS[i]));
        if (soFronteira) {
          naFronteira += 1;
          assert.equal(g.cobertura(x, y), doMapa(g, x, y), `(${x},${y}) na faixa da fronteira: a do mapa`);
          // antes (a regra da Ordem 48) era null aqui, salvo onde o mapa tem cobertura 2 (essa afirmava-se sempre).
          // LAGO-MAIOR: com a floresta devolvida há troncos e rochas na faixa da fronteira — cobertura 2 nalgumas casas.
          assert.equal(antigo.cobertura(x, y), doMapa(g, x, y) === 2 ? 2 : null, `(${x},${y}) antes: null (ou 2, a do mapa)`);
        } else {
          assert.equal(g.cobertura(x, y), antigo.cobertura(x, y), `(${x},${y}) fora da faixa da fronteira: o mesmo juízo`);
        }
      }
    }
    assert.equal(naFronteira, nulasFronteiraAntes);
  });
}

test('as grelhas que não tocam a fronteira julgam-se exactamente como antes', () => {
  const antigo = prepararTerreno(comCabecalho((c) => delete c.folgaFonteCoberturaM));
  for (const [l, a, s] of [[30, 30, 1.5], [30, 30, 2], [20, 20, 1.5], [25, 25, 1], [21, 17, 1], [33, 27, 2], [44, 20, 1.5], [50, 50, 1], [48, 48, 1.5], [36, 36, 2]]) {
    const g = T.para(l, a, s);
    const v = antigo.para(l, a, s);
    assert.deepEqual([...g.ladosNaFronteira], [], `${l}x${a}@${s}`);
    for (let y = 0; y < a; y++) for (let x = 0; x < l; x++) assert.equal(g.cobertura(x, y), v.cobertura(x, y), `${l}x${a}@${s} (${x},${y})`);
  }
});

test('uma folga inválida no pacote não se prepara (falha fechado, com o nome)', () => {
  for (const mau of [-0.1, '0.7', null, Number.NaN]) {
    assert.throws(() => prepararTerreno(comCabecalho((c) => { c.folgaFonteCoberturaM = mau; })), /terreno: cabecalho\.folgaFonteCoberturaM inválida/);
  }
});
