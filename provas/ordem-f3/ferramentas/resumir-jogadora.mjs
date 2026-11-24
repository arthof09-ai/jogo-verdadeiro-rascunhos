// ORDEM-F3: uma linha com o que interessa do bancada-jogadora.json — o desvio da heroína a 1 m e a 2 m (o campo que o
// comparador lê à letra) e cada resto ≠ 0 que o registo `quietos` apanhou no momento do «assente»/«pronta».
//   node resumir-jogadora.mjs <bancada-jogadora.json> [...]
import { readFileSync } from 'node:fs';

for (const f of process.argv.slice(2)) {
  const d = JSON.parse(readFileSync(f, 'utf8'));
  const desv = d.fases.map((fa) => {
    const h = Object.values(fa.figuras).find((x) => x.quem === 'heroína');
    return `${fa.casaM} m desvio=${h.desvioXZ ? `(${h.desvioXZ.join(', ')})` : '-'}`;
  });
  // os desvios esperados por casa: 1,5 m → 0; 1 m → −0,25, 0 ou 0,25; 2 m → 0
  const ESPERADO = { '1.5': [0], '1': [-0.25, 0, 0.25], '2': [0] };
  const exacto = d.fases.every((fa) => Object.values(fa.figuras).every((x) => !x.desvioXZ
    || x.desvioXZ.every((v) => (ESPERADO[String(fa.casaM)] ?? [0]).includes(v))));
  const restos = (d.quietos ?? []).flatMap((q) => Object.entries(q.resto)
    .filter(([, r]) => r !== 'Vector3(0, 0, 0)')
    .map(([id, r]) => `${q.onde} ${id.slice(0, 6)} ${r} (${q.frames} frames)`));
  console.log(`${desv.join(' · ')} · desvios ${exacto ? 'EXACTOS' : 'COM RESTO'} · restos no «quietos»: ${restos.length ? restos.join('; ') : 'nenhum'}`);
}
