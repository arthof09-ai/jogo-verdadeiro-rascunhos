// Projeção por destinatário (protocolo v2 §6, ERRATA v0.2 E-P1..E-P14 e v0.2.1).
// REGRA: sem node:*.
//
// Princípio: LISTA DE CAMPOS PERMITIDOS. Um campo que não esteja na lista do tipo de
// evento, para aquele papel, NÃO SAI. Um tipo de evento que não esteja na lista não sai
// para nenhum papel que não seja o Mestre (falha fechada).
// Nada de `soMestre` nem de `publico.recibo` do motor chega à Party: o recibo do motor
// só é guardado em `soMestre` pelo núcleo, e aqui só se copiam campos da lista.

import { clonarJson } from './util.js';
import { fogoPublico, fogoDoMestre } from './ambiente.js';

/**
 * Campos permitidos por tipo de ROOM_EVENT.
 *  - `todos`: Party inteira (jogadoras e espectadores);
 *  - `propria`: só a jogadora a quem o evento diz respeito (ver EH_PROPRIO).
 * Campo novo entra AQUI primeiro (regra de ouro do §6), e o teste de privacidade
 * falha se o núcleo emitir para a Party um campo fora desta lista.
 */
export const CAMPOS_PERMITIDOS = Object.freeze({
  entrada: Object.freeze({ todos: ['figuraId', 'nomePublico', 'lado'], propria: [] }),
  colocacao: Object.freeze({ todos: ['figuraId', 'nomePublico', 'lado', 'x', 'y', 'orientacao', 'visivel'], propria: [] }),
  turno: Object.freeze({ todos: ['figuraId', 'rodada', 'narra'], propria: [] }), // E-P11: o modo nunca sai
  movimento: Object.freeze({ todos: ['figuraId', 'de', 'para', 'caminho'], propria: ['custoM', 'reservaM'] }),
  // v0.2.1: a jogadora vê a expressão, as faces e o total do ataque DELA.
  ataque: Object.freeze({
    todos: ['atacanteId', 'alvoId', 'arma', 'resultado', 'ataqueDeOportunidade'],
    propria: ['total', 'faces', 'expressao'],
  }),
  // v0.2.1: o número do dano só a quem causou ou a quem recebeu (A-2: outra jogadora ✘).
  dano: Object.freeze({ todos: ['alvoId', 'autorId'], propria: ['valor', 'tipos'] }),
  // Ordem 7 (site REF_31, vlabFiltrarReciboCura): a Party vê quem curou quem e com que técnica; a expressão e as faces só
  // quem cura (se é jogadora). O total da cura e a Vida do alvo não saem daqui (o `estado` da própria traz a Vida dela).
  cura: Object.freeze({ todos: ['curadorId', 'alvoId', 'tecnica'], propria: ['faces', 'expressao'] }),
  // Q8: a arma e o corpo DELA (os mesmos campos do ROOM_SNAPSHOT.propria) também seguem no `estado` da própria.
  estado: Object.freeze({ todos: ['figuraId', 'visivel'], propria: ['vidaActual', 'paLivre', 'estadoMorte', 'armaCaida', 'armaQuebrada', 'corpoPartido'] }),
  desgraca: Object.freeze({ todos: ['figuraId', 'efeito'], propria: ['perdeQuarto'] }), // só a desgraça APLICADA; REF_19
  teste_morte: Object.freeze({ todos: ['figuraId'], propria: [] }), // só que houve teste; a CD e a saída ficam no soMestre
  reacao: Object.freeze({ todos: ['figuraId', 'reacao'], propria: [] }),
  consumivel: Object.freeze({ todos: ['figuraId', 'itemId', 'alvoId'], propria: [] }),
  ambiente: Object.freeze({ todos: ['efeito'], propria: [] }), // E-P12: só o efeito presente
  revertido: Object.freeze({ todos: [], propria: [] }), // nada de journalSeq
  fim: Object.freeze({ todos: ['desfecho'], propria: [] }),
  // N4 (08/11): o Mestre recomeçou a batalha do zero; o snapshot vem a seguir.
  recomeco: Object.freeze({ todos: [], propria: [] }),
  // Ordem 8 (item 8): o Mestre mudou a escala. Sem campos: o resultado chega no snapshot (mapa.casaM) e nas opções.
  escala: Object.freeze({ todos: [], propria: [] }),
  // Ordem 13 (dívida E1; site «RAIO E FOGO», REF_39): o raio que cai, o fogo e o dano do ambiente vêem-se na mesa
  // (o site desenha-os a todos). O número do dano só a quem o sofreu; o combustível, os dados, o raio pendente e o
  // painel ficam no soMestre.
  raio: Object.freeze({ todos: ['x', 'y', 'alvoId', 'desfecho'], propria: [] }),
  dano_ambiente: Object.freeze({ todos: ['alvoId', 'origem', 'desfecho'], propria: ['valor', 'tipos'] }),
  fogo: Object.freeze({ todos: ['casas', 'aArder', 'apagados'], propria: [] }),
});

/** "Este evento é dela?" — decide se os campos `propria` entram. */
const EH_PROPRIO = Object.freeze({
  movimento: (d, f) => d.figuraId === f,
  ataque: (d, f) => d.atacanteId === f,
  cura: (d, f) => d.curadorId === f,
  dano: (d, f) => d.alvoId === f || d.autorId === f,
  estado: (d, f) => d.figuraId === f,
  desgraca: (d, f) => d.figuraId === f,
  dano_ambiente: (d, f) => d.alvoId === f,
});

// Climas que a Party pode ver como efeito. Texto livre do Mestre nunca sai.
export const CLIMAS_VISIVEIS = Object.freeze(['limpo', 'nublado', 'chuva', 'tempestade', 'nevoeiro', 'neve']);

/** Efeito presente do ambiente, visto pela Party (o painel é só do Mestre). */
export function efeitoAmbiente(ambiente) {
  const clima = CLIMAS_VISIVEIS.includes(ambiente?.clima) ? ambiente.clima : null;
  let luz = null;
  const m = /^(\d{1,2}):(\d{2})$/.exec(typeof ambiente?.hora === 'string' ? ambiente.hora : '');
  // Ordem 22 (V14): só uma hora do relógio (00:00..23:59) diz dia ou noite; "25:70" dava «noite».
  if (m && Number(m[1]) <= 23 && Number(m[2]) <= 59) {
    const h = Number(m[1]);
    luz = h >= 6 && h < 18 ? 'dia' : 'noite';
  }
  return { clima, luz };
}

/** Nome que a Party pode ver. O nome verdadeiro (`nome`) de criatura/NPC nunca sai. */
export function nomePublicoDe(ficha) {
  if (!ficha) return 'Figura';
  if (ficha.nomePublico) return ficha.nomePublico;
  if (ficha.papel === 'jogadora') return ficha.nome;
  return ficha.papel === 'npc' ? 'Personagem' : 'Criatura';
}

/** Estado visível de uma figura: de_pe, caida, morta ou transformada. */
export function visivelDe(fig) {
  if (!fig.vivo) return 'morta';
  if (fig.caido || fig.estadoMorte?.fase === 'aMorrer') return 'caida';
  if (fig.transformada) return 'transformada';
  return 'de_pe';
}

function escolher(origem, chaves) {
  const saida = {};
  for (const k of chaves) {
    if (origem && Object.prototype.hasOwnProperty.call(origem, k) && origem[k] !== undefined) {
      // Cópia profunda: nada partilha referência com o estado interno.
      saida[k] = clonarJson(origem[k]);
    }
  }
  return saida;
}

/**
 * Projeta um evento interno do journal para um destinatário.
 * @param {{journalSeq:number, tipo:string, dados:Object, soMestre:Object|null}} evento
 * @param {{papel:'mestre'|'jogadora'|'espectador', figuraId?:string|null}} dest
 * @returns {Object|null} os `dados` do ROOM_EVENT, ou null se este destinatário não o recebe.
 */
export function projetarEvento(evento, dest) {
  if (dest.papel === 'mestre') {
    // O Mestre vê tudo, incluindo o journalSeq interno (E-P4) e o soMestre.
    return { ...clonarJson(evento.dados ?? {}), soMestre: clonarJson(evento.soMestre ?? null), journalSeq: evento.journalSeq };
  }
  const regra = CAMPOS_PERMITIDOS[evento.tipo];
  if (!regra) return null; // tipo interno ou desconhecido: falha fechada
  const saida = escolher(evento.dados, regra.todos);
  if (dest.papel === 'jogadora' && dest.figuraId && regra.propria.length) {
    const eh = EH_PROPRIO[evento.tipo];
    if (eh && eh(evento.dados ?? {}, dest.figuraId)) Object.assign(saida, escolher(evento.dados, regra.propria));
  }
  return saida;
}

/** Figura vista pela Party: posição, orientação e estado visível. Mais nada. */
export function figuraPublica(fig, fichas) {
  return {
    id: fig.id,
    nomePublico: nomePublicoDe(fichas[fig.fichaId]),
    lado: fig.lado,
    x: fig.x,
    y: fig.y,
    orientacao: fig.orientacao,
    visivel: visivelDe(fig),
  };
}

/**
 * Figura vista pelo Mestre (só no bloco `mestre`): o estado interno inteiro + o que a ficha diz e o ecrã
 * precisa — nome verdadeiro, nome público, vida total e PA total (L1, JV3.1). Nunca vai à Party.
 */
export function figuraDoMestre(fig, fichas) {
  const ficha = fichas[fig.fichaId];
  return {
    ...clonarJson(fig),
    nome: ficha?.nome ?? null,
    nomePublico: nomePublicoDe(ficha),
    vidaTotal: ficha?.vidaTotal ?? null,
    paTotal: ficha?.paTotal ?? null,
    // Plano B: o desenho da figura na arena do Mestre (marcador do site; sem ficha visual, o cliente usa o padrão).
    alturaM: Number.isFinite(ficha?.visual?.alturaM) ? ficha.visual.alturaM : null,
    marcador: ficha?.visual?.marcador ?? null,
    // Ordem 13 (parte C; site FRASES_IA): os verbos do golpe de cada monstro, da ficha. null = o cliente diz «acerta».
    verbos: ficha?.verbos ? clonarJson(ficha.verbos) : null,
  };
}

/**
 * Snapshot projetado (sem seq/revision; o núcleo junta-os ao enviar).
 * @param {Object} mundo estado da sala
 * @param {Object} fichas mapa id → ficha congelada
 * @param {{papel:string, figuraId?:string|null}} dest
 */
export function projetarSnapshot(mundo, fichas, dest) {
  const colocadas = Object.values(mundo.figuras).filter((f) => f.colocada);
  const base = {
    fase: mundo.fase,
    mapa: { largura: mundo.mapa.largura, altura: mundo.mapa.altura, casaM: mundo.mapa.casaM },
    figuras: colocadas.map((f) => figuraPublica(f, fichas)),
    // E-P (linhas novas do §6): a Party vê só a ORDEM, nunca os valores de iniciativa.
    iniciativa: mundo.ordem.filter((id) => mundo.figuras[id]?.colocada),
    vezId: mundo.vez?.figuraId ?? null,
    rodada: mundo.rodada,
    ambiente: efeitoAmbiente(mundo.ambiente),
    // Ordem 13: as casas a arder e quem arde (sem combustível). A Party vê o fogo, como no site.
    fogo: fogoPublico(mundo),
  };

  if (dest.papel === 'mestre') {
    base.mestre = {
      // Inclui as não colocadas, fichaId e modo. L1 do desenho JV3.1 (revisão do Muse, 08/11): o ecrã do
      // Mestre precisa dos totais e dos nomes para mostrar «12/20» e quem é quem — vêm da ficha, só aqui.
      figuras: Object.values(mundo.figuras).map((f) => figuraDoMestre(f, fichas)),
      lobby: clonarJson(mundo.lobby),
      vez: clonarJson(mundo.vez),
      ambiente: clonarJson(mundo.ambiente),
      // Ordem 13: o fogo com o combustível de cada casa (só o Mestre).
      fogo: fogoDoMestre(mundo),
      // Ordem 8 (item 5): a `saidaProposta` (a saída do motor guardada para o «Não acontece nada») é trabalho interno do
      // servidor: não vai na vista (o Mestre já tem a proposta, a lista e a rolagem no cartão).
      cartoes: mundo.cartoes.filter((c) => c.estado === 'aberto').map(({ saidaProposta, ...c }) => clonarJson(c)),
      pausa: clonarJson(mundo.pausa),
      // L6: a rodada em que o Mestre deu «Continuar a rodada» às marchas puras (null: nenhuma).
      marchaLivreRodada: mundo.marchaLivre ?? null,
    };
    return base;
  }

  if (dest.papel === 'jogadora' && dest.figuraId) {
    const f = mundo.figuras[dest.figuraId];
    const ficha = f ? fichas[f.fichaId] : null;
    if (f && ficha) {
      // Vida, PA e ficha DA PRÓPRIA: ✔ só para ela.
      base.propria = {
        figuraId: f.id,
        vidaActual: f.vidaActual,
        vidaTotal: ficha.vidaTotal,
        paLivre: ficha.paTotal - f.paGasto,
        paTotal: ficha.paTotal,
        estadoMorte: clonarJson(f.estadoMorte),
        armaCaida: f.armaCaida,
        armaQuebrada: f.armaQuebrada,
        corpoPartido: f.corpoPartido,
        ficha: clonarJson(ficha),
      };
    }
  }
  return base;
}
