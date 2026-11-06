// Journal: eventos, estado e recibos juntos; exportação com hash; restauração que
// recusa 1 byte adulterado.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { restaurarJournal, ErroJournal } from '../nucleo/journal.js';
import { criarSala } from '../nucleo/sala.js';
import { montarMesa, exigirAplicada, rngDeterministico, relogio, fichasDeTeste, INICIATIVA, PIN, SENHAS } from './ajudantes.mjs';
import { criarMotorFalso } from './motor-falso.mjs';

function sessao() {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }], ['lobo-teste', { x: 12, y: 2 }]]);
  const h = m.clientes.heroina;
  exigirAplicada(m.intencao('heroina', { tipo: 'atacar', alvoId: h.idPorNome('Orc'), arma: 'chicote-teste' }));
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  return m;
}

test('exportação: corpo canónico + assinatura; restaurar dá o mesmo estado e a mesma cadeia', () => {
  const m = sessao();
  const exp = m.sala.exportar();
  assert.match(exp, /\nsha256:[0-9a-f]{64}\n$/);
  const j = restaurarJournal(exp);
  assert.equal(j.hashEstado(), m.sala.depuracao.hashEstado());
  assert.equal(j.journalSeq, m.sala.depuracao.journalSeq());
  assert.deepEqual(j.eventos(), m.sala.depuracao.eventos());
});

test('restauração recusa 1 byte adulterado (amostra de posições, inserção e remoção)', () => {
  const exp = sessao().sala.exportar();
  const n = exp.length;
  const posicoes = new Set([0, 1, 2, n - 1, n - 2, n - 10, n - 70, n - 71, n - 72]);
  for (let i = 0; i < 64; i++) posicoes.add(i);
  for (let i = n - 80; i < n; i++) posicoes.add(i);
  const r = rngDeterministico(42);
  for (let i = 0; i < 200; i++) posicoes.add(r() % n);
  for (const p of posicoes) {
    const c = exp[p];
    const troca = c === 'a' ? 'b' : 'a';
    const adulterado = exp.slice(0, p) + troca + exp.slice(p + 1);
    assert.throws(() => restaurarJournal(adulterado), ErroJournal, `posição ${p} passou`);
  }
  assert.throws(() => restaurarJournal(exp.slice(0, 100) + exp.slice(101)), ErroJournal, 'remoção');
  assert.throws(() => restaurarJournal(exp.slice(0, 100) + ' ' + exp.slice(100)), ErroJournal, 'inserção');
  assert.throws(() => restaurarJournal(exp + '\n'), ErroJournal, 'moldura');
});

test('com chave (HMAC), só quem tem a chave restaura', () => {
  const m = montarMesa();
  m.entrarTodos();
  const motor = criarMotorFalso();
  const fichas = fichasDeTeste();
  const config = {
    roomId: 'sala-hmac', iniciativa: INICIATIVA,
    lugares: [
      { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste' },
      { papel: 'mestre', pin: PIN },
    ],
  };
  const sala = criarSala({ motores: motor, fichas, rng: rngDeterministico(), agora: relogio(), config, chaveJournal: 'chave-de-teste' });
  const exp = sala.exportar();
  assert.match(exp, /\nhmac-sha256:[0-9a-f]{64}\n$/);
  assert.ok(restaurarJournal(exp, { chave: 'chave-de-teste' }));
  assert.throws(() => restaurarJournal(exp, { chave: 'outra' }), ErroJournal);
  assert.throws(() => restaurarJournal(exp), ErroJournal);
});

test('a sala restaurada continua: a heroína volta com o seatToken e vê o mesmo tabuleiro', () => {
  const m = sessao();
  const h = m.clientes.heroina;
  const exp = m.sala.exportar();
  const config = {
    roomId: 'sala-teste', iniciativa: INICIATIVA, depurar: true,
    lugares: [
      { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
      { papel: 'mestre', nome: 'Mestre', pin: PIN },
    ],
  };
  const sala2 = criarSala({
    motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(7), agora: relogio(), config, restaurarDe: exp,
  });
  assert.equal(sala2.depuracao.hashEstado(), m.sala.depuracao.hashEstado());
  const r = sala2.entrar({ v: 2, type: 'ROOM_JOIN', papel: 'jogadora', seatToken: h.token, lastSeq: h.ultimoSeq }, { ip: '10.0.0.9' });
  assert.equal(r.ok, true);
  assert.equal(r.seatId, h.seatId);
  // lastSeq igual ao último que ela viu: nada em falta; e o token rodou.
  assert.notEqual(r.mensagens[0].seatToken, h.token);
  assert.ok(!r.mensagens.some((x) => x.type === 'ROOM_EVENT' && x.seq <= h.ultimoSeq));
  // O token antigo deixa de servir.
  const velho = sala2.entrar({ v: 2, type: 'ROOM_JOIN', papel: 'jogadora', seatToken: h.token }, { ip: '10.0.0.9' });
  assert.equal(velho.ok, false);
});

test('motor de outra versão ao restaurar → ROOM_PAUSED {manutencao}', () => {
  const m = sessao();
  const exp = m.sala.exportar();
  const motor = criarMotorFalso();
  motor.MOTOR_SHA256 = 'f'.repeat(64);
  const config = {
    roomId: 'sala-teste', iniciativa: INICIATIVA,
    lugares: [
      { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste' },
      { papel: 'mestre', nome: 'Mestre', pin: PIN },
    ],
  };
  const sala2 = criarSala({ motores: motor, fichas: fichasDeTeste(), rng: rngDeterministico(), agora: relogio(), config, restaurarDe: exp });
  const est = sala2.depuracao.estado();
  assert.equal(est.fase, 'pausa');
  assert.equal(est.pausa.motivo, 'manutencao');
});

test('o journal nunca apaga história: "voltar" cria um evento revertido e marca os recibos posteriores', () => {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }]]);
  const h = m.clientes.heroina;
  const ponto = m.sala.depuracao.journalSeq();
  exigirAplicada(m.intencao('heroina', { tipo: 'atacar', alvoId: h.idPorNome('Orc'), arma: 'chicote-teste' }, { intentId: 'golpe-1' }));
  const antes = m.sala.depuracao.eventos().length;
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'voltar', ateSeq: ponto }));
  const evs = m.sala.depuracao.eventos();
  assert.ok(evs.length > antes, 'nada foi apagado');
  assert.equal(evs[evs.length - 1].tipo, 'revertido');
  const rec = m.sala.depuracao.recibo(h.seatId, 'golpe-1');
  assert.ok(rec.revertidaEm, 'o recibo ganhou revertidaEm');
  const recMsg = h.msgs.filter((x) => x.type === 'ROOM_RECEIPT' && x.intentId === 'golpe-1').pop();
  assert.ok(recMsg.revertidaEm && !/^\d+$/.test(String(recMsg.revertidaEm)), 'carimbo de hora, nunca o journalSeq');
  // A vida do orc voltou e a heroína recebeu um snapshot novo.
  assert.ok(h.ultimo('ROOM_SNAPSHOT'));
  const orc = Object.values(m.sala.depuracao.estado().figuras).find((f) => f.fichaId === 'orc-teste');
  assert.equal(orc.vidaActual, 7777);
  // Um id revertido nunca volta a ser aplicado.
  const de = m.intencao('heroina', { tipo: 'atacar', alvoId: h.idPorNome('Orc'), arma: 'chicote-teste' }, { intentId: 'golpe-1' });
  assert.ok(de.every((x) => x.type !== 'ROOM_EVENT'));
});
