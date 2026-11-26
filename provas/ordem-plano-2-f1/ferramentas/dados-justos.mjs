// ORDEM-PLANO-2-F1, item 3 — D-AUD-15: os dados são justos?
//
//   node provas/ordem-plano-2-f1/ferramentas/dados-justos.mjs --motor=<motores.mjs> [--journal=<registo-MESTRE-ONLY…json> | --registados=<json>]
//        [--n=2000000] [--saida=<pasta>]
//
// --motor   o VLAB do jogo embrulhado (rascunhos/servidor/motores/embrulhar.mjs sobre o vlab-completo.js oficial; o
//           mesmo que a bancada carrega de bancada-rede/privado/motores.mjs). O SHA-256 dele sai no relatório.
// --journal o registo do Mestre de uma batalha (envelope `registo-mestre/1`), para reproduzir as faces registadas.
//
// Dois passos, os dois pelo caminho real do ataque:
//  (A) REPRODUÇÃO pelo servidor inteiro: para cada ataque da heroína registado no journal (seq 30, 45, 56, 67, 78, 89 da
//      auditoria), uma sala nova (criarSala do servidor, com o motor real e as fichas canário da bancada — as mesmas da
//      auditoria) onde a semente sorteada é a registada; a heroína ataca o orc com o chicote pela intenção ROOM_INTENT,
//      como no jogo (sala → montarContexto → Vlab.resolverAtaque → evento `ataque`). As faces e o recibo do evento têm de
//      ser os do journal.
//  (B) DISTRIBUIÇÃO: a entrada EXACTA que a sala passou ao Vlab.resolverAtaque no passo A (atacante, alvo, técnica e
//      contexto, gravada pela espia), com a semente trocada, N vezes, em duas séries: sementes 1..N (repetível) e N
//      sementes do mesmo gerador do servidor de produção (crypto.getRandomValues, servidor-ws.js rngNode). Conta-se a
//      face do d20 (rolagem.conjuntosDeFaces[0][0]) de cada resolução.
// Critério (sentença da análise, §A item 8): cada face dentro de 5 % ± 0,06 pp, em N ≥ 200 000 sementes.
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { pathToFileURL, fileURLToPath } from 'node:url';
import path from 'node:path';

const AQUI = path.dirname(fileURLToPath(import.meta.url));
const RAIZ = path.resolve(AQUI, '../../..');
const SERVIDOR = path.join(RAIZ, 'rascunhos/servidor');
const { montarMesa, exigirAplicada } = await import(pathToFileURL(path.join(SERVIDOR, 'testes/ajudantes.mjs')).href);
const { rngNode } = await import(pathToFileURL(path.join(SERVIDOR, 'adaptadores/node/servidor-ws.js')).href);

const args = Object.fromEntries(process.argv.slice(2).map((a) => { const m = /^--([^=]+)=(.*)$/.exec(a); return m ? [m[1], m[2]] : [a, true]; }));
if (!args.motor) { console.error('uso: dados-justos.mjs --motor=<motores.mjs> [--journal=…] [--n=2000000] [--saida=…]'); process.exit(2); }
const N = Number(args.n ?? 2000000);
const SEQS = [30, 45, 56, 67, 78, 89];
const FACES = 20;
const BARRA_PP = 0.06; // a barra da medição da auditoria (o «±0,5 pp» do Plano 2 não vale)
const linhas = [];
const dizer = (s = '') => { linhas.push(s); console.log(s); };

const mod = await import(pathToFileURL(path.resolve(args.motor)).href);
const shaFicheiroMotor = createHash('sha256').update(readFileSync(path.resolve(args.motor))).digest('hex');
dizer('# D-AUD-15 — os dados do ataque, pelo caminho real');
dizer('');
dizer(`motor: ${path.basename(args.motor)} · VLAB oficial SHA-256 ${mod.MOTOR_SHA256} (o .mjs: ${shaFicheiroMotor})`);
dizer(`node ${process.version} · ${new Date().toISOString()}`);

// A espia: o Vlab do motor real, a registar a entrada e a saída de cada resolverAtaque que a sala faz.
const chamadas = [];
const Vlab = Object.create(mod.Vlab);
Vlab.resolverAtaque = (entrada) => {
  const copia = JSON.parse(JSON.stringify(entrada));
  const saida = mod.Vlab.resolverAtaque(entrada);
  chamadas.push({ entrada: copia, saida: JSON.parse(JSON.stringify(saida)) });
  return saida;
};
const motor = { Dmg: mod.Dmg, Vlab, MOTOR_SHA256: mod.MOTOR_SHA256, DMG_VERSAO: 'real', LEVELUP_SHA: null };

/** Uma sala nova; a semente de TODAS as resoluções é `semente`; a heroína ataca o orc com o chicote. */
function atacarComSemente(semente) {
  const m = montarMesa({ motor, rngSemente: () => semente });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 3 }]]);
  const orc = m.clientes.heroina.idPorNome('Orc');
  const antes = chamadas.length;
  exigirAplicada(m.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }), 'ataque');
  const ev = m.clientes.mestre.eventos('ataque').at(-1);
  return { ev, chamada: chamadas.slice(antes).find((c) => c.entrada.contexto?.semente === semente) };
}

// ---------------------------------------------------------------- (A) reprodução
let registados = [];
if (args.journal) {
  const env = JSON.parse(readFileSync(path.resolve(args.journal), 'utf8'));
  const corpo = JSON.parse((env.registo ?? '').split('\n')[0]);
  dizer(`journal: ${path.basename(args.journal)} · vlabSha do estado ${corpo.estado?.motores?.vlabSha}` +
    (corpo.estado?.motores?.vlabSha === mod.MOTOR_SHA256 ? ' (= o motor desta corrida)' : ' (≠ o motor desta corrida!)'));
  registados = corpo.eventos.filter((e) => e.tipo === 'ataque' && SEQS.includes(e.journalSeq))
    .map((e) => ({ seq: e.journalSeq, semente: e.soMestre.semente, faces: e.soMestre.faces, recibo: e.soMestre.recibo }));
} else if (args.registados) {
  // Sem o journal (o registo privado da auditoria saiu do disco nas limpezas): os seis registos tirados dele em 24/11
  // (dados/registados-auditoria.json: seq, semente, faces e recibo do evento `ataque`, soMestre).
  registados = JSON.parse(readFileSync(path.resolve(args.registados), 'utf8')).registados;
  dizer(`registados: ${path.basename(args.registados)} (${registados.length} ataques tirados do journal da auditoria em 24/11)`);
}
dizer('');
dizer('## (A) A sequência registada, reproduzida pelo servidor inteiro');
dizer('');
dizer('A auditoria simulou a 1.ª saída do **xorshift32** (`novoCursorC`, vlab-completo.js:1115-1130). Esse cursor é o da');
dizer('Parte C (validações de movimento e testes); o **ataque** tira as faces de `mulberry32(contexto.semente)`');
dizer('(vlab-completo.js:788-801, `resolverAtaque`): face = 1 + ⌊rng()·20⌋, a 1.ª saída, sem sorteios antes.');
dizer('');
dizer('| seq | semente | faces no journal | faces pelo servidor | recibo igual | 1.ª saída xorshift32 (a simulação da auditoria) |');
dizer('|---|---|---|---|---|---|');
const xorshift1 = (s) => { let e = (s >>> 0) || 0x9e3779b9; e ^= e << 13; e >>>= 0; e ^= e >> 17; e ^= e << 5; e >>>= 0; return (e % 20) + 1; };
let iguais = 0;
let entradaReal = null;
for (const r of registados) {
  const { ev, chamada } = atacarComSemente(r.semente);
  entradaReal ??= chamada.entrada;
  const f = ev.dados.soMestre.faces;
  const ok = JSON.stringify(f) === JSON.stringify(r.faces) && ev.dados.soMestre.recibo === r.recibo && ev.dados.soMestre.semente === r.semente;
  if (ok) iguais++;
  dizer(`| ${r.seq} | ${r.semente} | ${JSON.stringify(r.faces)} | ${JSON.stringify(f)} | ${ev.dados.soMestre.recibo === r.recibo ? 'sim' : 'NÃO'} | ${xorshift1(r.semente)} |`);
}
if (registados.length) {
  dizer('');
  dizer(`**Reprodução: ${iguais}/${registados.length} iguais** (faces, recibo e semente do evento \`ataque\` = os do journal).`);
}
if (!entradaReal) entradaReal = atacarComSemente(0x2f1).chamada.entrada;

// ---------------------------------------------------------------- (B) distribuição
function serie(nome, proxSemente) {
  const cont = new Array(FACES + 1).fill(0);
  const pares = new Array((FACES + 1) * (FACES + 1)).fill(0);
  let anterior = 0;
  let erros = 0;
  const e = JSON.parse(JSON.stringify(entradaReal));
  const t0 = Date.now();
  for (let i = 0; i < N; i++) {
    e.contexto.semente = proxSemente(i);
    const s = mod.Vlab.resolverAtaque(e);
    const face = s?.rolagem?.conjuntosDeFaces?.[0]?.[0];
    if (!Number.isInteger(face) || face < 1 || face > FACES) { erros++; continue; }
    cont[face]++;
    if (anterior) pares[anterior * (FACES + 1) + face]++;
    anterior = face;
  }
  const ms = Date.now() - t0;
  const validas = N - erros;
  let qui = 0;
  const esperado = validas / FACES;
  let pior = 0;
  const faces = [];
  for (let k = 1; k <= FACES; k++) {
    const pct = (100 * cont[k]) / validas;
    const desvio = pct - 100 / FACES;
    pior = Math.max(pior, Math.abs(desvio));
    qui += (cont[k] - esperado) ** 2 / esperado;
    faces.push({ face: k, n: cont[k], pct, desvio });
  }
  // Pares seguidos (face i, face i+1): 400 casas, 399 graus de liberdade — testa a independência entre resoluções.
  let quiPares = 0;
  const totPares = validas - 1;
  const espPar = totPares / (FACES * FACES);
  for (let a = 1; a <= FACES; a++) for (let b = 1; b <= FACES; b++) quiPares += (pares[a * (FACES + 1) + b] - espPar) ** 2 / espPar;
  return { nome, n: validas, erros, ms, faces, pior, qui, pQui: pQuiQuadrado(qui, FACES - 1), quiPares, pPares: pQuiQuadrado(quiPares, FACES * FACES - 1) };
}

/** P(X² ≥ x) com k graus de liberdade (gama incompleta regularizada superior, série/fracção contínua). */
function pQuiQuadrado(x, k) {
  const a = k / 2, z = x / 2;
  const lnGama = (v) => { // Lanczos
    const g = 7, c = [0.99999999999980993, 676.5203681218851, -1259.1392167224028, 771.32342877765313, -176.61502916214059,
      12.507343278686905, -0.13857109526572012, 9.9843695780195716e-6, 1.5056327351493116e-7];
    if (v < 0.5) return Math.log(Math.PI / Math.sin(Math.PI * v)) - lnGama(1 - v);
    v -= 1; let s = c[0]; for (let i = 1; i < g + 2; i++) s += c[i] / (v + i);
    const t = v + g + 0.5; return 0.5 * Math.log(2 * Math.PI) + (v + 0.5) * Math.log(t) - t + Math.log(s);
  };
  if (z < a + 1) { // série da inferior
    let soma = 1 / a, termo = soma;
    for (let n = 1; n < 1000; n++) { termo *= z / (a + n); soma += termo; if (termo < soma * 1e-15) break; }
    return 1 - soma * Math.exp(-z + a * Math.log(z) - lnGama(a));
  }
  let b = z + 1 - a, c = 1e300, d = 1 / b, h = d; // fracção contínua da superior (Lentz)
  for (let i = 1; i < 1000; i++) {
    const an = -i * (i - a); b += 2; d = an * d + b; if (Math.abs(d) < 1e-300) d = 1e-300;
    c = b + an / c; if (Math.abs(c) < 1e-300) c = 1e-300; d = 1 / d; const del = d * c; h *= del; if (Math.abs(del - 1) < 1e-15) break;
  }
  return h * Math.exp(-z + a * Math.log(z) - lnGama(a));
}

dizer('');
dizer(`## (B) A distribuição das faces do d20 do ataque, N = ${N.toLocaleString('pt-PT')} sementes por série`);
dizer('');
dizer('A entrada é a que a sala passou ao `Vlab.resolverAtaque` no passo A (gravada pela espia): heroína-teste, chicote');
dizer(`\`${entradaReal.tecnica?.expressaoAtaque}\`, alvo CA ${entradaReal.alvo?.ca}, sem vantagem nem desvantagem; só a semente muda.`);
const csprng = rngNode();
const series = [serie('sementes 1..N (repetível)', (i) => i + 1), serie('sementes do CSPRNG do servidor (rngNode)', () => csprng() >>> 0)];
dizer('');
dizer('| face | ' + series.map((s) => `${s.nome}: n · % · desvio (pp)`).join(' | ') + ' |');
dizer('|---|' + series.map(() => '---').join('|') + '|');
for (let k = 0; k < FACES; k++) {
  dizer(`| ${k + 1} | ` + series.map((s) => { const f = s.faces[k]; return `${f.n} · ${f.pct.toFixed(3)} % · ${f.desvio >= 0 ? '+' : ''}${f.desvio.toFixed(3)}`; }).join(' | ') + ' |');
}
dizer('');
let todasDentro = true;
for (const s of series) {
  const dentro = s.pior <= BARRA_PP;
  todasDentro &&= dentro && s.n >= 200000 && s.erros === 0;
  dizer(`- **${s.nome}:** ${s.n} resoluções (${s.erros} sem face), ${s.ms} ms. Faces entre ${Math.min(...s.faces.map((f) => f.pct)).toFixed(3)} % e ` +
    `${Math.max(...s.faces.map((f) => f.pct)).toFixed(3)} %; **maior desvio ${s.pior.toFixed(3)} pp** (barra ±${BARRA_PP} pp: ${dentro ? 'DENTRO' : 'FORA'}). ` +
    `χ² = ${s.qui.toFixed(2)} com 19 g.l., p = ${s.pQui.toFixed(3)}. Pares seguidos (independência): χ² = ${s.quiPares.toFixed(1)} com 399 g.l., p = ${s.pPares.toFixed(3)}.`);
}
const sigma = Math.sqrt(0.05 * 0.95 / N) * 100;
dizer(`- Desvio-padrão esperado por face com N = ${N}: ${sigma.toFixed(4)} pp (a barra ±${BARRA_PP} pp = ${(BARRA_PP / sigma).toFixed(1)} σ). ` +
  `Com N = 200 000 seria ${(Math.sqrt(0.05 * 0.95 / 200000) * 100).toFixed(4)} pp (a barra = ${(BARRA_PP / (Math.sqrt(0.05 * 0.95 / 200000) * 100)).toFixed(1)} σ: ` +
  'uma de 20 faces cai fora só por acaso na maioria das corridas). Por isso N = 2 000 000.');

// ---------------------------------------------------------------- a suspeita: 4 × 18 seguidos em 6 ataques
let comCorrida = 0;
const M = 2000000;
const r = rngNode();
for (let i = 0; i < M; i++) {
  let maior = 1, cur = 1, ant = -1;
  for (let j = 0; j < 6; j++) { const f = (r() % 20); if (f === ant) { cur++; if (cur > maior) maior = cur; } else cur = 1; ant = f; }
  if (maior >= 4) comCorrida++;
}
dizer('');
dizer('## A suspeita');
dizer('');
dizer(`- Em 6 lançamentos justos de d20, a probabilidade de haver **4 ou mais faces iguais seguidas** (qualquer face) é ` +
  `${((100 * comCorrida) / M).toFixed(3)} % (${M.toLocaleString("pt-PT")} simulações). Pouco provável numa ` +
  'sequência escolhida de antemão; numa auditoria que olha para muitas sequências à procura de um padrão, não é sinal de nada.');
const reproduziu = registados.length > 0 && iguais === registados.length;
const independentes = series.every((x) => x.pPares > 0.001);
dizer(reproduziu
  ? '- As faces registadas saem **exactamente** das sementes registadas pelo caminho do jogo (passo A): não há sorteios ' +
    'escondidos antes da face, nem outra semente. A simulação da auditoria divergia por usar o gerador da Parte C (xorshift32).'
  : `- A reprodução do passo A deu ${iguais}/${registados.length}: a sequência registada NÃO sai igual (ver a tabela).`);
dizer(todasDentro
  ? '- A distribuição da face do ataque sobre as sementes fica dentro da barra em todas as séries (passo B).'
  : '- A distribuição da face do ataque sobre as sementes NÃO fica dentro da barra em todas as séries (passo B).');
dizer(independentes
  ? '- As faces de resoluções seguidas não mostram dependência (teste dos pares, p > 0,001 nas duas séries).'
  : '- O teste dos pares seguidos dá p ≤ 0,001 numa série: ver acima.');
dizer('');
const veredicto = reproduziu && todasDentro;
dizer(`**Veredicto: ${veredicto ? 'suspeita AFASTADA — os dados do ataque são justos e a sequência registada é a simulada' : 'NÃO FECHA — ver acima'}.**`);

if (args.saida) {
  mkdirSync(path.resolve(args.saida), { recursive: true });
  writeFileSync(path.join(path.resolve(args.saida), 'dados-justos.md'), linhas.join('\n') + '\n');
  writeFileSync(path.join(path.resolve(args.saida), 'dados-justos.json'), JSON.stringify({
    motorSha: mod.MOTOR_SHA256, n: N, barraPP: BARRA_PP, reproducao: { iguais, total: registados.length, registados },
    series: series.map((s) => ({ ...s, faces: s.faces })), corrida4em6: comCorrida / M, veredicto,
  }, null, 2) + '\n');
}
process.exit(veredicto ? 0 : 1);
