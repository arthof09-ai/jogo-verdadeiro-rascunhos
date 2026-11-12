// Ordem 25 do CM-000009, item 1 — varredura do servidor (V20+), pela superfície que faltava ler: o adaptador Node
// inteiro (handshake, enquadramento, HTTP estático, journal em disco), journal.js e ambiente.js. Cada teste de
// correcção falhava antes (conferido com o servidor-ws.js de aa56f97) e passa depois; os de controlo passavam antes.
//
//  V20  O handshake aceitava pedidos que a RFC 6455 §4.2.1 manda recusar («the server MUST stop processing the
//       client's handshake and return an HTTP response with an appropriate error code (such as 400 Bad Request)»):
//       método que não é GET (POST com «Upgrade: websocket» recebia 101), HTTP/1.0, e um Sec-WebSocket-Key que não é
//       base64 de 16 bytes («x», vazio). Agora 400 e nenhuma ligação nasce. O pedido certo (o do Godot e o do
//       WebSocket do Node) continua a dar 101.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import net from 'node:net';
import { criarServidor } from '../adaptadores/node/servidor-ws.js';

const salaMuda = {
  entrar: () => ({ ok: false, mensagens: [], saidas: [] }),
  receber: () => [],
  conexaoAberta: () => [],
  conexaoFechada: () => [],
  exportar: () => '',
};

async function comServidor(fn) {
  const servidor = criarServidor({ sala: salaMuda });
  await new Promise((r) => servidor.listen(0, '127.0.0.1', r));
  try {
    await fn(servidor.address().port);
  } finally {
    servidor.close();
  }
}

/** Manda o pedido cru e devolve a linha de estado da resposta. */
function pedir(porta, linha, cabecalhos) {
  return new Promise((res) => {
    const c = net.connect(porta, '127.0.0.1', () => {
      c.write(`${linha}\r\nHost: 127.0.0.1:${porta}\r\n${cabecalhos.map((h) => h + '\r\n').join('')}\r\n`);
    });
    let d = '';
    const fim = () => res(d.split('\r\n')[0] || '(fechou sem resposta)');
    c.on('data', (b) => {
      d += b;
      if (d.includes('\r\n')) {
        c.destroy();
        fim();
      }
    });
    c.on('error', fim);
    c.on('close', fim);
  });
}

const CHAVE = 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ=='; // RFC 6455 §1.3 (16 bytes)
const BASE = ['Upgrade: websocket', 'Connection: Upgrade', 'Sec-WebSocket-Version: 13'];

test('V20: handshake com método que não é GET é recusado (400), não 101', async () => {
  await comServidor(async (porta) => {
    for (const metodo of ['POST', 'PUT', 'DELETE']) {
      const r = await pedir(porta, `${metodo} /ws HTTP/1.1`, [...BASE, CHAVE, 'Content-Length: 0']);
      assert.match(r, /^HTTP\/1\.1 400/, `${metodo}: ${r}`);
    }
  });
});

test('V20: handshake em HTTP/1.0 é recusado (400)', async () => {
  await comServidor(async (porta) => {
    const r = await pedir(porta, 'GET /ws HTTP/1.0', [...BASE, CHAVE]);
    assert.match(r, /^HTTP\/1\.1 400/, r);
  });
});

test('V20: Sec-WebSocket-Key que não é base64 de 16 bytes é recusada (400)', async () => {
  await comServidor(async (porta) => {
    for (const chave of ['x', '', 'dGhlIHNhbXBsZSBub25jZQ', 'dGhlIHNhbXBsZSBub25jZSE=', 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA', '!!!!!!!!!!!!!!!!!!!!!!==']) {
      const r = await pedir(porta, 'GET /ws HTTP/1.1', [...BASE, `Sec-WebSocket-Key: ${chave}`]);
      assert.match(r, /^HTTP\/1\.1 400/, `chave ${JSON.stringify(chave)}: ${r}`);
    }
  });
});

test('V20 controlo: o handshake certo continua a dar 101 (e o WebSocket do Node liga)', async () => {
  await comServidor(async (porta) => {
    const r = await pedir(porta, 'GET /ws HTTP/1.1', [...BASE, CHAVE]);
    assert.match(r, /^HTTP\/1\.1 101/, r);
    const r2 = await pedir(porta, 'GET /ws HTTP/1.1', ['Upgrade: WebSocket', 'Connection: keep-alive, Upgrade', 'Sec-WebSocket-Version: 13', 'Sec-WebSocket-Key: AQIDBAUGBwgJCgsMDQ4PEA==']);
    assert.match(r2, /^HTTP\/1\.1 101/, r2);
    if (typeof WebSocket === 'function') {
      const aberto = await new Promise((res) => {
        const ws = new WebSocket(`ws://127.0.0.1:${porta}/ws`);
        ws.onopen = () => {
          ws.close();
          res(true);
        };
        ws.onerror = () => res(false);
      });
      assert.equal(aberto, true);
    }
  });
});
