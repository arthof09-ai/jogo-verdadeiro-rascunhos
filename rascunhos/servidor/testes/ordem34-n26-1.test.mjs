// Ordem 34 do CM-000009 — N26-1 (sentença da bancada, 2026-11-12): o MASTER_SEARCH com schema estrito.
//  - additionalProperties: false; `texto` obrigatório, string, 1 a 64 caracteres depois de aparado (caracteres, não
//    bytes). Texto ausente, vazio, não-string, > 64 ou campo a mais = recusa — nunca pesquisar '' por omissão nem
//    cortar em silêncio;
//  - forma única da recusa: ERRO com código `formato` (não ROOM_REJECT: a pesquisa não é comando de sala), com o cmdId
//    recebido se for string válida, senão null; a isenção de recibo mantém-se (nenhum ROOM_RECEIPT);
//  - o erro de formato só da pesquisa NÃO conta para MAX_REJEICOES_FORMATO = 5: a ligação do Mestre nunca fecha 1008
//    por pesquisas mal formadas (e a pesquisa recusada também não desfaz a contagem dos outros erros de formato);
//  - o ritmo de 10 mensagens/s aplica-se também à pesquisa, como às restantes (controlo: já era assim).
// Os testes de correcção falhavam antes (o servidor pesquisava '' e cortava aos 64); os de controlo passavam.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { criarSala } from '../nucleo/sala.js';
import { criarServidor } from '../adaptadores/node/servidor-ws.js';
import { montarMesa, rngDeterministico, relogio, fichasDeTeste, INICIATIVA, PIN, SENHAS } from './ajudantes.mjs';
import { criarMotorFalso } from './motor-falso.mjs';
import { ligarWs, mensagensWs, fecho } from './ajudantes-ws.mjs';

const S = (o) => ({ type: 'MASTER_SEARCH', ...o });
const MAL_FORMADAS = {
  'sem texto': [S({ cmdId: 'p-1' }), 'p-1'],
  'texto vazio': [S({ cmdId: 'p-2', texto: '' }), 'p-2'],
  'texto só com espaços': [S({ cmdId: 'p-3', texto: '   \t ' }), 'p-3'],
  'texto número': [S({ cmdId: 'p-4', texto: 42 }), 'p-4'],
  'texto null': [S({ cmdId: 'p-5', texto: null }), 'p-5'],
  'texto com 65': [S({ cmdId: 'p-6', texto: 'a'.repeat(65) }), 'p-6'],
  'texto com 65 acentuados': [S({ cmdId: 'p-7', texto: 'ç'.repeat(65) }), 'p-7'],
  'campo a mais': [S({ cmdId: 'p-8', texto: 'orc', limite: 3 }), 'p-8'],
  'sem cmdId e sem texto': [S({}), null],
  'cmdId inválido': [S({ cmdId: 'não é id!', texto: '' }), null],
  'cmdId número': [S({ cmdId: 7, texto: 'orc' }), null],
  'revision negativa': [S({ cmdId: 'p-9', texto: 'orc', revision: -1 }), 'p-9'],
};

function mesa() {
  const m = montarMesa({ comEspectador: true });
  m.entrarTodos();
  return m;
}

test('ordem 34 (N26-1, falhava antes): o MASTER_SEARCH fora do schema recebe ERRO formato com o cmdId, sem pesquisa nem recibo', () => {
  for (const [rotulo, [msg, cmdId]] of Object.entries(MAL_FORMADAS)) {
    const m = mesa();
    const nParty = { heroina: m.clientes.heroina.msgs.length, espectador: m.clientes.espectador.msgs.length };
    const r = m.enviar('mestre', msg);
    assert.equal(r.length, 1, `${rotulo}: uma resposta só (veio ${JSON.stringify(r)})`);
    assert.equal(r[0].type, 'ERRO', `${rotulo}: ERRO, não ROOM_REJECT nem MASTER_RESULTS (veio ${JSON.stringify(r[0])})`);
    assert.equal(r[0].codigo, 'formato', rotulo);
    assert.ok('cmdId' in r[0], `${rotulo}: a recusa leva o cmdId`);
    assert.equal(r[0].cmdId, cmdId, `${rotulo}: o cmdId recebido se for válido, senão null`);
    assert.ok(!/\d/.test(r[0].texto), `${rotulo}: o texto sem números`);
    assert.equal(m.clientes.heroina.msgs.length, nParty.heroina, `${rotulo}: a Party não recebe nada`);
    assert.equal(m.clientes.espectador.msgs.length, nParty.espectador, `${rotulo}: o espectador não recebe nada`);
  }
});

test('ordem 34 (N26-1, controlo): a pesquisa bem formada — apara, conta caracteres (não bytes) e não corta', () => {
  const m = mesa();
  const pesquisa = (texto) => m.enviar('mestre', S({ texto }));
  const r1 = pesquisa('  orc ');
  assert.equal(r1[0].type, 'MASTER_RESULTS');
  assert.deepEqual(r1[0].resultados.map((x) => x.fichaId), ['orc-teste']);
  // 64 caracteres acentuados (128 bytes): vale.
  const r2 = pesquisa('ç'.repeat(64));
  assert.equal(r2[0].type, 'MASTER_RESULTS', '64 acentuados é pesquisa');
  assert.deepEqual(r2[0].resultados, []);
  // 64 depois de aparado, com espaços à volta: vale (a conta é depois de aparar).
  const r3 = pesquisa('  ' + 'a'.repeat(64) + '  ');
  assert.equal(r3[0].type, 'MASTER_RESULTS');
  // Com cmdId e revision (o schema aceita-os): pesquisa, sem recibo.
  const r4 = m.mestre('MASTER_SEARCH', { texto: 'lobo' });
  assert.equal(r4.length, 1);
  assert.equal(r4[0].type, 'MASTER_RESULTS');
  assert.deepEqual(r4[0].resultados.map((x) => x.fichaId), ['lobo-teste']);
  // 65 com um espaço no fim já não corta em silêncio: aparado dá 64 → vale; 65 letras → recusa (acima).
  assert.equal(pesquisa('a'.repeat(64) + ' ')[0].type, 'MASTER_RESULTS');
});

function novaSala(agora = relogio()) {
  return criarSala({
    motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(7), agora,
    config: {
      roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'auto', depurar: true,
      lugares: [
        { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
        { papel: 'mestre', nome: 'Mestre', pin: PIN },
      ],
    },
  });
}
const JOIN_MESTRE = { v: 2, type: 'ROOM_JOIN', papel: 'mestre', pin: PIN };
const V = (o) => ({ v: 2, roomId: 'sala-teste', ...o });

test('ordem 34 (N26-1, falhava antes): no adaptador, pesquisas mal formadas nunca fecham a ligação do Mestre (1008)', () => {
  const sala = novaSala();
  const servidor = criarServidor({ sala });
  const a = ligarWs(servidor, '10.0.26.10');
  a.json(JOIN_MESTRE);
  assert.ok(mensagensWs(a.socket).some((m) => m.type === 'ROOM_WELCOME'));
  for (let i = 0; i < 8; i++) a.json(V(S({ cmdId: 'q-' + i, texto: i % 2 ? '' : 'x'.repeat(65) })));
  assert.equal(fecho(a.socket), null, 'oito pesquisas mal formadas: a ligação continua aberta');
  const erros = mensagensWs(a.socket).filter((m) => m.type === 'ERRO');
  assert.equal(erros.length, 8);
  assert.ok(erros.every((m) => m.codigo === 'formato'));
  a.json(V(S({ texto: 'orc' })));
  assert.ok(mensagensWs(a.socket).some((m) => m.type === 'MASTER_RESULTS'), 'e a pesquisa certa a seguir responde');
  servidor.close();
});

test('ordem 34 (N26-1): a pesquisa recusada não conta nem desfaz a família de formato dos outros erros', () => {
  const sala = novaSala();
  const servidor = criarServidor({ sala });
  const a = ligarWs(servidor, '10.0.26.11');
  a.json(JOIN_MESTRE);
  for (let i = 0; i < 4; i++) a.texto('{isto não é JSON');
  assert.equal(fecho(a.socket), null, 'quatro JSON inválidos: ainda aberta');
  a.json(V(S({ cmdId: 'q-a', texto: '' })));
  a.json(V(S({ cmdId: 'q-b', texto: 7 })));
  assert.equal(fecho(a.socket), null, 'as pesquisas recusadas não somam');
  a.texto('{outra vez não');
  assert.deepEqual(fecho(a.socket), { codigo: 1008, motivo: 'formato' }, 'a quinta dos outros fecha: a pesquisa não a desfez');
  servidor.close();
});

test('ordem 34 (N26-1, controlo): o ritmo de 10 mensagens/s aplica-se também à pesquisa', () => {
  const parado = () => Date.UTC(2026, 10, 12, 21, 0, 0); // o relógio da sala parado: tudo no mesmo segundo
  const sala = novaSala(parado);
  const servidor = criarServidor({ sala });
  const a = ligarWs(servidor, '10.0.26.12');
  a.json(JOIN_MESTRE);
  for (let i = 0; i < 11; i++) a.json(V(S({ cmdId: 'r-' + i, texto: 'orc' })));
  const resp = mensagensWs(a.socket).filter((m) => m.type === 'MASTER_RESULTS' || m.type === 'ROOM_REJECT' || m.type === 'ERRO');
  assert.equal(resp.filter((m) => m.type === 'MASTER_RESULTS').length, 10, 'dez pesquisas respondidas');
  const fora = resp.at(-1);
  assert.equal(fora.type, 'ROOM_REJECT', 'a décima primeira fica fora do ritmo, como as restantes mensagens');
  assert.equal(fora.motivo, 'formato');
  servidor.close();
});
