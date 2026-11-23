// ORDEM MAPA-JOGÁVEL-CUSTO-CÂMARA (A4): a sonda que confere a grelha da sala servida pela cópia adaptada. Entra como a
// jogadora (a mesma mensagem do jogadora-e2e.mjs) e imprime o `mapa` do primeiro ROOM_SNAPSHOT. Só lê.
//   node provas/ordem-mapa-jogavel/custo-gpu-camara/e2e/sonda-grelha.mjs <porta>
import { SENHAS } from '../../../../rascunhos/servidor/testes/ajudantes.mjs';
const porta = Number(process.argv[2] ?? 8767);
const ws = new WebSocket(`ws://127.0.0.1:${porta}/ws`);
const t = setTimeout(() => { console.error('sonda: sem snapshot em 10 s'); process.exit(1); }, 10000);
ws.onopen = () => ws.send(JSON.stringify({ v: 2, type: 'ROOM_JOIN', papel: 'jogadora', nome: 'Heroína Teste',
  senha: SENHAS.heroina, cliente: 'sonda-grelha' }));
ws.onmessage = (e) => {
  const m = JSON.parse(e.data);
  if (m.type !== 'ROOM_SNAPSHOT') return;
  const minha = (m.figuras ?? []).find((f) => f.lado === 'jogadora' || f.fichaId === 'heroina-teste');
  console.log('sonda: mapa ' + JSON.stringify(m.mapa) + ' · casa da heroína ' + JSON.stringify(minha ? [minha.x, minha.y] : null));
  clearTimeout(t); ws.close(); process.exit(0);
};
