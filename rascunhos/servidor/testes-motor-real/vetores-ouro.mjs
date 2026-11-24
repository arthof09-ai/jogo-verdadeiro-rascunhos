// JV0.3 — vetores-ouro (Plano A v1.1, ficha JV0.3; Plano 2, F4 ponto 6; ORDEM-F4-PARCIAL).
//
// Casos de referência congelados que o servidor tem de reproduzir EXACTAMENTE, nos 9 grupos da ficha JV0.3:
//   ataque normal · ataque crítico · falha crítica (as 6 desgraças) · morte 3×3 · Desvincular · Defender ·
//   transformação · consumíveis · acumulação do DMG.
// Cada caso traz a entrada, a semente (ou as faces) e a saída; cada ficheiro traz o SHA-256 do motor.
//
// De onde vem o motor: o `vlab-completo.js` oficial (VLAB + DMG 2.0), baixado e embrulhado pelo job `motor-real` do CI
// (MOTOR_MJS), como em todo o `testes-motor-real/`. O motor NÃO se copia para o repositório (README da raiz: as cópias do
// motor são excluídas por regra); o SHA dele fica gravado em cada ficheiro e no MANIFESTO, e um motor diferente faz o
// teste falhar com o aviso de regenerar e rever.
//
// Dois níveis:
//   - «motor»: a chamada que a sala faz à porta dos motores (Vlab.resolverAtaque, resolverTesteDeMorte,
//     validarSaidaDeAdjacencia; Dmg.calcularDano), com entidades fictícias na forma do `entidadeMotor` da sala.
//   - «sala»: dois grupos que o motor não resolve e que são do servidor (transformação: a `fichaEfetiva` da forma
//     transformada e o custo; consumíveis: o que o servidor oferece e recusa hoje). Correm a sala de verdade
//     (`criarSala` pelos `testes/ajudantes.mjs`) com o motor real e o rng determinista.
//
// SÓ DADOS FICTÍCIOS: as entidades e técnicas daqui são inventadas (as expressões das técnicas vêm de
// `dados-exemplo/fichas-ficticias.json`). Nenhum número do Mestre nem da Party.
//
// O QUE NÃO DECIDE: os valores do Defender usados aqui são fictícios (o valor da reação Defender é decisão do Mestre,
// `sala.js` TODO(R0)); o grupo dos consumíveis congela a AUSÊNCIA de hoje (`consumiveis: []`, a intenção recusada) — o
// conteúdo dos consumíveis é decisão do Mestre (JV0.6b) e, quando chegar, este grupo regenera-se.
import { jsonCanonico } from '../nucleo/util.js';
import { sha256Hex } from '../nucleo/sha256.js';
import { carregarFichas } from '../nucleo/carregar-fichas.js';
import { montarMesa, listaDeFichas, recibo, rngDeterministico } from '../testes/ajudantes.mjs';

export const FORMATO = 'vetores-ouro/1';
export const GRUPOS = Object.freeze([
  '01-ataque-normal', '02-ataque-critico', '03-falha-critica', '04-morte-3x3', '05-desvincular', '06-defender',
  '07-transformacao', '08-consumiveis', '09-acumulacao-dmg',
]);

const json = (x) => (x === undefined ? null : JSON.parse(JSON.stringify(x)));

// ------------------------------------------------------------------------------------------------ peças fictícias
// As expressões das quatro técnicas são as de dados-exemplo/fichas-ficticias.json.
const TECNICAS = Object.freeze([
  { id: 'chicote-teste', nome: 'Chicote de Teste', expressaoAtaque: '1d20+4', expressaoDano: '1d6+2', tipo: 'cortante', custoPA: 2, usaArma: true },
  { id: 'faca-teste', nome: 'Faca de Teste', expressaoAtaque: '1d20+2', expressaoDano: '1d4+1', tipo: 'perfurante', custoPA: 0, usaArma: true },
  { id: 'machado-teste', nome: 'Machado de Teste', expressaoAtaque: '1d20+7', expressaoDano: '2d6+4', tipo: 'cortante', custoPA: 0, usaArma: true },
  { id: 'mordida-teste', nome: 'Mordida de Teste', expressaoAtaque: '1d20+5', componentes: [{ tipo: 'perfurante', expressao: '1d8+3' }], tipos: ['perfurante'], custoPA: 0, derruba: true },
]);

function atacante(extra = {}) {
  return {
    id: 'atacante-ficticio', nomePublico: 'Atacante Fictício', classificacao: 'prata', vidaActual: 40, vidaTotal: 40,
    paLivre: 10, estado: [], testes: { ataque: '1d20+3', fortitude: '1d20+2' }, constituicao: 12,
    rd: { geral: 0, porTipo: {} }, armaCaida: false, armaQuebrada: false, ...extra,
  };
}
function alvo(extra = {}) {
  return {
    id: 'alvo-ficticio', nomePublico: 'Alvo Fictício', classificacao: 'bronze', vidaActual: 30, vidaTotal: 30, ca: 12,
    rd: { geral: 0, porTipo: {} }, estado: [], testesDeMorteDesignado: false, estadoMorte: null, constituicao: 11,
    testes: { fortitude: '1d20+1' }, ...extra,
  };
}
// Triplos da verificação de crítico (errata JV1.1-a §6) que NÃO dão crítico nem falha crítica com margem 0.
const VERIF_NEUTRAS = Object.freeze([[3, 4, 2], [6, 5, 6], [1, 2, 3], [6, 6, 1], [1, 1, 3], [2, 6, 6], [5, 5, 5], [4, 1, 6]]);
const ALIADOS = Object.freeze([
  { id: 'aliado-ficticio-1', posicao: 'adjacente' },
  { id: 'aliado-ficticio-2', posicao: 'naLinha' },
]);

// ------------------------------------------------------------------------------------------------ os casos
function casosMotor() {
  const g = Object.fromEntries(GRUPOS.map((n) => [n, []]));
  const add = (grupo, funcao, entrada) => g[grupo].push({ funcao, entrada: json(entrada) });

  // 01 — ataque normal: 4 técnicas × 24 variações (CA, V/D, flanco, caído, RD, Vida, designação de morte).
  TECNICAS.forEach((t, it) => {
    for (let k = 0; k < 24; k += 1) {
      const ctx = {
        semente: 1000 + 37 * k + 7 * it, verificacaoCritico: VERIF_NEUTRAS[(k + it) % VERIF_NEUTRAS.length],
        modoDesgraca: 'proposta', niveisVantagem: k % 5 === 1 ? 1 + (k % 3) : 0, niveisDesvantagem: k % 5 === 2 ? 1 : 0,
        ataqueDeOportunidade: false, flanqueando: k % 7 === 3, atacanteCaido: k % 11 === 4, atacanteFraco: k % 13 === 6,
        aliadosAoAlcance: [],
      };
      const a = alvo({
        ca: 6 + (k % 16), rd: { geral: k % 6 === 5 ? 2 : 0, porTipo: {} }, vidaActual: k % 8 === 7 ? 3 : 30,
        testesDeMorteDesignado: k % 2 === 1,
      });
      add('01-ataque-normal', 'Vlab.resolverAtaque', { atacante: atacante(), alvo: a, tecnica: t, contexto: ctx });
    }
  });

  // 02 — crítico: «6,6 e o 3.º ≥ 5 − margem», margem 0..4, todas as terceiras faces que o dão; e a magia (sem crítico).
  let n2 = 0;
  for (let margem = 0; margem <= 4; margem += 1) {
    for (let c = 5 - margem; c <= 6; c += 1) {
      for (const t of [TECNICAS[n2 % 4], TECNICAS[(n2 + 1) % 4]]) {
        const ctx = { semente: 2000 + 11 * n2, verificacaoCritico: [6, 6, c], margemCritico: margem, modoDesgraca: 'proposta', aliadosAoAlcance: [] };
        add('02-ataque-critico', 'Vlab.resolverAtaque', { atacante: atacante(), alvo: alvo({ ca: 25 + (n2 % 5) }), tecnica: t, contexto: ctx });
      }
      n2 += 1;
    }
  }
  for (let k = 0; k < 4; k += 1) {
    const t = { ...TECNICAS[k], magia: true };
    add('02-ataque-critico', 'Vlab.resolverAtaque', { atacante: atacante(), alvo: alvo({ ca: 10 }), tecnica: t, contexto: { semente: 2500 + k, verificacaoCritico: [6, 6, 6], aliadosAoAlcance: [] } });
  }

  // 03 — falha crítica e as 6 desgraças: «1,1 e o 3.º em 1 ou 2».
  const IDS_DESGRACA = ['cai', 'arma-cai', 'acerta-amigo', 'acerta-se', 'arma-quebra', 'quebra-corpo'];
  let n3 = 0;
  for (const id of IDS_DESGRACA) {
    for (const comAliados of [true, false]) {
      for (const usaArma of [true, false]) {
        const t = { ...TECNICAS[n3 % 3], usaArma };
        const ctx = { semente: 3000 + 13 * n3, verificacaoCritico: [1, 1, 1 + (n3 % 2)], modoDesgraca: 'escolha', desgracaEscolhida: id, aliadosAoAlcance: comAliados ? ALIADOS : [], parteDoCorpo: id === 'quebra-corpo' ? 'braço' : undefined };
        add('03-falha-critica', 'Vlab.resolverAtaque', { atacante: atacante({ vidaActual: 6 + (n3 % 30) }), alvo: alvo(), tecnica: t, contexto: ctx });
        n3 += 1;
      }
    }
  }
  for (let k = 0; k < 30; k += 1) { // «sorte»: o d100 da tabela renormalizada, por semente
    const ctx = { semente: 3500 + 101 * k, verificacaoCritico: [1, 1, 1 + (k % 2)], modoDesgraca: 'sorte', aliadosAoAlcance: k % 3 === 0 ? [] : ALIADOS };
    add('03-falha-critica', 'Vlab.resolverAtaque', { atacante: atacante({ vidaActual: 3 + (k % 20), estado: k % 7 === 0 ? ['caido'] : [] }), alvo: alvo(), tecnica: TECNICAS[k % 4], contexto: ctx });
  }
  for (let k = 0; k < 12; k += 1) { // «proposta»: o que o servidor manda (cartão ao Mestre)
    const ctx = { semente: 3900 + 17 * k, verificacaoCritico: [1, 1, 2 - (k % 2)], modoDesgraca: 'proposta', aliadosAoAlcance: k % 2 ? ALIADOS : [] };
    add('03-falha-critica', 'Vlab.resolverAtaque', { atacante: atacante(), alvo: alvo(), tecnica: TECNICAS[k % 4], contexto: ctx });
  }

  // 04 — morte 3×3: os 9 estados (0..2 sucessos × 0..2 falhas) × faces + ajudante + bónus de Fortitude; e as recusas.
  const CLASSES = ['bronze', 'prata', 'ouro', 'ouroNegro', 'lendario'];
  let n4 = 0;
  for (let s = 0; s <= 2; s += 1) {
    for (let f = 0; f <= 2; f += 1) {
      for (const face of [1, 8, 14, 20]) {
        const moribundo = {
          id: 'moribundo-ficticio', testesDeMorteDesignado: true, estadoMorte: { fase: 'aMorrer', sucessos: s, falhas: f },
          constituicao: 8 + (n4 % 7), classificacao: CLASSES[n4 % CLASSES.length], testes: { fortitude: '1d20+2' },
          bonusFortitude: [0, 7, 14, 3][n4 % 4],
        };
        const ajudante = n4 % 5 === 2 ? { id: 'ajudante-ficticio', constituicao: 13, testes: { fortitude: '1d20+4' } } : undefined;
        add('04-morte-3x3', 'Vlab.resolverTesteDeMorte', { moribundo, ajudante, contexto: { faces: [face] } });
        n4 += 1;
      }
    }
  }
  const morteRecusas = [
    { moribundo: { testesDeMorteDesignado: false, estadoMorte: { fase: 'aMorrer', sucessos: 0, falhas: 0 }, constituicao: 10, classificacao: 'bronze', testes: { fortitude: '1d20' } }, contexto: { semente: 1 } },
    { moribundo: { testesDeMorteDesignado: true, estadoMorte: { fase: 'estabilizado', sucessos: 3, falhas: 1 }, constituicao: 10, classificacao: 'bronze', testes: { fortitude: '1d20' } }, contexto: { semente: 1 } },
    { moribundo: { testesDeMorteDesignado: true, estadoMorte: { fase: 'aMorrer', sucessos: 0, falhas: 0 }, constituicao: 10, classificacao: 'titanio', testes: { fortitude: '1d20' } }, contexto: { semente: 1 } },
    { moribundo: { testesDeMorteDesignado: true, estadoMorte: { fase: 'aMorrer', sucessos: 0, falhas: 0 }, constituicao: 10, classificacao: 'prata', testes: { fortitude: '1d20' } }, contexto: { faces: [5, 6] } },
  ];
  for (const e of morteRecusas) add('04-morte-3x3', 'Vlab.resolverTesteDeMorte', e);
  for (let face = 1; face <= 20; face += 1) { // o estado decisivo (2 × 2): cada face do d20, com e sem bónus extra
    add('04-morte-3x3', 'Vlab.resolverTesteDeMorte', { moribundo: { id: 'moribundo-ficticio', testesDeMorteDesignado: true, estadoMorte: { fase: 'aMorrer', sucessos: 2, falhas: 2 }, constituicao: 10, classificacao: 'prata', testes: { fortitude: '1d20+3' }, bonusFortitude: face % 2 ? 0 : 14 }, contexto: { faces: [face] } });
  }
  for (let k = 0; k < 8; k += 1) { // por semente (o servidor manda semente quando não há dados físicos)
    add('04-morte-3x3', 'Vlab.resolverTesteDeMorte', { moribundo: { testesDeMorteDesignado: true, estadoMorte: { fase: 'aMorrer', sucessos: k % 3, falhas: (k + 1) % 3 }, constituicao: 11, classificacao: CLASSES[k % 5], testes: { fortitude: '1d20+1' } }, contexto: { semente: 4000 + 41 * k } });
  }

  // 05 — Desvincular (validarSaidaDeAdjacencia): 0 a 3 inimigos adjacentes × reação disponível × desvincular.
  const opcoesDesv = [null, { gastouAccaoPadrao: true }, { gastouAccaoPadrao: false }];
  for (let nIn = 0; nIn <= 3; nIn += 1) {
    for (let bits = 0; bits < (1 << nIn); bits += 1) {
      const inimigos = Array.from({ length: nIn }, (_, i) => ({ id: 'inimigo-ficticio-' + (i + 1), reacaoDisponivel: !!(bits & (1 << i)) }));
      for (const d of opcoesDesv) add('05-desvincular', 'Vlab.validarSaidaDeAdjacencia', { inimigosAdjacentes: inimigos, desvincular: d });
    }
  }
  add('05-desvincular', 'Vlab.validarSaidaDeAdjacencia', { desvincular: { gastouAccaoPadrao: true } });
  add('05-desvincular', 'Vlab.validarSaidaDeAdjacencia', { inimigosAdjacentes: [null, { reacaoDisponivel: true }, { id: 'inimigo-ficticio-9', reacaoDisponivel: true }], desvincular: { gastouAccaoPadrao: true } });

  // 06 — Defender: a reação declarada no ALVO (alvo.reacaoDefensiva), como a sala a põe. VALORES FICTÍCIOS.
  for (let k = 0; k < 32; k += 1) {
    const reacao = { tipo: 'Defender', valor: 8 + (k % 17), origem: 'valor fictício do vetor-ouro (não é o valor do Mestre)' };
    const a = alvo({ ca: 10 + (k % 5), reacaoDefensiva: reacao, ...(k % 4 === 3 ? { ca: undefined } : {}) });
    const ctx = { semente: 6000 + 29 * k, verificacaoCritico: VERIF_NEUTRAS[k % VERIF_NEUTRAS.length], modoDesgraca: 'proposta', niveisVantagem: k % 6 === 1 ? 1 : 0, aliadosAoAlcance: [] };
    add('06-defender', 'Vlab.resolverAtaque', { atacante: atacante(), alvo: a, tecnica: TECNICAS[k % 4], contexto: ctx });
  }
  for (let k = 0; k < 4; k += 1) { // contra um ataque de oportunidade o alvo não reage (o motor recusa; a sala tira-a)
    add('06-defender', 'Vlab.resolverAtaque', { atacante: atacante(), alvo: alvo({ reacaoDefensiva: { tipo: 'Defender', valor: 15, origem: 'fictício' } }), tecnica: TECNICAS[k], contexto: { semente: 6900 + k, verificacaoCritico: [3, 3, 3], ataqueDeOportunidade: true, niveisVantagem: 1 } });
  }
  for (let k = 0; k < 4; k += 1) { // sem reação: a defesa é a CA (o controlo)
    add('06-defender', 'Vlab.resolverAtaque', { atacante: atacante(), alvo: alvo({ ca: 15 }), tecnica: TECNICAS[k], contexto: { semente: 6950 + k, verificacaoCritico: [3, 3, 3] } });
  }

  // 09 — acumulação do DMG (Dmg.calcularDano): componentes por tipo, repartição, crítico (soma o máximo dos dados),
  //      faces dadas e semente; e as recusas nomeadas.
  const EXPR = ['1d4', '1d6+2', '2d6+4', '1d8+3', '3d10', '1d12-1', '4d6', '2d8+1d4+2'];
  const TIPOS = ['cortante', 'perfurante', 'fogo', 'frio', 'radiante'];
  let n9 = 0;
  for (let nComp = 1; nComp <= 3; nComp += 1) {
    for (let k = 0; k < 20; k += 1) {
      const componentes = Array.from({ length: nComp }, (_, i) => ({ tipo: TIPOS[(k + i) % TIPOS.length], expressao: EXPR[(k + 3 * i) % EXPR.length] }));
      add('09-acumulacao-dmg', 'Dmg.calcularDano', { componentes, contexto: { semente: 9000 + 53 * n9, critico: k % 4 === 1 } });
      n9 += 1;
    }
  }
  for (let k = 0; k < 16; k += 1) {
    const e = EXPR[k % EXPR.length];
    add('09-acumulacao-dmg', 'Dmg.calcularDano', { expressaoDano: e, tipos: [TIPOS[k % 5]], contexto: { semente: 9500 + k, critico: k % 2 === 0 } });
  }
  for (let k = 0; k < 8; k += 1) { // repartição: vários tipos, uma expressão por tipo
    add('09-acumulacao-dmg', 'Dmg.calcularDano', { expressaoDano: '3d6', tipos: ['fogo', 'cortante'], reparticao: [EXPR[k % 8], EXPR[(k + 2) % 8]], contexto: { semente: 9600 + k, critico: k % 3 === 0 } });
  }
  const FACES9 = [[1], [6], [3, 4], [2, 2, 2, 2], [8, 1], [6, 6]];
  const EXPR_FACES = ['1d6', '1d6+2', '2d4', '4d6', '1d8+1d4', '2d6'];
  FACES9.forEach((faces, k) => {
    add('09-acumulacao-dmg', 'Dmg.calcularDano', { expressaoDano: EXPR_FACES[k], tipos: ['cortante'], contexto: { faces, critico: k % 2 === 1 } });
    add('09-acumulacao-dmg', 'Dmg.calcularDano', { expressaoDano: EXPR_FACES[k], tipos: ['cortante'], contexto: { faces: [...faces, 1], critico: false } }); // FACES_A_MAIS
  });
  for (const e of [
    { tipos: ['fogo'], contexto: { semente: 1 } }, // sem expressão nem classificação
    { classificacao: 'Prata', tipos: ['fogo'], contexto: { semente: 1 } }, // sem posição FIP
    { classificacao: 'Ouro', posicaoFIP: 'Media', tipos: ['fogo'], contexto: { semente: 1 } }, // derivação sem expressão
    { expressaoDano: '1d6', tipos: ['fogo', 'frio'], contexto: { semente: 1 } }, // vários tipos sem repartição
    { expressaoDano: '1d6', tipos: ['fogo'], contexto: {} }, // sem faces nem semente
    { expressaoDano: '1d6', tipos: ['fogo'], contexto: { faces: [7] } }, // face fora do intervalo
  ]) add('09-acumulacao-dmg', 'Dmg.calcularDano', e);
  return g;
}

// ------------------------------------------------------------------------------------------------ os guiões da sala
function fichasComTransformacao(custo, forma) {
  const lista = listaDeFichas();
  const h = lista.find((f) => f.id === 'heroina-teste');
  h.paTotal = 20; h.vidaTotal = 60; h.ca = 12; // fictícios (os canários 4040, 5150 e 5551 da fixture não importam aqui: o guião não varre privacidade)
  h.transformacao = { custo, ...forma };
  const orc = lista.find((f) => f.id === 'orc-teste');
  orc.ca = 11; orc.rd = { geral: 0, porTipo: {} }; orc.vidaTotal = 200; // fictício e baixo: o ataque pode acertar
  const r = carregarFichas(lista);
  if (!r.ok) throw new Error('fichas fictícias inválidas: ' + JSON.stringify(r.erros));
  return r.fichas;
}

/** O que um passo da sala deixa: o recibo de quem pediu e os eventos que o Mestre recebeu (tipo e dados). */
function passo(m, acao) {
  const antes = m.clientes.mestre.msgs.length;
  const r = recibo(acao());
  const eventos = m.clientes.mestre.msgs.slice(antes).filter((x) => x.type === 'ROOM_EVENT').map((x) => ({ seq: x.seq, tipo: x.tipo, dados: x.dados }));
  return { recibo: r ? { type: r.type, estado: r.estado ?? null, motivo: r.motivo ?? null } : null, eventosMestre: json(eventos) };
}

export const GUIOES_SALA = Object.freeze({
  /** Transformação: a forma transformada sobrepõe a ficha (menos o custo), gasta PA e a acção padrão; depois ataca. */
  transformacao(motor, g) {
    const fichas = fichasComTransformacao(g.custo, g.forma);
    const m = montarMesa({ motor, fichas, rngSemente: rngDeterministico(g.semente) });
    m.entrarTodos();
    m.iniciarCombate([['orc-teste', { x: 2, y: 3 }]]);
    const h = m.clientes.heroina;
    const orc = h.idPorNome('Orc');
    const acoesAntes = json(h.opcoes.acoes);
    const transformar = passo(m, () => m.intencao('heroina', { tipo: 'transformar' }, { intentId: 'tr-1' }));
    const depois = { acoes: json(h.opcoes.acoes), ataques: json(h.opcoes.ataques.map((a) => ({ alvoId: a.alvoId === orc ? 'orc' : a.alvoId, arma: a.arma }))) };
    const armas = h.opcoes.ataques.filter((a) => a.alvoId === orc).map((a) => a.arma);
    // A acção padrão já foi gasta ao transformar: o ataque na mesma vez tem de ser recusado; na vez seguinte, passa.
    const atacarMesmaVez = passo(m, () => m.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: g.arma }, { intentId: 'tr-2' }));
    const encerrar = passo(m, () => m.intencao('heroina', { tipo: 'encerrar' }, { intentId: 'tr-3' }));
    for (let i = 0; i < 6; i += 1) { // a vez do orc (auto): os cartões dele, aprovados como o Mestre faria
      const aberto = m.sala.depuracao.estado().cartoes.find((c) => c.estado === 'aberto');
      if (!aberto) break;
      m.mestre('MASTER_APPROVE', { cartaoId: aberto.cartaoId, decisao: 'aprovar' });
    }
    const atacarVezSeguinte = passo(m, () => m.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: g.arma }, { intentId: 'tr-4' }));
    const estado = m.sala.depuracao.estado();
    const fig = estado.figuras[h.figuraId];
    return { acoesAntes, transformar, depois, armasContraOrc: armas, atacarMesmaVez, encerrar, atacarVezSeguinte, heroina: { transformada: fig.transformada, paGasto: fig.paGasto } };
  },

  /** Consumíveis: o que o servidor oferece hoje (nada) e o que faz com a intenção (recusa). Congela a AUSÊNCIA. */
  consumivel(motor, g) {
    const m = montarMesa({ motor, rngSemente: rngDeterministico(g.semente) });
    m.entrarTodos();
    m.iniciarCombate([['orc-teste', { x: 2, y: 3 }]]);
    const h = m.clientes.heroina;
    const alvos = { propria: h.figuraId, orc: h.idPorNome('Orc'), inexistente: 'figura-que-nao-existe' };
    const acao = { tipo: 'consumivel', itemId: g.itemId };
    if (g.alvo) acao.alvoId = alvos[g.alvo];
    if (g.foraDaVez) m.intencao('heroina', { tipo: 'encerrar' }, { intentId: 'cs-0' });
    const r = passo(m, () => m.intencao('heroina', acao, { intentId: 'cs-1' }));
    return { consumiveisOferecidos: json(h.opcoes?.consumiveis ?? null), ...r };
  },
});

function casosSala() {
  const g7 = [];
  const FORMAS = [
    { tecnicas: [{ id: 'garra-transformada', nome: 'Garra (fictícia)', expressaoAtaque: '1d20+6', expressaoDano: '2d8+3', tipo: 'cortante', custoPA: 0, alcanceM: 1.5, usaArma: false }], deslocamentoBase: 12 },
    { tecnicas: [{ id: 'garra-transformada', nome: 'Garra (fictícia)', expressaoAtaque: '1d20+9', componentes: [{ tipo: 'fogo', expressao: '1d10+2' }], tipos: ['fogo'], custoPA: 1, alcanceM: 1.5, usaArma: false }] },
    { tecnicas: [{ id: 'chicote-teste', nome: 'Chicote (forma fictícia)', expressaoAtaque: '1d20+8', expressaoDano: '1d6+6', tipo: 'cortante', custoPA: 2, alcanceM: 9, usaArma: true }] },
  ];
  for (const custo of [0, 3, 7, 18, 21]) { // 21 > 20 de PA: «transformar» não é oferecido, a intenção é recusada
    FORMAS.forEach((forma, i) => {
      for (const semente of [11, 12]) g7.push({ funcao: 'sala.transformacao', guiao: { custo, forma, arma: forma.tecnicas[0].id, semente: semente + 100 * i + custo } });
    });
  }
  const g8 = [];
  const ITENS = ['pocao-ficticia', 'erva-ficticia', 'bomba-ficticia', '', 'x'.repeat(64)];
  for (const itemId of ITENS) {
    for (const alvo of [null, 'propria', 'orc', 'inexistente']) g8.push({ funcao: 'sala.consumivel', guiao: { itemId, alvo, foraDaVez: false, semente: 800 + g8.length } });
  }
  for (const itemId of ITENS.slice(0, 3)) g8.push({ funcao: 'sala.consumivel', guiao: { itemId, alvo: 'propria', foraDaVez: true, semente: 850 + g8.length } });
  g8.push({ funcao: 'sala.consumivel', guiao: { itemId: 'x'.repeat(65), alvo: null, foraDaVez: false, semente: 899 } }); // formato: não gravada
  return { '07-transformacao': g7, '08-consumiveis': g8 };
}

// ------------------------------------------------------------------------------------------------ correr e serializar
export function executarCaso(motor, caso) {
  const [ns, fn] = caso.funcao.split('.');
  if (ns === 'sala') return json(GUIOES_SALA[fn](motor, json(caso.guiao)));
  const alvoNs = ns === 'Vlab' ? motor.Vlab : ns === 'Dmg' ? motor.Dmg : null;
  if (!alvoNs || typeof alvoNs[fn] !== 'function') throw new Error('função do motor desconhecida: ' + caso.funcao);
  try {
    return json(alvoNs[fn](json(caso.entrada)));
  } catch (e) {
    return { excecao: String(e?.message ?? e) };
  }
}

/** Todos os casos com a saída, por grupo (determinista: a mesma entrada e o mesmo motor dão os mesmos bytes). */
export function gerarCasos(motor) {
  const porGrupo = { ...casosMotor(), ...casosSala() };
  const out = {};
  for (const grupo of GRUPOS) {
    out[grupo] = porGrupo[grupo].map((c, i) => ({
      id: grupo.slice(0, 2) + '-' + String(i + 1).padStart(3, '0'),
      funcao: c.funcao,
      ...(c.entrada !== undefined ? { entrada: c.entrada } : {}),
      ...(c.guiao !== undefined ? { guiao: c.guiao } : {}),
      saida: executarCaso(motor, c),
    }));
  }
  return out;
}

/** Um ficheiro por grupo, um caso por linha (JSON canónico), LF. */
export function serializarGrupo(grupo, casos, motorSha256) {
  const cab = { formato: FORMATO, grupo, motorSha256, total: casos.length, nota: 'Só dados fictícios. Gerado por testes-motor-real/gerar-vetores.mjs; não editar à mão.' };
  const c = jsonCanonico(cab);
  return c.slice(0, -1) + ',"casos":[\n' + casos.map((x) => jsonCanonico(x)).join(',\n') + '\n]}\n';
}

/** Os ficheiros (nome → texto) e o manifesto, a partir do motor. */
export function gerarFicheiros(motor) {
  const sha = motor.MOTOR_SHA256;
  if (typeof sha !== 'string' || !/^[0-9a-f]{64}$/.test(sha)) throw new Error('o motor não traz MOTOR_SHA256');
  const casos = gerarCasos(motor);
  const ficheiros = {};
  const grupos = [];
  for (const grupo of GRUPOS) {
    const nome = grupo + '.json';
    ficheiros[nome] = serializarGrupo(grupo, casos[grupo], sha);
    grupos.push({ grupo, ficheiro: nome, casos: casos[grupo].length, sha256: sha256Hex(ficheiros[nome]) });
  }
  const manifesto = { formato: FORMATO, motorSha256: sha, grupos, total: grupos.reduce((s, x) => s + x.casos, 0) };
  ficheiros['MANIFESTO.json'] = JSON.stringify(manifesto, null, 2) + '\n';
  return ficheiros;
}
