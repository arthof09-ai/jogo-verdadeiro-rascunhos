// Mesa de prova (servidor de verdade, fichas de bancada) a servir um export web na mesma origem do ws://…/ws.
//   node servir-mesa.mjs --estatica=<build/web> --porta=8580 [--pin=90210777] [--combate] [--repo=<repo>]
// --combate: um Mestre-bot abre o combate (para a jogadora passar à arena). Sem ele, a mesa espera o Mestre.
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const a = Object.fromEntries(process.argv.slice(2).map((x) => /^--([a-z-]+)(?:=(.*))?$/.exec(x)).filter(Boolean).map((m) => [m[1], m[2] ?? true]));
const repo = a.repo || 'C:/Users/txcga/RPG_Local/jogo-verdadeiro/ordem-correccao-entrada-pc/repo';
const imp = (p) => import(pathToFileURL(path.join(repo, 'rascunhos/servidor', p)));
const { criarServidor } = await imp('adaptadores/node/servidor-ws.js');
const { criarMesaProva, JOGADORAS } = await imp('aparelhos/mesa-prova.mjs');
const pin = String(a.pin || '90210777');
const sala = criarMesaProva({ pin });
const servidor = criarServidor({ sala, pastaEstatica: path.resolve(a.estatica), registo: (t) => console.log('[servidor] ' + t), urlsMesa: () => [] });
const porta = Number(a.porta || 8580);
await new Promise((r) => servidor.listen(porta, '127.0.0.1', r));
console.log(`mesa em http://127.0.0.1:${porta}/  PIN ${pin}  jogadoras: ${JOGADORAS.map((j) => j.nome + ' / ' + j.senha).join('; ')}`);
if (a.combate) {
  const { BotMestre } = await imp('aparelhos/bots.mjs');
  const m = new BotMestre({ url: `ws://127.0.0.1:${porta}/ws`, pin });
  await m.ligar();
  await m.abrirCombate();
  console.log('combate aberto pelo Mestre-bot');
}
