// Abre uma página num Chromium sem janela com ecrã de celular (toque, DPR 3) e fotografa-a.
//   node ver-pagina.mjs --url=<url> --saida=<pasta> --nome=<prefixo> [--w=360 --h=640 --dpr=3 --espera=4000] [--repo=<repo>]
// Grava <nome>.png e <nome>.json (tamanho do canvas, elemento focado, caixas dos campos/botões visíveis).
import { mkdirSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const a = Object.fromEntries(process.argv.slice(2).map((x) => /^--([a-z-]+)(?:=(.*))?$/.exec(x)).filter(Boolean).map((m) => [m[1], m[2] ?? true]));
const repo = a.repo || 'C:/Users/txcga/RPG_Local/jogo-verdadeiro/ordem-correccao-entrada-pc/repo';
const { abrirNavegador } = await import(pathToFileURL(path.join(repo, 'rascunhos/servidor/aparelhos/navegador.mjs')));
const w = Number(a.w || 360), h = Number(a.h || 640), dpr = Number(a.dpr || 3);
mkdirSync(a.saida, { recursive: true });
const nav = await abrirNavegador({ largura: w, altura: h, gpu: Boolean(a.gpu), registo: (t) => console.log(t) });
const p = nav.pagina;
await p.enviar('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: dpr, mobile: true });
await p.enviar('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 });
await p.navegar(a.url);
await new Promise((r) => setTimeout(r, Number(a.espera || 4000)));
const info = await p.enviar('Runtime.evaluate', { returnByValue: true, expression: `(() => {
  const cx = (e) => { const r = e.getBoundingClientRect(); return [Math.round(r.x), Math.round(r.y), Math.round(r.width), Math.round(r.height)]; };
  const vis = (e) => { const r = e.getBoundingClientRect(); const s = getComputedStyle(e); return r.width > 0 && r.height > 0 && s.visibility !== 'hidden' && s.display !== 'none'; };
  const c = document.querySelector('canvas');
  return {
    janela: [innerWidth, innerHeight, devicePixelRatio],
    canvas: c ? { css: cx(c), px: [c.width, c.height] } : null,
    focado: document.activeElement ? document.activeElement.tagName + '#' + document.activeElement.id : null,
    controlos: [...document.querySelectorAll('input,textarea,button,a')].filter(vis).map((e) => ({
      tag: e.tagName, id: e.id, cls: e.className, tipo: e.type, txt: (e.innerText || e.placeholder || e.value || '').trim().slice(0, 60), caixa: cx(e),
      fonte: getComputedStyle(e).fontSize, cor: getComputedStyle(e).color, fundo: getComputedStyle(e).backgroundColor })),
  };
})()` });
writeFileSync(path.join(a.saida, a.nome + '.json'), JSON.stringify(info.result.value, null, 1));
writeFileSync(path.join(a.saida, a.nome + '.png'), await p.captura());
console.log(JSON.stringify(info.result.value, null, 1));
await nav.fechar();
process.exit(0);
