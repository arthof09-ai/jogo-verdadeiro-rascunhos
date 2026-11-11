// Ordem 17 do CM-000009 — omissos implementáveis (parte B) e varredura crítica do servidor (parte C).
// Cada teste aqui falhava antes da correcção que o acompanha (conferido; os de Windows, no Windows) e passa depois.
// Tudo é MESTRE-ONLY: nenhum teste muda o que a Party recebe; vários conferem que a Party não vê nada novo.
//
//  B1 (omisso 16-2, a parte que não precisa da palavra do Mestre): o journal que falhou a gravação volta a tentar
//     sozinho (no relógio do ping do adaptador), mesmo sem commit novo; e não deixa o «.a-gravar» a meio.
//  B2 (omisso 15-6, o lado do Mestre): a intenção de atacar/curar recusada por alcance leva o porquê ao Mestre
//     (detalhe no evento interno `recusa`); a Party vê a mesma recusa de sempre.
//  V1  restaurar com motor de outra versão numa sala JÁ em pausa (Mestre desligado): a volta do Mestre retomava a mesa
//      com o motor novo (E-C11 furado).
//  V2  restaurarJournal: corpo bem assinado (sha256 recalculável) mas com a estrutura errada dava TypeError, não
//      ErroJournal (o adaptador deixava-o escapar em vez de «journal recusado»).
//  V3  journal: commit guardava eventos e mensagens por referência; quem mexesse numa saída (o adaptador, um teste)
//      mudava o journal exportado e partia a cadeia do restauro.
//  V4  conferirCaminhoJournal no Windows: a pasta estática com outras maiúsculas deixava o journal cair lá (E-P13).
//  V5  ficheiros estáticos no Windows: «\» no URL e o nome curto 8.3 («SEGRED~1») contornavam «nada de dotfiles».
//  V6  a mesma ligação a repetir o ROOM_JOIN dava ao Mestre um alerta falso de «segunda_ligacao».
//  V7  quadros de controlo do WebSocket fragmentados ou com mais de 125 bytes eram aceites (RFC 6455 §5.5).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { EventEmitter } from 'node:events';
import path from 'node:path';
import { writeFileSync, existsSync, mkdtempSync, mkdirSync, readdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { criarJournal, restaurarJournal, ErroJournal } from '../nucleo/journal.js';
import { jsonCanonico } from '../nucleo/util.js';
import { sha256Hex } from '../nucleo/sha256.js';
import { criarSala, TEXTOS_RECUSA } from '../nucleo/sala.js';
import {
  conferirCaminhoJournal, criarGravadorJournal, lerJournalDoDisco, criarServidor,
} from '../adaptadores/node/servidor-ws.js';
import { montarMesa, exigirAplicada, recibo, rngDeterministico, relogio, fichasDeTeste, INICIATIVA, PIN, SENHAS } from './ajudantes.mjs';
import { criarMotorFalso } from './motor-falso.mjs';

const PASTA_DISCO = process.env.JOURNAL_DISCO_PASTA || tmpdir();
const PODE_ESCREVER = !process.permission || process.permission.has('fs.write', PASTA_DISCO);
const SEM_DISCO = PODE_ESCREVER ? false : 'sem escrita (passo só de leitura): os testes de disco correm no job protocolo do CI';
const pastaNova = () => mkdtempSync(path.join(PASTA_DISCO, 'o17-'));

function sessao() {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }], ['lobo-teste', { x: 12, y: 2 }]]);
  const h = m.clientes.heroina;
  exigirAplicada(m.intencao('heroina', { tipo: 'atacar', alvoId: h.idPorNome('Orc'), arma: 'chicote-teste' }));
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  return m;
}

/** A mesma config do montarMesa (os lugares têm de bater para a heroína e o Mestre voltarem). */
function criarDe(restaurarDe, motor = criarMotorFalso()) {
  const config = {
    roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'auto', depurar: true,
    lugares: [
      { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
      { papel: 'mestre', nome: 'Mestre', pin: PIN },
    ],
  };
  return criarSala({ motores: motor, fichas: fichasDeTeste(), rng: rngDeterministico(7), agora: relogio(), config, restaurarDe });
}

const lugarDe = (sala, papel) => Object.values(sala.depuracao.estado().lugares).find((s) => s.papel === papel);

// ------------------------------------------------------------------ V1: motor de outra versão numa sala já em pausa

test('ordem 17 V1: motor de outra versão ao restaurar uma sala já em pausa (Mestre desligado) — a volta do Mestre não a retoma', () => {
  const m = sessao();
  m.sair('mestre'); // E-C4: zero ligações de Mestre → pausa por desconexão
  const antes = m.sala.depuracao.estado();
  assert.equal(antes.fase, 'pausa');
  assert.equal(antes.pausa.origem, 'desconexao');
  const seqParty = lugarDe(m.sala, 'jogadora').seq;

  const outro = criarMotorFalso();
  outro.MOTOR_SHA256 = 'f'.repeat(64);
  const sala2 = criarDe(m.sala.exportar(), outro);
  const est = sala2.depuracao.estado();
  assert.equal(est.fase, 'pausa');
  assert.equal(est.pausa.origem, 'motor', 'a pausa passa a ser do motor (E-C11): só a migração a levanta');
  assert.equal(lugarDe(sala2, 'jogadora').seq, seqParty, 'a Party não recebe nada novo');
  const ev = sala2.depuracao.eventos().at(-1);
  assert.equal(ev.tipo, 'pausa', 'fica no registo do Mestre (evento interno, fora da lista da Party)');
  assert.equal(ev.soMestre.origem, 'motor');
  assert.equal(ev.soMestre.origemAnterior, 'desconexao');

  // O Mestre volta (JOIN + RESYNC): antes desta ordem, o RESYNC retomava a mesa com o motor novo.
  const r = sala2.entrar({ v: 2, type: 'ROOM_JOIN', papel: 'mestre', pin: PIN }, { ip: '10.0.0.50' });
  assert.equal(r.ok, true);
  sala2.conexaoAberta(r.seatId);
  const saidas = sala2.receber(r.seatId, { v: 2, type: 'ROOM_RESYNC', lastSeq: 0 });
  assert.ok(!saidas.some((s) => s.msg.type === 'ROOM_RESUMED'), 'nada de ROOM_RESUMED');
  assert.equal(sala2.depuracao.estado().fase, 'pausa');
  const rev = lugarDe(sala2, 'mestre').revision;
  const resp = sala2.receber(r.seatId, { v: 2, type: 'MASTER_RESUME', cmdId: 'retomar-1', revision: rev });
  const rec = resp.find((s) => s.msg.type === 'ROOM_RECEIPT' || s.msg.type === 'ROOM_REJECT')?.msg;
  assert.equal(rec?.motivo, 'acao_invalida', 'o MASTER_RESUME continua recusado na pausa do motor');
  assert.equal(sala2.depuracao.estado().fase, 'pausa');
  assert.equal(lugarDe(sala2, 'jogadora').seq, seqParty, 'a Party continua sem nada novo');
});

test('ordem 17 V1 (controlo): o mesmo motor numa sala em pausa por desconexão — a volta do Mestre retoma, como antes', () => {
  const m = sessao();
  m.sair('mestre');
  const sala2 = criarDe(m.sala.exportar());
  assert.equal(sala2.depuracao.estado().pausa.origem, 'desconexao');
  assert.equal(sala2.exportar(), m.sala.exportar(), 'restaurar sem mudar nada');
  const r = sala2.entrar({ v: 2, type: 'ROOM_JOIN', papel: 'mestre', pin: PIN }, { ip: '10.0.0.51' });
  sala2.conexaoAberta(r.seatId);
  sala2.receber(r.seatId, { v: 2, type: 'ROOM_RESYNC', lastSeq: 0 });
  assert.equal(sala2.depuracao.estado().fase, 'combate');
});

// ------------------------------------------------------------------ V2: estrutura do corpo do journal

function assinado(corpo) {
  const t = jsonCanonico(corpo);
  return t + '\n' + 'sha256:' + sha256Hex(t) + '\n';
}
const CADEIA_ZERO = '0'.repeat(64);
const corpoBase = (extra = {}) => ({
  formato: 'journal-sala/1', marca: 'MESTRE-ONLY', eventos: [], estado: { roomId: 'x' }, recibos: [], fluxos: {}, hashCadeia: CADEIA_ZERO, ...extra,
});

test('ordem 17 V2: corpo bem assinado mas com a estrutura errada → ErroJournal (nunca TypeError)', () => {
  const casos = {
    'fluxos null': corpoBase({ fluxos: null }),
    'fluxos lista': corpoBase({ fluxos: [[]] }),
    'fluxo com null': corpoBase({ fluxos: { s1: [null] } }),
    'evento null': corpoBase({ eventos: [null] }),
    'evento lista': corpoBase({ eventos: [[1]] }),
    'recibo que não é par': corpoBase({ recibos: [5] }),
    'recibo sem objecto': corpoBase({ recibos: [['s\u0000id']] }),
    'recibo com chave que não é texto': corpoBase({ recibos: [[7, {}]] }),
    'estado texto': corpoBase({ estado: 'texto' }),
    'estado lista': corpoBase({ estado: [1] }),
    'hashCadeia número': corpoBase({ hashCadeia: 0 }),
  };
  for (const [rotulo, corpo] of Object.entries(casos)) {
    const texto = assinado(corpo);
    assert.throws(() => restaurarJournal(texto), ErroJournal, rotulo);
    // Na sala também: o abrirSalaComJournal do adaptador só converte ErroJournal em «journal recusado».
    assert.throws(() => criarDe(texto), ErroJournal, rotulo + ' (criarSala)');
  }
  // O corpo mínimo bem formado continua a restaurar.
  assert.ok(restaurarJournal(assinado(corpoBase())));
});

// ------------------------------------------------------------------ V3: o journal não partilha referências

test('ordem 17 V3: mexer no que se passou ao commit (ou no que o journal devolve) não muda o journal', () => {
  const j = criarJournal({ estadoInicial: { a: 1 } });
  const ev = { journalSeq: 1, ts: 't', tipo: 'x', dados: { v: 1 }, soMestre: null };
  const msg = { seq: 1, dados: { v: 1 } };
  const rec = { estado: 'APLICADA' };
  j.commit({ estado: { a: 2 }, eventos: [ev], recibos: [['s\u0000id', rec]], fluxos: { s: [msg] } });
  const exp = j.exportar();
  ev.dados.v = 999;
  msg.dados.v = 999;
  rec.estado = 'MEXIDO';
  assert.equal(j.exportar(), exp, 'a exportação não mudou');
  assert.ok(restaurarJournal(j.exportar()), 'a cadeia continua a conferir');
  // O que o journal devolve também não serve para o mudar.
  const f = j.fluxo('s');
  try { f.push({ seq: 2 }); } catch { /* lista só de leitura também serve */ }
  try { j.fluxo('s')[0].dados.v = 5; } catch { /* congelado */ }
  try { j.recibo('s\u0000id').estado = 'X'; } catch { /* congelado */ }
  assert.equal(j.exportar(), exp, 'nem pelo que devolve');
});

test('ordem 17 V3: o adaptador que mexa numa mensagem entregue não muda o registo da sala', () => {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }]]);
  const h = m.clientes.heroina;
  const saidas = m.sala.receber(h.seatId, {
    v: 2, roomId: 'sala-teste', type: 'ROOM_INTENT', intentId: 'golpe-v3', revision: h.revision,
    acao: { tipo: 'atacar', alvoId: h.idPorNome('Orc'), arma: 'chicote-teste' },
  });
  const exp = m.sala.exportar();
  for (const s of saidas) {
    if (s.msg.type === 'ROOM_EVENT') {
      try { s.msg.dados = { mexido: true }; } catch { /* congelada também serve */ }
    }
  }
  assert.equal(m.sala.exportar(), exp, 'o fluxo gravado não mudou');
  // E o que o RESYNC devolve (o fluxo gravado) também não serve para o mudar.
  const sinc = m.sala.receber(h.seatId, { v: 2, roomId: 'sala-teste', type: 'ROOM_RESYNC', lastSeq: 0 });
  for (const s of sinc) if (s.msg.type === 'ROOM_EVENT') try { s.msg.seq = -1; } catch { /* congelada */ }
  assert.equal(m.sala.exportar(), exp);
  assert.ok(restaurarJournal(m.sala.exportar()));
});

// ------------------------------------------------------------------ V4: caminho do journal no Windows

test('ordem 17 V4: no Windows, a pasta estática com outras maiúsculas também apanha o journal (E-P13)', () => {
  const w = path.win32;
  assert.throws(() => conferirCaminhoJournal('c:\\mesa\\CLIENTE\\registo-MESTRE-ONLY.json', 'C:\\Mesa\\cliente', w), ErroJournal);
  assert.throws(() => conferirCaminhoJournal('C:\\MESA\\Cliente\\sub\\registo-MESTRE-ONLY.json', 'c:\\mesa\\cliente\\', w), ErroJournal);
  assert.throws(() => conferirCaminhoJournal('C:\\Mesa\\cliente', 'C:\\Mesa\\cliente', w), ErroJournal);
  // Fora da pasta continua a valer (incluindo uma pasta irmã com o mesmo começo de nome).
  assert.equal(conferirCaminhoJournal('C:\\Mesa\\privado\\registo-MESTRE-ONLY.json', 'C:\\Mesa\\cliente', w), 'C:\\Mesa\\privado\\registo-MESTRE-ONLY.json');
  assert.equal(conferirCaminhoJournal('C:\\Mesa\\cliente-velho\\registo-MESTRE-ONLY.json', 'C:\\Mesa\\cliente', w),
    'C:\\Mesa\\cliente-velho\\registo-MESTRE-ONLY.json');
  // No POSIX as maiúsculas contam (outra pasta), como antes.
  const p = path.posix;
  assert.equal(conferirCaminhoJournal('/srv/Cliente/registo-MESTRE-ONLY.json', '/srv/cliente', p), '/srv/Cliente/registo-MESTRE-ONLY.json');
  assert.throws(() => conferirCaminhoJournal('/srv/cliente/registo-MESTRE-ONLY.json', '/srv/cliente', p), ErroJournal);
});

// ------------------------------------------------------------------ B1: a gravação que falhou volta a tentar

test('ordem 17 B1 (disco): a gravação que falha fica pendente e não deixa o «.a-gravar» para trás', { skip: SEM_DISCO }, () => {
  const sala = criarDe(null);
  const pasta = pastaNova();
  const caminho = path.join(pasta, 'registo-MESTRE-ONLY.json');
  mkdirSync(caminho); // o nome está tomado por uma pasta: a troca de nome falha
  const erros = [];
  const g = criarGravadorJournal({ sala, caminho, registo: (t) => erros.push(t) });
  assert.equal(g.gravar(), false);
  assert.equal(g.pendente(), true, 'fica pendente');
  assert.equal(erros.length, 1);
  assert.deepEqual(readdirSync(pasta), ['registo-MESTRE-ONLY.json'], 'nenhum .a-gravar a meio');
});

test('ordem 17 B1 (disco): o relógio do adaptador volta a tentar a gravação pendente, sem commit novo', { skip: SEM_DISCO }, (t) => {
  t.mock.timers.enable({ apis: ['setInterval'] });
  const sala = criarDe(null);
  const pasta = path.join(pastaNova(), 'ainda-nao-existe');
  const caminho = path.join(pasta, 'registo-MESTRE-ONLY.json');
  const g = criarGravadorJournal({ sala, caminho });
  const servidor = criarServidor({ sala, journal: g });
  assert.equal(g.gravar(), false, 'a pasta não existe: falha');
  assert.equal(g.pendente(), true);
  mkdirSync(pasta); // o disco volta
  t.mock.timers.tick(20_000); // um ciclo do ping
  assert.equal(g.pendente(), false, 'gravou no ciclo do relógio');
  assert.ok(existsSync(caminho));
  assert.equal(lerJournalDoDisco(caminho), sala.exportar());
  servidor.close();
});

test('ordem 17 B1: sem nada pendente, o relógio não exporta (não regrava a cada ping)', (t) => {
  t.mock.timers.enable({ apis: ['setInterval'] });
  const sala = criarDe(null);
  let chamadas = 0;
  const journal = { gravar() { chamadas += 1; return false; }, pendente: () => false };
  const servidor = criarServidor({ sala, journal });
  t.mock.timers.tick(60_000);
  assert.equal(chamadas, 0);
  servidor.close();
});

// ------------------------------------------------------------------ V5: «\» nos estáticos (Windows)

function pedido(servidor, url) {
  return new Promise((resolve) => {
    const res = {
      headersSent: false,
      writeHead(codigo) { this.codigo = codigo; this.headersSent = true; return this; },
      end() { resolve(this.codigo); },
    };
    servidor.emit('request', { method: 'GET', url, headers: {} }, res);
  });
}

test('ordem 17 V5 (disco): nada de dotfiles, também com «\\» no caminho (Windows)', { skip: SEM_DISCO }, async () => {
  const pasta = pastaNova();
  mkdirSync(path.join(pasta, 'sub'));
  writeFileSync(path.join(pasta, '.segredo'), 'CANARIO-DOTFILE');
  writeFileSync(path.join(pasta, 'sub', '.segredo'), 'CANARIO-DOTFILE');
  writeFileSync(path.join(pasta, 'ok.txt'), 'ok');
  const servidor = criarServidor({ sala: criarDe(null), pastaEstatica: pasta });
  assert.equal(await pedido(servidor, '/ok.txt'), 200, 'controlo');
  assert.equal(await pedido(servidor, '/.segredo'), 404, 'controlo');
  for (const url of ['/sub%5C.segredo', '/sub%5C..%5C.segredo', '/x%5C..%5C.segredo', '/sub/%5C.segredo']) {
    assert.equal(await pedido(servidor, url), 404, url);
  }
  // O nome curto 8.3 do Windows («.segredo» → «SEGRED~1», nos volumes que os geram) também não serve o dotfile.
  for (const url of ['/SEGRED~1', '/sub/SEGRED~1', '/segred~1']) assert.equal(await pedido(servidor, url), 404, url);
  servidor.close();
});

// ------------------------------------------------------------------ V6: a mesma ligação a repetir o JOIN

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

function quadroMascarado(texto) {
  const dados = Buffer.from(texto, 'utf8');
  const mascara = Buffer.from([0x11, 0x22, 0x33, 0x44]);
  const cab = dados.length < 126 ? Buffer.from([0x81, 0x80 | dados.length]) : Buffer.from([0x81, 0x80 | 126, dados.length >> 8, dados.length & 0xff]);
  const corpo = Buffer.from(dados.map((b, i) => b ^ mascara[i & 3]));
  return Buffer.concat([cab, mascara, corpo]);
}

/** As mensagens de texto que o servidor escreveu (cada write é um quadro; o primeiro é o aperto de mão). */
function mensagensDe(socket) {
  const out = [];
  for (const b of socket.saida.slice(1)) {
    if ((b[0] & 0x0f) !== 0x1) continue;
    let len = b[1] & 0x7f;
    let off = 2;
    if (len === 126) { len = b.readUInt16BE(2); off = 4; } else if (len === 127) { len = b.readUInt32BE(6); off = 10; }
    out.push(JSON.parse(b.subarray(off, off + len).toString('utf8')));
  }
  return out;
}

function ligar(servidor, ip) {
  const socket = new SocketFalso();
  const req = {
    url: '/ws',
    headers: { 'sec-websocket-key': 'dGhlIHNhbXBsZSBub25jZQ==', 'sec-websocket-version': '13', upgrade: 'websocket', host: 'local' },
    socket: { remoteAddress: ip },
  };
  servidor.emit('upgrade', req, socket, Buffer.alloc(0));
  return { socket, enviar: (obj) => socket.emit('data', quadroMascarado(JSON.stringify(obj))) };
}

test('ordem 17 V6: a mesma ligação a repetir o ROOM_JOIN não dá ao Mestre um alerta de segunda ligação', () => {
  const sala = criarDe(null);
  const servidor = criarServidor({ sala });
  const mestre = ligar(servidor, '10.0.0.1');
  mestre.enviar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'mestre', pin: PIN });
  const heroina = ligar(servidor, '10.0.0.2');
  const join = { v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina };
  heroina.enviar(join);
  heroina.enviar(join); // a mesma ligação outra vez
  const alertas = () => mensagensDe(mestre.socket).filter((x) => x.type === 'MASTER_ALERTA' && x.motivo === 'segunda_ligacao');
  assert.equal(alertas().length, 0, 'nenhum alerta falso');
  assert.equal(heroina.socket.terminado, false, 'a ligação dela continua aberta');
  assert.equal(mensagensDe(heroina.socket).filter((x) => x.type === 'ROOM_WELCOME').length, 2);

  // Controlo: uma segunda ligação de verdade continua a dar o alerta e a fechar a anterior.
  const outra = ligar(servidor, '10.0.0.3');
  outra.enviar(join);
  assert.equal(alertas().length, 1, 'a segunda ligação real dá o alerta');
  assert.equal(heroina.socket.terminado, true, 'e a anterior fecha (4002)');
  servidor.close();
});

// ------------------------------------------------------------------ V7: quadros de controlo (RFC 6455 §5.5)

function quadroCru(b0, payload) {
  const mascara = Buffer.from([1, 2, 3, 4]);
  const n = payload.length;
  const cab = n < 126 ? Buffer.from([b0, 0x80 | n]) : Buffer.from([b0, 0x80 | 126, n >> 8, n & 0xff]);
  return Buffer.concat([cab, mascara, Buffer.from(payload.map((b, i) => b ^ mascara[i & 3]))]);
}
const codigoDeFecho = (socket) => {
  const q = socket.saida.slice(1).find((b) => (b[0] & 0x0f) === 0x8);
  return q ? q.readUInt16BE(2) : null;
};

test('ordem 17 V7: ping fragmentado ou com mais de 125 bytes fecha a ligação com 1002 (RFC 6455 §5.5)', () => {
  const servidor = criarServidor({ sala: criarDe(null) });
  const a = ligar(servidor, '10.0.0.7');
  a.socket.emit('data', quadroCru(0x09, Buffer.alloc(126, 0x61))); // ping (FIN) com 126 bytes
  assert.equal(codigoDeFecho(a.socket), 1002, 'controlo grande');
  const b = ligar(servidor, '10.0.0.8');
  b.socket.emit('data', quadroCru(0x09 & 0x0f, Buffer.from('oi'))); // ping sem FIN
  assert.equal(codigoDeFecho(b.socket), 1002, 'controlo fragmentado');
  // Controlo: o ping normal recebe o pong e a ligação fica.
  const c = ligar(servidor, '10.0.0.9');
  c.socket.emit('data', quadroCru(0x89, Buffer.from('oi')));
  assert.equal(codigoDeFecho(c.socket), null);
  assert.ok(c.socket.saida.slice(1).some((q) => (q[0] & 0x0f) === 0xa), 'pong');
  servidor.close();
});

// ------------------------------------------------------------------ B2: o porquê da recusa por alcance, só ao Mestre

function mesaAlcance(casaHeroina, criaturas) {
  const m = montarMesa({ modoPadrao: 'manual', casas: { heroina: casaHeroina } });
  m.entrarTodos();
  m.iniciarCombate(criaturas);
  return m;
}
const idDaFicha = (m, fichaId) => Object.values(m.sala.depuracao.estado().figuras).find((f) => f.fichaId === fichaId).id;

function conferirSoMestre(m, rotuloDetalhe, padrao) {
  const h = m.clientes.heroina;
  const seqAntes = h.ultimoSeq;
  const r = recibo(m.intencao('heroina', { tipo: 'atacar', alvoId: idDaFicha(m, 'orc-teste'), arma: 'chicote-teste' }));
  assert.equal(r.type, 'ROOM_REJECT');
  assert.equal(r.motivo, 'acao_invalida');
  assert.equal(r.texto, TEXTOS_RECUSA.acao_invalida, 'a Party vê o texto fixo de sempre');
  assert.equal(h.ultimoSeq, seqAntes, 'nenhum evento novo na Party');
  const rec = m.clientes.mestre.eventos('recusa').at(-1);
  assert.ok(rec, 'o Mestre recebe o evento interno recusa');
  assert.match(rec.dados.soMestre.detalhe, padrao, rotuloDetalhe);
  const tudoDaParty = JSON.stringify(h.msgs);
  assert.ok(!tudoDaParty.includes('ALCANCE') && !tudoDaParty.includes('CAMINHO'), 'o detalhe nunca chega à Party');
}

test('ordem 17 B2: a chicotada para lá do alcance pelo caminho — o porquê vai só ao Mestre', () => {
  // A geometria da ordem 15: o lobo tapa a linha, o desvio dá 8 passos para um alcance de 6 casas.
  const m = mesaAlcance({ x: 2, y: 2 }, [['lobo-teste', { x: 2, y: 5 }], ['orc-teste', { x: 2, y: 8 }]]);
  conferirSoMestre(m, 'passos e alcance', /^ALVO_FORA_DO_ALCANCE: 8 passos pelo caminho das casas; a técnica chega a 6 casas$/);
});

test('ordem 17 B2: sem caminho nenhum até ao alvo — o porquê vai só ao Mestre', () => {
  const m = mesaAlcance({ x: 0, y: 0 }, [['lobo-teste', { x: 1, y: 0 }], ['lobo-teste', { x: 0, y: 1 }], ['orc-teste', { x: 2, y: 2 }]]);
  conferirSoMestre(m, 'caminho tapado', /^CAMINHO_TAPADO: /);
});

test('ordem 17 B2 (controlo): uma recusa que não é de alcance não ganha detalhe de alcance', () => {
  const m = mesaAlcance({ x: 2, y: 2 }, [['orc-teste', { x: 2, y: 6 }]]);
  const antes = m.clientes.mestre.eventos('recusa').length;
  const r = recibo(m.intencao('heroina', { tipo: 'atacar', alvoId: idDaFicha(m, 'orc-teste'), arma: 'arma-que-nao-existe' }));
  assert.equal(r.motivo, 'acao_invalida');
  assert.equal(m.clientes.mestre.eventos('recusa').length, antes, 'sem evento de recusa novo (como antes)');
});
