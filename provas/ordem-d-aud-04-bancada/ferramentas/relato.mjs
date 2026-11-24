// ORDEM-D-AUD-04-BANCADA — o RELATO da batalha medida, tirado do journal do servidor (Mestre-only, fora do Git).
//   node provas/ordem-d-aud-04-bancada/ferramentas/relato.mjs <journal.json> [inicioVideoISO]
// Escreve no stdout o relato em texto: cada ataque com o recibo do motor (faces, total, CA, dano, e as parcelas
// «bruto»/«RD» quando há RD), cada dano, queda, teste de morte, morte e o fim, com a hora e (dado o início do vídeo)
// o segundo do vídeo em que aparece. Os ids opacos trocam-se pelo fichaId FICTÍCIO da bancada; a semente não sai.
import { readFileSync } from 'node:fs';
const [caminho, inicio] = process.argv.slice(2);
const j = JSON.parse(readFileSync(caminho, 'utf8'));
const r = JSON.parse(String(j.registo).split('\n')[0]);
const e = r.estado;
const t0 = inicio ? Date.parse(inicio) : null;
const nome = (id) => e.figuras[id]?.fichaId ?? id;
const seg = (ts) => (t0 === null ? '' : ` [vídeo t=${((Date.parse(ts) - t0) / 1000).toFixed(1)} s]`);
const linhas = [];
const contas = { ataques: 0, porResultado: {}, danoPorAutor: {}, testesDeMorte: 0 };
for (const x of r.eventos) {
  const d = x.dados ?? {};
  const h = x.ts.slice(11, 23) + 'Z' + seg(x.ts);
  switch (x.tipo) {
    case 'ataque':
      contas.ataques += 1;
      contas.porResultado[d.resultado] = (contas.porResultado[d.resultado] ?? 0) + 1;
      linhas.push(`${h}  #${x.journalSeq} ATAQUE ${nome(d.atacanteId)} → ${nome(d.alvoId)} com ${d.arma}: ${d.resultado.toUpperCase()} | recibo: ${x.soMestre?.recibo ?? '—'}`);
      break;
    case 'dano':
      contas.danoPorAutor[nome(d.autorId)] = (contas.danoPorAutor[nome(d.autorId)] ?? []).concat(d.valor);
      linhas.push(`${h}  #${x.journalSeq} DANO ${d.valor} (${(d.tipos ?? []).join('+')}) de ${nome(d.autorId)} em ${nome(d.alvoId)}`);
      break;
    case 'estado':
      if (d.vidaActual !== undefined || d.visivel !== 'de_pe' || d.estadoMorte)
        linhas.push(`${h}  #${x.journalSeq} ESTADO ${nome(d.figuraId)}: vida=${d.vidaActual ?? '(não dita)'} visivel=${d.visivel} estadoMorte=${JSON.stringify(d.estadoMorte ?? null)}${d.paLivre !== undefined ? ' paLivre=' + d.paLivre : ''}`);
      break;
    case 'teste_morte': {
      contas.testesDeMorte += 1;
      const s = x.soMestre?.saida ?? {};
      linhas.push(`${h}  #${x.journalSeq} TESTE DE MORTE ${nome(d.figuraId)}: ${s.teste?.expressao ?? ''} → ${s.teste?.total ?? '?'} vs CD ${s.cdEfectiva ?? s.cd ?? '?'} → ${s.sucesso ? 'sucesso' : 'falha'} · ${JSON.stringify(s.estadoMorte ?? null)} · desfecho ${s.desfecho ?? '?'}${s.morteAdjudicada ? ' · MORTE ADJUDICADA' : ''} | recibo público: «${s.publico?.recibo ?? ''}»`);
      break;
    }
    case 'movimento':
      linhas.push(`${h}  #${x.journalSeq} MOVIMENTO ${nome(d.figuraId)} (${d.de.x},${d.de.y}) → (${d.para.x},${d.para.y}) ${d.custoM} m`);
      break;
    case 'turno': case 'ia': break;
    default:
      linhas.push(`${h}  #${x.journalSeq} ${x.tipo.toUpperCase()} ${JSON.stringify(Object.fromEntries(Object.entries(d).map(([k, v]) => [k, /Id$/.test(k) ? nome(v) : v])))}`);
  }
}
console.log(linhas.join('\n'));
console.log('\nCONTAGEM: ' + JSON.stringify({ ...contas, fase: e.fase, rodada: e.rodada, desfecho: e.desfecho ?? null,
  figurasNoFim: Object.values(e.figuras).map((f) => ({ ficha: f.fichaId, vida: f.vidaActual, vivo: f.vivo, caido: f.caido, estadoMorte: f.estadoMorte })) }));
