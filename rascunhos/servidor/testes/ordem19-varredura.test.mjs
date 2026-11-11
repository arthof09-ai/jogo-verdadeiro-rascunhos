// Ordem 19 do CM-000009 — varredura crítica alargada (servidor, cliente e protocolo).
// Cada teste de correcção falhava com o código de 258171d e passa depois; os de controlo passam nos dois.
// O contrato fica igual: nenhum tipo de mensagem, campo, schema ou código novo.
//
//  V11  a resposta à RECEIPT_QUERY devolvia tal e qual um id que não é id (ex.: 65 caracteres ou mais): o ROOM_RECEIPT
//       DESCONHECIDA que saía violava o próprio schema (intentId com maxLength 64). Agora um id inválido volta como
//       `intentId: null` (a forma que o schema já tinha para o id que não é texto).
//  (V12 é do cliente: rascunhos/cliente/testes/rodar_testes.gd, «Reentrada num servidor restaurado».)
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { montarMesa, exigirAplicada } from './ajudantes.mjs';

function sessao() {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }]]);
  return m;
}

const recibos = (msgs) => msgs.filter((x) => x.type === 'ROOM_RECEIPT');

test('ordem 19 (V11): RECEIPT_QUERY com um id que não é id devolve intentId null, nunca o texto recebido', () => {
  const m = sessao();
  const longo = 'a'.repeat(65); // passa do maxLength 64 do schema ROOM_RECEIPT
  const estranho = 'não é id!'; // caracteres fora do RE_ID
  const resp = recibos(m.enviar('heroina', { type: 'RECEIPT_QUERY', intentIds: [longo, estranho, 42] }));
  assert.equal(resp.length, 3, 'uma resposta por id pedido');
  for (const r of resp) {
    assert.equal(r.estado, 'DESCONHECIDA');
    assert.equal(r.intentId, null, 'o id inválido não volta: ' + JSON.stringify(r.intentId));
    assert.deepEqual(Object.keys(r).sort(), ['estado', 'intentId', 'roomId', 'type', 'v']);
  }
});

test('ordem 19 (V11, controlo): um id válido continua a voltar como foi pedido (próprio, alheio ou desconhecido)', () => {
  const m = sessao();
  const h = m.clientes.heroina;
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }, { intentId: 'it-proprio' }));
  const resp = recibos(m.enviar('heroina', { type: 'RECEIPT_QUERY', intentIds: ['it-proprio', 'it-nunca-visto'] }));
  assert.equal(resp[0].intentId, 'it-proprio');
  assert.equal(resp[0].estado, 'APLICADA');
  assert.equal(resp[1].intentId, 'it-nunca-visto');
  assert.equal(resp[1].estado, 'DESCONHECIDA');
  assert.ok(h.seatId);
});
