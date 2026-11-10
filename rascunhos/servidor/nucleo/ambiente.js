// Raio e fogo do ambiente (ordem 13 do CM-000009, dívida E1 da auditoria da ordem 10).
// REGRA: sem node:*. Sem relógio nem acaso próprios: os dados entram injetados (`dado(faces)` → 1..faces).
//
// AS REGRAS (palavra do Mestre; as mesmas do painel Ambiente do site, jogo.js «RAIO E FOGO», REF_39):
//  (1) onde o raio cai, a casa pega fogo;
//  (2) o raio é aleatório (a casa sorteia-se no tabuleiro inteiro);
//  (3) raio numa pessoa: a pessoa pega fogo e sofre dano;
//  (4) dano do raio = 15, fixo, PROVISÓRIO («por enquanto pode ser um dano fixo de 15; depois eu resolvo»);
//  (5) dano do fogo = 1d8 enquanto a pessoa estiver na casa a arder; sair para a chuva apaga o fogo da pessoa;
//      sem chuva, sair não apaga;
//  (6) a RD fica FORA do dano do ambiente (palavra do Mestre, 2026-11-09 14:04): a parcela cobra-se inteira.
//
// O RELÓGIO (o do site, que é a leitura aprovada das regras acima):
//  - «momento de ambiente» no início de cada rodada a partir da 2.ª, antes da primeira vez: (a) cada casa que já
//    ardia rola a extinção pela chuva desse instante (pouca: 1–2 em 1d6; forte: 1–5) — apagada, apaga também a
//    pessoa que lá está a arder; senão (b) gasta 1 de combustível e, a 0, apaga-se (a pessoa continua a arder);
//    (c) os raios da rodada: primeiro o pedido pelo Mestre («Raio agora»), depois o automático (pouca: 1 em 1d6;
//    forte: 1–2). Sem chuva ou com os raios desligados não cai raio nenhum (e o pedido cancela-se);
//  - impacto: a casa acende com combustível 1d6 (re-impacto renova) e acende a CRUZ — as 4 vizinhas directas
//    (palavra do Mestre 09/11 14:16; a vizinha que já ardia conserva o combustível; a cruz corta-se na borda). Só
//    quem está na casa do impacto leva os 15 e fica a arder;
//  - tick: no início da vez da figura, UM por figura e por rodada, se ela está a arder ou começa a vez numa casa a
//    arder (e aí pega fogo). Na rodada do impacto, o tick soma-se ao raio (leitura literal das duas frases);
//  - quem está a arder FORA de uma casa a arder, com chuva, apaga-se no início da vez (antes do tick) ou ao acabar
//    um movimento fora do fogo; sem chuva continua a arder;
//  - só se fere quem está vivo e de pé no relógio da morte: a heroína já a morrer ou estabilizada não leva dano
//    do ambiente (não ganha falhas: o ambiente não é ataque). A Vida a 0 deita-a a morrer com 0/0; o monstro a 0
//    morre (sai do fogo).
//
// QUEM VÊ O QUÊ (o servidor projeta, ver projecao.js): a Party vê as casas a arder e quem arde (o site desenha-os
// a todos), onde o raio caiu e quem atingiu; o número do dano só quem o sofreu. O combustível, os dados, o raio
// pendente e o painel (hora, clima, raios) ficam só no Mestre.

/** PROVISÓRIO, palavra do Mestre: o dano do raio é fixo. */
export const DANO_RAIO = 15;
/** Faces do dado do fogo (1d8 por tick). */
export const FACES_FOGO = 8;
/** Faces do combustível de uma casa acesa (1d6 rodadas). */
export const FACES_COMBUSTIVEL = 6;
export const TIPO_RAIO = 'eletrico';
export const TIPO_FOGO = 'fogo';
/** Extinção pela chuva no momento de ambiente: apaga com 1d6 ≤ isto (índice = nível da chuva). */
const EXTINCAO = Object.freeze([0, 2, 5]);
/** Raio automático no momento de ambiente: cai com 1d6 ≤ isto (índice = nível da chuva). */
const RAIO_AUTO = Object.freeze([0, 1, 2]);
const VIZ4 = Object.freeze([[0, -1], [0, 1], [-1, 0], [1, 0]]);

/**
 * Nível da chuva a partir do clima do painel do JV: 'chuva' = pouca (1), 'tempestade' = forte (2); o resto, 0.
 * (O site tem três botões — sem chuva / pouca / forte; o JV já tinha os climas, e estes são os dois com chuva.)
 */
export function chuvaDe(ambiente) {
  const c = ambiente?.clima;
  return c === 'tempestade' ? 2 : c === 'chuva' ? 1 : 0;
}

/** Podem cair raios agora? (raios ligados pelo Mestre e chuva a cair). */
export function haTempestade(ambiente) {
  return ambiente?.raios === true && chuvaDe(ambiente) > 0;
}

export function fogoVazio() {
  return { casas: [], aArder: [], ultimoTick: {}, rodadaResolvida: 1 };
}

/** O estado do fogo da sala (cria-o se faltar: salas e pontos de «voltar» de antes desta ordem não o têm). */
export function fogoDe(m) {
  if (!fogoValido(m.fogo)) m.fogo = fogoVazio();
  return m.fogo;
}
function fogoValido(fogo) {
  return !!fogo && typeof fogo === 'object' && Array.isArray(fogo.casas) && Array.isArray(fogo.aArder);
}
/** Só leitura (a projeção não muda o estado): o fogo da sala, ou um vazio. */
function lerFogo(m) {
  return fogoValido(m?.fogo) ? m.fogo : fogoVazio();
}

function casaDoFogo(fogo, x, y) {
  return fogo.casas.find((c) => c.x === x && c.y === y) ?? null;
}
export function arde(m, x, y) {
  return !!casaDoFogo(lerFogo(m), x, y);
}
export function estaAArder(m, id) {
  return lerFogo(m).aArder.includes(id);
}
function incendiar(fogo, id) {
  if (!fogo.aArder.includes(id)) fogo.aArder.push(id);
}
function apagarPessoa(fogo, id) {
  const i = fogo.aArder.indexOf(id);
  if (i < 0) return false;
  fogo.aArder.splice(i, 1);
  return true;
}

/** O que a Party vê do fogo: casas (sem combustível) e quem arde (só figuras vivas e colocadas). */
export function fogoPublico(m) {
  const fogo = lerFogo(m);
  const casas = fogo.casas.map((c) => ({ x: c.x, y: c.y })).sort((a, b) => a.y - b.y || a.x - b.x);
  const aArder = fogo.aArder.filter((id) => m.figuras[id]?.colocada && m.figuras[id]?.vivo).slice().sort();
  return { casas, aArder };
}

/** O que só o Mestre vê do fogo: o público + o combustível de cada casa. */
export function fogoDoMestre(m) {
  const fogo = lerFogo(m);
  const pub = fogoPublico(m);
  return {
    ...pub,
    casas: pub.casas.map(({ x, y }) => ({ x, y, combustivel: casaDoFogo(fogo, x, y).combustivel })),
  };
}

/** A figura que está nesta casa e o fogo pode ferir: colocada e viva. */
function ocupanteVivo(m, x, y) {
  return Object.values(m.figuras).find((f) => f.colocada && f.vivo && f.x === x && f.y === y) ?? null;
}

/** Pode o ambiente ferir esta figura? Viva, e (heroína) fora do relógio da morte. */
export function ferivel(f) {
  if (!f || !f.colocada || !f.vivo) return false;
  if (f.lado === 'jogadora' && f.estadoMorte) return false;
  return true;
}

/**
 * Dano do ambiente numa figura (regra 6: SEM RD; sem rolagem de ataque, sem Defesa, sem reacção).
 * Muda a figura e devolve {aplicado, desfecho: 'caiu'|'aMorrer'|null}, ou null se não é ferível.
 */
export function ferir(f, valor) {
  if (!ferivel(f)) return null;
  const aplicado = Math.max(0, Math.trunc(valor));
  f.vidaActual = Math.max(0, f.vidaActual - aplicado);
  if (f.vidaActual > 0) return { aplicado, desfecho: null };
  if (f.lado === 'jogadora') {
    // Como o site (rfAplicarDanoAmbiente): a morrer com 0/0 — o ambiente não soma falhas.
    f.estadoMorte = { fase: 'aMorrer', sucessos: 0, falhas: 0 };
    return { aplicado, desfecho: 'aMorrer' };
  }
  f.vivo = false;
  return { aplicado, desfecho: 'caiu' };
}

function acender(m, fogo, x, y, dado, renovar) {
  const c = casaDoFogo(fogo, x, y);
  if (c) {
    if (renovar) c.combustivel = dado(FACES_COMBUSTIVEL);
    return c;
  }
  const nova = { x, y, combustivel: dado(FACES_COMBUSTIVEL) };
  fogo.casas.push(nova);
  return nova;
}

/**
 * O impacto de um raio na casa (x, y). Devolve o registo:
 * {tipo:'raio', x, y, origem, combustivel, cruz:[{x,y,combustivel}], alvoId?, aplicado?, desfecho?, visAntes?, vidaAntes?}
 * `antes(f)` devolve {vis, vida} da figura antes do dano (o núcleo precisa disso para o `estado`).
 */
export function impactoRaio(m, x, y, origem, dado, antes) {
  const fogo = fogoDe(m);
  const casa = acender(m, fogo, x, y, dado, true);
  const cruz = [];
  for (const [dx, dy] of VIZ4) {
    const cx = x + dx;
    const cy = y + dy;
    if (cx < 0 || cy < 0 || cx >= m.mapa.largura || cy >= m.mapa.altura) continue;
    if (casaDoFogo(fogo, cx, cy)) continue; // a vizinha que já ardia conserva o combustível
    const c = acender(m, fogo, cx, cy, dado, false);
    cruz.push({ x: cx, y: cy, combustivel: c.combustivel });
  }
  const reg = { tipo: 'raio', x, y, origem, combustivel: casa.combustivel, cruz };
  const f = ocupanteVivo(m, x, y);
  if (!f || !ferivel(f)) return reg;
  const a = antes(f);
  const r = ferir(f, DANO_RAIO);
  Object.assign(reg, { alvoId: f.id, aplicado: r.aplicado, desfecho: r.desfecho, visAntes: a.vis, vidaAntes: a.vida });
  if (r.desfecho === 'caiu') apagarPessoa(fogo, f.id); // a morte apaga o fogo da figura
  else incendiar(fogo, f.id);
  return reg;
}

/** Sorteia a casa do raio no tabuleiro inteiro (regra 2) e resolve o impacto. */
export function raioAoAcaso(m, origem, dado, antes) {
  const n = m.mapa.largura * m.mapa.altura;
  const i = dado(n) - 1;
  return impactoRaio(m, i % m.mapa.largura, Math.floor(i / m.mapa.largura), origem, dado, antes);
}

/**
 * O momento de ambiente da rodada `m.rodada` (corre uma vez por rodada, da 2.ª em diante). Devolve a lista dos
 * registos, pela ordem em que aconteceram: {tipo:'extincao', x, y, porque:'chuva'|'combustivel', apagouId?} e os
 * {tipo:'raio', ...} de impactoRaio, mais {tipo:'raio_cancelado'} quando o pedido do Mestre caiu sem tempestade.
 */
export function momentoDaRodada(m, dado, antes) {
  const fogo = fogoDe(m);
  const regs = [];
  if (m.rodada <= fogo.rodadaResolvida) return regs;
  fogo.rodadaResolvida = m.rodada;
  const chuva = chuvaDe(m.ambiente);
  for (const c of fogo.casas.slice()) {
    if (chuva > 0 && dado(6) <= EXTINCAO[chuva]) {
      fogo.casas.splice(fogo.casas.indexOf(c), 1);
      const reg = { tipo: 'extincao', x: c.x, y: c.y, porque: 'chuva' };
      const oc = ocupanteVivo(m, c.x, c.y);
      if (oc && apagarPessoa(fogo, oc.id)) reg.apagouId = oc.id;
      regs.push(reg);
      continue;
    }
    c.combustivel -= 1;
    if (c.combustivel <= 0) {
      fogo.casas.splice(fogo.casas.indexOf(c), 1);
      regs.push({ tipo: 'extincao', x: c.x, y: c.y, porque: 'combustivel' });
    }
  }
  const pedido = m.ambiente?.raioPendente === true;
  if (pedido) m.ambiente.raioPendente = false;
  if (haTempestade(m.ambiente)) {
    if (pedido) regs.push(raioAoAcaso(m, 'pedido', dado, antes));
    if (batalhaAcabou(m)) return regs; // como o site: o raio pedido acabou a batalha, não cai mais nenhum
    if (dado(6) <= RAIO_AUTO[chuva]) regs.push(raioAoAcaso(m, 'automatico', dado, antes));
  } else if (pedido) {
    regs.push({ tipo: 'raio_cancelado' });
  }
  return regs;
}

/**
 * O tick do fogo no início da vez da figura. Devolve null (nada) ou um registo:
 * {tipo:'apagado', figuraId, porque:'chuva'} — a chuva apagou-a, fora do fogo, antes do tick;
 * {tipo:'tick', alvoId, faces:[n], aplicado, desfecho, pegouFogo, visAntes, vidaAntes}.
 */
export function tickInicioDaVez(m, f, dado, antes) {
  if (!ferivel(f)) return null;
  const fogo = fogoDe(m);
  const naCasa = !!casaDoFogo(fogo, f.x, f.y);
  const aArder = fogo.aArder.includes(f.id);
  if (aArder && !naCasa && chuvaDe(m.ambiente) > 0) {
    apagarPessoa(fogo, f.id);
    return { tipo: 'apagado', figuraId: f.id, porque: 'chuva' };
  }
  if (!aArder && !naCasa) return null;
  if (fogo.ultimoTick[f.id] === m.rodada) return null;
  fogo.ultimoTick[f.id] = m.rodada;
  const pegouFogo = !aArder;
  incendiar(fogo, f.id);
  const a = antes(f);
  const face = dado(FACES_FOGO);
  const r = ferir(f, face);
  if (r.desfecho === 'caiu') apagarPessoa(fogo, f.id);
  return { tipo: 'tick', alvoId: f.id, faces: [face], aplicado: r.aplicado, desfecho: r.desfecho, pegouFogo, visAntes: a.vis, vidaAntes: a.vida };
}

/**
 * Ordem 15 do CM-000009 (palavra do Mestre, 2026-11-10): apagar-se SEM chuva, como no site (jogo-t1/jogo.js
 * rfPodeApagarFogo, RF_FIM_SECO = 'acao-movimento'): quem está a arder FORA de uma casa a arder, sem chuva nenhuma,
 * pode gastar a Acção de Movimento da vez a apagar-se. As outras condições (é a vez dela, é jogadora, não está a
 * morrer) confere-as a sala. Com chuva, apagar-se continua automático (tickInicioDaVez e depoisDoMovimento).
 */
export function podeApagarSeco(m, f) {
  const fogo = lerFogo(m);
  if (!f || !fogo.aArder.includes(f.id)) return false;
  if (chuvaDe(m.ambiente) !== 0) return false;
  return !casaDoFogo(fogo, f.x, f.y);
}
/** Apaga-a (fim seco). Devolve {tipo:'apagado', figuraId, porque:'seco'} ou null se não pode. */
export function apagarSeco(m, f) {
  if (!podeApagarSeco(m, f)) return null;
  apagarPessoa(fogoDe(m), f.id);
  return { tipo: 'apagado', figuraId: f.id, porque: 'seco' };
}

/**
 * Acabou um movimento (regra 5): a arder, fora de qualquer casa a arder e com chuva → apaga-se. Sem chuva continua.
 * Devolve {tipo:'apagado', figuraId, porque:'saiu'} ou null.
 */
export function depoisDoMovimento(m, f) {
  const fogo = fogoDe(m);
  if (!fogo.aArder.includes(f.id) || casaDoFogo(fogo, f.x, f.y)) return null;
  if (chuvaDe(m.ambiente) === 0) return null;
  apagarPessoa(fogo, f.id);
  return { tipo: 'apagado', figuraId: f.id, porque: 'saiu' };
}

/** Todas as heroínas mortas ou todas as criaturas mortas (a mesma conta do verificarFim da sala). */
export function batalhaAcabou(m) {
  const todas = Object.values(m.figuras).filter((f) => f.colocada);
  const jog = todas.filter((f) => f.lado === 'jogadora');
  const mon = todas.filter((f) => f.lado !== 'jogadora');
  return (jog.length > 0 && jog.every((f) => !f.vivo)) || (mon.length > 0 && mon.every((f) => !f.vivo));
}

/** A figura morreu por outra via (ataque): sai do fogo. */
export function aoMorrer(m, id) {
  const fogo = fogoDe(m);
  apagarPessoa(fogo, id);
  delete fogo.ultimoTick[id];
}
