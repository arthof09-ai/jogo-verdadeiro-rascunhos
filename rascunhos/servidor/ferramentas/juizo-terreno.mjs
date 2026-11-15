// juizo-terreno.mjs — Ordens 44 (parte A) e 48. O que o SERVIDOR julga do terreno, para a prova do cliente comparar
// com o que a arena desenha (cliente/cenas/arena/ferramentas/provar_terreno_servidor.gd).
//
//   node ferramentas/juizo-terreno.mjs <largura> <altura> [--heroina=x,y] [--figuras=x,y;x,y;...] [--escala=2]
//
// Abre uma sala de verdade (núcleo sala.js, motor falso, fichas fictícias dos testes) com o pacote do terreno
// (dados/terreno-floresta.json), entra o Mestre e a heroína, começa o combate e o Mestre coloca uma criatura em cada
// casa pedida (MASTER_PLACE: o servidor aceita ou recusa). Escreve em JSON, no stdout:
//   juizo     por casa: alturaM, peM, passavel, motivo, cobertura (sala.depuracao.juizoTerreno)
//   figuras   as figuras colocadas, onde o servidor as pôs (x, y) e com que pé (peM da casa)
//   recusas   as casas que o servidor recusou, com o porquê que vai ao Mestre
//   mover     as casas que o servidor oferece à heroína (ROOM_OPTIONS.mover)
// Ordem 48: qualquer tamanho que caiba no mapa (a sala recorta a grelha do mapa inteiro). A sala nasce com casas de
// 1,5 m: um tamanho que não caiba nessa escala não abre (o erro nomeado sai no stderr, código ≠ 0). Na faixa da borda
// a cobertura pode vir null (o servidor não a afirma: ver nucleo/terreno.js) — desde a Ordem 59, só nos lados da
// zona que não estão na fronteira do mapa.
// Só fichas fictícias; nada do Mestre real.
import { readFileSync } from 'node:fs';
import { montarMesa, recibo } from '../testes/ajudantes.mjs';

const [largura, altura] = process.argv.slice(2, 4).map(Number);
const opcao = (nome) => process.argv.find((a) => a.startsWith(`--${nome}=`))?.slice(nome.length + 3) ?? null;
const casa = (t) => { const [x, y] = t.split(',').map(Number); return { x, y }; };
const terreno = JSON.parse(readFileSync(new URL('../dados/terreno-floresta.json', import.meta.url), 'utf8'));

const m = montarMesa({ terreno, mapa: { largura, altura }, casas: { heroina: casa(opcao('heroina') ?? '2,2') } });
m.entrarTodos();
const pedidas = (opcao('figuras') ?? '').split(';').filter(Boolean).map(casa);
m.iniciarCombate([]);
if (opcao('escala')) m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM: Number(opcao('escala')) });
const recusas = [];
for (const c of pedidas) {
  const r = recibo(m.mestre('MASTER_PLACE', { fichaId: 'orc-teste', casa: c }));
  if (r?.type !== 'ROOM_RECEIPT') {
    const porque = m.sala.depuracao.eventos().filter((e) => e.tipo === 'recusa').map((e) => JSON.stringify(e)).pop() ?? '';
    recusas.push({ ...c, detalhe: (porque.match(/CASA_BLOQUEADA[^"]*/) ?? [null])[0] });
  }
}
const juizo = m.sala.depuracao.juizoTerreno();
const est = m.sala.depuracao.estado();
// Cada altura vai também em BITS (o double IEEE-754, 8 bytes little-endian em hexadecimal: alturaBits, peBits). O
// analisador de JSON do Godot nem sempre devolve o double exacto do texto (erros de 1e-16) e a prova compara bit a bit.
const bits = (v) => {
  if (typeof v !== 'number') return null;
  const d = new DataView(new ArrayBuffer(8));
  d.setFloat64(0, v, true);
  return [...new Uint8Array(d.buffer)].map((b) => b.toString(16).padStart(2, '0')).join('');
};
if (juizo) for (const c of juizo.casas) Object.assign(c, { alturaBits: bits(c.alturaM), peBits: bits(c.peM) });
const peDe = (x, y) => juizo?.casas[y * juizo.largura + x]?.peM ?? null;
const figuras = Object.values(est.figuras).filter((f) => f.colocada)
  .map((f) => ({ id: f.id, lado: f.lado, x: f.x, y: f.y, peM: peDe(f.x, f.y), peBits: bits(peDe(f.x, f.y)) }));
const mover = m.sala.depuracao.opcoes(m.clientes.heroina.figuraId).mover;
// O JSON sai só em ASCII (os acentos em \uXXXX): no Windows o stdout do Node chega ao Godot sem descodificar como UTF-8.
const ascii = (t) => t.replace(/[\u0080-￿]/g, (c) => `\\u${c.charCodeAt(0).toString(16).padStart(4, '0')}`);
process.stdout.write(ascii(JSON.stringify({ mapa: est.mapa, juizo, figuras, recusas, mover })) + '\n');
