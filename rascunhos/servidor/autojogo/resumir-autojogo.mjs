// ORDEM AUTOJOGO — FERRAMENTA DE MEDIÇÃO: resume N registos do autojogo numa tabela só.
//
//   node servidor/autojogo/resumir-autojogo.mjs <registo.jsonl>... [--md=<saida.md>] [--json=<saida.json>]
//
// Cada registo é o JSON Lines de uma partida (res://autojogo/autojogo.gd). Antes de somar, CONFERE cada registo contra
// si próprio (o resumo tem de bater com as linhas):
//   - todas as linhas trazem a mesma semente;
//   - há exactamente um `inicio` (a 1.ª linha) e um `resumo` (a última);
//   - o número de turnos do resumo = o número de linhas `vez`;
//   - o dano causado/sofrido de cada figura no resumo = a soma dos eventos `dano` (autorId/alvoId) do registo;
//   - o vencedor bate com o evento `fim` (vitoria → heroínas, morte → criaturas).
// Um registo que não bate entra na tabela marcado e o processo sai com código 1 (nunca um número calado).
// Os desequilíbrios REGISTAM-SE aqui; corrigir números é missão separada.
import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

export function lerRegisto(texto) {
  return texto.split('\n').filter((l) => l.trim() !== '').map((l, i) => {
    try { return JSON.parse(l); } catch { throw new Error(`linha ${i + 1} não é JSON`); }
  });
}

/** Confere um registo. Devolve {semente, resumo, problemas:[texto]}. */
export function conferirRegisto(linhas) {
  const problemas = [];
  if (!linhas.length) return { semente: null, resumo: null, problemas: ['registo vazio'] };
  const semente = linhas[0].semente;
  linhas.forEach((l, i) => { if (l.semente !== semente) problemas.push(`linha ${i + 1}: semente ${l.semente} ≠ ${semente}`); });
  const inicios = linhas.filter((l) => l.tipo === 'inicio');
  const resumos = linhas.filter((l) => l.tipo === 'resumo');
  const falhas = linhas.filter((l) => l.tipo === 'falha');
  if (falhas.length) problemas.push('a partida falhou: ' + falhas.map((f) => f.texto).join(' | '));
  if (inicios.length !== 1 || linhas[0].tipo !== 'inicio') problemas.push('falta o `inicio` na 1.ª linha (ou há mais de um)');
  if (resumos.length !== 1 || linhas.at(-1).tipo !== 'resumo') {
    problemas.push('falta o `resumo` na última linha (ou há mais de um)');
    return { semente, resumo: null, problemas };
  }
  const resumo = resumos[0];
  const vezes = linhas.filter((l) => l.tipo === 'vez').length;
  if (resumo.turnos !== vezes) problemas.push(`turnos do resumo ${resumo.turnos} ≠ ${vezes} linhas «vez»`);
  const causado = {};
  const sofrido = {};
  for (const l of linhas) {
    if (l.tipo !== 'evento' || l.evento !== 'dano' || !l.dados) continue;
    const v = Number(l.dados.valor ?? 0);
    if (l.dados.autorId) causado[l.dados.autorId] = (causado[l.dados.autorId] ?? 0) + v;
    if (l.dados.alvoId) sofrido[l.dados.alvoId] = (sofrido[l.dados.alvoId] ?? 0) + v;
  }
  for (const f of resumo.figuras ?? []) {
    if ((causado[f.figuraId] ?? 0) !== f.danoCausado) problemas.push(`${f.figura}: dano causado ${f.danoCausado} no resumo ≠ ${causado[f.figuraId] ?? 0} nos eventos`);
    if ((sofrido[f.figuraId] ?? 0) !== f.danoSofrido) problemas.push(`${f.figura}: dano sofrido ${f.danoSofrido} no resumo ≠ ${sofrido[f.figuraId] ?? 0} nos eventos`);
  }
  const fim = linhas.filter((l) => l.tipo === 'evento' && l.evento === 'fim').at(-1);
  const esperado = { vitoria: 'heroinas', morte: 'criaturas' }[fim?.dados?.desfecho] ?? 'nenhum';
  if (resumo.vencedor !== esperado) problemas.push(`vencedor ${resumo.vencedor} ≠ ${esperado} (evento fim: ${fim?.dados?.desfecho ?? '—'})`);
  return { semente, resumo, problemas };
}

const media = (xs) => (xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : 0);
const fmt = (x) => (Number.isInteger(x) ? String(x) : x.toFixed(1));

/** Soma as partidas conferidas. Devolve o objecto do resumo (o mesmo que vai para o --json). */
export function resumir(partidas) {
  const boas = partidas.filter((p) => p.resumo && !p.problemas.length);
  const vitorias = { heroinas: 0, criaturas: 0, nenhum: 0 };
  const porFicha = new Map();
  for (const p of boas) {
    vitorias[p.resumo.vencedor] = (vitorias[p.resumo.vencedor] ?? 0) + 1;
    for (const f of p.resumo.figuras) {
      const k = f.fichaId;
      if (!porFicha.has(k)) porFicha.set(k, { fichaId: k, figura: f.figura, lado: f.lado, vidaTotal: f.vidaTotal, perdas: [], causado: [], sofrido: [], ataques: [], caidas: 0, mortes: 0 });
      const a = porFicha.get(k);
      a.perdas.push(f.vidaTotal - f.vidaRestante);
      a.causado.push(f.danoCausado);
      a.sofrido.push(f.danoSofrido);
      a.ataques.push(f.ataques);
      if (f.vidaRestante <= 0) a.caidas += 1; // a vida chegou a 0 (fora de combate), viva ou morta
      if (!f.viva) a.mortes += 1;
    }
  }
  const figuras = [...porFicha.values()].sort((a, b) => (a.lado === b.lado ? a.fichaId.localeCompare(b.fichaId) : a.lado === 'jogadora' ? -1 : 1)).map((a) => ({
    fichaId: a.fichaId, figura: a.figura, lado: a.lado, vidaTotal: a.vidaTotal,
    vidaPerdidaMedia: media(a.perdas), danoCausadoMedio: media(a.causado), danoSofridoMedio: media(a.sofrido),
    ataquesMedios: media(a.ataques), caidas: a.caidas, mortes: a.mortes,
  }));
  return {
    formato: 'autojogo-resumo/1',
    partidas: partidas.length,
    conferidas: boas.length,
    sementes: partidas.map((p) => p.semente),
    vitorias,
    turnosMedios: media(boas.map((p) => p.resumo.turnos)),
    rodadasMedias: media(boas.map((p) => p.resumo.rodadas)),
    figuras,
    porPartida: partidas.map((p) => ({ semente: p.semente, ficheiro: p.ficheiro, vencedor: p.resumo?.vencedor ?? null, turnos: p.resumo?.turnos ?? null, rodadas: p.resumo?.rodadas ?? null, problemas: p.problemas })),
  };
}

export function tabelaMd(r) {
  const L = [];
  L.push(`# Autojogo — ${r.partidas} partidas (sementes ${r.sementes.join(', ')})`);
  L.push('');
  L.push(`Conferidas (resumo = registo): ${r.conferidas}/${r.partidas} · vitórias: heroínas ${r.vitorias.heroinas} · criaturas ${r.vitorias.criaturas} · sem vencedor ${r.vitorias.nenhum} · turnos médios ${fmt(r.turnosMedios)} · rodadas médias ${fmt(r.rodadasMedias)}`);
  L.push('');
  L.push('| Figura | Lado | Vida | Vida perdida (média) | Dano causado (média) | Dano sofrido (média) | Ataques (média) | Caiu (vida 0) | Morreu |');
  L.push('| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |');
  for (const f of r.figuras) {
    L.push(`| ${f.figura} | ${f.lado} | ${f.vidaTotal} | ${fmt(f.vidaPerdidaMedia)} | ${fmt(f.danoCausadoMedio)} | ${fmt(f.danoSofridoMedio)} | ${fmt(f.ataquesMedios)} | ${f.caidas}/${r.conferidas} | ${f.mortes}/${r.conferidas} |`);
  }
  L.push('');
  L.push('Vida perdida = vida total − vida restante (pára no 0). Dano sofrido = a soma dos golpes recebidos, como o servidor a conta (inclui o excesso além da vida). «Caiu» = acabou com vida 0; «Morreu» = a morte foi adjudicada (uma heroína caída pode continuar viva, em teste de morte).');
  L.push('');
  L.push('| Semente | Vencedor | Turnos | Rodadas | Conferência |');
  L.push('| ---: | --- | ---: | ---: | --- |');
  for (const p of r.porPartida) L.push(`| ${p.semente} | ${p.vencedor ?? '—'} | ${p.turnos ?? '—'} | ${p.rodadas ?? '—'} | ${p.problemas.length ? 'NÃO BATE: ' + p.problemas.join('; ') : 'bate'} |`);
  return L.join('\n') + '\n';
}

function principal(argv) {
  const ficheiros = argv.filter((a) => !a.startsWith('--'));
  const opc = Object.fromEntries(argv.filter((a) => a.startsWith('--')).map((a) => { const [k, ...v] = a.slice(2).split('='); return [k, v.join('=')]; }));
  if (!ficheiros.length) { console.error('uso: resumir-autojogo.mjs <registo.jsonl>... [--md=f] [--json=f]'); return 2; }
  const partidas = ficheiros.map((f) => {
    try {
      return { ficheiro: path.basename(f), ...conferirRegisto(lerRegisto(readFileSync(f, 'utf8'))) };
    } catch (e) {
      return { ficheiro: path.basename(f), semente: null, resumo: null, problemas: [String(e?.message ?? e)] };
    }
  });
  const r = resumir(partidas);
  const md = tabelaMd(r);
  process.stdout.write(md);
  if (opc.md) writeFileSync(opc.md, md);
  if (opc.json) writeFileSync(opc.json, JSON.stringify(r, null, 2) + '\n');
  return r.conferidas === r.partidas ? 0 : 1;
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  process.exitCode = principal(process.argv.slice(2));
}
