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
// Nomes REAIS do VLAB (medidos no CI): acerta, erra, critico, falhaCritica.
const RESULTADOS_CONHECIDOS = new Set(['acerta', 'erra', 'critico', 'falhaCritica']);

async function motorRealComEspiao() {
  const mod = await import(pathToFileURL(path.resolve(MOTOR_MJS)).href);
  const saidas = [];
  const Vlab = Object.create(mod.Vlab);
  Vlab.resolverAtaque = (entrada) => {
    let s;
    try { s = mod.Vlab.resolverAtaque(entrada); } catch (e) { saidas.push({ excecao: String(e?.message || e) }); throw e; }
    saidas.push({ resultado: s?.resultado, danoAplicado: s?.danoAplicado, erro: s?.erro?.codigo ?? s?.erro ?? null,
      chavesRolagem: s?.rolagem && typeof s.rolagem === 'object' ? Object.keys(s.rolagem).sort() : null,
      rolagemExemplo: s?.rolagem ?? null, totalEfectivo: s?.totalEfectivo ?? null,
      chavesPublico: s?.publico && typeof s.publico === 'object' ? Object.keys(s.publico).sort() : null,
      chavesFalhaCritica: s?.desgracaPendente && typeof s.desgracaPendente === 'object' ? Object.keys(s.desgracaPendente).sort() : null,
      desgracaPendente: s?.desgracaPendente ?? null,
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
  // Falha crítica da jogadora → cartão de desgraça ao Mestre (H10). A sala espera, e bem;
  // o teste faz de Mestre e aprova, como o Mestre faria na mesa (IBX-266).
  const desgracas = [];
  for (let volta = 0; volta < 25; volta++) {
    const r = recibo(mesa.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' }));
    recibos.push(r ? { type: r.type, estado: r.estado, motivo: r.motivo } : null);
    if (r && r.estado === 'AGUARDANDO_MESTRE') {
      const cartao = mesa.clientes.mestre.ultimo('MASTER_CARD');
      const aprovado = cartao ? recibo(mesa.mestre('MASTER_APPROVE', { cartaoId: cartao.cartaoId, decisao: 'aprovar' })) : null;
      desgracas.push({
        tipo: cartao?.tipo ?? null,
        proposta: cartao?.proposta ?? null,
        aprovacao: aprovado ? { type: aprovado.type, estado: aprovado.estado, motivo: aprovado.motivo } : null,
      });
    }
    const fim = recibo(mesa.intencao('heroina', { tipo: 'encerrar' }));
    if (!fim) break;
    // Decisão 1 do Mestre (ordem 6): a falha crítica do orc também abre cartão; o teste faz de Mestre e aprova.
    for (let i = 0; i < 5; i++) {
      const aberto = mesa.sala.depuracao.estado().cartoes.find((c) => c.estado === 'aberto');
      if (!aberto) break;
      const aprovado = recibo(mesa.mestre('MASTER_APPROVE', { cartaoId: aberto.cartaoId, decisao: 'aprovar' }));
      desgracas.push({
        tipo: aberto.tipo, proposta: aberto.proposta ?? null, doMonstro: true,
        aprovacao: aprovado ? { type: aprovado.type, estado: aprovado.estado, motivo: aprovado.motivo } : null,
      });
    }
    if (h.eventos('fim').length) break;
  }

  const resultados = [...new Set(saidas.map((s) => s.resultado))];
  const desconhecidos = resultados.filter((x) => !RESULTADOS_CONHECIDOS.has(x));
  const danos = h.eventos('dano');
  console.log('DIAGNOSTICO-MOTOR-REAL ' + JSON.stringify({
    sha: motor.MOTOR_SHA256, chamadas: saidas.length, resultados, desconhecidos,
    excecoes: saidas.filter((s) => s.excecao), erros: [...new Set(saidas.map((s) => s.erro).filter(Boolean))],
    exemploSaida: saidas.find((s) => (s.danoAplicado?.total ?? 0) > 0) ?? saidas[0] ?? null,
    exemploFalhaCritica: saidas.find((s) => s.resultado === 'falhaCritica') ?? null,
    voltas: recibos.length,
    contagem: recibos.reduce((a, r) => { const k = r ? `${r.type}:${r.estado ?? r.motivo}` : 'nulo'; a[k] = (a[k] ?? 0) + 1; return a; }, {}),
    recusas: recibos.filter((r) => r && r.type === 'ROOM_REJECT'),
    desgracas, eventosDanoHeroina: danos.length,
  }, null, 1));

  assert.ok(saidas.length > 0, 'o motor real foi chamado');
  assert.deepEqual(saidas.filter((s) => s.excecao), [], 'o motor real não rebenta');
  assert.deepEqual(desconhecidos, [], 'todos os valores de resultado do VLAB são conhecidos pelo sala.js');
  assert.ok(saidas.some((s) => (s.danoAplicado?.total ?? 0) > 0), 'houve pelo menos um acerto com dano (danoAplicado.total)');
  assert.ok(recibos.some((r) => r && r.type === 'ROOM_RECEIPT' && r.estado === 'APLICADA'), 'pelo menos um ataque aplicado');
  // Cada desgraça aprovada pelo Mestre tem de se aplicar com o motor real (a proposta real do VLAB serve à sala).
  for (const d of desgracas) {
    assert.equal(d.tipo, 'desgraca', 'o cartão aberto pela falha crítica é de desgraça');
    assert.ok(d.aprovacao && d.aprovacao.type === 'ROOM_RECEIPT' && d.aprovacao.estado === 'APLICADA',
      'a aprovação do Mestre aplica a desgraça com o motor real: ' + JSON.stringify(d));
  }
  // Com o Mestre a decidir, nenhuma recusa por espera; as restantes (do motor/regra) continuam poucas.
  const recusas = recibos.filter((r) => r && r.type === 'ROOM_REJECT');
  assert.deepEqual(recusas.filter((r) => r.motivo === 'aguardando_mestre'), [], 'nenhum ataque recusado por espera do Mestre');
  assert.ok(recusas.length <= 3, 'poucos ataques recusados: ' + JSON.stringify(recusas));
  assert.ok(danos.length > 0, 'a heroína recebeu pelo menos um evento de dano (ela vê o dano que causa)');

  // Nada do motor chega cru à jogadora.
  const achados = procurarCanarios(h.msgs, { chaves: ['soDoMestre', 'alvoDepois', 'defesaAplicavel', 'reacaoDefensiva', 'semente'] });
  assert.deepEqual(achados, [], 'nenhuma chave interna do motor na Party');
});
