// Ordem AUTOJOGO — a ferramenta de medição (servidor/autojogo): o dado semeado, o cenário fictício e o conferidor dos
// registos. Só leitura, sem rede: o servidor de bancada não arranca aqui (a partida inteira prova-se com o Godot).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { fileURLToPath } from 'node:url';
import { rngSemeado, lerCenario } from '../autojogo/servidor-autojogo.mjs';
import { conferirRegisto, resumir, tabelaMd } from '../autojogo/resumir-autojogo.mjs';

const CENARIO = fileURLToPath(new URL('../autojogo/cenario-bancada.json', import.meta.url));

test('autojogo: a mesma semente dá a mesma sequência de dados; outra semente, outra', () => {
  const tirar = (s) => { const r = rngSemeado(s); return Array.from({ length: 32 }, () => r()); };
  assert.deepEqual(tirar(7), tirar(7));
  assert.notDeepEqual(tirar(7), tirar(8));
  for (const x of tirar(1)) assert.ok(Number.isInteger(x) && x >= 0 && x < 2 ** 32);
});

test('autojogo: o cenário de bancada carrega e as fichas dele validam', () => {
  const { cenario, fichas } = lerCenario(CENARIO);
  assert.equal(cenario.formato, 'cenario-autojogo/1');
  const tem = (id) => Object.hasOwn(fichas, id); // carregarFichas devolve um mapa id → ficha
  for (const x of [...cenario.heroinas, ...cenario.criaturas]) assert.ok(tem(x.fichaId), x.fichaId);
});

// Um registo mínimo de uma partida (a forma que o autojogo.gd escreve).
function registo({ dano = 10, resumoDano = 10, vencedor = 'heroinas', turnos = 2 } = {}) {
  const l = (x) => ({ semente: 5, ...x });
  return [
    l({ tipo: 'inicio' }),
    l({ tipo: 'vez', rodada: 1, turno: 1 }),
    l({ tipo: 'evento', evento: 'dano', dados: { autorId: 'h', alvoId: 'c', valor: dano } }),
    l({ tipo: 'vez', rodada: 1, turno: 2 }),
    l({ tipo: 'evento', evento: 'fim', dados: { desfecho: 'vitoria' } }),
    l({ tipo: 'resumo', turnos, rodadas: 1, desfecho: 'vitoria', vencedor, figuras: [
      { figura: 'H', figuraId: 'h', fichaId: 'h', lado: 'jogadora', vidaTotal: 20, vidaRestante: 20, viva: true, danoCausado: resumoDano, danoSofrido: 0, ataques: 1 },
      { figura: 'C', figuraId: 'c', fichaId: 'c', lado: 'criatura', vidaTotal: 8, vidaRestante: 0, viva: false, danoCausado: 0, danoSofrido: resumoDano, ataques: 0 },
    ] }),
  ];
}

test('autojogo: o conferidor aceita o registo que bate e soma-o', () => {
  const p = conferirRegisto(registo());
  assert.deepEqual(p.problemas, []);
  const r = resumir([{ ficheiro: 's5.jsonl', ...p }]);
  assert.equal(r.conferidas, 1);
  assert.deepEqual(r.vitorias, { heroinas: 1, criaturas: 0, nenhum: 0 });
  const c = r.figuras.find((f) => f.fichaId === 'c');
  assert.equal(c.vidaPerdidaMedia, 8);
  assert.equal(c.caidas, 1);
  assert.equal(c.mortes, 1);
  assert.match(tabelaMd(r), /\| 5 \| heroinas \| 2 \| 1 \| bate \|/);
});

test('autojogo: o conferidor recusa o resumo que não bate com o registo', () => {
  assert.ok(conferirRegisto(registo({ resumoDano: 11 })).problemas.some((t) => /dano causado 11/.test(t)));
  assert.ok(conferirRegisto(registo({ turnos: 3 })).problemas.some((t) => /turnos do resumo 3/.test(t)));
  assert.ok(conferirRegisto(registo({ vencedor: 'nenhum' })).problemas.some((t) => /vencedor nenhum/.test(t)));
  const outra = registo();
  outra[2].semente = 6;
  assert.ok(conferirRegisto(outra).problemas.some((t) => /semente 6/.test(t)));
  assert.ok(conferirRegisto(registo().slice(0, -1)).problemas.some((t) => /falta o `resumo`/.test(t)));
});
