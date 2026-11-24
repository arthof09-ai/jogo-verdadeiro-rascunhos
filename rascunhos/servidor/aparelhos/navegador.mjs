// Ordem PLANO-2-F2 — um Chromium sem janela comandado pelo DevTools Protocol, sem bibliotecas (o WebSocket global do
// Node ≥ 22). Serve às provas da web: o «pronto» do export (JV0.2), o ROOM_SNAPSHOT pela entrada do lobby (JV2.1b) e a
// medição V1.0. O executável vem de $CHROME, ou do sítio habitual (Linux: google-chrome / chromium; Windows: Chrome ou
// Edge).
import { spawn } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';

export function acharChrome() {
  if (process.env.CHROME) return process.env.CHROME;
  const candidatos = process.platform === 'win32'
    ? ['C:/Program Files/Google/Chrome/Application/chrome.exe', 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe']
    : ['/usr/bin/google-chrome', '/usr/bin/google-chrome-stable', '/usr/bin/chromium', '/usr/bin/chromium-browser'];
  const c = candidatos.find((x) => existsSync(x));
  if (!c) throw new Error('não encontrei o Chrome/Chromium (defina CHROME)');
  return c;
}

const esperar = (ms) => new Promise((r) => setTimeout(r, ms));

/** Lança o navegador e devolve {pagina, fechar}. `pagina` fala CDP com a primeira página (about:blank). */
export async function abrirNavegador({ largura = 1280, altura = 720, gpu = false, registo = () => {} } = {}) {
  const perfil = mkdtempSync(path.join(tmpdir(), 'f2-chromium-'));
  const args = [
    '--headless=new', '--no-first-run', '--no-default-browser-check', '--disable-extensions',
    '--remote-debugging-port=0', `--user-data-dir=${perfil}`, `--window-size=${largura},${altura}`,
    '--ignore-gpu-blocklist', '--autoplay-policy=no-user-gesture-required', 'about:blank',
  ];
  // WebGL2 sem GPU: o SwiftShader (no CI não há GPU). Com gpu=true (só no PC), a GPU de verdade da máquina.
  if (!gpu) args.splice(args.length - 1, 0, '--use-angle=swiftshader', '--enable-unsafe-swiftshader');
  if (process.platform === 'linux') args.unshift('--no-sandbox');
  const proc = spawn(acharChrome(), args, { stdio: ['ignore', 'ignore', 'pipe'] });
  proc.stderr.on('data', () => {});
  const ficheiroPorta = path.join(perfil, 'DevToolsActivePort');
  for (let i = 0; i < 200 && !existsSync(ficheiroPorta); i++) await esperar(50);
  if (!existsSync(ficheiroPorta)) throw new Error('o navegador não abriu o DevTools');
  await esperar(100);
  const porta = Number(readFileSync(ficheiroPorta, 'utf8').split('\n')[0]);
  let alvos = [];
  for (let i = 0; i < 50 && !alvos.some((a) => a.type === 'page'); i++) {
    alvos = await (await fetch(`http://127.0.0.1:${porta}/json/list`)).json();
    if (!alvos.some((a) => a.type === 'page')) await esperar(100);
  }
  const alvo = alvos.find((a) => a.type === 'page');
  const pagina = await ligarCdp(alvo.webSocketDebuggerUrl, registo);
  return {
    pagina,
    async fechar() {
      try {
        pagina.fechar();
      } catch {
        /* já fechada */
      }
      proc.kill();
      await esperar(500);
      try {
        rmSync(perfil, { recursive: true, force: true });
      } catch {
        /* o Windows pode segurar ficheiros um pouco mais */
      }
    },
  };
}

async function ligarCdp(url, registo) {
  const ws = new WebSocket(url);
  await new Promise((r, j) => {
    ws.onopen = r;
    ws.onerror = () => j(new Error('CDP: não liguei'));
  });
  let n = 0;
  const pendentes = new Map();
  const ouvintes = [];
  const consola = []; // {t, texto}
  ws.onmessage = (ev) => {
    const m = JSON.parse(String(ev.data));
    if (m.id && pendentes.has(m.id)) {
      const { r, j } = pendentes.get(m.id);
      pendentes.delete(m.id);
      if (m.error) j(new Error(m.error.message));
      else r(m.result);
      return;
    }
    if (m.method === 'Runtime.consoleAPICalled') {
      const texto = (m.params.args ?? []).map((a) => a.value ?? a.description ?? '').join(' ');
      consola.push({ t: Date.now(), texto });
      registo('[consola] ' + texto.slice(0, 300));
    }
    if (m.method === 'Runtime.exceptionThrown') {
      const texto = 'EXCEPÇÃO ' + (m.params.exceptionDetails?.exception?.description ?? m.params.exceptionDetails?.text);
      consola.push({ t: Date.now(), texto });
      registo('[consola] ' + texto.slice(0, 300));
    }
    for (const o of ouvintes) o(m);
  };
  const enviar = (method, params = {}) => new Promise((r, j) => {
    const id = ++n;
    pendentes.set(id, { r, j });
    ws.send(JSON.stringify({ id, method, params }));
  });
  await enviar('Runtime.enable');
  await enviar('Page.enable');
  const pagina = {
    consola,
    enviar,
    fechar: () => ws.close(),
    /** Espera uma linha da consola que case `re`, depois do índice `desde`. Devolve {t, texto, indice}. */
    async esperarConsola(re, ms, desde = 0) {
      const fim = Date.now() + ms;
      for (;;) {
        for (let i = desde; i < consola.length; i++) if (re.test(consola[i].texto)) return { ...consola[i], indice: i };
        if (Date.now() > fim) throw new Error(`a consola não mostrou ${re} em ${ms / 1000} s`);
        await esperar(50);
      }
    },
    async navegar(u) {
      await enviar('Page.navigate', { url: u });
    },
    async clicar(x, y) {
      for (const type of ['mousePressed', 'mouseReleased']) {
        await enviar('Input.dispatchMouseEvent', { type, x, y, button: 'left', clickCount: 1 });
      }
    },
    /** Escreve texto tecla a tecla (o Godot web lê keydown/keypress, não o «input» do DOM). */
    async escrever(texto) {
      for (const c of texto) {
        await enviar('Input.dispatchKeyEvent', { type: 'keyDown', key: c, text: c, unmodifiedText: c });
        await enviar('Input.dispatchKeyEvent', { type: 'keyUp', key: c });
        await esperar(15);
      }
    },
    async tecla(key, codigo) {
      const extra = key === 'Enter' ? { text: '\r' } : {};
      await enviar('Input.dispatchKeyEvent', { type: 'rawKeyDown', key, code: key, windowsVirtualKeyCode: codigo, nativeVirtualKeyCode: codigo, ...extra });
      if (key === 'Enter') await enviar('Input.dispatchKeyEvent', { type: 'char', key, text: '\r' });
      await enviar('Input.dispatchKeyEvent', { type: 'keyUp', key, code: key, windowsVirtualKeyCode: codigo, nativeVirtualKeyCode: codigo });
      await esperar(30);
    },
    async captura() {
      const r = await enviar('Page.captureScreenshot', { format: 'png' });
      return Buffer.from(r.data, 'base64');
    },
  };
  return pagina;
}
