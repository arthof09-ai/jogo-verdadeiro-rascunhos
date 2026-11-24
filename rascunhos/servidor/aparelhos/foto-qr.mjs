// Ordem PLANO-2-F2 (JV3.4): a página /qr do servidor de verdade, fotografada no Chromium, para o decodificador
// independente a ler (aparelhos/ler-foto-qr.py). Prova de ponta a ponta: o que o Mestre mostra no PC lê-se.
//
//   node aparelhos/foto-qr.mjs <pasta-de-saída> [--links=http://192.168.1.20:8080/]
//
// Sem --links, usa os endereços da rede local desta máquina (como o servidor do Mestre). Escreve qr-pagina.png e
// qr-esperado.json (o link que o QR grande tem de dar).
import { mkdirSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { criarServidor, urlsDaRede } from '../adaptadores/node/servidor-ws.js';
import { criarMesaProva } from './mesa-prova.mjs';
import { abrirNavegador } from './navegador.mjs';

const saida = path.resolve(process.argv[2] ?? '.');
mkdirSync(saida, { recursive: true });
const arg = process.argv.find((x) => x.startsWith('--links='));
let links = arg ? arg.slice('--links='.length).split(',') : null;
const servidor = criarServidor({ sala: criarMesaProva({ pin: '97531864' }), urlsMesa: () => links });
await new Promise((r) => servidor.listen(0, '127.0.0.1', r));
if (!links) links = urlsDaRede(8080).slice(0, 1);
if (!links.length) links = ['http://192.168.1.20:8080/'];
const nav = await abrirNavegador({ largura: 900, altura: 1100 });
await nav.pagina.navegar(`http://127.0.0.1:${servidor.address().port}/qr`);
await new Promise((r) => setTimeout(r, 1500));
writeFileSync(path.join(saida, 'qr-pagina.png'), await nav.pagina.captura());
writeFileSync(path.join(saida, 'qr-esperado.json'), JSON.stringify({ link: links[0] }) + '\n');
await nav.fechar();
servidor.close();
console.log(`qr-pagina.png escrito (link do QR grande: ${links[0]})`);
