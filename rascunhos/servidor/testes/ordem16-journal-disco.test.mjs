// Ordem 16 do CM-000009 — o journal vai a disco (TODO JV1.x do adaptador servidor-ws.js).
// Seguindo a recomendação do estudo da ordem 14: quem lê o ficheiro abre o envelope 'registo-mestre/1'
// (confere formato e marca) e passa SÓ o 'registo' ao restaurarJournal; aceita a forma antiga (a string
// JSON é o próprio texto); qualquer outra forma falha FECHADO. A 'narracao' nunca entra no estado.
//
// Duas camadas:
//  - a abertura do ficheiro e o restauro (sem disco): correm sempre, também no passo só de leitura do CI;
//  - o disco de verdade (gravar, ler, restaurar, arrancar): numa pasta temporária nova (JOURNAL_DISCO_PASTA ou
//    a pasta temporária do sistema). Com o modelo de permissões do Node sem escrita (o passo «só leitura» do
//    job servidor), saltam; no CI correm no job protocolo, que corre todos os testes do servidor sem esse modelo.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { EventEmitter } from 'node:events';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { readFileSync, writeFileSync, existsSync, mkdtempSync, readdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { ErroJournal } from '../nucleo/journal.js';
import { criarSala } from '../nucleo/sala.js';
import {
  abrirFicheiroJournal, envelopeJournal, conferirCaminhoJournal, abrirSalaComJournal, criarGravadorJournal,
  gravarJournalEmDisco, lerJournalDoDisco, criarServidor, FORMATO_FICHEIRO_JOURNAL, MARCA_MESTRE,
} from '../adaptadores/node/servidor-ws.js';
import { montarMesa, exigirAplicada, rngDeterministico, relogio, fichasDeTeste, INICIATIVA, PIN, SENHAS } from './ajudantes.mjs';
import { criarMotorFalso } from './motor-falso.mjs';

const PASTA_DISCO = process.env.JOURNAL_DISCO_PASTA || tmpdir();
const PODE_ESCREVER = !process.permission || process.permission.has('fs.write', PASTA_DISCO);
const SEM_DISCO = PODE_ESCREVER ? false : 'sem escrita (passo só de leitura): os testes de disco correm no job protocolo do CI';
const NARRACAO_CANARIO = 'CANARIO-NARRACAO-16: Orc desferiu o machado a Heroína Teste, caída — 999 de dano';

function sessao() {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }], ['lobo-teste', { x: 12, y: 2 }]]);
  const h = m.clientes.heroina;
  exigirAplicada(m.intencao('heroina', { tipo: 'atacar', alvoId: h.idPorNome('Orc'), arma: 'chicote-teste' }));
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  return m;
}

/** A mesma config do montarMesa (os lugares têm de bater para a heroína voltar). */
function criarDe(restaurarDe) {
  const config = {
    roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'auto', depurar: true,
    lugares: [
      { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
      { papel: 'mestre', nome: 'Mestre', pin: PIN },
    ],
  };
  return criarSala({ motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(7), agora: relogio(), config, restaurarDe });
}

function igualA(sala2, sala) {
  assert.equal(sala2.depuracao.hashEstado(), sala.depuracao.hashEstado(), 'hash do estado');
  assert.equal(sala2.depuracao.journalSeq(), sala.depuracao.journalSeq(), 'journalSeq');
  assert.deepEqual(sala2.depuracao.eventos(), sala.depuracao.eventos(), 'eventos');
  assert.deepEqual(sala2.depuracao.estado(), sala.depuracao.estado(), 'estado');
  assert.equal(sala2.exportar(), sala.exportar(), 'a exportação da sala restaurada é a mesma, byte a byte');
}

/** O envelope do «Exportar registo» do ecrã do Mestre (modelo_mestre.gd conteudo_export), com a narração. */
function envelopeDoMestre(exp, narracao = [NARRACAO_CANARIO]) {
  return JSON.stringify({ formato: 'registo-mestre/1', marca: 'MESTRE-ONLY', registo: exp, narracao });
}

function formasInvalidas(exp) {
  return {
    'texto cru do journal (sem envelope nem aspas)': exp,
    'JSON inválido': '{"formato":"registo-mestre/1",',
    'objecto vazio': '{}',
    'formato de outra versão': JSON.stringify({ formato: 'registo-mestre/2', marca: 'MESTRE-ONLY', registo: exp }),
    'formato em falta': JSON.stringify({ marca: 'MESTRE-ONLY', registo: exp }),
    'marca da Party': JSON.stringify({ formato: 'registo-mestre/1', marca: 'PARTY', registo: exp }),
    'marca em falta': JSON.stringify({ formato: 'registo-mestre/1', registo: exp }),
    'registo que não é texto': JSON.stringify({ formato: 'registo-mestre/1', marca: 'MESTRE-ONLY', registo: { texto: exp } }),
    'registo em falta (só a narração)': JSON.stringify({ formato: 'registo-mestre/1', marca: 'MESTRE-ONLY', narracao: [exp] }),
    'registo vazio': JSON.stringify({ formato: 'registo-mestre/1', marca: 'MESTRE-ONLY', registo: '' }),
    'string antiga vazia': '""',
    'null': 'null',
    'número': '42',
    'lista com o texto': JSON.stringify([exp]),
    'ficheiro vazio': '',
  };
}

// ------------------------------------------------------------------ sem disco

test('ordem 16: o envelope do adaptador leva o registo intacto e abre-se para o mesmo texto', () => {
  const m = sessao();
  const exp = m.sala.exportar();
  const env = envelopeJournal(exp);
  const lido = JSON.parse(env);
  assert.equal(lido.formato, FORMATO_FICHEIRO_JOURNAL);
  assert.equal(lido.formato, 'registo-mestre/1');
  assert.equal(lido.marca, MARCA_MESTRE);
  assert.equal(lido.marca, 'MESTRE-ONLY');
  assert.equal(lido.registo, exp, 'o registo é o texto do servidor byte a byte');
  assert.deepEqual(Object.keys(lido).sort(), ['formato', 'marca', 'registo'], 'o servidor não escreve narração');
  assert.equal(abrirFicheiroJournal(env), exp);
  igualA(criarDe(abrirFicheiroJournal(env)), m.sala);
});

test('ordem 16: a forma antiga (a string JSON do texto) também se abre e restaura o mesmo estado', () => {
  const m = sessao();
  const exp = m.sala.exportar();
  const antigo = JSON.stringify(exp); // o que o ecrã do Mestre gravava antes da ordem 13
  assert.equal(abrirFicheiroJournal(antigo), exp);
  igualA(criarDe(abrirFicheiroJournal(antigo)), m.sala);
});

test('ordem 16: o envelope do ecrã do Mestre restaura pelo registo; a narração nunca entra no estado', () => {
  const m = sessao();
  const exp = m.sala.exportar();
  const sala2 = criarDe(abrirFicheiroJournal(envelopeDoMestre(exp)));
  igualA(sala2, m.sala);
  const tudo = JSON.stringify([sala2.depuracao.estado(), sala2.depuracao.eventos(), sala2.exportar()]);
  assert.ok(!tudo.includes('CANARIO-NARRACAO-16'), 'a narração não entrou no estado nem no journal');
  // Narração editada (não é assinada) ou de forma estranha não muda nada: não é lida.
  for (const narracao of [['outra coisa'], [], 'texto solto', { estado: { fase: 'fim' } }, null]) {
    const s = criarDe(abrirFicheiroJournal(envelopeDoMestre(exp, narracao)));
    assert.equal(s.depuracao.hashEstado(), m.sala.depuracao.hashEstado());
  }
});

test('ordem 16: formas desconhecidas falham FECHADO (ErroJournal, nada é restaurado)', () => {
  const exp = sessao().sala.exportar();
  for (const [rotulo, conteudo] of Object.entries(formasInvalidas(exp))) {
    assert.throws(() => abrirFicheiroJournal(conteudo), ErroJournal, rotulo);
  }
  assert.throws(() => abrirFicheiroJournal(undefined), ErroJournal);
  assert.throws(() => abrirFicheiroJournal(Buffer.from(envelopeJournal(exp))), ErroJournal, 'só texto');
});

test('ordem 16: um registo adulterado dentro do envelope certo não restaura (a assinatura do journal decide)', () => {
  const exp = sessao().sala.exportar();
  const p = exp.indexOf('"vidaActual"');
  assert.ok(p > 0);
  const adulterado = exp.slice(0, p + 14) + (exp[p + 14] === '1' ? '2' : '1') + exp.slice(p + 15);
  const texto = abrirFicheiroJournal(envelopeDoMestre(adulterado)); // o envelope abre...
  assert.throws(() => criarDe(texto), ErroJournal); // ...mas o restaurarJournal recusa
});

test('ordem 16: o ficheiro tem de dizer MESTRE-ONLY no nome e nunca fica na pasta estática', () => {
  const base = path.resolve('/srv/mesa');
  assert.equal(conferirCaminhoJournal(path.join(base, 'privado', 'registo-MESTRE-ONLY-sala.json'), path.join(base, 'cliente')),
    path.join(base, 'privado', 'registo-MESTRE-ONLY-sala.json'));
  assert.throws(() => conferirCaminhoJournal(path.join(base, 'privado', 'registo-sala.json')), ErroJournal, 'sem MESTRE-ONLY');
  assert.throws(() => conferirCaminhoJournal(path.join(base, 'MESTRE-ONLY', 'registo.json')), ErroJournal, 'só a pasta não chega');
  assert.throws(() => conferirCaminhoJournal(path.join(base, 'cliente', 'registo-MESTRE-ONLY.json'), path.join(base, 'cliente')),
    ErroJournal, 'na pasta estática (E-P13)');
  assert.throws(() => conferirCaminhoJournal(''), ErroJournal);
});

// ------------------------------------------------------------------ com disco

function pastaNova() {
  return mkdtempSync(path.join(PASTA_DISCO, 'o16-'));
}

test('ordem 16 (disco): ponta-a-ponta exportar → gravar → ler → restaurar dá o estado exportado', { skip: SEM_DISCO }, () => {
  const m = sessao();
  const pasta = pastaNova();
  const caminho = path.join(pasta, 'registo-MESTRE-ONLY-sala-teste.json');
  const g = criarGravadorJournal({ sala: m.sala, caminho });
  assert.equal(g.gravar(), true, 'grava');
  assert.equal(g.gravar(), false, 'sem commit novo não regrava');
  assert.deepEqual(readdirSync(pasta), ['registo-MESTRE-ONLY-sala-teste.json'], 'nenhum ficheiro a meio');
  const noDisco = JSON.parse(readFileSync(caminho, 'utf8'));
  assert.equal(noDisco.formato, 'registo-mestre/1');
  assert.equal(noDisco.marca, 'MESTRE-ONLY');
  assert.equal(noDisco.registo, m.sala.exportar(), 'o registo em disco é a exportação do servidor, byte a byte');
  assert.equal(lerJournalDoDisco(caminho), m.sala.exportar());

  let criadaCom;
  const r = abrirSalaComJournal({ caminho, criar: (t) => { criadaCom = t; return criarDe(t); } });
  assert.equal(r.ok, true);
  assert.equal(r.restaurada, true);
  assert.equal(criadaCom, m.sala.exportar(), 'ao restaurarJournal chega só o registo');
  igualA(r.sala, m.sala);

  // A heroína volta à sala restaurada com o seatToken que tinha.
  const h = m.clientes.heroina;
  const volta = r.sala.entrar({ v: 2, type: 'ROOM_JOIN', papel: 'jogadora', seatToken: h.token, lastSeq: h.ultimoSeq }, { ip: '10.0.0.9' });
  assert.equal(volta.ok, true);
  assert.equal(volta.seatId, h.seatId);

  // Mais um commit na sala original: o gravador regrava e o novo restauro acompanha.
  const seq = m.sala.depuracao.journalSeq();
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'terminar' }));
  assert.ok(m.sala.depuracao.journalSeq() > seq, 'houve commit');
  assert.equal(g.gravar(), true);
  const r2 = abrirSalaComJournal({ caminho, criar: criarDe });
  assert.equal(r2.ok, true);
  igualA(r2.sala, m.sala);
});

test('ordem 16 (disco): as duas formas em disco (envelope do Mestre com narração e string antiga)', { skip: SEM_DISCO }, () => {
  const m = sessao();
  const exp = m.sala.exportar();
  const pasta = pastaNova();
  const formas = { envelope: envelopeDoMestre(exp), antiga: JSON.stringify(exp) };
  for (const [rotulo, conteudo] of Object.entries(formas)) {
    const caminho = path.join(pasta, `registo-MESTRE-ONLY-${rotulo}.json`);
    writeFileSync(caminho, conteudo, 'utf8');
    const r = abrirSalaComJournal({ caminho, criar: criarDe });
    assert.equal(r.ok, true, rotulo);
    assert.equal(r.restaurada, true, rotulo);
    igualA(r.sala, m.sala);
    assert.ok(!JSON.stringify(r.sala.depuracao.estado()).includes('CANARIO-NARRACAO-16'), rotulo);
  }
});

test('ordem 16 (disco): forma inválida ou registo adulterado → a sala não abre e o ficheiro fica intacto', { skip: SEM_DISCO }, () => {
  const exp = sessao().sala.exportar();
  const pasta = pastaNova();
  const casos = { ...formasInvalidas(exp) };
  const p = exp.indexOf('"journalSeq"');
  casos['registo adulterado no envelope'] = envelopeJournal(exp.slice(0, p) + '"journalSeq" ' + exp.slice(p + 12));
  let i = 0;
  for (const [rotulo, conteudo] of Object.entries(casos)) {
    const caminho = path.join(pasta, `registo-MESTRE-ONLY-${++i}.json`);
    writeFileSync(caminho, conteudo, 'utf8');
    const antes = createHash('sha256').update(readFileSync(caminho)).digest('hex');
    let salaCriada = false;
    const r = abrirSalaComJournal({ caminho, criar: (t) => { const s = criarDe(t); salaCriada = true; return s; } });
    assert.equal(r.ok, false, rotulo);
    assert.ok(r.erro instanceof ErroJournal, rotulo);
    assert.equal(r.sala, undefined, rotulo);
    assert.equal(salaCriada, false, rotulo + ': nenhuma sala, nem nova');
    assert.equal(createHash('sha256').update(readFileSync(caminho)).digest('hex'), antes, rotulo + ': ficheiro intacto');
  }
});

test('ordem 16 (disco): sem ficheiro, sala nova; o primeiro gravar cria-o', { skip: SEM_DISCO }, () => {
  const caminho = path.join(pastaNova(), 'registo-MESTRE-ONLY-nova.json');
  let criadaCom = 'nada';
  const r = abrirSalaComJournal({ caminho, criar: (t) => { criadaCom = t; return criarDe(t); } });
  assert.equal(r.ok, true);
  assert.equal(r.restaurada, false);
  assert.equal(criadaCom, null);
  assert.equal(existsSync(caminho), false, 'abrir não escreve');
  assert.equal(criarGravadorJournal({ sala: r.sala, caminho }).gravar(), true);
  igualA(abrirSalaComJournal({ caminho, criar: criarDe }).sala, r.sala);
  // gravarJournalEmDisco/lerJournalDoDisco directos
  gravarJournalEmDisco(caminho, r.sala.exportar());
  assert.equal(lerJournalDoDisco(caminho), r.sala.exportar());
});

// O adaptador de verdade: uma ligação WebSocket simulada (sem rede) entra como Mestre; o commit do JOIN
// tem de estar no disco antes de a resposta sair.
class SocketFalso extends EventEmitter {
  constructor() {
    super();
    this.saida = [];
  }
  setNoDelay() {}
  write(b) {
    this.saida.push(Buffer.from(b));
    return true;
  }
  end() {}
  destroy() {}
}

function quadroMascarado(texto) {
  const dados = Buffer.from(texto, 'utf8');
  const mascara = Buffer.from([0x11, 0x22, 0x33, 0x44]);
  const cab = dados.length < 126 ? Buffer.from([0x81, 0x80 | dados.length]) : Buffer.from([0x81, 0x80 | 126, dados.length >> 8, dados.length & 0xff]);
  const corpo = Buffer.from(dados.map((b, i) => b ^ mascara[i & 3]));
  return Buffer.concat([cab, mascara, corpo]);
}

test('ordem 16 (disco): o criarServidor grava o journal a cada commit, antes de entregar', { skip: SEM_DISCO }, () => {
  const sala = criarDe(null);
  const caminho = path.join(pastaNova(), 'registo-MESTRE-ONLY-adaptador.json');
  const g = criarGravadorJournal({ sala, caminho });
  const socket = new SocketFalso();
  let escritasAntesDoDisco = null; // quantas escritas no socket havia quando o journal foi a disco
  const journal = {
    gravar() {
      const r = g.gravar();
      if (r && escritasAntesDoDisco === null) escritasAntesDoDisco = socket.saida.length;
      return r;
    },
  };
  const servidor = criarServidor({ sala, journal });
  const req = {
    url: '/ws',
    method: 'GET', httpVersionMajor: 1, httpVersionMinor: 1, // ordem 25 (V20): o que um pedido real traz
    headers: { 'sec-websocket-key': 'dGhlIHNhbXBsZSBub25jZQ==', 'sec-websocket-version': '13', upgrade: 'websocket', host: 'local' },
    socket: { remoteAddress: '10.0.0.1' },
  };
  servidor.emit('upgrade', req, socket, Buffer.alloc(0));
  socket.emit('data', quadroMascarado(JSON.stringify({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'mestre', pin: PIN })));
  assert.ok(socket.saida.length >= 2, 'houve resposta ao JOIN');
  assert.ok(existsSync(caminho), 'o journal foi a disco');
  assert.equal(lerJournalDoDisco(caminho), sala.exportar(), 'o disco tem o estado de agora');
  assert.equal(escritasAntesDoDisco, 1, 'só o aperto de mão tinha saído quando o journal foi a disco');
  const r = abrirSalaComJournal({ caminho, criar: criarDe });
  assert.equal(r.ok, true);
  igualA(r.sala, sala);
  servidor.close();
});
