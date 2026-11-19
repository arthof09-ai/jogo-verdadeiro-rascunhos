// Prova da construção (Ordem INICIATIVA NO SERVIDOR) — corre a sala real com o motor falso dos testes.
import assert from 'node:assert/strict';
const R = '/home/user/jogo-verdadeiro-rascunhos/rascunhos/servidor/';
const { montarMesa, exigirAplicada, recibo, PIN, SENHAS, fichasDeTeste, rngDeterministico, relogio, INICIATIVA } = await import(R + 'testes/ajudantes.mjs');
const { criarSala } = await import(R + 'nucleo/sala.js');
const { criarMotorFalso } = await import(R + 'testes/motor-falso.mjs');

const log = (...a) => console.log(...a);
const m = montarMesa({ comAliada: true, comEspectador: true, modoPadrao: 'manual' });
m.entrarTodos();
m.iniciarCombate([['orc-teste', { x: 8, y: 8 }], ['lobo-teste', { x: 12, y: 12 }]]);
const vista = () => m.enviar('mestre', { type: 'MASTER_VIEW' }).find((x) => x.type === 'MASTER_VIEW');

// 1) A ordem inicial vem do servidor e é igual para todos os que entram.
const snapIni = (c) => c.ultimo('ROOM_SNAPSHOT')?.iniciativa;
// a Party entra outra vez depois do START (snapshot novo)
for (const [k, j] of [['heroina', { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina }],
  ['aliada', { papel: 'jogadora', nome: 'Aliada Teste', senha: SENHAS.aliada }],
  ['espectador', { papel: 'espectador', nome: 'Visita', senha: SENHAS.espectador }]]) { m.sair(k); m.entrar(k, j); }
const v0 = vista();
const ini = { mestre: v0.iniciativa, heroina: snapIni(m.clientes.heroina), aliada: snapIni(m.clientes.aliada), espectador: snapIni(m.clientes.espectador) };
log('1) iniciativa (ordem inicial do servidor) por cliente:', JSON.stringify(ini));
for (const k of Object.keys(ini)) assert.deepEqual(ini[k], ini.mestre, 'ordem inicial diferente em ' + k);
assert.equal(ini.mestre.length, 4);
log('   ordemDinamica no início:', JSON.stringify(v0.ordemDinamica));
assert.deepEqual(v0.ordemDinamica, { ordem: [], fechada: false, ultimo: null });

// 2) Acções: heroína anda, aliada anda; o Mestre faz o orc e o lobo agir (MASTER_ACT mover); a heroína volta (fecha).
const H = m.clientes.heroina.figuraId, A = m.clientes.aliada.figuraId;
const orc = m.clientes.mestre.idPorNome('Orc'), lobo = m.clientes.mestre.idPorNome('Lobo');
const nome = { [H]: 'Heroína', [A]: 'Aliada', [orc]: 'Orc', [lobo]: 'Lobo' };
const nomes = (od) => od.ordem.map((id) => nome[id]).join(' → ') + ` | fechada=${od.fechada} | última=${nome[od.ultimo] ?? null}`;
const act = (figuraId, acao) => exigirAplicada(m.mestre('MASTER_ACT', { intentId: m.novoId('act'), figuraId, acao }), 'ACT');
const vezDe = () => m.sala.depuracao.estado().vez?.figuraId;
function jogar(id, destino) {
  if (vezDe() !== id) throw new Error('não é a vez de ' + nome[id] + ' (é de ' + nome[vezDe()] + ')');
  if (id === H || id === A) {
    const k = id === H ? 'heroina' : 'aliada';
    exigirAplicada(m.intencao(k, { tipo: 'mover', destino }), 'mover');
    exigirAplicada(m.intencao(k, { tipo: 'encerrar' }), 'encerrar');
  } else { act(id, { tipo: 'mover', destino }); act(id, { tipo: 'encerrar' }); }
}
const sequencia = m.sala.depuracao.estado().ordem;
log('   ordem de iniciativa no estado:', sequencia.map((id) => nome[id]).join(' → '));
jogar(H, { x: 3, y: 2 }); jogar(A, { x: 3, y: 4 }); jogar(lobo, { x: 11, y: 12 }); jogar(orc, { x: 8, y: 7 });
let v1 = vista(); log('2) depois de uma volta:', nomes(v1.ordemDinamica));
jogar(H, { x: 4, y: 2 });
v1 = vista(); log('   a heroína volta a agir (fecha):', nomes(v1.ordemDinamica));
assert.equal(v1.ordemDinamica.fechada, true);

// 3) Entrada a meio da batalha: o Mestre põe um bandido (entra na ordem quando agir); 4) sair e voltar a entrar.
exigirAplicada(m.mestre('MASTER_PLACE', { fichaId: 'bandido-teste', casa: { x: 15, y: 15 } }), 'PLACE bandido');
const antesDeSair = vista().ordemDinamica;
m.sair('mestre');
m.entrar('mestre', { papel: 'mestre', pin: PIN });
const reentrada = m.clientes.mestre.ultimo('MASTER_VIEW') ?? vista();
log('3) Mestre sai e volta a entrar a meio da batalha:', nomes(reentrada.ordemDinamica));
assert.deepEqual(reentrada.ordemDinamica, antesDeSair, 'a ordem dinâmica não voltou igual');

// 5) O journal: a sala reabre do registo gravado e a ordem dinâmica volta igual.
const exportado = m.sala.exportar();
const CONFIG = { roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'manual', depurar: true,
  lugares: [
    { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
    { papel: 'jogadora', nome: 'Aliada Teste', senha: SENHAS.aliada, fichaId: 'aliada-teste', casa: { x: 2, y: 4 } },
    { papel: 'espectador', nome: 'Visita', senha: SENHAS.espectador },
    { papel: 'mestre', nome: 'Mestre', pin: PIN }] };
const sala2 = criarSala({ motores: criarMotorFalso(), fichas: fichasDeTeste({ comAliada: true }), rng: rngDeterministico(), agora: relogio(), config: CONFIG, restaurarDe: exportado });
const r = sala2.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', papel: 'mestre', pin: PIN }, { ip: '10.9.9.9' });
sala2.conexaoAberta(r.seatId);
const v2 = [...r.mensagens, ...sala2.receber(r.seatId, { v: 2, type: 'MASTER_VIEW' }).map((s) => s.msg)].find((x) => x.type === 'MASTER_VIEW');
log('4) sala reaberta do journal:', nomes(v2.ordemDinamica));
assert.deepEqual(v2.ordemDinamica, antesDeSair);

// 6) Atraso: o Mestre dita outra sequência (o orc age antes da vez do lobo) — mas a vez é do servidor; prova directa no módulo.
const OD = await import(R + 'nucleo/ordem-dinamica.js');
const od = OD.ordemDinamicaVazia();
for (const [t, d] of [['ataque', { atacanteId: 'j1', ataqueDeOportunidade: false }], ['ataque', { atacanteId: 'j2' }], ['cura', { curadorId: 'j3' }],
  ['ataque', { atacanteId: 'm' }], ['ataque', { atacanteId: 'j1' }], ['ataque', { atacanteId: 'j3' }]]) OD.registarEvento(od, { tipo: t, dados: d });
log('5) o exemplo do Mestre + atraso da j2:', od.ordem.join(' → '), '| fechada', od.fechada);
assert.deepEqual(od.ordem, ['j1', 'j3', 'j2', 'm']);

// 7) «voltar»: a ordem dinâmica volta à do ponto.
if (m.sala.depuracao.estado().fase === 'pausa') exigirAplicada(m.mestre('MASTER_RESUME'), 'RESUME');
const pontos = vista().pontos;
const alvo = pontos.find((p) => p.vezId === A && p.tipos.includes('movimento'));
exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'voltar', ateSeq: alvo.journalSeq }));
const v3 = vista(); log('6) «voltar» ao ponto em que a aliada andou:', nomes(v3.ordemDinamica));
assert.deepEqual(v3.ordemDinamica.ordem, [H, A]);

// 8) Nenhum campo de vida/alma no que é novo; a Party nunca recebe ordemDinamica.
const chaves = new Set(); const juntar = (o) => { if (o && typeof o === 'object') for (const [k, x] of Object.entries(o)) { chaves.add(k); juntar(x); } };
juntar(v3.ordemDinamica); juntar(m.sala.depuracao.estado().ordemDinamica);
log('7) chaves de ordemDinamica (vista e estado):', [...chaves].sort().join(', '));
assert.ok([...chaves].every((k) => ['ordem', 'fechada', 'ultimo', 'vezes', '0', '1', '2', '3', '4'].includes(k)));
for (const k of ['heroina', 'aliada', 'espectador']) assert.ok(!JSON.stringify(m.clientes[k].msgs).includes('ordemDinamica'), 'a Party recebeu ordemDinamica: ' + k);
log('   a Party (heroína, aliada, espectador) nunca recebeu ordemDinamica: ok');
log('PROVA OK');
