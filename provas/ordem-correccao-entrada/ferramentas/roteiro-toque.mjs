// Roteiro de toque num Chromium sem janela com ecrã de celular (toque verdadeiro do CDP, DPR 3, mobile).
//   node roteiro-toque.mjs --url=<url> --saida=<pasta> --passos=<ficheiro.json> [--w=360 --h=640 --dpr=3 --gpu]
// passos: [{"espera":ms} | {"foto":"nome"} | {"tocar":"#selector"} | {"tocarXY":[x,y]} | {"inserir":"texto"} (o que o
//  teclado do celular faz: Input.insertText, sem keydown) | {"tecla":"Enter"} | {"consola":"regex","ms":n} | {"estado":"nome"}]
// «estado» grava o elemento focado (o teclado do celular só abre com um <input>/<textarea> focado) e o valor dele.
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const a = Object.fromEntries(process.argv.slice(2).map((x) => /^--([a-z-]+)(?:=(.*))?$/.exec(x)).filter(Boolean).map((m) => [m[1], m[2] ?? true]));
const repo = a.repo || 'C:/Users/txcga/RPG_Local/jogo-verdadeiro/ordem-correccao-entrada-pc/repo';
const { abrirNavegador } = await import(pathToFileURL(path.join(repo, 'rascunhos/servidor/aparelhos/navegador.mjs')));
const w = Number(a.w || 360), h = Number(a.h || 640), dpr = Number(a.dpr || 3);
const passos = JSON.parse(readFileSync(a.passos, 'utf8'));
mkdirSync(a.saida, { recursive: true });
const esperar = (ms) => new Promise((r) => setTimeout(r, ms));
const t0 = Date.now();
const log = (t) => console.log(`[${((Date.now() - t0) / 1000).toFixed(1).padStart(6)} s] ${t}`);
const nav = await abrirNavegador({ largura: w, altura: h, gpu: Boolean(a.gpu), registo: log });
const p = nav.pagina;
await p.enviar('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: dpr, mobile: true });
await p.enviar('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 });
const relatorio = { url: a.url, ecran: [w, h, dpr], passos: [] };
let falhou = false;
const avaliar = async (expr) => (await p.enviar('Runtime.evaluate', { returnByValue: true, expression: expr })).result.value;
const tocar = async (x, y) => {
  await p.enviar('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y }] });
  await esperar(60);
  await p.enviar('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
};
await p.navegar(a.url);
try {
  for (const s of passos) {
    const r = { passo: s };
    if (s.espera) await esperar(s.espera);
    if (s.foto) writeFileSync(path.join(a.saida, s.foto + '.png'), await p.captura());
    if (s.tocar) {
      const c = await avaliar(`(() => { const e = document.querySelector(${JSON.stringify(s.tocar)}); if (!e) return null; const b = e.getBoundingClientRect(); return [b.x + b.width / 2, b.y + b.height / 2]; })()`);
      if (!c) throw new Error('não há ' + s.tocar);
      r.xy = c.map(Math.round);
      await tocar(c[0], c[1]);
    }
    if (s.tocarXY) await tocar(s.tocarXY[0], s.tocarXY[1]);
    if (s.inserir != null) await p.enviar('Input.insertText', { text: s.inserir });
    if (s.tecla) await p.tecla(s.tecla, s.tecla === 'Enter' ? 13 : 9);
    if (s.consola) r.consola = (await p.esperarConsola(new RegExp(s.consola), s.ms || 30000)).texto;
    if (s.estado) {
      r.estado = await avaliar(`(() => { const e = document.activeElement; return { focado: e ? e.tagName + (e.id ? '#' + e.id : '') + (e.className ? '.' + String(e.className).split(' ')[0] : '') : null,
        teclado_abre: !!e && (e.tagName === 'INPUT' || e.tagName === 'TEXTAREA' || e.isContentEditable),
        tipo: e && e.type, valor_len: e && e.value != null ? e.value.length : null, janela: [innerWidth, innerHeight] }; })()`);
      writeFileSync(path.join(a.saida, s.estado + '.png'), await p.captura());
    }
    log(JSON.stringify(r));
    relatorio.passos.push(r);
  }
} catch (e) {
  falhou = true;
  relatorio.erro = e.message;
  log('PAROU: ' + e.message);
  writeFileSync(path.join(a.saida, 'onde-parou.png'), await p.captura());
}
relatorio.consola = p.consola.map((c) => ({ s: Number(((c.t - t0) / 1000).toFixed(2)), texto: c.texto.slice(0, 300) }));
writeFileSync(path.join(a.saida, 'roteiro.json'), JSON.stringify(relatorio, null, 1));
await nav.fechar();
process.exit(falhou ? 1 : 0);
