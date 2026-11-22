// Prova da Ordem CAIXA-PERSISTENTE — o servidor de mesa DE VERDADE com a batalha de BANCADA (o cenário do autojogo).
//
// É o mesmo que servidor/autojogo/servidor-autojogo.mjs monta (sala de nucleo/sala.js, WebSocket de
// adaptadores/node/servidor-ws.js, cenário e fichas de bancada, dado semeado, relógio fixo, criaturas em modo manual,
// terreno da floresta), com UMA diferença: NÃO fecha quando o Mestre sai — a prova é precisamente o Mestre sair e
// voltar a entrar a meio da batalha. Fecha-se ao fim de --vida-max-s (nunca fica órfão) ou com SIGTERM.
// A ferramenta de medição do autojogo fica intacta (não se mexeu nela).
//
//   node provas/ordem-caixa/ferramentas/servidor-bancada-prova.mjs --porta=8791 --semente=7 --info=<ficheiro>
//        --pin=<PIN da corrida> [--motor-falso | --motor=<vlab-completo.js>] [--vida-max-s=600]
//
// Ordem CAIXA-RELATO-B7-CORRECOES-6 (B1/B2): o PIN do Mestre JÁ NÃO está no cenário cometido. Vem por `--pin=` (o
// lançador gera um fresco em cada corrida e nunca o escreve no repositório); sem ele, ou fora de /^\d{6,}$/, o servidor
// sai com 2. O info (--info) e a linha «pronto-…» já NÃO levam o PIN.
// Ordem CAIXA-RELATO-B7-CORRECOES-7 (B1/JD2): os caminhos passam por fileURLToPath, como na cópia do HUD
// (provas/ordem-caixa-hud-jogadora/ferramentas/servidor-bancada-prova.mjs). O `.pathname` do URL dava, no Windows,
// «/C:/…» (e %-escapes nos acentos), que o fs não abre: o cenário não se lia e o 4.º lançador não corria fora do Linux.
import { readFileSync, writeFileSync, renameSync, existsSync, mkdirSync } from 'node:fs';
import { pathToFileURL, fileURLToPath } from 'node:url';
import path from 'node:path';

const SRV = new URL('../../../rascunhos/servidor/', import.meta.url);
const { criarSala } = await import(new URL('nucleo/sala.js', SRV).href);
const { criarServidor } = await import(new URL('adaptadores/node/servidor-ws.js', SRV).href);
const { lerCenario, rngSemeado } = await import(new URL('autojogo/servidor-autojogo.mjs', SRV).href);
const { embrulhar } = await import(new URL('motores/embrulhar.mjs', SRV).href);

const args = Object.fromEntries(process.argv.slice(2).map((x) => /^--([a-z-]+)(?:=(.*))?$/.exec(x)).filter(Boolean).map((m) => [m[1], m[2] ?? true]));
const porta = Number(args.porta ?? 8791);
const semente = Number(args.semente ?? 7);
const pin = typeof args.pin === 'string' ? args.pin : '';
if (!/^\d{6,}$/.test(pin)) { console.error('[prova] falta --pin=<6 dígitos ou mais> (o PIN da corrida; o cenário já não o traz)'); process.exit(2); }
const caminhoCenario = fileURLToPath(new URL('autojogo/cenario-bancada.json', SRV));
const { cenario, fichas, shaCenario, shaFichas } = lerCenario(caminhoCenario);

async function motor() {
  if (args['motor-falso']) {
    const { criarMotorFalso } = await import(new URL('testes/motor-falso.mjs', SRV).href);
    return { motores: criarMotorFalso(), rotulo: 'falso', sha: null };
  }
  const fonte = typeof args.motor === 'string' ? path.resolve(args.motor) : fileURLToPath(new URL('autojogo/.cache/vlab-completo.js', SRV));
  if (!existsSync(fonte)) throw new Error('motor não encontrado: ' + fonte + ' (passe --motor=<vlab-completo.js> ou --motor-falso)');
  const { sha, codigo } = embrulhar(readFileSync(fonte));
  const dir = fileURLToPath(new URL('autojogo/.cache/', SRV));
  mkdirSync(dir, { recursive: true });
  const modulo = path.join(dir, `motores-${sha.slice(0, 16)}.mjs`);
  if (!existsSync(modulo)) writeFileSync(modulo, codigo);
  const mod = await import(pathToFileURL(modulo).href);
  return { motores: { Dmg: mod.Dmg, Vlab: mod.Vlab, MOTOR_SHA256: mod.MOTOR_SHA256, DMG_VERSAO: 'real', LEVELUP_SHA: null }, rotulo: 'vlab-real', sha };
}

const m = await motor();
const terreno = JSON.parse(readFileSync(new URL('dados/terreno-floresta.json', SRV), 'utf8'));
const lugares = cenario.heroinas.map((h) => ({ papel: 'jogadora', nome: h.nome, senha: h.senha, fichaId: h.fichaId, casa: h.casa }));
lugares.push({ papel: 'mestre', nome: 'Mestre da bancada', pin });
const sala = criarSala({
  terreno, motores: m.motores, fichas, rng: rngSemeado(semente), agora: (() => { let t = Date.UTC(2026, 10, 19, 12, 0, 0); return () => (t += 250); })(),
  config: { roomId: 'bancada-caixa-s' + semente, teste: true, mapa: cenario.mapa ?? { largura: 20, altura: 20 }, iniciativa: cenario.iniciativa ?? {}, modoPadrao: 'manual', lugares },
});
const servidor = criarServidor({ sala, registo: (t) => console.log('[servidor]', t) });
setTimeout(() => { console.log('[prova] vida máxima esgotada: fecho'); process.exit(3); }, Number(args['vida-max-s'] ?? 600) * 1000).unref();
process.on('SIGTERM', () => process.exit(0));
servidor.listen(porta, '127.0.0.1', () => {
  const info = { pronto: true, porta, semente, roomId: sala.roomId, motor: m.rotulo, motorSha256: m.sha, cenarioSha256: shaCenario, fichasSha256: shaFichas };
  if (typeof args.info === 'string') { writeFileSync(args.info + '.tmp', JSON.stringify(info)); renameSync(args.info + '.tmp', args.info); }
  console.log('pronto-prova-caixa ' + JSON.stringify(info));
});
