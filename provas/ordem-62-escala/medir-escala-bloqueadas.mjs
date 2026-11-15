// Ordem 62 (medição): quantas figuras ficam em casas bloqueadas depois de o Mestre mudar a escala?
// Correr: node provas/ordem-62-escala/medir-escala-bloqueadas.mjs
// Só lê o servidor (montarMesa dos testes, com o terreno de verdade). Dois caminhos:
//  A) as 6 mudanças de escala (1 / 1,5 / 2 m, de cada uma para cada outra) numa 30 × 30, com uma criatura de 2 em 2
//     casas (o servidor recusa as bloqueadas na colocação) — o caso da sonda da Ordem 58 (1,5 → 2) é um deles;
//  B) a escala muda com as figuras em casas livres, e depois o «Recomeçar» devolve-as às casas onde foram colocadas.
import { readFileSync } from 'node:fs';
const R = new URL('../../rascunhos/servidor/', import.meta.url).href;
const { montarMesa, recibo } = await import(R + 'testes/ajudantes.mjs');
const terreno = JSON.parse(readFileSync(new URL('dados/terreno-floresta.json', R), 'utf8'));

const conta = (m) => {
  const j = m.sala.depuracao.juizoTerreno();
  const fs = Object.values(m.sala.depuracao.estado().figuras).filter((f) => f.colocada);
  const bloq = fs.filter((f) => !j.casas[f.y * j.largura + f.x].passavel);
  return { casaM: j.casaM, figuras: fs.length, emBloqueadas: bloq.length, casas: bloq.map((f) => `(${f.x},${f.y}) ${j.casas[f.y * j.largura + f.x].motivo}`) };
};
const detalhes = (m, desde) => m.sala.depuracao.eventos().slice(desde).filter((e) => e.tipo === 'recusa').map((e) => e.soMestre?.detalhe ?? null);

let total = 0;
console.log('A) mudança de escala numa 30 × 30, uma criatura de 2 em 2 casas');
for (const [de, para] of [[1.5, 2], [1.5, 1], [1, 1.5], [1, 2], [2, 1.5], [2, 1]]) {
  const m = montarMesa({ terreno, mapa: { largura: 30, altura: 30 }, casas: { heroina: { x: 2, y: 2 } } });
  m.entrarTodos();
  m.iniciarCombate([]);
  if (de !== 1.5) { const r0 = recibo(m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM: de })); if (r0?.estado !== 'APLICADA') throw new Error('escala de partida ' + de); }
  for (let y = 0; y < 30; y += 2) for (let x = 0; x < 30; x += 2) m.mestre('MASTER_PLACE', { fichaId: 'orc-teste', casa: { x, y } });
  const antes = conta(m);
  const n = m.sala.depuracao.eventos().length;
  const r = recibo(m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM: para }));
  const depois = conta(m);
  total += depois.emBloqueadas;
  console.log(`  ${de} → ${para} m: ${antes.figuras} figuras, ${antes.emBloqueadas} em casas bloqueadas antes · recibo ${r?.type}${r?.estado ? ' ' + r.estado : ''} · escala viva ${depois.casaM} m · em casas bloqueadas depois: ${depois.emBloqueadas}${depois.casas.length ? ' ' + JSON.stringify(depois.casas) : ''}`);
  for (const d of detalhes(m, n)) console.log('      porquê ao Mestre: ' + d);
}

console.log('B) a escala muda com as figuras em casas livres; depois «Recomeçar»');
{
  // a heroína é colocada em (6,4): livre com 1,5 m, menir com 2 m. Anda uma casa para (7,4) e a escala passa a 2 m.
  const m = montarMesa({ terreno, mapa: { largura: 30, altura: 30 }, casas: { heroina: { x: 6, y: 4 } } });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 20, y: 20 }]]);
  const rm = recibo(m.intencao('heroina', { tipo: 'mover', destino: { x: 7, y: 4 } }));
  const r1 = recibo(m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM: 2 }));
  const meio = conta(m);
  const n = m.sala.depuracao.eventos().length;
  const r2 = recibo(m.mestre('MASTER_SUPERVISOR', { op: 'recomecar' }));
  const depois = conta(m);
  total += depois.emBloqueadas;
  console.log(`  mover (6,4)→(7,4): ${rm?.estado ?? rm?.type} · escala 2 m: ${r1?.estado ?? r1?.type} (em bloqueadas: ${meio.emBloqueadas}) · recomeçar: ${r2?.type}${r2?.estado ? ' ' + r2.estado : ''} · em casas bloqueadas depois: ${depois.emBloqueadas}${depois.casas.length ? ' ' + JSON.stringify(depois.casas) : ''}`);
  for (const d of detalhes(m, n)) console.log('      porquê ao Mestre: ' + d);
}
console.log(`TOTAL de figuras deixadas em casas bloqueadas: ${total}`);
