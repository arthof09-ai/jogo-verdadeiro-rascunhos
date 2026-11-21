// ORDEM-PROVAS-MAPA-CORR8: a sonda Node (procurarCanarios, a do espectador e dos testes do servidor) sobre a ESCUTA DO
// FIO da jogadora (bancada-servidor-canario.mjs). Tem duas partes:
//  1) o controlo positivo no fio: os cinco casos de teste K1–K5 têm de ser apanhados, cada um pelo conjunto exacto de
//     canários que leva (CORR8-CORRECOES, C1-2), e fora deles tem de haver 0 achados;
//  2) a cronologia do fio, e em especial o que chegou à jogadora em cada entrega que trouxe um evento `escala` (a lista
//     do «deve receber»).
//   node sonda-fio.mjs <escuta.jsonl> <relatorio.json>
import { readFileSync, writeFileSync } from 'node:fs';
import { procurarCanarios, FIXTURE, PIN } from '../../../rascunhos/servidor/testes/ajudantes.mjs';

const [entrada, saida] = process.argv.slice(2);
const fio = readFileSync(entrada, 'utf8').split('\n').filter(Boolean).map((l) => JSON.parse(l));
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
  else fora.push(a);
}
let falhas = 0;
const ok = (c, t) => { if (!c) falhas += 1; console.log((c ? '  ok    ' : '  FALHA ') + t); };
const casos = msgs.filter((m) => m.canarioTeste).map((m) => m.canarioTeste);
console.log(`== a sonda Node no fio da jogadora: ${msgs.length} mensagens, casos de teste ${JSON.stringify(casos)} ==`);
// CORR8-CORRECOES (C1-2): cada caso tem de ser apanhado pelo conjunto EXACTO de canários que a mensagem de teste leva
// (como a sonda da jogadora e o teste (a)), e não só por «algum». K1–K3 são os da sonda da jogadora
// (bancada_jogadora_canario.gd `_sonda`). K4 é a MASTER_VIEW do Mestre depois de o orc ser posto: leva o nome verdadeiro,
// a Vida e os PA do orc, mas não a CA (a vista do Mestre não a mostra). K5 é o texto do ROOM_REJECT alheio.
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
ok(fora.length === 0, `fora das mensagens de teste: ${fora.length} achados ${JSON.stringify(fora.slice(0, 5))}`);

const resumo = (e) => ({ n: e.n, lote: e.lote, onde: e.onde, type: e.msg.type, tipo: e.msg.tipo ?? null, seq: e.msg.seq ?? null,
  revision: e.msg.revision ?? null, canarioTeste: e.msg.canarioTeste ?? null, mapa: e.msg.mapa ?? null,
  dados: e.msg.type === 'ROOM_EVENT' ? e.msg.dados : undefined,
  vezId: e.msg.vezId ?? null, orcamentoM: e.msg.orcamentoM ?? null, nMover: Array.isArray(e.msg.mover) ? e.msg.mover.length : null,
  figuras: Array.isArray(e.msg.figuras) ? e.msg.figuras.map((f) => `${f.nomePublico}(${f.x},${f.y})`) : null });
const lotesEscala = [...new Set(fio.filter((e) => e.msg.type === 'ROOM_EVENT' && e.msg.tipo === 'escala' && !e.msg.canarioTeste).map((e) => e.lote))];
const escalas = lotesEscala.map((l) => fio.filter((e) => e.lote === l).map(resumo));
console.log(`== o que chegou à jogadora em cada entrega com um evento \`escala\` (${escalas.length}) ==`);
for (const lote of escalas) {
  console.log(`-- lote ${lote[0].lote}:`);
  for (const r of lote) console.log(`   ${r.n} ${r.type}${r.tipo ? ':' + r.tipo : ''} seq=${r.seq} rev=${r.revision}${r.canarioTeste ? ' [TESTE ' + r.canarioTeste + ']' : ''}${r.mapa ? ' mapa=' + JSON.stringify(r.mapa) : ''}${r.dados !== undefined ? ' dados=' + JSON.stringify(r.dados).slice(0, 80) : ''}${r.orcamentoM !== null ? ' orcamentoM=' + r.orcamentoM + ' mover=' + r.nMover : ''}${r.figuras ? ' figuras=' + r.figuras.join(' ') : ''}`);
}
writeFileSync(saida, JSON.stringify({ mensagens: msgs.length, casos, porCaso: Object.fromEntries(Object.entries(porCaso).map(([k, v]) => [k, [...v].sort()])),
  fora, escalas, cronologia: fio.map(resumo) }, null, 1));
console.log(falhas ? `${falhas} FALHAS` : 'TUDO PASSOU');
process.exit(falhas ? 1 : 0);
