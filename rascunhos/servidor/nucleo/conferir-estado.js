// Conferência completa do estado restaurado (ordem 34 do CM-000009, N31-1; sentença da bancada de 2026-11-12).
// REGRA: sem node:*. Só lê: nunca repara, nunca põe valores por omissão, nunca apaga nada.
//
// O V10 (ordem 18, `conferirFormaDoEstado` em sala.js) confere a forma de topo. Aqui confere-se o resto, antes de a
// sala abrir:
//  (1) esquema completo em profundidade — tipos e campos obrigatórios em todos os níveis do estado `sala/1`, e a
//      forma dos eventos, recibos e fluxos que o servidor volta a ler;
//  (2) referências que existem — a ficha de cada figura, a figura da vez, da ordem, de cada lugar e de cada cartão
//      aberto (ordem 35, N34-1: os fechados são história e podem apontar para uma figura que o «voltar» desfez).
// Um campo inválido = ErroJournal com o `caminho` do campo (ex.: `figuras.<id>.fichaId`): a sala não abre.
//
// O que é obrigatório: o que o servidor sempre escreveu e lê sem rede. O que ele próprio já lia com tolerância à falta
// (journals de antes da ordem que o criou: `fogo`, `mapa.casaM`, `motores`, `marchaLivre`, `casaColocacao`,
// `seqSnapshot`, `seqEspera`, os campos do painel de ambiente) pode faltar; se estiver presente, tem de ter o tipo certo.
// Chaves a mais não são erro (ninguém as lê) — excepto em `ordemDinamica`, `ordemDinamicaParty` e
// `caixaMestre`, que recusam chaves a mais (ordem CAIXA-LOBBY, B7a). Nenhuma regra de jogo: só forma e referências.

import { ErroJournal } from './journal.js';

const FASES = Object.freeze(['lobby', 'combate', 'pausa', 'fim']);
const PAPEIS = Object.freeze(['jogadora', 'espectador', 'mestre']);
const LADOS = Object.freeze(['jogadora', 'criatura', 'npc']);
const MODOS = Object.freeze(['manual', 'semi', 'auto']);
const ESTADOS_RECIBO = Object.freeze(['APLICADA', 'RECUSADA', 'AGUARDANDO_MESTRE']);

const ehObj = (v) => v !== null && typeof v === 'object' && !Array.isArray(v);
const ehTexto = (v) => typeof v === 'string';
const ehTextoCheio = (v) => typeof v === 'string' && v.length > 0;
const ehBool = (v) => typeof v === 'boolean';
const ehNum = (v) => typeof v === 'number' && Number.isFinite(v);
const ehNumPos0 = (v) => ehNum(v) && v >= 0;
const ehInt = (v) => Number.isInteger(v);
const ehIntPos0 = (v) => Number.isInteger(v) && v >= 0;
const tem = (o, k) => Object.prototype.hasOwnProperty.call(o, k);

function falha(caminho, porque) {
  throw new ErroJournal(`estado da sala inválido em ${caminho} (${porque})`, caminho);
}

/** O campo `k` de `o` é obrigatório e tem de passar `teste`. */
function exigir(o, k, base, teste, porque) {
  const caminho = base ? base + '.' + k : k;
  if (!tem(o, k) || o[k] === undefined) falha(caminho, 'em falta');
  if (!teste(o[k])) falha(caminho, porque);
}
/** O campo `k` pode faltar; presente, tem de passar `teste`. */
function seHouver(o, k, base, teste, porque) {
  if (!tem(o, k) || o[k] === undefined) return;
  if (!teste(o[k])) falha(base ? base + '.' + k : k, porque);
}
const ouNull = (teste) => (v) => v === null || teste(v);

function conferirCasa(c, caminho, comOrientacao) {
  if (!ehObj(c)) falha(caminho, 'não é objecto');
  exigir(c, 'x', caminho, ehInt, 'não é inteiro');
  exigir(c, 'y', caminho, ehInt, 'não é inteiro');
  if (comOrientacao) seHouver(c, 'orientacao', caminho, ouNull(ehTexto), 'não é texto');
}

function conferirFigura(f, id, fichas) {
  const p = 'figuras.' + id;
  if (!ehObj(f)) falha(p, 'não é objecto');
  exigir(f, 'id', p, (v) => v === id, 'não é a chave da figura');
  exigir(f, 'fichaId', p, ehTextoCheio, 'não é texto');
  // Camada 2: a ficha existe (as fichas são as que o carregador entregou a esta sala).
  if (!tem(fichas, f.fichaId) || !ehObj(fichas[f.fichaId])) falha(p + '.fichaId', 'ficha inexistente');
  exigir(f, 'lado', p, (v) => LADOS.includes(v), 'lado desconhecido');
  exigir(f, 'colocada', p, ehBool, 'não é booleano');
  exigir(f, 'x', p, ehInt, 'não é inteiro');
  exigir(f, 'y', p, ehInt, 'não é inteiro');
  exigir(f, 'orientacao', p, ehTexto, 'não é texto');
  exigir(f, 'casaInicial', p, ouNull(ehObj), 'não é objecto nem null');
  if (f.casaInicial !== null) conferirCasa(f.casaInicial, p + '.casaInicial', false);
  exigir(f, 'vidaActual', p, ehNum, 'não é número finito');
  exigir(f, 'paGasto', p, ehNumPos0, 'não é número finito >= 0');
  for (const k of ['vivo', 'caido', 'armaCaida', 'armaQuebrada', 'corpoPartido', 'transformada', 'reacaoDisponivel', 'defendendo']) {
    exigir(f, k, p, ehBool, 'não é booleano');
  }
  exigir(f, 'estadoMorte', p, ouNull(ehObj), 'não é objecto nem null');
  if (f.estadoMorte !== null) {
    seHouver(f.estadoMorte, 'fase', p + '.estadoMorte', ehTexto, 'não é texto');
    seHouver(f.estadoMorte, 'sucessos', p + '.estadoMorte', ehNum, 'não é número finito');
    seHouver(f.estadoMorte, 'falhas', p + '.estadoMorte', ehNum, 'não é número finito');
  }
  exigir(f, 'modo', p, ouNull((v) => MODOS.includes(v)), 'modo desconhecido');
  seHouver(f, 'casaColocacao', p, ouNull(ehObj), 'não é objecto nem null');
  if (ehObj(f.casaColocacao)) conferirCasa(f.casaColocacao, p + '.casaColocacao', true);
  // Ordem 34 (D-1): a ordem de colocação (journals de antes não a têm); presente, inteiro >= 1.
  if (ehObj(f.casaColocacao)) seHouver(f.casaColocacao, 'ordem', p + '.casaColocacao', (v) => Number.isInteger(v) && v >= 1, 'não é inteiro >= 1');
}

function conferirLugar(s, id, e, fluxos) {
  const p = 'lugares.' + id;
  if (!ehObj(s)) falha(p, 'não é objecto');
  exigir(s, 'seatId', p, (v) => v === id, 'não é a chave do lugar');
  exigir(s, 'indice', p, ehIntPos0, 'não é inteiro >= 0');
  exigir(s, 'papel', p, (v) => PAPEIS.includes(v), 'papel desconhecido');
  exigir(s, 'nome', p, ouNull(ehTexto), 'não é texto nem null');
  exigir(s, 'figuraId', p, ouNull(ehTextoCheio), 'não é texto nem null');
  // Camada 2: a jogadora tem a sua figura; os outros papéis não têm nenhuma.
  if (s.papel === 'jogadora') {
    if (s.figuraId === null || !tem(e.figuras, s.figuraId)) falha(p + '.figuraId', 'figura inexistente');
  } else if (s.figuraId !== null && !tem(e.figuras, s.figuraId)) {
    falha(p + '.figuraId', 'figura inexistente');
  }
  exigir(s, 'seq', p, ehIntPos0, 'não é inteiro >= 0');
  // O seq do lugar é o tamanho do fluxo gravado dele (o commit seguinte recusa qualquer outro: «seq com buraco»).
  const fluxo = fluxos && tem(fluxos, id) ? fluxos[id] : [];
  if (Array.isArray(fluxo) && s.seq !== fluxo.length) falha(p + '.seq', 'não confere com o fluxo gravado');
  exigir(s, 'revision', p, ehIntPos0, 'não é inteiro >= 0');
  exigir(s, 'revisaoHash', p, ouNull(ehTexto), 'não é texto nem null');
  exigir(s, 'tokenHash', p, ouNull(ehTexto), 'não é texto nem null');
  exigir(s, 'epoch', p, ehIntPos0, 'não é inteiro >= 0');
  seHouver(s, 'seqSnapshot', p, ehIntPos0, 'não é inteiro >= 0');
  seHouver(s, 'seqEspera', p, ehIntPos0, 'não é inteiro >= 0');
}

function conferirVez(v, e) {
  if (v === null) return;
  if (!ehObj(v)) falha('vez', 'não é objecto nem null');
  exigir(v, 'figuraId', 'vez', ehTextoCheio, 'não é texto');
  if (!tem(e.figuras, v.figuraId)) falha('vez.figuraId', 'figura inexistente'); // camada 2
  for (const k of ['atacou', 'correrUsado', 'desvinculou', 'iaMoveu', 'iaPausada']) exigir(v, k, 'vez', ehBool, 'não é booleano');
  exigir(v, 'andouM', 'vez', ehNumPos0, 'não é número finito >= 0');
  exigir(v, 'reservaM', 'vez', ehNumPos0, 'não é número finito >= 0');
  exigir(v, 'cobertos', 'vez', Array.isArray, 'não é lista');
  v.cobertos.forEach((x, i) => { if (!ehTexto(x)) falha('vez.cobertos.' + i, 'não é texto'); });
  exigir(v, 'recusas', 'vez', ehIntPos0, 'não é inteiro >= 0');
  exigir(v, 'intencoes', 'vez', ehIntPos0, 'não é inteiro >= 0');
}

function conferirCartao(c, i, e) {
  const p = 'cartoes.' + i;
  if (!ehObj(c)) falha(p, 'não é objecto');
  exigir(c, 'cartaoId', p, ehTextoCheio, 'não é texto');
  exigir(c, 'estado', p, (v) => v === 'aberto' || v === 'fechado', 'estado desconhecido');
  exigir(c, 'tipo', p, ehTextoCheio, 'não é texto');
  exigir(c, 'decisao', p, ouNull(ehTexto), 'não é texto nem null');
  seHouver(c, 'figuraId', p, ouNull(ehTextoCheio), 'não é texto nem null');
  seHouver(c, 'alvoId', p, ouNull(ehTextoCheio), 'não é texto nem null');
  // Camada 2: as figuras do cartão ABERTO existem (ordem 35, N34-1). Só os abertos se voltam a ler (o cartão pendente,
  // a MASTER_VIEW, o MASTER_APPROVE). Os fechados são história: o «voltar» para antes de uma figura deixa os cartões
  // nascidos depois fechados «revertido», a apontar para a figura que ainda não existia — e esse estado, gravado pelo
  // próprio servidor, tem de voltar a abrir. A forma (texto ou null) continua conferida acima.
  if (c.estado === 'aberto') {
    for (const k of ['figuraId', 'alvoId']) if (ehTexto(c[k]) && !tem(e.figuras, c[k])) falha(p + '.' + k, 'figura inexistente');
  }
  seHouver(c, 'tecnicaId', p, ouNull(ehTexto), 'não é texto nem null');
  seHouver(c, 'razao', p, ouNull(ehTexto), 'não é texto nem null');
  seHouver(c, 'faces', p, ouNull(Array.isArray), 'não é lista nem null');
  seHouver(c, 'excluidas', p, Array.isArray, 'não é lista');
  seHouver(c, 'aooRestantes', p, Array.isArray, 'não é lista');
  seHouver(c, 'contexto', p, ouNull(ehObj), 'não é objecto nem null');
  seHouver(c, 'saidaProposta', p, ouNull(ehObj), 'não é objecto nem null');
  seHouver(c, 'origem', p, ouNull(ehObj), 'não é objecto nem null');
  if (ehObj(c.origem)) {
    for (const k of ['seatId', 'id', 'idCampo', 'chave']) exigir(c.origem, k, p + '.origem', ehTexto, 'não é texto');
  }
}

function conferirFogo(fogo) {
  if (!ehObj(fogo)) falha('fogo', 'não é objecto');
  exigir(fogo, 'casas', 'fogo', Array.isArray, 'não é lista');
  fogo.casas.forEach((c, i) => {
    const p = 'fogo.casas.' + i;
    if (!ehObj(c)) falha(p, 'não é objecto');
    exigir(c, 'x', p, ehInt, 'não é inteiro');
    exigir(c, 'y', p, ehInt, 'não é inteiro');
    exigir(c, 'combustivel', p, ehNum, 'não é número finito');
  });
  exigir(fogo, 'aArder', 'fogo', Array.isArray, 'não é lista');
  fogo.aArder.forEach((x, i) => { if (!ehTexto(x)) falha('fogo.aArder.' + i, 'não é texto'); });
  exigir(fogo, 'ultimoTick', 'fogo', ehObj, 'não é objecto');
  for (const [k, v] of Object.entries(fogo.ultimoTick)) if (!ehNum(v)) falha('fogo.ultimoTick.' + k, 'não é número finito');
  exigir(fogo, 'rodadaResolvida', 'fogo', ehNum, 'não é número finito');
}

/**
 * Confere o estado `sala/1` restaurado, em profundidade (camadas 1 e 2). Lança ErroJournal com `.caminho`.
 * Pressupõe a forma de topo já conferida (V10). `fluxos`: seatId → mensagens gravadas (para o seq de cada lugar).
 */
export function conferirEstadoProfundo(e, fichas, fluxos = null) {
  if (!ehObj(e)) falha('estado', 'não é objecto');
  exigir(e, 'formato', '', (v) => v === 'sala/1', 'formato desconhecido');
  exigir(e, 'roomId', '', ehTextoCheio, 'não é texto');
  exigir(e, 'fase', '', (v) => FASES.includes(v), 'fase desconhecida');

  exigir(e, 'pausa', '', ouNull(ehObj), 'não é objecto nem null');
  if (e.fase === 'pausa' && e.pausa === null) falha('pausa', 'em falta com a sala em pausa');
  if (e.pausa !== null) {
    exigir(e.pausa, 'motivo', 'pausa', ehTexto, 'não é texto');
    exigir(e.pausa, 'origem', 'pausa', ehTexto, 'não é texto');
    exigir(e.pausa, 'faseAnterior', 'pausa', (v) => FASES.includes(v) && v !== 'pausa', 'fase desconhecida');
  }

  exigir(e, 'mapa', '', ehObj, 'não é objecto');
  exigir(e.mapa, 'largura', 'mapa', (v) => ehInt(v) && v >= 1, 'não é inteiro >= 1');
  exigir(e.mapa, 'altura', 'mapa', (v) => ehInt(v) && v >= 1, 'não é inteiro >= 1');
  seHouver(e.mapa, 'casaM', 'mapa', (v) => ehNum(v) && v > 0, 'não é número finito > 0');

  exigir(e, 'lobby', '', ouNull(ehObj), 'não é objecto nem null');
  if (e.lobby !== null) {
    exigir(e.lobby, 'mapaId', 'lobby', ouNull(ehTexto), 'não é texto nem null');
    for (const k of ['criaturasDisponiveis', 'npcsDisponiveis']) {
      exigir(e.lobby, k, 'lobby', Array.isArray, 'não é lista');
      e.lobby[k].forEach((x, i) => { if (!ehTexto(x)) falha(`lobby.${k}.${i}`, 'não é texto'); });
    }
  }

  exigir(e, 'figuras', '', ehObj, 'não é objecto');
  for (const [id, f] of Object.entries(e.figuras)) conferirFigura(f, id, fichas);

  exigir(e, 'lugares', '', ehObj, 'não é objecto');
  for (const [id, s] of Object.entries(e.lugares)) conferirLugar(s, id, e, fluxos);

  exigir(e, 'ordem', '', Array.isArray, 'não é lista');
  e.ordem.forEach((id, i) => {
    if (!ehTextoCheio(id)) falha('ordem.' + i, 'não é texto');
    if (!tem(e.figuras, id)) falha('ordem.' + i, 'figura inexistente'); // camada 2
  });
  exigir(e, 'vezIdx', '', (v) => ehInt(v) && v >= -1, 'não é inteiro >= -1');
  exigir(e, 'rodada', '', ehIntPos0, 'não é inteiro >= 0');
  exigir(e, 'vez', '', ouNull(ehObj), 'não é objecto nem null');
  conferirVez(e.vez, e);

  exigir(e, 'ambiente', '', ehObj, 'não é objecto');
  seHouver(e.ambiente, 'hora', 'ambiente', ouNull(ehTexto), 'não é texto nem null');
  seHouver(e.ambiente, 'clima', 'ambiente', ouNull(ehTexto), 'não é texto nem null');
  seHouver(e.ambiente, 'futuro', 'ambiente', ouNull(ehTexto), 'não é texto nem null');
  seHouver(e.ambiente, 'raios', 'ambiente', ehBool, 'não é booleano');
  seHouver(e.ambiente, 'raioPendente', 'ambiente', ehBool, 'não é booleano');
  seHouver(e.ambiente, 'raioPedidoRodada', 'ambiente', ehInt, 'não é inteiro');

  if (tem(e, 'fogo') && e.fogo !== undefined) conferirFogo(e.fogo);

  exigir(e, 'cartoes', '', Array.isArray, 'não é lista');
  e.cartoes.forEach((c, i) => conferirCartao(c, i, e));

  exigir(e, 'contadores', '', ehObj, 'não é objecto');
  exigir(e.contadores, 'cartao', 'contadores', ehIntPos0, 'não é inteiro >= 0');
  exigir(e.contadores, 'ia', 'contadores', ehIntPos0, 'não é inteiro >= 0');

  seHouver(e, 'motores', '', ouNull(ehObj), 'não é objecto nem null');
  if (ehObj(e.motores)) {
    for (const k of ['vlabSha', 'dmgVersao', 'levelupSha']) seHouver(e.motores, k, 'motores', ouNull(ehTexto), 'não é texto nem null');
  }
  exigir(e, 'desfecho', '', ouNull(ehTexto), 'não é texto nem null');
  seHouver(e, 'marchaLivre', '', ouNull(ehInt), 'não é inteiro nem null');
  // Ordem INICIATIVA NO SERVIDOR: a ordem dinâmica da caixa do Mestre (journals de antes não a têm; o «voltar» a um
  // ponto de antes dela põe null). Presente: só ids de figuras que existem, um booleano e um contador.
  seHouver(e, 'ordemDinamica', '', ouNull(ehObj), 'não é objecto nem null');
  if (ehObj(e.ordemDinamica)) conferirOrdemDinamica(e.ordemDinamica, e);
  // Ordem CAIXA-HUD-JOGADORA: a ordem dinâmica da Party (journals de antes não a têm). A mesma forma.
  seHouver(e, 'ordemDinamicaParty', '', ouNull(ehObj), 'não é objecto nem null');
  if (ehObj(e.ordemDinamicaParty)) conferirOrdemDinamica(e.ordemDinamicaParty, e, 'ordemDinamicaParty');
  // Ordem CAIXA-PERSISTENTE: a escolha da caixa do Mestre (journals de antes não a têm). Presente: um booleano e um modo.
  seHouver(e, 'caixaMestre', '', ehObj, 'não é objecto');
  if (ehObj(e.caixaMestre)) {
    exigir(e.caixaMestre, 'ligada', 'caixaMestre', ehBool, 'não é booleano');
    exigir(e.caixaMestre, 'modo', 'caixaMestre', (v) => v === 'dinamico' || v === 'iniciativa', 'modo desconhecido');
    for (const k of Object.keys(e.caixaMestre)) if (k !== 'ligada' && k !== 'modo') falha('caixaMestre.' + k, 'campo a mais');
  }
}

/** Ordem CAIXA-LOBBY (B7a): as chaves da ordem dinâmica (ordem-dinamica.js ordemDinamicaVazia); nenhuma outra. */
const CHAVES_ORDEM_DINAMICA = ['ordem', 'fechada', 'ultimo', 'vezes'];

function conferirOrdemDinamica(od, e, p = 'ordemDinamica') {
  exigir(od, 'ordem', p, Array.isArray, 'não é lista');
  od.ordem.forEach((id, i) => {
    if (!ehTextoCheio(id)) falha(`${p}.ordem.${i}`, 'não é texto');
    if (!tem(e.figuras, id)) falha(`${p}.ordem.${i}`, 'figura inexistente'); // camada 2
  });
  exigir(od, 'fechada', p, ehBool, 'não é booleano');
  exigir(od, 'ultimo', p, ouNull(ehTextoCheio), 'não é texto nem null');
  if (od.ultimo !== null && !tem(e.figuras, od.ultimo)) falha(p + '.ultimo', 'figura inexistente'); // camada 2
  exigir(od, 'vezes', p, ehIntPos0, 'não é inteiro >= 0');
  // Ordem CAIXA-LOBBY (B7a): como a caixaMestre — uma chave fora da lista recusa o journal, não se ignora.
  for (const k of Object.keys(od)) if (!CHAVES_ORDEM_DINAMICA.includes(k)) falha(`${p}.${k}`, 'campo a mais');
}

/**
 * Confere a forma dos eventos, dos recibos e dos fluxos que o servidor volta a ler depois de restaurar (camada 1) e os
 * lugares a que pertencem (camada 2). O `restaurarJournal` já conferiu a moldura, a cadeia e a numeração.
 * @param {{eventos:Array, recibos:Array<[string,Object]>, fluxos:Object<string,Array>}} corpo
 */
export function conferirRegistoProfundo(corpo, e) {
  corpo.eventos.forEach((ev, i) => {
    const p = 'eventos.' + i;
    exigir(ev, 'ts', p, ehTexto, 'não é texto');
    exigir(ev, 'tipo', p, ehTextoCheio, 'não é texto');
    exigir(ev, 'dados', p, ehObj, 'não é objecto');
    exigir(ev, 'soMestre', p, ouNull(ehObj), 'não é objecto nem null');
  });
  corpo.recibos.forEach(([chave, r], i) => {
    const p = 'recibos.' + i;
    exigir(r, 'seatId', p, ehTextoCheio, 'não é texto');
    // Os recibos das acções da IA são do pseudo-lugar «ia» (sala.js: aplicarAcaoIA); os outros são de um lugar que existe.
    if (r.seatId !== 'ia' && !tem(e.lugares, r.seatId)) falha(p + '.seatId', 'lugar inexistente');
    exigir(r, 'id', p, ehTextoCheio, 'não é texto');
    exigir(r, 'idCampo', p, (v) => v === 'intentId' || v === 'cmdId', 'campo de id desconhecido');
    exigir(r, 'hashAcao', p, ehTexto, 'não é texto');
    exigir(r, 'estado', p, (v) => ESTADOS_RECIBO.includes(v), 'estado desconhecido');
    exigir(r, 'motivo', p, ouNull(ehTexto), 'não é texto nem null');
    for (const k of ['seq', 'revision', 'journalSeq']) exigir(r, k, p, ehIntPos0, 'não é inteiro >= 0');
    exigir(r, 'revertidaEm', p, ouNull(ehTexto), 'não é texto nem null');
    if (!chave.startsWith(r.seatId + '\u0000')) falha(p, 'a chave não é do lugar do recibo');
  });
  for (const [seatId, fluxo] of Object.entries(corpo.fluxos)) {
    if (!tem(e.lugares, seatId)) falha('fluxos.' + seatId, 'lugar inexistente');
    fluxo.forEach((m, i) => {
      const p = `fluxos.${seatId}.${i}`;
      exigir(m, 'type', p, (v) => v === 'ROOM_EVENT', 'não é ROOM_EVENT');
      exigir(m, 'tipo', p, ehTextoCheio, 'não é texto');
      exigir(m, 'dados', p, ehObj, 'não é objecto');
    });
  }
}
