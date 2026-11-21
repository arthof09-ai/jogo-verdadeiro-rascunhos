// ORDEM PROVAS-MAPA-CORR9: põe lado a lado as corridas das provas do mapa e diz se se repetem.
//   node comparar-corridas.mjs [--bits] [--md=<saida.md>] <rotulo>=<pasta> <rotulo>=<pasta> [...]
// Cada pasta tem os JSON que as provas escrevem: terreno-servidor-arena.json (original), terreno-servidor-arena-
// adaptada.json (cópia) e bancada-jogadora.json + bancada-mestre.json (a batalha). A primeira pasta é a referência.
// Compara-se o RESUMO de cada corrida (os números que o ESTADO-FINAL da ORDEM-PROVAS-MAPA regista) e não o JSON
// bruto, porque este traz o que muda por natureza de corrida para corrida: os ids das figuras (aleatórios por sala)
// e os tempos das verificações «(0.2 s)».
// Dos registos (.log) lê-se ainda a sequência da floresta: o campo `casas_bloqueadas` de cada linha «[floresta]
// pronta …» (uma por carga: 18 na ferramenta original, 18 na adaptada, 3 na bancada), comparada carga a carga.
//   «números»: contagens, desvios, recusas, recibos, caminhos, alcances, passos, reservas e a privacidade — o portão.
//   «bits»:    impressões SHA-256 das alturas desenhadas (figuras, marcos) e dos nós das figuras na bancada — a
//              repetição bit a bit; só é portão com --bits.
// Sai com 0 se todas as corridas dão o mesmo resumo que a referência; 1 se não; 2 se falta um ficheiro.
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { join } from 'node:path';

const args = process.argv.slice(2);
const portaoBits = args.includes('--bits');
const md = (args.find((a) => a.startsWith('--md=')) ?? '').slice(5) || null;
const corridas = args.filter((a) => !a.startsWith('--')).map((a) => {
  const i = a.indexOf('=');
  return { rotulo: a.slice(0, i), pasta: a.slice(i + 1) };
});
if (corridas.length < 2) {
  console.error('uso: comparar-corridas.mjs [--bits] [--md=f] r1=pasta1 r2=pasta2 ...');
  process.exit(2);
}

const lerTexto = (p, f) => {
  const c = join(p, f);
  if (!existsSync(c)) { console.error(`falta ${c}`); process.exit(2); }
  return readFileSync(c, 'utf8');
};
const ler = (p, f) => JSON.parse(lerTexto(p, f));
// CORR9-CORRECOES B1: a sequência da floresta. Cada carga da floresta escreve «[floresta] pronta em N ms | {json}»;
// tira-se `casas_bloqueadas` de cada uma, pela ordem do registo. Uma linha «[floresta]» sem JSON legível ou sem o
// campo conta como «(ilegível)», para que não passe calada.
function floresta(texto) {
  return texto.split(/\r?\n/).filter((l) => l.startsWith('[floresta] pronta')).map((l) => {
    const i = l.indexOf('{');
    try { const v = JSON.parse(l.slice(i)).casas_bloqueadas; return Number.isFinite(v) ? v : '(ilegível)'; }
    catch { return '(ilegível)'; }
  });
}
const sha = (v) => createHash('sha256').update(JSON.stringify(v)).digest('hex').slice(0, 16);
const g3 = (g) => `${g.largura}×${g.altura} @ ${g.casaM}`;
const cmpStr = (a, b) => (JSON.stringify(a) < JSON.stringify(b) ? -1 : 1);

function terreno(j) {
  return j.grelhas.map((g, i) => {
    const p = g.pedida ?? g.grelha;
    const ff = g.faixaFronteira;
    return {
      n: {
        grelha: `${g3(p)} → ${g3(g.grelha)} (NO ${g.grelha.origemM?.join(', ')})`,
        casas: `${g.casasDentroZonaLivre + g.casasFora} (${g.casasDentroZonaLivre}/${g.casasFora})`,
        'bloq. srv': g.casasBloqueadas,
        'juízo≠ / motivo≠ / cob. afirmada≠': `${g.juizoDiferente} / ${g.motivosDiferentes} / ${g.coberturaAfirmadaDiferente}`,
        'cob. não afirmada (cli≠ref)': `${g.coberturaNaoAfirmada} (${g.coberturaNaoAfirmadaClienteDifereDaReferencia})`,
        faixa: `${ff.lados.join('+') || '—'}: ${ff.casas} casas, afirmada ${ff.coberturaAfirmada}, ≠ ${ff.coberturaAfirmadaDiferente}`,
        'desvio altura dentro/fora · pé dentro/fora · figuras (m)': `${g.desvioMaxAlturaM.dentro}/${g.desvioMaxAlturaM.fora} · ${g.desvioMaxPeM.dentro}/${g.desvioMaxPeM.fora} · ${g.desvioMaxFigurasM}`,
        figuras: g.figuras.length,
        recusas: `${g.recusas.length} [${sha(g.recusas.map((r) => `${r.x},${r.y} ${r.detalhe}`).sort())}]`,
        'mover (bloq. no cli)': `${g.moverOferecidas} (${g.moverBloqueadas})`,
        marcos: `${g.marcos.filter((m) => m.servidor.bloqueada).length}/${g.marcos.length}`,
      },
      b: {
        'figuras (x, y, desenhadaY, peM)': sha(g.figuras.map((f) => [f.x, f.y, f.desenhadaY, f.servidorPeM]).sort(cmpStr)),
        'marcos (casa, alturas)': sha(g.marcos.map((m) => [m.casa, m.servidor.alturaM, m.cliente.alturaM]).sort(cmpStr)),
      },
    };
  });
}

const semTempo = (t) => t.replace(/ \(\d+\.\d s\)$/, '');
function bancada(jog, mes) {
  const n = {};
  for (const f of jog.fases) {
    const figs = Object.values(f.figuras)
      .map((x) => `${x.quem} (${x.casa}) nó (${x.noXZ})${x.desvioXZ ? ` desvio (${x.desvioXZ})` : ''}${x.agua ? ' água' : ''}`)
      .sort();
    const c = f.caminho, a = f.alcance, p = f.passo, k = `${f.casaM} m:`;
    n[`${k} grelha`] = `${f.lado}×${f.lado}`;
    n[`${k} figuras`] = figs.join(' · ');
    n[`${k} caminho srv/cli (só-srv·só-cli·custo≠), água, reserva`] =
      `${c.servidor}/${c.cliente} (${c.soServidor}·${c.soCliente}·${c.custoDiferente}), ${c.deAgua}, ${c.reservaM} m = ${c.maxCasas} casas`;
    n[`${k} alcance`] = `${a.passos} passos vs ${a.alcanceCasas} casas → ${a.aoAlcance ? 'ao alcance' : 'fora'}; nos ataques: ${a.nosAtaques}`;
    n[`${k} passo`] = `→ (${p.para}) ${p.custoM} m ${p.recibo}${p.agua ? ' (água)' : ''}`;
  }
  const v = jog.verificacoes, m = mes.mestre, e = mes.espectador;
  n['jogadora: verificações'] = `${v.filter((x) => x.ok).length} de ${v.length} [${sha(v.map((x) => [x.ok, semTempo(x.texto)]))}]`;
  n['jogadora: sonda'] = `${jog.sonda.mensagens} mensagens, ${jog.sonda.mensagensDeMestre} de Mestre, ${jog.sonda.nAchados} achados`;
  n['jogadora: mapas vistos'] = jog.sonda.mapasVistos.join(' ');
  n['Mestre: recibos'] = m.recibos.map((r) => `${r.type}${r.campos?.op ? `(${r.campos.op} ${r.campos.casaM})` : ''}=${r.estado}`).join(' ');
  n['Mestre: escalas'] = m.escalas.map((s) => {
    const o = s.evento.soMestre;
    return `${o.casaMAntes}→${o.casaM} m, ${o.grelhaAntes.largura}→${o.grelha.largura}, reserva ${o.vez.reservaM} paga ${o.vez.casasQuePaga}; ${s.depois.figuras.map((f) => `${f.nome} (${f.x},${f.y})`).join(' ')}`;
  }).join(' | ');
  n['Mestre: movimentos'] = m.movimentos.map((x) => `(${x.de.x},${x.de.y})→(${x.para.x},${x.para.y}) ${x.custoM} m, fica ${x.reservaM}`).join(' | ');
  n['espectador'] = `${e.mensagens} mensagens, ${e.achados.length} achados, eventos escala ${JSON.stringify(e.eventosEscala)}`;
  n['Mestre: falhas'] = mes.falhas.length;
  const b = { 'jogadora: nós desenhados': sha(jog.fases.map((f) => Object.values(f.figuras).map((x) => [x.quem, x.noXZ, x.antesXZ ?? null]).sort(cmpStr))) };
  return { n, b };
}

function resumo(pasta) {
  const lin = { n: {}, b: {} };
  for (const [rot, f] of [['original', 'terreno-servidor-arena.json'], ['adaptada', 'terreno-servidor-arena-adaptada.json']]) {
    terreno(ler(pasta, f)).forEach((g, i) => {
      const pre = `${rot} g${String(i + 1).padStart(2, '0')}`;
      for (const [k, v] of Object.entries(g.n)) lin.n[`${pre} ${k}`] = v;
      for (const [k, v] of Object.entries(g.b)) lin.b[`${pre} ${k}`] = v;
    });
  }
  for (const [rot, f] of [['original', 'provar-terreno-servidor.log'], ['adaptada', 'provar-terreno-servidor-adaptada.log'], ['bancada', 'bancada-jogadora.log']]) {
    const seq = floresta(lerTexto(pasta, f));
    lin.n[`${rot} floresta: cargas`] = seq.length;
    seq.forEach((v, i) => { lin.n[`${rot} floresta carga ${String(i + 1).padStart(2, '0')}: casas_bloqueadas`] = v; });
  }
  const bc = bancada(ler(pasta, 'bancada-jogadora.json'), ler(pasta, 'bancada-mestre.json'));
  for (const [k, v] of Object.entries(bc.n)) lin.n[`bancada ${k}`] = v;
  for (const [k, v] of Object.entries(bc.b)) lin.b[`bancada ${k}`] = v;
  return lin;
}

const rs = corridas.map((c) => ({ ...c, r: resumo(c.pasta) }));
const ref = rs[0].r;
const dif = { n: 0, b: 0 };
const linhas = [];
const esc = (s) => String(s).replace(/\|/g, '\\|');
for (const nivel of ['n', 'b']) {
  linhas.push('', `### ${nivel === 'n' ? 'Números (o portão)' : 'Bits (impressões SHA-256 das alturas e dos nós desenhados)'}`, '');
  linhas.push(`| campo | ${rs.map((x) => x.rotulo).join(' | ')} | igual |`, `|---|${rs.map(() => '---|').join('')}---|`);
  const chaves = [...new Set(rs.flatMap((x) => Object.keys(x.r[nivel])))];
  for (const k of chaves) {
    const vs = rs.map((x) => x.r[nivel][k]);
    const igual = vs.every((v) => v !== undefined && JSON.stringify(v) === JSON.stringify(vs[0]));
    if (!igual) dif[nivel]++;
    linhas.push(`| ${esc(k)} | ${vs.map((v) => esc(v ?? '(falta)')).join(' | ')} | ${igual ? 'sim' : '**NÃO**'} |`);
  }
}
const nn = Object.keys(ref.n).length, nb = Object.keys(ref.b).length;
const veredicto = `${corridas.map((c) => c.rotulo).join(' × ')}: números ${nn - dif.n}/${nn} iguais, bits ${nb - dif.b}/${nb} iguais${portaoBits ? ' (bits no portão)' : ' (bits só registados)'}`;
const ok = dif.n === 0 && (!portaoBits || dif.b === 0);
linhas.unshift(`## Corridas lado a lado — ${veredicto}`, '', ...corridas.map((c) => `- **${c.rotulo}**: \`${c.pasta}\``));
linhas.push('', `${ok ? 'REPETE-SE' : 'NÃO SE REPETE'} — ${veredicto}`);
if (md) writeFileSync(md, linhas.join('\n') + '\n');
console.log(linhas.join('\n'));
process.exit(ok ? 0 : 1);
