// Ordem PLANO-2-F2 — a prova do export web num Chromium sem janela (JV0.2, JV2.1b, JV3.4 e V1.0).
//
//   node aparelhos/prova-web.mjs --estatica=<build/web> --saida=<pasta> [--medir] [--repetir-medicao] [--gpu]
//
//  1. A mesa de prova (servidor de verdade) serve o export web e o ws://…/ws na MESMA origem; o Mestre-bot abre o combate.
//  2. O Chromium abre http://127.0.0.1:<porta>/ : o export tem de dizer «pronto» na consola em ≤ 30 s.
//  3. A entrada pelo lobby, como uma jogadora: o nome, Tab, a senha, Enter (o teclado de verdade, pelo CDP).
//     Aceite: «rede: ROOM_SNAPSHOT seq=…» na consola (o snapshot do combate chegou ao aparelho).
//  4. Com --medir: abre /?medir=1 e espera o JSON da V1.0 (1 minuto) na consola e no servidor (POST /medicao, 204).
//     Com --repetir-medicao, mede duas vezes e compara (±10 %). --gpu: a GPU da máquina em vez do SwiftShader (no PC).
// Capturas PNG e o relatório JSON vão para --saida. Sai com 0 se tudo passa.
import { mkdirSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { criarServidor } from '../adaptadores/node/servidor-ws.js';
import { criarMesaProva, JOGADORAS } from './mesa-prova.mjs';
import { BotMestre } from './bots.mjs';
import { abrirNavegador } from './navegador.mjs';

const a = Object.fromEntries(process.argv.slice(2).map((x) => /^--([a-z-]+)(?:=(.*))?$/.exec(x)).filter(Boolean).map((m) => [m[1], m[2] ?? true]));
if (typeof a.estatica !== 'string' || typeof a.saida !== 'string') {
  console.error('uso: node aparelhos/prova-web.mjs --estatica=<build/web> --saida=<pasta> [--medir] [--repetir-medicao]');
  process.exit(2);
}
const saida = path.resolve(a.saida);
const medicoes = path.join(saida, 'medicoes-servidor');
mkdirSync(medicoes, { recursive: true });
const t0 = Date.now();
const log = (t) => console.log(`[${((Date.now() - t0) / 1000).toFixed(1).padStart(6)} s] ${t}`);
const PIN = '13572468';
const LIMITE_PRONTO_S = 30;

const sala = criarMesaProva({ pin: PIN });
const servidor = criarServidor({
  sala, pastaEstatica: path.resolve(a.estatica), medicoes, registo: (t) => log('[servidor] ' + t),
  urlsMesa: () => [`http://127.0.0.1:${servidor.address().port}/`],
});
await new Promise((r) => servidor.listen(0, '127.0.0.1', r));
const porta = servidor.address().port;
const origem = `http://127.0.0.1:${porta}`;
log(`mesa de prova em ${origem} (estática: o export web; ws na mesma origem)`);
const mestre = new BotMestre({ url: `ws://127.0.0.1:${porta}/ws`, pin: PIN });
await mestre.ligar();
await mestre.abrirCombate();
log('combate aberto pelo Mestre-bot');

const relatorio = { formato: 'prova-web/1', origem, resultados: {} };
const falhas = [];
const conferir = (ok, texto) => {
  console.log(`  ${ok ? 'ok   ' : 'FALHA'} ${texto}`);
  if (!ok) falhas.push(texto);
};

const nav = await abrirNavegador({ registo: log, gpu: Boolean(a.gpu) });
const p = nav.pagina;
try {
  // 2. «pronto» em ≤ 30 s.
  const tNav = Date.now();
  await p.navegar(origem + '/');
  const pronto = await p.esperarConsola(/^pronto$/, 90000);
  const sPronto = (pronto.t - tNav) / 1000;
  relatorio.resultados.prontoS = sPronto;
  conferir(sPronto <= LIMITE_PRONTO_S, `o export web disse «pronto» em ${sPronto.toFixed(1)} s (≤ ${LIMITE_PRONTO_S} s)`);
  // A arena pede a entrada e o lobby abre (o 2.º «pronto»).
  await p.esperarConsola(/^pronto$/, 20000, pronto.indice + 1);
  await new Promise((r) => setTimeout(r, 1500));
  writeFileSync(path.join(saida, 'web-01-pronto-lobby.png'), await p.captura());

  // 3. A entrada como jogadora: o teclado de verdade.
  const j = JOGADORAS[1];
  await p.escrever(j.nome);
  await p.tecla('Tab', 9);
  await p.escrever(j.senha);
  await p.tecla('Enter', 13);
  const snap = await p.esperarConsola(/^rede: ROOM_SNAPSHOT seq=/, 30000);
  relatorio.resultados.snapshot = snap.texto;
  conferir(/fase=combate/.test(snap.texto), `a web recebeu o ROOM_SNAPSHOT do combate («${snap.texto}»)`);
  await new Promise((r) => setTimeout(r, 4000));
  writeFileSync(path.join(saida, 'web-02-arena-na-mesa.png'), await p.captura());
  const erros = p.consola.filter((c) => /SCRIPT ERROR|Parse Error|EXCEPÇÃO/.test(c.texto));
  conferir(erros.length === 0, `0 erros de script na consola (${erros.length})`);

  // 4. A medição V1.0.
  if (a.medir) {
    const vezes = a['repetir-medicao'] ? 2 : 1;
    relatorio.resultados.medicoes = [];
    for (let v = 1; v <= vezes; v++) {
      const desde = p.consola.length;
      await p.navegar(origem + '/?medir=1');
      const m = await p.esperarConsola(/^medicao-v1\.0 \{/, 150000, desde);
      const json = JSON.parse(m.texto.slice('medicao-v1.0 '.length));
      const envio = await p.esperarConsola(/^medicao-v1\.0 envio /, 20000, desde);
      relatorio.resultados.medicoes.push({ json, envio: envio.texto });
      writeFileSync(path.join(saida, `web-03-medicao-${v}.png`), await p.captura());
      const campos = ['fps_mediana', 'fps_p5', 'chamadas_mediana', 'chamadas_max', 'gpu', 'viewport', 'dpr', 'quadros'];
      conferir(campos.every((c) => c in json), `medição ${v}: o JSON traz ${campos.join(', ')}`);
      conferir(/envio 204/.test(envio.texto), `medição ${v}: chegou ao servidor sozinha («${envio.texto}»)`);
      log(`medição ${v}: FPS mediana ${json.fps_mediana}, p5 ${json.fps_p5}, chamadas ${json.chamadas_mediana}, GPU ${json.gpu_webgl ?? json.gpu}`);
    }
    const noServidor = readdirSync(medicoes).filter((f) => f.endsWith('.json'));
    conferir(noServidor.length === vezes, `o servidor gravou ${noServidor.length} medição(ões) em ${path.basename(medicoes)}/`);
    relatorio.resultados.ficheirosNoServidor = noServidor.map((f) => JSON.parse(readFileSync(path.join(medicoes, f), 'utf8')));
    if (vezes === 2) {
      const [m1, m2] = relatorio.resultados.medicoes.map((x) => x.json);
      const perto = (x, y) => Math.abs(x - y) <= 0.1 * Math.max(Math.abs(x), Math.abs(y));
      for (const c of ['fps_mediana', 'fps_p5', 'chamadas_mediana']) {
        conferir(perto(m1[c], m2[c]), `repetir dá o mesmo ±10 %: ${c} ${m1[c]} → ${m2[c]}`);
      }
    }
  }
} catch (e) {
  conferir(false, 'a prova parou: ' + e.message);
  try {
    writeFileSync(path.join(saida, 'web-99-onde-parou.png'), await p.captura());
  } catch {
    /* sem captura */
  }
} finally {
  relatorio.consola = p.consola.map((c) => ({ s: Number(((c.t - t0) / 1000).toFixed(2)), texto: c.texto }));
  relatorio.falhas = falhas;
  writeFileSync(path.join(saida, 'prova-web.json'), JSON.stringify(relatorio, null, 1) + '\n');
  await nav.fechar();
  mestre.ws.close();
  servidor.close();
}
console.log(falhas.length ? `PROVA WEB FALHOU (${falhas.length})` : 'PROVA WEB OK');
process.exit(falhas.length ? 1 : 0);
