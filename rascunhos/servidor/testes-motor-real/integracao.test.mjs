// Integração do servidor de mesa com o MOTOR REAL (vlab-completo.js embrulhado pela JV1.1-a).
// Corre só no CI, no job motor-real, com MOTOR_MJS a apontar para o módulo gerado por embrulhar.mjs.
// Objetivo: descobrir e travar as diferenças entre o motor falso e o real (TODO(JV0.3) do sala.js):
//   - que valores de `resultado` o VLAB devolve;
//   - se a sala aplica dano e estado a partir da saída real;
//   - se nada da saída do motor (soDoMestre, recibo cru) chega à jogadora.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { pathToFileURL } from 'node:url';
import path from 'node:path';
import { carregarFichas } from '../nucleo/carregar-fichas.js';
import { montarMesa, listaDeFichas, recibo, procurarCanarios } from '../testes/ajudantes.mjs';

const MOTOR_MJS = process.env.MOTOR_MJS;
const RESULTADOS_CONHECIDOS = new Set(['acerto', 'erro', 'critico', 'falha_critica', 'falhaCritica']);

async function motorRealComEspiao() {
  const mod = await import(pathToFileURL(path.resolve(MOTOR_MJS)).href);
  const saidas = [];
  const Vlab = Object.create(mod.Vlab);
  Vlab.resolverAtaque = (entrada) => {
    let s;
    try { s = mod.Vlab.resolverAtaque(entrada); } catch (e) { saidas.push({ excecao: String(e?.message || e) }); throw e; }
    saidas.push({ resultado: s?.resultado, danoAplicado: s?.danoAplicado, erro: s?.erro?.codigo ?? s?.erro ?? null,
      chavesTopo: s && typeof s === 'object' ? Object.keys(s).sort() : null,
      chavesSoDoMestre: s?.soDoMestre ? Object.keys(s.soDoMestre).sort() : null,
      alvoDepois: s?.soDoMestre?.alvoDepois ? Object.keys(s.soDoMestre.alvoDepois).sort() : null });
    return s;
  };
  return { motor: { Dmg: mod.Dmg, Vlab, MOTOR_SHA256: mod.MOTOR_SHA256, DMG_VERSAO: 'real', LEVELUP_SHA: null }, saidas };
}

function fichasAcertaveis() {
  const lista = listaDeFichas();
  const orc = lista.find((f) => f.id === 'orc-teste');
  orc.ca = 10;          // fictício e baixo: o ataque pode acertar
  orc.rd = { geral: 0, porTipo: {} };
  orc.vidaTotal = 200;
  const r = carregarFichas(lista);
  if (!r.ok) throw new Error('fichas inválidas: ' + JSON.stringify(r.erros));
  return r.fichas;
}

test('motor real: ataques da heroína ao orc resolvem sem erro de ponte, com dano, e sem vazar o motor', { skip: !MOTOR_MJS && 'MOTOR_MJS não definido (só corre no job motor-real)' }, async () => {
  const { motor, saidas } = await motorRealComEspiao();
  const mesa = montarMesa({ motor, fichas: fichasAcertaveis() });
  mesa.entrarTodos();
  mesa.iniciarCombate([['orc-teste', { x: 2, y: 5 }]]);
  const h = mesa.clientes.heroina;
  const orc = h.idPorNome('Orc');
  assert.ok(orc, 'a heroína vê o orc');

  const recibos = [];
  for (let volta = 0; volta < 25; volta++) {
    const r = recibo(mesa.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }));
    recibos.push(r ? { type: r.type, estado: r.estado, motivo: r.motivo } : null);
    const fim = recibo(mesa.intencao('heroina', { tipo: 'encerrar' }));
    if (!fim) break;
    if (h.eventos('fim').length) break;
  }

  const resultados = [...new Set(saidas.map((s) => s.resultado))];
  const desconhecidos = resultados.filter((x) => !RESULTADOS_CONHECIDOS.has(x));
  const danos = h.eventos('dano');
  console.log('DIAGNOSTICO-MOTOR-REAL ' + JSON.stringify({
    sha: motor.MOTOR_SHA256, chamadas: saidas.length, resultados, desconhecidos,
    excecoes: saidas.filter((s) => s.excecao), erros: [...new Set(saidas.map((s) => s.erro).filter(Boolean))],
    exemploSaida: saidas.find((s) => s.danoAplicado > 0) ?? saidas[0] ?? null,
    recibos: recibos.slice(0, 8), eventosDanoHeroina: danos.length,
  }, null, 1));

  assert.ok(saidas.length > 0, 'o motor real foi chamado');
  assert.deepEqual(saidas.filter((s) => s.excecao), [], 'o motor real não rebenta');
  assert.deepEqual(desconhecidos, [], 'todos os valores de resultado do VLAB são conhecidos pelo sala.js');
  assert.ok(saidas.some((s) => typeof s.danoAplicado === 'number' && s.danoAplicado > 0), 'houve pelo menos um acerto com dano');
  assert.ok(danos.length > 0, 'a heroína recebeu pelo menos um evento de dano (ela vê o dano que causa)');

  // Nada do motor chega cru à jogadora.
  const achados = procurarCanarios(h.msgs, { chaves: ['soDoMestre', 'alvoDepois', 'defesaAplicavel', 'reacaoDefensiva', 'semente'] });
  assert.deepEqual(achados, [], 'nenhuma chave interna do motor na Party');
});
