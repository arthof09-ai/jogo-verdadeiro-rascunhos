// Ordem PLANO-2-F2 (CM-000009, 2026-11-23) — o servidor de mesa nos aparelhos da casa.
//  - JV3.4: os links da mesa saem só dos IPv4 da rede local; a página /qr tem o QR de cada um (e o da medição);
//    o QR é bem formado (a leitura por um decodificador independente está em aparelhos/conferir-qr.py, no CI).
//  - V1.0: o POST /medicao só aceita o JSON da medição (formato certo, números), até 16 KB; sem pasta, 404.
// Os pedidos HTTP vão pelo evento 'request' do servidor (sem rede, como os outros testes do adaptador).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { EventEmitter } from 'node:events';
import { criarSala } from '../nucleo/sala.js';
import * as Adaptador from '../adaptadores/node/servidor-ws.js';
import { codificarQR, capacidade, qrEmSvg, qrNoTerminal } from '../adaptadores/node/qr.js';
import { rngDeterministico, relogio, fichasDeTeste, INICIATIVA, PIN, SENHAS } from './ajudantes.mjs';
import { criarMotorFalso } from './motor-falso.mjs';

const { criarServidor, ipsDaRede, urlsDaRede, paginaQr, conferirMedicao, textoQrDoTerminal } = Adaptador;

function novaSala() {
  return criarSala({
    motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(7), agora: relogio(),
    config: {
      roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'auto',
      lugares: [
        { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
        { papel: 'mestre', nome: 'Mestre', pin: PIN },
      ],
    },
  });
}

/** Um pedido HTTP falso pelo evento 'request'; devolve a promessa de {codigo, cabecalhos, corpo}. */
function pedir(servidor, { metodo = 'GET', url = '/', corpo = null, cabecalhos = {} } = {}) {
  return new Promise((resolver) => {
    const req = new EventEmitter();
    Object.assign(req, { method: metodo, url, headers: cabecalhos, socket: { remoteAddress: '192.168.1.50' } });
    req.destroy = () => {};
    const res = {
      headersSent: false,
      writeHead(codigo, cab = {}) {
        this.codigo = codigo;
        this.cab = cab;
        this.headersSent = true;
        return this;
      },
      end(b) {
        resolver({ codigo: this.codigo, cabecalhos: this.cab, corpo: b ? Buffer.from(b).toString('utf8') : '' });
        return this;
      },
    };
    servidor.emit('request', req, res);
    if (corpo !== null) req.emit('data', Buffer.from(corpo, 'utf8'));
    req.emit('end');
  });
}

const INTERFACES = {
  'Wi-Fi': [{ address: '192.168.1.20', family: 'IPv4', internal: false }, { address: 'fe80::1', family: 'IPv6', internal: false }],
  Loopback: [{ address: '127.0.0.1', family: 'IPv4', internal: true }],
  Ethernet: [{ address: '10.0.0.7', family: 4, internal: false }],
  Tailscale: [{ address: '100.101.102.103', family: 'IPv4', internal: false }],
  Publico: [{ address: '8.8.8.8', family: 'IPv4', internal: false }],
  Docker: [{ address: '172.17.0.1', family: 'IPv4', internal: false }],
  Fora: [{ address: '172.32.0.1', family: 'IPv4', internal: false }],
};

const MEDICAO = {
  formato: 'medicao-v1.0/1', quadros: 3300, aquecimento_s: 5, janela_s: 55, fps_mediana: 59.9, fps_p5: 41.2,
  chamadas_mediana: 180, chamadas_max: 230, gpu: 'WebGL2', viewport: [1920, 1080], dpr: 2.625, plataforma: 'Web',
};

test('JV3.4: os links da mesa são só os IPv4 da rede local, 192.168 primeiro (sem loopback, Tailscale nem públicos)', () => {
  assert.deepEqual(ipsDaRede(INTERFACES), ['192.168.1.20', '10.0.0.7', '172.17.0.1']);
  assert.deepEqual(urlsDaRede(8080, INTERFACES), ['http://192.168.1.20:8080/', 'http://10.0.0.7:8080/', 'http://172.17.0.1:8080/']);
  assert.deepEqual(urlsDaRede(8080, {}), []);
});

test('JV3.4: a página /qr tem o QR (SVG) de cada link e o da medição; sem links, diz o que fazer', async () => {
  const s = criarServidor({ sala: novaSala(), urlsMesa: () => ['http://192.168.1.20:8080/'] });
  const r = await pedir(s, { url: '/qr' });
  assert.equal(r.codigo, 200);
  assert.match(r.cabecalhos['Content-Type'], /^text\/html/);
  assert.match(r.cabecalhos['Content-Security-Policy'], /default-src 'none'/);
  assert.equal((r.corpo.match(/<svg /g) ?? []).length, 2);
  assert.ok(r.corpo.includes('http://192.168.1.20:8080/?medir=1'));
  assert.ok(!r.corpo.includes('<script'));
  assert.ok(paginaQr([]).includes('Não encontrei nenhum endereço da rede local'));
  assert.ok(paginaQr(['http://x/"<b>']).includes('http://x/&quot;&lt;b&gt;'), 'o link é escapado no HTML');
  const t = textoQrDoTerminal(['http://192.168.1.20:8080/']);
  assert.ok(t.includes('http://192.168.1.20:8080/qr') && t.includes('http://192.168.1.20:8080/?medir=1'));
});

test('JV3.4: o QR é bem formado (tamanho 4v+17, padrões de posição, versão mínima que cabe, até à 10)', () => {
  for (const [texto, versao] of [['http://192.168.1.20:8080/', 2], ['http://192.168.100.200:65535/?medir=1', 3]]) {
    const q = codificarQR(texto);
    assert.equal(q.versao, versao);
    assert.equal(q.tamanho, versao * 4 + 17);
    // O canto superior esquerdo: o padrão de posição 7×7 (borda escura, anel claro, miolo 3×3 escuro).
    const linha0 = q.modulos[0].slice(0, 8).map((v) => (v ? 1 : 0)).join('');
    const linha1 = q.modulos[1].slice(0, 8).map((v) => (v ? 1 : 0)).join('');
    const linha2 = q.modulos[2].slice(0, 8).map((v) => (v ? 1 : 0)).join('');
    assert.deepEqual([linha0, linha1, linha2], ['11111110', '10000010', '10111010']);
    assert.equal(q.modulos[q.tamanho - 8][8], true, 'o módulo escuro fixo');
  }
  assert.equal(capacidade(1), 14);
  assert.equal(capacidade(10), 213);
  assert.equal(codificarQR('x'.repeat(213)).versao, 10);
  assert.throws(() => codificarQR('x'.repeat(214)), /não cabem/);
  assert.match(qrEmSvg('http://a/'), /^<svg [^>]*viewBox="0 0 /);
  assert.equal(qrNoTerminal('http://a/').split('\n').length, Math.ceil((21 + 8) / 2));
});

test('V1.0: o JSON da medição — formato e números obrigatórios', () => {
  assert.deepEqual(conferirMedicao(JSON.stringify(MEDICAO)), MEDICAO);
  assert.equal(conferirMedicao('{'), null);
  assert.equal(conferirMedicao('[]'), null);
  assert.equal(conferirMedicao(JSON.stringify({ ...MEDICAO, formato: 'outro' })), null);
  assert.equal(conferirMedicao(JSON.stringify({ ...MEDICAO, fps_p5: '41' })), null);
  const { quadros, ...semQuadros } = MEDICAO;
  assert.equal(conferirMedicao(JSON.stringify(semQuadros)), null);
  assert.equal(quadros, 3300);
});

test('V1.0: POST /medicao sem pasta dá 404; GET dá 405; acima de 16 KB, 413; mal formado, 400', async () => {
  const sem = criarServidor({ sala: novaSala() });
  assert.equal((await pedir(sem, { metodo: 'POST', url: '/medicao', corpo: JSON.stringify(MEDICAO) })).codigo, 404);
  const com = criarServidor({ sala: novaSala(), medicoes: '/pasta-que-nao-se-escreve-neste-teste' });
  assert.equal((await pedir(com, { metodo: 'GET', url: '/medicao' })).codigo, 405);
  assert.equal((await pedir(com, { metodo: 'POST', url: '/medicao', corpo: 'x', cabecalhos: { 'content-length': '20000' } })).codigo, 413);
  assert.equal((await pedir(com, { metodo: 'POST', url: '/medicao', corpo: 'x'.repeat(17 * 1024) })).codigo, 413);
  assert.equal((await pedir(com, { metodo: 'POST', url: '/medicao', corpo: '{"formato":"medicao-v1.0/1"}' })).codigo, 400);
});

test('JV3.4: as rotas novas não mexem na estática nem no ws (sem pasta estática, / continua 404)', async () => {
  const s = criarServidor({ sala: novaSala() });
  assert.equal((await pedir(s, { url: '/' })).codigo, 404);
  assert.equal((await pedir(s, { url: '/qr/../index.html' })).codigo, 404);
});
