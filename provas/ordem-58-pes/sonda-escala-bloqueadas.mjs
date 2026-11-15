// Ordem 58 (sonda): a mudança de escala deixa figuras em casas que o terreno bloqueia? Só lê; não muda o servidor.
// Correr: node provas/ordem-58-pes/sonda-escala-bloqueadas.mjs
// 30 × 30 de 1,5 m, uma criatura de 2 em 2 casas (o servidor recusa as bloqueadas), depois a escala passa a 2 m.
import { readFileSync } from 'node:fs';
const R = new URL('../../rascunhos/servidor/', import.meta.url).href;
const { montarMesa, recibo } = await import(R + 'testes/ajudantes.mjs');
const terreno = JSON.parse(readFileSync(new URL('dados/terreno-floresta.json', R), 'utf8'));
const m = montarMesa({ terreno, mapa: { largura: 30, altura: 30 }, casas: { heroina: { x: 2, y: 2 } } });
m.entrarTodos();
m.iniciarCombate([]);
let postas = 0;
for (let y = 0; y < 30; y += 2) for (let x = 0; x < 30; x += 2) {
  const r = recibo(m.mestre('MASTER_PLACE', { fichaId: 'orc-teste', casa: { x, y } }));
  if (r?.type === 'ROOM_RECEIPT') postas++;
}
const conta = () => {
  const j = m.sala.depuracao.juizoTerreno();
  const est = m.sala.depuracao.estado();
  const fs = Object.values(est.figuras).filter((f) => f.colocada);
  const bloq = fs.filter((f) => !j.casas[f.y * j.largura + f.x].passavel);
  return { casaM: j.casaM, figuras: fs.length, emBloqueadas: bloq.map((f) => `(${f.x},${f.y}) ${j.casas[f.y * j.largura + f.x].motivo}`) };
};
console.log('postas', postas, JSON.stringify(conta()));
const r = recibo(m.mestre('MASTER_SUPERVISOR', { op: 'escala', casaM: 2 }));
console.log('escala 2 m:', r?.type, JSON.stringify(conta()));
