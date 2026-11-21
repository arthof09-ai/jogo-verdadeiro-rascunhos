// ORDEM-CORR10-PREP — a bancada de rede verdadeira: prepara o que o SERVIDOR DE PRODUÇÃO precisa para arrancar.
//
//   node bancada-rede/preparar.mjs --privado=<pasta> [--porta=8790] [--host=0.0.0.0] [--motor=auto|real|falso]
//                                  [--aliada] [--modo=manual|semi|auto]
//
// Escreve em <privado>/ (fora do que o Git guarda — ver bancada-rede/.gitignore):
//   - config.json  — a config do arranque de produção (`node rascunhos/servidor/adaptadores/node/servidor-ws.js
//                    config.json`), como o Mestre a tem: porta, host, motores, fichas, terreno, journal e a sala;
//   - fichas.json  — as fichas FICTÍCIAS de `dados-exemplo/fichas-ficticias.json` (+ a Aliada, se --aliada);
//   - motores.mjs  — o VLAB real (baixado do site, como o job motor-real do CI, e embrulhado pelo
//                    `motores/embrulhar.mjs` sem mudar uma linha) ou, sem rede / com --motor=falso,
//                    motor-falso.mjs — o motor falso dos testes, exposto como módulo.
// A sala nasce SEM `mapa` na config: com o terreno, é a grelha-mapa da linha (50 × 50 casas de 1,5 m), a mesma das
// bancadas PROVAS-MAPA. Não muda nada do jogo: só escreve ficheiros de arranque.
// Imprime uma linha JSON com o resumo (o lançador lê-a).
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const AQUI = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(AQUI, '..');
const SERVIDOR = path.join(REPO, 'rascunhos', 'servidor');
const URL_MOTOR = 'https://arthof09-ai.github.io/arena-das-bestas-prototipo-cm9/jogo-t1/vlab-completo.js'; // o do CI

const args = Object.fromEntries(process.argv.slice(2).map((a) => {
  const m = /^--([^=]+)(?:=(.*))?$/.exec(a);
  return m ? [m[1], m[2] ?? true] : [a, true];
}));
const PRIVADO = path.resolve(String(args.privado ?? path.join(AQUI, 'privado')));
const PORTA = Number(args.porta ?? 8790);
const HOST = String(args.host ?? '0.0.0.0');
const MOTOR = String(args.motor ?? 'auto');
const ALIADA = Boolean(args.aliada);
const MODO = String(args.modo ?? 'manual');
mkdirSync(PRIVADO, { recursive: true });

const { PIN, SENHAS, INICIATIVA, listaDeFichas } = await import(pathToFileURL(path.join(SERVIDOR, 'testes', 'ajudantes.mjs')).href);
const FIXTURE = JSON.parse(readFileSync(path.join(SERVIDOR, 'dados-exemplo', 'fichas-ficticias.json'), 'utf8'));
const rel = (p) => path.relative(PRIVADO, p).split(path.sep).join('/');

// ---------------------------------------------------------------- o motor
async function motorReal() {
  const destino = path.join(PRIVADO, 'motores.mjs');
  if (existsSync(destino)) return { caminho: destino, origem: 'real (em cache)' };
  const r = await fetch(URL_MOTOR, { signal: AbortSignal.timeout(30000) });
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  const bytes = Buffer.from(await r.arrayBuffer());
  writeFileSync(path.join(PRIVADO, 'vlab-completo.js'), bytes);
  const { embrulhar } = await import(pathToFileURL(path.join(SERVIDOR, 'motores', 'embrulhar.mjs')).href);
  const { sha, codigo } = embrulhar(bytes);
  writeFileSync(destino, codigo);
  return { caminho: destino, origem: `real (baixado agora, SHA-256 ${sha})` };
}
function motorFalso() {
  const destino = path.join(PRIVADO, 'motor-falso.mjs');
  const de = pathToFileURL(path.join(SERVIDOR, 'testes', 'motor-falso.mjs')).href;
  writeFileSync(destino, [
    '// GERADO por bancada-rede/preparar.mjs: o motor FALSO dos testes do servidor, exposto como módulo de motores.',
    '// Dá sempre falha crítica nos ataques (cada golpe abre um cartão de desgraça ao Mestre).',
    `import { criarMotorFalso } from ${JSON.stringify(de)};`,
    "const m = criarMotorFalso({ resultado: 'falha_critica' });",
    'export const Dmg = m.Dmg;',
    'export const Vlab = m.Vlab;',
    'export const MOTOR_SHA256 = m.MOTOR_SHA256;',
    'export const DMG_VERSAO = m.DMG_VERSAO;',
    'export const LEVELUP_SHA = m.LEVELUP_SHA;',
    '',
  ].join('\n'));
  return { caminho: destino, origem: 'falso (o dos testes: sempre falha crítica)' };
}
let motor;
if (MOTOR === 'falso') motor = motorFalso();
else {
  try {
    motor = await motorReal();
  } catch (e) {
    if (MOTOR === 'real') { console.error(`motor real indisponível: ${e.message}`); process.exit(1); }
    motor = { ...motorFalso(), origem: `falso (o real não se baixou: ${e.message})` };
  }
}

// ---------------------------------------------------------------- as fichas e a sala
writeFileSync(path.join(PRIVADO, 'fichas.json'), JSON.stringify({ ...FIXTURE, fichas: listaDeFichas({ comAliada: ALIADA }) }, null, 1));

// As casas da batalha de bancada PROVAS-MAPA: a heroína em terra a norte do lago; a aliada ao lado dela.
const lugares = [
  { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 38, y: 4 } },
];
if (ALIADA) lugares.push({ papel: 'jogadora', nome: 'Aliada Teste', senha: SENHAS.aliada, fichaId: 'aliada-teste', casa: { x: 36, y: 4 } });
lugares.push({ papel: 'mestre', nome: 'Mestre', pin: PIN });

const config = {
  porta: PORTA,
  host: HOST,
  motores: rel(motor.caminho),
  fichas: 'fichas.json',
  terreno: rel(path.join(SERVIDOR, 'dados', 'terreno-floresta.json')),
  journal: 'registo-MESTRE-ONLY-bancada-rede.json',
  sala: {
    roomId: 'sala-bancada-rede',
    teste: true, // fichas fictícias: sala de TESTE (o selo só o Mestre o vê)
    // SEM `mapa`: a grelha-mapa da linha (ORDEM MAPA-JOGÁVEL §0) — 50 × 50 de 1,5 m; a escala muda-a o Mestre.
    iniciativa: INICIATIVA,
    modoPadrao: MODO,
    lugares,
  },
};
writeFileSync(path.join(PRIVADO, 'config.json'), JSON.stringify(config, null, 2));
console.log(JSON.stringify({ ok: true, config: path.join(PRIVADO, 'config.json'), motor: motor.origem, porta: PORTA, host: HOST, aliada: ALIADA, modo: MODO }));
