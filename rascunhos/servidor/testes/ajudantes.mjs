// Ajudantes dos testes: mesa determinista (rng e relógio fixos), clientes que guardam
// tudo o que recebem, e o varrimento de canários.

import { readFileSync } from 'node:fs';
import { carregarFichas } from '../nucleo/carregar-fichas.js';
import { criarSala } from '../nucleo/sala.js';
import { criarMotorFalso } from './motor-falso.mjs';

export const FIXTURE = JSON.parse(readFileSync(new URL('../dados-exemplo/fichas-ficticias.json', import.meta.url), 'utf8'));
export const PIN = '90210777';
export const SENHAS = Object.freeze({ heroina: 'CANARIO-SENHA-H', aliada: 'CANARIO-SENHA-A', espectador: 'CANARIO-SENHA-E' });
// Valores de iniciativa: só do Mestre (a Party vê só a ordem). Também são canários.
export const INICIATIVA = Object.freeze({
  'heroina-teste': 973, 'aliada-teste': 971, 'lobo-teste': 967, 'orc-teste': 953, 'bandido-teste': 947,
});

export function rngDeterministico(semente = 0x9e3779b9) {
  let x = semente >>> 0 || 1;
  return () => {
    x ^= x << 13;
    x ^= x >>> 17;
    x ^= x << 5;
    x >>>= 0;
    return x;
  };
}

export function relogio(inicio = Date.UTC(2026, 10, 6, 20, 0, 0), passo = 250) {
  let t = inicio;
  return () => (t += passo);
}

/** Fichas da fixture (+ uma segunda jogadora derivada, para os testes de "outra jogadora"). */
export function listaDeFichas({ comAliada = false } = {}) {
  const lista = JSON.parse(JSON.stringify(FIXTURE.fichas));
  if (comAliada) {
    const a = JSON.parse(JSON.stringify(lista.find((f) => f.id === 'heroina-teste')));
    a.id = 'aliada-teste';
    a.nome = 'Aliada Teste';
    a.nomePublico = 'Aliada Teste';
    a.ca = 2468; // canários DELA (a heroína não os pode ver)
    a.vidaTotal = 3579;
    a.paTotal = 1357;
    a.testes.percepcao = '1d20+1';
    lista.push(a);
  }
  return lista;
}

export function fichasDeTeste(opcoes) {
  const r = carregarFichas(listaDeFichas(opcoes));
  if (!r.ok) throw new Error('fixture inválida: ' + JSON.stringify(r.erros));
  return r.fichas;
}

export class Cliente {
  constructor(nome) {
    this.nome = nome;
    this.msgs = [];
    this.seatId = null;
    this.token = null;
    this.figuraId = null;
    this.revision = 0;
    this.opcoes = null;
    this.ultimoSeq = 0;
  }
  receber(msg) {
    // Cópia: o cliente guarda o que "chegou pelo fio".
    const m = JSON.parse(JSON.stringify(msg));
    this.msgs.push(m);
    if (Number.isInteger(m.revision) && m.revision > this.revision) this.revision = m.revision;
    if (m.type === 'ROOM_OPTIONS') this.opcoes = m;
    if (m.type === 'ROOM_WELCOME') {
      this.seatId = m.seatId;
      this.token = m.seatToken;
    }
    if (m.type === 'ROOM_SNAPSHOT' && m.propria) this.figuraId = m.propria.figuraId;
    if ((m.type === 'ROOM_EVENT' || m.type === 'ROOM_SNAPSHOT') && m.seq > this.ultimoSeq) this.ultimoSeq = m.seq;
  }
  ultimo(type) {
    for (let i = this.msgs.length - 1; i >= 0; i--) if (this.msgs[i].type === type) return this.msgs[i];
    return null;
  }
  eventos(tipo) {
    return this.msgs.filter((m) => m.type === 'ROOM_EVENT' && (!tipo || m.tipo === tipo));
  }
  /** Id opaco de uma figura pelo nome público (a partir do que este cliente viu). */
  idPorNome(nomePublico) {
    for (const m of this.msgs) {
      if (m.type === 'ROOM_EVENT' && m.tipo === 'colocacao' && m.dados.nomePublico === nomePublico) return m.dados.figuraId;
      if (m.type === 'ROOM_SNAPSHOT') {
        const f = m.figuras.find((x) => x.nomePublico === nomePublico);
        if (f) return f.id;
      }
    }
    return null;
  }
}

/**
 * Mesa de teste. Tudo é determinista: o mesmo guião dá os mesmos ids, sementes e revisões.
 */
export function montarMesa({
  motor = criarMotorFalso(), comAliada = false, comEspectador = false, rngSemente, modoPadrao = 'auto',
  mapa = { largura: 20, altura: 20 }, casas = {},
} = {}) {
  const fichas = fichasDeTeste({ comAliada });
  const lugares = [
    { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: casas.heroina ?? { x: 2, y: 2 } },
  ];
  if (comAliada) {
    lugares.push({ papel: 'jogadora', nome: 'Aliada Teste', senha: SENHAS.aliada, fichaId: 'aliada-teste', casa: casas.aliada ?? { x: 2, y: 4 } });
  }
  if (comEspectador) lugares.push({ papel: 'espectador', nome: 'Visita', senha: SENHAS.espectador });
  lugares.push({ papel: 'mestre', nome: 'Mestre', pin: PIN });
  const config = { roomId: 'sala-teste', mapa, lugares, iniciativa: INICIATIVA, modoPadrao, depurar: true };
  const sala = criarSala({ motores: motor, fichas, rng: rngDeterministico(), rngSemente, agora: relogio(), config });

  const clientes = {};
  const porSeat = new Map();
  let contador = 0;
  const novoId = (p = 'id') => `${p}-${++contador}`;

  function entregar(saidas) {
    for (const { seatId, msg } of saidas) porSeat.get(seatId)?.receber(msg);
  }

  function entrar(chave, msgJoin, ip = '10.0.0.' + (Object.keys(clientes).length + 1)) {
    const c = clientes[chave] ?? new Cliente(chave);
    const r = sala.entrar({ v: 2, type: 'ROOM_JOIN', roomId: 'sala-teste', ...msgJoin }, { ip });
    if (!r.ok) {
      for (const m of r.mensagens) c.receber(m);
      entregar(r.saidas);
      return { ok: false, cliente: c, r };
    }
    clientes[chave] = c;
    porSeat.set(r.seatId, c);
    sala.conexaoAberta(r.seatId);
    for (const m of r.mensagens) c.receber(m);
    entregar(r.saidas);
    return { ok: true, cliente: c, r };
  }

  function sair(chave) {
    const c = clientes[chave];
    entregar(sala.conexaoFechada(c.seatId));
  }

  /** Envia e entrega a todos; devolve só o que voltou para quem enviou. */
  function enviar(chave, msg) {
    const c = clientes[chave];
    const saidas = sala.receber(c.seatId, { v: 2, roomId: 'sala-teste', ...msg });
    entregar(saidas);
    return saidas.filter((s) => s.seatId === c.seatId).map((s) => JSON.parse(JSON.stringify(s.msg)));
  }

  function mestre(type, campos = {}) {
    return enviar('mestre', { type, cmdId: novoId('cmd'), revision: clientes.mestre.revision, ...campos });
  }

  function intencao(chave, acao, extra = {}) {
    const c = clientes[chave];
    const msg = { type: 'ROOM_INTENT', intentId: extra.intentId ?? novoId('it'), revision: extra.revision ?? c.revision, acao };
    if (extra.dadosFisicos) msg.dadosFisicos = extra.dadosFisicos;
    return enviar(chave, msg);
  }

  function entrarTodos() {
    entrar('mestre', { papel: 'mestre', pin: PIN });
    entrar('heroina', { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina });
    if (comAliada) entrar('aliada', { papel: 'jogadora', nome: 'Aliada Teste', senha: SENHAS.aliada });
    if (comEspectador) entrar('espectador', { papel: 'espectador', nome: 'Visita', senha: SENHAS.espectador });
  }

  /** Lobby, START e colocação. `criaturas` = [[fichaId, {x,y}], ...]. */
  function iniciarCombate(criaturas = [['orc-teste', { x: 2, y: 6 }]]) {
    const r1 = mestre('MASTER_LOBBY_SET', {
      mapaId: 'arena-teste', criaturasDisponiveis: ['orc-teste', 'lobo-teste'], npcsDisponiveis: ['bandido-teste'],
    });
    exigirAplicada(r1, 'LOBBY_SET');
    exigirAplicada(mestre('MASTER_START'), 'START');
    for (const [fichaId, casa] of criaturas) exigirAplicada(mestre('MASTER_PLACE', { fichaId, casa }), 'PLACE ' + fichaId);
  }

  return { sala, motor, fichas, clientes, entrar, sair, enviar, mestre, intencao, entrarTodos, iniciarCombate, entregar, novoId };
}

export function recibo(respostas) {
  return respostas.find((m) => m.type === 'ROOM_RECEIPT' || m.type === 'ROOM_REJECT') ?? null;
}

export function exigirAplicada(respostas, rotulo = '') {
  const r = recibo(respostas);
  if (!r || r.type !== 'ROOM_RECEIPT' || r.estado !== 'APLICADA') {
    throw new Error(`esperava APLICADA (${rotulo}), veio ${JSON.stringify(r)}`);
  }
  return r;
}

/**
 * Varre um valor JSON e chama `visitar({chave, valor, ehChave})` para cada chave e cada folha.
 */
export function varrer(valor, visitar, chave = null) {
  if (Array.isArray(valor)) {
    for (const v of valor) varrer(v, visitar, chave);
  } else if (valor !== null && typeof valor === 'object') {
    for (const [k, v] of Object.entries(valor)) {
      visitar({ chave: k, valor: k, ehChave: true });
      varrer(v, visitar, k);
    }
  } else {
    visitar({ chave, valor, ehChave: false });
  }
}

/**
 * Procura canários numa lista de mensagens. Devolve a lista de achados (vazia = limpo).
 * - numeros: valores numéricos proibidos (comparação exata). Números pequenos (< 100)
 *   não contam nas chaves seq/revision/rodada, que são contadores do servidor.
 * - textos: substrings proibidas em qualquer string (chaves incluídas).
 * - chaves: nomes de chave proibidos.
 */
export function procurarCanarios(mensagens, { numeros = [], textos = [], chaves = [] }) {
  const achados = [];
  const contadores = new Set(['seq', 'revision', 'rodada', 'x', 'y']);
  mensagens.forEach((msg, i) => {
    varrer(msg, ({ chave, valor, ehChave }) => {
      if (ehChave && chaves.includes(valor)) achados.push({ i, type: msg.type, tipo: msg.tipo, chave: valor, porque: 'chave proibida' });
      if (typeof valor === 'number' && numeros.includes(valor)) {
        if (!(contadores.has(chave) && valor < 100)) achados.push({ i, type: msg.type, tipo: msg.tipo, chave, valor });
      }
      if (typeof valor === 'string') {
        for (const t of textos) if (valor.includes(t)) achados.push({ i, type: msg.type, tipo: msg.tipo, chave, valor: t });
      }
    });
  });
  return achados;
}
