// Ordem 18 do CM-000009 — os quatro omissos da ordem 17 (README do servidor, 17-1..17-4).
// Cada teste falhava antes da correcção que o acompanha (conferido com o sala.js de 9314401) e passa depois.
// Só o Mestre vê as diferenças; o contrato (tipos de mensagem, campos, schemas, texto do journal) fica igual.
//
//  17-1  o travão do ROOM_JOIN guardava uma entrada por IP sem tecto de memória → tecto MAX_TRAVAO, podando primeiro
//        as entradas por bloquear (um IP bloqueado continua bloqueado durante a enxurrada).
//  17-2  sala restaurada em combate sem o Mestre ligado não ficava em pausa → a primeira entrada de outro lugar pausa-a
//        (E-C4); a volta do Mestre retoma-a; o Mestre a entrar primeiro não muda nada. SUBSTITUÍDO na ordem 22: quem
//        entra antes do Mestre fica no lobby (ordem22-decisoes.test.mjs).
//  17-3  o «Recomeçar» numa sala restaurada no fim corria com o motor novo → recusado, com o porquê só ao Mestre.
//  17-4  ROOM_RESYNC e RECEIPT_QUERY sem ritmo → 10/s por lugar (o número do §2), num balde próprio; fora do ritmo,
//        a recusa do excesso de comandos que já existia (ROOM_REJECT formato, id null).
//
// Parte C (varredura nova), cada achado com um teste que falhava antes:
//  V8   o ERRO `formato` (JSON inválido no adaptador; tipo desconhecido ou sala errada no núcleo) não contava para
//       fechar a ligação: só o ROOM_REJECT formato contava. Um cliente mandava lixo sem fim e nunca era fechado (§2).
//  V9   texto do WebSocket que não é UTF-8 válido era aceite (trocado por U+FFFD); a RFC 6455 §8.1 manda fechar (1007).
//  V10  um journal bem assinado com um `estado` sem a forma da sala (ex.: sem lugares) abria a sala, ou dava TypeError
//       em vez de «journal recusado»; a sala aberta assim rebentava no primeiro ROOM_JOIN.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { EventEmitter } from 'node:events';
import { criarSala, MAX_TRAVAO, TEXTOS_RECUSA } from '../nucleo/sala.js';
import { ErroJournal } from '../nucleo/journal.js';
import { jsonCanonico } from '../nucleo/util.js';
import { sha256Hex } from '../nucleo/sha256.js';
import { criarServidor } from '../adaptadores/node/servidor-ws.js';
import { montarMesa, exigirAplicada, rngDeterministico, relogio, fichasDeTeste, INICIATIVA, PIN, SENHAS } from './ajudantes.mjs';
import { criarMotorFalso } from './motor-falso.mjs';

const CONFIG = () => ({
  roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'auto', depurar: true,
  lugares: [
    { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
    { papel: 'mestre', nome: 'Mestre', pin: PIN },
  ],
});

function criarDe(restaurarDe, { motor = criarMotorFalso(), agora = relogio() } = {}) {
  return criarSala({ motores: motor, fichas: fichasDeTeste(), rng: rngDeterministico(7), agora, config: CONFIG(), restaurarDe });
}

/** Relógio parado que o teste faz andar. */
function relogioParado(inicio = Date.UTC(2026, 10, 11, 10, 0, 0)) {
  let t = inicio;
  const agora = () => t;
  agora.andar = (ms) => {
    t += ms;
  };
  return agora;
}

function sessao() {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }], ['lobo-teste', { x: 12, y: 2 }]]);
  const h = m.clientes.heroina;
  exigirAplicada(m.intencao('heroina', { tipo: 'atacar', alvoId: h.idPorNome('Orc'), arma: 'chicote-teste' }));
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  return m;
}

const lugarDe = (sala, papel) => Object.values(sala.depuracao.estado().lugares).find((s) => s.papel === papel);
const JOIN_HEROINA = { v: 2, type: 'ROOM_JOIN', papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina };
const JOIN_MESTRE = { v: 2, type: 'ROOM_JOIN', papel: 'mestre', pin: PIN };
const respostaA = (saidas, seatId) => saidas.filter((s) => s.seatId === seatId).map((s) => s.msg);
const reciboDe = (msgs) => msgs.find((x) => x.type === 'ROOM_RECEIPT' || x.type === 'ROOM_REJECT') ?? null;

function ligar(sala, join, ip) {
  const r = sala.entrar(join, { ip });
  assert.equal(r.ok, true, 'entrou');
  sala.conexaoAberta(r.seatId);
  return r;
}

// ------------------------------------------------------------------ 17-1: tecto do travão

test('ordem 18 (17-1): o travão do ROOM_JOIN tem tecto de memória; o IP bloqueado continua bloqueado na enxurrada', () => {
  const agora = relogioParado();
  const sala = criarSala({ motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(3), agora, config: CONFIG() });
  const errado = { v: 2, type: 'ROOM_JOIN', papel: 'jogadora', nome: 'Ninguém', senha: 'x' };

  for (let i = 0; i < 5; i++) assert.equal(sala.entrar(errado, { ip: 'atacante' }).ok, false);
  assert.equal(sala.entrar(JOIN_HEROINA, { ip: 'atacante' }).mensagens[0].codigo, 'bloqueado', 'bloqueado (E-P9)');

  // Enxurrada: muitos IPs diferentes, uma falha cada (IPv6), dentro do mesmo minuto.
  const n = MAX_TRAVAO + 1500;
  for (let i = 0; i < n; i++) sala.entrar(errado, { ip: '2001:db8::' + i.toString(16) });
  assert.ok(sala.depuracao.travao() <= MAX_TRAVAO, `travão com ${sala.depuracao.travao()} entradas (tecto ${MAX_TRAVAO})`);

  agora.andar(1000);
  const r = sala.entrar(JOIN_HEROINA, { ip: 'atacante' });
  assert.equal(r.ok, false);
  assert.equal(r.mensagens[0].codigo, 'bloqueado', 'a poda não solta o IP bloqueado');

  // Quem não estava bloqueado continua a entrar.
  assert.equal(sala.entrar(JOIN_HEROINA, { ip: '2001:db8::1' }).ok, true);
});

test('ordem 18 (17-1): só bloqueados acima do tecto — sai primeiro o que acaba primeiro e a memória fica limitada', () => {
  const agora = relogioParado();
  const sala = criarSala({ motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(4), agora, config: CONFIG() });
  const errado = { v: 2, type: 'ROOM_JOIN', papel: 'espectador', nome: 'Ninguém', senha: 'x' };
  for (let i = 0; i < MAX_TRAVAO + 50; i++) {
    for (let k = 0; k < 5; k++) sala.entrar(errado, { ip: 'b' + i });
  }
  assert.ok(sala.depuracao.travao() <= MAX_TRAVAO);
  assert.equal(sala.entrar(errado, { ip: 'b' + (MAX_TRAVAO + 49) }).mensagens[0].codigo, 'bloqueado', 'o mais novo continua bloqueado');
});

// ------------------------------------------------------------------ 17-2: restaurada em combate sem o Mestre

// SUBSTITUÍDO na ordem 22 (palavra do Mestre, 11/11/2026 14:27): quem entra antes do Mestre já não pausa a mesa;
// fica no lobby (sala de espera) e a batalha retoma com o Mestre dentro. Ver testes/ordem22-decisoes.test.mjs.
test('ordem 18 (17-2, depois da ordem 22): a jogadora antes do Mestre já não pausa a mesa', () => {
  const m = sessao();
  const sala2 = criarDe(m.sala.exportar());
  ligar(sala2, JOIN_HEROINA, '10.0.1.1');
  assert.equal(sala2.depuracao.estado().fase, 'combate', 'sem pausa: a jogadora está no lobby, à espera do Mestre');
  assert.ok(!sala2.depuracao.eventos().some((e) => e.tipo === 'pausa'));
});

test('ordem 18 (17-2, controlo): o Mestre entra primeiro — nada de pausa, nenhum evento novo de pausa', () => {
  const m = sessao();
  const sala2 = criarDe(m.sala.exportar());
  const eventosAntes = sala2.depuracao.eventos().length;
  ligar(sala2, JOIN_MESTRE, '10.0.2.2');
  ligar(sala2, JOIN_HEROINA, '10.0.2.1');
  assert.equal(sala2.depuracao.estado().fase, 'combate');
  assert.ok(!sala2.depuracao.eventos().slice(eventosAntes).some((e) => e.tipo === 'pausa'));
});

test('ordem 18 (17-2, controlo): uma sala nova (não restaurada) não muda — a jogadora no lobby antes do Mestre', () => {
  const m = montarMesa();
  m.entrar('heroina', { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina });
  assert.equal(m.sala.depuracao.estado().fase, 'lobby');
});

// ------------------------------------------------------------------ 17-3: «Recomeçar» com motor de outra versão

function sessaoNoFim() {
  const m = sessao();
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'terminar' }), 'terminar');
  assert.equal(m.sala.depuracao.estado().fase, 'fim');
  return m;
}

test('ordem 18 (17-3): sala restaurada no fim com motor de outra versão — o «Recomeçar» é recusado, só o Mestre sabe porquê', () => {
  const m = sessaoNoFim();
  const outro = criarMotorFalso();
  outro.MOTOR_SHA256 = 'e'.repeat(64);
  const sala2 = criarDe(m.sala.exportar(), { motor: outro });
  assert.equal(sala2.depuracao.estado().fase, 'fim');

  const rh = ligar(sala2, JOIN_HEROINA, '10.0.3.1');
  const rm = ligar(sala2, JOIN_MESTRE, '10.0.3.2');
  const seqParty = lugarDe(sala2, 'jogadora').seq;
  const rev = lugarDe(sala2, 'mestre').revision;
  const saidas = sala2.receber(rm.seatId, { v: 2, type: 'MASTER_SUPERVISOR', op: 'recomecar', cmdId: 'rec-1', revision: rev });
  assert.equal(reciboDe(respostaA(saidas, rm.seatId))?.motivo, 'acao_invalida');
  assert.equal(sala2.depuracao.estado().fase, 'fim', 'a batalha não recomeça com o motor novo (E-C11)');
  const recusa = sala2.depuracao.eventos().filter((e) => e.tipo === 'recusa').at(-1);
  assert.match(recusa?.soMestre?.detalhe ?? '', /^MOTOR_DIFERENTE/);
  assert.equal(respostaA(saidas, rh.seatId).length, 0, 'a Party não recebe nada');
  assert.equal(lugarDe(sala2, 'jogadora').seq, seqParty, 'nem no fluxo dela');
});

test('ordem 18 (17-3, controlo): o mesmo motor — o «Recomeçar» depois do restauro funciona como antes', () => {
  const m = sessaoNoFim();
  const sala2 = criarDe(m.sala.exportar());
  const rm = ligar(sala2, JOIN_MESTRE, '10.0.4.2');
  const rev = lugarDe(sala2, 'mestre').revision;
  const saidas = sala2.receber(rm.seatId, { v: 2, type: 'MASTER_SUPERVISOR', op: 'recomecar', cmdId: 'rec-2', revision: rev });
  assert.equal(reciboDe(respostaA(saidas, rm.seatId))?.estado, 'APLICADA');
  assert.equal(sala2.depuracao.estado().fase, 'combate');
});

// ------------------------------------------------------------------ 17-4: ritmo do RESYNC e da RECEIPT_QUERY

function salaParada() {
  const agora = relogioParado();
  const sala = criarSala({ motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(5), agora, config: CONFIG() });
  const rh = ligar(sala, JOIN_HEROINA, '10.0.5.1');
  return { sala, agora, seat: rh.seatId };
}

test('ordem 18 (17-4): RESYNC acima de 10/s por lugar → a recusa do excesso (ROOM_REJECT formato), sem o fluxo', () => {
  const { sala, agora, seat } = salaParada();
  for (let i = 0; i < 10; i++) {
    const r = respostaA(sala.receber(seat, { v: 2, type: 'ROOM_RESYNC', lastSeq: 0 }), seat);
    assert.ok(r.some((x) => x.type === 'ROOM_SNAPSHOT' || x.type === 'ROOM_EVENT'), 'dentro do ritmo: sincroniza');
  }
  const fora = respostaA(sala.receber(seat, { v: 2, type: 'ROOM_RESYNC', lastSeq: 0 }), seat);
  assert.deepEqual(fora, [{ v: 2, type: 'ROOM_REJECT', roomId: 'sala-teste', intentId: null, motivo: 'formato', texto: TEXTOS_RECUSA.formato }]);
  // A consulta de recibos partilha o balde.
  const q = respostaA(sala.receber(seat, { v: 2, type: 'RECEIPT_QUERY', intentIds: ['a', 'b'] }), seat);
  assert.equal(q.length, 1);
  assert.equal(q[0].type, 'ROOM_REJECT');
  assert.equal(q[0].motivo, 'formato');
  // Passado um segundo, volta a sincronizar.
  agora.andar(1000);
  const de = respostaA(sala.receber(seat, { v: 2, type: 'ROOM_RESYNC', lastSeq: 0 }), seat);
  assert.ok(de.some((x) => x.type === 'ROOM_SNAPSHOT' || x.type === 'ROOM_EVENT'));
});

test('ordem 18 (17-4): RECEIPT_QUERY acima de 10/s → recusa; os comandos têm o seu próprio balde', () => {
  const { sala, seat } = salaParada();
  for (let i = 0; i < 10; i++) {
    const r = respostaA(sala.receber(seat, { v: 2, type: 'RECEIPT_QUERY', intentIds: ['x' + i] }), seat);
    assert.equal(r[0].type, 'ROOM_RECEIPT');
    assert.equal(r[0].estado, 'DESCONHECIDA');
  }
  const fora = respostaA(sala.receber(seat, { v: 2, type: 'RECEIPT_QUERY', intentIds: ['y'] }), seat);
  assert.equal(fora[0].type, 'ROOM_REJECT');
  // O balde dos comandos não foi gasto pelas consultas: a intenção chega à regra (fora de combate → fora_da_vez).
  const rev = lugarDe(sala, 'jogadora').revision;
  const it = respostaA(sala.receber(seat, { v: 2, type: 'ROOM_INTENT', intentId: 'it-o18-2', revision: rev, acao: { tipo: 'encerrar' } }), seat);
  assert.notEqual(reciboDe(it)?.motivo, 'formato');
});

// ------------------------------------------------------------------ ligação WebSocket simulada (sem rede)

class SocketFalso extends EventEmitter {
  constructor() {
    super();
    this.saida = [];
    this.terminado = false;
  }
  setNoDelay() {}
  write(b) {
    this.saida.push(Buffer.from(b));
    return true;
  }
  end() { this.terminado = true; }
  destroy() {}
}

function quadroTexto(dados) {
  const mascara = Buffer.from([0x11, 0x22, 0x33, 0x44]);
  const n = dados.length;
  const cab = n < 126 ? Buffer.from([0x81, 0x80 | n]) : Buffer.from([0x81, 0x80 | 126, n >> 8, n & 0xff]);
  return Buffer.concat([cab, mascara, Buffer.from(dados.map((b, i) => b ^ mascara[i & 3]))]);
}

function ligarWs(servidor, ip) {
  const socket = new SocketFalso();
  const req = {
    url: '/ws',
    method: 'GET', httpVersionMajor: 1, httpVersionMinor: 1, // ordem 25 (V20): o que um pedido real traz
    headers: { 'sec-websocket-key': 'dGhlIHNhbXBsZSBub25jZQ==', 'sec-websocket-version': '13', upgrade: 'websocket', host: 'local' },
    socket: { remoteAddress: ip },
  };
  servidor.emit('upgrade', req, socket, Buffer.alloc(0));
  return {
    socket,
    bytes: (b) => socket.emit('data', quadroTexto(Buffer.from(b))),
    texto: (t) => socket.emit('data', quadroTexto(Buffer.from(t, 'utf8'))),
    json: (o) => socket.emit('data', quadroTexto(Buffer.from(JSON.stringify(o), 'utf8'))),
  };
}
const codigoDeFecho = (socket) => {
  const q = socket.saida.slice(1).find((b) => (b[0] & 0x0f) === 0x8);
  return q ? q.readUInt16BE(2) : null;
};
function mensagensWs(socket) {
  const out = [];
  for (const b of socket.saida.slice(1)) {
    if ((b[0] & 0x0f) !== 0x1) continue;
    let len = b[1] & 0x7f;
    let off = 2;
    if (len === 126) { len = b.readUInt16BE(2); off = 4; }
    out.push(JSON.parse(b.subarray(off, off + len).toString('utf8')));
  }
  return out;
}

// ------------------------------------------------------------------ V8: o ERRO formato também conta para fechar

test('ordem 18 V8: JSON inválido repetido fecha a ligação (1008), como as outras rejeições de formato (§2)', () => {
  const servidor = criarServidor({ sala: criarDe(null) });
  const a = ligarWs(servidor, '10.0.8.1');
  for (let i = 0; i < 5; i++) a.texto('{isto não é json');
  assert.equal(codigoDeFecho(a.socket), 1008);
  // Controlo: 4 seguidas não fecham.
  const b = ligarWs(servidor, '10.0.8.2');
  for (let i = 0; i < 4; i++) b.texto('[');
  assert.equal(codigoDeFecho(b.socket), null);
  assert.equal(mensagensWs(b.socket).filter((x) => x.type === 'ERRO' && x.codigo === 'formato').length, 4);
  // ROOM_JOIN mal formado (não passa pelo travão de credenciais) também conta.
  const c = ligarWs(servidor, '10.0.8.5');
  for (let i = 0; i < 5; i++) c.json({ type: 'ROOM_JOIN', papel: 'mestre' }); // sem `v`: ERRO formato
  assert.equal(codigoDeFecho(c.socket), 1008);
  servidor.close();
});

test('ordem 18 V8: tipo desconhecido repetido depois de entrar (ERRO formato do núcleo) também fecha', () => {
  const servidor = criarServidor({ sala: criarDe(null) });
  const a = ligarWs(servidor, '10.0.8.3');
  a.json({ ...JOIN_HEROINA, roomId: 'sala-teste' });
  assert.ok(mensagensWs(a.socket).some((x) => x.type === 'ROOM_WELCOME'));
  for (let i = 0; i < 5; i++) a.json({ v: 2, type: 'NAO_EXISTE' });
  assert.equal(codigoDeFecho(a.socket), 1008);
  // Controlo: um RESYNC bem feito pelo meio repõe a contagem, como antes.
  const b = ligarWs(servidor, '10.0.8.4');
  b.json({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'mestre', pin: PIN });
  for (let i = 0; i < 4; i++) b.json({ v: 2, type: 'NAO_EXISTE' });
  b.json({ v: 2, type: 'ROOM_RESYNC', lastSeq: 0 });
  for (let i = 0; i < 4; i++) b.json({ v: 2, type: 'NAO_EXISTE' });
  assert.equal(codigoDeFecho(b.socket), null);
  servidor.close();
});

// ------------------------------------------------------------------ V9: UTF-8 inválido (RFC 6455 §8.1)

test('ordem 18 V9: texto que não é UTF-8 válido fecha a ligação com 1007; UTF-8 com acentos passa', () => {
  const servidor = criarServidor({ sala: criarDe(null) });
  const a = ligarWs(servidor, '10.0.9.1');
  a.bytes([0x7b, 0xff, 0xfe, 0x7d]);
  assert.equal(codigoDeFecho(a.socket), 1007);
  assert.equal(mensagensWs(a.socket).length, 0, 'nada chega ao núcleo');
  const b = ligarWs(servidor, '10.0.9.2');
  b.json({ ...JOIN_HEROINA, roomId: 'sala-teste' }); // «Heroína» leva um acento
  assert.equal(codigoDeFecho(b.socket), null);
  assert.ok(mensagensWs(b.socket).some((x) => x.type === 'ROOM_WELCOME'));
  servidor.close();
});

// ------------------------------------------------------------------ V10: estado restaurado sem a forma da sala

function assinado(corpo) {
  const t = jsonCanonico(corpo);
  return t + '\n' + 'sha256:' + sha256Hex(t) + '\n';
}

test('ordem 18 V10: journal bem assinado com um estado sem a forma da sala → ErroJournal, a sala não abre', () => {
  const valido = JSON.parse(sessao().sala.exportar().split('\n')[0]);
  const comEstado = (mexer) => {
    const c = JSON.parse(JSON.stringify(valido));
    mexer(c.estado);
    return assinado(c);
  };
  const casos = {
    'estado mínimo': assinado({ ...valido, estado: { roomId: 'x' } }),
    'outro formato': comEstado((e) => { e.formato = 'outra/9'; }),
    'sem lugares': comEstado((e) => { delete e.lugares; }),
    'lugares lista': comEstado((e) => { e.lugares = []; }),
    'lugar null': comEstado((e) => { e.lugares[Object.keys(e.lugares)[0]] = null; }),
    'sem Mestre': comEstado((e) => { for (const s of Object.values(e.lugares)) if (s.papel === 'mestre') s.papel = 'espectador'; }),
    'figuras null': comEstado((e) => { e.figuras = null; }),
    'fase desconhecida': comEstado((e) => { e.fase = 'nada'; }),
    'roomId número': comEstado((e) => { e.roomId = 7; }),
    'cartões objecto': comEstado((e) => { e.cartoes = {}; }),
  };
  for (const [rotulo, texto] of Object.entries(casos)) {
    // ErroJournal é o que o abrirSalaComJournal do adaptador converte em «journal recusado» (sala não abre).
    assert.throws(() => criarDe(texto), ErroJournal, rotulo);
  }
  // Controlo: o journal verdadeiro (re-assinado igual) abre.
  assert.doesNotThrow(() => criarDe(assinado(valido)));
});
