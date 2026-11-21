// Prova da construção (Ordem CAIXA-PERSISTENTE) — corre a sala real (nucleo/sala.js) com o motor falso dos testes.
// A escolha da caixa do Mestre (ligada, modo) vive no servidor: sai e volta a entrar igual, sobrevive ao journal, não
// muda com o «voltar» nem com o «Recomeçar», vale com cartão aberto e em pausa, e a Party nunca recebe a `caixaMestre`.
// Actualizada na Ordem CAIXA-TESTES (21/11/2026, correcção B4): desde a CAIXA-HUD-JOGADORA a Party recebe a escolha
// no ROOM_SNAPSHOT dela (campo `caixa`: ligada, ordemPor, ordem dinâmica DA PARTY) — o passo 3 prova agora isso:
// exactamente 1 snapshot por membro da Party, e nada mais.
//   node provas/ordem-caixa/ferramentas/prova-servidor.mjs
// Com PROTOCOLO_DUMP=<ficheiro>, o tráfego vai para a conferência dos schemas (protocolo/ferramentas/conferir-schemas.py).
import assert from 'node:assert/strict';
import { createHash, randomUUID } from 'node:crypto';
const R = new URL('../../../rascunhos/servidor/', import.meta.url).href;
const { montarMesa, exigirAplicada, recibo, PIN, SENHAS, fichasDeTeste, rngDeterministico, relogio, INICIATIVA } = await import(R + 'testes/ajudantes.mjs');
const { criarSala } = await import(R + 'nucleo/sala.js');
const { criarMotorFalso } = await import(R + 'testes/motor-falso.mjs');

const log = (...a) => console.log(...a);
const m = montarMesa({ comAliada: true, comEspectador: true, modoPadrao: 'manual' });
m.entrarTodos();
m.iniciarCombate([['orc-teste', { x: 8, y: 8 }], ['lobo-teste', { x: 12, y: 12 }]]);
const vista = () => m.enviar('mestre', { type: 'MASTER_VIEW' }).find((x) => x.type === 'MASTER_VIEW');
// cmdId em UUID v4 (como o cliente real): a conferência dos schemas confere estas mensagens (ignora os ids de teste).
const caixa = (ligada, modo, extra = {}) => m.mestre('MASTER_SUPERVISOR', { cmdId: randomUUID(), op: 'caixa', caixa: { ligada, modo }, ...extra });
const estado = () => m.sala.depuracao.estado();
const party = ['heroina', 'aliada', 'espectador'];
const contagens = () => Object.fromEntries(party.map((k) => [k, m.clientes[k].msgs.length]));
const revisoes = () => Object.fromEntries(Object.values(estado().lugares).map((s) => [s.papel + ':' + s.seatId.slice(0, 6), s.revision]));
const reentrar = () => {
  m.sair('mestre');
  m.entrar('mestre', { papel: 'mestre', pin: PIN });
  return m.clientes.mestre.ultimo('MASTER_VIEW');
};

// 1) A escolha por omissão é a de sempre (Ordem HUD): ligada, modo dinâmico.
const v0 = vista();
log('1) escolha por omissão na MASTER_VIEW:', JSON.stringify(v0.caixaMestre));
assert.deepEqual(v0.caixaMestre, { ligada: true, modo: 'dinamico' });

// 2) Uma volta da batalha (a ordem dinâmica forma-se, como na INICIATIVA).
const H = m.clientes.heroina.figuraId, A = m.clientes.aliada.figuraId;
const orc = m.clientes.mestre.idPorNome('Orc'), lobo = m.clientes.mestre.idPorNome('Lobo');
const nome = { [H]: 'Heroína', [A]: 'Aliada', [orc]: 'Orc', [lobo]: 'Lobo' };
const act = (figuraId, acao) => exigirAplicada(m.mestre('MASTER_ACT', { intentId: m.novoId('act'), figuraId, acao }), 'ACT');
function jogar(id, destino) {
  if (estado().vez?.figuraId !== id) throw new Error('não é a vez de ' + nome[id]);
  if (id === H || id === A) {
    const k = id === H ? 'heroina' : 'aliada';
    exigirAplicada(m.intencao(k, { tipo: 'mover', destino }), 'mover');
    exigirAplicada(m.intencao(k, { tipo: 'encerrar' }), 'encerrar');
  } else { act(id, { tipo: 'mover', destino }); act(id, { tipo: 'encerrar' }); }
}
jogar(H, { x: 3, y: 2 }); jogar(A, { x: 3, y: 4 });
log('2) a meio da batalha: ordem dinâmica', vista().ordemDinamica.ordem.map((id) => nome[id]).join(' → '), '| vez de', nome[estado().vez.figuraId]);

// 3) O Mestre liga o «Modo iniciativa»: o servidor guarda; sem evento, sem revisão nova. A Party recebe EXACTAMENTE um
//    ROOM_SNAPSHOT novo (desde a CAIXA-HUD-JOGADORA, com a `caixa` dela) e nada mais — nunca a `caixaMestre`.
const seqAntes = vista().journalSeq, revAntes = revisoes(), partyAntes = contagens(), pontosAntes = vista().pontos.length;
const r3 = caixa(true, 'iniciativa');
exigirAplicada(r3, 'caixa iniciativa');
const v3 = vista();
log('3) «Modo iniciativa» → recibo', recibo(r3).estado, '| estado.caixaMestre', JSON.stringify(estado().caixaMestre));
assert.deepEqual(estado().caixaMestre, { ligada: true, modo: 'iniciativa' });
assert.deepEqual(v3.caixaMestre, { ligada: true, modo: 'iniciativa' });
assert.equal(v3.journalSeq, seqAntes, 'a escolha da caixa não é um evento da batalha');
assert.equal(v3.pontos.length, pontosAntes, 'nenhum ponto novo do «voltar»');
assert.deepEqual(revisoes(), revAntes, 'nenhuma revisão mudou');
for (const k of party) {
  const novas = m.clientes[k].msgs.slice(partyAntes[k]);
  assert.deepEqual(novas.map((x) => x.type), ['ROOM_SNAPSHOT'], k + ': a Party recebe exactamente o snapshot, e nada mais');
  assert.deepEqual(Object.keys(novas[0].caixa).sort(), ['ligada', 'ordemDinamica', 'ordemPor'], k + ': a caixa da Party');
  assert.equal(novas[0].caixa.ordemPor, 'iniciativa', k);
  assert.equal(novas[0].caixaMestre, undefined, k + ': nunca a caixaMestre');
}
log('   journalSeq', seqAntes, '→', v3.journalSeq, '| revisões iguais | Party: exactamente 1 mensagem nova cada (ROOM_SNAPSHOT, caixa.ordemPor',
  m.clientes.heroina.ultimo('ROOM_SNAPSHOT').caixa.ordemPor + ') | pontos do «voltar»:', pontosAntes, '→', v3.pontos.length);

// 4) SAIR E VOLTAR A ENTRAR a meio da batalha: a caixa volta com a escolha (e com a ordem dinâmica, da INICIATIVA).
const odAntes = v3.ordemDinamica;
const v4 = reentrar();
log('4) Mestre sai e volta a entrar a meio da batalha: caixaMestre', JSON.stringify(v4.caixaMestre), '| fase', v4.fase,
  '| ordem', v4.ordemDinamica.ordem.map((id) => nome[id]).join(' → '));
assert.deepEqual(v4.caixaMestre, { ligada: true, modo: 'iniciativa' });
assert.deepEqual(v4.ordemDinamica, odAntes);

// 5) Desligar a caixa (aba Sala) e voltar a entrar: desligada.
exigirAplicada(caixa(false, 'iniciativa'), 'caixa desligada');
const v5 = reentrar();
log('5) caixa desligada, sair e voltar a entrar:', JSON.stringify(v5.caixaMestre));
assert.deepEqual(v5.caixaMestre, { ligada: false, modo: 'iniciativa' });

// 6) Em pausa vale (a caixa aparece em combate e em pausa); os comandos de jogo continuam recusados.
if (estado().fase !== 'pausa') exigirAplicada(m.mestre('MASTER_PAUSE'), 'PAUSE');
exigirAplicada(caixa(true, 'dinamico'), 'caixa em pausa');
const amb = recibo(m.mestre('MASTER_AMBIENTE', { hora: '12:00' }));
log('6) em pausa: caixa → APLICADA', JSON.stringify(estado().caixaMestre), '| MASTER_AMBIENTE →', amb.motivo);
assert.equal(amb.motivo, 'sala_pausada');
exigirAplicada(m.mestre('MASTER_RESUME'), 'RESUME');

// 7) O journal: a sala reaberta do registo gravado traz a escolha.
exigirAplicada(caixa(true, 'iniciativa'), 'caixa antes do export');
const exportado = m.sala.exportar();
const CONFIG = { roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'manual', depurar: true,
  lugares: [
    { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
    { papel: 'jogadora', nome: 'Aliada Teste', senha: SENHAS.aliada, fichaId: 'aliada-teste', casa: { x: 2, y: 4 } },
    { papel: 'espectador', nome: 'Visita', senha: SENHAS.espectador },
    { papel: 'mestre', nome: 'Mestre', pin: PIN }] };
function vistaDaSalaRestaurada(texto) {
  const sala2 = criarSala({ motores: criarMotorFalso(), fichas: fichasDeTeste({ comAliada: true }), rng: rngDeterministico(), agora: relogio(), config: CONFIG, restaurarDe: texto });
  const r = sala2.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'mestre', pin: PIN }, { ip: '10.9.9.9' });
  sala2.conexaoAberta(r.seatId);
  return [...r.mensagens, ...sala2.receber(r.seatId, { v: 2, type: 'MASTER_VIEW' }).map((s) => s.msg)].find((x) => x.type === 'MASTER_VIEW');
}
const v7 = vistaDaSalaRestaurada(exportado);
log('7) sala reaberta do journal:', JSON.stringify(v7.caixaMestre));
assert.deepEqual(v7.caixaMestre, { ligada: true, modo: 'iniciativa' });
// Um journal de ANTES desta ordem (sem `caixaMestre` no estado) abre e dá a escolha por omissão.
const [corpo] = exportado.split('\n');
const semCampo = JSON.parse(corpo);
delete semCampo.estado.caixaMestre;
const textoAntigo = JSON.stringify(semCampo);
const reassinado = textoAntigo + '\n' + 'sha256:' + createHash('sha256').update(textoAntigo).digest('hex') + '\n';
const v7b = vistaDaSalaRestaurada(reassinado);
log('   journal de antes desta ordem (sem o campo): abre, caixaMestre', JSON.stringify(v7b.caixaMestre));
assert.deepEqual(v7b.caixaMestre, { ligada: true, modo: 'dinamico' });
// Um journal com o campo estragado não abre (conferir-estado.js).
for (const mau of [{ ligada: 'sim', modo: 'dinamico' }, { ligada: true, modo: 'turnos' }, { ligada: true, modo: 'dinamico', vida: 10 }]) {
  const c2 = JSON.parse(corpo); c2.estado.caixaMestre = mau; const t2 = JSON.stringify(c2);
  assert.throws(() => vistaDaSalaRestaurada(t2 + '\nsha256:' + createHash('sha256').update(t2).digest('hex') + '\n'));
}
log('   journal com caixaMestre estragado (ligada não booleana, modo desconhecido, campo a mais): não abre');

// 8) O «voltar» não mexe na escolha (preferência do Mestre, não mundo); o «Recomeçar» também não.
const alvo = vista().pontos.find((p) => p.vezId === A && p.tipos.includes('movimento'));
exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'voltar', ateSeq: alvo.journalSeq }), 'voltar');
const v8 = vista();
log('8) «voltar» ao ponto em que a Aliada andou: ordem', v8.ordemDinamica.ordem.map((id) => nome[id]).join(' → '), '| caixaMestre', JSON.stringify(v8.caixaMestre));
assert.deepEqual(v8.caixaMestre, { ligada: true, modo: 'iniciativa' });
exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'recomecar' }), 'recomecar');
log('   «Recomeçar»: caixaMestre', JSON.stringify(vista().caixaMestre), '| ordem dinâmica', JSON.stringify(vista().ordemDinamica.ordem));
assert.deepEqual(vista().caixaMestre, { ligada: true, modo: 'iniciativa' });

// 9) Com um cartão aberto vale (E-C6 só trava comandos de jogo).
const mc = montarMesa();
mc.entrarTodos();
mc.iniciarCombate([['lobo-teste', { x: 10, y: 2 }]]);
exigirAplicada(mc.mestre('MASTER_MODE', { figuraId: mc.clientes.heroina.idPorNome('Lobo'), modo: 'semi' }));
exigirAplicada(mc.intencao('heroina', { tipo: 'encerrar' }));
assert.ok(mc.sala.depuracao.estado().cartoes.some((c) => c.estado === 'aberto'), 'há um cartão aberto');
const rc = mc.mestre('MASTER_SUPERVISOR', { cmdId: randomUUID(), op: 'caixa', caixa: { ligada: false, modo: 'dinamico' } });
const bloq = recibo(mc.mestre('MASTER_AMBIENTE', { hora: '12:00' }));
log('9) com um cartão aberto: caixa →', recibo(rc).estado, '| MASTER_AMBIENTE →', bloq.motivo);
assert.equal(recibo(rc).estado, 'APLICADA');
assert.equal(bloq.motivo, 'cartao_aberto');

// 10) Mal formada = recusa de formato (nada se grava).
const antes10 = JSON.stringify(estado().caixaMestre);
const maus = [
  { op: 'caixa', caixa: { ligada: true } },
  { op: 'caixa', caixa: { ligada: 1, modo: 'dinamico' } },
  { op: 'caixa', caixa: { ligada: true, modo: 'turnos' } },
  { op: 'caixa', caixa: { ligada: true, modo: 'dinamico', vida: 3 } },
  { op: 'caixa' },
  { op: 'caixa', caixa: { ligada: true, modo: 'dinamico' }, casaM: 2 },
  { op: 'escala', casaM: 2, caixa: { ligada: true, modo: 'dinamico' } },
];
const motivos = maus.map((x) => recibo(m.mestre('MASTER_SUPERVISOR', x))?.motivo);
log('10) mensagens mal formadas →', motivos.join(', '));
assert.ok(motivos.every((x) => x === 'formato'));
assert.equal(JSON.stringify(estado().caixaMestre), antes10);

// 11) Nenhum valor de vida/alma: só `ligada` e `modo`; a Party nunca recebe `caixaMestre`.
const chaves = new Set([...Object.keys(estado().caixaMestre), ...Object.keys(vista().caixaMestre)]);
log('11) chaves de caixaMestre (estado e vista):', [...chaves].sort().join(', '));
assert.deepEqual([...chaves].sort(), ['ligada', 'modo']);
for (const k of party) assert.ok(!JSON.stringify(m.clientes[k].msgs).includes('caixaMestre'), 'a Party recebeu caixaMestre: ' + k);
log('   a Party (heroína, aliada, espectador) nunca recebeu caixaMestre: ok');
log('PROVA OK');
