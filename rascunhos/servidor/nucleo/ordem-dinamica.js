// Ordem INICIATIVA NO SERVIDOR (19/11/2026): a ORDEM DINÂMICA da caixa do Mestre passa a viver no servidor.
//
// Antes (Ordem HUD) a ordem dinâmica formava-se só no cliente do Mestre (`cliente/hud/ordem_turnos.gd`): se ele saísse
// e voltasse a entrar a meio da batalha, a caixa recomeçava vazia. Agora o servidor guarda-a no estado da sala
// (`ordemDinamica`, no journal e nos pontos do «voltar») e manda-a na MASTER_VIEW; o cliente só a lê.
//
// As regras são as MESMAS da caixa (desenho = palavra do Mestre, 16/11/2026 11:18), passadas para aqui sem mudar nada:
//  - conta como «agiu» o que o servidor narra como acção de alguém: `movimento` (figuraId), `ataque` que NÃO é de
//    oportunidade (atacanteId), `cura` (curadorId), `consumivel` (figuraId) e `acao` das acções da vez (correr,
//    apanhar a arma, apagar o fogo, defender, desvincular — nunca `sem_desgraca`, que é decisão do Mestre);
//  - várias acções seguidas da mesma figura são uma só vez;
//  - quem age pela primeira vez ENTRA no fim da ordem; quando uma figura que já está na ordem volta a agir, a volta
//    FECHA e a ordem passa a repetir-se;
//  - fechada, quem age fora da sequência (o Mestre ditou outra coisa — um ATRASO ou um adiantamento) passa a ficar logo
//    a seguir a quem agiu antes dela;
//  - «Recomeçar» limpa a ordem; o «voltar» repõe a ordem do ponto a que se volta (vem no checkpoint, com o mundo);
//  - quem SAI da batalha (figura que deixou de estar colocada) não aparece na ordem que se manda (`ordemParaVista`).
//
// Só ids, um booleano e um contador. NENHUM valor de vida ou de alma — regra da casa (a ordem é só de quem e quando).
// Nenhuma regra de jogo, nenhum dado, nenhuma fórmula: não decide quem vai, só regista quem foi.

/** Os `acao` (sala.js) que são a figura a agir na vez dela. */
export const ACOES_DA_VEZ = Object.freeze(['correr', 'apanhar_arma', 'apagar_fogo', 'defender', 'desvincular']);

/** A ordem dinâmica vazia (início de batalha, «Recomeçar», salas de antes desta ordem). */
export function ordemDinamicaVazia() {
  return { ordem: [], fechada: false, ultimo: null, vezes: 0 };
}

const idOuVazio = (v) => (typeof v === 'string' && v.length > 0 ? v : '');

/** O id de quem agiu neste evento ({tipo, dados}), ou '' se o evento não é uma acção de alguém. */
export function actorDoEvento(ev) {
  const d = ev?.dados;
  if (d === null || typeof d !== 'object') return '';
  switch (ev.tipo) {
    case 'movimento':
    case 'consumivel':
      return idOuVazio(d.figuraId);
    case 'ataque':
      return d.ataqueDeOportunidade === true ? '' : idOuVazio(d.atacanteId); // a reacção de oportunidade não é «ir»
    case 'cura':
      return idOuVazio(d.curadorId);
    case 'acao':
      return ACOES_DA_VEZ.includes(d.tipo) ? idOuVazio(d.figuraId) : '';
    default:
      return '';
  }
}

function seguinteDe(od, id) {
  const i = od.ordem.indexOf(id);
  if (i < 0 || od.ordem.length === 0) return '';
  return od.ordem[(i + 1) % od.ordem.length];
}

/** Põe `id` logo a seguir a `anterior` na ordem (se `anterior` lá estiver); senão, no fim. */
function colocarDepois(od, id, anterior) {
  if (od.ordem.indexOf(anterior) < 0) {
    if (!od.ordem.includes(id)) od.ordem.push(id);
    return;
  }
  if (seguinteDe(od, anterior) === id) return;
  const i = od.ordem.indexOf(id);
  if (i >= 0) od.ordem.splice(i, 1);
  od.ordem.splice(od.ordem.indexOf(anterior) + 1, 0, id);
}

/** Uma figura agiu (muda `od`). Devolve true se a vez passou (ou a ordem mudou). */
export function registarAcao(od, id) {
  if (!id || id === od.ultimo) return false; // mais uma acção da mesma vez
  const anterior = od.ultimo ?? '';
  od.ultimo = id;
  od.vezes += 1;
  const i = od.ordem.indexOf(id);
  if (!od.fechada) {
    if (i < 0) od.ordem.push(id);
    else {
      od.fechada = true; // voltou a agir quem já estava: a ordem repete-se
      colocarDepois(od, id, anterior);
    }
    return true;
  }
  // Fechada: quem age a seguir ao esperado não muda nada; fora da sequência, passa para depois de quem agiu antes.
  if (i >= 0 && anterior !== '' && seguinteDe(od, anterior) === id) return true;
  colocarDepois(od, id, anterior);
  return true;
}

/**
 * Lê um evento do journal ({tipo, dados}) e muda `od`. `recomeco` limpa (a sequência de antes deixou de ser a que
 * aconteceu); `revertido` não mexe: o «voltar» já repôs a ordem do ponto com o resto do mundo.
 */
export function registarEvento(od, ev) {
  if (ev?.tipo === 'recomeco') {
    Object.assign(od, ordemDinamicaVazia());
    return true;
  }
  const id = actorDoEvento(ev);
  return id ? registarAcao(od, id) : false;
}

/**
 * O que vai na MASTER_VIEW: a ordem só com as figuras que estão na batalha (colocadas), sem repetidos, e quem agiu por
 * último (a figura «na vez» no modo dinâmico). Só ids e um booleano.
 */
export function ordemParaVista(od, figuras) {
  const o = od && typeof od === 'object' ? od : ordemDinamicaVazia();
  const naBatalha = (id) => typeof id === 'string' && figuras?.[id]?.colocada === true;
  const ordem = [];
  for (const id of Array.isArray(o.ordem) ? o.ordem : []) if (naBatalha(id) && !ordem.includes(id)) ordem.push(id);
  return { ordem, fechada: o.fechada === true, ultimo: naBatalha(o.ultimo) ? o.ultimo : null };
}

// ---------------------------------------------------------------------------------------------------------------------
// Ordem CAIXA-PERSISTENTE (19/11/2026): a ESCOLHA DA CAIXA do Mestre passa a viver no servidor, ao lado da ordem dinâmica.
//
// Antes (Ordem HUD, pendência 2) o «ligar/desligar a caixa» (aba Sala) e o «Modo iniciativa» (botão da caixa) viviam só
// no cliente do Mestre: se ele saísse e voltasse a entrar a meio da batalha, a caixa voltava ligada e no modo dinâmico,
// fosse qual fosse a escolha dele. Agora o servidor guarda-a no estado da sala (`caixaMestre`, no journal) e manda-a na
// MASTER_VIEW; o cliente reconstrói a caixa com ela. A figura MOSTRADA na caixa (quem está na vez) já era do servidor:
// `ordemDinamica.ultimo` no modo dinâmico e `vezId` no modo iniciativa — a escolha decide qual das duas se mostra.
//
// É uma preferência de apresentação do Mestre, não um facto do mundo: NÃO entra nos pontos do «voltar» (voltar atrás na
// batalha não religa uma caixa que o Mestre desligou depois), nem se apaga no «Recomeçar» ou numa batalha nova. Só um
// booleano e um modo — nenhum valor de vida ou de alma. Só o Mestre a vê e só ele a muda (MASTER_SUPERVISOR op 'caixa').

/** Os modos da caixa (os mesmos de `cliente/hud/ordem_turnos.gd`: DINAMICO e INICIATIVA). */
export const MODOS_CAIXA = Object.freeze(['dinamico', 'iniciativa']);

/** A escolha por omissão — a de sempre no cliente (Ordem HUD): caixa ligada, modo dinâmico. */
export function caixaMestrePadrao() {
  return { ligada: true, modo: 'dinamico' };
}

/** A escolha que vem no MASTER_SUPERVISOR op 'caixa': exactamente {ligada: booleano, modo: um dos MODOS_CAIXA}. */
export function caixaBemFormada(c) {
  return !!c && typeof c === 'object' && !Array.isArray(c)
    && Object.keys(c).length === 2 && typeof c.ligada === 'boolean' && MODOS_CAIXA.includes(c.modo);
}

/** O que vai na MASTER_VIEW: a escolha guardada ou, nas salas de antes desta ordem, a de omissão. */
export function caixaParaVista(c) {
  return caixaBemFormada(c) ? { ligada: c.ligada, modo: c.modo } : caixaMestrePadrao();
}

// ---------------------------------------------------------------------------------------------------------------------
// Ordem CAIXA-HUD-JOGADORA (20/11/2026): a CAIXA NO HUD DA JOGADORA. A escolha do Mestre (ligada, modo) chega à Party no
// ROOM_SNAPSHOT (`caixa`), com a ordem dinâmica QUE A PARTY PODE SABER.
//
// PRIVACIDADE: a ordem dinâmica do Mestre conta também os `acao` (correr, defender, apanhar a arma…), que não saem para
// a Party (projecao.js CAMPOS_PERMITIDOS não tem `acao`). Por isso a Party tem a SUA ordem dinâmica
// (`estado.ordemDinamicaParty`), formada com as mesmas regras de cima mas só pelos eventos TAL COMO A PARTY OS RECEBE
// (a projecção do evento para um espectador): nada nela se deriva de um dado que a jogadora não vê. A jogadora que
// adianta a caixa pelos eventos que recebe chega à mesma ordem; o snapshot dá-lha ao entrar ou voltar a entrar.
// Só ids, um booleano e um modo — nunca vida, alma, valores de iniciativa, nem nada técnico.

/**
 * A caixa que vai no ROOM_SNAPSHOT da Party: a escolha do Mestre e a ordem dinâmica da Party (só figuras colocadas).
 * `ordemPor` é o modo da caixa ('dinamico' | 'iniciativa'). Não se chama `modo`: essa chave é PROIBIDA à Party (é o
 * modo H10 das figuras, E-P11 — a sonda de canários dos testes falha com ela). No modo iniciativa a jogadora usa a
 * `iniciativa` e o `vezId` do próprio snapshot (já eram públicos).
 */
export function caixaParaParty(caixaMestre, odParty, figuras) {
  const c = caixaParaVista(caixaMestre);
  return { ligada: c.ligada, ordemPor: c.modo, ordemDinamica: ordemParaVista(odParty, figuras) };
}
