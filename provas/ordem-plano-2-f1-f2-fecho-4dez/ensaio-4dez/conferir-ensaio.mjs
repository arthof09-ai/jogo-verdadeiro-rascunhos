// ORDEM-PLANO-2-F1-F2-FECHO-4DEZ (B3) — confere por máquina o resultado do ensaio da casa (JV3.4b).
//
//   node conferir-ensaio.mjs <pasta resultado-…>   (a que o arrancar-ensaio guarda ao fechar a mesa)
//
// Lê o journal (registo-MESTRE-ONLY-bancada-rede.json), o registos/servidor.log e as medicoes/*.json e diz, um a um:
//   - turnos no journal (≥ 10);  - um só `fim` e `{"desfecho":"morte"}` (não «Terminar»);
//   - colocações: 0 ids repetidos e 0 casas repetidas;
//   - as saídas e reentradas da jogadora no registo do servidor (SAIU → ENTROU, com as horas);
//   - o JSON da V1.0 com todos os campos.
// O cronómetro (Wi-Fi ligado → a mesa de volta ≤ 30 s) e as 4 fotos são da pessoa: lavram-se no REGISTO à mão.
// Exit 0 se o que a máquina confere passa; 1 se não. Não escreve nada.
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import path from 'node:path';

const pasta = process.argv[2];
if (!pasta) { console.error('uso: node conferir-ensaio.mjs <pasta resultado-…>'); process.exit(2); }
const falhas = [];
const ok = (cond, txt) => { console.log(`${cond ? '  ok   ' : '  FALHA'} ${txt}`); if (!cond) falhas.push(txt); };

// ---- o journal
const fj = path.join(pasta, 'registo-MESTRE-ONLY-bancada-rede.json');
if (!existsSync(fj)) ok(false, `journal em falta: ${fj}`);
else {
  const j = JSON.parse(readFileSync(fj, 'utf8'));
  const r = JSON.parse(String(j.registo).split('\n')[0]);
  const ev = r.eventos;
  const conta = (t) => ev.filter((e) => e.tipo === t);
  console.log(`journal: ${ev.length} eventos, seq ${ev[0]?.journalSeq}…${ev.at(-1)?.journalSeq}`);
  const seqs = ev.map((e) => e.journalSeq);
  ok(seqs.every((s, i) => i === 0 || s === seqs[i - 1] + 1), 'seq do journal contínuo (sem buracos nem repetidos)');
  ok(conta('turno').length >= 10, `turnos no journal: ${conta('turno').length} (≥ 10)`);
  const fins = conta('fim');
  ok(fins.length === 1, `eventos «fim»: ${fins.length} (1)`);
  ok(fins.length === 1 && fins[0].dados?.desfecho === 'morte',
    `fim ${JSON.stringify(fins[0]?.dados ?? null)} no seq ${fins[0]?.journalSeq ?? '—'} (tem de ser {"desfecho":"morte"})`);
  const col = conta('colocacao');
  const ids = col.map((e) => e.dados.figuraId), casas = col.map((e) => `${e.dados.x},${e.dados.y}`);
  for (const e of col) console.log(`         colocação seq ${e.journalSeq}: ${e.dados.nomePublico} (${e.dados.x},${e.dados.y})`);
  ok(new Set(ids).size === ids.length, `colocações: ${col.length}, ids repetidos ${ids.length - new Set(ids).size} (0)`);
  ok(new Set(casas).size === casas.length, `colocações: casas repetidas ${casas.length - new Set(casas).size} (0)`);
  console.log(`         mortes/testes: ${conta('teste_morte').length} testes de morte; estado final fase «${r.estado?.fase}»`);
}

// ---- o registo do servidor: saídas e reentradas
const fl = path.join(pasta, 'registos', 'servidor.log');
if (!existsSync(fl)) ok(false, `registo do servidor em falta: ${fl}`);
else {
  const linhas = readFileSync(fl, 'utf8').split(/\r?\n/).filter((l) => / (ENTROU|SAIU) /.test(l));
  for (const l of linhas) console.log(`         ${l.trim()}`);
  const hora = (l) => { const m = /(\d\d):(\d\d):(\d\d\.\d\d\d) (ENTROU|SAIU) (.+?)(?: \(|$)/.exec(l); return m && { s: +m[1] * 3600 + +m[2] * 60 + +m[3], tipo: m[4], nome: m[5] }; };
  const jog = linhas.map(hora).filter((h) => h && !/^Mestre/.test(h.nome));
  const cortes = [];
  for (let i = 0; i < jog.length - 1; i++) if (jog[i].tipo === 'SAIU' && jog[i + 1].tipo === 'ENTROU' && jog[i + 1].nome === jog[i].nome) cortes.push(jog[i + 1].s - jog[i].s);
  for (const c of cortes) console.log(`         corte da jogadora: SAIU → ENTROU = ${c.toFixed(3)} s (inclui os 25 s sem Wi-Fi)`);
  ok(cortes.length >= 1, `cortes com reentrada no registo do servidor: ${cortes.length} (≥ 1)`);
}

// ---- a V1.0
const fm = path.join(pasta, 'medicoes');
const med = existsSync(fm) ? readdirSync(fm).filter((f) => f.endsWith('.json')) : [];
ok(med.length >= 1, `medições V1.0 gravadas pelo servidor: ${med.length} (≥ 1)`);
const CAMPOS = ['fps_mediana', 'fps_p5', 'chamadas_mediana', 'chamadas_max', 'gpu', 'viewport', 'dpr', 'quadros', 'plataforma', 'navegador'];
for (const f of med) {
  const m = JSON.parse(readFileSync(path.join(fm, f), 'utf8')).medicao ?? {};
  const falta = CAMPOS.filter((c) => !(c in m));
  ok(falta.length === 0, `${f}: plataforma ${m.plataforma}, FPS mediana ${m.fps_mediana}, p5 ${m.fps_p5}, chamadas ${m.chamadas_mediana}, gpu «${m.gpu}»` + (falta.length ? `; FALTAM ${falta.join(', ')}` : '; todos os campos'));
}

console.log(falhas.length ? `ENSAIO: ${falhas.length} conferência(s) da máquina falharam` : 'ENSAIO: o que a máquina confere passa (falta o cronómetro e as 4 fotos, da pessoa)');
process.exit(falhas.length ? 1 : 0);
