// Canários de privacidade (protocolo §6, ERRATA E-P1..E-P14, v0.2.1; base da JV1.2).
// Um guião completo com duas jogadoras, um espectador e o Mestre. Depois, varre-se TUDO o que
// chegou à Party à procura de valores que só o Mestre pode ver.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  montarMesa, exigirAplicada, procurarCanarios, recibo, varrer, PIN, SENHAS,
  SEMENTE, NUMEROS_SO_MESTRE, TEXTOS_SO_MESTRE, CHAVES_SO_MESTRE, NUMEROS_HEROINA, NUMEROS_ALIADA, TEXTOS_HEROINA,
} from './ajudantes.mjs';
import { CAMPOS_PERMITIDOS, projetarEvento } from '../nucleo/projecao.js';
import { ordemDinamicaVazia, registarEvento } from '../nucleo/ordem-dinamica.js';

// Ordem CAIXA-TESTES-CORRECOES-3 (B7): as listas vêm de ajudantes.mjs (uma só fonte com caixa-hud-jogadora.test.mjs).
// Valores que NENHUM papel da Party pode ver.
const NUMEROS_MESTRE = NUMEROS_SO_MESTRE;
// Os textos de qualquer mesa + os canários deste guião (cartões da IA e da desgraça, o bandido-fantasma, o ambiente).
const TEXTOS_MESTRE = [
  'CANARIO-RAZAO-IA', 'CANARIO-DESGRACA', 'CANARIO-FANTASMA', 'raio 23:59 CANARIO', '23:59',
  ...TEXTOS_SO_MESTRE,
];
const CHAVES_MESTRE = CHAVES_SO_MESTRE;
// Da heroína: só ela os vê. Da aliada: só ela. (NUMEROS_HEROINA / NUMEROS_ALIADA, de ajudantes.mjs.)

function guiao({ m51b = false, voltar = true } = {}) {
  const m = montarMesa({ comAliada: true, comEspectador: true, rngSemente: () => SEMENTE });
  m.entrarTodos();
  // Lobby com o bandido disponível, mas NUNCA colocado (CANARIO-FANTASMA).
  m.iniciarCombate([['orc-teste', { x: 2, y: 6 }], ['lobo-teste', { x: 12, y: 12 }]]);
  const h = m.clientes.heroina;
  const orc = h.idPorNome('Orc');
  const lobo = h.idPorNome('Lobo');

  // Ocultos: modo H10 e painel do ambiente.
  exigirAplicada(m.mestre('MASTER_MODE', { figuraId: lobo, modo: 'semi' }));
  exigirAplicada(m.mestre('MASTER_AMBIENTE', { hora: '23:59', clima: 'tempestade', futuro: 'raio 23:59 CANARIO' }));
  m.mestre('MASTER_SEARCH', { texto: 'bandido' });

  // Heroína acerta o orc: 1176 de dano (ela vê o número), o orc fica com 6601 (ninguém da Party vê).
  exigirAplicada(m.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }));
  // Recusas indistinguíveis: id oculto (fichaId do bandido), inexistente.
  m.intencao('heroina', { tipo: 'atacar', alvoId: 'bandido-teste', arma: 'chicote-teste' }, { intentId: 'oculto-1' });
  m.intencao('heroina', { tipo: 'atacar', alvoId: 'f0000000000000000', arma: 'chicote-teste' }, { intentId: 'oculto-2' });
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));

  // Aliada: falha crítica → cartão de desgraça ao Mestre (CANARIO-DESGRACA) → aprovado.
  m.motor.cfg.resultado = 'falha_critica';
  const r = m.intencao('aliada', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }, { intentId: 'aliada-fc' });
  assert.equal(recibo(r).estado, 'AGUARDANDO_MESTRE');
  const cartaoDesgraca = m.clientes.mestre.ultimo('MASTER_CARD');
  assert.equal(cartaoDesgraca.tipo, 'desgraca');
  exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: cartaoDesgraca.cartaoId, decisao: 'aprovar' }));
  m.motor.cfg.resultado = 'acerto';
  exigirAplicada(m.intencao('aliada', { tipo: 'encerrar' }));

  // Lobo em semi: o Mestre aprova as propostas (CANARIO-RAZAO-IA nos cartões) até a vez passar.
  for (let i = 0; i < 8; i++) {
    const c = m.clientes.mestre.ultimo('MASTER_CARD');
    if (!m.sala.depuracao.estado().cartoes.some((x) => x.cartaoId === c.cartaoId && x.estado === 'aberto')) break;
    exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: c.cartaoId, decisao: 'aprovar' }));
  }
  // O orc (auto) joga sozinho; a vez volta à heroína.
  assert.equal(h.opcoes?.vezId, h.figuraId, 'a vez voltou à heroína');

  // Ordem CAIXA-TESTES (21/11/2026, correcção B5-b): o Mestre muda a caixa (escolherCaixa) a meio da batalha, com a
  // ordem dinâmica já formada — a Party recebe um ROOM_SNAPSHOT com a `caixa` dela, e esse caminho também é varrido.
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'caixa', caixa: { ligada: true, modo: 'iniciativa' } }), 'caixa iniciativa');
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'caixa', caixa: { ligada: false, modo: 'iniciativa' } }), 'caixa desligada');
  exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'caixa', caixa: { ligada: true, modo: 'dinamico' } }), 'caixa dinâmico');

  // Reconexões: RESYNC desde o início e snapshot, para todos os papéis da Party.
  for (const k of ['heroina', 'aliada', 'espectador']) {
    m.enviar(k, { type: 'ROOM_RESYNC', lastSeq: 0 });
    m.enviar(k, { type: 'ROOM_RESYNC' });
    m.enviar(k, { type: 'RECEIPT_QUERY', intentIds: ['aliada-fc', 'oculto-1'] });
  }
  // Ordem CAIXA-TESTES-CORRECOES-6 (B1): o caminho da M51b, sem fuga — a aliada desce a uma Vida BAIXA, é fotografada
  // num RESYNC e o Mestre volta ao fim do guião (2403). Só no teste da Vida baixa; o guião de sempre não muda.
  // O caminho: uma volta inteira (o orc acerta-lhe: 2403 → 1227); na volta seguinte o lobo, já ao pé, acerta-lhe
  // primeiro (1227 → 51) — o RESYNC é logo aí, antes de o orc jogar (o orc levava-a a −1125).
  // Ordem CAIXA-TESTES-GUIAO-FRAGIL (B3): `voltar: false` deixa o guião acabar nas duas voltas, SEM «voltar» — a ordem
  // dinâmica da Party já não é a das escolhas da caixa (na 2.ª volta o lobo joga antes do orc e a ordem troca-os).
  if (m51b) {
    const vidaAliada = () => m.sala.depuracao.estado().figuras[m.clientes.aliada.figuraId].vidaActual;
    const fimDoGuiao = m.sala.depuracao.journalSeq();
    voltaInteira(m);
    voltaInteira(m, () => vidaAliada() !== 1227);
    assert.equal(vidaAliada(), 51, 'M51b: o lobo levou a aliada a 51');
    for (const k of ['heroina', 'aliada', 'espectador']) m.enviar(k, { type: 'ROOM_RESYNC' });
    if (voltar) exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'voltar', ateSeq: fimDoGuiao }), 'voltar ao fim do guião');
  }
  return m;
}

// Ordem CAIXA-TESTES-GUIAO-FRAGIL (B2): a ordem dinâmica da Party que a SALA registou num instante do journal. É a mesma
// regra do servidor (sala.js finalizar): cada evento, projectado como o vê o espectador, passa por registarEvento; o
// «Recomeçar» limpa (registarEvento); o «voltar» (`revertido`, soMestre.ateSeq) repõe a ordem do ponto a que se volta
// (o journal nunca apaga história: reconstrói-se esse ponto). Uma batalha nova (rodada de volta a 1 sem `recomeco` nem
// `revertido`) não é modelada: falha ALTA, não calada — muda-se esta função, nunca se volta à ordem do fim.
function ordemPartyRegistada(m, ateSeq) {
  const eventos = m.sala.depuracao.eventos();
  const reconstruir = (ate) => {
    let od = ordemDinamicaVazia();
    let rodada = 0;
    for (const e of eventos) {
      if (e.journalSeq > ate) break;
      if (e.tipo === 'revertido') {
        assert.ok(Number.isInteger(e.soMestre?.ateSeq) && e.soMestre.ateSeq < e.journalSeq, 'o `revertido` traz o ateSeq');
        ({ od, rodada } = reconstruir(e.soMestre.ateSeq));
        continue;
      }
      if (e.tipo === 'recomeco') rodada = 0;
      if (e.tipo === 'turno') {
        assert.ok(e.dados.rodada >= rodada, `journal ${e.journalSeq}: batalha nova sem recomeço — a reconstrução da ordem não a modela`);
        rodada = e.dados.rodada;
      }
      const visto = projetarEvento(e, { papel: 'espectador', figuraId: null });
      if (visto !== null) registarEvento(od, { tipo: e.tipo, dados: visto });
    }
    return { od, rodada };
  };
  return reconstruir(ateSeq).od;
}

// O instante do journal em que um snapshot foi feito: o último evento com ts ≤ o do snapshot. O relógio da mesa anda a
// cada transacção (ajudantes.mjs relogio) e o escolherCaixa não emite evento — o snapshot dele é o estado nesse ponto.
// (O RESYNC com lastSeq reenvia o snapshot GRAVADO, com o mesmo ts: dá o mesmo instante.)
function journalSeqDoSnapshot(m, s) {
  let seq = 0;
  for (const e of m.sala.depuracao.eventos()) if (e.ts <= s.ts) seq = Math.max(seq, e.journalSeq);
  assert.ok(seq > 0, 'o snapshot tem um instante no journal');
  return seq;
}

// Uma volta da ordem: as duas jogadoras encerram e o Mestre aprova as propostas do lobo (semi) até a vez passar; o orc
// (auto) joga sozinho. Cada golpe na aliada tira 1176 (o motor falso). `parar` corta a volta a meio (depois de uma
// aprovação), para fotografar um estado intermédio.
function voltaInteira(m, parar = () => false) {
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
  exigirAplicada(m.intencao('aliada', { tipo: 'encerrar' }));
  for (let i = 0; i < 8; i++) {
    const c = m.clientes.mestre.ultimo('MASTER_CARD');
    if (!m.sala.depuracao.estado().cartoes.some((x) => x.cartaoId === c.cartaoId && x.estado === 'aberto')) break;
    exigirAplicada(m.mestre('MASTER_APPROVE', { cartaoId: c.cartaoId, decisao: 'aprovar' }));
    if (parar()) return;
  }
}

// Ordem CAIXA-TESTES-CORRECOES-5 (B4): todos os valores que a Vida actual da jogadora `k` teve no guião, não só o do
// fim. Um segundo golpe (ou uma cura, ou um «voltar») depois de um snapshot com fuga deixa o valor que fugiu ≠ o do fim,
// e uma guarda só com o do fim passava calada. O histórico vem de: a Vida máxima (o valor de partida, da ficha), cada
// evento `estado` do journal com a `vidaActual` dessa figura, o valor final do estado da sala e — com `proprias` — a
// `propria` de cada snapshot que a própria recebeu. O journal nunca apaga história, nem no «voltar».
// Ordem CAIXA-TESTES-CORRECOES-7 (B3), precisado na CAIXA-TESTES-CORRECOES-8 (B3): o `estado` NÃO regista todas as
// mudanças da Vida. As acções do jogo emitem-no, mas o «voltar» e o «recomeçar» mudam a Vida sem ele: o «voltar» emite
// `revertido` (mais `cartao_fechado`/`cartao` para os cartões) e o «recomeçar» emite `recomeco`, nenhum emite `estado`.
// Hoje isso não abre buraco: o «voltar» repõe a Vida de um instante anterior do guião, o «recomeçar» repõe a máxima (a
// de partida), e a Vida do fim entra sempre pelo estado da sala.
// Ordem CAIXA-TESTES-CORRECOES-6 (B1), parágrafo reescrito na CAIXA-TESTES-CORRECOES-7 (B2): só o 0 fica de fora. NÃO é o
// único valor que colide. No guião de hoje chegam às jogadoras, sob chaves que o varredor NÃO isenta, o 0 (`geral`) e o
// 2, 3, 6, 9, 14, 18, 20 e 23 (`custoPA`/`protocolo`/`v`, `custoM`, `custoM`, `alcanceM`/`custoM`/`deslocamentoBase`/
// `orcamentoM`, `constituicao`, `faces`, `altura`/`largura`, `total`), e o 51 (`vidaActual`), só nas mensagens da
// própria aliada no guião da M51b — é dela, não é colisão (CAIXA-TESTES-CORRECOES-8, B2). O 0 é o único que TEM de ser
// excluído, porque é uma Vida alcançável (a de quem cai) e o `geral: 0` vai em todos os snapshots das jogadoras: com o
// 0 no histórico, a guarda falhava sempre. Os outros só colidem se a Vida de uma jogadora passar por eles, e hoje não
// passa. Os contadores e as coordenadas a 0 (`seq`, `revision`, `rodada`, `x`, `y`) não colidem: `procurarCanarios`
// isenta-os abaixo de 100.
// O corte antigo (< 100) deixava passar calada a fuga de um intermédio baixo: a M51b (a aliada a 51, fotografada num
// RESYNC, depois «voltar» a 2403) ficava viva com este ficheiro 9/9 e a suite verde. Se um valor baixo do histórico
// colidir um dia com um número legítimo, a falha é ALTA, não calada: muda-se o guião, nunca se volta ao corte.
function historicoVida(m, k, { proprias = true } = {}) {
  const est = m.sala.depuracao.estado();
  const fig = m.clientes[k].figuraId;
  const v = new Set([m.fichas[est.figuras[fig].fichaId].vidaTotal, est.figuras[fig].vidaActual]);
  for (const e of m.sala.depuracao.eventos()) {
    if (e.tipo === 'estado' && e.dados?.figuraId === fig && typeof e.dados.vidaActual === 'number') v.add(e.dados.vidaActual);
  }
  if (proprias) for (const s of m.clientes[k].msgs) if (s.type === 'ROOM_SNAPSHOT' && typeof s.propria?.vidaActual === 'number') v.add(s.propria.vidaActual);
  return [...v].filter((x) => x !== 0).sort((a, b) => a - b);
}

function conferirCanariosDoMestre(m) {
  for (const k of ['heroina', 'aliada', 'espectador']) {
    const achados = procurarCanarios(m.clientes[k].msgs, { numeros: NUMEROS_MESTRE, textos: TEXTOS_MESTRE, chaves: CHAVES_MESTRE });
    assert.deepEqual(achados, [], `vazamento para ${k}: ${JSON.stringify(achados.slice(0, 5))}`);
  }
  // Sanidade (B5-b): o caminho do escolherCaixa correu e foi varrido — cada papel da Party recebeu os snapshots da caixa,
  // com a ordem dinâmica já formada (não vazia); o Mestre recebeu a escolha dele na MASTER_VIEW.
  for (const k of ['heroina', 'aliada', 'espectador']) {
    const caixas = m.clientes[k].msgs.filter((x) => x.type === 'ROOM_SNAPSHOT' && x.caixa).map((x) => x.caixa);
    assert.ok(caixas.some((c) => c.ligada === true && c.ordemPor === 'iniciativa'), k + ': snapshot da caixa em iniciativa');
    assert.ok(caixas.some((c) => c.ligada === false), k + ': snapshot da caixa desligada');
    assert.ok(caixas.some((c) => c.ordemDinamica.ordem.length > 0), k + ': a caixa varrida traz a ordem dinâmica da Party');
    // B2 (CAIXA-TESTES-CORRECOES-2): o VALOR da ordem nos snapshots do escolherCaixa (os únicos em `iniciativa`), com 2+
    // figuras para uma ordem trocada se ver. Re-ancorada na CAIXA-TESTES-GUIAO-FRAGIL (B2): compara-se com a ordem que
    // a sala REGISTOU no instante desse snapshot (ordemPartyRegistada, pelo journal), não com a do fim. Antes valia «nada
    // mexe nela depois das escolhas» — o guião com duas voltas depois das escolhas e sem «voltar» (a 2.ª volta troca o
    // lobo e o orc) partia este teste em falso positivo, sem fuga nenhuma.
    const snapsIniciativa = m.clientes[k].msgs.filter((x) => x.type === 'ROOM_SNAPSHOT' && x.caixa?.ordemPor === 'iniciativa');
    assert.ok(snapsIniciativa.length >= 1, k + ': snapshots do escolherCaixa em iniciativa');
    for (const s of snapsIniciativa) {
      const registada = ordemPartyRegistada(m, journalSeqDoSnapshot(m, s)).ordem;
      assert.ok(registada.length >= 2, k + ': a ordem da Party registada nesse instante tem 2+ figuras');
      assert.deepEqual(s.caixa.ordemDinamica.ordem, registada, k + ': a ordem no snapshot do escolherCaixa');
    }
    // B6 (CAIXA-TESTES-CORRECOES): as chaves exactas da caixa da Party em todos os snapshots — nada a mais, nada a menos.
    for (const c of caixas) {
      assert.deepEqual(Object.keys(c).sort(), ['ligada', 'ordemDinamica', 'ordemPor'], k + ': as chaves da caixa');
      assert.deepEqual(Object.keys(c.ordemDinamica).sort(), ['fechada', 'ordem', 'ultimo'], k + ': as chaves da ordem dinâmica');
    }
  }
  const vistaMestre = m.enviar('mestre', { type: 'MASTER_VIEW' }).find((x) => x.type === 'MASTER_VIEW');
  assert.deepEqual(vistaMestre.caixaMestre, { ligada: true, modo: 'dinamico' }, 'o Mestre vê a escolha dele');
  // Sanidade: o Mestre recebeu os canários (o teste não está a varrer o vazio).
  const mestre = JSON.stringify(m.clientes.mestre.msgs);
  // CAIXA-TESTES-CORRECOES-3 (B3): também o nome verdadeiro do lobo e os verbos do orc e do lobo.
  for (const t of ['CANARIO-RAZAO-IA', 'CANARIO-DESGRACA', 'CANARIO-FANTASMA', 'raio 23:59 CANARIO', '9137', '6601', String(SEMENTE),
    'Lobo Teste', 'desferiu o machado', 'tentou desferir o machado', 'deu uma patada', 'tentou dar uma patada']) {
    assert.ok(mestre.includes(t), 'o Mestre vê ' + t);
  }
  // Sanidade da reconstrução (B2, CAIXA-TESTES-GUIAO-FRAGIL): pelo journal inteiro, ordemPartyRegistada chega à ordem da
  // Party que a sala tem agora — a função não se desvia da regra do servidor (se se desviar, falha aqui, alto).
  const { ordem, fechada, ultimo, vezes } = m.sala.depuracao.estado().ordemDinamicaParty;
  assert.deepEqual(ordemPartyRegistada(m, m.sala.depuracao.journalSeq()), { ordem, fechada, ultimo, vezes }, 'a ordem reconstruída do journal = a da sala');
}

test('canários: nada do Mestre chega a nenhum papel da Party (jogadoras e espectador)', () => {
  conferirCanariosDoMestre(guiao());
});

// Ordem CAIXA-TESTES-GUIAO-FRAGIL (B3): o controlo da fragilidade. O guião avança as duas voltas depois das escolhas da
// caixa (as da M51b) e acaba SEM «voltar»: a ordem da Party do fim já não é a das escolhas (sanidade do caminho, abaixo).
// O teste de cima, todo, tem de passar assim — a ordem do snapshot do escolherCaixa vale pelo instante registado.
test('canários: nada do Mestre chega à Party com o guião duas voltas depois das escolhas da caixa, sem «voltar»', () => {
  const m = guiao({ m51b: true, voltar: false });
  assert.ok(!m.sala.depuracao.eventos().some((e) => e.tipo === 'revertido'), 'o guião acabou sem «voltar»');
  assert.equal(m.sala.depuracao.estado().figuras[m.clientes.aliada.figuraId].vidaActual, 51, 'o guião acabou nas duas voltas (aliada a 51)');
  const snap = m.clientes.heroina.msgs.find((x) => x.type === 'ROOM_SNAPSHOT' && x.caixa?.ordemPor === 'iniciativa');
  assert.notDeepEqual(m.sala.depuracao.estado().ordemDinamicaParty.ordem, snap.caixa.ordemDinamica.ordem,
    'a ordem da Party mudou depois das escolhas (senão o controlo não toca a fragilidade)');
  conferirCanariosDoMestre(m);
});

test('canários: "outra jogadora" e espectador não veem a ficha, a Vida nem o dano alheio', () => {
  const m = guiao();
  const cfg = (numeros) => ({ numeros, textos: [], chaves: [] });
  assert.deepEqual(procurarCanarios(m.clientes.aliada.msgs, cfg(NUMEROS_HEROINA)), [], 'a aliada não vê a heroína (perícia 8642)');
  assert.deepEqual(procurarCanarios(m.clientes.espectador.msgs, cfg(NUMEROS_HEROINA)), []);
  assert.deepEqual(procurarCanarios(m.clientes.heroina.msgs, cfg(NUMEROS_ALIADA)), [], 'a heroína não vê a aliada');
  assert.deepEqual(procurarCanarios(m.clientes.espectador.msgs, cfg(NUMEROS_ALIADA)), []);
  // Número do dano: a heroína vê o dela (1176 no orc); o espectador nunca vê números de dano.
  assert.ok(JSON.stringify(m.clientes.heroina.msgs).includes('1176'), 'v0.2.1: ela vê o dano que causa');
  assert.deepEqual(procurarCanarios(m.clientes.espectador.msgs, cfg([1176])), [], 'o espectador não vê o número');
  // A-2: a aliada não vê o número do golpe da heroína (só os dela).
  const danosVistosPelaAliada = m.clientes.aliada.eventos('dano');
  const h = m.clientes.heroina;
  for (const e of danosVistosPelaAliada) {
    if (e.dados.autorId === h.figuraId) assert.ok(!('valor' in e.dados), 'sem número do golpe alheio');
  }
  // A própria vê a sua ficha (com a perícia 8642).
  assert.ok(JSON.stringify(h.msgs).includes('1d20+8642'));
  // Ordem CAIXA-TESTES-CORRECOES-4 (B2): a perícia 8642 também como TEXTO ('1d20+8642' na ficha). NUMEROS_HEROINA só a
  // apanha como número; a aliada e o espectador não a podem ver em string nenhuma. (A heroína fica de fora: é dela.)
  const txt = (textos) => ({ numeros: [], textos, chaves: [] });
  assert.deepEqual(procurarCanarios(m.clientes.aliada.msgs, txt(TEXTOS_HEROINA)), [], 'a aliada não vê a perícia da heroína em texto');
  assert.deepEqual(procurarCanarios(m.clientes.espectador.msgs, txt(TEXTOS_HEROINA)), [], 'o espectador não vê a perícia da heroína em texto');
});

// Ordem CAIXA-TESTES-CORRECOES-4 (B1): a Vida VARIÁVEL. NUMEROS_HEROINA/NUMEROS_ALIADA só têm a Vida máxima (5150/3579):
// a `vidaActual` de uma jogadora ferida (no guião, a aliada fica com 2403 = 3579 − 1176) posta no snapshot da outra
// passava calada. Duas guardas: (1) o VALOR — cada Vida actual que cada jogadora teve no guião (CORRECOES-5, B4: o
// histórico, não só a do fim), não chega à outra nem ao espectador, em mensagem nenhuma; (2) a FORMA — cada ROOM_SNAPSHOT da Party mostra só as
// `vidaActual` que esse papel pode ver (a própria, em `propria`; nenhuma ao espectador) e as figuras públicas têm as
// chaves exactas de projecao.js figuraPublica (sem Vida de ninguém). A figura não tem `vidaTotal` (sala.js novaFigura):
// a Vida máxima vem da ficha.
test('canários: a Vida actual (variável) de uma jogadora ferida não chega à outra jogadora nem ao espectador', () => {
  const m = guiao();
  const est = m.sala.depuracao.estado();
  const figuraDe = { heroina: m.clientes.heroina.figuraId, aliada: m.clientes.aliada.figuraId };
  const vidaActual = (k) => est.figuras[figuraDe[k]].vidaActual;
  const vidaTotal = (k) => m.fichas[est.figuras[figuraDe[k]].fichaId].vidaTotal;
  // Sanidade: o canário variável está vivo — a aliada está ferida (Vida actual ≠ a máxima das listas fixas).
  assert.ok(vidaActual('aliada') < vidaTotal('aliada'), `a aliada está ferida (${vidaActual('aliada')}/${vidaTotal('aliada')})`);
  // A guarda (1) varre o histórico da Vida (historicoVida, acima: CORRECOES-5 B4, CORRECOES-6 B1). Hoje a aliada
  // fere-se num só passo (3579 → 2403), e aí o valor final é o único intermédio.
  const historico = (k) => historicoVida(m, k);
  // Sanidade do histórico: a fonte não está morta — a aliada passou pela máxima e pela ferida (hoje [2403, 3579]).
  assert.ok(historico('aliada').includes(vidaActual('aliada')) && historico('aliada').includes(vidaTotal('aliada')),
    `o histórico da Vida da aliada tem a de partida e a do fim (${historico('aliada')})`);
  assert.ok(m.sala.depuracao.eventos().some((e) => e.tipo === 'estado' && e.dados?.figuraId === figuraDe.aliada && e.dados.vidaActual === vidaActual('aliada')),
    'o journal regista a Vida ferida da aliada num evento `estado` (a fonte dos intermédios)');
  // (1) O valor — cada valor do histórico —, em tudo o que chegou (snapshots e eventos).
  const cfg = (numeros) => ({ numeros, textos: [], chaves: [] });
  for (const [dona, outros] of [['heroina', ['aliada', 'espectador']], ['aliada', ['heroina', 'espectador']]]) {
    for (const k of outros) {
      assert.deepEqual(procurarCanarios(m.clientes[k].msgs, cfg(historico(dona))), [], `${k} viu uma Vida actual de ${dona} (${historico(dona)})`);
    }
  }
  // (2) A forma, snapshot a snapshot.
  const CHAVES_FIGURA_PUBLICA = ['id', 'lado', 'nomePublico', 'orientacao', 'visivel', 'x', 'y'];
  for (const k of ['heroina', 'aliada', 'espectador']) {
    const snaps = m.clientes[k].msgs.filter((x) => x.type === 'ROOM_SNAPSHOT');
    assert.ok(snaps.length >= 2, k + ': snapshots varridos');
    for (const s of snaps) {
      const vidas = [];
      varrer(s, ({ chave, valor, ehChave }) => { if (!ehChave && chave === 'vidaActual') vidas.push(valor); });
      if (k === 'espectador') {
        assert.equal(s.propria, undefined, 'o espectador não tem `propria`');
        assert.deepEqual(vidas, [], 'o espectador não vê Vida actual nenhuma');
      } else {
        assert.equal(s.propria?.figuraId, figuraDe[k], k + ': a `propria` é a dela');
        assert.deepEqual(vidas, [s.propria.vidaActual], k + ': só a Vida actual dela, em `propria`');
      }
      for (const f of s.figuras) assert.deepEqual(Object.keys(f).sort(), CHAVES_FIGURA_PUBLICA, k + ': as chaves da figura pública');
    }
    // Sanidade da exclusão (re-ancorada na CAIXA-TESTES-CORRECOES-6, B2): cada `propria` mostra uma Vida que a SALA
    // registou para essa jogadora (a de partida, um evento `estado` do journal ou a do fim — sem as próprias `propria`,
    // que seria circular). Antes comparava-se o ÚLTIMO snapshot com a Vida do fim, o que só vale se o guião acabar num
    // snapshot. O guião PODE acabar sem RESYNC: uma acção depois do último snapshot muda a Vida sem snapshot novo (a M20
    // sem RESYNC: 2403 no último snapshot ≠ 1227 no fim), e aí a sanidade antiga falhava em falso positivo, sem fuga.
    if (k !== 'espectador') {
      const registadas = historicoVida(m, k, { proprias: false });
      for (const s of snaps) assert.ok(registadas.includes(s.propria.vidaActual), `${k}: a \`propria\` (${s.propria.vidaActual}) é uma Vida registada dela (${registadas})`);
    }
  }
  // E a ferida vê-se ferida: algum snapshot da aliada mostra-lhe uma Vida abaixo da máxima (a exclusão não lhe tira a dela).
  assert.ok(m.clientes.aliada.msgs.some((s) => s.type === 'ROOM_SNAPSHOT' && s.propria.vidaActual < vidaTotal('aliada')),
    'aliada: vê a Vida ferida dela num snapshot');
});

// Ordem CAIXA-TESTES-CORRECOES-6 (B1, a M51b como regressão na suite): a Vida BAIXA de um intermédio. A aliada desce a
// 51 (3579 → 2403 → 1227 → 51), é fotografada num RESYNC com essa Vida e o Mestre «volta» ao fim do guião (2403). O 51
// nunca é o valor do fim: só o histórico o tem, e o corte antigo (< 100) tirava-o de lá. Sem fuga, ninguém da Party
// além dela vê o 51 nem o 1227; o teste prende também que o histórico os TEM (se o corte voltar, isto falha alto).
test('canários: a Vida baixa de um intermédio (51, depois «voltar») não chega à outra jogadora nem ao espectador', () => {
  const m = guiao({ m51b: true });
  const est = m.sala.depuracao.estado();
  const aliada = m.clientes.aliada;
  // Sanidades do caminho: o «voltar» repôs a Vida do fim do guião, e a aliada recebeu o snapshot com o 51.
  assert.equal(est.figuras[aliada.figuraId].vidaActual, 2403, 'o «voltar» repôs a aliada no 2403');
  assert.ok(aliada.msgs.some((s) => s.type === 'ROOM_SNAPSHOT' && s.propria?.vidaActual === 51), 'a aliada foi fotografada com 51');
  const hist = historicoVida(m, 'aliada');
  for (const v of [51, 1227, 2403, 3579]) assert.ok(hist.includes(v), `o histórico da aliada tem o ${v} (${hist})`);
  const cfg = (numeros) => ({ numeros, textos: [], chaves: [] });
  for (const k of ['heroina', 'espectador']) {
    assert.deepEqual(procurarCanarios(m.clientes[k].msgs, cfg(hist)), [], `${k} viu uma Vida actual da aliada (${hist})`);
  }
});

test('lista de campos permitidos: todo o ROOM_EVENT da Party só tem campos da lista do seu tipo', () => {
  const m = guiao();
  for (const k of ['heroina', 'aliada', 'espectador']) {
    for (const e of m.clientes[k].eventos()) {
      const regra = CAMPOS_PERMITIDOS[e.tipo];
      assert.ok(regra, `tipo ${e.tipo} chegou a ${k} sem estar na lista`);
      const permitidos = new Set([...regra.todos, ...regra.propria]);
      for (const campo of Object.keys(e.dados)) assert.ok(permitidos.has(campo), `${k}: campo ${e.tipo}.${campo} fora da lista`);
      if (k === 'espectador') for (const campo of Object.keys(e.dados)) assert.ok(regra.todos.includes(campo), `espectador: ${e.tipo}.${campo}`);
    }
  }
});

test('E-P7: id oculto e id inexistente dão a MESMA recusa, byte a byte (tirando o intentId)', () => {
  const m = guiao();
  const rej = m.clientes.heroina.msgs.filter((x) => x.type === 'ROOM_REJECT' && (x.intentId === 'oculto-1' || x.intentId === 'oculto-2'));
  assert.equal(rej.length, 2);
  const semId = rej.map((x) => JSON.stringify({ ...x, intentId: 'X' }));
  assert.equal(semId[0], semId[1]);
  assert.equal(rej[0].motivo, 'acao_invalida');
});

test('seatToken: cada um só vê o seu; a exportação leva só o hash; PIN e senhas nunca entram', () => {
  const m = guiao();
  const tokens = Object.fromEntries(Object.entries(m.clientes).map(([k, c]) => [k, c.token]));
  for (const [k, c] of Object.entries(m.clientes)) {
    const texto = JSON.stringify(c.msgs);
    for (const [outro, tok] of Object.entries(tokens)) {
      if (outro !== k) assert.ok(!texto.includes(tok), `${k} viu o token de ${outro}`);
    }
  }
  const exp = m.sala.exportar();
  assert.ok(exp.includes('MESTRE-ONLY'));
  for (const tok of Object.values(tokens)) assert.ok(!exp.includes(tok), 'token na exportação');
  for (const s of [PIN, SENHAS.heroina, SENHAS.aliada, SENHAS.espectador]) assert.ok(!exp.includes(s), 'segredo na exportação');
});

test('E-P9: 5 ROOM_JOIN errados bloqueiam e avisam o Mestre; papel mestre sem PIN é recusado', () => {
  const m = montarMesa();
  m.entrarTodos();
  const mestre = m.clientes.mestre;
  const ip = '192.0.2.7';
  for (let i = 0; i < 5; i++) {
    const r = m.entrar('intrusa', { papel: 'jogadora', nome: 'Heroína Teste', senha: 'errada-' + i }, ip);
    assert.equal(r.ok, false);
  }
  assert.ok(mestre.msgs.some((x) => x.type === 'MASTER_ALERTA' && x.motivo === 'bloqueio_join'), 'alerta ao Mestre');
  const sexta = m.entrar('intrusa', { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina }, ip);
  assert.equal(sexta.ok, false, 'bloqueado mesmo com a senha certa');
  assert.equal(sexta.r.mensagens[0].codigo, 'bloqueado');
  // O alerta não leva o IP nem a senha tentada.
  assert.ok(!JSON.stringify(mestre.msgs).includes('errada-'));

  const semPin = m.entrar('falso-mestre', { papel: 'mestre' }, '192.0.2.8');
  assert.equal(semPin.ok, false);
  const pinErrado = m.entrar('falso-mestre', { papel: 'mestre', pin: '000000' }, '192.0.2.8');
  assert.equal(pinErrado.ok, false);
});

test('E-P9: a recusa do JOIN é a mesma para nome inexistente e para senha errada', () => {
  const m = montarMesa();
  m.entrarTodos();
  const a = m.entrar('x', { papel: 'jogadora', nome: 'Ninguém', senha: 'x' }, '192.0.2.9');
  const b = m.entrar('y', { papel: 'jogadora', nome: 'Heroína Teste', senha: 'x' }, '192.0.2.10');
  assert.equal(a.ok, false);
  assert.equal(b.ok, false);
  assert.deepEqual(a.r.mensagens, b.r.mensagens);
});

test('Mestre ausente: ROOM_PAUSED, intenções recusadas, nenhum cartão se aprova sozinho; RESUMED só após o RESYNC', () => {
  const m = montarMesa();
  m.entrarTodos();
  m.iniciarCombate();
  const h = m.clientes.heroina;
  m.sair('mestre');
  assert.equal(h.ultimo('ROOM_PAUSED')?.motivo, 'mestre_desconectado');
  const r = m.intencao('heroina', { tipo: 'encerrar' });
  assert.equal(recibo(r).motivo, 'sala_pausada');
  // O Mestre volta: só o JOIN não retoma.
  m.entrar('mestre', { papel: 'mestre', pin: PIN });
  assert.equal(h.ultimo('ROOM_RESUMED'), null);
  m.enviar('mestre', { type: 'ROOM_RESYNC', lastSeq: m.clientes.mestre.ultimoSeq });
  assert.equal(h.ultimo('ROOM_RESUMED')?.motivo, 'mestre_desconectado');
  exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
});
