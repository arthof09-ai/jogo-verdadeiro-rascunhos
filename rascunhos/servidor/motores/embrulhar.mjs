// embrulhar.mjs - passo de build da JV1.1-a. Gera um modulo ES a partir do motor oficial SEM mudar uma linha dele.
// Uso: node motores/embrulhar.mjs <vlab-completo.js> <saida.mjs> [sha256-esperado]
// O motor regista-se em window.Dmg e window.Vlab; aqui window e falso, e module/require ficam indefinidos
// (o segundo module.exports do arquivo apagaria o primeiro - ver JV1.1-a).
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { createHash } from 'node:crypto';
import path from 'node:path';

export function embrulhar(bytesMotor) {
  const sha = createHash('sha256').update(bytesMotor).digest('hex');
  const texto = bytesMotor.toString('utf8');
  const cabeca = '// GERADO por embrulhar.mjs - nao editar.\n' +
    '// Fonte: vlab-completo.js oficial, SHA-256 ' + sha + '\n' +
    'const window = {};\nconst module = undefined;\nconst require = undefined;\n' +
    '/* ======== inicio do arquivo oficial, byte a byte ======== */\n';
  const pe = '\n/* ======== fim do arquivo oficial ======== */\n' +
    'export const Dmg = window.Dmg;\nexport const Vlab = window.Vlab;\n' +
    'export const MOTOR_SHA256 = "' + sha + '";\n';
  return { sha, codigo: cabeca + texto + pe };
}

if (process.argv[1] && path.resolve(process.argv[1]) === path.resolve(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'))) {
  const [, , entrada, saida, esperado] = process.argv;
  if (!entrada || !saida) { console.error('uso: node embrulhar.mjs <motor.js> <saida.mjs> [sha]'); process.exit(2); }
  const bytes = readFileSync(entrada);
  const { sha, codigo } = embrulhar(bytes);
  if (esperado && esperado.toLowerCase() !== sha) { console.error('ABORTA: SHA do motor ' + sha + ' != esperado ' + esperado); process.exit(3); }
  mkdirSync(path.dirname(path.resolve(saida)), { recursive: true });
  writeFileSync(saida, codigo);
  console.log(JSON.stringify({ ok: true, sha, bytes: bytes.length, saida }));
}
