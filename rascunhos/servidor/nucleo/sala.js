// Sala de mesa: um escritor por sala (protocolo v2 + ERRATA v0.2/v0.2.1),
// máquina de turnos do REF_7 (JV1.1-b) e porta dos motores (JV1.1-a).
//
// REGRAS DESTE ARQUIVO
//  - Não importa node:* (tem de rodar também no workerd).
//  - Os motores (Dmg, Vlab) entram INJETADOS em criarSala({motores}); nunca se importam.
//  - A aleatoriedade (rng, rngSemente) e o relógio (agora) entram injetados.
//  - Cada mensagem é processada numa secção síncrona: validar → aplicar → gravar, sem E/S (E-C9).
//  - O cliente nunca calcula regra: as opções saem daqui (ROOM_OPTIONS), por lugar.
//
// O que ainda não está feito está marcado com TODO(JV1.x) ou TODO(JV0.3) (motor real).

import { jsonCanonico, clonarJson, hex8, iguaisTempoConstante } from './util.js';
import { sha256Hex } from './sha256.js';
import { criarJournal, restaurarJournal } from './journal.js';
import { projetarEvento, projetarSnapshot, efeitoAmbiente, nomePublicoDe, visivelDe } from './projecao.js';

export const PROTOCOLO = 2;
export const CASA_M = 1.5;
export const MAX_INTENCOES_TURNO = 20; // E-C12, invariante 12
const MAX_CHECKPOINTS = 500;
const EPS = 1e-9;
const VIZ4 = Object.freeze([[1, 0], [-1, 0], [0, 1], [0, -1]]); // sem diagonais (REF_7 §3)

// §3.1 + `correr` (REF_7 §2). TODO(JV0.4 errata): acrescentar `correr` à tabela §3.1 do protocolo.
export const TIPOS_ACAO = Object.freeze([
  'mover', 'atacar', 'consumivel', 'defender', 'desvincular', 'transformar', 'reacao', 'encerrar', 'correr',
]);

// Textos fixos (E-P7: recusas indistinguíveis; nenhum número do Mestre).
export const TEXTOS_RECUSA = Object.freeze({
  revisao_antiga: 'O tabuleiro mudou. Escolha de novo.',
  fora_da_vez: 'Ainda não é a sua vez.',
  acao_invalida: 'Ação não disponível.',
  aguardando_mestre: 'O Mestre está decidindo.',
  sala_pausada: 'A mesa está em pausa.',
  formato: 'Mensagem mal formada.',
  intent_conflito: 'Este pedido já foi usado com outra ação.',
  cartao_aberto: 'Há um cartão por decidir.',
  revertido: 'A jogada foi desfeita pelo Mestre.',
});

const MODOS = Object.freeze(['manual', 'semi', 'auto']);
const DESGRACAS = Object.freeze(['cai', 'arma-cai', 'arma-quebra', 'acerta-se', 'quebra-corpo', 'acerta-amigo']);
const RESULTADOS = Object.freeze({
  acerto: 'acerto', erro: 'erro', critico: 'critico', falha_critica: 'falha_critica',
  // TODO(JV0.3): conferir os nomes reais que o VLAB devolve em `resultado`.
  falhaCritica: 'falha_critica',
});
const TIPOS_MESTRE = Object.freeze([
  'MASTER_LOBBY_SET', 'MASTER_START', 'MASTER_PLACE', 'MASTER_MODE', 'MASTER_ACT', 'MASTER_APPROVE',
  'MASTER_CONFIRM_DICE', 'MASTER_AMBIENTE', 'MASTER_SUPERVISOR', 'MASTER_PAUSE', 'MASTER_RESUME',
]);
const RE_ID = /^[A-Za-z0-9_-]{1,64}$/;
const CHAVES_MUNDO = Object.freeze(['fase', 'mapa', 'lobby', 'figuras', 'ordem', 'vezIdx', 'rodada', 'vez', 'ambiente', 'desfecho']);

/** Recusa terminal de uma intenção (E-C5): fica gravada como recibo RECUSADA. */
export class ErroRecusa extends Error {
  constructor(motivo, detalhe = null) {
    super(motivo);
    this.name = 'ErroRecusa';
    this.motivo = motivo;
    this.detalhe = detalhe; // só para o Mestre (evento interno `recusa`)
  }
}

const chaveRecibo = (seatId, id) => seatId + '\u0000' + id;
const arred = (x) => Math.round(x * 1000) / 1000;
const numeroOuNull = (x) => (typeof x === 'number' && Number.isFinite(x) ? x : null);

/** Formato de `acao` (§3.1). Chaves a mais → formato (o hashAcao fica estável). */
export function acaoBemFormada(a) {
  if (!a || typeof a !== 'object' || Array.isArray(a) || !TIPOS_ACAO.includes(a.tipo)) return false;
  const permitidas = {
    mover: ['tipo', 'destino'],
    atacar: ['tipo', 'alvoId', 'arma'],
    consumivel: ['tipo', 'itemId', 'alvoId'],
    reacao: ['tipo', 'reacaoId', 'aceitar'],
  }[a.tipo] ?? ['tipo'];
  if (Object.keys(a).some((k) => !permitidas.includes(k))) return false;
  switch (a.tipo) {
    case 'mover':
      return !!a.destino && typeof a.destino === 'object' && !Array.isArray(a.destino)
        && Object.keys(a.destino).every((k) => k === 'x' || k === 'y')
        && Number.isInteger(a.destino.x) && Number.isInteger(a.destino.y);
    case 'atacar':
      return typeof a.alvoId === 'string' && a.alvoId.length >= 1 && a.alvoId.length <= 64
        && typeof a.arma === 'string' && a.arma.length >= 1 && a.arma.length <= 64;
    case 'consumivel':
      return typeof a.itemId === 'string' && a.itemId.length <= 64 && (a.alvoId === undefined || typeof a.alvoId === 'string');
    case 'reacao':
      return typeof a.reacaoId === 'string' && a.reacaoId.length <= 64 && typeof a.aceitar === 'boolean';
    default:
      return true;
  }
}

function dadosFisicosBemFormados(d) {
  if (d === undefined || d === null) return true;
  if (typeof d !== 'object' || Array.isArray(d) || Object.keys(d).some((k) => k !== 'faces')) return false;
  // TODO(JV1.x M-28): validar o intervalo de cada face contra a expressão da técnica (ex.: 1..20 num d20).
  return Array.isArray(d.faces) && d.faces.length >= 1 && d.faces.length <= 10
    && d.faces.every((x) => Number.isInteger(x) && x >= 1 && x <= 100);
}

function acaoNasOpcoes(ops, acao) {
  switch (acao.tipo) {
    case 'mover':
      return ops.mover.some((o) => o.x === acao.destino.x && o.y === acao.destino.y);
    case 'atacar':
      return ops.ataques.some((o) => o.alvoId === acao.alvoId && o.arma === acao.arma);
    case 'consumivel':
      return ops.consumiveis.some((o) => o.itemId === acao.itemId && (acao.alvoId === undefined || (o.alvos ?? []).includes(acao.alvoId)));
    case 'reacao':
      return ops.reacoes.some((o) => o.reacaoId === acao.reacaoId);
    default:
      return ops.acoes.includes(acao.tipo);
  }
}

/**
 * Cria uma sala.
 * @param {Object} p
 * @param {{Dmg:Object, Vlab:Object, MOTOR_SHA256?:string, DMG_VERSAO?:string, LEVELUP_SHA?:string}} p.motores
 *        módulo embrulhado (servidor/motores/gerado/motores.mjs) ou um falso nos testes
 * @param {Object} p.fichas  mapa id → ficha, CONGELADO (saída de carregarFichas().fichas)
 * @param {() => number} p.rng  inteiro de 32 bits; em produção, CSPRNG (crypto.getRandomValues)
 * @param {() => number} [p.rngSemente]  gerador só das sementes (por omissão, o rng)
 * @param {() => number} p.agora  relógio do servidor, em ms
 * @param {(s:string|Uint8Array) => string} [p.hash]  SHA-256 hex (por omissão, o JS puro)
 * @param {Object} p.config  {roomId?, mapa?:{largura,altura}, lugares:[...], iniciativa:{fichaId:n}, modoPadrao?, reacaoDefender?, depurar?}
 * @param {string} [p.restaurarDe]  exportação do journal (restaura em vez de criar)
 * @param {string} [p.chaveJournal]  chave HMAC da exportação
 */
export function criarSala({
  motores, fichas, rng, rngSemente, agora, hash = sha256Hex, config = {}, restaurarDe = null, chaveJournal = null,
} = {}) {
  // ------------------------------------------------------------------ verificações de entrada
  if (!motores || !motores.Vlab || typeof motores.Vlab.resolverAtaque !== 'function') {
    throw new TypeError('criarSala: motores.Vlab.resolverAtaque em falta (injete o módulo embrulhado)');
  }
  if (!fichas || typeof fichas !== 'object' || !Object.isFrozen(fichas)) {
    throw new TypeError('criarSala: as fichas têm de vir congeladas do carregador (carregarFichas)');
  }
  if (typeof rng !== 'function') throw new TypeError('criarSala: rng em falta');
  if (typeof agora !== 'function') throw new TypeError('criarSala: agora em falta');

  const sortearSemente = typeof rngSemente === 'function' ? rngSemente : rng;
  const depurar = config.depurar === true;
  const modoPadrao = MODOS.includes(config.modoPadrao) ? config.modoPadrao : 'auto';
  const iniciativa = Object.freeze({ ...(config.iniciativa ?? {}) }); // valores só do Mestre (vivem na memória)
  const lugaresConfig = Array.isArray(config.lugares) ? config.lugares : [];
  const largura = Number.isInteger(config.mapa?.largura) ? config.mapa.largura : 20; // v1: ≥ 20×20
  const altura = Number.isInteger(config.mapa?.altura) ? config.mapa.altura : 20;
  const motoresInfo = Object.freeze({
    vlabSha: motores.MOTOR_SHA256 ?? null,
    dmgVersao: motores.DMG_VERSAO ?? null,
    levelupSha: motores.LEVELUP_SHA ?? null,
  });

  if (lugaresConfig.filter((l) => l.papel === 'mestre').length !== 1) {
    throw new TypeError('criarSala: tem de haver exatamente um lugar de Mestre');
  }
  lugaresConfig.forEach((l, i) => {
    if (!['jogadora', 'espectador', 'mestre'].includes(l.papel)) throw new TypeError(`criarSala: lugar ${i}: papel inválido`);
    if (l.papel === 'mestre' && !(typeof l.pin === 'string' && /^\d{6,}$/.test(l.pin))) {
      throw new TypeError('criarSala: o PIN do Mestre tem de ter 6 dígitos ou mais (E-P9)');
    }
    if (l.papel === 'jogadora' && (!fichas[l.fichaId] || fichas[l.fichaId].papel !== 'jogadora')) {
      throw new TypeError(`criarSala: lugar ${i}: fichaId de jogadora inválido`);
    }
  });

  // ------------------------------------------------------------------ memória que NÃO vai ao journal
  // PIN e senhas: só o hash com sal, só em memória (E-P13: nunca entram no journal).
  const credenciais = new Map();
  lugaresConfig.forEach((l, i) => {
    const segredo = l.papel === 'mestre' ? l.pin : l.senha;
    if (typeof segredo === 'string' && segredo.length > 0) {
      const sal = hex8(rng()) + hex8(rng());
      credenciais.set(i, { sal, hash: hash(sal + '\u0000' + segredo) });
    }
  });
  const conexoes = new Map(); // seatId → nº de ligações vivas
  const tentativas = new Map(); // travão do ROOM_JOIN (E-P9)
  const ritmo = new Map(); // seatId → carimbos (10 intenções/s)
  const checkpoints = new Map(); // journalSeq → mundo (para MASTER_SUPERVISOR voltar)
  const fila = [];
  let drenando = false;

  // ------------------------------------------------------------------ journal
  let roomId = typeof config.roomId === 'string' ? config.roomId : 'sala-' + hex8(rng());
  let journal;
  if (restaurarDe) {
    journal = restaurarJournal(restaurarDe, { chave: chaveJournal ?? undefined, hash });
    roomId = journal.estado.roomId;
  } else {
    journal = criarJournal({ estadoInicial: construirEstadoInicial(), hash });
  }
  guardarCheckpoint();
  if (restaurarDe && (journal.estado.motores?.vlabSha ?? null) !== motoresInfo.vlabSha) {
    // E-C11: versão de motor diferente ao acordar → ROOM_PAUSED {manutencao}.
    // TODO(JV3.x): procedimento de migração de versão do motor (o Mestre decide).
    transacao((tx) => pausar(tx, 'manutencao', 'motor'));
  }

  // =================================================================== utilitários
  function u32() {
    return rng() >>> 0;
  }
  function novoId(prefixo, existentes) {
    // E-P14: ids opacos e aleatórios por sala.
    for (;;) {
      const id = prefixo + hex8(u32()) + hex8(u32());
      if (!existentes || !(id in existentes)) return id;
    }
  }
  function novoToken() {
    return hex8(u32()) + hex8(u32()) + hex8(u32()) + hex8(u32()); // 128 bits
  }
  function d6() {
    const limite = Math.floor(0x100000000 / 6) * 6; // rejeição: sem viés de módulo
    for (;;) {
      const x = u32();
      if (x < limite) return 1 + (x % 6);
    }
  }
  function isoAgora() {
    return new Date(agora()).toISOString();
  }
  function msgErro(codigo, texto) {
    return { v: PROTOCOLO, type: 'ERRO', roomId, codigo, texto };
  }
  function rejeicaoNaoGravada(idCampo, id, motivo) {
    return { v: PROTOCOLO, type: 'ROOM_REJECT', roomId, [idCampo]: id, motivo, texto: TEXTOS_RECUSA[motivo] };
  }

  // =================================================================== estado inicial
  function novaFigura(id, ficha, casa) {
    const lado = ficha.papel; // jogadora | criatura | npc
    return {
      id, fichaId: ficha.id, lado, colocada: false,
      x: Number.isInteger(casa?.x) ? casa.x : 0, y: Number.isInteger(casa?.y) ? casa.y : 0, orientacao: 'S',
      casaInicial: casa && Number.isInteger(casa.x) && Number.isInteger(casa.y) ? { x: casa.x, y: casa.y } : null,
      vidaActual: ficha.vidaTotal, paGasto: 0, vivo: true, caido: false, estadoMorte: null,
      armaCaida: false, armaQuebrada: false, corpoPartido: false, transformada: false,
      reacaoDisponivel: true, defendendo: false,
      modo: lado === 'jogadora' ? null : modoPadrao, // H10, nunca projetado (E-P11)
    };
  }

  function construirEstadoInicial() {
    const lugares = {};
    const figuras = {};
    lugaresConfig.forEach((l, i) => {
      const seatId = novoId('s', lugares);
      let figuraId = null;
      if (l.papel === 'jogadora') {
        figuraId = novoId('f', figuras);
        figuras[figuraId] = novaFigura(figuraId, fichas[l.fichaId], l.casa);
      }
      lugares[seatId] = {
        seatId, indice: i, papel: l.papel, nome: typeof l.nome === 'string' ? l.nome : null, figuraId,
        seq: 0, revision: 0, revisaoHash: null, tokenHash: null, epoch: 0,
      };
    });
    const estado = {
      formato: 'sala/1', roomId, fase: 'lobby', pausa: null,
      mapa: { largura, altura, casaM: CASA_M },
      lobby: null, figuras, ordem: [], vezIdx: -1, rodada: 0, vez: null,
      ambiente: { hora: null, clima: null, futuro: null },
      cartoes: [], contadores: { cartao: 0, ia: 0 }, lugares, motores: { ...motoresInfo }, desfecho: null,
    };
    atualizarRevisoes(estado);
    return estado;
  }

  // =================================================================== leitura do mundo
  function fichaDe(f) {
    return fichas[f.fichaId];
  }
  function fichaEfetiva(f) {
    const base = fichas[f.fichaId];
    if (f.transformada && base.transformacao && typeof base.transformacao === 'object') {
      // TODO(JV1.x): formato exato de `transformacao` (ficha parcial). Hoje: sobrepõe os campos, menos `custo`.
      const { custo, ...sobre } = base.transformacao;
      return { ...base, ...sobre };
    }
    return base;
  }
  function ehFraca(f) {
    return f.vidaActual * 10 < fichaDe(f).vidaTotal; // REF_7 §5
  }
  function reservaBase(f) {
    // Metade se Fraca, metade se corpo partido; acumulam. B7 corrigido: vale também para a IA.
    let b = fichaEfetiva(f).deslocamentoBase;
    if (ehFraca(f)) b /= 2;
    if (f.corpoPartido) b /= 2;
    return b;
  }
  function paLivre(f) {
    // TODO(JV1.x): "comprometido" da alma (REF_7 §7) ainda não modelado.
    return fichaDe(f).paTotal - f.paGasto;
  }
  function colocadas(m) {
    return Object.values(m.figuras).filter((f) => f.colocada);
  }
  function chaveCasa(x, y) {
    return x + ',' + y;
  }
  function dentro(m, x, y) {
    return Number.isInteger(x) && Number.isInteger(y) && x >= 0 && y >= 0 && x < m.mapa.largura && y < m.mapa.altura;
  }
  function ocupada(m, x, y) {
    return colocadas(m).some((f) => f.x === x && f.y === y);
  }
  function saoInimigos(a, b) {
    // TODO(JV1.x): NPC aliado. Hoje todo NPC é do lado das criaturas.
    return (a.lado === 'jogadora') !== (b.lado === 'jogadora');
  }
  function adjacentes(a, b) {
    return Math.abs(a.x - b.x) + Math.abs(a.y - b.y) === 1;
  }
  function distanciaM(a, b) {
    return Math.hypot(a.x - b.x, a.y - b.y) * CASA_M;
  }
  function cartaoAtivo(m) {
    return m.cartoes.find((c) => c.estado === 'aberto') ?? null; // FIFO: o primeiro aberto
  }
  function monstrosAdjacentes(m, casa, jogadora) {
    // Monstro caído não provoca ataque de oportunidade (REF_7 §3).
    return colocadas(m).filter(
      (x) => x.id !== jogadora.id && x.vivo && !x.caido && saoInimigos(jogadora, x) && adjacentes(casa, x),
    );
  }
  function iniciativaDe(fichaId) {
    // TODO(JV0.6a errata): `iniciativa` ainda não é campo da ficha; vem da config do Mestre.
    return Number.isFinite(iniciativa[fichaId]) ? iniciativa[fichaId] : 0;
  }

  /** BFS de 4 vizinhos. Figuras vivas bloqueiam; cadáveres NÃO (IBX-212 J12/J13). */
  function bfs(m, origem, maxCasas, proprioId) {
    const bloqueia = new Set();
    const ocupadas = new Set();
    for (const f of colocadas(m)) {
      if (f.id === proprioId) continue;
      const k = chaveCasa(f.x, f.y);
      ocupadas.add(k);
      if (f.vivo) bloqueia.add(k);
    }
    const k0 = chaveCasa(origem.x, origem.y);
    const dist = new Map([[k0, 0]]);
    const pai = new Map();
    const casas = new Map([[k0, { x: origem.x, y: origem.y }]]);
    const filaBfs = [{ x: origem.x, y: origem.y }];
    for (let i = 0; i < filaBfs.length; i++) {
      const c = filaBfs[i];
      const kc = chaveCasa(c.x, c.y);
      const d = dist.get(kc);
      if (d >= maxCasas) continue;
      for (const [dx, dy] of VIZ4) {
        const x = c.x + dx;
        const y = c.y + dy;
        if (!dentro(m, x, y)) continue;
        const k = chaveCasa(x, y);
        if (dist.has(k) || bloqueia.has(k)) continue;
        dist.set(k, d + 1);
        pai.set(k, kc);
        casas.set(k, { x, y });
        filaBfs.push({ x, y });
      }
    }
    return { dist, pai, casas, ocupadas, k0 };
  }
  function caminhoAte(r, k) {
    const lista = [];
    let atual = k;
    while (atual !== undefined) {
      lista.push(r.casas.get(atual));
      if (atual === r.k0) break;
      atual = r.pai.get(atual);
    }
    return lista.reverse();
  }

  /** Metros do Correr, ou null se o motor recusar. Opção honesta: só aparece se der. */
  function metrosCorrida(f) {
    const base = reservaBase(f);
    const fn = motores.Vlab.validarCorrer;
    if (typeof fn !== 'function') {
      // TODO(JV1.x R0): regra do Correr sem o motor. Provisório: o dobro da reserva base.
      return arred(base * 2);
    }
    // TODO(JV0.3): assinatura real de Vlab.validarCorrer (nos vetores-ouro).
    let r;
    try {
      r = fn({ deslocamentoBase: base, jaAndou: false, jaAtacou: false });
    } catch {
      return null;
    }
    if (!r || r.valido === false || r.erro) return null;
    const metros = r.deslocamentoM ?? r.metros ?? r.reservaM;
    return typeof metros === 'number' && Number.isFinite(metros) && metros >= 0 ? arred(metros) : null;
  }

  function opcoesVazias(m) {
    return { vezId: m.vez?.figuraId ?? null, orcamentoM: 0, mover: [], ataques: [], consumiveis: [], acoes: [], reacoes: [] };
  }

  /**
   * ROOM_OPTIONS de uma figura, calculadas sobre o mundo projetado (E-P6).
   * Invariante 11: toda a opção daqui, enviada na sua revisão, dá APLICADA.
   */
  function calcularOpcoes(m, figuraId) {
    if (m.fase !== 'combate' || !m.vez || m.vez.figuraId !== figuraId) return opcoesVazias(m);
    const f = m.figuras[figuraId];
    const v = m.vez;
    const ficha = fichaEfetiva(f);
    if (f.lado === 'jogadora' && f.estadoMorte?.fase === 'aMorrer') {
      return { ...opcoesVazias(m), vezId: figuraId, acoes: ['encerrar'] }; // a vez dela foi o teste de morte
    }

    const mover = [];
    const maxCasas = Math.floor(v.reservaM / CASA_M + EPS);
    if (maxCasas > 0) {
      const r = bfs(m, f, maxCasas, f.id);
      for (const [k, d] of r.dist) {
        if (d === 0 || r.ocupadas.has(k)) continue; // não se acaba em cima de ninguém (nem de cadáver)
        const c = r.casas.get(k);
        mover.push({ x: c.x, y: c.y, custoM: arred(d * CASA_M) });
      }
      mover.sort((a, b) => a.custoM - b.custoM || a.y - b.y || a.x - b.x);
    }

    const ataques = [];
    if (!v.atacou) {
      for (const t of ficha.tecnicas) {
        if (t.usaArma && f.armaQuebrada) continue;
        // TODO(JV1.x): a jogadora apanha a arma caída com o movimento (REF_7 §4). Hoje: sem ataque com arma.
        if (t.usaArma && f.armaCaida && f.lado === 'jogadora') continue;
        if (f.lado === 'jogadora' && t.custoPA > paLivre(f)) continue; // os monstros não gastam PA
        for (const alvo of colocadas(m)) {
          if (alvo.id === f.id || !alvo.vivo || !saoInimigos(f, alvo)) continue;
          // B9 corrigido: métrica de grelha euclidiana × 1,5 m, e não o caminho a pé.
          // TODO(JV1.x C-42): linha de visão por supercover.
          if (distanciaM(f, alvo) > t.alcanceM + EPS) continue;
          ataques.push({ alvoId: alvo.id, arma: t.id });
        }
      }
    }

    const acoes = ['encerrar'];
    // Correr: substitui a reserva; só se ainda não andou nem atacou.
    if (!v.atacou && v.andouM === 0 && !v.correrUsado && metrosCorrida(f) !== null) acoes.push('correr');
    if (f.lado === 'jogadora') {
      if (f.reacaoDisponivel && !f.defendendo) acoes.push('defender');
      if (!v.atacou && !v.desvinculou && monstrosAdjacentes(m, f, f).length > 0) acoes.push('desvincular');
      const tr = fichaDe(f).transformacao;
      const custoTr = Number.isInteger(tr?.custo) ? tr.custo : 0;
      if (!v.atacou && tr && !f.transformada && custoTr <= paLivre(f)) acoes.push('transformar');
    }
    // TODO(JV1.x): consumíveis (REF_7 §9.10: ainda sem conteúdo) e reações (A-4: janela de reação).
    return { vezId: figuraId, orcamentoM: arred(v.reservaM), mover, ataques, consumiveis: [], acoes, reacoes: [] };
  }

  function destinatario(s) {
    return { papel: s.papel, figuraId: s.figuraId, seatId: s.seatId };
  }

  /** Opções que este lugar recebe agora (ou null). Com cartão aberto, ninguém tem opções. */
  function opcoesDoLugar(m, s) {
    if (m.fase !== 'combate' || !m.vez || cartaoAtivo(m)) return null;
    const vezFig = m.figuras[m.vez.figuraId];
    if (s.papel === 'jogadora') return s.figuraId === vezFig.id ? calcularOpcoes(m, vezFig.id) : null;
    if (s.papel === 'mestre') return vezFig.lado !== 'jogadora' ? calcularOpcoes(m, vezFig.id) : null;
    return null;
  }

  /**
   * E-P5: revision por lugar = contador que só sobe quando muda o hash da VISTA desse lugar
   * (snapshot projetado + opções). Mudança oculta (ex.: MASTER_MODE) não mexe na Party.
   */
  function atualizarRevisoes(m) {
    const mudaram = new Set();
    for (const s of Object.values(m.lugares)) {
      const vista = { snap: projetarSnapshot(m, fichas, destinatario(s)), opcoes: opcoesDoLugar(m, s) };
      const h = hash(jsonCanonico(vista));
      if (h !== s.revisaoHash) {
        s.revision += 1;
        s.revisaoHash = h;
        mudaram.add(s.seatId);
      }
    }
    return mudaram;
  }

  // =================================================================== mensagens
  function mensagemSnapshot(m, s, ts) {
    return { v: PROTOCOLO, type: 'ROOM_SNAPSHOT', roomId, seq: s.seq, revision: s.revision, ts, ...projetarSnapshot(m, fichas, destinatario(s)) };
  }
  function mensagemOpcoes(s, o) {
    return { v: PROTOCOLO, type: 'ROOM_OPTIONS', roomId, revision: s.revision, ...o };
  }
  function mensagemVistaMestre() {
    const m = journal.estado;
    const s = Object.values(m.lugares).find((x) => x.papel === 'mestre');
    return { v: PROTOCOLO, type: 'MASTER_VIEW', roomId, journalSeq: journal.journalSeq, ...projetarSnapshot(m, fichas, destinatario(s)) };
  }
  function mensagemCartao(c) {
    return {
      v: PROTOCOLO, type: 'MASTER_CARD', roomId, cartaoId: c.cartaoId, tipo: c.tipo, figuraId: c.figuraId ?? null,
      proposta: clonarJson(c.proposta ?? null), razao: c.razao ?? null, faces: clonarJson(c.faces ?? null),
      intentIdOrigem: c.origem?.id ?? null,
    };
  }
  /** Recibo → mensagem. Só campos da lista; nada do motor (E-P1). Determinista (mesmos bytes no reenvio). */
  function mensagemDoRecibo(r) {
    const idCampo = r.idCampo ?? 'intentId';
    if (r.estado === 'RECUSADA' && !r.revertidaEm) {
      return {
        v: PROTOCOLO, type: 'ROOM_REJECT', roomId, [idCampo]: r.id, motivo: r.motivo,
        texto: TEXTOS_RECUSA[r.motivo] ?? TEXTOS_RECUSA.acao_invalida,
      };
    }
    const msg = { v: PROTOCOLO, type: 'ROOM_RECEIPT', roomId, [idCampo]: r.id, estado: r.estado, seq: r.seq, revision: r.revision };
    if (r.estado === 'RECUSADA') msg.motivo = r.motivo;
    if (r.revertidaEm) msg.revertidaEm = r.revertidaEm; // carimbo de hora, nunca o journalSeq
    return msg;
  }
  function lugarDoMestre(m) {
    return Object.values(m.lugares).find((s) => s.papel === 'mestre');
  }
  function alertaMestre(motivo, extra = {}) {
    const s = lugarDoMestre(journal.estado);
    return s ? [{ seatId: s.seatId, msg: { v: PROTOCOLO, type: 'MASTER_ALERTA', roomId, motivo, ...extra } }] : [];
  }

  // =================================================================== transação (gravado junto)
  /**
   * Corre `fn(tx)` sobre uma CÓPIA do estado. Se lançar, nada fica (princípio 8).
   * Se não, projeta, numera por destinatário e grava evento + estado + recibo de uma vez.
   */
  function transacao(fn) {
    const antes = journal.estado;
    const tx = {
      estado: clonarJson(antes),
      eventos: [],
      recibos: [],
      fluxos: {},
      saidas: [],
      opcoesForcadas: new Set(),
      anuncio: null,
      snapshotsTodos: false,
      ts: isoAgora(),
      baseSeq: journal.journalSeq,
    };
    tx.emitir = (tipo, dados, soMestre) => {
      const ev = {
        journalSeq: tx.baseSeq + tx.eventos.length + 1,
        ts: tx.ts,
        tipo,
        dados: clonarJson(dados ?? {}),
        soMestre: soMestre === undefined || soMestre === null ? null : clonarJson(soMestre),
      };
      tx.eventos.push(ev);
      return ev;
    };
    const cartaoAntes = cartaoAtivo(antes)?.cartaoId ?? null;
    const resultado = fn(tx);
    finalizar(tx, cartaoAntes);
    journal.commit({
      estado: tx.estado,
      eventos: tx.eventos,
      recibos: tx.recibos.map((r) => [r.chave, r.recibo]),
      fluxos: tx.fluxos,
    });
    if (tx.eventos.length) guardarCheckpoint();
    return { saidas: tx.saidas, resultado };
  }

  function finalizar(tx, cartaoAntes) {
    const m = tx.estado;
    const mudaram = atualizarRevisoes(m);
    const lugares = Object.values(m.lugares);
    // 1) eventos, projetados e numerados POR DESTINATÁRIO (E-P4)
    for (const ev of tx.eventos) {
      for (const s of lugares) {
        const dados = projetarEvento(ev, destinatario(s));
        if (dados === null) continue;
        s.seq += 1;
        const msg = { v: PROTOCOLO, type: 'ROOM_EVENT', roomId, seq: s.seq, revision: s.revision, ts: ev.ts, tipo: ev.tipo, dados };
        (tx.fluxos[s.seatId] ??= []).push(msg);
        tx.saidas.push({ seatId: s.seatId, msg });
      }
    }
    // 2) snapshots (depois de um "voltar")
    if (tx.snapshotsTodos) for (const s of lugares) tx.saidas.push({ seatId: s.seatId, msg: mensagemSnapshot(m, s, tx.ts) });
    // 3) recibos (E-C7: por socket, primeiro os eventos, depois o recibo)
    for (const r of tx.recibos) {
      const s = m.lugares[r.recibo.seatId];
      r.recibo.seq = s ? s.seq : 0;
      r.recibo.revision = s ? s.revision : 0;
      r.recibo.journalSeq = tx.baseSeq + tx.eventos.length;
      if (r.enviar && s) tx.saidas.push({ seatId: s.seatId, msg: mensagemDoRecibo(r.recibo) });
    }
    // 4) opções novas (revisão mudou, ou recusa por revisao_antiga)
    for (const s of lugares) {
      if (!mudaram.has(s.seatId) && !tx.opcoesForcadas.has(s.seatId)) continue;
      const o = opcoesDoLugar(m, s);
      if (o) tx.saidas.push({ seatId: s.seatId, msg: mensagemOpcoes(s, o) });
    }
    // 5) cartão que passou a ativo → MASTER_CARD (só o Mestre)
    const ativo = cartaoAtivo(m);
    if (ativo && ativo.cartaoId !== cartaoAntes) {
      for (const s of lugares) if (s.papel === 'mestre') tx.saidas.push({ seatId: s.seatId, msg: mensagemCartao(ativo) });
    }
    // 6) pausa / retomada (não são ROOM_EVENT: não gastam seq)
    if (tx.anuncio) {
      for (const s of lugares) {
        tx.saidas.push({ seatId: s.seatId, msg: { v: PROTOCOLO, type: tx.anuncio.type, roomId, motivo: tx.anuncio.motivo } });
      }
    }
  }

  function mundoDe(m) {
    const o = {};
    for (const k of CHAVES_MUNDO) o[k] = clonarJson(m[k]) ?? null;
    if (m.fase === 'pausa' && m.pausa) o.fase = m.pausa.faseAnterior;
    return o;
  }
  function guardarCheckpoint() {
    // TODO(JV1.x): os checkpoints vivem só em memória; depois de restaurar, o "voltar" só alcança o que vier depois.
    checkpoints.set(journal.journalSeq, mundoDe(journal.estado));
    while (checkpoints.size > MAX_CHECKPOINTS) checkpoints.delete(checkpoints.keys().next().value);
  }

  // =================================================================== regras de jogo (dentro de tx)
  function pausar(tx, motivo, origem) {
    const m = tx.estado;
    if (m.fase === 'pausa' || m.fase === 'fim') return false;
    m.pausa = { motivo, origem, faseAnterior: m.fase };
    m.fase = 'pausa';
    tx.emitir('pausa', { motivo }, { origem });
    tx.anuncio = { type: 'ROOM_PAUSED', motivo };
    return true;
  }
  function retomar(tx) {
    const m = tx.estado;
    if (m.fase !== 'pausa') return false;
    const motivo = m.pausa.motivo;
    m.fase = m.pausa.faseAnterior;
    m.pausa = null;
    tx.emitir('retomada', { motivo }, null);
    tx.anuncio = { type: 'ROOM_RESUMED', motivo };
    return true;
  }

  function abrirCartao(tx, dados) {
    const m = tx.estado;
    m.contadores.cartao += 1;
    const c = { cartaoId: 'c' + m.contadores.cartao, estado: 'aberto', decisao: null, ...clonarJson(dados) };
    m.cartoes.push(c);
    tx.emitir('cartao', { cartaoId: c.cartaoId, tipo: c.tipo }, c); // a semente fica gravada aqui
    return c;
  }
  function fecharCartao(tx, c, decisao) {
    c.estado = 'fechado';
    c.decisao = decisao;
    tx.emitir('cartao_fechado', { cartaoId: c.cartaoId, decisao }, null);
  }

  function emitirEstado(tx, f, forcar, visAntes, vidaAntes) {
    const vis = visivelDe(f);
    const ehJog = f.lado === 'jogadora';
    if (!forcar && vis === visAntes && !(ehJog && f.vidaActual !== vidaAntes)) return;
    const dados = { figuraId: f.id, visivel: vis };
    if (ehJog) {
      // Só a própria recebe estes (lista `propria` da projeção).
      dados.vidaActual = f.vidaActual;
      dados.paLivre = paLivre(f);
      dados.estadoMorte = f.estadoMorte;
    }
    tx.emitir('estado', dados, ehJog ? null : { vidaActual: f.vidaActual, estadoMorte: f.estadoMorte });
  }

  function iniciarVez(tx, f) {
    const m = tx.estado;
    f.reacaoDisponivel = true; // uma reação por ronda
    f.defendendo = false; // a declaração de Defender anterior expira
    m.vez = {
      figuraId: f.id, atacou: false, andouM: 0, reservaM: 0, correrUsado: false, desvinculou: false,
      iaMoveu: false, iaPausada: false, recusas: 0, intencoes: 0,
    };
    tx.emitir('turno', { figuraId: f.id, rodada: m.rodada, narra: f.lado !== 'jogadora' }, { modo: f.modo });
    if (f.lado === 'jogadora' && f.estadoMorte?.fase === 'aMorrer') {
      // A Ong nunca sai da ordem: a vez dela vira teste de morte.
      m.vez.atacou = true;
      testeDeMorte(tx, f);
      return;
    }
    if (f.caido) {
      // Caída levanta-se e gasta a reserva toda. B6 corrigido: o monstro também se levanta.
      const vis = visivelDe(f);
      const vida = f.vidaActual;
      f.caido = false;
      emitirEstado(tx, f, false, vis, vida);
      m.vez.reservaM = 0;
    } else {
      m.vez.reservaM = arred(reservaBase(f)); // nasce cheia e não acumula
    }
  }

  function testeDeMorte(tx, f) {
    const fn = motores.Vlab.resolverTesteDeMorte;
    if (typeof fn !== 'function') return; // TODO(JV0.3): motor sem teste de morte → a vez fica só com `encerrar`
    const ctx = { semente: sortearSemente() >>> 0 };
    let saida;
    try {
      // TODO(JV0.3): assinatura e forma da saída de resolverTesteDeMorte nos vetores-ouro.
      saida = fn({ moribundo: entidadeMotor(f), contexto: clonarJson(ctx) });
    } catch (e) {
      saida = { erro: 'EXCECAO:' + (e?.message ?? String(e)) };
    }
    if (!saida || typeof saida !== 'object' || saida.erro) {
      tx.emitir('erro_motor', { figuraId: f.id }, { erro: String(saida?.erro ?? 'SAIDA_INVALIDA'), contexto: ctx });
      return;
    }
    aplicarDepois(f, saida.soDoMestre?.moribundoDepois ?? saida.soDoMestre?.alvoDepois);
    tx.emitir('teste_morte', { figuraId: f.id }, { semente: ctx.semente, saida });
    emitirEstado(tx, f, true);
    verificarFim(tx);
  }

  function verificarFim(tx) {
    const m = tx.estado;
    if (m.fase !== 'combate') return m.fase === 'fim';
    const todas = colocadas(m);
    const jog = todas.filter((f) => f.lado === 'jogadora');
    const mon = todas.filter((f) => f.lado !== 'jogadora');
    let desfecho = null;
    if (jog.length && jog.every((f) => !f.vivo)) desfecho = 'morte';
    // TODO(JV1.x): a vitória é automática quando todas as criaturas COLOCADAS caem; o Mestre pode querer pôr mais.
    else if (mon.length && mon.every((f) => !f.vivo)) desfecho = 'vitoria';
    // TODO(JV1.x R0 §9.7): "estabilizada" é derrota?
    if (!desfecho) return false;
    m.fase = 'fim';
    m.desfecho = desfecho;
    m.vez = null;
    tx.emitir('fim', { desfecho }, null);
    return true;
  }

  function avancarVez(tx) {
    const m = tx.estado;
    if (verificarFim(tx)) return;
    const n = m.ordem.length;
    for (let passo = 0; passo < n; passo++) {
      m.vezIdx += 1;
      if (m.vezIdx >= n) {
        m.vezIdx = 0;
        m.rodada += 1; // a rodada sobe ao dar a volta
      }
      const f = m.figuras[m.ordem[m.vezIdx]];
      if (!f || !f.colocada || !f.vivo) continue; // monstro morto sai da ordem; caído não sai
      iniciarVez(tx, f);
      return;
    }
    m.vez = null;
  }

  function ordenarPorIniciativa(ids, m) {
    // Fixa e sem rolagem; empate fica na ordem de entrada (o sort é estável). Nunca se recalcula.
    return ids.slice().sort((a, b) => iniciativaDe(m.figuras[b].fichaId) - iniciativaDe(m.figuras[a].fichaId));
  }
  function inserirNaOrdem(m, id) {
    const ini = iniciativaDe(m.figuras[id].fichaId);
    let pos = m.ordem.length;
    for (let i = 0; i < m.ordem.length; i++) {
      if (iniciativaDe(m.figuras[m.ordem[i]].fichaId) < ini) {
        pos = i;
        break;
      }
    }
    m.ordem.splice(pos, 0, id);
    if (pos <= m.vezIdx) m.vezIdx += 1; // a vez corrente não muda
  }

  // ------------------------------------------------------------------ ponte para o motor
  function entidadeMotor(f) {
    const ficha = fichaEfetiva(f);
    const estado = [];
    // TODO(JV0.3): nomes exatos dos estados que o VLAB lê.
    if (f.caido) estado.push('caido');
    if (ehFraca(f)) estado.push('fraco');
    if (f.corpoPartido) estado.push('corpoPartido');
    return {
      ...ficha,
      vidaActual: f.vidaActual,
      paLivre: f.lado === 'jogadora' ? paLivre(f) : ficha.paTotal,
      estado,
      estadoMorte: clonarJson(f.estadoMorte),
      armaCaida: f.armaCaida,
      armaQuebrada: f.armaQuebrada,
    };
  }

  function flanqueia(m, atacante, alvo) {
    // REF_7: qualquer figura no lado oposto do alvo. Servidor: cadáveres não dão flanqueamento.
    if (!adjacentes(atacante, alvo)) return false;
    const x = 2 * alvo.x - atacante.x;
    const y = 2 * alvo.y - atacante.y;
    return colocadas(m).some((f) => f.id !== atacante.id && f.id !== alvo.id && f.vivo && f.x === x && f.y === y);
  }

  function montarContexto(m, atacante, alvo, extra) {
    const ctx = {
      semente: sortearSemente() >>> 0, // uma por resolução, gravada no evento
      verificacaoCritico: [d6(), d6(), d6()], // errata JV1.1-a §6: o servidor gera-a por CSPRNG
      modoDesgraca: atacante.lado === 'jogadora' ? 'proposta' : 'sorte',
      niveisVantagem: extra.niveisVantagem ?? 0,
      niveisDesvantagem: atacante.corpoPartido ? 1 : 0,
      ataqueDeOportunidade: !!extra.ataqueDeOportunidade,
      flanqueando: atacante.lado !== 'jogadora' && alvo.lado === 'jogadora' ? flanqueia(m, atacante, alvo) : false,
      atacanteCaido: !!atacante.caido,
      atacanteFraco: ehFraca(atacante),
    };
    if (atacante.lado !== 'jogadora' && atacante.armaCaida) ctx.armaRecuperada = true;
    // Errata JV1.1-a §4: NUNCA enviar modificador de crítico (defeito latente MASTER_DECISIONS).
    // TODO(JV1.x R0): valor da reação Defender. Hoje só se a config do Mestre o der.
    if (!extra.semReacaoDefensiva && alvo.defendendo && config.reacaoDefender) {
      ctx.reacaoDefensiva = clonarJson(config.reacaoDefender);
    }
    return ctx;
  }

  function chamarMotorAtaque(atacante, alvo, t, ctx) {
    let saida;
    try {
      // TODO(JV0.3): confirmar nos vetores-ouro a assinatura de Vlab.resolverAtaque (objeto único).
      saida = motores.Vlab.resolverAtaque({
        atacante: entidadeMotor(atacante), alvo: entidadeMotor(alvo), tecnica: t, contexto: clonarJson(ctx),
      });
    } catch (e) {
      return { erro: 'EXCECAO:' + (e?.message ?? String(e)) };
    }
    if (!saida || typeof saida !== 'object') return { erro: 'SAIDA_INVALIDA' };
    if (saida.erro) return { erro: typeof saida.erro === 'string' ? saida.erro : String(saida.erro.codigo ?? 'ERRO') };
    if (!Object.prototype.hasOwnProperty.call(RESULTADOS, saida.resultado)) return { erro: 'RESULTADO_DESCONHECIDO' };
    return saida;
  }

  /** Copia do motor só os campos de estado conhecidos (o estado vivo atualiza-se no servidor). */
  function aplicarDepois(f, d) {
    if (!d || typeof d !== 'object') return;
    if (typeof d.vidaActual === 'number' && Number.isFinite(d.vidaActual)) f.vidaActual = d.vidaActual;
    if (d.estadoMorte !== undefined) f.estadoMorte = d.estadoMorte === null ? null : clonarJson(d.estadoMorte);
    if (Array.isArray(d.estado)) f.caido = d.estado.includes('caido');
    if (typeof d.caido === 'boolean') f.caido = d.caido;
    for (const k of ['armaCaida', 'armaQuebrada', 'corpoPartido']) if (typeof d[k] === 'boolean') f[k] = d[k];
    if (f.lado !== 'jogadora') {
      if (f.vidaActual <= 0 || d.vivo === false) f.vivo = false;
    } else if (d.vivo === false || f.estadoMorte?.fase === 'morreu' || f.estadoMorte?.fase === 'morta') {
      // TODO(JV0.3): nome exato da fase final do estadoMorte.
      f.vivo = false;
    }
  }

  function desgracaAplicada(saida) {
    const fc = saida.falhaCritica;
    if (!fc || typeof fc !== 'object' || fc.requerConfirmacao) return null;
    const d = fc.desgraca ?? fc.desgracaAplicada;
    const tipo = typeof d === 'string' ? d : d && typeof d.tipo === 'string' ? d.tipo : null;
    return tipo && tipo !== 'nenhuma' ? tipo : null;
  }
  function aplicarEfeitoDesgraca(f, tipo) {
    switch (tipo) {
      case 'cai': f.caido = true; break;
      case 'arma-cai': f.armaCaida = true; break;
      case 'arma-quebra': f.armaQuebrada = true; break;
      case 'quebra-corpo': f.corpoPartido = true; break; // desvantagem 1 e metade do deslocamento até ao fim
      // TODO(JV0.3): `acerta-se` e `acerta-amigo` — o dano vem do motor (aliadoAtingidoId); não aplicado aqui.
      default: break;
    }
  }
  function tiposDe(t) {
    if (Array.isArray(t.tipos)) return t.tipos.slice();
    if (typeof t.tipo === 'string') return [t.tipo];
    if (Array.isArray(t.componentes)) return t.componentes.map((c) => c.tipo);
    return [];
  }

  /** Grava o desfecho de uma resolução do motor como eventos e aplica o estado. */
  function aplicarSaida(tx, atacante, alvo, t, ctx, saida, extra) {
    const resultado = RESULTADOS[saida.resultado];
    const visAlvo = visivelDe(alvo);
    const vidaAlvo = alvo.vidaActual;
    const visAtac = visivelDe(atacante);
    const vidaAtac = atacante.vidaActual;
    const sm = saida.soDoMestre && typeof saida.soDoMestre === 'object' ? saida.soDoMestre : {};
    const total = numeroOuNull(saida.totalEfectivo ?? saida.total);
    const faces = Array.isArray(saida.rolagem?.faces) ? saida.rolagem.faces.filter((x) => Number.isInteger(x)) : null;
    const ehJog = atacante.lado === 'jogadora';
    const dados = {
      atacanteId: atacante.id, alvoId: alvo.id, arma: t.id, resultado, ataqueDeOportunidade: !!extra.ataqueDeOportunidade,
    };
    // v0.2.1: total e faces só vão nos dados quando a atacante é jogadora (a própria vê-os).
    // O bruto do monstro fica só no soMestre (§6).
    if (ehJog) Object.assign(dados, { total, faces, expressao: t.expressaoAtaque });
    tx.emitir('ataque', dados, {
      semente: ctx.semente, verificacaoCritico: ctx.verificacaoCritico, contexto: ctx,
      total, faces, recibo: saida.publico?.recibo ?? null, soDoMestre: sm,
    });
    aplicarDepois(alvo, sm.alvoDepois);
    aplicarDepois(atacante, sm.atacanteDepois);
    const des = desgracaAplicada(saida);
    if (des) {
      aplicarEfeitoDesgraca(atacante, des);
      tx.emitir('desgraca', { figuraId: atacante.id, efeito: DESGRACAS.includes(des) ? des : null }, { bruto: saida.falhaCritica });
    }
    const dano = numeroOuNull(saida.danoAplicado) ?? 0;
    if (dano > 0) tx.emitir('dano', { alvoId: alvo.id, autorId: atacante.id, valor: dano, tipos: tiposDe(t) }, null);
    emitirEstado(tx, alvo, false, visAlvo, vidaAlvo);
    if (atacante.id !== alvo.id) emitirEstado(tx, atacante, false, visAtac, vidaAtac);
  }

  function finalizarAtaque(tx, f, alvo, t, ctx, saida) {
    const m = tx.estado;
    if (m.vez && m.vez.figuraId === f.id) m.vez.atacou = true; // o Confirmar marca `atacou`
    if (f.lado === 'jogadora') f.paGasto += t.custoPA; // debita-se só no Confirmar
    else if (f.armaCaida) f.armaCaida = false; // o monstro recupera a arma de graça ao atacar
    aplicarSaida(tx, f, alvo, t, ctx, saida, {});
    verificarFim(tx);
  }

  /** Ataque de quem tem a vez: proposta → (cartão do Mestre) → Confirmar, sempre com a semente do servidor. */
  function executarAtaque(tx, f, alvo, t, origem, { faces } = {}) {
    const ctx = montarContexto(tx.estado, f, alvo, {});
    if (faces) ctx.faces = faces.slice(); // dados físicos confirmados pelo Mestre; o dano usa a semente se faltarem
    const saida = chamarMotorAtaque(f, alvo, t, ctx);
    if (saida.erro) throw new ErroRecusa('acao_invalida', 'MOTOR:' + saida.erro);
    if (f.lado === 'jogadora' && saida.falhaCritica && saida.falhaCritica.requerConfirmacao) {
      // §8.3 / H10: a jogadora nunca autoriza a própria desgraça. A rolagem já está gravada no cartão.
      abrirCartao(tx, {
        tipo: 'desgraca', figuraId: f.id, alvoId: alvo.id, tecnicaId: t.id, contexto: ctx,
        proposta: saida.falhaCritica.desgracaProposta ?? saida.falhaCritica.proposta ?? null,
        razao: null, origem: origemCartao(origem),
      });
      return 'AGUARDANDO_MESTRE';
    }
    finalizarAtaque(tx, f, alvo, t, ctx, saida);
    return 'APLICADA';
  }

  function tecnicaCorpoACorpo(f) {
    const ts = fichaEfetiva(f).tecnicas;
    return ts.find((t) => t.alcanceM <= CASA_M + EPS && !(t.usaArma && f.armaQuebrada)) ?? null;
  }

  /** Ataque de oportunidade de um monstro (na chegada, com vantagem 1, sem a reação defensiva dela). */
  function ataqueDeOportunidade(tx, mon, alvo) {
    const t = tecnicaCorpoACorpo(mon);
    if (!t) return;
    mon.reacaoDisponivel = false;
    // TODO(JV1.x A-4): em modo semi/manual, o AoO devia passar pelo Mestre? Hoje é automático.
    const ctx = montarContexto(tx.estado, mon, alvo, { ataqueDeOportunidade: true, niveisVantagem: 1, semReacaoDefensiva: true });
    const saida = chamarMotorAtaque(mon, alvo, t, ctx);
    if (saida.erro) {
      tx.emitir('erro_motor', { figuraId: mon.id }, { erro: String(saida.erro), contexto: ctx });
      return;
    }
    if (mon.armaCaida) mon.armaCaida = false;
    aplicarSaida(tx, mon, alvo, t, ctx, saida, { ataqueDeOportunidade: true });
  }

  function aplicarMover(tx, f, destino) {
    const m = tx.estado;
    const v = m.vez;
    const r = bfs(m, f, Math.floor(v.reservaM / CASA_M + EPS), f.id);
    const k = chaveCasa(destino.x, destino.y);
    const d = r.dist.get(k);
    if (d === undefined || d === 0 || r.ocupadas.has(k)) throw new ErroRecusa('acao_invalida'); // defensivo
    const caminho = caminhoAte(r, k);
    const de = { x: f.x, y: f.y };
    const ehJog = f.lado === 'jogadora';

    // Ataques de oportunidade (REF_7 §3): guardam-se NA PARTIDA.
    //  grupo A: monstros vivos adjacentes à casa de partida (Desvincular cobre-o);
    //  grupo B: monstros cuja zona ela atravessa e depois abandona.
    // TODO(JV0.3): conferir no REF_7 se o grupo A exige que ela saia da zona. Aqui segue-se o texto à letra.
    const grupoA = ehJog && !v.desvinculou ? monstrosAdjacentes(m, de, f) : [];
    const idsA = new Set(grupoA.map((x) => x.id));
    const grupoB = [];
    if (ehJog) {
      const final = caminho[caminho.length - 1];
      const vistos = new Set();
      for (const casa of caminho.slice(1)) {
        for (const mon of monstrosAdjacentes(m, casa, f)) if (!idsA.has(mon.id)) vistos.add(mon.id);
      }
      for (const id of vistos) if (!adjacentes(final, m.figuras[id])) grupoB.push(m.figuras[id]);
    }

    f.x = destino.x;
    f.y = destino.y;
    const custoM = arred(d * CASA_M); // débito no fim do movimento: casas × 1,5
    v.reservaM = arred(Math.max(0, v.reservaM - custoM));
    v.andouM = arred(v.andouM + custoM);
    if (!ehJog) v.iaMoveu = true;
    tx.emitir('movimento', { figuraId: f.id, de, para: { x: f.x, y: f.y }, caminho, custoM, reservaM: v.reservaM }, null);

    // Resolvem-se só na CHEGADA, depois do débito, pela ordem de iniciativa.
    const atacantes = [...grupoA, ...grupoB].sort((a, b) => m.ordem.indexOf(a.id) - m.ordem.indexOf(b.id));
    for (const mon of atacantes) {
      if (m.fase !== 'combate' || !f.vivo || f.estadoMorte?.fase === 'aMorrer') break; // morrer interrompe a série
      if (!mon.vivo || mon.caido || !mon.reacaoDisponivel) continue;
      ataqueDeOportunidade(tx, mon, f);
      verificarFim(tx);
    }
  }

  function origemCartao(origem) {
    return origem ? { seatId: origem.seatId, id: origem.id, idCampo: origem.idCampo, chave: origem.chave } : null;
  }

  /** Valida a ação contra as opções correntes e aplica-a. Devolve o estado do recibo. */
  function aplicarIntencao(tx, figuraId, acao, origem) {
    const m = tx.estado;
    const f = m.figuras[figuraId];
    const v = m.vez;
    const ops = calcularOpcoes(m, figuraId);
    if (!f || !acaoNasOpcoes(ops, acao)) throw new ErroRecusa('acao_invalida');
    if (origem.dadosFisicos && acao.tipo !== 'atacar') throw new ErroRecusa('acao_invalida');
    v.intencoes += 1;
    switch (acao.tipo) {
      case 'mover':
        aplicarMover(tx, f, acao.destino);
        return 'APLICADA';
      case 'atacar': {
        const alvo = m.figuras[acao.alvoId];
        const t = fichaEfetiva(f).tecnicas.find((x) => x.id === acao.arma);
        if (origem.dadosFisicos) {
          // §8.2: dados físicos → cartão ao Mestre; a vez fica parada.
          abrirCartao(tx, {
            tipo: 'dados', figuraId: f.id, alvoId: alvo.id, tecnicaId: t.id,
            faces: origem.dadosFisicos.faces.slice(), razao: null, origem: origemCartao(origem),
          });
          return 'AGUARDANDO_MESTRE';
        }
        return executarAtaque(tx, f, alvo, t, origem);
      }
      case 'correr': {
        const metros = metrosCorrida(f);
        if (metros === null) throw new ErroRecusa('acao_invalida');
        v.correrUsado = true;
        v.atacou = true; // gasta a ação padrão
        v.reservaM = metros; // substitui a reserva, não soma
        tx.emitir('acao', { figuraId: f.id, tipo: 'correr' }, { reservaM: metros });
        return 'APLICADA';
      }
      case 'defender':
        f.reacaoDisponivel = false;
        f.defendendo = true;
        tx.emitir('acao', { figuraId: f.id, tipo: 'defender' }, null);
        return 'APLICADA';
      case 'desvincular':
        v.desvinculou = true;
        v.atacou = true;
        tx.emitir('acao', { figuraId: f.id, tipo: 'desvincular' }, null);
        return 'APLICADA';
      case 'transformar': {
        const tr = fichaDe(f).transformacao;
        const vis = visivelDe(f);
        const vida = f.vidaActual;
        f.paGasto += Number.isInteger(tr.custo) ? tr.custo : 0;
        f.transformada = true;
        v.atacou = true;
        emitirEstado(tx, f, false, vis, vida);
        return 'APLICADA';
      }
      case 'encerrar':
        avancarVez(tx);
        return 'APLICADA';
      default:
        // TODO(JV1.x): consumivel e reacao (A-4).
        throw new ErroRecusa('acao_invalida');
    }
  }

  // =================================================================== IA simples (REF_7 §6 + invariante 12)
  function distMinima(c, alvos) {
    // mapaDistancias do REF_7 atravessa figuras: sem terreno, é a distância de Manhattan.
    return Math.min(...alvos.map((a) => Math.abs(a.x - c.x) + Math.abs(a.y - c.y)));
  }

  /** Gera UMA intenção a partir do ROOM_OPTIONS corrente (invariante 12). */
  function proporIA(m, f) {
    const ops = calcularOpcoes(m, f.id);
    const nota = fichaDe(f).comportamentoIA?.nota;
    const sufixo = typeof nota === 'string' ? ` [${nota}]` : '';
    const alvos = colocadas(m).filter((x) => x.lado === 'jogadora' && x.vivo);
    if (ops.ataques.length) {
      // Alvo: a jogadora (REF_7: "sempre a Ong"); com várias, a mais perto.
      const a = ops.ataques
        .slice()
        .sort((p, q) => distanciaM(f, m.figuras[p.alvoId]) - distanciaM(f, m.figuras[q.alvoId]))[0];
      return { acao: { tipo: 'atacar', alvoId: a.alvoId, arma: a.arma }, razao: 'Alvo ao alcance: ataca.' + sufixo };
    }
    if (!m.vez.iaMoveu && ops.mover.length && alvos.length) {
      const atual = distMinima(f, alvos);
      let melhor = null;
      for (const o of ops.mover) {
        const d = distMinima(o, alvos);
        if (d < atual && (melhor === null || d < melhor.d)) melhor = { ...o, d }; // empate: o de menos passos (lista ordenada)
      }
      if (melhor) return { acao: { tipo: 'mover', destino: { x: melhor.x, y: melhor.y } }, razao: 'Aproxima-se da jogadora.' + sufixo };
    }
    return { acao: { tipo: 'encerrar' }, razao: 'Nada a fazer: encerra.' + sufixo };
  }

  function passoIAAuto(figuraId) {
    const m0 = journal.estado;
    const f0 = m0.figuras[figuraId];
    const n = m0.contadores.ia + 1;
    const intentId = 'ia-' + n;
    const noLimite = m0.vez.intencoes >= MAX_INTENCOES_TURNO - 1; // a 20.ª é sempre `encerrar`
    const proposta = noLimite ? { acao: { tipo: 'encerrar' }, razao: 'Limite de intenções do turno.' } : proporIA(m0, f0);
    const meta = { seatId: 'ia', chave: chaveRecibo('ia', intentId), id: intentId, idCampo: 'intentId', hashAcao: hash(jsonCanonico({ acao: proposta.acao })) };
    try {
      return transacao((tx) => {
        tx.estado.contadores.ia = n;
        tx.emitir('ia', { figuraId }, { intentId, acao: proposta.acao, razao: proposta.razao });
        const estado = aplicarIntencao(tx, figuraId, proposta.acao, { seatId: 'ia', id: intentId, idCampo: 'intentId', chave: meta.chave });
        tx.recibos.push({ chave: meta.chave, recibo: novoRecibo(meta, estado, null), enviar: false });
      }).saidas;
    } catch (e) {
      if (!(e instanceof ErroRecusa) && depurar) throw e;
      const erro = e instanceof ErroRecusa ? e : new ErroRecusa('acao_invalida', 'EXCECAO:' + (e?.message ?? String(e)));
      return transacao((tx) => {
        const m = tx.estado;
        m.contadores.ia = n;
        const v = m.vez;
        v.recusas += 1;
        v.intencoes += 1;
        tx.emitir('recusa', { seatId: 'ia' }, { id: intentId, acao: proposta.acao, motivo: erro.motivo, detalhe: erro.detalhe });
        tx.recibos.push({ chave: meta.chave, recibo: novoRecibo(meta, 'RECUSADA', erro.motivo), enviar: false });
        if (v.recusas >= 2) avancarVez(tx); // invariante 12: 2.ª recusa no turno → `auto` encerra
      }).saidas;
    }
  }

  /** Depois de cada comando: se a vez é de criatura, a IA joga (auto) ou propõe (semi). */
  function rodarIA() {
    const saidas = [];
    for (let guarda = 0; guarda < 2000; guarda++) {
      const m = journal.estado;
      if (m.fase !== 'combate' || !m.vez || cartaoAtivo(m)) break;
      const f = m.figuras[m.vez.figuraId];
      if (f.lado === 'jogadora' || f.modo === 'manual') break;
      if (f.modo === 'semi') {
        if (m.vez.iaPausada) break;
        saidas.push(...transacao((tx) => {
          const p = proporIA(tx.estado, tx.estado.figuras[f.id]);
          abrirCartao(tx, { tipo: 'ia', figuraId: f.id, proposta: p.acao, razao: p.razao, origem: null });
        }).saidas);
        break;
      }
      saidas.push(...passoIAAuto(f.id));
    }
    return saidas;
  }

  // =================================================================== recibos e execução
  function novoRecibo(meta, estado, motivo) {
    return {
      seatId: meta.seatId, id: meta.id, idCampo: meta.idCampo, hashAcao: meta.hashAcao,
      estado, motivo: motivo ?? null, seq: 0, revision: 0, journalSeq: 0, revertidaEm: null,
    };
  }

  /** E-C1: mesmo id + mesmo hash → recibo original; mesmo id + outro hash → intent_conflito, sem gravar. */
  function deduplicar(seatId, chave, hashAcao, idCampo, id) {
    const r = journal.recibo(chave);
    if (!r) return null;
    if (r.hashAcao === hashAcao) return [{ seatId, msg: mensagemDoRecibo(r) }];
    return [{ seatId, msg: rejeicaoNaoGravada(idCampo, id, 'intent_conflito') }];
  }

  function atualizarReciboOrigem(tx, origem, estado, motivo = null) {
    if (!origem?.chave) return;
    const atual = journal.recibo(origem.chave);
    if (!atual) return;
    tx.recibos.push({ chave: origem.chave, recibo: { ...atual, estado, motivo }, enviar: true });
  }

  /**
   * Executa um comando com recibo. Sucesso → APLICADA/AGUARDANDO_MESTRE.
   * Recusa (E-C5) → transação nova que grava o recibo RECUSADA (terminal para o id).
   */
  function executarComRecibo(meta, fn, aoRecusar) {
    const saidas = [];
    try {
      saidas.push(...transacao((tx) => {
        const estado = fn(tx);
        tx.recibos.push({ chave: meta.chave, recibo: novoRecibo(meta, estado, null), enviar: true });
      }).saidas);
    } catch (e) {
      if (!(e instanceof ErroRecusa) && depurar) throw e;
      const erro = e instanceof ErroRecusa ? e : new ErroRecusa('acao_invalida', 'EXCECAO:' + (e?.message ?? String(e)));
      saidas.push(...transacao((tx) => {
        if (erro.detalhe) tx.emitir('recusa', { seatId: meta.seatId }, { id: meta.id, motivo: erro.motivo, detalhe: erro.detalhe });
        if (aoRecusar) aoRecusar(tx, erro);
        tx.recibos.push({ chave: meta.chave, recibo: novoRecibo(meta, 'RECUSADA', erro.motivo), enviar: true });
        if (erro.motivo === 'revisao_antiga') tx.opcoesForcadas.add(meta.seatId); // §4: nunca fica preso
      }).saidas);
    }
    saidas.push(...rodarIA());
    return saidas;
  }

  // =================================================================== mensagens do cliente
  function dentroDoRitmo(seatId) {
    const t = agora();
    const lista = (ritmo.get(seatId) ?? []).filter((x) => t - x < 1000);
    if (lista.length >= 10) {
      ritmo.set(seatId, lista);
      return false;
    }
    lista.push(t);
    ritmo.set(seatId, lista);
    return true;
  }

  function tratarIntencao(seat, msg) {
    const { intentId, revision, acao } = msg;
    const dadosFisicos = msg.dadosFisicos ?? null;
    const idOk = typeof intentId === 'string' && RE_ID.test(intentId);
    if (!idOk || !Number.isInteger(revision) || !acaoBemFormada(acao) || !dadosFisicosBemFormados(dadosFisicos)) {
      return [{ seatId: seat.seatId, msg: rejeicaoNaoGravada('intentId', idOk ? intentId : null, 'formato') }];
    }
    const hashAcao = hash(jsonCanonico({ acao, dadosFisicos, revision }));
    const chave = chaveRecibo(seat.seatId, intentId); // E-P8: deduplicação por (seatId, intentId)
    const dup = deduplicar(seat.seatId, chave, hashAcao, 'intentId', intentId);
    if (dup) return dup;
    const meta = { seatId: seat.seatId, chave, id: intentId, idCampo: 'intentId', hashAcao };
    return executarComRecibo(meta, (tx) => {
      const m = tx.estado;
      const s = m.lugares[seat.seatId];
      if (m.fase === 'pausa') throw new ErroRecusa('sala_pausada');
      if (cartaoAtivo(m)) throw new ErroRecusa('aguardando_mestre');
      if (revision !== s.revision) throw new ErroRecusa('revisao_antiga'); // invariante 5
      if (m.fase !== 'combate' || !m.vez || m.vez.figuraId !== s.figuraId) throw new ErroRecusa('fora_da_vez');
      return aplicarIntencao(tx, s.figuraId, acao, { seatId: seat.seatId, id: intentId, idCampo: 'intentId', chave, dadosFisicos });
    });
  }

  function tratarConsulta(seat, msg) {
    if (!Array.isArray(msg.intentIds)) return [{ seatId: seat.seatId, msg: rejeicaoNaoGravada('intentId', null, 'formato') }];
    return msg.intentIds.slice(0, 50).map((id) => {
      let r = null;
      if (typeof id === 'string' && RE_ID.test(id)) {
        // Só responde ids do próprio lugar; os alheios vêm como DESCONHECIDA (E-P8).
        r = journal.recibo(chaveRecibo(seat.seatId, id));
        if (!r && seat.papel === 'mestre') {
          r = journal.recibo(chaveRecibo(seat.seatId, 'act:' + id)) ?? journal.recibo(chaveRecibo(seat.seatId, 'cmd:' + id));
        }
      }
      if (!r) {
        return { seatId: seat.seatId, msg: { v: PROTOCOLO, type: 'ROOM_RECEIPT', roomId, intentId: typeof id === 'string' ? id : null, estado: 'DESCONHECIDA' } };
      }
      const base = mensagemDoRecibo(r);
      if (base.type === 'ROOM_REJECT') {
        return {
          seatId: seat.seatId,
          msg: { v: PROTOCOLO, type: 'ROOM_RECEIPT', roomId, [r.idCampo]: r.id, estado: 'RECUSADA', motivo: r.motivo, seq: r.seq, revision: r.revision },
        };
      }
      return { seatId: seat.seatId, msg: base };
    });
  }

  /** Eventos que faltam desde lastSeq (do fluxo DESTE lugar) ou um snapshot. Sem await (E-C8). */
  function mensagensDeSincronizacao(seatId, lastSeq) {
    const m = journal.estado;
    const s = m.lugares[seatId];
    const fluxo = journal.fluxo(seatId);
    const out = [];
    if (Number.isInteger(lastSeq) && lastSeq >= 0 && lastSeq <= s.seq && fluxo.length === s.seq) {
      for (let i = lastSeq; i < fluxo.length; i++) out.push({ seatId, msg: fluxo[i] });
    } else {
      out.push({ seatId, msg: mensagemSnapshot(m, s, isoAgora()) });
    }
    const o = opcoesDoLugar(m, s);
    if (o) out.push({ seatId, msg: mensagemOpcoes(s, o) });
    if (s.papel === 'mestre') {
      out.push({ seatId, msg: mensagemVistaMestre() });
      const c = cartaoAtivo(m);
      if (c) out.push({ seatId, msg: mensagemCartao(c) });
    }
    return out;
  }

  function tratarResync(seat, msg) {
    const saidas = mensagensDeSincronizacao(seat.seatId, msg.lastSeq);
    const m = journal.estado;
    // E-C4: o ROOM_RESUMED só sai depois do RESYNC do Mestre.
    if (seat.papel === 'mestre' && m.fase === 'pausa' && m.pausa?.origem === 'desconexao' && (conexoes.get(seat.seatId) ?? 0) > 0) {
      saidas.push(...transacao((tx) => retomar(tx)).saidas);
      saidas.push(...rodarIA());
    }
    return saidas;
  }

  // ------------------------------------------------------------------ Mestre
  function mestreBemFormado(msg) {
    const s = (x, max = 64) => typeof x === 'string' && x.length >= 1 && x.length <= max;
    const sn = (x, max) => x === undefined || x === null || (typeof x === 'string' && x.length <= max);
    const listaIds = (x) => x === undefined || (Array.isArray(x) && x.length <= 200 && x.every((y) => s(y)));
    switch (msg.type) {
      case 'MASTER_LOBBY_SET':
        return sn(msg.mapaId, 64) && listaIds(msg.criaturasDisponiveis) && listaIds(msg.npcsDisponiveis);
      case 'MASTER_START':
      case 'MASTER_PAUSE':
      case 'MASTER_RESUME':
        return true;
      case 'MASTER_PLACE':
        return s(msg.fichaId) && !!msg.casa && Number.isInteger(msg.casa.x) && Number.isInteger(msg.casa.y) && sn(msg.orientacao, 8);
      case 'MASTER_MODE':
        return s(msg.figuraId) && MODOS.includes(msg.modo);
      case 'MASTER_ACT':
        return s(msg.figuraId) && acaoBemFormada(msg.acao);
      case 'MASTER_APPROVE':
        return s(msg.cartaoId) && ['aprovar', 'recusar', 'editar'].includes(msg.decisao)
          && (msg.edicao === undefined || msg.edicao === null || (typeof msg.edicao === 'object' && !Array.isArray(msg.edicao)));
      case 'MASTER_CONFIRM_DICE':
        return typeof msg.intentId === 'string' && RE_ID.test(msg.intentId) && typeof msg.aceitar === 'boolean';
      case 'MASTER_AMBIENTE':
        return sn(msg.hora, 16) && sn(msg.clima, 64) && sn(msg.futuro, 500);
      case 'MASTER_SUPERVISOR':
        return msg.op === 'voltar' && Number.isInteger(msg.ateSeq) && msg.ateSeq >= 0;
      default:
        return false;
    }
  }

  function aoRecusarActMestre(tx, erro) {
    // Invariante 12 em semi/manual: na 2.ª recusa no mesmo turno, um cartão ao Mestre.
    const m = tx.estado;
    if (!m.vez || erro.motivo !== 'acao_invalida') return;
    const f = m.figuras[m.vez.figuraId];
    if (!f || f.lado === 'jogadora') return;
    m.vez.recusas += 1;
    if (m.vez.recusas >= 2 && !cartaoAtivo(m)) {
      abrirCartao(tx, { tipo: 'progresso', figuraId: f.id, proposta: { tipo: 'encerrar' }, razao: 'Duas recusas neste turno.', origem: null });
    }
  }

  function executarComandoMestre(tx, seatId, msg) {
    const m = tx.estado;
    const tipo = msg.type;
    const ativo = cartaoAtivo(m);
    const liberadoComCartao =
      (tipo === 'MASTER_APPROVE' && ativo && msg.cartaoId === ativo.cartaoId)
      || (tipo === 'MASTER_CONFIRM_DICE' && ativo && ativo.tipo === 'dados' && ativo.origem?.id === msg.intentId)
      || (tipo === 'MASTER_SUPERVISOR' && msg.op === 'voltar')
      || tipo === 'MASTER_PAUSE' || tipo === 'MASTER_RESUME';
    if (ativo && !liberadoComCartao) throw new ErroRecusa('cartao_aberto'); // E-C6
    if (m.fase === 'pausa' && tipo !== 'MASTER_RESUME' && tipo !== 'MASTER_PAUSE') throw new ErroRecusa('sala_pausada');
    if (msg.revision !== m.lugares[seatId].revision) throw new ErroRecusa('revisao_antiga'); // E-C3

    switch (tipo) {
      case 'MASTER_LOBBY_SET': {
        if (m.fase !== 'lobby') throw new ErroRecusa('acao_invalida');
        const criaturas = msg.criaturasDisponiveis ?? [];
        const npcs = msg.npcsDisponiveis ?? [];
        for (const id of [...criaturas, ...npcs]) {
          if (!fichas[id] || fichas[id].papel === 'jogadora') throw new ErroRecusa('acao_invalida');
        }
        m.lobby = { mapaId: msg.mapaId ?? null, criaturasDisponiveis: criaturas.slice(), npcsDisponiveis: npcs.slice() };
        tx.emitir('lobby', {}, m.lobby); // nada aparece às jogadoras
        return 'APLICADA';
      }
      case 'MASTER_START': {
        if (m.fase !== 'lobby') throw new ErroRecusa('acao_invalida');
        const jog = Object.values(m.figuras).filter((f) => f.lado === 'jogadora');
        if (!jog.length) throw new ErroRecusa('acao_invalida');
        for (const f of jog) {
          let casa = f.casaInicial;
          if (!casa || !dentro(m, casa.x, casa.y) || ocupada(m, casa.x, casa.y)) casa = primeiraCasaLivre(m);
          if (!casa) throw new ErroRecusa('acao_invalida');
          f.x = casa.x;
          f.y = casa.y;
          f.colocada = true;
          tx.emitir('colocacao', {
            figuraId: f.id, nomePublico: nomePublicoDe(fichaDe(f)), lado: f.lado, x: f.x, y: f.y, orientacao: f.orientacao, visivel: visivelDe(f),
          }, { fichaId: f.fichaId });
        }
        m.fase = 'combate';
        m.rodada = 1;
        m.ordem = ordenarPorIniciativa(colocadas(m).map((f) => f.id), m);
        // A batalha começa sempre na vez dela (D-13.3, rodada 1).
        m.vezIdx = m.ordem.findIndex((id) => m.figuras[id].lado === 'jogadora');
        iniciarVez(tx, m.figuras[m.ordem[m.vezIdx]]);
        return 'APLICADA';
      }
      case 'MASTER_PLACE': {
        if (m.fase !== 'lobby' && m.fase !== 'combate') throw new ErroRecusa('acao_invalida');
        const ficha = fichas[msg.fichaId];
        if (!ficha || ficha.papel === 'jogadora') throw new ErroRecusa('acao_invalida');
        if (m.lobby && ![...m.lobby.criaturasDisponiveis, ...m.lobby.npcsDisponiveis].includes(ficha.id)) {
          throw new ErroRecusa('acao_invalida');
        }
        if (!dentro(m, msg.casa.x, msg.casa.y) || ocupada(m, msg.casa.x, msg.casa.y)) throw new ErroRecusa('acao_invalida');
        const id = novoId('f', m.figuras);
        const f = novaFigura(id, ficha, null);
        f.x = msg.casa.x;
        f.y = msg.casa.y;
        f.orientacao = msg.orientacao ?? 'S';
        f.colocada = true; // só AGORA existe para as jogadoras
        m.figuras[id] = f;
        tx.emitir('colocacao', {
          figuraId: id, nomePublico: nomePublicoDe(ficha), lado: f.lado, x: f.x, y: f.y, orientacao: f.orientacao, visivel: visivelDe(f),
        }, { fichaId: ficha.id, modo: f.modo });
        if (m.fase === 'combate') inserirNaOrdem(m, id);
        return 'APLICADA';
      }
      case 'MASTER_MODE': {
        const f = m.figuras[msg.figuraId];
        if (!f || f.lado === 'jogadora') throw new ErroRecusa('acao_invalida');
        f.modo = msg.modo;
        if (m.vez && m.vez.figuraId === f.id) m.vez.iaPausada = false;
        tx.emitir('modo', { figuraId: f.id }, { modo: f.modo }); // tipo interno: a Party não recebe nada
        return 'APLICADA';
      }
      case 'MASTER_ACT': {
        const f = m.figuras[msg.figuraId];
        if (!f || f.lado === 'jogadora') throw new ErroRecusa('acao_invalida');
        if (m.fase !== 'combate' || !m.vez || m.vez.figuraId !== f.id) throw new ErroRecusa('fora_da_vez');
        return aplicarIntencao(tx, f.id, msg.acao, {
          seatId, id: msg.intentId, idCampo: 'intentId', chave: chaveRecibo(seatId, 'act:' + msg.intentId),
        });
      }
      case 'MASTER_APPROVE':
        return aprovarCartao(tx, seatId, msg);
      case 'MASTER_CONFIRM_DICE': {
        const c = ativo;
        if (!c || c.tipo !== 'dados' || c.origem?.id !== msg.intentId) throw new ErroRecusa('acao_invalida');
        fecharCartao(tx, c, msg.aceitar ? 'aceitar' : 'recusar');
        if (!msg.aceitar) {
          atualizarReciboOrigem(tx, c.origem, 'RECUSADA', 'acao_invalida');
          return 'APLICADA';
        }
        const f = m.figuras[c.figuraId];
        const alvo = m.figuras[c.alvoId];
        const t = fichaEfetiva(f).tecnicas.find((x) => x.id === c.tecnicaId);
        const r = executarAtaque(tx, f, alvo, t, c.origem, { faces: c.faces });
        if (r === 'APLICADA') atualizarReciboOrigem(tx, c.origem, 'APLICADA');
        return 'APLICADA';
      }
      case 'MASTER_AMBIENTE': {
        const antes = efeitoAmbiente(m.ambiente);
        m.ambiente = {
          hora: msg.hora !== undefined ? msg.hora : m.ambiente.hora,
          clima: msg.clima !== undefined ? msg.clima : m.ambiente.clima,
          futuro: msg.futuro !== undefined ? msg.futuro : m.ambiente.futuro,
        };
        const depois = efeitoAmbiente(m.ambiente);
        // A Party só recebe evento se o EFEITO presente mudou (senão o seq dela denunciaria o painel).
        if (jsonCanonico(antes) !== jsonCanonico(depois)) tx.emitir('ambiente', { efeito: depois }, m.ambiente);
        else tx.emitir('ambiente_mestre', {}, m.ambiente);
        // TODO(JV1.x): raio e fogo com dano (valores do ambiente.json do pacote).
        return 'APLICADA';
      }
      case 'MASTER_SUPERVISOR':
        return voltar(tx, msg.ateSeq);
      case 'MASTER_PAUSE':
        if (!pausar(tx, 'manutencao', 'mestre')) throw new ErroRecusa('acao_invalida');
        return 'APLICADA';
      case 'MASTER_RESUME':
        if (m.fase !== 'pausa' || m.pausa?.origem === 'motor') throw new ErroRecusa('acao_invalida');
        retomar(tx);
        return 'APLICADA';
      default:
        throw new ErroRecusa('acao_invalida');
    }
  }

  function primeiraCasaLivre(m) {
    for (let y = 0; y < m.mapa.altura; y++) for (let x = 0; x < m.mapa.largura; x++) if (!ocupada(m, x, y)) return { x, y };
    return null;
  }

  function aprovarCartao(tx, seatId, msg) {
    const m = tx.estado;
    const c = m.cartoes.find((x) => x.cartaoId === msg.cartaoId && x.estado === 'aberto');
    if (!c || c.tipo === 'dados') throw new ErroRecusa('acao_invalida'); // decisão idempotente: a primeira ganha
    const decisao = msg.decisao;
    if (c.tipo === 'desgraca') {
      const f = m.figuras[c.figuraId];
      const alvo = m.figuras[c.alvoId];
      const t = fichaEfetiva(f).tecnicas.find((x) => x.id === c.tecnicaId);
      let escolhida;
      if (decisao === 'aprovar') escolhida = typeof c.proposta === 'string' ? c.proposta : c.proposta?.tipo ?? null;
      else if (decisao === 'editar') escolhida = msg.edicao?.desgraca;
      else escolhida = 'nenhuma'; // TODO(JV1.x R0): o que "recusar a desgraça" significa na regra
      if (typeof escolhida !== 'string') throw new ErroRecusa('acao_invalida');
      // Resolve de novo com a MESMA semente e a escolha do Mestre (JV1.1-a §4).
      const ctx = { ...c.contexto, modoDesgraca: 'escolha', desgracaEscolhida: escolhida };
      const saida = chamarMotorAtaque(f, alvo, t, ctx);
      if (saida.erro) throw new ErroRecusa('acao_invalida', 'MOTOR:' + saida.erro);
      fecharCartao(tx, c, decisao);
      finalizarAtaque(tx, f, alvo, t, ctx, saida);
      atualizarReciboOrigem(tx, c.origem, 'APLICADA');
      return 'APLICADA';
    }
    if (c.tipo === 'ia') {
      fecharCartao(tx, c, decisao);
      if (decisao === 'recusar') {
        m.vez.iaPausada = true; // o Mestre joga esta vez à mão (MASTER_ACT)
        return 'APLICADA';
      }
      const acao = decisao === 'editar' ? msg.edicao?.acao : c.proposta;
      if (!acaoBemFormada(acao)) throw new ErroRecusa('acao_invalida');
      aplicarIntencao(tx, c.figuraId, acao, { seatId, id: 'cartao-' + c.cartaoId, idCampo: 'intentId', chave: null });
      return 'APLICADA';
    }
    if (c.tipo === 'progresso') {
      fecharCartao(tx, c, decisao);
      if (decisao === 'recusar') {
        m.vez.recusas = 0;
        m.vez.iaPausada = true;
      } else avancarVez(tx); // aprovar = encerrar o turno
      return 'APLICADA';
    }
    throw new ErroRecusa('acao_invalida');
  }

  /** MASTER_SUPERVISOR voltar: cria `revertido`; o journal nunca apaga história. */
  function voltar(tx, ateSeq) {
    const m = tx.estado;
    if (ateSeq >= journal.journalSeq || !checkpoints.has(ateSeq)) throw new ErroRecusa('acao_invalida');
    Object.assign(m, clonarJson(checkpoints.get(ateSeq)));
    for (const c of m.cartoes) {
      if (c.estado === 'aberto') {
        c.estado = 'fechado';
        c.decisao = 'revertido';
      }
    }
    tx.emitir('revertido', {}, { ateSeq });
    for (const [chave, r] of journal.todosRecibos()) {
      if (r.journalSeq > ateSeq && !r.revertidaEm && r.estado !== 'RECUSADA') {
        const novo = { ...r, revertidaEm: tx.ts };
        if (novo.estado === 'AGUARDANDO_MESTRE') {
          novo.estado = 'RECUSADA';
          novo.motivo = 'revertido';
        }
        tx.recibos.push({ chave, recibo: novo, enviar: true });
      }
    }
    tx.snapshotsTodos = true; // projetados no instante novo
    // TODO(JV1.x E-P12): replay "no instante histórico" para quem pedir o passado (hoje: fluxos gravados).
    return 'APLICADA';
  }

  function tratarMestre(seat, msg) {
    const s = seat.seatId;
    const tipo = msg.type;
    // Isentos de revision e de recibo (E-C3).
    if (tipo === 'MASTER_SEARCH') {
      const texto = typeof msg.texto === 'string' ? msg.texto.trim().toLowerCase().slice(0, 64) : '';
      const resultados = Object.values(fichas)
        .filter((f) => f.papel !== 'jogadora')
        .filter((f) => !texto || f.nome.toLowerCase().includes(texto) || (f.nomePublico ?? '').toLowerCase().includes(texto) || f.id.includes(texto))
        .slice(0, 50)
        .map((f) => ({ fichaId: f.id, nome: f.nome, nomePublico: f.nomePublico ?? null, papel: f.papel, classificacao: f.classificacao }));
      return [{ seatId: s, msg: { v: PROTOCOLO, type: 'MASTER_RESULTS', roomId, resultados } }];
    }
    if (tipo === 'MASTER_VIEW') return [{ seatId: s, msg: mensagemVistaMestre() }];
    if (tipo === 'MASTER_SUPERVISOR' && msg.op === 'exportar') {
      // E-P13: só o lugar do Mestre, nunca por URL servida; marcada MESTRE-ONLY.
      return [{ seatId: s, msg: { v: PROTOCOLO, type: 'MASTER_EXPORT', roomId, marca: 'MESTRE-ONLY', conteudo: journal.exportar({ chave: chaveJournal ?? undefined }) } }];
    }
    if (!TIPOS_MESTRE.includes(tipo)) return [{ seatId: s, msg: msgErro('formato', TEXTOS_RECUSA.formato) }];
    const ehAct = tipo === 'MASTER_ACT';
    const idCampo = ehAct ? 'intentId' : 'cmdId';
    const id = msg[idCampo];
    const idOk = typeof id === 'string' && RE_ID.test(id);
    if (!idOk || !Number.isInteger(msg.revision) || !mestreBemFormado(msg)) {
      return [{ seatId: s, msg: rejeicaoNaoGravada(idCampo, idOk ? id : null, 'formato') }];
    }
    const corpo = { ...msg };
    delete corpo.v;
    delete corpo.roomId;
    delete corpo[idCampo];
    const hashAcao = hash(jsonCanonico(corpo));
    const chave = chaveRecibo(s, (ehAct ? 'act:' : 'cmd:') + id); // espaço separado para o Mestre (E-P8)
    const dup = deduplicar(s, chave, hashAcao, idCampo, id);
    if (dup) return dup;
    return executarComRecibo({ seatId: s, chave, id, idCampo, hashAcao }, (tx) => executarComandoMestre(tx, s, msg), ehAct ? aoRecusarActMestre : null);
  }

  function processarUm(seatId, msg) {
    const seat = journal.estado.lugares[seatId];
    if (!seat) return [];
    if (!msg || typeof msg !== 'object' || Array.isArray(msg)) return [{ seatId, msg: msgErro('formato', TEXTOS_RECUSA.formato) }];
    if (msg.v !== PROTOCOLO) return [{ seatId, msg: msgErro('versao', 'Versão do protocolo não suportada.') }];
    if (msg.roomId !== undefined && msg.roomId !== roomId) return [{ seatId, msg: msgErro('formato', 'Sala errada.') }];
    const ehComando = msg.type === 'ROOM_INTENT' || (typeof msg.type === 'string' && msg.type.startsWith('MASTER_'));
    if (ehComando && !dentroDoRitmo(seatId)) {
      // TODO(JV1.x): o adaptador fecha a ligação se o excesso se repetir (§2).
      const idCampo = msg.type === 'ROOM_INTENT' || msg.type === 'MASTER_ACT' ? 'intentId' : 'cmdId';
      const id = typeof msg[idCampo] === 'string' && RE_ID.test(msg[idCampo]) ? msg[idCampo] : null;
      return [{ seatId, msg: rejeicaoNaoGravada(idCampo, id, 'formato') }];
    }
    switch (msg.type) {
      case 'ROOM_INTENT':
        if (seat.papel !== 'jogadora') return [{ seatId, msg: msgErro('proibido', 'Este papel não envia intenções.') }];
        return tratarIntencao(seat, msg);
      case 'RECEIPT_QUERY':
        return tratarConsulta(seat, msg);
      case 'ROOM_RESYNC':
        return tratarResync(seat, msg);
      default:
        if (typeof msg.type === 'string' && msg.type.startsWith('MASTER_')) {
          if (seat.papel !== 'mestre') return [{ seatId, msg: msgErro('proibido', 'Só o Mestre.') }];
          return tratarMestre(seat, msg);
        }
        return [{ seatId, msg: msgErro('formato', TEXTOS_RECUSA.formato) }];
    }
  }

  // =================================================================== entrada (ROOM_JOIN, E-P9)
  function estaBloqueado(chave, t) {
    const r = tentativas.get(chave);
    return !!r && r.bloqueadoAte > t;
  }
  /** Regista uma falha. Devolve true quando começa um bloqueio novo (→ alerta ao Mestre). */
  function registrarFalha(chave, t) {
    const r = tentativas.get(chave) ?? { falhas: [], bloqueadoAte: 0, nivel: 0 };
    r.falhas = r.falhas.filter((x) => t - x < 60000);
    r.falhas.push(t);
    let novo = false;
    if (r.falhas.length >= 5) {
      r.bloqueadoAte = t + 60000 * 2 ** r.nivel; // espera que dobra
      r.nivel = Math.min(r.nivel + 1, 10);
      r.falhas = [];
      novo = true;
    }
    tentativas.set(chave, r);
    return novo;
  }
  function confereSegredo(indice, valor) {
    const c = credenciais.get(indice);
    if (!c || typeof valor !== 'string') return false;
    return iguaisTempoConstante(c.hash, hash(c.sal + '\u0000' + valor));
  }

  /**
   * ROOM_JOIN. O adaptador associa a ligação ao seatId devolvido e entrega:
   *  - `mensagens` a ESTA ligação (WELCOME com o seatToken, sincronização, opções);
   *  - `saidas` aos outros lugares;
   *  - se `fecharAnteriores`, fecha as outras ligações deste lugar (código 4002).
   */
  function entrar(msg, { ip = 'desconhecido' } = {}) {
    const t = agora();
    const falha = (mensagens, saidas = []) => ({ ok: false, mensagens, saidas, fecharAnteriores: false });
    const bloqueio = () => falha([msgErro('bloqueado', 'Muitas tentativas. Espere um pouco.')]);
    if (!msg || typeof msg !== 'object' || msg.v !== PROTOCOLO || msg.type !== 'ROOM_JOIN') {
      return falha([msgErro(msg?.v !== undefined && msg?.v !== PROTOCOLO ? 'versao' : 'formato', TEXTOS_RECUSA.formato)]);
    }
    if (estaBloqueado('ip:' + ip, t)) return bloqueio();
    const m = journal.estado;
    const lugares = Object.values(m.lugares);
    let seat = null;
    let candidato = null;
    if (typeof msg.seatToken === 'string' && msg.seatToken.length >= 32 && msg.seatToken.length <= 128) {
      const h = hash('token\u0000' + msg.seatToken);
      seat = lugares.find((s) => s.tokenHash && s.papel === msg.papel && iguaisTempoConstante(s.tokenHash, h)) ?? null;
    } else if (msg.papel === 'jogadora' || msg.papel === 'espectador') {
      // TODO(JV1.x E-P9): espectador só por convite emitido pelo Mestre; hoje, lugar configurado com senha.
      candidato = lugares.find((s) => s.papel === msg.papel && typeof msg.nome === 'string' && s.nome === msg.nome) ?? null;
      if (candidato && estaBloqueado('lugar:' + candidato.seatId, t)) return bloqueio();
      if (candidato && confereSegredo(candidato.indice, msg.senha)) seat = candidato;
    } else if (msg.papel === 'mestre') {
      // `papel: mestre` sem PIN é recusado. TODO(JV0.5 c / A-3): autenticação da C-17.
      candidato = lugares.find((s) => s.papel === 'mestre') ?? null;
      if (candidato && estaBloqueado('lugar:' + candidato.seatId, t)) return bloqueio();
      if (candidato && typeof msg.pin === 'string' && confereSegredo(candidato.indice, msg.pin)) seat = candidato;
    }
    if (!seat) {
      const alertas = [];
      if (registrarFalha('ip:' + ip, t)) alertas.push(...alertaMestre('bloqueio_join', { alvo: 'ip' }));
      if (candidato && registrarFalha('lugar:' + candidato.seatId, t)) {
        alertas.push(...alertaMestre('bloqueio_join', { alvo: 'lugar', papel: candidato.papel, nome: candidato.nome }));
      }
      return falha([msgErro('credenciais', 'Não foi possível entrar.')], alertas);
    }
    tentativas.delete('ip:' + ip);
    tentativas.delete('lugar:' + seat.seatId);

    const token = novoToken(); // roda a cada JOIN; vinculado ao seatId; só o hash fica no estado
    const { saidas } = transacao((tx) => {
      const s = tx.estado.lugares[seat.seatId];
      s.tokenHash = hash('token\u0000' + token);
      s.epoch += 1;
      if (s.epoch === 1 && s.papel === 'jogadora') {
        const f = tx.estado.figuras[s.figuraId];
        tx.emitir('entrada', { figuraId: f.id, nomePublico: nomePublicoDe(fichaDe(f)), lado: f.lado }, null);
      }
    });
    const outros = saidas.filter((x) => x.seatId !== seat.seatId); // a própria recebe o snapshot
    const welcome = {
      v: PROTOCOLO, type: 'ROOM_WELCOME', roomId, seatId: seat.seatId, seatToken: token, papel: seat.papel,
      protocolo: PROTOCOLO, motores: { ...motoresInfo },
    };
    const sinc = mensagensDeSincronizacao(seat.seatId, msg.lastSeq).map((x) => x.msg);
    const fecharAnteriores = seat.papel !== 'mestre' && (conexoes.get(seat.seatId) ?? 0) > 0;
    if (fecharAnteriores) outros.push(...alertaMestre('segunda_ligacao', { papel: seat.papel, nome: seat.nome }));
    return { ok: true, seatId: seat.seatId, mensagens: [welcome, ...sinc], saidas: outros, fecharAnteriores };
  }

  // =================================================================== API pública
  /** Fila síncrona por sala (E-C9). Devolve as saídas [{seatId, msg}] de tudo o que processou. */
  function receber(seatId, msg) {
    fila.push([seatId, msg]);
    if (drenando) return [];
    drenando = true;
    const saidas = [];
    try {
      while (fila.length) {
        const [s, m] = fila.shift();
        try {
          saidas.push(...processarUm(s, m));
        } catch (e) {
          if (depurar) throw e;
          saidas.push({ seatId: s, msg: msgErro('interno', 'Erro interno. Nada foi gravado.') });
        }
      }
    } finally {
      drenando = false;
    }
    return saidas;
  }

  function conexaoAberta(seatId) {
    if (!journal.estado.lugares[seatId]) return [];
    conexoes.set(seatId, (conexoes.get(seatId) ?? 0) + 1);
    return [];
  }

  function conexaoFechada(seatId) {
    const s = journal.estado.lugares[seatId];
    if (!s) return [];
    const n = Math.max(0, (conexoes.get(seatId) ?? 0) - 1);
    conexoes.set(seatId, n);
    // E-C4: Mestre caído = zero ligações de Mestre vivas → a mesa congela.
    if (s.papel === 'mestre' && n === 0) return transacao((tx) => pausar(tx, 'mestre_desconectado', 'desconexao')).saidas;
    return [];
  }

  return Object.freeze({
    get roomId() {
      return roomId;
    },
    entrar,
    receber,
    conexaoAberta,
    conexaoFechada,
    exportar: () => journal.exportar({ chave: chaveJournal ?? undefined }),
    lugares: () => Object.values(journal.estado.lugares).map((s) => ({ seatId: s.seatId, papel: s.papel, nome: s.nome })),
    // Só para testes e ferramentas do Mestre: nunca ligar isto a uma rota pública.
    depuracao: Object.freeze({
      estado: () => clonarJson(journal.estado),
      eventos: () => journal.eventos(),
      journalSeq: () => journal.journalSeq,
      hashEstado: () => journal.hashEstado(),
      opcoes: (figuraId) => calcularOpcoes(journal.estado, figuraId),
      recibo: (seatId, id) => clonarJson(journal.recibo(chaveRecibo(seatId, id))),
    }),
  });
}
