// Ordem 34 do CM-000009 — N26-2 (sentença da bancada, 2026-11-12), a rede de trás do servidor.
// A validação normal é no aparelho (o lobby não envia um ROOM_JOIN com um campo fora). No servidor:
//  - o ROOM_JOIN mal formado (nome fora de 1-64, senha fora de 1-128, PIN que não casa ^[0-9]{6,32}$, formas misturadas)
//    recebe ERRO formato e conta para a família de formato (5 → fecho 1008);
//  - NUNCA conta para o travão de credenciais (nem do IP, nem do lugar) e não gera alerta ao Mestre;
//  - só o ROOM_JOIN bem formado que falha a credencial gasta tentativa do travão, como antes.
// Antes desta ordem, o mal formado respondia «credenciais» e gastava tentativas: 5 bloqueavam o IP e o lugar.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { criarSala } from '../nucleo/sala.js';
import { criarServidor } from '../adaptadores/node/servidor-ws.js';
import { rngDeterministico, relogio, fichasDeTeste, INICIATIVA, PIN, SENHAS } from './ajudantes.mjs';
import { criarMotorFalso } from './motor-falso.mjs';
import { ligarWs, mensagensWs, fecho } from './ajudantes-ws.mjs';

const NOME_ACENTOS = 'ã'.repeat(64); // 64 caracteres, 128 bytes em UTF-8: vale 64
function novaSala() {
  return criarSala({
    motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(7), agora: relogio(),
    config: {
      roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'auto', depurar: true,
      lugares: [
        { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
        { papel: 'mestre', nome: 'Mestre', pin: PIN },
      ],
    },
  });
}
const J = (o) => ({ v: 2, type: 'ROOM_JOIN', ...o });
const JOIN_MESTRE = J({ papel: 'mestre', pin: PIN });
const JOIN_HEROINA = J({ papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina });

const MAL_FORMADOS = {
  'nome vazio': J({ papel: 'jogadora', nome: '', senha: 'x' }),
  'nome com 65': J({ papel: 'jogadora', nome: 'a'.repeat(65), senha: 'x' }),
  'nome com 65 acentuados': J({ papel: 'jogadora', nome: 'ã'.repeat(65), senha: 'x' }),
  'nome número': J({ papel: 'jogadora', nome: 7, senha: 'x' }),
  'nome em falta': J({ papel: 'jogadora', senha: 'x' }),
  'senha vazia': J({ papel: 'jogadora', nome: 'Heroína Teste', senha: '' }),
  'senha em falta': J({ papel: 'jogadora', nome: 'Heroína Teste' }),
  'senha com 129': J({ papel: 'jogadora', nome: 'Heroína Teste', senha: 's'.repeat(129) }),
  'senha número': J({ papel: 'jogadora', nome: 'Heroína Teste', senha: 123456 }),
  'PIN com letras': J({ papel: 'mestre', pin: 'abcdef' }),
  'PIN com 5': J({ papel: 'mestre', pin: '12345' }),
  'PIN com 33': J({ papel: 'mestre', pin: '1'.repeat(33) }),
  'PIN com espaço': J({ papel: 'mestre', pin: ' ' + PIN }),
  'PIN com mudança de linha': J({ papel: 'mestre', pin: PIN + '\n' }),
  'PIN número': J({ papel: 'mestre', pin: 90210777 }),
  'PIN em falta': J({ papel: 'mestre' }),
  'jogadora com PIN': J({ papel: 'jogadora', pin: PIN }),
  'mestre com nome e senha': J({ papel: 'mestre', nome: 'Mestre', senha: 'x' }),
  'papel desconhecido': J({ papel: 'rainha', nome: 'a', senha: 'x' }),
  'seatToken curto': J({ papel: 'jogadora', seatToken: 'abc' }),
  'seatToken com símbolos': J({ papel: 'jogadora', seatToken: '!'.repeat(40) }),
};

test('ordem 34 (N26-2, falhava antes): o ROOM_JOIN mal formado recebe ERRO formato, nunca «credenciais»', () => {
  for (const [rotulo, msg] of Object.entries(MAL_FORMADOS)) {
    const sala = novaSala();
    const r = sala.entrar(msg, { ip: '10.0.26.1' });
    assert.equal(r.ok, false, rotulo);
    assert.deepEqual(r.mensagens.map((m) => [m.type, m.codigo]), [['ERRO', 'formato']], rotulo);
    assert.deepEqual(r.saidas, [], rotulo + ': nada ao Mestre');
  }
});

test('ordem 34 (N26-2, falhava antes): mal formados sem fim não gastam o travão — nem do IP, nem do lugar, nem alertam o Mestre', () => {
  const sala = novaSala();
  const mestre = sala.entrar(JOIN_MESTRE, { ip: '10.0.26.9' });
  assert.equal(mestre.ok, true);
  sala.conexaoAberta(mestre.seatId);
  const saidas = [];
  for (let volta = 0; volta < 3; volta++) {
    for (const msg of Object.values(MAL_FORMADOS)) {
      const r = sala.entrar(msg, { ip: '10.0.26.2' });
      assert.equal(r.mensagens[0].codigo, 'formato');
      saidas.push(...r.saidas);
    }
  }
  assert.equal(saidas.filter((s) => s.msg?.type === 'MASTER_ALERTA').length, 0, 'nenhum bloqueio_join');
  // O mesmo IP e os mesmos lugares entram à primeira com a credencial certa.
  const h = sala.entrar(JOIN_HEROINA, { ip: '10.0.26.2' });
  assert.equal(h.ok, true, JSON.stringify(h.mensagens));
  const m2 = sala.entrar(JOIN_MESTRE, { ip: '10.0.26.2' });
  assert.equal(m2.ok, true, JSON.stringify(m2.mensagens));
});

test('ordem 34 (N26-2, controlo): contam-se caracteres, não bytes — 64 letras com acento é nome bem formado', () => {
  const sala = novaSala();
  const r = sala.entrar(J({ papel: 'jogadora', nome: NOME_ACENTOS, senha: 'x'.repeat(128) }), { ip: '10.0.26.3' });
  assert.equal(r.mensagens[0].codigo, 'credenciais', 'bem formado; o nome é que não existe');
  const pin32 = sala.entrar(J({ papel: 'mestre', pin: '1'.repeat(32) }), { ip: '10.0.26.4' });
  assert.equal(pin32.mensagens[0].codigo, 'credenciais');
});

test('ordem 34 (N26-2, controlo): o bem formado com a credencial errada gasta o travão, como antes (5 → bloqueado + alerta)', () => {
  const sala = novaSala();
  const mestre = sala.entrar(JOIN_MESTRE, { ip: '10.0.26.9' });
  sala.conexaoAberta(mestre.seatId);
  const alertas = [];
  for (let i = 0; i < 5; i++) {
    const r = sala.entrar(J({ papel: 'jogadora', nome: 'Heroína Teste', senha: 'errada' }), { ip: '10.0.26.5' });
    assert.equal(r.mensagens[0].codigo, 'credenciais');
    alertas.push(...r.saidas.filter((s) => s.msg?.type === 'MASTER_ALERTA'));
  }
  assert.ok(alertas.length >= 1, 'o Mestre é avisado do bloqueio');
  const depois = sala.entrar(JOIN_HEROINA, { ip: '10.0.26.5' });
  assert.equal(depois.mensagens[0].codigo, 'bloqueado');
  // O bloqueado que manda um mal formado: é formato (não é tentativa), e o bloqueio fica como estava.
  const mal = sala.entrar(MAL_FORMADOS['senha vazia'], { ip: '10.0.26.5' });
  assert.equal(mal.mensagens[0].codigo, 'formato');
  assert.equal(sala.entrar(JOIN_HEROINA, { ip: '10.0.26.5' }).mensagens[0].codigo, 'bloqueado');
});

test('ordem 34 (N26-2, falhava antes): no adaptador, 5 ROOM_JOIN mal formados fecham a ligação (1008 formato) e o travão fica intacto', () => {
  const sala = novaSala();
  const servidor = criarServidor({ sala });
  const a = ligarWs(servidor, '10.0.26.6');
  for (let i = 0; i < 4; i++) a.json(MAL_FORMADOS['PIN com letras']);
  assert.equal(fecho(a.socket), null, 'à quarta ainda está aberta');
  a.json(MAL_FORMADOS['senha vazia']);
  assert.deepEqual(fecho(a.socket), { codigo: 1008, motivo: 'formato' });
  assert.ok(mensagensWs(a.socket).every((m) => m.type === 'ERRO' && m.codigo === 'formato'));
  // Do mesmo IP, logo a seguir, com as credenciais certas: entra (nenhuma tentativa foi gasta).
  const b = ligarWs(servidor, '10.0.26.6');
  b.json(JOIN_MESTRE);
  assert.ok(mensagensWs(b.socket).some((m) => m.type === 'ROOM_WELCOME'));
  const c = ligarWs(servidor, '10.0.26.6');
  c.json(JOIN_HEROINA);
  assert.ok(mensagensWs(c.socket).some((m) => m.type === 'ROOM_WELCOME'));
  servidor.close();
});
