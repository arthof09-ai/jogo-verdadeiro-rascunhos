// Ordem 34 do CM-000009 — N30-1 (sentença da bancada, 2026-11-12): um conjunto de valores, sem alternativas.
//  - Prazo de entrada: 300 s absolutos, da abertura da ligação até a um ROOM_JOIN aceite com lugar; ping/pong NÃO
//    prolonga; aos 300 s sem entrada: fecho 1008. Quem foi fechado liga outra vez na hora, sem castigo. Depois do
//    ROOM_JOIN aceite, a regra nunca mais se aplica àquela ligação.
//  - Tectos de ligações simultâneas: 12 por IP; 32 sem lugar; 64 no total. Ao bater um tecto recusa-se só a ligação
//    nova, com fecho 1013; ninguém é despejado; sem fila — a nova tenta outra vez quando houver vaga.
//  - Antes da entrada, qualquer mensagem que não seja ROOM_JOIN conta para a família de formato (5 → fecho 1008), e o
//    ritmo de 10 mensagens/s aplica-se também às ligações sem lugar.
// Antes desta ordem: a ligação que nunca entrava ficava aberta sem fim e não havia tecto nenhum (N30-1, ordem 30).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { criarSala } from '../nucleo/sala.js';
import * as Adaptador from '../adaptadores/node/servidor-ws.js';
import { rngDeterministico, relogio, fichasDeTeste, INICIATIVA, PIN, SENHAS } from './ajudantes.mjs';
import { criarMotorFalso } from './motor-falso.mjs';
import { ligarWs, mensagensWs, fecho, aceite } from './ajudantes-ws.mjs';

const { criarServidor } = Adaptador;

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
const JOIN_MESTRE = { v: 2, type: 'ROOM_JOIN', papel: 'mestre', pin: PIN };
const JOIN_HEROINA = { v: 2, type: 'ROOM_JOIN', papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina };
const RESYNC = { v: 2, type: 'ROOM_RESYNC', lastSeq: 0 };
const entrou = (socket) => mensagensWs(socket).some((m) => m.type === 'ROOM_WELCOME');
const ip = (n) => `10.30.${Math.floor(n / 10)}.${n % 10}`; // 10 ligações por IP (abaixo do tecto de 12)

test('ordem 34 (N30-1): os valores fechados pela bancada', () => {
  assert.equal(Adaptador.PRAZO_ENTRADA_MS, 300_000);
  assert.equal(Adaptador.MAX_LIGACOES_POR_IP, 12);
  assert.equal(Adaptador.MAX_LIGACOES_SEM_LUGAR, 32);
  assert.equal(Adaptador.MAX_LIGACOES, 64);
});

test('ordem 34 (N30-1, falhava antes): 300 s sem ROOM_JOIN aceite → fecho 1008; o pong não prolonga; volta a ligar na hora', (t) => {
  t.mock.timers.enable({ apis: ['setTimeout', 'setInterval'] });
  const servidor = criarServidor({ sala: novaSala() });
  const a = ligarWs(servidor, '10.30.0.1');
  for (let s = 20; s < 300; s += 20) {
    t.mock.timers.tick(20_000);
    a.pong(); // responde a todos os pings, como um navegador
  }
  t.mock.timers.tick(19_999);
  assert.equal(fecho(a.socket), null, 'aos 299,999 s ainda está aberta');
  t.mock.timers.tick(1);
  assert.deepEqual(fecho(a.socket), { codigo: 1008, motivo: 'prazo de entrada' });
  // Sem castigo nem espera: a mesma máquina liga outra vez na hora e entra.
  const b = ligarWs(servidor, '10.30.0.1');
  assert.ok(aceite(b.socket));
  b.json(JOIN_HEROINA);
  assert.ok(entrou(b.socket));
  assert.equal(fecho(b.socket), null);
  servidor.close();
});

test('ordem 34 (N30-1, falhava antes): tentativas de entrada falhadas e mensagens soltas não prolongam o prazo', (t) => {
  t.mock.timers.enable({ apis: ['setTimeout', 'setInterval'] });
  const servidor = criarServidor({ sala: novaSala() });
  const a = ligarWs(servidor, '10.30.0.2');
  t.mock.timers.tick(150_000);
  a.json({ ...JOIN_HEROINA, senha: 'errada' }); // bem formado, credencial errada: não é entrada
  t.mock.timers.tick(100_000);
  a.json(RESYNC);
  t.mock.timers.tick(49_999);
  assert.equal(fecho(a.socket), null);
  t.mock.timers.tick(1);
  assert.equal(fecho(a.socket)?.codigo, 1008);
  servidor.close();
});

test('ordem 34 (N30-1, controlo): depois do ROOM_JOIN aceite o prazo nunca mais se aplica àquela ligação', (t) => {
  t.mock.timers.enable({ apis: ['setTimeout', 'setInterval'] });
  const servidor = criarServidor({ sala: novaSala() });
  const a = ligarWs(servidor, '10.30.0.3');
  t.mock.timers.tick(299_000);
  a.json(JOIN_HEROINA); // entra a 1 s do fim
  assert.ok(entrou(a.socket));
  for (let s = 0; s < 1200; s += 20) {
    t.mock.timers.tick(20_000);
    a.pong();
  }
  assert.equal(fecho(a.socket), null, '20 minutos depois continua na mesa');
  servidor.close();
});

test('ordem 34 (N30-1, falhava antes): tecto por IP — a 13.ª ligação do mesmo IP é recusada com 1013; as 12 ficam; outro IP entra', () => {
  const servidor = criarServidor({ sala: novaSala() });
  const doIp = [];
  for (let i = 0; i < 12; i++) doIp.push(ligarWs(servidor, '10.30.1.1'));
  assert.ok(doIp.every((l) => aceite(l.socket) && fecho(l.socket) === null), 'as 12 primeiras ficam');
  const a13 = ligarWs(servidor, '10.30.1.1');
  assert.equal(fecho(a13.socket)?.codigo, 1013, 'a chegada é recusada com 1013');
  assert.equal(a13.socket.terminado, true);
  assert.ok(doIp.every((l) => fecho(l.socket) === null), 'ninguém é despejado');
  const outro = ligarWs(servidor, '10.30.1.2');
  assert.equal(fecho(outro.socket), null, 'outro IP não é afectado');
  // A recusada não ficou a contar nem em fila: sai uma, a nova tentativa entra.
  doIp[0].cair();
  const denovo = ligarWs(servidor, '10.30.1.1');
  assert.equal(fecho(denovo.socket), null, 'com vaga, a nova tentativa fica');
  assert.equal(fecho(ligarWs(servidor, '10.30.1.1').socket)?.codigo, 1013, 'e o tecto continua nos 12');
  servidor.close();
});

test('ordem 34 (N30-1, falhava antes): tecto pré-entrada — a 33.ª ligação sem lugar é recusada com 1013; entrar liberta vaga', () => {
  const servidor = criarServidor({ sala: novaSala() });
  const espera = [];
  for (let i = 0; i < 32; i++) espera.push(ligarWs(servidor, ip(i)));
  assert.ok(espera.every((l) => fecho(l.socket) === null));
  const a33 = ligarWs(servidor, '10.30.9.1');
  assert.equal(fecho(a33.socket)?.codigo, 1013);
  assert.ok(espera.every((l) => fecho(l.socket) === null), 'quem já estava à espera não é despejado');
  // Uma das que esperavam entra (ganha lugar): deixa de contar como pré-entrada, e a chegada seguinte fica.
  espera[0].json(JOIN_MESTRE);
  assert.ok(entrou(espera[0].socket));
  const nova = ligarWs(servidor, '10.30.9.1');
  assert.equal(fecho(nova.socket), null);
  assert.equal(fecho(ligarWs(servidor, '10.30.9.2').socket)?.codigo, 1013, 'e volta a estar cheio nas 32');
  servidor.close();
});

test('ordem 34 (N30-1, falhava antes): tecto geral — a 65.ª ligação (com e sem lugar) é recusada com 1013; ninguém sai', () => {
  const servidor = criarServidor({ sala: novaSala() });
  const todas = [];
  // 40 com lugar (o lugar do Mestre aceita várias ligações) + 24 sem lugar = 64.
  for (let i = 0; i < 40; i++) {
    const l = ligarWs(servidor, ip(i));
    l.json(JOIN_MESTRE);
    assert.ok(entrou(l.socket), 'ligação ' + i);
    todas.push(l);
  }
  for (let i = 40; i < 64; i++) todas.push(ligarWs(servidor, ip(i)));
  assert.ok(todas.every((l) => fecho(l.socket) === null), 'as 64 ficam');
  const a65 = ligarWs(servidor, '10.30.9.9');
  assert.equal(fecho(a65.socket)?.codigo, 1013);
  assert.ok(todas.every((l) => fecho(l.socket) === null), 'nem quem entrou nem quem espera é despejado');
  todas[63].cair();
  assert.equal(fecho(ligarWs(servidor, '10.30.9.9').socket), null, 'com vaga, a nova fica');
  servidor.close();
});

test('ordem 34 (N30-1, falhava antes): antes da entrada, a mensagem que não é ROOM_JOIN conta para a família de formato (5 → 1008)', () => {
  const servidor = criarServidor({ sala: novaSala() });
  // 3 mensagens soltas + 2 JSON inválidos = 5 da família: fecha (antes, as duas contagens não se somavam).
  const a = ligarWs(servidor, '10.30.2.1');
  for (let i = 0; i < 3; i++) a.json(RESYNC);
  a.texto('{não é json');
  assert.equal(fecho(a.socket), null, 'à quarta ainda está aberta');
  a.texto('{não é json');
  assert.deepEqual(fecho(a.socket), { codigo: 1008, motivo: 'formato' });
  // 2 ROOM_JOIN mal formados + 3 mensagens soltas: também.
  const b = ligarWs(servidor, '10.30.2.2');
  for (let i = 0; i < 2; i++) b.json({ v: 2, type: 'ROOM_JOIN', papel: 'mestre', pin: 'abc' });
  for (let i = 0; i < 2; i++) b.json(RESYNC);
  assert.equal(fecho(b.socket), null);
  b.json({ v: 2, type: 'MASTER_VIEW' });
  assert.equal(fecho(b.socket)?.codigo, 1008);
  servidor.close();
});

test('ordem 34 (N30-1, falhava antes): o ritmo de 10 mensagens/s aplica-se à ligação sem lugar — a 11.ª no mesmo segundo nem chega à sala', () => {
  const verdadeira = novaSala();
  let entradas = 0;
  const sala = { ...verdadeira, roomId: verdadeira.roomId, entrar: (msg, ctx) => { entradas += 1; return verdadeira.entrar(msg, ctx); } };
  const servidor = criarServidor({ sala });
  const a = ligarWs(servidor, '10.30.3.1');
  // 10 ROOM_JOIN bem formados com a credencial errada (4 de nome que não existe: só o travão do IP conta até 4).
  const errado = (i) => ({ v: 2, type: 'ROOM_JOIN', papel: 'jogadora', nome: 'Ninguém ' + i, senha: 'x' });
  for (let i = 0; i < 10; i++) a.json(errado(i));
  assert.equal(entradas, 10);
  assert.equal(fecho(a.socket), null);
  a.json(JOIN_HEROINA); // a 11.ª no mesmo segundo: fora do ritmo
  assert.equal(entradas, 10, 'a 11.ª não chega à sala (não é tentativa de entrada)');
  const ultima = mensagensWs(a.socket).at(-1);
  assert.deepEqual([ultima.type, ultima.codigo], ['ERRO', 'formato']);
  // O excesso conta para a família de formato: mais 4 e a ligação fecha.
  for (let i = 0; i < 4; i++) a.json(JOIN_HEROINA);
  assert.equal(entradas, 10);
  assert.deepEqual(fecho(a.socket), { codigo: 1008, motivo: 'formato' });
  servidor.close();
});
