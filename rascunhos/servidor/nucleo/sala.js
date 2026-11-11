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
import { criarJournal, restaurarJournal, ErroJournal } from './journal.js';
import { projetarEvento, projetarSnapshot, efeitoAmbiente, nomePublicoDe, visivelDe } from './projecao.js';
import * as Amb from './ambiente.js';

export const PROTOCOLO = 2;
/** A escala com que a sala nasce (Q5 do site, jogo.js: CASA_M = 1,5 m). Ordem 8 do CM-000009 (item 8, desempate do
 *  Mestre 09/11 08:18): o Mestre pode mudar a escala a meio da batalha (MASTER_SUPERVISOR op 'escala'); a escala viva é
 *  `mapa.casaM` do estado, e é essa que conta em todo o lado (casaDe). */
export const CASA_M = 1.5;
/** Ordem 11 do CM-000009 (paridade P8a; site REF_36, ESCALAS_CASA_M em jogo.js): as ÚNICAS escalas que valem, em metros
 *  por casa. Outro valor é recusado (acao_invalida, com o detalhe ESCALA_INVALIDA no registo do Mestre). */
export const ESCALAS_CASA_M = Object.freeze([1, 1.5, 2]);
export const MAX_INTENCOES_TURNO = 20; // E-C12, invariante 12
const MAX_CHECKPOINTS = 500;
// Ordem 18 (omisso 17-1): tecto do travão do ROOM_JOIN (entradas 'ip:'); poda-se até 90 % para não podar a cada falha.
export const MAX_TRAVAO = 4096;
const MAX_TRAVAO_PODA = Math.floor(MAX_TRAVAO * 0.9);
/** L8: quantos pontos de «voltar» vão na MASTER_VIEW (os mais novos). */
const MAX_PONTOS_VISTA = 50;
const EPS = 1e-9;
const VIZ4 = Object.freeze([[1, 0], [-1, 0], [0, 1], [0, -1]]); // sem diagonais (REF_7 §3)

// §3.1 + `correr` e `apanhar_arma` (ERRATA v0.2.2 do protocolo; REF_7 §2 e §4).
export const TIPOS_ACAO = Object.freeze([
  'mover', 'atacar', 'consumivel', 'defender', 'desvincular', 'transformar', 'reacao', 'encerrar', 'correr',
  'apanhar_arma', 'curar', 'apagar_fogo',
]);
// P3: todo o laço de rejeição tem teto. Passar dele é rng avariado: lança (a transação desfaz tudo).
export const MAX_TENTATIVAS_LACO = 1000;

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
/**
 * L2 do desenho JV3.1 (revisão do Muse, 08/11): a lista que o Mestre pode escolher no «Escolher outra» do cartão de
 * desgraça. Vai dentro do MASTER_CARD e o servidor só aceita uma escolha que esteja nela.
 * Regra-mãe do Mestre (08/11, «vale o site»): no site a rolagem da falha crítica NUNCA se deita fora (jogo.js J1 e
 * EM-J1-04: o «Voltar» devolve à mesma rolagem; só o Confirmar a resolve). Por isso já não há «nenhuma» nem
 * «recusar» na desgraça — e o VLAB não tem «nenhuma» na tabela. As que o motor declara inaplicáveis nesta cena
 * (`falhaCritica.excluidas`: sem arma, sem aliado) saem da lista do cartão.
 */
const DESGRACAS_EDITAVEIS = DESGRACAS;
const RESULTADOS = Object.freeze({
  // Nomes REAIS do VLAB (medidos no CI, run 42315490663, 74 chamadas): acerta, erra, critico, falhaCritica.
  acerta: 'acerto', erra: 'erro', critico: 'critico', falhaCritica: 'falha_critica',
  // Nomes do motor falso dos testes (o servidor fala 'acerto/erro/falha_critica' para dentro).
  acerto: 'acerto', erro: 'erro', falha_critica: 'falha_critica',
});

/**
 * Dano que o alvo sofre de facto.
 * VLAB real: `danoAplicado = dmg` é o objeto CRU do DMG {parcelas, total, dme, recibo, rdAplicada, erro}, ANTES da RD
 * ("totalEfectivo = Math.max(0, dmg.total - rdAplicada)"; na falha crítica "totalEfectivo = 0"). Por isso, com a forma
 * real, o número certo é o `totalEfectivo`; o `danoAplicado.total` só serve de recurso.
 * O motor falso dá `danoAplicado` como número (e o `totalEfectivo` dele é o total do ATAQUE): fica como estava.
 */
function danoTotalDe(saida) {
  const d = saida?.danoAplicado;
  if (typeof d === 'number' && Number.isFinite(d)) return d;
  if (d && typeof d === 'object') {
    if (typeof saida.totalEfectivo === 'number' && Number.isFinite(saida.totalEfectivo)) return Math.max(0, saida.totalEfectivo);
    if (Number.isFinite(d.total)) return d.total;
  }
  return 0;
}

/**
 * Total e faces do ataque, para a jogadora que atacou (v0.2.1).
 * VLAB real: `rolagem = {expressao, conjuntosDeFaces, bonus, ajusteVantagemDesvantagem, niveisLiquidos, resultados,
 * escolhido: total, total}`. `conjuntosDeFaces` é um array de arrays (1 + |nível líquido| conjuntos) e
 * `resultados[i]` é a soma do conjunto i com o bónus; mostram-se as faces do conjunto ESCOLHIDO.
 * O falso dá `rolagem.faces` (lista simples).
 */
function rolagemVisivel(saida) {
  const r = saida?.rolagem && typeof saida.rolagem === 'object' ? saida.rolagem : {};
  const total = numeroOuNull(r.total ?? r.escolhido ?? r.totalAtaque ?? saida?.total);
  let faces = null;
  if (Array.isArray(r.faces)) faces = r.faces;
  else if (Array.isArray(r.conjuntosDeFaces) && r.conjuntosDeFaces.length) {
    let i = Array.isArray(r.resultados) && total !== null ? r.resultados.indexOf(total) : -1;
    if (i < 0 || !Array.isArray(r.conjuntosDeFaces[i])) i = 0;
    faces = Array.isArray(r.conjuntosDeFaces[i]) ? r.conjuntosDeFaces[i] : null;
  }
  return { total, faces: faces ? faces.filter((x) => Number.isInteger(x)) : null };
}

/** Id de uma desgraça. VLAB real: objeto {id, nome, gravidade}; o falso usa {tipo} ou uma string. */
function idDesgraca(d) {
  if (typeof d === 'string') return d;
  if (d && typeof d === 'object') {
    if (typeof d.id === 'string') return d.id;
    if (typeof d.tipo === 'string') return d.tipo;
  }
  return null;
}

/** Técnica que usa arma. VLAB real: "const usaArmaTec = tecnica.usaArma !== false" (sem o campo, USA arma). */
function usaArmaDe(t) {
  return t.usaArma !== false;
}
const TIPOS_MESTRE = Object.freeze([
  'MASTER_LOBBY_SET', 'MASTER_START', 'MASTER_PLACE', 'MASTER_MODE', 'MASTER_ACT', 'MASTER_APPROVE',
  'MASTER_CONFIRM_DICE', 'MASTER_AMBIENTE', 'MASTER_SUPERVISOR', 'MASTER_PAUSE', 'MASTER_RESUME',
]);
const RE_ID = /^[A-Za-z0-9_-]{1,64}$/;
// `cartoes` entra no checkpoint para o «voltar» repor os cartões do instante (rolagem por resolver incluída).
// Ordem 13: `fogo` (casas a arder, quem arde) também volta com o «voltar».
const CHAVES_MUNDO = Object.freeze(['fase', 'mapa', 'lobby', 'figuras', 'ordem', 'vezIdx', 'rodada', 'vez', 'ambiente', 'desfecho', 'cartoes', 'marchaLivre', 'fogo']);
/**
 * L6 (D4 do Plano A, desenho JV3.1; I0004 08/11): «marcha pura» = proposta da IA sem efeito de regra sobre ninguém
 * (andar ou encerrar a vez). Com o «Continuar a rodada» do Mestre (MASTER_APPROVE {rodada:true}), as marchas puras
 * das criaturas em semi seguem sem cartão até ao fim dessa rodada. Ataques e o resto continuam a pedir cartão.
 */
const MARCHA_PURA = Object.freeze(new Set(['mover', 'encerrar']));

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
    curar: ['tipo', 'alvoId', 'tecnica'],
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
    case 'curar':
      return typeof a.alvoId === 'string' && a.alvoId.length >= 1 && a.alvoId.length <= 64
        && typeof a.tecnica === 'string' && a.tecnica.length >= 1 && a.tecnica.length <= 64;
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
    case 'curar':
      return (ops.curas ?? []).some((o) => o.alvoId === acao.alvoId && o.tecnica === acao.tecnica);
    default:
      return ops.acoes.includes(acao.tipo);
  }
}

const FASES_SALA = Object.freeze(['lobby', 'combate', 'pausa', 'fim']);
const ehObj = (v) => v !== null && typeof v === 'object' && !Array.isArray(v);
/**
 * Ordem 18 (V10): o estado restaurado tem de ter a forma da sala (`sala/1`). O restaurarJournal confere a assinatura e o
 * corpo do journal, não o estado da sala; sem chave, um `sha256:` recalcula-se. Um estado sem lugares (ou com eles
 * estragados) dava TypeError — que o adaptador não trata como «journal recusado» — ou abria uma sala que rebentava no
 * primeiro ROOM_JOIN. Só a forma que o próprio servidor sempre escreveu; nenhuma regra de jogo.
 */
function conferirFormaDoEstado(e) {
  const lugares = ehObj(e?.lugares) ? Object.entries(e.lugares) : null;
  const ok = ehObj(e) && e.formato === 'sala/1' && typeof e.roomId === 'string' && FASES_SALA.includes(e.fase)
    && lugares !== null
    && lugares.every(([k, s]) => ehObj(s) && s.seatId === k && ['jogadora', 'espectador', 'mestre'].includes(s.papel)
      && Number.isInteger(s.seq) && Number.isInteger(s.revision))
    && lugares.filter(([, s]) => s.papel === 'mestre').length === 1
    && ehObj(e.figuras) && Object.values(e.figuras).every(ehObj)
    && ehObj(e.mapa) && Array.isArray(e.ordem) && Array.isArray(e.cartoes) && ehObj(e.contadores)
    && (e.fase !== 'pausa' || (ehObj(e.pausa) && FASES_SALA.includes(e.pausa.faseAnterior)));
  if (!ok) throw new ErroJournal('estado da sala com forma inválida');
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
 * @param {(faces:number) => number} [p.dadoAmbiente]  dado do raio e do fogo (ordem 13): 1..faces. Por omissão, sai do rng.
 * @param {string} [p.restaurarDe]  exportação do journal (restaura em vez de criar)
 * @param {string} [p.chaveJournal]  chave HMAC da exportação
 */
export function criarSala({
  motores, fichas, rng, rngSemente, agora, hash = sha256Hex, config = {}, restaurarDe = null, chaveJournal = null,
  dadoAmbiente = null,
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
  const tentativas = new Map(); // travão do ROOM_JOIN (E-P9); com tecto (ordem 18, omisso 17-1): ver registrarFalha
  const ritmo = new Map(); // seatId → carimbos (10 intenções/s)
  // Ordem 18 (omisso 17-4): o RESYNC e a RECEIPT_QUERY têm o seu próprio balde, com o mesmo número do §2 (10/s), para
  // não gastarem o ritmo dos comandos (um cliente que volta a ligar-se pede-os em rajada) nem ficarem sem limite.
  const ritmoSinc = new Map(); // seatId → carimbos
  // Ordem 18 (omisso 17-2): a sala restaurada acorda sem ninguém ligado. Enquanto o Mestre não voltar, a primeira
  // entrada de outro lugar em combate pausa a mesa (E-C4), como se o Mestre tivesse caído.
  let vigiarMestreAusente = !!restaurarDe;
  const checkpoints = new Map(); // journalSeq → mundo (para MASTER_SUPERVISOR voltar)
  // L8 do desenho JV3.1 (I0004, 08/11): o resumo de cada ponto guardado, para o Mestre saber a que pontos
  // pode voltar. Vai SÓ na MASTER_VIEW (o lugar do Mestre), em `pontos`.
  const pontosInfo = new Map(); // journalSeq → {journalSeq, ts, fase, rodada, vezId, tipos}
  // L9 (C-28): sala de TESTE (config.teste === true). O selo só aparece ao Mestre (MASTER_VIEW.selo).
  const seloTeste = config.teste === true ? 'TESTE' : null;
  const fila = [];
  let drenando = false;

  // ------------------------------------------------------------------ journal
  let roomId = typeof config.roomId === 'string' ? config.roomId : 'sala-' + hex8(rng());
  let journal;
  if (restaurarDe) {
    journal = restaurarJournal(restaurarDe, { chave: chaveJournal ?? undefined, hash });
    conferirFormaDoEstado(journal.estado);
    roomId = journal.estado.roomId;
  } else {
    journal = criarJournal({ estadoInicial: construirEstadoInicial(), hash });
  }
  guardarCheckpoint();
  if (restaurarDe && (journal.estado.motores?.vlabSha ?? null) !== motoresInfo.vlabSha) {
    // E-C11: versão de motor diferente ao acordar → ROOM_PAUSED {manutencao}.
    // TODO(JV3.x): procedimento de migração de versão do motor (o Mestre decide).
    transacao((tx) => {
      if (pausar(tx, 'manutencao', 'motor')) return;
      // Ordem 17 (V1): a sala já vinha em pausa (ex.: o Mestre tinha caído). Antes ficava a pausa antiga, e a volta do
      // Mestre (RESYNC, origem 'desconexao') ou o MASTER_RESUME retomavam a mesa com o motor novo, furando a E-C11.
      // A pausa passa a ser do motor. Só no registo do Mestre: o evento `pausa` não está na lista da Party, não há
      // anúncio novo e o motivo que a Party já viu fica o mesmo. (Sala no fim: ver omisso 17-3 no README.)
      const p = tx.estado.pausa;
      if (tx.estado.fase !== 'pausa' || !p || p.origem === 'motor') return;
      const origemAnterior = p.origem;
      p.origem = 'motor';
      tx.emitir('pausa', { motivo: p.motivo }, { origem: 'motor', origemAnterior });
    });
  }

  // =================================================================== utilitários
  function u32() {
    return rng() >>> 0;
  }
  function novoId(prefixo, existentes) {
    // E-P14: ids opacos e aleatórios por sala. P3: com teto (64 bits não colidem 1000 vezes seguidas sem rng avariado).
    for (let i = 0; i < MAX_TENTATIVAS_LACO; i++) {
      const id = prefixo + hex8(u32()) + hex8(u32());
      if (!existentes || !(id in existentes)) return id;
    }
    throw new Error('novoId: ' + MAX_TENTATIVAS_LACO + ' colisões seguidas (rng avariado)');
  }
  function novoToken() {
    return hex8(u32()) + hex8(u32()) + hex8(u32()) + hex8(u32()); // 128 bits
  }
  function dN(faces) {
    const limite = Math.floor(0x100000000 / faces) * faces; // rejeição: sem viés de módulo
    // P3: a rejeição é rara (< faces/2^32); 1000 seguidas = rng avariado.
    for (let i = 0; i < MAX_TENTATIVAS_LACO; i++) {
      const x = u32();
      if (x < limite) return 1 + (x % faces);
    }
    throw new Error('d' + faces + ': ' + MAX_TENTATIVAS_LACO + ' rejeições seguidas (rng avariado)');
  }
  function d6() {
    return dN(6);
  }
  /** Ordem 13: o dado do ambiente (raio e fogo). Um dado injetado que saia de 1..faces é avaria: lança. */
  function dadoAmb(faces) {
    if (typeof dadoAmbiente !== 'function') return dN(faces);
    const v = dadoAmbiente(faces);
    if (!Number.isInteger(v) || v < 1 || v > faces) throw new Error('dadoAmbiente: ' + v + ' fora de 1..' + faces);
    return v;
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
      // Ordem 13: `raios` (o interruptor do painel), `raioPendente` («Raio agora» à espera do momento de ambiente) e
      // `raioPedidoRodada` (um pedido por rodada, como o site). Tudo só do Mestre.
      ambiente: { hora: null, clima: null, futuro: null, raios: false, raioPendente: false, raioPedidoRodada: 0 },
      fogo: Amb.fogoVazio(),
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
  /** Metros por casa NESTA sala (ordem 8: a escala muda a meio da batalha; as posições ficam em casas). */
  function casaDe(m) {
    const c = m?.mapa?.casaM;
    return typeof c === 'number' && Number.isFinite(c) && c > 0 ? c : CASA_M;
  }
  function distanciaM(m, a, b) {
    return Math.hypot(a.x - b.x, a.y - b.y) * casaDe(m);
  }
  /**
   * Ordem 11 do CM-000009 (paridade P8b; site REF_36 Emenda 1, jogo.js alcanceEmCasas): o alcance conta-se em CASAS na
   * escala viva, com piso de 1 casa — alcanceEmCasas = max(1, metros / casaM). Toda a técnica chega pelo menos à casa
   * vizinha, seja qual for a escala (ex.: 1,5 m com casa de 2 m chega à vizinha; com casa de 1 m chega a 1,5 casas).
   */
  function alcanceEmCasas(m, metros) {
    return Math.max(1, metros / casaDe(m));
  }
  /**
   * Ordem 15 do CM-000009 (palavra do Mestre, 2026-11-10; CAI a decisão B9 do JV, a régua a direito): o alcance mede-se
   * pelo CAMINHO DAS CASAS, como no site (jogo.js distanciaEntre): BFS de 4 vizinhos dentro do mapa, com as OUTRAS
   * figuras vivas a bloquear a passagem (quem mede e o alvo não contam; o cadáver não bloqueia, T-J12J13) e a casa do
   * alvo a contar como destino. Devolve os passos, ou Infinity se não houver caminho.
   */
  function distanciaCasas(m, a, b) {
    if (a.x === b.x && a.y === b.y) return 0;
    const bloqueia = new Set();
    for (const f of colocadas(m)) {
      if (f.id === a.id || f.id === b.id || !f.vivo) continue;
      bloqueia.add(chaveCasa(f.x, f.y));
    }
    const destino = chaveCasa(b.x, b.y);
    const vistos = new Set([chaveCasa(a.x, a.y)]);
    const filaBfs = [{ x: a.x, y: a.y, passos: 0 }];
    for (let i = 0; i < filaBfs.length; i++) {
      const c = filaBfs[i];
      for (const [dx, dy] of VIZ4) {
        const x = c.x + dx;
        const y = c.y + dy;
        if (!dentro(m, x, y)) continue;
        const k = chaveCasa(x, y);
        if (k === destino) return c.passos + 1;
        if (vistos.has(k) || bloqueia.has(k)) continue;
        vistos.add(k);
        filaBfs.push({ x, y, passos: c.passos + 1 });
      }
    }
    return Infinity;
  }
  /** O alvo está ao alcance da técnica: passos pelo caminho das casas ≤ alcanceEmCasas (com o piso de 1 casa). */
  function aoAlcance(m, a, b, metros) {
    return distanciaCasas(m, a, b) <= alcanceEmCasas(m, metros) + EPS;
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

  /** Q4: jogadora estabilizada (viva, caída com 1 de Vida, à espera de cura). */
  function estabilizadaSemCura(f) {
    return f.lado === 'jogadora' && f.vivo && f.estadoMorte?.fase === 'estabilizado';
  }

  /**
   * Alvo que a cura do motor aceita (site REF_31, vlab-completo.js aplicarCura): a Vida 0 só o ESTABILIZADO
   * (CURA_SOBRE_QUEM_ESTA_A_MORRER, CURA_NAO_RESSUSCITA); com a Vida cheia, não (CURA_ALVO_VIDA_CHEIA).
   * A estabilizada da Q4 está a 1 de Vida: entra pela regra geral e a cura soma por cima do 1.
   */
  function curavel(alvo) {
    const total = fichaEfetiva(alvo).vidaTotal;
    if (!Number.isFinite(total) || !Number.isFinite(alvo.vidaActual)) return false;
    if (alvo.vidaActual <= 0 && alvo.estadoMorte?.fase !== 'estabilizado') return false;
    return alvo.vidaActual < total;
  }

  /** Jogadora fora de combate: a morrer, estabilizada ou com Vida 0 (o VLAB marca `foraDeCombate`). */
  function jogadoraForaDeCombate(f) {
    if (f.lado !== 'jogadora') return false;
    const fase = f.estadoMorte?.fase;
    // VLAB real: as fases do estadoMorte são só 'aMorrer' e 'estabilizado' (a morte vem em `morteAdjudicada`).
    return fase === 'aMorrer' || fase === 'estabilizado' || f.vidaActual <= 0;
  }

  /** Metros do Correr, ou null se o motor recusar. Opção honesta: só aparece se der. */
  function metrosCorrida(f, acaoPadraoDisponivel = true) {
    const base = reservaBase(f);
    const fn = motores.Vlab.validarCorrer;
    if (typeof fn !== 'function') {
      // TODO(R0): regra do Correr sem o motor. Provisório: o dobro da reserva base (é o que o VLAB faz).
      return arred(base * 2);
    }
    let r;
    try {
      // VLAB real: validarCorrer({deslocamentoBase, acaoPadraoDisponivel}) → {deslocamentoMaximo, custoDeclarado, erro}.
      // Sem `acaoPadraoDisponivel` devolve erro CORRER_SEM_ACCAO_PADRAO (antes o Correr nunca aparecia com o real).
      // `deslocamentoBase` vai já com as metades de Fraca e de corpo partido (o motor pede-o assim).
      r = fn({ deslocamentoBase: base, acaoPadraoDisponivel: acaoPadraoDisponivel === true });
    } catch {
      return null;
    }
    if (!r || typeof r !== 'object' || r.valido === false || r.erro) return null;
    // VLAB real: `deslocamentoMaximo`. Os outros nomes ficam para o motor falso dos testes.
    const metros = r.deslocamentoMaximo ?? r.deslocamentoM ?? r.metros ?? r.reservaM;
    return typeof metros === 'number' && Number.isFinite(metros) && metros >= 0 ? arred(metros) : null;
  }

  /**
   * Ataques de oportunidade pelo motor. `candidatos` = monstros dos grupos A e B (já sem os cobertos).
   * VLAB real: validarSaidaDeAdjacencia({inimigosAdjacentes:[{id, reacaoDisponivel}], desvincular?:{gastouAccaoPadrao}})
   *   → {ataquesDeOportunidade:[{inimigoId, instrucao}], cobertosPorDesvincular:[id], erro}. O motor só filtra por
   *   `reacaoDisponivel` (não lê caído nem vivo: isso filtra-se aqui antes).
   * Sem a função, com exceção ou com outra forma (o falso dá {valido:true}): devolve null e a sala usa a lista dela.
   */
  function aooPeloMotor(candidatos, desvincular) {
    const fn = motores.Vlab.validarSaidaDeAdjacencia;
    if (typeof fn !== 'function') return null;
    let r;
    try {
      const entrada = { inimigosAdjacentes: candidatos.map((x) => ({ id: x.id, reacaoDisponivel: !!x.reacaoDisponivel })) };
      if (desvincular) entrada.desvincular = { gastouAccaoPadrao: true };
      r = fn(entrada);
    } catch {
      return null;
    }
    if (!r || typeof r !== 'object' || r.erro) return null;
    if (desvincular) return Array.isArray(r.cobertosPorDesvincular) ? r.cobertosPorDesvincular.filter((x) => typeof x === 'string') : null;
    if (!Array.isArray(r.ataquesDeOportunidade)) return null;
    return r.ataquesDeOportunidade.map((a) => a && a.inimigoId).filter((x) => typeof x === 'string');
  }

  function opcoesVazias(m) {
    return { vezId: m.vez?.figuraId ?? null, orcamentoM: 0, mover: [], ataques: [], curas: [], consumiveis: [], acoes: [], reacoes: [] };
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
    if (jogadoraForaDeCombate(f)) {
      // A morrer: a vez dela foi o teste de morte. Estabilizada ou com Vida 0: fora de combate.
      // Q4 (decisão 4 do Mestre): a estabilizada não luta até uma cura; avancarVez já lhe salta a vez.
      return { ...opcoesVazias(m), vezId: figuraId, acoes: ['encerrar'] };
    }

    const mover = [];
    // Ordem 8: a reserva está em METROS; as casas que ela paga contam-se na escala viva (o já gasto não se reconverte).
    const maxCasas = Math.floor(v.reservaM / casaDe(m) + EPS);
    if (maxCasas > 0) {
      const r = bfs(m, f, maxCasas, f.id);
      for (const [k, d] of r.dist) {
        if (d === 0 || r.ocupadas.has(k)) continue; // não se acaba em cima de ninguém (nem de cadáver)
        const c = r.casas.get(k);
        mover.push({ x: c.x, y: c.y, custoM: arred(d * casaDe(m)) });
      }
      mover.sort((a, b) => a.custoM - b.custoM || a.y - b.y || a.x - b.x);
    }

    const ataques = [];
    if (!v.atacou) {
      for (const t of ficha.tecnicas) {
        // VLAB real: sem `usaArma` a técnica USA arma (usaArma !== false); antes a sala só olhava para `usaArma === true`.
        // Q8 + site («fica inutilizável até ser consertada»): não há conserto em combate; a sala esconde a técnica
        // (REF_7 §5) e o VLAB recusa-a de qualquer modo (ARMA_QUEBRADA).
        if (usaArmaDe(t) && f.armaQuebrada) continue;
        // A jogadora com a arma caída tem de a apanhar primeiro (`apanhar_arma`). VLAB real: sem isso dá ARMA_CAIDA.
        if (usaArmaDe(t) && f.armaCaida && f.lado === 'jogadora') continue;
        if (f.lado === 'jogadora' && t.custoPA > paLivre(f)) continue; // os monstros não gastam PA
        for (const alvo of colocadas(m)) {
          if (alvo.id === f.id || !alvo.vivo || !saoInimigos(f, alvo)) continue;
          // Ordem 15: o caminho das casas, com as figuras a bloquear (site distanciaEntre; cai o B9); ordem 11: piso de 1 casa.
          if (!aoAlcance(m, f, alvo, t.alcanceM)) continue;
          ataques.push({ alvoId: alvo.id, arma: t.id });
        }
      }
    }

    // Ordem 7 (CM-000009): acção de CURA, pelas regras do site (REF_31: vlab-completo.js aplicarCura + jogo.js
    // vlabAplicarCuraDepois). A cura é componente declarado (`expressaoCura`) de uma técnica da ficha; os alvos são os
    // que o motor aceita (cura não ressuscita, não acorda quem está a morrer, não passa da Vida cheia).
    const curas = [];
    if (!v.atacou) {
      for (const t of ficha.tecnicas) {
        if (typeof t.expressaoCura !== 'string') continue;
        if (f.lado === 'jogadora' && t.custoPA > paLivre(f)) continue; // o motor recusa PA_INSUFICIENTE; não forçamos
        for (const alvo of colocadas(m)) {
          if (!alvo.vivo || saoInimigos(f, alvo) || !curavel(alvo)) continue;
          if (!aoAlcance(m, f, alvo, t.alcanceM)) continue; // ordens 11 e 15: a mesma régua do ataque
          curas.push({ alvoId: alvo.id, tecnica: t.id });
        }
      }
    }

    const acoes = ['encerrar'];
    // Correr: substitui a reserva; só se ainda não andou nem atacou.
    // TODO(R0 §9.9): pode-se Correr depois de andar uma parte? Hoje não (REF_7).
    if (!v.atacou && v.andouM === 0 && !v.correrUsado && metrosCorrida(f, !v.atacou) !== null) acoes.push('correr');
    if (f.lado === 'jogadora') {
      // Errata v0.2.2: `apanhar_arma` só com a arma caída; gasta a reserva toda (sem reserva, não há com que pagar).
      // TODO(R0): apanhar a arma com a reserva já a zero (ex.: na vez em que se levantou) é permitido?
      if (f.armaCaida && v.reservaM > EPS) acoes.push('apanhar_arma');
      // Ordem 15 (site rfPodeApagarFogo): a arder fora do fogo e sem chuva, apagar-se gasta a Acção de Movimento.
      // O site não pede reserva por gastar (zera-a, como ao levantar-se do Caído); aqui também não.
      if (Amb.podeApagarSeco(m, f)) acoes.push('apagar_fogo');
      if (f.reacaoDisponivel && !f.defendendo) acoes.push('defender');
      if (!v.atacou && !v.desvinculou && monstrosAdjacentes(m, f, f).length > 0) acoes.push('desvincular');
      const tr = fichaDe(f).transformacao;
      const custoTr = Number.isInteger(tr?.custo) ? tr.custo : 0;
      if (!v.atacou && tr && !f.transformada && custoTr <= paLivre(f)) acoes.push('transformar');
    }
    // TODO(JV1.x): consumíveis (REF_7 §9.10: ainda sem conteúdo) e reações (A-4: janela de reação).
    return { vezId: figuraId, orcamentoM: arred(v.reservaM), mover, ataques, curas, consumiveis: [], acoes, reacoes: [] };
  }

  function destinatario(s) {
    return { papel: s.papel, figuraId: s.figuraId, seatId: s.seatId };
  }

  /** Opções que este lugar recebe agora (ou null). Com cartão aberto, ninguém tem opções. */
  function opcoesDoLugar(m, s) {
    if (m.fase !== 'combate' || !m.vez) return null;
    const vezFig = m.figuras[m.vez.figuraId];
    const ativo = cartaoAtivo(m);
    if (ativo) {
      // L10 do desenho JV3.1 (I0004, 08/11): com o cartão de IA aberto, o Mestre recebe as opções da criatura
      // da vez, para o «Escolher outra» (MASTER_APPROVE editar {acao}). Mais ninguém recebe opções com cartão aberto.
      if (s.papel === 'mestre' && ativo.tipo === 'ia' && ativo.figuraId === vezFig.id) return calcularOpcoes(m, vezFig.id);
      return null;
    }
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
    return {
      v: PROTOCOLO, type: 'MASTER_VIEW', roomId, journalSeq: journal.journalSeq, ...projetarSnapshot(m, fichas, destinatario(s)),
      pontos: pontosParaVoltar(),
      // L9 (C-28; I0004 08/11): o selo TESTE e as estatísticas só existem no papel Mestre.
      selo: seloTeste,
      estatisticas: estatisticas(),
    };
  }
  function mensagemCartao(c) {
    return {
      v: PROTOCOLO, type: 'MASTER_CARD', roomId, cartaoId: c.cartaoId, tipo: c.tipo, figuraId: c.figuraId ?? null,
      proposta: clonarJson(c.proposta ?? null), razao: c.razao ?? null, faces: clonarJson(c.faces ?? null),
      intentIdOrigem: c.origem?.id ?? null,
      // L2: só o cartão de desgraça leva a lista do «Escolher outra»; os outros levam null.
      desgracas: c.tipo === 'desgraca' ? desgracasDoCartao(c) : null,
      // Q12 (BANCADA-DESGRACA-JULGAMENTO.md; Musa 08/11 17:03): os amigos elegíveis para o «acerta-amigo», do
      // mais perto para o mais longe. O Mestre declara qual é atingido (edicao.aliadoAtingidoId); sem declarar,
      // vale o primeiro. Só no cartão de desgraça; [] quando o «acerta-amigo» não se pode escolher.
      amigos: c.tipo === 'desgraca' ? amigosDoCartao(c) : null,
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
    if (tx.eventos.length) guardarCheckpoint(tx);
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
  function guardarCheckpoint(tx = null) {
    // TODO(JV1.x): os checkpoints vivem só em memória; depois de restaurar, o "voltar" só alcança o que vier depois.
    const mundo = mundoDe(journal.estado);
    checkpoints.set(journal.journalSeq, mundo);
    pontosInfo.set(journal.journalSeq, {
      journalSeq: journal.journalSeq,
      ts: tx?.ts ?? null,
      fase: mundo.fase,
      rodada: mundo.rodada ?? 0,
      vezId: mundo.vez?.figuraId ?? null,
      tipos: tx ? [...new Set(tx.eventos.map((e) => e.tipo))] : ['inicio'],
    });
    while (checkpoints.size > MAX_CHECKPOINTS) {
      const velho = checkpoints.keys().next().value;
      checkpoints.delete(velho);
      pontosInfo.delete(velho);
    }
  }
  /**
   * L9 (C-28): estatísticas da batalha, só para o Mestre. Contam a história TODA do journal (o «voltar» não
   * apaga história), por figura: ataques feitos, dano causado e sofrido; e as decisões dos cartões.
   */
  function estatisticas() {
    const e = { eventos: journal.journalSeq, rodada: journal.estado.rodada ?? 0, ataques: {}, danoCausado: {}, danoSofrido: {}, cartoes: {} };
    const somar = (o, k, v) => { if (k) o[k] = (o[k] ?? 0) + v; };
    for (const ev of journal.eventos()) {
      if (ev.tipo === 'ataque') somar(e.ataques, ev.dados?.atacanteId, 1);
      if (ev.tipo === 'dano') {
        somar(e.danoCausado, ev.dados?.autorId, ev.dados?.valor ?? 0);
        somar(e.danoSofrido, ev.dados?.alvoId, ev.dados?.valor ?? 0);
      }
      if (ev.tipo === 'dano_ambiente') somar(e.danoSofrido, ev.dados?.alvoId, ev.dados?.valor ?? 0); // ordem 13
      if (ev.tipo === 'cartao_fechado') somar(e.cartoes, ev.dados?.decisao, 1);
    }
    return e;
  }
  /** L8: os pontos a que o «voltar» aceita ir (journalSeq < actual e com checkpoint), do mais novo ao mais velho. */
  function pontosParaVoltar() {
    const saida = [];
    for (const [seq, info] of pontosInfo) if (seq < journal.journalSeq && checkpoints.has(seq)) saida.push(clonarJson(info));
    saida.sort((a, b) => b.journalSeq - a.journalSeq);
    return saida.slice(0, MAX_PONTOS_VISTA);
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
      // Acrescentados (P2: apanhar_arma): a própria sabe da arma e do corpo sem esperar por um snapshot.
      dados.armaCaida = f.armaCaida;
      dados.armaQuebrada = f.armaQuebrada;
      dados.corpoPartido = f.corpoPartido;
    }
    tx.emitir('estado', dados, ehJog ? null : { vidaActual: f.vidaActual, estadoMorte: f.estadoMorte });
  }

  // =================================================================== raio e fogo (ordem 13, dívida E1)
  // As regras vivem em ambiente.js (sem estado próprio, com o dado injetado); aqui só se emitem os eventos.
  //  - `raio` {x, y, alvoId?, desfecho?}: onde caiu e quem atingiu (a Party vê-o, como no site);
  //  - `dano_ambiente` {alvoId, origem 'raio'|'fogo', desfecho} + `valor` só a quem o sofreu;
  //  - `fogo` {casas, aArder, apagados?}: o fogo que a Party vê, sempre que muda;
  //  - o combustível, os dados, o raio pendente e o cancelado ficam no soMestre (e no `ambiente_mestre`).
  function antesDe(f) {
    return { vis: visivelDe(f), vida: f.vidaActual };
  }
  function desfechoPublico(d) {
    return d === 'caiu' || d === 'aMorrer' ? d : 'arde';
  }
  /**
   * Emite os registos do ambiente pela ordem em que aconteceram. `pubAntes` = jsonCanonico do fogo público antes.
   * Devolve true se alguém morreu ou caiu a morrer.
   */
  function emitirAmbiente(tx, regs, pubAntes) {
    const m = tx.estado;
    if (!regs.length) return false;
    let mudouVida = false;
    const apagados = [];
    const extintas = [];
    for (const r of regs) {
      if (r.tipo === 'raio') {
        const dados = { x: r.x, y: r.y };
        if (r.alvoId) Object.assign(dados, { alvoId: r.alvoId, desfecho: desfechoPublico(r.desfecho) });
        tx.emitir('raio', dados, {
          origem: r.origem, combustivel: r.combustivel, cruz: r.cruz,
          ...(r.alvoId ? { tipo: Amb.TIPO_RAIO, bruto: Amb.DANO_RAIO, rd: 0, dano: r.aplicado } : {}),
        });
        if (r.alvoId) {
          const f = m.figuras[r.alvoId];
          tx.emitir('dano_ambiente', {
            alvoId: r.alvoId, origem: 'raio', desfecho: desfechoPublico(r.desfecho), valor: r.aplicado, tipos: [Amb.TIPO_RAIO],
          }, { tipo: Amb.TIPO_RAIO, bruto: Amb.DANO_RAIO, rd: 0, dano: r.aplicado, vidaDepois: f.vidaActual });
          emitirEstado(tx, f, false, r.visAntes, r.vidaAntes);
          mudouVida = mudouVida || !!r.desfecho;
        }
      } else if (r.tipo === 'tick') {
        const f = m.figuras[r.alvoId];
        tx.emitir('dano_ambiente', {
          alvoId: r.alvoId, origem: 'fogo', desfecho: desfechoPublico(r.desfecho), valor: r.aplicado, tipos: [Amb.TIPO_FOGO],
        }, { tipo: Amb.TIPO_FOGO, expressao: '1d' + Amb.FACES_FOGO, faces: r.faces, bruto: r.faces[0], rd: 0, dano: r.aplicado, pegouFogo: r.pegouFogo, vidaDepois: f.vidaActual });
        emitirEstado(tx, f, false, r.visAntes, r.vidaAntes);
        mudouVida = mudouVida || !!r.desfecho;
      } else if (r.tipo === 'extincao') {
        extintas.push({ x: r.x, y: r.y, porque: r.porque });
        if (r.apagouId) apagados.push({ figuraId: r.apagouId, porque: 'chuva-casa' });
      } else if (r.tipo === 'apagado') {
        apagados.push({ figuraId: r.figuraId, porque: r.porque });
      } else if (r.tipo === 'raio_cancelado') {
        tx.emitir('ambiente_mestre', {}, { ...clonarJson(m.ambiente), raioCancelado: true });
      }
    }
    const pub = Amb.fogoPublico(m);
    const mestreFogo = { fogo: Amb.fogoDoMestre(m), extintas };
    if (jsonCanonico(pub) !== pubAntes || apagados.length) {
      tx.emitir('fogo', { ...pub, ...(apagados.length ? { apagados } : {}) }, mestreFogo);
    } else if (extintas.length || regs.some((r) => r.tipo === 'raio')) {
      tx.emitir('ambiente_mestre', {}, { ...clonarJson(m.ambiente), ...mestreFogo });
    }
    return mudouVida;
  }
  /** Momento de ambiente: início da rodada, antes da primeira vez (da 2.ª rodada em diante). */
  function momentoAmbiente(tx) {
    const m = tx.estado;
    const pubAntes = jsonCanonico(Amb.fogoPublico(m));
    // Sem registos, só o combustível pode ter descido (nada público): o Mestre vê-o no MASTER_VIEW seguinte.
    const regs = Amb.momentoDaRodada(m, dadoAmb, antesDe);
    if (!regs.length) return;
    emitirAmbiente(tx, regs, pubAntes);
    verificarFim(tx);
  }
  /** Tick do fogo no início da vez. Devolve 'caiu' se o fogo deitou a figura (a vez não acontece). */
  function tickAmbiente(tx, f) {
    const m = tx.estado;
    const pubAntes = jsonCanonico(Amb.fogoPublico(m));
    const r = Amb.tickInicioDaVez(m, f, dadoAmb, antesDe);
    if (r) emitirAmbiente(tx, [r], pubAntes);
    return r?.tipo === 'tick' ? (r.desfecho ?? 'aplicado') : null;
  }
  /** Acabou um movimento: com chuva, quem arde e saiu do fogo apaga-se (regra 5). */
  function aposMovimentoAmbiente(tx, f) {
    const m = tx.estado;
    const pubAntes = jsonCanonico(Amb.fogoPublico(m));
    const r = Amb.depoisDoMovimento(m, f);
    if (r) emitirAmbiente(tx, [r], pubAntes);
  }

  function iniciarVez(tx, f) {
    const m = tx.estado;
    // Ordem 13: o tick do fogo corre na abertura da vez, antes de tudo (site: ambTickInicioTurno). Se deitar um
    // monstro, a vez não acontece; se deitar a heroína a morrer, a vez dela é o teste de morte (ramo abaixo).
    if (tickAmbiente(tx, f) === 'caiu') {
      avancarVez(tx);
      return;
    }
    f.reacaoDisponivel = true; // uma reação por ronda
    f.defendendo = false; // a declaração de Defender anterior expira
    m.vez = {
      figuraId: f.id, atacou: false, andouM: 0, reservaM: 0, correrUsado: false, desvinculou: false,
      cobertos: [], // ids que o Desvincular cobriu nesta vez (C2, opção B)
      iaMoveu: false, iaPausada: false, recusas: 0, intencoes: 0,
    };
    tx.emitir('turno', { figuraId: f.id, rodada: m.rodada, narra: f.lado !== 'jogadora' }, { modo: f.modo });
    if (f.lado === 'jogadora' && f.estadoMorte?.fase === 'aMorrer') {
      // A Ong nunca sai da ordem: a vez dela vira teste de morte (reserva 0, ação padrão gasta).
      m.vez.atacou = true;
      testeDeMorte(tx, f);
      return;
    }
    if (jogadoraForaDeCombate(f)) {
      // Estabilizada ou com Vida 0: não age. VLAB real recusa o teste de morte em 'estabilizado'.
      m.vez.atacou = true;
      return;
    }
    if (f.caido) {
      // Caída levanta-se e gasta a reserva toda. B6 corrigido: o monstro também se levanta.
      // TODO(R0 §9.4): levantar custa a reserva toda também para o monstro? Hoje sim (IBX-212 J7).
      const vis = visivelDe(f);
      const vida = f.vidaActual;
      f.caido = false;
      emitirEstado(tx, f, false, vis, vida);
      m.vez.reservaM = 0;
    } else {
      m.vez.reservaM = arred(reservaBase(f)); // nasce cheia e não acumula
    }
  }

  /**
   * Teste de morte na vez da jogadora a morrer.
   * VLAB real: resolverTesteDeMorte({moribundo, ajudante?, contexto:{semente|faces}}) lê no moribundo
   *   testesDeMorteDesignado === true, estadoMorte {fase:'aMorrer', sucessos, falhas} (inteiros), constituicao,
   *   classificacao (chave de K_TESTE_DE_MORTE: bronze, prata, ouro, ouroNegro, lendario) e testes.fortitude.
   *   Devolve {cd, cdEfectiva, teste, sucesso, estadoMorte:{fase, sucessos, falhas}, estabilizado, morteAdjudicada,
   *   morteVia, desfecho:'continua'|'estabilizado'|'morreu', publico:{recibo}, soDoMestre:{cd, cdEfectiva, estadoMorte,
   *   rodadaPor}, erro}. NÃO há `moribundoDepois`: antes a sala não aplicava nada da saída real.
   * TODO(R0): estabilização por ajudante (`ajudante`) ainda não tem ação no protocolo.
   */
  function testeDeMorte(tx, f) {
    const fn = motores.Vlab.resolverTesteDeMorte;
    if (typeof fn !== 'function') return; // motor sem teste de morte → a vez fica só com `encerrar`
    const ctx = { semente: sortearSemente() >>> 0 };
    let saida;
    try {
      saida = fn({ moribundo: entidadeMotor(f), contexto: clonarJson(ctx) });
    } catch (e) {
      saida = { erro: 'EXCECAO:' + (e?.message ?? String(e)) };
    }
    if (!saida || typeof saida !== 'object' || saida.erro) {
      const erro = saida?.erro && typeof saida.erro === 'object' ? String(saida.erro.codigo ?? 'ERRO') : String(saida?.erro ?? 'SAIDA_INVALIDA');
      tx.emitir('erro_motor', { figuraId: f.id }, { erro, contexto: ctx });
      return;
    }
    const sm = saida.soDoMestre && typeof saida.soDoMestre === 'object' ? saida.soDoMestre : {};
    // Forma antiga (motor falso): soDoMestre.moribundoDepois / alvoDepois.
    const depois = { ...((sm.moribundoDepois && typeof sm.moribundoDepois === 'object' ? sm.moribundoDepois : null) ?? (sm.alvoDepois && typeof sm.alvoDepois === 'object' ? sm.alvoDepois : {})) };
    // VLAB real: o estadoMorte novo vem no topo (e repetido em soDoMestre.estadoMorte); a morte, em morteAdjudicada.
    const em = saida.estadoMorte ?? sm.estadoMorte;
    if (em && typeof em === 'object') depois.estadoMorte = em;
    if (saida.morteAdjudicada === true || saida.desfecho === 'morreu') depois.morteAdjudicada = true;
    aplicarDepois(f, depois);
    if (f.vivo && f.estadoMorte?.fase === 'estabilizado') {
      // Q4 (decisão 4 do Mestre; site REF_31, jogo.js «danoSofrido = total − 1»): estabilizar NÃO tira da batalha.
      // Volta com 1 de Vida, caída e sem lutar até receber qualquer cura; a cura soma por cima do 1.
      f.vidaActual = 1;
      f.caido = true;
    }
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
    // Q4 (decisão 4 do Mestre, ordem 6; o site já o faz desde a REF_31): estabilizar JÁ NÃO acaba a batalha. A
    // estabilizada fica na batalha, caída, com 1 de Vida, até uma cura a levantar. A derrota é só com todas mortas.
    // (O desfecho 'estabilizada' fica no protocolo por compatibilidade, mas o servidor já não o emite.)
    if (jog.length && jog.every((f) => !f.vivo)) desfecho = 'morte';
    // TODO(JV1.x): a vitória é automática quando todas as criaturas COLOCADAS caem; o Mestre pode querer pôr mais.
    else if (mon.length && mon.every((f) => !f.vivo)) desfecho = 'vitoria';
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
        // Ordem 13: o momento de ambiente abre a rodada, antes da primeira vez (raios, extinção, combustível).
        momentoAmbiente(tx);
        if (m.fase !== 'combate') return; // o raio acabou a batalha (verificarFim já emitiu o `fim`)
      }
      const f = m.figuras[m.ordem[m.vezIdx]];
      if (!f || !f.colocada || !f.vivo) continue; // monstro morto sai da ordem; caído não sai
      // Q4 (site REF_31, passarVez): a estabilizada não perde o lugar na ordem, mas a vez dela SALTA — sem agir e
      // sem testes de morte — até uma cura a levantar.
      if (estabilizadaSemCura(f)) continue;
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
  /**
   * Objeto que o motor recebe: ficha (fixa) + estado da sala (vivo).
   * @param {Object} [op]
   * @param {boolean} [op.comoAlvo]  é o alvo de um ataque (pode levar a reação Defender)
   * @param {boolean} [op.alvoDeAoO]  é o alvo de um ataque de oportunidade (sem reação nenhuma)
   */
  function entidadeMotor(f, op = {}) {
    const ficha = fichaEfetiva(f);
    const estado = [];
    // VLAB real lê estes nomes: "caido" e "fraco" (atacante: desvantagem), "foraDeCombate" (alvo: não repete).
    if (f.caido) estado.push('caido');
    if (ehFraca(f)) estado.push('fraco');
    if (f.vidaActual <= 0) estado.push('foraDeCombate');
    if (f.corpoPartido) estado.push('corpoPartido'); // o motor não o lê: a desvantagem vai em niveisDesvantagem
    const e = {
      ...ficha,
      vidaActual: f.vidaActual,
      paLivre: f.lado === 'jogadora' ? paLivre(f) : ficha.paTotal,
      estado,
      estadoMorte: clonarJson(f.estadoMorte),
      armaCaida: f.armaCaida,
      armaQuebrada: f.armaQuebrada,
    };
    // VLAB real: a corrida 3×3 só nasce com `testesDeMorteDesignado === true` (senão: TESTE_DE_MORTE_NAO_DESIGNADO e,
    // no ataque, a Vida 0 dá só foraDeCombate). A jogadora "nunca sai da ordem" (REF_7 §1): por omissão, designada.
    // TODO(R0): o Mestre designa NPCs/criaturas para testes de morte? Hoje só pela ficha.
    if (typeof ficha.testesDeMorteDesignado !== 'boolean') e.testesDeMorteDesignado = f.lado === 'jogadora';
    if (op.alvoDeAoO) {
      // VLAB real: "if (ctx.ataqueDeOportunidade === true && (alvo.reacaoDefensiva || alvo.defesaAplicavel ||
      // alvo.contraAtaque)) return falha('REACCAO_CONTRA_ATAQUE_DE_OPORTUNIDADE')". REF_7 §3: "sem a reação defensiva".
      delete e.reacaoDefensiva;
      delete e.contraAtaque;
      // `defesaAplicavel` é, para o motor, uma reação-limiar (usouReacaoLimiar). Sai se houver CA para a substituir.
      // TODO(R0): alvo de AoO que só tem defesaAplicavel (sem ca): que defesa vale? Hoje o motor recusa e fica erro_motor.
      if (Number.isFinite(e.ca)) delete e.defesaAplicavel;
    } else if (op.comoAlvo && f.defendendo && config.reacaoDefender && typeof config.reacaoDefender === 'object') {
      // VLAB real: a reação defensiva lê-se do ALVO ("alvo.reacaoDefensiva.valor" substitui a defesa), e não do
      // contexto. Antes a sala punha-a em contexto.reacaoDefensiva, que o motor ignora.
      // TODO(R0): valor da reação Defender (hoje vem só da config do Mestre {tipo, valor, origem}).
      e.reacaoDefensiva = clonarJson(config.reacaoDefender);
    }
    return e;
  }

  function flanqueia(m, atacante, alvo) {
    // REF_7: qualquer figura no lado oposto do alvo. Servidor: cadáveres não dão flanqueamento.
    if (!adjacentes(atacante, alvo)) return false;
    const x = 2 * alvo.x - atacante.x;
    const y = 2 * alvo.y - atacante.y;
    return colocadas(m).some((f) => f.id !== atacante.id && f.id !== alvo.id && f.vivo && f.x === x && f.y === y);
  }

  /**
   * Casas que o segmento entre os centros de `a` e `b` atravessa, sem as duas pontas (supercover, como no C-42
   * desenho v2: quando passa exactamente num canto, entram as duas casas desse canto).
   */
  function casasNaLinha(a, b) {
    const dx = b.x - a.x, dy = b.y - a.y;
    const nx = Math.abs(dx), ny = Math.abs(dy), sx = Math.sign(dx), sy = Math.sign(dy);
    const casas = [];
    let x = a.x, y = a.y, ix = 0, iy = 0;
    while (ix < nx || iy < ny) {
      const d = (1 + 2 * ix) * ny - (1 + 2 * iy) * nx;
      if (d === 0) {
        casas.push({ x: x + sx, y }, { x, y: y + sy });
        x += sx; y += sy; ix++; iy++;
      } else if (d < 0) { x += sx; ix++; } else { y += sy; iy++; }
      casas.push({ x, y });
    }
    const vistas = new Set();
    return casas.filter((c) => {
      const k = chaveCasa(c.x, c.y);
      if (vistas.has(k) || (c.x === b.x && c.y === b.y) || (c.x === a.x && c.y === a.y)) return false;
      vistas.add(k);
      return true;
    });
  }
  /**
   * Q12 «amigo ao alcance» (julgamento da casa de 2026-11-03, bancada da desgraça; Musa 08/11/2026 16:31): aliado do
   * atacante (do mesmo lado, vivo, colocado, que não é o alvo) ADJACENTE ao atacante ou NA LINHA entre ele e o alvo.
   * Lista ordenada por proximidade ao atacante (empate: id), para o VLAB escolher «primeiroDaListaPorProximidade».
   * O site é uma batalha a solo e manda sempre `[]` (jogo.js: «sem aliados de nenhum dos lados nesta casca»): a forma
   * {id, posicao: 'adjacente'|'naLinha'} é a que o VLAB lê. Quem está adjacente e na linha conta como 'adjacente'.
   */
  function aliadosAoAlcance(m, atacante, alvo) {
    const linha = new Set(casasNaLinha(atacante, alvo).map((c) => chaveCasa(c.x, c.y)));
    return colocadas(m)
      .filter((f) => f.id !== atacante.id && f.id !== alvo.id && f.vivo && !saoInimigos(atacante, f))
      .map((f) => ({ f, posicao: adjacentes(atacante, f) ? 'adjacente' : linha.has(chaveCasa(f.x, f.y)) ? 'naLinha' : null }))
      .filter((a) => a.posicao)
      .sort((p, q) => distanciaM(m, atacante, p.f) - distanciaM(m, atacante, q.f) || (p.f.id < q.f.id ? -1 : p.f.id > q.f.id ? 1 : 0))
      .map((a) => ({ id: a.f.id, posicao: a.posicao }));
  }

  function montarContexto(m, atacante, alvo, extra) {
    const ctx = {
      semente: sortearSemente() >>> 0, // uma por resolução, gravada no evento
      verificacaoCritico: [d6(), d6(), d6()], // errata JV1.1-a §6: o servidor gera-a por CSPRNG
      // Ordem 6 do CM-000009, decisão 1 do Mestre: os monstros também têm cartão de desgraça (proposta → o Mestre
      // decide), como as heroínas. Ordem 9 (decisão do Mestre 09/11 11:29, «Opção C — Sim, cartão também na
      // oportunidade»; extensão M2 no site): o ataque de oportunidade também — já não há 'sorte' em lado nenhum.
      modoDesgraca: 'proposta',
      niveisVantagem: extra.niveisVantagem ?? 0,
      niveisDesvantagem: atacante.corpoPartido ? 1 : 0,
      ataqueDeOportunidade: !!extra.ataqueDeOportunidade,
      flanqueando: atacante.lado !== 'jogadora' && alvo.lado === 'jogadora' ? flanqueia(m, atacante, alvo) : false,
      atacanteCaido: !!atacante.caido,
      atacanteFraco: ehFraca(atacante),
      aliadosAoAlcance: aliadosAoAlcance(m, atacante, alvo), // Q12; sem eles o VLAB exclui o «acerta-amigo»
    };
    // VLAB real: um monstro com a arma caída recupera-a de graça ao atacar (sem isto: ARMA_CAIDA).
    if (atacante.lado !== 'jogadora' && atacante.armaCaida) ctx.armaRecuperada = true;
    // Errata JV1.1-a §4: NUNCA enviar modificador de crítico (defeito latente MASTER_DECISIONS).
    // VLAB real: verificacaoCritico = três inteiros 1..6 ("6,6 e o 3.º ≥ 5 − margem" = crítico; "1,1 e o 3.º em 1 ou 2"
    // = falha crítica; não corre para magia). `margemCritico` (0..4) baixa o limiar do 3.º dado.
    // TODO(R0): de onde vem a margemCritico (técnica? ficha?). Hoje não se envia (= 0).
    // A reação Defender vai no ALVO (entidadeMotor), e não aqui. `extra.semReacaoDefensiva` fica só como registo.
    return ctx;
  }

  /**
   * VLAB real: resolverAtaque({atacante, alvo, tecnica, contexto}) → topo {resultado ('acerta'|'erra'|'critico'|
   * 'falhaCritica'), rolagem, defesaUsada, pa {custo, paLivreAntes, paLivreDepois, exaustao}, danoAplicado (DMG cru),
   * rdAplicada, totalEfectivo (dano efetivo), reacaoConsumida, contraAtaquePendente, desgracaPendente, publico {recibo},
   * soDoMestre {alvoDepois, efeitosAtacante[], colapso?, falhaCritica?, atacanteDepois?}, erro {codigo, detalhe}|null}.
   */
  function chamarMotorAtaque(atacante, alvo, t, ctx) {
    let saida;
    try {
      saida = motores.Vlab.resolverAtaque({
        atacante: entidadeMotor(atacante),
        alvo: entidadeMotor(alvo, { comoAlvo: true, alvoDeAoO: ctx.ataqueDeOportunidade === true }),
        tecnica: t,
        contexto: clonarJson(ctx),
      });
    } catch (e) {
      return { erro: 'EXCECAO:' + (e?.message ?? String(e)) };
    }
    if (!saida || typeof saida !== 'object') return { erro: 'SAIDA_INVALIDA' };
    if (saida.erro) return { erro: typeof saida.erro === 'string' ? saida.erro : String(saida.erro.codigo ?? 'ERRO') };
    if (!Object.prototype.hasOwnProperty.call(RESULTADOS, saida.resultado)) return { erro: 'RESULTADO_DESCONHECIDO' };
    // VLAB real: a falha crítica vem em soDoMestre.falhaCritica = {modo, rolagemDesgraca, tabelaEfectiva, excluidas,
    // desgraca:{id, nome, gravidade}, aplicado, requerConfirmacao? (só no modo 'proposta'), propostaOriginal?}. O falso, no topo.
    if (saida.falhaCritica === undefined && saida.soDoMestre && typeof saida.soDoMestre === 'object' && saida.soDoMestre.falhaCritica) {
      saida.falhaCritica = saida.soDoMestre.falhaCritica;
    }
    return saida;
  }

  /**
   * Cura pelo motor (site REF_31, vlab-completo.js aplicarCura). VLAB real:
   *   aplicarCura({origem:{nome}, quemCura:{paLivre}, alvo:{vidaTotal, vidaActual, estadoMorte, estado}, expressaoCura,
   *   custoPA, magia, contexto:{semente|faces}}) → {curaRolada:null, publico:{recibo}, soDoMestre:{curaRolada,
   *   curaEfectiva, excesso, pa:{custo, paLivreAntes, paLivreDepois, exaustaoEspiritual}, alvoDepois:{vidaActual,
   *   estadosRemovidos, estadoMorte?}}, erro}. Nunca vai `forcarSemPA` (a opção só aparece com PA livre suficiente).
   * Pontos onde o site é omisso NÃO entram aqui (ver README do servidor, «Ordem 7»): `curaBloqueada` da ferida-fonte.
   */
  function chamarMotorCura(quem, alvo, t, ctx) {
    const fn = motores.Vlab.aplicarCura;
    if (typeof fn !== 'function') return { erro: 'SEM_CURA_NO_MOTOR' };
    let saida;
    try {
      saida = fn({
        origem: { nome: t.nome || t.id, id: t.id },
        quemCura: { paLivre: quem.lado === 'jogadora' ? paLivre(quem) : fichaEfetiva(quem).paTotal },
        alvo: entidadeMotor(alvo),
        expressaoCura: t.expressaoCura,
        custoPA: Number.isInteger(t.custoPA) ? t.custoPA : 0,
        magia: t.magia === true,
        contexto: clonarJson(ctx),
      });
    } catch (e) {
      return { erro: 'EXCECAO:' + (e?.message ?? String(e)) };
    }
    if (!saida || typeof saida !== 'object') return { erro: 'SAIDA_INVALIDA' };
    if (saida.erro) return { erro: typeof saida.erro === 'string' ? saida.erro : String(saida.erro.codigo ?? 'ERRO') };
    return saida;
  }

  /** Copia do motor só os campos de estado conhecidos (o estado vivo atualiza-se no servidor). */
  function aplicarDepois(f, d) {
    if (!d || typeof d !== 'object') return;
    if (typeof d.vidaActual === 'number' && Number.isFinite(d.vidaActual)) f.vidaActual = d.vidaActual;
    if (d.estadoMorte !== undefined) f.estadoMorte = d.estadoMorte === null ? null : clonarJson(d.estadoMorte);
    if (Array.isArray(d.estado)) f.caido = d.estado.includes('caido');
    // VLAB real: soDoMestre.alvoDepois = {estadosNovos, estadosRemovidos, vidaActual}.
    if (Array.isArray(d.estadosNovos) && d.estadosNovos.includes('caido')) f.caido = true;
    if (Array.isArray(d.estadosRemovidos) && d.estadosRemovidos.includes('caido')) f.caido = false;
    if (typeof d.caido === 'boolean') f.caido = d.caido;
    // VLAB real (desgraças): atacanteDepois = {armaCaida:true, custoRecuperacao} | {armaQuebrada:true, duracao} |
    // {estadosNovos:['caido']} | {vidaActual, estadosNovos} (acerta-se). O quebra-corpo NÃO vem aqui (vem em
    // falhaCritica.efeitoMecanico); aplica-se por aplicarEfeitoDesgraca.
    for (const k of ['armaCaida', 'armaQuebrada', 'corpoPartido']) if (typeof d[k] === 'boolean') f[k] = d[k];
    // Q4 (site REF_31, vlabAplicarCuraDepois): sobre a estabilizada, a cura soma por cima do 1; curou e ficou acima
    // de 0 → a marca sai e ela levanta-se. O recibo de cura entra aqui com `curou: true` (acção `curar`, ordem 7).
    // Levantar-se pela cura NÃO gasta o movimento da vez seguinte: no site a queda a 0 é só da vista
    // (entrarAMorrer → setVivo false) e a cura repõe a vista (setVivo true); o 'caido' que gasta a reserva é só o da
    // desgraça (iniciarVez).
    if (d.curou === true && estabilizadaSemCura(f) && f.vidaActual > 0) {
      f.estadoMorte = null;
      f.caido = false;
    }
    if (f.lado !== 'jogadora') {
      // VLAB real: Vida a 0 → estadosNovos 'foraDeCombate' e morteAdjudicada:false; o monstro sai da ordem (REF_7 §1).
      if (f.vidaActual <= 0 || d.vivo === false || d.morteAdjudicada === true) f.vivo = false;
    } else if (d.vivo === false || d.morteAdjudicada === true || f.estadoMorte?.fase === 'morreu' || f.estadoMorte?.fase === 'morta') {
      // VLAB real: as fases são só 'aMorrer' e 'estabilizado'; a morte vem em `morteAdjudicada: true`
      // (morteVia 'testesDeMorte'), no ataque (soDoMestre.alvoDepois) e no teste de morte (topo). 'morreu'/'morta'
      // ficam por segurança (o `desfecho` do teste de morte chama-se 'morreu').
      f.vivo = false;
    }
  }

  /** Desgraça APLICADA pelo motor (modo 'sorte' ou 'escolha'), ou null. */
  function desgracaAplicada(saida) {
    const fc = saida.falhaCritica;
    // VLAB real: no modo 'proposta' vem `aplicado: false` e `requerConfirmacao: true` (nada se aplica).
    if (!fc || typeof fc !== 'object' || fc.requerConfirmacao || fc.aplicado === false) return null;
    // VLAB real: `desgraca` é {id, nome, gravidade}; antes a sala lia `.tipo` e nunca aplicava a desgraça real.
    const tipo = idDesgraca(fc.desgraca ?? fc.desgracaAplicada);
    return tipo && tipo !== 'nenhuma' ? tipo : null;
  }
  /**
   * REF_19 (T-QUEBRAR25; palavra do Mestre, 07/11/2026 09:02): quem quebra uma parte do corpo perde NA HORA 25% da
   * Vida ACTUAL — floor(vida/4), tecto vida−1, nunca negativa (com Vida 1–3 a perda é 0). A regra sozinha nunca mata.
   * Vale para monstro ou heroína. Só se chama com a desgraça já APLICADA (modo 'sorte'/'escolha'): a proposta H10
   * (requerConfirmacao) não cobra, porque cobraria antes da autorização do Mestre.
   */
  function perdaQuebrarCorpo(f) {
    const v = typeof f.vidaActual === 'number' && Number.isFinite(f.vidaActual) ? f.vidaActual : 0;
    return Math.max(0, Math.min(Math.floor(v / 4), v - 1));
  }
  /** Aplica o efeito da desgraça na figura; devolve a Vida perdida pela própria desgraça (0 se não houver). */
  function aplicarEfeitoDesgraca(f, tipo) {
    switch (tipo) {
      case 'cai': f.caido = true; break;
      case 'arma-cai': f.armaCaida = true; break;
      case 'arma-quebra': f.armaQuebrada = true; break;
      case 'quebra-corpo': { // desvantagem 1 e metade do deslocamento até ao fim + REF_19 (um quarto da Vida actual)
        f.corpoPartido = true;
        const perda = perdaQuebrarCorpo(f);
        f.vidaActual -= perda;
        return perda;
      }
      // VLAB real: `acerta-se` traz o dano em soDoMestre.atacanteDepois.vidaActual (já aplicado por aplicarDepois);
      // sem vida do atacante vem em `desgracaPendente` (acertaSiProprio). `acerta-amigo` vem SEMPRE em
      // `desgracaPendente` (acertaAmigo): resolve-se em resolverDesgracaPendente (Q12).
      default: break;
    }
    return 0;
  }
  /**
   * RD de quem recebe o dano da desgraça — a mesma regra do VLAB (rdDe): sem RD → 0; RD geral OU específica do único
   * tipo; dois tipos ou as duas RD ao mesmo tempo → o VLAB recusa (RD_SEM_DISTRIBUICAO_POR_TIPO /
   * RD_EMPILHAMENTO_SEM_DECISAO): aqui não se aplica e fica para o Mestre, sem inventar.
   */
  function rdDaDesgraca(f, tipos) {
    const rd = fichaEfetiva(f).rd;
    const temRd = rd && ((rd.geral | 0) > 0 || (rd.porTipo && Object.values(rd.porTipo).some((x) => x > 0)));
    if (!temRd) return { rd: 0 };
    const unicos = [...new Set(tipos)];
    if (unicos.length !== 1) return { erro: 'RD_SEM_DISTRIBUICAO_POR_TIPO' };
    const geral = rd.geral | 0, especifica = (rd.porTipo && rd.porTipo[unicos[0]]) | 0;
    if (geral > 0 && especifica > 0) return { erro: 'RD_EMPILHAMENTO_SEM_DECISAO' };
    return { rd: geral > 0 ? geral : especifica };
  }
  /**
   * Q12 (julgamento da casa de 2026-11-03; instrução do VLAB no próprio pendente): o dano da desgraça já vem como metade
   * com piso (`danoAntesDaRD`), nunca crítico. Quem chama aplica: − RD de quem recebe → Vida, com o TECTO de nunca
   * baixar de 1 de Vida (logo nunca abre testes de morte), e sem reacção defensiva. Devolve o registo (só Mestre).
   */
  function resolverDesgracaPendente(m, atacante, pend) {
    const reg = { tipo: pend.tipo ?? null, aplicada: false };
    const quem = pend.tipo === 'acertaAmigo' ? m.figuras[pend.aliadoId] ?? null : pend.tipo === 'acertaSiProprio' ? atacante : null;
    const metade = Number(pend.danoAntesDaRD);
    if (!quem || !Number.isFinite(metade)) {
      reg.motivo = !quem ? 'figura desconhecida' : 'sem danoAntesDaRD';
      return { reg, quem: null };
    }
    reg.figuraId = quem.id;
    const r = rdDaDesgraca(quem, Array.isArray(pend.tipos) ? pend.tipos : []);
    if (r.erro) {
      reg.motivo = r.erro; // fica para o Mestre (TODO(R0): a RD com dois tipos ou empilhada não tem decisão)
      return { reg, quem: null };
    }
    const vida = Number.isFinite(quem.vidaActual) ? quem.vidaActual : 0;
    const preTecto = Math.max(0, Math.floor(metade) - r.rd);
    const efectivo = Math.min(preTecto, Math.max(0, vida - 1));
    quem.vidaActual = vida - efectivo;
    Object.assign(reg, { aplicada: true, danoAntesDaRD: Math.floor(metade), rdAplicada: r.rd, danoSofrido: efectivo,
      tetoAplicado: efectivo < preTecto, vidaAntes: vida, vidaDepois: quem.vidaActual });
    return { reg, quem, efectivo };
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
    const bandeiras = (f) => `${f.armaCaida}|${f.armaQuebrada}|${f.corpoPartido}`;
    const bandAtac = bandeiras(atacante);
    const sm = saida.soDoMestre && typeof saida.soDoMestre === 'object' ? saida.soDoMestre : {};
    // O `totalEfectivo` do VLAB real é o DANO efetivo (após RD), e não o total do ataque.
    // VLAB real: o total do ataque é `rolagem.total` (= `rolagem.escolhido`); as faces vêm em `rolagem.conjuntosDeFaces`.
    const { total, faces } = rolagemVisivel(saida);
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
      // Acrescentados (só Mestre): pendências que o motor devolve e a sala ainda não resolve.
      totalEfectivo: numeroOuNull(saida.totalEfectivo), reacaoConsumida: saida.reacaoConsumida ?? null,
      desgracaPendente: saida.desgracaPendente ?? null, contraAtaquePendente: saida.contraAtaquePendente ?? null,
    });
    // TODO(R0): `contraAtaquePendente` ({expressaoAtaque, contextoSugerido, defesaDoAlvo, instrucao}, só quando erra e o
    // alvo tem contraAtaque) não se resolve: fica registado para o Mestre.
    aplicarDepois(alvo, sm.alvoDepois);
    aplicarDepois(atacante, sm.atacanteDepois);
    if (saida.reacaoConsumida === true && alvo.defendendo) {
      // VLAB real: `reacaoConsumida` = a reação-limiar do alvo foi usada. Uma reação por ronda (REF_7 §2):
      // a declaração de Defender gasta-se no primeiro ataque que a usa.
      // TODO(R0 A-4): a `defesaAplicavel` de um monstro também consome a reação dele (fica sem AoO nesta ronda)?
      alvo.defendendo = false;
    }
    const des = desgracaAplicada(saida);
    if (des) {
      // Uma vez por desgraça: aplicarSaida é o único ponto onde a desgraça aplicada entra (vez, oportunidade, pós-cartão).
      const perdaVida = aplicarEfeitoDesgraca(atacante, des);
      const dadosDesgraca = { figuraId: atacante.id, efeito: DESGRACAS.includes(des) ? des : null };
      // Q12: o dano pendente do «acerta-amigo» (sempre) e do «acerta-se» (quando o motor não tinha a Vida).
      const pend = saida.desgracaPendente && typeof saida.desgracaPendente === 'object' ? saida.desgracaPendente : null;
      let pendente = null;
      if (pend) {
        const atingido = pend.tipo === 'acertaAmigo' ? tx.estado.figuras[pend.aliadoId] : atacante;
        const visP = atingido ? visivelDe(atingido) : null;
        const vidaP = atingido ? atingido.vidaActual : null;
        pendente = { ...resolverDesgracaPendente(tx.estado, atacante, pend), visP, vidaP };
      }
      // REF_19: a frase «…e perde um quarto da vida que tem agora» só quando a perda acontece. Vai só à própria
      // (campo `propria`); o número fica no soMestre e a Vida nova segue pelo evento `estado`.
      if (perdaVida > 0) dadosDesgraca.perdeQuarto = true;
      tx.emitir('desgraca', dadosDesgraca, { bruto: saida.falhaCritica, perdaVida, ...(pendente ? { pendente: pendente.reg } : {}) });
      if (pendente?.quem) {
        if (pendente.efectivo > 0) {
          tx.emitir('dano', { alvoId: pendente.quem.id, autorId: atacante.id, valor: pendente.efectivo, tipos: saida.desgracaPendente.tipos ?? [] }, null);
        }
        // O alvo e o atacante saem já no fim de aplicarSaida; o amigo atingido sai aqui.
        if (pendente.quem.id !== alvo.id && pendente.quem.id !== atacante.id) emitirEstado(tx, pendente.quem, false, pendente.visP, pendente.vidaP);
      }
    }
    const dano = danoTotalDe(saida);
    if (dano > 0) tx.emitir('dano', { alvoId: alvo.id, autorId: atacante.id, valor: dano, tipos: tiposDe(t) }, null);
    emitirEstado(tx, alvo, false, visAlvo, vidaAlvo);
    // A própria sabe logo da arma caída/quebrada e do corpo partido (o `estado` só saía com a Vida a mudar).
    if (atacante.id !== alvo.id) emitirEstado(tx, atacante, atacante.lado === 'jogadora' && bandeiras(atacante) !== bandAtac, visAtac, vidaAtac);
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
    if (saida.falhaCritica && saida.falhaCritica.requerConfirmacao) {
      // §8.3 / H10: a jogadora nunca autoriza a própria desgraça. A rolagem já está gravada no cartão.
      // Decisão 1 do Mestre (ordem 6): o monstro também — o cartão vai ao Mestre, com a mesma lista e a mesma rolagem.
      abrirCartao(tx, {
        tipo: 'desgraca', figuraId: f.id, alvoId: alvo.id, tecnicaId: t.id, contexto: ctx,
        proposta: saida.falhaCritica.desgracaProposta ?? saida.falhaCritica.proposta ?? saida.falhaCritica.propostaOriginal ?? saida.falhaCritica.desgraca ?? null,
        excluidas: Array.isArray(saida.falhaCritica.excluidas) ? clonarJson(saida.falhaCritica.excluidas) : [],
        razao: null, origem: origemCartao(origem),
        // Ordem 8 (item 5): a saída da proposta guarda-se no cartão (só Mestre) para o «Não acontece nada», que a
        // aplica tal como está (sem desgraça aplicada) e NÃO faz a segunda chamada ao motor (REF_34).
        saidaProposta: clonarJson(saida),
      });
      return 'AGUARDANDO_MESTRE';
    }
    finalizarAtaque(tx, f, alvo, t, ctx, saida);
    return 'APLICADA';
  }

  /**
   * A técnica do ataque de oportunidade: a que chega à casa vizinha. Ordem 11 (Emenda 1 da REF_36): com o piso de 1 casa
   * TODAS chegam à vizinha, em qualquer escala (antes exigia-se alcanceM <= casaM, e com casa de 1 m uma técnica de
   * 1,5 m deixava de chegar). Entre as que servem, usa-se a de MENOR alcance (a mais «corpo-a-corpo»; empate: a ordem
   * da ficha), para não trocar a arma curta do monstro por uma de longe.
   */
  function tecnicaCorpoACorpo(m, f) {
    const ts = fichaEfetiva(f).tecnicas.filter((t) => !(t.usaArma && f.armaQuebrada) && alcanceEmCasas(m, t.alcanceM) >= 1);
    return ts.reduce((melhor, t) => (melhor === null || t.alcanceM < melhor.alcanceM - EPS ? t : melhor), null);
  }

  /**
   * Ataque de oportunidade de um monstro (na chegada, com vantagem 1, sem a reação defensiva dela).
   * Ordem 9 do CM-000009 (decisão do Mestre 09/11 11:29, «Opção C»): a falha crítica do AoO do MONSTRO passa pelo
   * cartão do Mestre como as outras. O movimento dela já terminou (aplicarMover move e debita ANTES da série); a série
   * pára aqui e o cartão guarda os monstros que faltam (`aooRestantes`), que atacam depois da decisão. A IA não
   * decide: o cartão abre sempre, em auto, semi ou manual. Devolve true quando abriu o cartão (a série pára).
   */
  function ataqueDeOportunidade(tx, mon, alvo, restantes = []) {
    const t = tecnicaCorpoACorpo(tx.estado, mon);
    if (!t) return false;
    mon.reacaoDisponivel = false;
    const ctx = montarContexto(tx.estado, mon, alvo, { ataqueDeOportunidade: true, niveisVantagem: 1, semReacaoDefensiva: true });
    const saida = chamarMotorAtaque(mon, alvo, t, ctx);
    if (saida.erro) {
      tx.emitir('erro_motor', { figuraId: mon.id }, { erro: String(saida.erro), contexto: ctx });
      return false;
    }
    if (saida.falhaCritica && saida.falhaCritica.requerConfirmacao) {
      abrirCartao(tx, {
        tipo: 'desgraca', figuraId: mon.id, alvoId: alvo.id, tecnicaId: t.id, contexto: ctx,
        proposta: saida.falhaCritica.desgracaProposta ?? saida.falhaCritica.proposta ?? saida.falhaCritica.propostaOriginal ?? saida.falhaCritica.desgraca ?? null,
        excluidas: Array.isArray(saida.falhaCritica.excluidas) ? clonarJson(saida.falhaCritica.excluidas) : [],
        // Sem recibo de origem: o recibo do movimento dela já ficou APLICADA (ela chegou ao destino).
        razao: null, origem: null,
        saidaProposta: clonarJson(saida), // para o «Não acontece nada» (sem segunda chamada ao motor)
        ataqueDeOportunidade: true,
        aooRestantes: restantes.slice(),
      });
      return true;
    }
    if (mon.armaCaida) mon.armaCaida = false;
    aplicarSaida(tx, mon, alvo, t, ctx, saida, { ataqueDeOportunidade: true });
    return false;
  }

  /** Corre (ou retoma, depois do cartão) a série de ataques de oportunidade contra `f`, pela ordem dada. */
  function serieDeOportunidade(tx, f, ids) {
    const m = tx.estado;
    for (let i = 0; i < ids.length; i++) {
      if (m.fase !== 'combate' || !f.vivo || f.estadoMorte?.fase === 'aMorrer') break; // morrer interrompe a série
      const mon = m.figuras[ids[i]];
      if (!mon || !mon.vivo || mon.caido || !mon.reacaoDisponivel) continue;
      const parou = ataqueDeOportunidade(tx, mon, f, ids.slice(i + 1));
      if (parou) return; // o cartão está aberto: o resto vem depois da decisão do Mestre
      verificarFim(tx);
    }
  }

  /** Fecho de um cartão de desgraça de ataque de oportunidade: aplica, e a série continua com os que faltam. */
  function finalizarOportunidade(tx, mon, alvo, t, ctx, saida, c) {
    if (mon.armaCaida) mon.armaCaida = false; // como no AoO sem cartão: recupera antes; a desgraça escolhida aplica-se depois
    aplicarSaida(tx, mon, alvo, t, ctx, saida, { ataqueDeOportunidade: true });
    verificarFim(tx);
    serieDeOportunidade(tx, alvo, Array.isArray(c.aooRestantes) ? c.aooRestantes : []);
  }

  function aplicarMover(tx, f, destino) {
    const m = tx.estado;
    const v = m.vez;
    const r = bfs(m, f, Math.floor(v.reservaM / casaDe(m) + EPS), f.id);
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
    const custoM = arred(d * casaDe(m)); // débito no fim do movimento: casas × a escala viva (1,5 ao nascer)
    v.reservaM = arred(Math.max(0, v.reservaM - custoM));
    v.andouM = arred(v.andouM + custoM);
    if (!ehJog) v.iaMoveu = true;
    tx.emitir('movimento', { figuraId: f.id, de, para: { x: f.x, y: f.y }, caminho, custoM, reservaM: v.reservaM }, null);
    aposMovimentoAmbiente(tx, f); // ordem 13: sair do fogo para a chuva apaga-a (no fim do movimento, como o site)

    // Resolvem-se só na CHEGADA, depois do débito, pela ordem de iniciativa. Ordem 9: uma falha crítica abre o
    // cartão do Mestre e a série pára aí (o movimento já terminou); o recibo do movimento fica APLICADA.
    const atacantes = [...grupoA, ...grupoB].sort((a, b) => m.ordem.indexOf(a.id) - m.ordem.indexOf(b.id));
    serieDeOportunidade(tx, f, atacantes.map((x) => x.id));
  }

  /**
   * Acção `curar` (ordem 7 do CM-000009). Regras do site REF_31:
   *  - o motor rola a cura e devolve a Vida depois (teto = Vida máxima; o total fica só em soDoMestre);
   *  - sobre a estabilizada (Q4, 1 de Vida, caída) a cura soma por cima do 1; a marca sai, ela levanta-se e a
   *    rotação volta a dar-lhe a vez (avancarVez já não a salta sem a marca) — vlabAplicarCuraDepois;
   *  - quem cura e não é a própria não vê expressão nem faces (vlabFiltrarReciboCura): fica a origem.
   * PROVISÓRIO (site omisso, ver README «Ordem 7»): a cura gasta a acção padrão (`atacou`), como as outras técnicas.
   */
  function aplicarCuraAcao(tx, f, alvo, t) {
    const m = tx.estado;
    const ctx = { semente: sortearSemente() >>> 0 };
    const saida = chamarMotorCura(f, alvo, t, ctx);
    if (saida.erro) throw new ErroRecusa('acao_invalida', 'MOTOR:' + saida.erro);
    const sm = saida.soDoMestre && typeof saida.soDoMestre === 'object' ? saida.soDoMestre : {};
    const visAlvo = visivelDe(alvo);
    const vidaAlvo = alvo.vidaActual;
    const paAntes = f.lado === 'jogadora' ? paLivre(f) : null;
    if (m.vez && m.vez.figuraId === f.id) m.vez.atacou = true;
    if (f.lado === 'jogadora') f.paGasto += Number.isInteger(sm.pa?.custo) ? sm.pa.custo : (Number.isInteger(t.custoPA) ? t.custoPA : 0);
    aplicarDepois(alvo, { ...(sm.alvoDepois && typeof sm.alvoDepois === 'object' ? sm.alvoDepois : {}), curou: true });
    const faces = facesDoRecibo(saida.publico?.recibo);
    const dados = { curadorId: f.id, alvoId: alvo.id, tecnica: t.id };
    // Como no ataque (v0.2.1): só quem cura, se for jogadora, vê a expressão e as faces dela. O total é do Mestre.
    if (f.lado === 'jogadora') Object.assign(dados, { faces, expressao: t.expressaoCura });
    tx.emitir('cura', dados, { semente: ctx.semente, contexto: ctx, recibo: saida.publico?.recibo ?? null, soDoMestre: sm });
    emitirEstado(tx, alvo, alvo.id === f.id, visAlvo, vidaAlvo);
    if (alvo.id !== f.id && f.lado === 'jogadora' && paLivre(f) !== paAntes) emitirEstado(tx, f, true);
    verificarFim(tx);
  }

  /** Faces do recibo público do VLAB real («cura 1d8+2 → [5] (origem: …)»), ou null. */
  function facesDoRecibo(recibo) {
    const r = typeof recibo === 'string' ? /→ \[([0-9,]*)\]/.exec(recibo) : null;
    if (!r) return null;
    const fs = r[1].split(',').filter(Boolean).map(Number);
    return fs.length && fs.every((x) => Number.isInteger(x) && x >= 1 && x <= 100) ? fs : null;
  }

  function origemCartao(origem) {
    return origem ? { seatId: origem.seatId, id: origem.id, idCampo: origem.idCampo, chave: origem.chave } : null;
  }

  /**
   * Ordem 17 (B2; omisso 15-6, o lado do Mestre): o porquê de um atacar/curar recusado por ALCANCE, para o evento interno
   * `recusa` (só o Mestre, como o ESCALA_INVALIDA). É diagnóstico, não regra: a régua é a mesma das opções (aoAlcance).
   * A Party continua a ver a recusa fixa de sempre; mostrar o porquê na HUD dela precisa da palavra do Mestre.
   * Devolve null quando o alcance não é o problema (ou não se sabe a técnica ou o alvo).
   */
  function detalheDeAlcance(m, f, acao) {
    if (!f || (acao?.tipo !== 'atacar' && acao?.tipo !== 'curar')) return null;
    const alvo = m.figuras[acao.alvoId];
    const t = fichaEfetiva(f).tecnicas.find((x) => x.id === (acao.tipo === 'atacar' ? acao.arma : acao.tecnica));
    if (!alvo || !alvo.colocada || alvo.id === f.id || !t || !f.colocada) return null;
    if (acao.tipo === 'curar' && typeof t.expressaoCura !== 'string') return null;
    if (aoAlcance(m, f, alvo, t.alcanceM)) return null;
    const passos = distanciaCasas(m, f, alvo);
    const alcance = arred(alcanceEmCasas(m, t.alcanceM));
    if (!Number.isFinite(passos)) return `CAMINHO_TAPADO: não há caminho pelas casas livres até ao alvo; a técnica chega a ${alcance} casas`;
    return `ALVO_FORA_DO_ALCANCE: ${passos} passos pelo caminho das casas; a técnica chega a ${alcance} casas`;
  }

  /** Valida a ação contra as opções correntes e aplica-a. Devolve o estado do recibo. */
  function aplicarIntencao(tx, figuraId, acao, origem) {
    const m = tx.estado;
    const f = m.figuras[figuraId];
    const v = m.vez;
    const ops = calcularOpcoes(m, figuraId);
    if (!f || !acaoNasOpcoes(ops, acao)) throw new ErroRecusa('acao_invalida', detalheDeAlcance(m, f, acao));
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
      case 'apanhar_arma': {
        // Q8 (julgamento da casa de 2026-11-03; Musa 08/11/2026) e o site (jogo.js: «recuperar = 1 Acção de
        // Movimento»): apanhar a arma caída gasta a Acção de Movimento — a reserva toda. Faltava este ramo: a opção
        // aparecia, mas a intenção era recusada (acao_invalida) e a arma caída da jogadora nunca voltava.
        const vis = visivelDe(f);
        const vida = f.vidaActual;
        f.armaCaida = false;
        v.reservaM = 0;
        tx.emitir('acao', { figuraId: f.id, tipo: 'apanhar_arma' }, null);
        emitirEstado(tx, f, true, vis, vida); // a própria sabe já que tem a arma na mão
        return 'APLICADA';
      }
      case 'apagar_fogo': {
        // Ordem 15 (palavra do Mestre, 2026-11-10; site jogo.js acao 'apagar-fogo'): sem chuva, quem arde fora do fogo
        // pára e apaga o fogo do corpo — gasta a Acção de Movimento (a reserva zera); o ataque continua livre.
        if (f.lado !== 'jogadora' || !Amb.podeApagarSeco(m, f)) throw new ErroRecusa('acao_invalida');
        const pubAntes = jsonCanonico(Amb.fogoPublico(m));
        const r = Amb.apagarSeco(m, f);
        v.reservaM = 0;
        tx.emitir('acao', { figuraId: f.id, tipo: 'apagar_fogo' }, null);
        emitirAmbiente(tx, [r], pubAntes);
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
      case 'curar': {
        const alvo = m.figuras[acao.alvoId];
        const t = fichaEfetiva(f).tecnicas.find((x) => x.id === acao.tecnica);
        aplicarCuraAcao(tx, f, alvo, t);
        return 'APLICADA';
      }
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
    // REQUISITO (ordem 6 do CM-000009, decisão 6 do Mestre) — entrada de desenho da IA das criaturas, NÃO regra fixa:
    // se a heroína caída é alvo depende do OBJECTIVO da criatura (sobrevivência ignora-a; caos ou fome ataca-a).
    // Hoje a IA não distingue (ataca a mais perto, caída ou não). Fica para o desenho da IA das criaturas.
    if (ops.ataques.length) {
      // Alvo: a jogadora (REF_7: "sempre a Ong"); com várias, a mais perto.
      const a = ops.ataques
        .slice()
        .sort((p, q) => distanciaM(m, f, m.figuras[p.alvoId]) - distanciaM(m, f, m.figuras[q.alvoId]))[0];
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
        // L6: com o «Continuar a rodada» dado nesta rodada, a marcha pura segue sem cartão (como no auto).
        if (m.marchaLivre === m.rodada && MARCHA_PURA.has(proporIA(m, f).acao?.tipo)) {
          saidas.push(...passoIAAuto(f.id));
          continue;
        }
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
  function dentroDoRitmo(seatId, balde = ritmo) {
    const t = agora();
    const lista = (balde.get(seatId) ?? []).filter((x) => t - x < 1000);
    if (lista.length >= 10) {
      balde.set(seatId, lista);
      return false;
    }
    lista.push(t);
    balde.set(seatId, lista);
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
          && (msg.rodada === undefined || typeof msg.rodada === 'boolean')
          && (msg.edicao === undefined || msg.edicao === null || (typeof msg.edicao === 'object' && !Array.isArray(msg.edicao)));
      case 'MASTER_CONFIRM_DICE':
        return typeof msg.intentId === 'string' && RE_ID.test(msg.intentId) && typeof msg.aceitar === 'boolean';
      case 'MASTER_AMBIENTE':
        // Ordem 13: `raios` (interruptor) e `raioAgora` (pedido de um raio para o próximo momento de ambiente).
        return sn(msg.hora, 16) && sn(msg.clima, 64) && sn(msg.futuro, 500)
          && (msg.raios === undefined || typeof msg.raios === 'boolean')
          && (msg.raioAgora === undefined || msg.raioAgora === true);
      case 'MASTER_SUPERVISOR':
        if (msg.op === 'terminar' || msg.op === 'recomecar') return msg.ateSeq === undefined && msg.casaM === undefined; // N4 (palavra do Mestre, 08/11)
        // Ordem 8 (item 8): a escala nova, em metros por casa. Aqui só a forma (número > 0); os valores que valem
        // (1 / 1,5 / 2, ordem 11) confere-os mudarEscala, para a recusa levar o detalhe ESCALA_INVALIDA ao Mestre.
        if (msg.op === 'escala') return msg.ateSeq === undefined && typeof msg.casaM === 'number' && Number.isFinite(msg.casaM) && msg.casaM > 0;
        if (msg.casaM !== undefined) return false;
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
      || (tipo === 'MASTER_SUPERVISOR' && ['voltar', 'terminar', 'recomecar'].includes(msg.op))
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
          f.casaColocacao = { x: casa.x, y: casa.y, orientacao: f.orientacao }; // para o «Recomeçar» (N4)
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
        f.casaColocacao = { x: f.x, y: f.y, orientacao: f.orientacao }; // para o «Recomeçar» (N4)
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
      case 'MASTER_AMBIENTE':
        return mudarAmbiente(tx, msg);
      case 'MASTER_SUPERVISOR':
        if (msg.op === 'terminar') return terminarBatalha(tx);
        if (msg.op === 'recomecar') return recomecarBatalha(tx);
        if (msg.op === 'escala') return mudarEscala(tx, msg.casaM);
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

  /**
   * MASTER_AMBIENTE (o painel Ambiente, só do Mestre). Ordem 13 (dívida E1): além da hora, do clima e do futuro,
   *  - `raios` liga/desliga os raios (só caem com chuva: clima 'chuva' = pouca, 'tempestade' = forte);
   *  - `raioAgora` pede UM raio, que cai ao acaso no momento de ambiente do início da rodada seguinte (como o
   *    «⚡ Raio agora» do site): só em combate, com tempestade, um pendente de cada vez e um pedido por rodada.
   *    A recusa leva o texto fixo (E-P7) e o detalhe só ao Mestre.
   * Desligar a chuva ou os raios com um pedido pendente cancela-o. A Party só recebe evento se o EFEITO presente
   * (clima, dia/noite) mudou: os raios e o pedido nunca lhe chegam (o raio que cai, sim — evento `raio`).
   */
  function mudarAmbiente(tx, msg) {
    const m = tx.estado;
    const antes = efeitoAmbiente(m.ambiente);
    const a = m.ambiente ?? {};
    m.ambiente = {
      hora: msg.hora !== undefined ? msg.hora : a.hora ?? null,
      clima: msg.clima !== undefined ? msg.clima : a.clima ?? null,
      futuro: msg.futuro !== undefined ? msg.futuro : a.futuro ?? null,
      raios: msg.raios !== undefined ? msg.raios : a.raios === true,
      raioPendente: a.raioPendente === true,
      raioPedidoRodada: Number.isInteger(a.raioPedidoRodada) ? a.raioPedidoRodada : 0,
    };
    let cancelado = false;
    if (msg.raioAgora === true) {
      if (m.fase !== 'combate') throw new ErroRecusa('acao_invalida', 'RAIO_FORA_DO_COMBATE');
      if (!Amb.haTempestade(m.ambiente)) {
        throw new ErroRecusa('acao_invalida', 'RAIO_SEM_TEMPESTADE: o raio pede chuva (clima chuva ou tempestade) e os raios ligados');
      }
      if (m.ambiente.raioPendente) throw new ErroRecusa('acao_invalida', 'RAIO_JA_PENDENTE: já há um raio à espera da rodada seguinte');
      if (m.ambiente.raioPedidoRodada === m.rodada) throw new ErroRecusa('acao_invalida', 'RAIO_UM_POR_RODADA: já se pediu um raio nesta rodada');
      m.ambiente.raioPendente = true;
      m.ambiente.raioPedidoRodada = m.rodada;
    } else if (m.ambiente.raioPendente && !Amb.haTempestade(m.ambiente)) {
      m.ambiente.raioPendente = false; // sem chuva ou sem raios, o pedido cancela-se
      cancelado = true;
    }
    const depois = efeitoAmbiente(m.ambiente);
    const so = { ...clonarJson(m.ambiente), ...(cancelado ? { raioCancelado: true } : {}) };
    // A Party só recebe evento se o EFEITO presente mudou (senão o seq dela denunciaria o painel).
    if (jsonCanonico(antes) !== jsonCanonico(depois)) tx.emitir('ambiente', { efeito: depois }, so);
    else tx.emitir('ambiente_mestre', {}, so);
    return 'APLICADA';
  }

  function primeiraCasaLivre(m) {
    for (let y = 0; y < m.mapa.altura; y++) for (let x = 0; x < m.mapa.largura; x++) if (!ocupada(m, x, y)) return { x, y };
    return null;
  }

  /** Q12: os amigos elegíveis do cartão (o contexto gravado na proposta), se o «acerta-amigo» se pode escolher. */
  function amigosDoCartao(c) {
    if (!desgracasDoCartao(c).includes('acerta-amigo')) return [];
    const lista = Array.isArray(c.contexto?.aliadosAoAlcance) ? c.contexto.aliadosAoAlcance : [];
    return lista.filter((a) => a && a.id && (a.posicao === 'adjacente' || a.posicao === 'naLinha')).map((a) => a.id);
  }
  /** L2 + regra-mãe: as desgraças que o Mestre pode escolher neste cartão (sem as que o motor excluiu). */
  function desgracasDoCartao(c) {
    const excluidas = new Set((c.excluidas ?? []).map((e) => (typeof e === 'string' ? e : e?.id)));
    return DESGRACAS_EDITAVEIS.filter((d) => !excluidas.has(d));
  }

  function aprovarCartao(tx, seatId, msg) {
    const m = tx.estado;
    const c = m.cartoes.find((x) => x.cartaoId === msg.cartaoId && x.estado === 'aberto');
    if (!c || c.tipo === 'dados') throw new ErroRecusa('acao_invalida'); // decisão idempotente: a primeira ganha
    const decisao = msg.decisao;
    // Ordem 8 (item 5): o «Não acontece nada» só existe ao RECUSAR uma proposta de desgraça; noutro sítio é recusado.
    if (msg.edicao?.semDesgraca !== undefined && (c.tipo !== 'desgraca' || decisao !== 'recusar' || msg.edicao.semDesgraca !== true)) {
      throw new ErroRecusa('acao_invalida');
    }
    if (c.tipo === 'desgraca') {
      const f = m.figuras[c.figuraId];
      const alvo = m.figuras[c.alvoId];
      const t = fichaEfetiva(f).tecnicas.find((x) => x.id === c.tecnicaId);
      let escolhida;
      if (decisao === 'aprovar') escolhida = typeof c.proposta === 'string' ? c.proposta : c.proposta?.tipo ?? c.proposta?.id ?? null;
      else if (decisao === 'editar') {
        escolhida = msg.edicao?.desgraca;
        if (!desgracasDoCartao(c).includes(escolhida)) throw new ErroRecusa('acao_invalida'); // L2: só da lista do cartão
      } else if (msg.edicao?.semDesgraca === true) {
        // Ordem 8 do CM-000009, item 5 (desempate do Mestre 09/11 08:17; site REF_34, T-DESGRACA-NADA): ao recusar a
        // proposta, «Não acontece nada» — escolha SÓ do Mestre (só o lugar do Mestre chega aqui), fora da tabela 1d100,
        // sem peso: o acaso nunca a dá e a IA nunca a escolhe (nenhum caminho automático manda `semDesgraca`).
        // Nenhum efeito de desgraça: a segunda chamada ao motor NÃO se faz — aplica-se a saída da proposta, que o
        // motor devolveu sem nada aplicado (requerConfirmacao). Os custos da falha crítica pagam-se na mesma.
        const prop = c.saidaProposta;
        if (!prop || typeof prop !== 'object' || !prop.falhaCritica?.requerConfirmacao) throw new ErroRecusa('acao_invalida');
        const saida = clonarJson(prop);
        if (saida.soDoMestre && typeof saida.soDoMestre === 'object') delete saida.soDoMestre.atacanteDepois;
        delete saida.desgracaPendente; // defensivo: a proposta não traz lado do atacante nem dano pendente
        fecharCartao(tx, c, 'recusar');
        if (c.ataqueDeOportunidade) {
          // Ordem 9: no AoO o registo vem antes, porque a série continua logo a seguir com os monstros que faltam.
          tx.emitir('acao', { figuraId: f.id, tipo: 'sem_desgraca' }, { proposta: c.proposta ?? null, escolha: 'nada' });
          finalizarOportunidade(tx, f, alvo, t, c.contexto, saida, c);
        } else {
          finalizarAtaque(tx, f, alvo, t, c.contexto, saida);
          tx.emitir('acao', { figuraId: f.id, tipo: 'sem_desgraca' }, { proposta: c.proposta ?? null, escolha: 'nada' });
        }
        atualizarReciboOrigem(tx, c.origem, 'APLICADA');
        return 'APLICADA';
      } else {
        // Regra-mãe (vale o site): recusar SEM escolher não deita a rolagem fora. O cartão fica por decidir, como o
        // «← Voltar» do cartão do site (REF_34): só uma escolha da lista (ou «Não acontece nada») o resolve.
        throw new ErroRecusa('acao_invalida');
      }
      if (typeof escolhida !== 'string') throw new ErroRecusa('acao_invalida');
      // Q12: o Mestre pode declarar QUAL amigo é atingido — só no «acerta-amigo» e só um dos elegíveis do cartão
      // (o VLAB recusaria os outros com ALIADO_ATINGIDO_NAO_ELEGIVEL; o servidor recusa antes, acao_invalida).
      const aliadoAtingidoId = decisao === 'editar' ? msg.edicao?.aliadoAtingidoId : undefined;
      if (aliadoAtingidoId !== undefined && aliadoAtingidoId !== null) {
        if (escolhida !== 'acerta-amigo' || !amigosDoCartao(c).includes(aliadoAtingidoId)) throw new ErroRecusa('acao_invalida');
      }
      // Resolve de novo com a MESMA semente e a escolha do Mestre (JV1.1-a §4).
      const ctx = { ...c.contexto, modoDesgraca: 'escolha', desgracaEscolhida: escolhida };
      if (typeof aliadoAtingidoId === 'string') ctx.aliadoAtingidoId = aliadoAtingidoId;
      const saida = chamarMotorAtaque(f, alvo, t, ctx);
      if (saida.erro) throw new ErroRecusa('acao_invalida', 'MOTOR:' + saida.erro);
      fecharCartao(tx, c, decisao);
      if (c.ataqueDeOportunidade) finalizarOportunidade(tx, f, alvo, t, ctx, saida, c);
      else finalizarAtaque(tx, f, alvo, t, ctx, saida);
      atualizarReciboOrigem(tx, c.origem, 'APLICADA');
      return 'APLICADA';
    }
    if (c.tipo === 'ia') {
      if (msg.rodada === true) {
        // L6: «Continuar a rodada» só para uma marcha pura aprovada tal como está.
        if (decisao !== 'aprovar' || !MARCHA_PURA.has(c.proposta?.tipo)) throw new ErroRecusa('acao_invalida');
        m.marchaLivre = m.rodada;
      }
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

  /** Fecha os cartões abertos (história: decisão 'revertido') e recusa os recibos que esperavam por eles. */
  function fecharCartoesAbertos(tx) {
    for (const c of tx.estado.cartoes) {
      if (c.estado !== 'aberto') continue;
      fecharCartao(tx, c, 'revertido');
      // Como no «voltar»: o recibo que esperava pelo cartão fica RECUSADA 'revertido', com o carimbo revertidaEm.
      const atual = c.origem?.chave ? journal.recibo(c.origem.chave) : null;
      if (atual) {
        tx.recibos.push({ chave: c.origem.chave, recibo: { ...atual, estado: 'RECUSADA', motivo: 'revertido', revertidaEm: tx.ts }, enviar: true });
      }
    }
  }

  /**
   * N4 (palavra do Mestre, 08/11: «Claro que quero»), como o site (jogo.js terminarBatalha, M-014): a batalha
   * termina a meio, quando o Mestre disser. Fim declarado: desfecho 'terminada'. Só em combate.
   */
  function terminarBatalha(tx) {
    const m = tx.estado;
    if (m.fase !== 'combate') throw new ErroRecusa('acao_invalida');
    fecharCartoesAbertos(tx);
    m.fase = 'fim';
    m.desfecho = 'terminada';
    m.vez = null;
    tx.emitir('fim', { desfecho: 'terminada' }, { origem: 'terminar' });
    return 'APLICADA';
  }

  /**
   * N4, como o site (jogo.js: «Recomeçar» = a mesma batalha do zero). Cada figura colocada volta à casa onde foi
   * colocada, com a ficha inteira (vida, PA, sem estados); o modo H10 das criaturas fica o que o Mestre escolheu.
   * Rodada 1, a começar na vez dela (D-13.3), cartões abertos fechados. O journal não apaga história: nasce o
   * evento `recomeco` e um snapshot novo para todos. Em combate ou depois do fim.
   */
  function recomecarBatalha(tx) {
    const m = tx.estado;
    if (m.fase !== 'combate' && m.fase !== 'fim') throw new ErroRecusa('acao_invalida');
    // Ordem 18 (omisso 17-3): a sala restaurada no fim com um motor de outra versão não fica em pausa (o `pausar` não
    // pausa o fim), e o «Recomeçar» começava a batalha com o motor novo, furando a E-C11. Recusa-se; o porquê vai só
    // ao Mestre (evento interno `recusa`), a Party não vê nada. A migração de motor continua TODO(JV3.x).
    if ((m.motores?.vlabSha ?? null) !== motoresInfo.vlabSha) {
      throw new ErroRecusa('acao_invalida', 'MOTOR_DIFERENTE: a sala foi gravada com outro motor (E-C11); recomeçar precisa da migração de versão');
    }
    fecharCartoesAbertos(tx);
    for (const f of colocadas(m)) {
      const novo = novaFigura(f.id, fichas[f.fichaId], null);
      const c = f.casaColocacao ?? { x: f.x, y: f.y, orientacao: f.orientacao };
      Object.assign(f, novo, {
        colocada: true, x: c.x, y: c.y, orientacao: c.orientacao ?? 'S', casaInicial: f.casaInicial,
        casaColocacao: c, modo: f.modo,
      });
    }
    m.fase = 'combate';
    m.desfecho = null;
    m.marchaLivre = null;
    // Ordem 13: a batalha do zero começa sem fogo e sem raio pendente; o painel (hora, clima, raios) fica o do Mestre.
    m.fogo = Amb.fogoVazio();
    m.ambiente = { ...m.ambiente, raioPendente: false, raioPedidoRodada: 0 };
    m.rodada = 1;
    m.ordem = ordenarPorIniciativa(colocadas(m).map((f) => f.id), m);
    m.vezIdx = m.ordem.findIndex((id) => m.figuras[id].lado === 'jogadora');
    tx.emitir('recomeco', {}, null);
    iniciarVez(tx, m.figuras[m.ordem[m.vezIdx]]);
    tx.snapshotsTodos = true;
    return 'APLICADA';
  }

  /**
   * Ordem 8 do CM-000009, item 8 (desempate do Mestre 09/11 08:18): MUDAR A ESCALA a meio da batalha.
   *  - acção só do Mestre (MASTER_SUPERVISOR op 'escala'), SEM CUSTO: não toca na vez, na acção, no PA nem na reacção;
   *  - as posições guardam-se em CASAS: nenhuma figura mexe (x, y ficam);
   *  - o movimento já gasto na volta conta em METROS: a reserva (reservaM) e o andado (andouM) da vez ficam em metros
   *    e as casas que a reserva ainda paga contam-se na escala nova (floor(reservaM / casaM)). Ex.: 9 m de base, andou
   *    2 casas a 1,5 (3 m) → sobram 6 m; a 3 m por casa, sobram 2 casas;
   *  - o servidor é dono da posição e da escala. A Party vê só o resultado (evento `escala` sem campos + snapshot
   *    novo com mapa.casaM + as opções da vez); o antes/depois fica no soMestre.
   * Em lobby ou em combate (não no fim nem em pausa; com um cartão aberto, o cartão decide-se primeiro).
   */
  function mudarEscala(tx, casaM) {
    const m = tx.estado;
    if (m.fase !== 'lobby' && m.fase !== 'combate') throw new ErroRecusa('acao_invalida');
    // Ordem 11 (P8a, REF_36): só 1 / 1,5 / 2 m por casa. O texto da recusa é o fixo (E-P7, sem números); o detalhe vai
    // só ao Mestre, no evento interno `recusa`.
    if (!ESCALAS_CASA_M.includes(casaM)) {
      throw new ErroRecusa('acao_invalida', 'ESCALA_INVALIDA: ' + casaM + ' m por casa; só valem ' + ESCALAS_CASA_M.join(' / ') + ' m');
    }
    const antes = casaDe(m);
    if (Math.abs(antes - casaM) < EPS) throw new ErroRecusa('acao_invalida'); // nada a mudar
    m.mapa.casaM = casaM;
    tx.emitir('escala', {}, {
      casaMAntes: antes, casaM,
      vez: m.vez ? { figuraId: m.vez.figuraId, reservaM: m.vez.reservaM, andouM: m.vez.andouM,
        casasQuePaga: Math.floor(m.vez.reservaM / casaM + EPS) } : null,
    });
    tx.snapshotsTodos = true; // mapa.casaM novo para todos; as opções seguem pela revisão
    return 'APLICADA';
  }

  /** MASTER_SUPERVISOR voltar: cria `revertido`; o journal nunca apaga história. */
  function voltar(tx, ateSeq) {
    const m = tx.estado;
    if (ateSeq >= journal.journalSeq || !checkpoints.has(ateSeq)) throw new ErroRecusa('acao_invalida');
    const antes = m.cartoes;
    Object.assign(m, clonarJson(checkpoints.get(ateSeq)));
    // Os cartões voltam ao instante ateSeq (delta REF_21/REF_24, I0004 08/11): o que estava por decidir nesse
    // instante volta a estar por decidir, com a MESMA rolagem gravada no cartão. Antes, todos os cartões abertos
    // fechavam como 'revertido': a rolagem por resolver ia fora sem custo (a jogadora atacava de novo, com rolagem
    // nova) e o recibo dela ficava AGUARDANDO_MESTRE para sempre. Os cartões nascidos depois de ateSeq não existiam
    // nesse instante: ficam na história, fechados 'revertido' (os recibos deles são marcados no laço abaixo).
    const noInstante = new Set(m.cartoes.map((c) => c.cartaoId));
    const abertosAntes = new Set(antes.filter((c) => c.estado === 'aberto').map((c) => c.cartaoId));
    for (const c of antes) {
      if (noInstante.has(c.cartaoId)) continue;
      const historia = clonarJson(c);
      if (historia.estado === 'aberto') {
        historia.estado = 'fechado';
        historia.decisao = 'revertido';
        tx.emitir('cartao_fechado', { cartaoId: historia.cartaoId, decisao: 'revertido' }, null);
      }
      m.cartoes.push(historia);
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
    // Cartões reabertos (decididos depois de ateSeq): o Mestre volta a recebê-los e o recibo de origem volta a
    // AGUARDANDO_MESTRE (este push vem depois do laço acima, por isso prevalece).
    for (const c of m.cartoes) {
      if (c.estado !== 'aberto' || abertosAntes.has(c.cartaoId)) continue;
      tx.emitir('cartao', { cartaoId: c.cartaoId, tipo: c.tipo }, c);
      atualizarReciboOrigem(tx, c.origem, 'AGUARDANDO_MESTRE');
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
    // Ordem 18 (omisso 17-4): cada RESYNC devolve o fluxo inteiro e cada consulta até 50 recibos. Fora do ritmo, a mesma
    // recusa do excesso de comandos (ROOM_REJECT formato, id null): nenhuma mensagem nova, e o adaptador fecha a
    // ligação se o excesso se repetir (§2), como já fazia com os comandos.
    if ((msg.type === 'ROOM_RESYNC' || msg.type === 'RECEIPT_QUERY') && !dentroDoRitmo(seatId, ritmoSinc)) {
      return [{ seatId, msg: rejeicaoNaoGravada('intentId', null, 'formato') }];
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
    tentativas.delete(chave); // reinsere no fim: o Map fica pela ordem da última falha (a mais velha à frente)
    tentativas.set(chave, r);
    if (tentativas.size > MAX_TRAVAO) podarTravao(t);
    return novo;
  }
  /**
   * Ordem 18 (omisso 17-1): o travão guardava uma entrada por IP que falhou, sem tecto (muitos IPs, IPv6 → memória
   * sem limite). Acima de MAX_TRAVAO entradas poda-se até MAX_TRAVAO_PODA: primeiro as que NÃO estão bloqueadas, da
   * falha mais velha para a mais nova; só se não chegar, as bloqueadas cujo bloqueio acaba primeiro. As entradas
   * 'lugar:' (poucas, uma por lugar configurado) nunca saem. Um IP bloqueado continua bloqueado enquanto houver
   * entradas por bloquear para podar; o que se perde ao podar é a contagem das falhas recentes e o `nivel` da
   * escada de quem já não está bloqueado (ver N18-1 no README).
   */
  function podarTravao(t) {
    const podaveis = (bloqueadas) => {
      const out = [];
      for (const [k, r] of tentativas) {
        if (!k.startsWith('ip:')) continue;
        if ((r.bloqueadoAte > t) === bloqueadas) out.push(k);
      }
      return out;
    };
    let excesso = tentativas.size - MAX_TRAVAO_PODA;
    for (const k of podaveis(false)) {
      if (excesso <= 0) return;
      tentativas.delete(k);
      excesso -= 1;
    }
    const bloqueadas = podaveis(true).sort((a, b) => tentativas.get(a).bloqueadoAte - tentativas.get(b).bloqueadoAte);
    for (const k of bloqueadas) {
      if (excesso <= 0) return;
      tentativas.delete(k);
      excesso -= 1;
    }
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
   * `seatIdDaLigacao`: o lugar a que ESTA ligação já está associada (o adaptador sabe-o), ou null.
   */
  function entrar(msg, { ip = 'desconhecido', seatIdDaLigacao = null } = {}) {
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
      // Ordem 18 (omisso 17-2): sala restaurada em combate e o Mestre ainda não voltou → a mesa congela antes de
      // esta ligação poder agir (E-C4; a IA em auto também pára). A volta do Mestre (JOIN + RESYNC) retoma-a, como
      // depois de uma queda. Restaurar e o Mestre entrar primeiro não muda nada no journal.
      if (vigiarMestreAusente && seat.papel !== 'mestre' && tx.estado.fase === 'combate' && !mestreLigado()) {
        pausar(tx, 'mestre_desconectado', 'desconexao');
      }
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
    // Ordem 17 (V6): a ligação que repete o JOIN no lugar onde já está conta-se a si mesma em `conexoes`; não é segunda.
    const propria = seatIdDaLigacao !== null && seatIdDaLigacao === seat.seatId ? 1 : 0;
    const fecharAnteriores = seat.papel !== 'mestre' && (conexoes.get(seat.seatId) ?? 0) - propria > 0;
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

  function mestreLigado() {
    return Object.values(journal.estado.lugares).some((s) => s.papel === 'mestre' && (conexoes.get(s.seatId) ?? 0) > 0);
  }

  function conexaoAberta(seatId) {
    const s = journal.estado.lugares[seatId];
    if (!s) return [];
    conexoes.set(seatId, (conexoes.get(seatId) ?? 0) + 1);
    if (s.papel === 'mestre') vigiarMestreAusente = false; // daqui em diante vale a E-C4 de sempre (queda → pausa)
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
      travao: () => tentativas.size, // ordem 18 (17-1): nº de entradas do travão do ROOM_JOIN
    }),
  });
}
