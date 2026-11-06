// P-PC-01 - prova da porta dos motores (JV1.1-a). Node >= 18, sem dependencias, sem instalar nada.
// Uso: node p01.mjs <pasta-de-saida>   (so aceita a pasta saida deste pacote)
// Escreve SO dentro da pasta saida. Unico acesso a rede: 1 GET ao vlab-completo.js publico.
// Emendas aplicadas: Infra E1-E3, Codigo 1-4 (06/11/2026).
import { createHash } from 'node:crypto';
import { writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';
import os from 'node:os';
import path from 'node:path';

setTimeout(() => { console.error('ABORTA: watchdog 30 s'); process.exit(8); }, 30000).unref();

const URL_MOTOR = 'https://arthof09-ai.github.io/arena-das-bestas-prototipo-cm9/jogo-t1/vlab-completo.js';
const SAIDA_OK = 'C:\\Users\\txcga\\RPG_Local\\jogo-verdadeiro\\pacotes\\P-PC-01\\saida';
const saida = process.argv[2];
if (!saida) { console.error('ABORTA: falta a pasta de saida'); process.exit(2); }
if (path.resolve(saida).toLowerCase() !== SAIDA_OK.toLowerCase()) { console.error('ABORTA: saida fora do previsto'); process.exit(6); }
if (os.hostname().toUpperCase() !== 'PCDANASA') { console.error('ABORTA: maquina inesperada ' + os.hostname()); process.exit(3); }
if (typeof fetch !== 'function' || Number(process.versions.node.split('.')[0]) < 18) { console.error('ABORTA: Node < 18'); process.exit(6); }
if (existsSync(saida)) { console.error('ABORTA: a pasta de saida ja existe (nao sobrescrevo): ' + saida); process.exit(4); }
mkdirSync(saida);

const rel = { pacote: 'P-PC-01', inicio: new Date().toISOString(), host: os.hostname(), node: process.version, url: URL_MOTOR };

// 1. Baixar o motor oficial (bytes exatos) e medir o SHA-256
const resp = await fetch(URL_MOTOR, { signal: AbortSignal.timeout(15000) });
if (!resp.ok) { console.error('ABORTA: HTTP ' + resp.status); process.exit(5); }
const bytes = Buffer.from(await resp.arrayBuffer());
rel.motorBytes = bytes.length;
rel.motorSha256 = createHash('sha256').update(bytes).digest('hex');

// Guarda do motor (Infra E3): tamanho e texto proibido, ANTES de gravar ou executar
const txt = bytes.toString('utf8');
const proibidos = ['child_process', 'process.', 'import(', 'fetch(', 'XMLHttpRequest', 'WebSocket', 'eval(', 'new Function', 'writeFile', 'unlink', 'spawn', 'exec('];
const achados = proibidos.filter(t => txt.includes(t));
if (bytes.length > 1048576 || achados.length) {
  writeFileSync(path.join(saida, 'resultado.json'), JSON.stringify({ ...rel, abortado: 'guarda-motor', achados }, null, 2));
  console.error('ABORTA: guarda-motor ' + JSON.stringify(achados)); process.exit(7);
}
const arqMotor = path.join(saida, 'vlab-completo.js');
writeFileSync(arqMotor, bytes);

// Entrada FICTICIA (nenhum dado do Mestre)
function entrada(semente) {
  return {
    atacante: { paLivre: 50, estado: [], armaCaida: false, armaQuebrada: false, testes: { ataque: '1d20+5' } },
    alvo: { ca: 12, defesaAplicavel: { valor: 12, nomeDaRegra: 'teste', origem: 'ficticio' }, reacaoDefensiva: null,
            vidaActual: 40, vidaTotal: 40, rd: { geral: 0, porTipo: {} }, estado: [], estadoMorte: null,
            testesDeMorteDesignado: 'fortitude', contraAtaque: null },
    tecnica: { expressaoAtaque: '1d20+5', expressaoDano: '1d8+2', componentes: [{ tipo: 'cortante', expressao: '1d8+2' }],
               tipos: ['cortante'], tipo: 'cortante', custoPA: 4, magia: false, usaArma: true, derruba: false },
    contexto: { semente }
  };
}
function resumo(r) {
  if (!r) return null;
  return { resultado: r.resultado ?? null, danoAplicado: r.danoAplicado ?? null, totalEfectivo: r.totalEfectivo ?? null,
           erro: r.erro ? (r.erro.codigo || String(r.erro)) : null };
}
function semEventId(obj) { return JSON.stringify(obj, (k, v) => (k === 'eventId' ? undefined : v)); }

// 2. Teste A - o defeito: carregar como CommonJS (como faria um require no Node)
const testeA = {};
try {
  const req = createRequire(import.meta.url);
  const m = req(path.resolve(arqMotor));
  testeA.chavesExportadas = Object.keys(m);
  testeA.temCalcularDano = typeof m.calcularDano === 'function';
  testeA.temResolverAtaque = typeof m.resolverAtaque === 'function';
  if (testeA.temResolverAtaque) {
    testeA.amostras = [];
    for (let s = 1; s <= 20; s++) {
      try { testeA.amostras.push({ s, ...resumo(m.resolverAtaque(entrada(s))) }); }
      catch (e) { testeA.amostras.push({ s, excecao: String(e && e.message || e) }); }
    }
  }
} catch (e) { testeA.excecaoAoCarregar = String(e && e.message || e); }
rel.testeA_commonjs = testeA;

// 3. Teste B - o embrulho: window falso, module/require indefinidos, motor colado byte a byte
const cabeca = 'const window = {};\nconst module = undefined;\nconst require = undefined;\n';
const pe = '\nexport const Dmg = window.Dmg;\nexport const Vlab = window.Vlab;\nexport const MOTOR_SHA256 = "' + rel.motorSha256 + '";\n';
const arqEmbrulho = path.join(saida, 'motores.mjs');
writeFileSync(arqEmbrulho, cabeca + txt + pe);
const testeB = {};
testeB.globalDmgAntes = typeof globalThis.Dmg;
try {
  const mod = await import(pathToFileURL(path.resolve(arqEmbrulho)).href);
  testeB.temDmg = !!mod.Dmg && typeof mod.Dmg.calcularDano === 'function';
  testeB.temVlab = !!mod.Vlab && typeof mod.Vlab.resolverAtaque === 'function';
  testeB.chavesVlab = mod.Vlab ? Object.keys(mod.Vlab) : [];
  if (testeB.temVlab) {
    testeB.amostras = [];
    for (let s = 1; s <= 20; s++) {
      try { testeB.amostras.push({ s, ...resumo(mod.Vlab.resolverAtaque(entrada(s))) }); }
      catch (e) { testeB.amostras.push({ s, excecao: String(e && e.message || e) }); }
    }
    const c1 = [], c2 = [];
    for (let s = 1; s <= 20; s++) { c1.push(semEventId(mod.Vlab.resolverAtaque(entrada(s)))); c2.push(semEventId(mod.Vlab.resolverAtaque(entrada(s)))); }
    testeB.deterministicoMesmaSemente = c1.every((x, i) => x === c2[i]);
    testeB.saidasDistintas = new Set(c1).size;
    testeB.errosDistintos = [...new Set(testeB.amostras.map(a => a.erro).filter(Boolean))];
    testeB.acertosComDano = testeB.amostras.filter(a => !a.erro && !a.excecao && a.danoAplicado != null && a.danoAplicado !== 0).length;
    const iA = testeB.amostras.findIndex(a => !a.erro && a.danoAplicado != null && a.danoAplicado !== 0);
    testeB.saidaCompletaExemplo = iA >= 0 ? { s: iA + 1, saida: JSON.parse(c1[iA]) } : null;
  }
} catch (e) { testeB.excecao = String(e && e.message || e); }
rel.testeB_embrulho = testeB;

rel.conclusao = {
  defeitoA: !testeA.excecaoAoCarregar && testeA.temCalcularDano === false && testeA.temResolverAtaque === true
            && (testeA.amostras || []).some(a => a.erro === 'DMG_INDISPONIVEL'),
  embrulhoB: !testeB.excecao && testeB.temDmg === true && testeB.temVlab === true
             && testeB.deterministicoMesmaSemente === true && testeB.acertosComDano >= 1 && testeB.saidasDistintas >= 2
             && !(testeB.errosDistintos || []).includes('DMG_INDISPONIVEL') && testeB.globalDmgAntes === 'undefined'
};
rel.fim = new Date().toISOString();
writeFileSync(path.join(saida, 'resultado.json'), JSON.stringify(rel, null, 2));
console.log(JSON.stringify({
  conclusao: rel.conclusao, sha: rel.motorSha256, bytes: rel.motorBytes,
  A: { chaves: testeA.chavesExportadas, temCalcularDano: testeA.temCalcularDano, excecao: testeA.excecaoAoCarregar,
       amostra: testeA.amostras && testeA.amostras.slice(0, 5) },
  B: { temDmg: testeB.temDmg, temVlab: testeB.temVlab, deterministico: testeB.deterministicoMesmaSemente,
       saidasDistintas: testeB.saidasDistintas, acertosComDano: testeB.acertosComDano, errosDistintos: testeB.errosDistintos,
       excecao: testeB.excecao, amostra: testeB.amostras && testeB.amostras.slice(0, 5) }
}, null, 1));
process.exit(0);
