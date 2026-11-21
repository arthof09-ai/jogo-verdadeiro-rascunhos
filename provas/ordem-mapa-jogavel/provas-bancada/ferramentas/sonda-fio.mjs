// ORDEM-F2: a SONDA DO FIO da corrida padrão da bancada. Vem da CORR8 (provas/ordem-provas-mapa-corr8/ferramentas/
// sonda-fio.mjs), sem os casos de teste: corre no fim do guião padrão sobre a escuta permanente do servidor
// (bancada-servidor.mjs) — o fio da heroína ANTES da Rede do cliente, onde se vê também o que a Rede deita fora
// (MASTER_*, rede.gd:488) ou ignora (um ROOM_REJECT alheio, rede.gd:566).
//
//   node sonda-fio.mjs <escuta.jsonl> <relatorio.json> [--canarios]
//
// Corrida padrão (sem --canarios):
//  (A) PRIVACIDADE: procurarCanarios (a sonda Node do espectador e dos testes do servidor) sobre TODAS as mensagens do
//      fio — snapshots, eventos, opções, recibos, o texto de qualquer ROOM_REJECT e ERRO, o ROOM_PAUSED: 0 achados;
//      nenhuma MASTER_* no fio; nenhuma mensagem de teste (`canarioTeste`) — a corrida padrão não as tem.
//  (B) LINHA 3 do contrato (§2f da CORR8): no lote da escala recusada do Mestre (MASTER_SUPERVISOR escala 3 m), o
//      Mestre recebe o ROOM_REJECT (e o evento `recusa`) e a heroína e o espectador recebem NADA.
//  (C) LINHA 4: no lote do pedido de escala da jogadora (um MASTER_SUPERVISOR vindo do lugar dela), ela recebe só o
//      ERRO `proibido` «Só o Mestre.», e mais ninguém recebe nada.
//  (D) o ROOM_PAUSED chegou ao fio dela (e foi varrido em A).
//  e a cronologia do fio, com o que chegou em cada entrega com um evento `escala`.
// Prova da escuta (--canarios, só fora da corrida padrão): em vez de «nenhuma mensagem de teste», cada caso K1–K5 tem
// de estar no fio UMA vez e de ser apanhado pelo conjunto EXACTO de canários que leva (CORR8-CORRECOES, C1-2); os
// achados fora deles continuam a ter de ser 0.
import { readFileSync, writeFileSync } from 'node:fs';
import { procurarCanarios, FIXTURE, PIN } from '../../../../rascunhos/servidor/testes/ajudantes.mjs';

const args = process.argv.slice(2);
const comCanarios = args.includes('--canarios');
const [entrada, saida] = args.filter((a) => !a.startsWith('--'));
const linhas = readFileSync(entrada, 'utf8').split('\n').filter(Boolean).map((l) => JSON.parse(l));
const fio = linhas.filter((e) => 'msg' in e);
const lotes = linhas.filter((e) => 'porPapel' in e);
const msgs = fio.map((e) => e.msg);
const ORC = FIXTURE.fichas.find((f) => f.id === 'orc-teste');
const canarios = {
  numeros: [ORC.vidaTotal, ORC.paTotal, ORC.ca],
  textos: ['ESCALA_', 'CANARIO-FANTASMA', 'CANARIO-DESGRACA', 'CANARIO-SENHA', 'Orc Verdadeiro', PIN],
  chaves: ['casaMAntes', 'grelhaAntes', 'casasQuePaga', 'soMestre'],
};
const achados = procurarCanarios(msgs, canarios);
const porCaso = {};
const fora = [];
for (const a of achados) {
  const k = msgs[a.i].canarioTeste;
  if (k) (porCaso[k] ??= new Set()).add(a.porque ? 'chave:' + a.chave : typeof a.valor === 'number' ? 'numero:' + a.valor : 'texto:' + a.valor);
  else fora.push({ ...a, n: fio[a.i].n, type: msgs[a.i].type });
}
let falhas = 0;
const ok = (c, t) => { if (!c) falhas += 1; console.log((c ? '  ok    ' : '  FALHA ') + t); };
const casos = msgs.filter((m) => m.canarioTeste).map((m) => m.canarioTeste);
const porType = {};
for (const m of msgs) { const t = m.type + (m.tipo ? ':' + m.tipo : ''); porType[t] = (porType[t] ?? 0) + 1; }
console.log(`== a sonda do fio da jogadora: ${msgs.length} mensagens em ${lotes.length} lotes${comCanarios ? ' — PROVA DA ESCUTA, com K1–K5' : ''} ==`);
console.log(`   por type: ${JSON.stringify(porType)}`);

// (A) privacidade
ok(fora.length === 0, `(A) fora: ${fora.length} achados${comCanarios ? ' (fora das mensagens de teste)' : ''} ${fora.length ? JSON.stringify(fora.slice(0, 5)) : ''}`);
const doMestre = msgs.filter((m) => !m.canarioTeste && String(m.type).startsWith('MASTER_'));
ok(doMestre.length === 0, `(A) mensagens MASTER_* no fio dela: ${doMestre.length}`);
const recusasEErros = msgs.filter((m) => !m.canarioTeste && ['ROOM_REJECT', 'ERRO', 'ROOM_PAUSED'].includes(m.type));
console.log(`   textos varridos em (A): ${JSON.stringify(recusasEErros.map((m) => ({ type: m.type, codigo: m.codigo, motivo: m.motivo, texto: m.texto })))}`);
if (comCanarios) {
  const ESPERADO = {
    K1: ['chave:soMestre', 'chave:casaMAntes', 'chave:grelhaAntes', 'chave:casasQuePaga'],
    K2: ['texto:ESCALA_', 'texto:Orc Verdadeiro', 'texto:CANARIO-FANTASMA', 'texto:' + PIN],
    K3: [ORC.vidaTotal, ORC.paTotal, ORC.ca].map((n) => 'numero:' + n),
    K4: ['texto:Orc Verdadeiro', 'numero:' + ORC.vidaTotal, 'numero:' + ORC.paTotal],
    K5: ['texto:ESCALA_', 'texto:CANARIO-FANTASMA'],
  };
  for (const k of ['K1', 'K2', 'K3', 'K4', 'K5']) {
    const apanhou = [...(porCaso[k] ?? [])].sort();
    const quer = [...ESPERADO[k]].sort();
    ok(casos.filter((c) => c === k).length === 1 && JSON.stringify(apanhou) === JSON.stringify(quer),
      `${k}: no fio (uma vez) e APANHADO pelo conjunto exacto — ${JSON.stringify(apanhou)} (esperado ${JSON.stringify(quer)})`);
  }
} else {
  ok(casos.length === 0, `(A) mensagens de teste no fio: ${casos.length} (a corrida padrão não as tem)`);
}

// (B) linha 3: a escala recusada do Mestre
const doLote = (l) => fio.filter((e) => e.lote === l.lote).map((e) => e.msg.type + (e.msg.tipo ? ':' + e.msg.tipo : ''));
const loteRecusa = lotes.filter((l) => l.entrada?.papel === 'mestre' && l.entrada?.type === 'MASTER_SUPERVISOR' && l.entrada?.op === 'escala' && l.entrada?.casaM === 3);
const lr = loteRecusa[0];
ok(loteRecusa.length === 1 && lr.porPapel.mestre?.types.includes('ROOM_REJECT') && lr.porPapel.mestre?.types.includes('ROOM_EVENT:recusa')
  && !lr.porPapel.jogadora && !lr.porPapel.espectador && doLote(lr).length === 0,
  `(B) linha 3 — a escala recusada do Mestre (3 m): ${loteRecusa.length} lote(s); Mestre ${JSON.stringify(lr?.porPapel.mestre?.types ?? null)}, jogadora ${lr?.porPapel.jogadora?.n ?? 0}, espectador ${lr?.porPapel.espectador?.n ?? 0}`);

// (C) linha 4: o pedido de escala da jogadora
const lotePedido = lotes.filter((l) => l.entrada?.papel === 'jogadora' && String(l.entrada?.type).startsWith('MASTER_'));
const lp = lotePedido[0];
const noLote = lp ? fio.filter((e) => e.lote === lp.lote).map((e) => e.msg) : [];
ok(lotePedido.length === 1 && noLote.length === 1 && noLote[0].type === 'ERRO' && noLote[0].codigo === 'proibido' && noLote[0].texto === 'Só o Mestre.'
  && Object.keys(lp.porPapel).join() === 'jogadora',
  `(C) linha 4 — o pedido de escala da jogadora (${lp?.entrada?.type ?? '—'} ${lp?.entrada?.op ?? ''} ${lp?.entrada?.casaM ?? ''}): ${lotePedido.length} lote(s); ela recebe ${JSON.stringify(noLote.map((m) => `${m.type} ${m.codigo} «${m.texto}»`))}; outros papéis ${JSON.stringify(Object.keys(lp?.porPapel ?? {}).filter((p) => p !== 'jogadora'))}`);

// (D) o ROOM_PAUSED
const pausas = fio.filter((e) => e.msg.type === 'ROOM_PAUSED');
ok(pausas.length >= 1, `(D) ROOM_PAUSED no fio dela: ${pausas.length} (${pausas.map((e) => `n=${e.n} ${e.onde} motivo=${e.msg.motivo}`).join('; ')}) — varrido em (A)`);

const resumo = (e) => ({ n: e.n, lote: e.lote, onde: e.onde, type: e.msg.type, tipo: e.msg.tipo ?? null, seq: e.msg.seq ?? null,
  revision: e.msg.revision ?? null, canarioTeste: e.msg.canarioTeste ?? null, mapa: e.msg.mapa ?? null,
  dados: e.msg.type === 'ROOM_EVENT' ? e.msg.dados : undefined,
  codigo: e.msg.codigo ?? null, motivo: e.msg.motivo ?? null, texto: e.msg.texto ?? null,
  vezId: e.msg.vezId ?? null, orcamentoM: e.msg.orcamentoM ?? null, nMover: Array.isArray(e.msg.mover) ? e.msg.mover.length : null,
  figuras: Array.isArray(e.msg.figuras) ? e.msg.figuras.map((f) => `${f.nomePublico}(${f.x},${f.y})`) : null });
const linha = (r) => `   ${r.n} ${r.type}${r.tipo ? ':' + r.tipo : ''} seq=${r.seq} rev=${r.revision}${r.canarioTeste ? ' [TESTE ' + r.canarioTeste + ']' : ''}${r.mapa ? ' mapa=' + JSON.stringify(r.mapa) : ''}${r.dados !== undefined ? ' dados=' + JSON.stringify(r.dados).slice(0, 80) : ''}${r.codigo ? ' codigo=' + r.codigo : ''}${r.motivo ? ' motivo=' + r.motivo : ''}${r.texto ? ' texto=«' + r.texto + '»' : ''}${r.orcamentoM !== null ? ' orcamentoM=' + r.orcamentoM + ' mover=' + r.nMover : ''}${r.figuras ? ' figuras=' + r.figuras.join(' ') : ''}`;
const lotesEscala = [...new Set(fio.filter((e) => e.msg.type === 'ROOM_EVENT' && e.msg.tipo === 'escala' && !e.msg.canarioTeste).map((e) => e.lote))];
const escalas = lotesEscala.map((l) => fio.filter((e) => e.lote === l).map(resumo));
console.log(`== o que chegou à jogadora em cada entrega com um evento \`escala\` (${escalas.length}) ==`);
for (const lote of escalas) {
  console.log(`-- lote ${lote[0].lote}:`);
  for (const r of lote) console.log(linha(r));
}
console.log('== a cronologia do fio (lote: quem mandou o quê → o que a heroína recebeu) ==');
for (const l of lotes) {
  const dela = fio.filter((e) => e.lote === l.lote);
  const outros = Object.entries(l.porPapel).filter(([p]) => p !== 'jogadora').map(([p, v]) => `${p} ${v.n}`).join(', ');
  console.log(`-- lote ${l.lote} ${l.onde} ← ${l.entrada ? `${l.entrada.papel} ${l.entrada.type ?? ''}${l.entrada.op ? ' ' + l.entrada.op : ''}${l.entrada.casaM !== undefined ? ' ' + l.entrada.casaM : ''}` : '?'}: heroína ${dela.length}${outros ? '; ' + outros : ''}`);
  for (const e of dela) console.log(linha(resumo(e)));
}
writeFileSync(saida, JSON.stringify({ modo: comCanarios ? 'prova da escuta (K1–K5)' : 'corrida padrão', mensagens: msgs.length, lotes: lotes.length, porType,
  casos, porCaso: Object.fromEntries(Object.entries(porCaso).map(([k, v]) => [k, [...v].sort()])), fora,
  linha3: lr ?? null, linha4: lp ? { lote: lp, recebeu: noLote } : null, pausas: pausas.map(resumo),
  escalas, cronologia: fio.map(resumo), lotesResumo: lotes }, null, 1));
console.log(falhas ? `${falhas} FALHAS` : 'TUDO PASSOU');
process.exit(falhas ? 1 : 0);
