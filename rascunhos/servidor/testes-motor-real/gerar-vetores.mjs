// JV0.3 — gera os vetores-ouro (ver vetores-ouro.mjs).
// Uso (na pasta servidor/), com o motor embrulhado pelo motores/embrulhar.mjs, como no job motor-real do CI:
//   node motores/embrulhar.mjs <vlab-completo.js> <motores.mjs>
//   node testes-motor-real/gerar-vetores.mjs <motores.mjs> [pasta-de-saida]
// Sem pasta, escreve em testes-motor-real/vetores-ouro/. Escreve só ficheiros .json da lista (nunca apaga nada).
import { writeFileSync, mkdirSync } from 'node:fs';
import { pathToFileURL, fileURLToPath } from 'node:url';
import path from 'node:path';
import { gerarFicheiros } from './vetores-ouro.mjs';

const [, , motorMjs, saida] = process.argv;
if (!motorMjs) {
  console.error('uso: node testes-motor-real/gerar-vetores.mjs <motores.mjs> [pasta-de-saida]');
  process.exit(2);
}
const mod = await import(pathToFileURL(path.resolve(motorMjs)).href);
const motor = { Dmg: mod.Dmg, Vlab: mod.Vlab, MOTOR_SHA256: mod.MOTOR_SHA256, DMG_VERSAO: 'real', LEVELUP_SHA: null };
const pasta = path.resolve(saida ?? path.join(path.dirname(fileURLToPath(import.meta.url)), 'vetores-ouro'));
mkdirSync(pasta, { recursive: true });
const ficheiros = gerarFicheiros(motor);
for (const [nome, texto] of Object.entries(ficheiros)) writeFileSync(path.join(pasta, nome), texto, { encoding: 'utf8' });
const man = JSON.parse(ficheiros['MANIFESTO.json']);
console.log(JSON.stringify({ ok: true, pasta, motorSha256: man.motorSha256, total: man.total, grupos: man.grupos.map((g) => [g.grupo, g.casos, g.sha256]) }));
