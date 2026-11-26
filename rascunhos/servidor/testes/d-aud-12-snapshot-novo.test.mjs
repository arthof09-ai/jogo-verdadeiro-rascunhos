// ORDEM-PLANO-2-F1-ADENDA (CM-000009, 23/11/2026) — D-AUD-12: o sufixo também no SNAPSHOT novo.
// A INVESTIGA (E9, reprodução `l28`) viu «Orc»/«Orc» na jogadora depois de um snapshot novo: o `nomePublico` das figuras
// do ROOM_SNAPSHOT da Party vem de `figuraPublica` (projecao.js), e não dos eventos. O cliente substitui as figuras
// inteiras pelas do snapshot (estado.gd:133-138: `figuras = {}` e depois cada uma da lista), por isso, se o snapshot
// perdesse o número, «Orc 1»/«Orc 2» voltavam a «Orc»/«Orc» no ecrã dela. Caso de regressão obrigatório: em cada
// caminho que dá um snapshot novo — reentrada, resync, recomeço e reabrir a sala a partir do journal — as duas criaturas
// da mesma ficha continuam numeradas, para a jogadora e para o espectador.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { criarSala } from '../nucleo/sala.js';
import { montarMesa, exigirAplicada, rngDeterministico, relogio, fichasDeTeste, INICIATIVA, PIN, SENHAS } from './ajudantes.mjs';
import { criarMotorFalso } from './motor-falso.mjs';

// J-F4 (PLANO-2-F1-ADENDA-J-F1-J-F6): sem `.sort()`. Cada nome confere-se na casa da figura que o deve ter — o orc posto
// primeiro (2,6) é «Orc 1», o segundo (5,6) é «Orc 2» —, para uma troca dos números entre as duas figuras não passar
// despercebida; e o snapshot tem de ter as 4 figuras. (A ordem da lista não é contrato: a sala reaberta do journal dá
// Heroína, Lobo, Orc, Orc; os outros caminhos dão Heroína, Orc, Orc, Lobo. Por isso não se compara a lista por posição.)
const ESPERADO = { '2,2': 'Heroína Teste', '2,6': 'Orc 1', '5,6': 'Orc 2', '9,9': 'Lobo 1' };
const nomes = (snap) => snap.figuras.map((f) => `${f.nomePublico}@${f.x},${f.y}`);
const porCasa = (snap) => Object.fromEntries(snap.figuras.map((f) => [`${f.x},${f.y}`, f.nomePublico]));
function conferir(snap, msg) {
  assert.equal(snap.figuras.length, 4, `${msg ?? 'snapshot'}: 4 figuras`);
  assert.deepEqual(porCasa(snap), ESPERADO, msg);
}
const snapshotsEm = (msgs) => msgs.filter((x) => x.type === 'ROOM_SNAPSHOT');

/** Se PROVA_SNAPSHOT estiver definido, escreve o snapshot (só os nomes) para o log das provas. */
function registar(rotulo, snap) {
  if (process.env.PROVA_SNAPSHOT) console.log(`PROVA ${rotulo}: ${JSON.stringify(nomes(snap))}`);
}

function doisOrcsEUmLobo() {
  const m = montarMesa({ comEspectador: true });
  m.entrarTodos();
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }], ['orc-teste', { x: 5, y: 6 }], ['lobo-teste', { x: 9, y: 9 }]]);
  return m;
}

test('D-AUD-12 adenda: quem entra a meio da batalha recebe o snapshot já com «Orc 1»/«Orc 2»', () => {
  // A Heroína entra antes das colocações; o espectador só entra depois, e o primeiro mundo que vê é o do snapshot.
  const m2 = montarMesa({ comEspectador: true });
  m2.entrar('mestre', { papel: 'mestre', pin: PIN });
  m2.entrar('heroina', { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina });
  m2.iniciarCombate([['orc-teste', { x: 2, y: 6 }], ['orc-teste', { x: 5, y: 6 }], ['lobo-teste', { x: 9, y: 9 }]]);
  const r = m2.entrar('espectador', { papel: 'espectador', nome: 'Visita', senha: SENHAS.espectador });
  assert.ok(r.ok);
  const snap = snapshotsEm(r.r.mensagens).at(-1);
  assert.ok(snap, 'a entrada leva um snapshot');
  registar('entrada-tardia-espectador', snap);
  conferir(snap);
});

test('D-AUD-12 adenda: REENTRADA — a jogadora sai e volta; o snapshot novo mantém «Orc 1»/«Orc 2»', () => {
  const m = doisOrcsEUmLobo();
  for (const [chave, join] of [
    ['heroina', { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina }],
    ['espectador', { papel: 'espectador', nome: 'Visita', senha: SENHAS.espectador }],
  ]) {
    m.sair(chave);
    const r = m.entrar(chave, join);
    assert.ok(r.ok, `${chave} volta a entrar`);
    const snap = snapshotsEm(r.r.mensagens).at(-1);
    assert.ok(snap, `${chave}: a reentrada leva um snapshot`);
    registar(`reentrada-${chave}`, snap);
    conferir(snap, `${chave}: os nomes no snapshot da reentrada`);
  }
});

test('D-AUD-12 adenda: RESYNC — um lastSeq que o servidor não consegue servir dá snapshot, com «Orc 1»/«Orc 2»', () => {
  const m = doisOrcsEUmLobo();
  for (const chave of ['heroina', 'espectador']) {
    const c = m.clientes[chave];
    const resp = m.enviar(chave, { type: 'ROOM_RESYNC', lastSeq: c.ultimoSeq + 1000 });
    const snap = snapshotsEm(resp).at(-1);
    assert.ok(snap, `${chave}: o resync deu snapshot`);
    registar(`resync-${chave}`, snap);
    conferir(snap, `${chave}: os nomes no snapshot do resync`);
  }
});

test('D-AUD-12 adenda: RESYNC depois do recomeço (lastSeq antes do corte) — o snapshot mantém «Orc 1»/«Orc 2»', () => {
  // J-F4: a jogadora e o espectador, como os outros casos de caminho.
  const m = doisOrcsEUmLobo();
  const antes = { heroina: m.clientes.heroina.ultimoSeq, espectador: m.clientes.espectador.ultimoSeq };
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'recomecar' }), 'recomeçar');
  for (const chave of ['heroina', 'espectador']) {
    const resp = m.enviar(chave, { type: 'ROOM_RESYNC', lastSeq: antes[chave] });
    const snap = snapshotsEm(resp).at(-1);
    assert.ok(snap, `${chave}: o resync com o lastSeq de antes do recomeço dá o snapshot`);
    registar(`resync-pos-recomeco-${chave}`, snap);
    conferir(snap, `${chave}: os nomes no snapshot do resync depois do recomeço`);
  }
});

test('D-AUD-12 adenda: RECOMEÇO — o snapshot que vai a todos mantém «Orc 1»/«Orc 2»', () => {
  const m = doisOrcsEUmLobo();
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'recomecar' }), 'recomeçar');
  for (const chave of ['heroina', 'espectador']) {
    const snap = m.clientes[chave].ultimo('ROOM_SNAPSHOT');
    registar(`recomeco-${chave}`, snap);
    conferir(snap, `${chave}: os nomes no snapshot do recomeço`);
  }
});

// A sala reaberta do journal (o servidor reinicia a meio da batalha). Até o Mestre voltar, quem não é Mestre fica na
// sala de espera (ordem 22, 17-2: o snapshot dela é só o lobby); a batalha chega-lhe num snapshot quando o Mestre entra,
// ou logo na entrada, se o Mestre já lá estiver.
function salaReaberta(m) {
  const config = {
    roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'auto', depurar: true,
    lugares: [
      { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
      { papel: 'espectador', nome: 'Visita', senha: SENHAS.espectador },
      { papel: 'mestre', nome: 'Mestre', pin: PIN },
    ],
  };
  return criarSala({
    motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(), agora: relogio(), config, restaurarDe: m.sala.exportar(),
  });
}
const JOIN = {
  mestre: { papel: 'mestre', pin: PIN },
  heroina: { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina },
};
const entrarEm = (sala, quem, ip) => {
  const r = sala.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', ...JOIN[quem] }, { ip });
  assert.ok(r.ok, `${quem} entra na sala reaberta`);
  sala.conexaoAberta(r.seatId);
  return r;
};

test('D-AUD-12 adenda: a sala REABERTA do journal, o Mestre já dentro — a jogadora entra e vê «Orc 1»/«Orc 2»', () => {
  const sala2 = salaReaberta(doisOrcsEUmLobo());
  entrarEm(sala2, 'mestre', '10.0.0.8');
  const snap = snapshotsEm(entrarEm(sala2, 'heroina', '10.0.0.9').mensagens).at(-1);
  assert.ok(snap, 'a entrada na sala reaberta leva um snapshot');
  registar('sala-reaberta-heroina', snap);
  assert.equal(snap.fase, 'combate');
  conferir(snap);
});

test('D-AUD-12 adenda: a sala REABERTA do journal, a jogadora à espera — o snapshot da batalha, quando o Mestre volta, traz «Orc 1»/«Orc 2»', () => {
  const sala2 = salaReaberta(doisOrcsEUmLobo());
  const h = entrarEm(sala2, 'heroina', '10.0.0.9');
  const lobby = snapshotsEm(h.mensagens).at(-1);
  assert.equal(lobby.fase, 'lobby', 'à espera do Mestre: só o lobby');
  // J-F5 (PLANO-2-F1-ADENDA-J-F1-J-F6): o lobby da espera não traz figuras — medido, não só lido no código.
  registar('sala-reaberta-lobby-heroina', lobby);
  assert.ok(Array.isArray(lobby.figuras), 'o snapshot do lobby tem a lista de figuras');
  assert.equal(lobby.figuras.length, 0, 'à espera do Mestre: o snapshot do lobby traz 0 figuras');
  const rm = entrarEm(sala2, 'mestre', '10.0.0.8');
  const snap = rm.saidas.filter((s) => s.seatId === h.seatId && s.msg.type === 'ROOM_SNAPSHOT').map((s) => s.msg).at(-1);
  assert.ok(snap, 'o Mestre entra: a jogadora recebe o snapshot da batalha');
  registar('sala-reaberta-fim-da-espera-heroina', snap);
  assert.equal(snap.fase, 'combate');
  conferir(snap);
});
