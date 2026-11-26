// ORDEM-PLANO-2-F1-F8 (follow-up da conferência F1-F4-F5-F6): o detector de canários do arnês e2e da jogadora.
// (a) quando acusa, o log guarda a mensagem acusada completa, e não só o valor do canário;
// (b) o canário numérico só casa como número inteiro e fora dos campos de id: um id hexadecimal que traga «9137» por
//     acaso já não dispara o alarme.
// Os casos puros vão a `e2e/canarios.mjs`; os dois últimos correm o próprio `e2e/jogadora-e2e.mjs` contra um servidor
// WebSocket mínimo, feito à mão, que lhe manda mensagens sintéticas.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { createServer } from 'node:http';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { CANARIOS, canariosEm, acusacao } from '../e2e/canarios.mjs';

const ARNES = fileURLToPath(new URL('../e2e/jogadora-e2e.mjs', import.meta.url));

// Ids hexadecimais com «9137» lá dentro, nos sítios em que os ids aparecem no fio dela.
const UUID_9137 = '3f2a9c10-9137-4b2e-8d1f-0a9137cde5f1';
const HEX_9137 = 'a9137f0c';
const SNAPSHOT_HEX = JSON.stringify({
  v: 2, type: 'ROOM_SNAPSHOT', roomId: 'sala-' + HEX_9137, revision: 3, vezId: UUID_9137,
  propria: { figuraId: UUID_9137 },
  figuras: [{ id: UUID_9137, nomePublico: 'Heroína Teste' }, { id: HEX_9137, nomePublico: 'Orc 1' }],
});
const RECIBO_HEX = JSON.stringify({ v: 2, type: 'ROOM_RECEIPT', intentId: UUID_9137, estado: 'APLICADA', revision: 4 });
const EVENTO_HEX = JSON.stringify({
  v: 2, type: 'ROOM_EVENT', tipo: 'colocacao', dados: { figuraId: HEX_9137, alvoIds: [UUID_9137], nomePublico: 'Orc 1' },
});

test('(b) um id hexadecimal com «9137» (UUID, hex solto, em *Id, *Ids e id) não dispara o alarme', () => {
  for (const m of [SNAPSHOT_HEX, RECIBO_HEX, EVENTO_HEX]) assert.deepEqual(canariosEm(m), [], m);
  assert.equal(acusacao([SNAPSHOT_HEX, RECIBO_HEX, EVENTO_HEX], 'sintético'), null);
  // Fronteiras num texto livre: algarismos, letras, «-», «_» e «.» encostados não são o número inteiro.
  for (const t of ['91370', '19137', 'x9137', '9137a', 'k-9137', '9137-k', '_9137', '9137.5', 'v1.9137', '0.9137']) {
    assert.deepEqual(canariosEm(JSON.stringify({ texto: t })), [], t);
  }
});

test('(b) o número inteiro continua a disparar: valor JSON, dentro de um texto, numa mensagem que não é JSON', () => {
  assert.deepEqual(canariosEm(JSON.stringify({ dados: { campoNovoDoMotor: 9137 } })), ['9137']);
  assert.deepEqual(canariosEm(JSON.stringify({ figuras: [{ ca: 9137, vida: 7777 }] })), ['7777', '9137']);
  assert.deepEqual(canariosEm(JSON.stringify({ texto: 'CA 9137, vida 7777.' })), ['7777', '9137']);
  assert.deepEqual(canariosEm(JSON.stringify({ texto: '(9137)' })), ['9137']);
  assert.deepEqual(canariosEm(JSON.stringify({ texto: 'fim em 9137.' })), ['9137']);
  assert.deepEqual(canariosEm('não é JSON: ca=9137'), ['9137']);
  assert.deepEqual(canariosEm('não é JSON: id a9137f'), []);
  // Um número inteiro ao lado de um id hexadecimal com «9137»: acusa pelo número, não pelo id.
  assert.deepEqual(canariosEm(JSON.stringify({ figuraId: HEX_9137, ca: 9137 })), ['9137']);
  // Um número que não é inteiro não é o canário.
  assert.deepEqual(canariosEm(JSON.stringify({ x: 9137.5 })), []);
});

test('os canários de texto casam em qualquer sítio, também dentro de um campo de id', () => {
  assert.deepEqual(canariosEm(JSON.stringify({ nomePublico: 'Orc Verdadeiro' })), ['Orc Verdadeiro']);
  assert.deepEqual(canariosEm(JSON.stringify({ figuraId: 'x-CANARIO-FANTASMA' })), ['CANARIO-FANTASMA']);
  assert.deepEqual(canariosEm(JSON.stringify({ t: 'CANARIO-DESGRACA' })), ['CANARIO-DESGRACA']);
  assert.deepEqual(CANARIOS, ['Orc Verdadeiro', '7777', 'CANARIO-DESGRACA', 'CANARIO-FANTASMA', '9137']);
});

test('(a) a acusação traz a mensagem acusada completa e diz qual é', () => {
  const limpa = SNAPSHOT_HEX;
  const suja = JSON.stringify({ v: 2, type: 'ROOM_EVENT', tipo: 'ataque', dados: { figuraId: HEX_9137, ca: 9137 } });
  const texto = acusacao([limpa, suja], 'fase jogo, ROOM_EVENT ataque');
  assert.ok(texto, 'devia acusar');
  assert.match(texto, /^canários do Mestre no fio dela \(fase jogo, ROOM_EVENT ataque\): 9137\n/);
  assert.ok(texto.includes(`mensagem acusada #2 de 2 (9137, ${suja.length} caracteres): ${suja}`), texto);
  assert.ok(!texto.includes('#1 de 2'), 'a mensagem limpa não é acusada');
});

// --- o arnês a sério, contra um servidor WebSocket mínimo -----------------------------------------------------------

function quadro(texto) {
  const dados = Buffer.from(texto, 'utf8');
  const n = dados.length;
  const cab = n < 126 ? Buffer.from([0x81, n]) : Buffer.from([0x81, 126, n >> 8, n & 0xff]);
  return Buffer.concat([cab, dados]);
}

/** Um servidor que aceita a ligação dela e lhe manda `mensagens`, por ordem. Devolve { porta, fechar }. */
async function servidorSintetico(mensagens) {
  const srv = createServer();
  const sockets = new Set();
  srv.on('upgrade', (req, socket) => {
    sockets.add(socket);
    socket.on('error', () => {});
    const aceite = createHash('sha1').update(req.headers['sec-websocket-key'] + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11')
      .digest('base64');
    socket.write('HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n'
      + `Sec-WebSocket-Accept: ${aceite}\r\n\r\n`);
    socket.once('data', () => { for (const m of mensagens) socket.write(quadro(m)); }); // depois do ROOM_JOIN dela
  });
  await new Promise((r) => srv.listen(0, '127.0.0.1', r));
  return {
    porta: srv.address().port,
    fechar: () => { for (const s of sockets) s.destroy(); srv.close(); },
  };
}

function correrArnes(porta, limiteMs = 20000) {
  return new Promise((resolve, reject) => {
    const p = spawn(process.execPath, [ARNES, String(porta)], { stdio: ['ignore', 'pipe', 'pipe'] });
    let out = '';
    let err = '';
    p.stdout.on('data', (b) => { out += b; });
    p.stderr.on('data', (b) => { err += b; });
    const t = setTimeout(() => { p.kill(); reject(new Error('o arnês não saiu a tempo:\n' + out + err)); }, limiteMs);
    p.on('exit', (code) => { clearTimeout(t); resolve({ code, out, err }); });
  });
}

test('(a)+(b) pelo arnês: os ids hexadecimais passam; a mensagem com o canário fica inteira no log e o arnês sai com 1',
  async () => {
    const suja = JSON.stringify({
      v: 2, type: 'ROOM_EVENT', tipo: 'ataque', dados: { figuraId: HEX_9137, campoNovoDoMotor: 9137, nota: 'sintética F8' },
    });
    const s = await servidorSintetico([SNAPSHOT_HEX, RECIBO_HEX, EVENTO_HEX, suja]);
    try {
      const { code, err } = await correrArnes(s.porta);
      assert.equal(code, 1, err);
      assert.ok(err.includes('[jogadora] FALHA: canários do Mestre no fio dela (fase jogo, ROOM_EVENT ataque): 9137'), err);
      assert.ok(err.includes(`mensagem acusada #1 de 1 (9137, ${suja.length} caracteres): ${suja}`), err);
      // As três mensagens com ids hexadecimais vieram antes e não acusaram (senão a falha seria a delas).
      for (const m of [SNAPSHOT_HEX, RECIBO_HEX, EVENTO_HEX]) assert.ok(!err.includes(m), 'acusou um id: ' + err);
    } finally {
      s.fechar();
    }
  });

test('(b) pelo arnês: só ids hexadecimais com «9137» — nenhuma acusação de canário (sai pelo tempo, não pelo alarme)',
  async () => {
    // O arnês só sai com 0 no fim do guião todo; aqui basta ver que, com as mensagens dadas, não acusa nada.
    const s = await servidorSintetico([SNAPSHOT_HEX, RECIBO_HEX, EVENTO_HEX]);
    try {
      const p = spawn(process.execPath, [ARNES, String(s.porta)], { stdio: ['ignore', 'pipe', 'pipe'] });
      let saida = '';
      p.stdout.on('data', (b) => { saida += b; });
      p.stderr.on('data', (b) => { saida += b; });
      await new Promise((r) => setTimeout(r, 3000));
      const ainda = p.exitCode === null;
      p.kill();
      assert.ok(ainda, 'o arnês saiu antes do tempo: ' + saida);
      assert.ok(!saida.includes('canários'), saida);
      assert.match(saida, /\[jogadora\] entrou|o orc está na mesa/);
    } finally {
      s.fechar();
    }
  });
