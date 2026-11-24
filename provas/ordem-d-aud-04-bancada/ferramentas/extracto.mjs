// ORDEM-D-AUD-04-BANCADA — o EXTRACTO do journal da batalha medida (o journal é Mestre-only e fica fora do Git).
//   node provas/ordem-d-aud-04-bancada/ferramentas/extracto.mjs <journal.json> <config.json> <pasta-de-saida>
// Escreve na pasta de saída:
//   - journal-extracto.json — o `estado.mapa` (a grelha em que a batalha correu), a fase, a rodada e o desfecho, as
//     figuras no fim e os eventos da batalha (sem `turno` nem `ia`), com o recibo do Mestre. As SEMENTES saem todas e
//     os ids opacos trocam-se pelo fichaId FICTÍCIO da bancada;
//   - config-da-sala.json   — a config com que o servidor de produção arrancou (a fonte do §5.3: sem `sala.mapa`,
//     portanto a grelha-mapa da linha), com o PIN e as senhas redigidos;
//   - medicoes.json         — as medições: cada ataque (d20, total, CA, resultado, dano e vida do alvo antes → depois),
//     cada teste de morte (dado, Constituição somada, total, CD) e as contagens.
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import path from 'node:path';

const [caminhoJ, caminhoC, saida] = process.argv.slice(2);
if (!saida) { console.error('uso: extracto.mjs <journal.json> <config.json> <pasta-de-saida>'); process.exit(2); }
mkdirSync(saida, { recursive: true });
const j = JSON.parse(readFileSync(caminhoJ, 'utf8'));
const r = JSON.parse(String(j.registo).split('\n')[0]);
const e = r.estado;
const ficha = (id) => e.figuras[id]?.fichaId ?? id;

// tira as sementes e troca os ids, a qualquer profundidade
const limpar = (v, chave = '') => {
  if (Array.isArray(v)) return v.map((x) => limpar(x));
  if (v && typeof v === 'object') {
    const o = {};
    for (const [k, x] of Object.entries(v)) if (!/semente/i.test(k)) o[k] = limpar(x, k);
    return o;
  }
  if (typeof v === 'string' && /Id$/.test(chave)) return ficha(v);
  return v;
};

const eventos = r.eventos.filter((x) => !['turno', 'ia'].includes(x.tipo)).map((x) => limpar(x));
writeFileSync(path.join(saida, 'journal-extracto.json'), JSON.stringify({
  fonte: 'bancada-rede/privado/registo-MESTRE-ONLY-bancada-rede.json (journal do servidor de produção; fora do Git)',
  mapa: e.mapa, fase: e.fase, rodada: e.rodada, desfecho: e.desfecho ?? null,
  figurasNoFim: Object.values(e.figuras).map((f) => ({ ficha: f.fichaId, lado: f.lado, x: f.x, y: f.y, vida: f.vidaActual,
    vivo: f.vivo, caido: f.caido, estadoMorte: f.estadoMorte })),
  totalDeEventos: r.eventos.length,
  eventos,
}, null, 1));

const cfg = JSON.parse(readFileSync(caminhoC, 'utf8'));
for (const l of cfg.sala.lugares) { if (l.pin) l.pin = '(redigido)'; if (l.senha) l.senha = '(redigida)'; }
writeFileSync(path.join(saida, 'config-da-sala.json'), JSON.stringify(cfg, null, 2));

// as medições
const vida = {};
for (const f of Object.values(e.figuras)) vida[f.id] = null;
const fichasBancada = JSON.parse(readFileSync(path.resolve(path.dirname(caminhoC), cfg.fichas), 'utf8')).fichas;
for (const f of Object.values(e.figuras)) vida[f.id] = fichasBancada.find((x) => x.id === f.fichaId)?.vidaTotal ?? null;
const ataques = [];
const testes = [];
for (const x of r.eventos) {
  const d = x.dados ?? {};
  if (x.tipo === 'ataque') {
    const s = x.soMestre ?? {};
    const tec = fichasBancada.find((f) => f.id === ficha(d.atacanteId))?.tecnicas.find((t) => t.id === d.arma);
    const antes = vida[d.alvoId];
    const depois = s.soDoMestre?.alvoDepois?.vidaActual ?? antes;
    vida[d.alvoId] = depois;
    ataques.push({ seq: x.journalSeq, ts: x.ts, atacante: ficha(d.atacanteId), alvo: ficha(d.alvoId), arma: d.arma,
      // o d20 e o total das criaturas só vêm no soMestre (o público da jogadora não os tem)
      expressaoAtaque: d.expressao ?? /^(\S+)/.exec(s.recibo ?? '')?.[1], d20: (d.faces ?? s.faces)?.[0], total: d.total ?? s.total, ca: Number(/CA (\d+)/.exec(s.recibo ?? '')?.[1]),
      verificacaoCritico3d6: s.verificacaoCritico, resultado: d.resultado,
      expressaoDano: tec?.expressaoDano ?? null, dano: d.resultado === 'erro' ? 0 : s.totalEfectivo,
      vidaAlvo: `${antes} → ${depois}`, recibo: s.recibo });
  }
  if (x.tipo === 'estado' && d.vidaActual !== undefined) vida[d.figuraId] = d.vidaActual;
  if (x.tipo === 'teste_morte') {
    const t = x.soMestre?.saida?.teste ?? {};
    const s = x.soMestre?.saida ?? {};
    testes.push({ seq: x.journalSeq, ts: x.ts, figura: ficha(d.figuraId), expressaoNoRecibo: t.expressao, dado: t.somaDados,
      constituicaoSomada: t.constituicaoSomada, bonusFortitude: t.bonusFortitude, total: t.total, cd: s.cdEfectiva,
      sucesso: s.sucesso, estadoMorte: s.estadoMorte, desfecho: s.desfecho, publico: s.publico?.recibo });
  }
}
const porResultado = {};
for (const a of ataques) porResultado[a.resultado] = (porResultado[a.resultado] ?? 0) + 1;
writeFileSync(path.join(saida, 'medicoes.json'), JSON.stringify({
  contagem: { ataques: ataques.length, porResultado, testesDeMorte: testes.length,
    sucessos: testes.filter((t) => t.sucesso).length, falhas: testes.filter((t) => !t.sucesso).length,
    danoTotalPorAutor: ataques.reduce((o, a) => ({ ...o, [a.atacante]: (o[a.atacante] ?? 0) + a.dano }), {}) },
  ataques, testesDeMorte: testes,
}, null, 1));
console.log(JSON.stringify({ ok: true, mapa: e.mapa, eventos: eventos.length, ataques: ataques.length, porResultado, testesDeMorte: testes.length, desfecho: e.desfecho }));
