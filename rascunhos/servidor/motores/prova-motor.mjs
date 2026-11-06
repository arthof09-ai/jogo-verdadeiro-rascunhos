// prova-motor.mjs - prova da porta dos motores (JV1.1-a) para correr no CI (nuvem), nao no PC.
// Uso: node motores/prova-motor.mjs <vlab-completo.js> <pasta-trabalho>
// Faz: (0) relatorio de textos sensiveis COM CONTEXTO (so informa, nao aborta);
//      (A) o defeito: carregar como CommonJS perde o DMG;
//      (B) o embrulho: Dmg e Vlab presentes, ataque com dano, deterministico pela semente.
// Sai 0 se A e B derem o esperado; 1 caso contrario. Imprime um JSON com tudo.
import { readFileSync, writeFileSync, mkdirSync, copyFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';
import path from 'node:path';
import { embrulhar } from './embrulhar.mjs';

const [, , arqMotor, pasta] = process.argv;
if (!arqMotor || !pasta) { console.error('uso: node prova-motor.mjs <motor.js> <pasta>'); process.exit(2); }
mkdirSync(pasta, { recursive: true });
const bytes = readFileSync(arqMotor);
const txt = bytes.toString('utf8');
const rel = { motorBytes: bytes.length };

// (0) textos sensiveis, com 60 caracteres de contexto de cada lado (so para leitura humana)
const sensiveis = ['child_process', 'process.', 'import(', 'fetch(', 'XMLHttpRequest', 'WebSocket', 'eval(', 'new Function', 'writeFile', 'unlink', 'spawn', 'exec('];
rel.textosSensiveis = [];
for (const t of sensiveis) {
  let i = txt.indexOf(t);
  while (i !== -1 && rel.textosSensiveis.length < 40) {
    rel.textosSensiveis.push({ texto: t, posicao: i, contexto: txt.slice(Math.max(0, i - 60), i + t.length + 60).replace(/\s+/g, ' ') });
    i = txt.indexOf(t, i + t.length);
  }
}

function entrada(semente) {
  return {
    atacante: { paLivre: 50, estado: [], armaCaida: false, armaQuebrada: false },
    alvo: { ca: 12, rd: { geral: 0, porTipo: {} }, estado: [], vidaActual: 40, vidaTotal: 40,
            estadoMorte: null, testesDeMorteDesignado: true, contraAtaque: null },
    tecnica: { expressaoAtaque: '1d20+5', componentes: [{ tipo: 'cortante', expressao: '1d8+2' }],
               custoPA: 4, magia: false, usaArma: true, derruba: false },
    contexto: { semente, modoDesgraca: 'sorte' }
  };
}
const resumo = r => r ? { resultado: r.resultado ?? null, danoAplicado: r.danoAplicado ?? null,
  totalEfectivo: r.totalEfectivo ?? null, erro: r.erro ? (r.erro.codigo || String(r.erro)) : null } : null;
const semEventId = o => JSON.stringify(o, (k, v) => (k === 'eventId' ? undefined : v));

// (A) CommonJS: gravar como .cjs para garantir o modo, independentemente de package.json
const A = {};
try {
  const cjs = path.join(pasta, 'motor-copia.cjs');
  copyFileSync(arqMotor, cjs);
  const m = createRequire(import.meta.url)(path.resolve(cjs));
  A.chaves = Object.keys(m);
  A.temCalcularDano = typeof m.calcularDano === 'function';
  A.temResolverAtaque = typeof m.resolverAtaque === 'function';
  A.amostras = [];
  if (A.temResolverAtaque) for (let s = 1; s <= 20; s++) {
    try { A.amostras.push({ s, ...resumo(m.resolverAtaque(entrada(s))) }); }
    catch (e) { A.amostras.push({ s, excecao: String(e?.message || e) }); }
  }
} catch (e) { A.excecao = String(e?.message || e); }
rel.A = A;

// (B) embrulho
const B = { globalDmgAntes: typeof globalThis.Dmg };
try {
  const { sha, codigo } = embrulhar(bytes);
  rel.motorSha256 = sha;
  const arq = path.join(pasta, 'motores.mjs');
  writeFileSync(arq, codigo);
  const mod = await import(pathToFileURL(path.resolve(arq)).href);
  B.temDmg = typeof mod.Dmg?.calcularDano === 'function';
  B.temVlab = typeof mod.Vlab?.resolverAtaque === 'function';
  B.chavesVlab = mod.Vlab ? Object.keys(mod.Vlab) : [];
  B.amostras = [];
  const c1 = [], c2 = [];
  for (let s = 1; s <= 20; s++) {
    try { B.amostras.push({ s, ...resumo(mod.Vlab.resolverAtaque(entrada(s))) }); } catch (e) { B.amostras.push({ s, excecao: String(e?.message || e) }); }
    c1.push(semEventId(mod.Vlab.resolverAtaque(entrada(s)))); c2.push(semEventId(mod.Vlab.resolverAtaque(entrada(s))));
  }
  B.deterministico = c1.every((x, i) => x === c2[i]);
  B.saidasDistintas = new Set(c1).size;
  B.errosDistintos = [...new Set(B.amostras.map(a => a.erro).filter(Boolean))];
  B.acertosComDano = B.amostras.filter(a => !a.erro && !a.excecao && a.danoAplicado != null && a.danoAplicado !== 0).length;
  const i = B.amostras.findIndex(a => !a.erro && a.danoAplicado != null && a.danoAplicado !== 0);
  B.exemplo = i >= 0 ? JSON.parse(c1[i]) : null;
} catch (e) { B.excecao = String(e?.message || e); }
rel.B = B;

rel.conclusao = {
  defeitoA: !A.excecao && A.temCalcularDano === false && A.temResolverAtaque === true && A.amostras.some(a => a.erro === 'DMG_INDISPONIVEL'),
  embrulhoB: !B.excecao && B.temDmg && B.temVlab && B.deterministico && B.acertosComDano >= 1 && B.saidasDistintas >= 2
             && !B.errosDistintos.includes('DMG_INDISPONIVEL') && B.globalDmgAntes === 'undefined'
};
writeFileSync(path.join(pasta, 'resultado.json'), JSON.stringify(rel, null, 2));
console.log(JSON.stringify({ conclusao: rel.conclusao, sha: rel.motorSha256, bytes: rel.motorBytes,
  textosSensiveis: rel.textosSensiveis, A: { chaves: A.chaves, temCalcularDano: A.temCalcularDano, excecao: A.excecao, amostra: A.amostras?.slice(0, 4) },
  B: { temDmg: B.temDmg, temVlab: B.temVlab, deterministico: B.deterministico, saidasDistintas: B.saidasDistintas,
       acertosComDano: B.acertosComDano, errosDistintos: B.errosDistintos, excecao: B.excecao, amostra: B.amostras?.slice(0, 4) } }, null, 1));
process.exit(rel.conclusao.defeitoA && rel.conclusao.embrulhoB ? 0 : 1);
