// ORDEM-D-AUD-07-REGISTO: a vista REAL do Mestre (servidor real, motor falso, IA em «auto») depois de duas voltas:
// a heroína encerra, a IA do orc joga e encerra (fecha a rodada 1), a heroína encerra outra vez. É a reprodução da
// auditoria (r-40) e da INVESTIGA (l30). Escreve a MASTER_VIEW em JSON para o capturar_registo.gd a desenhar.
//   node provas/ordem-d-aud-07-registo/ferramentas/gerar-vista-registo.mjs <saida.json>
import { writeFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';

const raiz = resolve(import.meta.dirname, '../../..');
const { montarMesa, exigirAplicada } = await import(pathToFileURL(resolve(raiz, 'rascunhos/servidor/testes/ajudantes.mjs')).href);

const m = montarMesa({ modoPadrao: 'auto' });
m.entrarTodos();
m.iniciarCombate([['orc-teste', { x: 2, y: 6 }]]);
exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
const v = m.enviar('mestre', { type: 'MASTER_VIEW' }).find((x) => x.type === 'MASTER_VIEW');
const nome = Object.fromEntries(v.mestre.figuras.map((f) => [f.id, f.nome]));
for (const p of v.pontos) {
  console.log(`#${p.journalSeq} [${p.tipos}] depois: rodada ${p.rodada}, vez ${nome[p.vezId] ?? '—'} | autor: rodada ${p.rodadaAutor}, vez ${nome[p.autorId] ?? '—'}`);
}
writeFileSync(process.argv[2], JSON.stringify(v, null, 1));
