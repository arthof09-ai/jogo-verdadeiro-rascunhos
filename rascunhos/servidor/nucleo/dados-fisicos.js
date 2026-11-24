// Dados físicos (JV1.3, M-28; ORDEM-F4-PARCIAL): o intervalo de cada face validado contra a expressão da técnica.
//
// REGRA: sem node:*, sem relógio, sem acaso. Função pura: não decide nenhuma regra de jogo, só diz se as faces que a
// jogadora declarou PODEM ter saído dos dados da técnica, pela mesma ordem em que o motor oficial as consome
// (vlab-completo.js, resolverAtaque, «D10. Determinismo: contexto.faces consumidas por ordem (conjuntos do ataque
// primeiro, dano a seguir)»):
//   1. os conjuntos do ataque: cada conjunto tem TODOS os dados da expressão de ataque, e há 1 + |V − D| conjuntos,
//      com a V/D líquida entre −4 e +4 (1 a 5 conjuntos). Quantos conjuntos há é o motor que sabe (lê estados que o
//      servidor não recalcula); por isso aceita-se a lista se ALGUM número de conjuntos de 1 a 5 a explicar;
//   2. depois, ou os dados do dano (os componentes da técnica; sem eles, a `reparticao`; sem ela, a `expressaoDano`),
//      ou — na falha crítica — o d100 da desgraça seguido dos dados do mesmo dano (dano derivado, rolarDerivado).
// As faces podem parar a meio do dano (o motor diz-o depois, ao resolver: FACES_INSUFICIENTES); o que NUNCA passa é
// uma face fora do intervalo do dado em que cai, nem uma lista mais comprida do que os dados da técnica.
// A gramática é a do motor (analisarExpressao / analisarExpressaoAtaque): NdM(+NdM)* com um bónus inteiro opcional,
// ou o objecto decomposto {qtd, faces, bonus}.

export const MAX_CONJUNTOS_ATAQUE = 5; // 1 + |liquido|, liquido em [−4, 4] (vlab-completo.js, «D3»)
export const FACES_DESGRACA = 100; // o 1d100 da tabela das desgraças (vlab-completo.js, «FALHA CRÍTICA → DESGRAÇA»)

/** Os dados de uma expressão, por ordem (um número de faces por dado), ou null se a expressão sai da gramática. */
export function dadosDaExpressao(expr) {
  if (expr && typeof expr === 'object' && !Array.isArray(expr)) {
    const { qtd, faces } = expr;
    if (!Number.isInteger(qtd) || !Number.isInteger(faces) || qtd < 1 || faces < 2) return null;
    return Array(qtd).fill(faces);
  }
  if (typeof expr !== 'string') return null;
  const m = expr.replace(/\s+/g, '').match(/^(\d+d\d+(?:\+\d+d\d+)*)([+-]\d+)?$/i);
  if (!m) return null;
  const dados = [];
  for (const termo of m[1].split('+')) {
    const [q, f] = termo.toLowerCase().split('d').map(Number);
    if (!(q >= 1 && f >= 2)) return null;
    // Teto de segurança: o formato do ROOM_INTENT já limita a lista a 10 faces; não há porque expandir mais.
    for (let i = 0; i < q && dados.length <= 64; i += 1) dados.push(f);
  }
  return dados;
}

/** Os dados do dano da técnica, pela escolha do DMG (calcularDano: componentes → reparticao → expressaoDano). */
function dadosDoDano(t) {
  let expressoes = null;
  if (Array.isArray(t.componentes) && t.componentes.length) expressoes = t.componentes.map((c) => c?.expressao);
  else if (t.expressaoDano != null) {
    const tipos = Array.isArray(t.tipos) && t.tipos.length ? t.tipos : [null];
    expressoes = tipos.length > 1 ? (Array.isArray(t.reparticao) ? t.reparticao : null) : [t.expressaoDano];
  }
  if (!expressoes) return [];
  const dados = [];
  for (const e of expressoes) {
    const d = dadosDaExpressao(e);
    if (!d) return null;
    dados.push(...d);
  }
  return dados;
}

/**
 * Confere as faces físicas de um ataque contra a técnica.
 * @param {number[]} faces  as faces que a jogadora declarou (já com a forma do ROOM_INTENT: inteiros, 1 a 10)
 * @param {Object} tecnica  a técnica efectiva (a mesma que vai ao motor)
 * @param {Object} [ficha]  a ficha efectiva de quem ataca (só para `testes.ataque`, quando a técnica não traz a sua)
 * @returns {null|string}  null se as faces cabem; senão o porquê (só para o Mestre)
 */
export function conferirFacesFisicas(faces, tecnica, ficha = null) {
  if (!Array.isArray(faces) || faces.length === 0) return 'sem faces';
  const exprAtaque = tecnica?.expressaoAtaque || ficha?.testes?.ataque;
  const ataque = dadosDaExpressao(exprAtaque);
  if (!ataque || ataque.length === 0) return 'a técnica não tem expressão de ataque na gramática dos dados';
  const dano = dadosDoDano(tecnica);
  if (dano === null) return 'a expressão de dano da técnica sai da gramática dos dados';

  let melhor = null; // o primeiro desvio da leitura mais próxima, para o detalhe
  for (let n = 1; n <= MAX_CONJUNTOS_ATAQUE; n += 1) {
    const conjuntos = [];
    for (let i = 0; i < n; i += 1) conjuntos.push(...ataque);
    if (faces.length < conjuntos.length) break; // menos faces do que conjuntos completos: n maiores também não servem
    for (const cauda of [dano, [FACES_DESGRACA, ...dano]]) {
      const seq = conjuntos.concat(cauda);
      if (faces.length > seq.length) continue;
      const i = faces.findIndex((x, k) => !Number.isInteger(x) || x < 1 || x > seq[k]);
      if (i < 0) return null;
      if (!melhor || i > melhor.i) melhor = { i, face: faces[i], lados: seq[i] };
    }
  }
  if (melhor) return `face ${melhor.face} fora do intervalo 1..${melhor.lados} (posição ${melhor.i + 1}) para ${exprAtaque}`;
  if (faces.length < ataque.length) return `faltam faces: ${exprAtaque} rola ${ataque.length} dado(s) por conjunto`;
  return `faces a mais: ${faces.length} não cabem nos dados de ${exprAtaque} e do dano`;
}
