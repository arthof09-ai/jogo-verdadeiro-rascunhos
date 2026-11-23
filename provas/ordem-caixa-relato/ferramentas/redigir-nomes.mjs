// Ordem F51 da sentença da F25 (§7.5): aplica a uma saída crua nova (p. ex. a do canário `teste_nomes_relato.gd`) a
// MESMA redacção do §2 da F25, para a poder comparar byte a byte com os registos limpos (os 11 da F25).
//   node provas/ordem-caixa-relato/ferramentas/redigir-nomes.mjs <saida-crua.log> [--fichas=<fichas.json>]
//        [--saida=<redigido.log>] [--comparar=<registo.log>] [--ignorar-cr]
//   node provas/ordem-caixa-relato/ferramentas/redigir-nomes.mjs --auto-teste [--fichas=<fichas.json>]
// Nomes verdadeiros: os das fichas com nome ≠ nomePublico, numerados pela ordem em que lá aparecem (a numeração da O1,
// a mesma do `conferir-registo.mjs`). Os nomes NUNCA estão neste ficheiro: lêem-se das fichas em todas as corridas.
// As formas redigidas (as do §2 da F25):
//   1. o nome inteiro, sem distinguir maiúsculas → «nome n.º N»; a forma toda em minúsculas → «nome n.º N em minúsculas»;
//   2. o nome com a preposição do meio mudada (o canário mudado) → «nome n.º N com a preposição mudada»;
//   3. o nome cortado na origem: a linha acaba num pedaço inicial do nome, maior do que o nome público da mesma ficha
//      (o nome público, sozinho, não se redige) → «nome n.º N (cortado na origem)»;
//   5. (desde a F97, F87) o nome sem a preposição do meio: a forma exacta de um só espaço «1.ª parte + última parte»,
//      com fronteira de palavra dos dois lados → «nome n.º N sem a preposição» (uma forma por preposição no meio, sem
//      ela). O apelido sozinho não se redige: é palavra corrente.
// Nada mais muda: nem linhas acrescentadas ou tiradas, nem os fins de linha (CRLF fica CRLF, LF fica LF).
// --saida escreve o redigido (sem --saida nem --comparar, vai para a saída padrão). --comparar compara byte a byte o
// redigido com um registo e diz só o n.º da 1.ª linha diferente, nunca o texto. --ignorar-cr tira os CR dos dois antes
// de comparar (o Godot do CI, em Linux, escreve LF; os registos cometidos foram escritos no Windows, com CRLF).
// Sai com 0 se tudo bate, 1 se a comparação (ou o auto-teste) falha, 2 por uso errado, 3 se sobrar no redigido um nome
// inteiro, uma variante de preposição fora da lista de 5 ou um corte a meio da linha (estes dois desde a F66, e desde
// a F94 também com pontuação (desde a F109 também antes da palavra do meio), partidos por quebra de linha ou colados a uma letra; ver `suspeitos`) ou, desde a F97, o
// nome sem a preposição que a 5.ª forma não redigiu (dois espaços, tabulador, quebra de linha). A saída 3 só diz
// contagens e n.ºs de linha, nunca o texto. Sem nenhum nome verdadeiro nas fichas sai com 2 antes de tudo (também
// antes do --auto-teste); com 1 só, o --auto-teste falha com 1.
import { readFileSync, writeFileSync } from 'node:fs';

const PREPOSICOES = ['de', 'da', 'do', 'das', 'dos'];
const esc = (k) => k.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const min = (s) => s.toLocaleLowerCase('pt');
const eLetra = (c) => /\p{L}/u.test(c);

export function lerFichas(caminho) {
  const fichas = JSON.parse(readFileSync(caminho, 'utf8')).fichas;
  const verdadeiros = fichas.filter((f) => f.nome && f.nome !== f.nomePublico)
    .map((f) => ({ nome: f.nome, publico: typeof f.nomePublico === 'string' ? f.nomePublico : '' }));
  const publicos = fichas.filter((f) => f.nome && f.nome === f.nomePublico).map((f) => f.nome);
  return { verdadeiros, publicos };
}

// As variantes do nome com a preposição do meio mudada (só nomes de 3 ou mais palavras).
function variantesPreposicao(nome) {
  const ps = nome.split(' ');
  const vs = [];
  for (let j = 1; j < ps.length - 1; j++) {
    if (!PREPOSICOES.includes(min(ps[j]))) continue;
    for (const outra of PREPOSICOES) {
      if (outra === min(ps[j])) continue;
      vs.push([...ps.slice(0, j), outra, ...ps.slice(j + 1)].join(' '));
    }
  }
  return vs;
}

// F97 (F87): o nome sem a preposição do meio — uma forma por preposição da lista no meio: as partes de antes e as de depois
// (só nomes de 3 ou mais palavras).
function partesSemPreposicao(nome) {
  const ps = nome.split(' ');
  const fs = [];
  for (let j = 1; j < ps.length - 1; j++) {
    if (PREPOSICOES.includes(min(ps[j]))) fs.push([ps.slice(0, j), ps.slice(j + 1)]);
  }
  return fs;
}

// Redige uma linha (sem o fim de linha). Devolve a linha e soma à contagem.
function redigirLinha(l, verdadeiros, conta) {
  verdadeiros.forEach(({ nome }, k) => {
    const rotulo = `nome n.º ${k + 1}`;
    const vs = variantesPreposicao(nome);
    if (vs.length) {
      l = l.replace(new RegExp(vs.map(esc).join('|'), 'giu'), () => { conta.preposicao++; return `${rotulo} com a preposição mudada`; });
    }
    l = l.replace(new RegExp(esc(nome), 'giu'), (m) => {
      if (m === min(m) && m !== nome) { conta.minusculas++; return `${rotulo} em minúsculas`; }
      conta.inteiros++;
      return rotulo;
    });
    // 5.ª forma (F97, F87): o nome sem a preposição, exacto, com um só espaço e fronteira de palavra dos dois lados.
    const fs = partesSemPreposicao(nome).map(([antes, depois]) => esc([...antes, ...depois].join(' ')));
    if (fs.length) {
      l = l.replace(new RegExp(`(?<!\\p{L})(?:${fs.join('|')})(?!\\p{L})`, 'giu'), () => { conta.semPreposicao++; return `${rotulo} sem a preposição`; });
    }
  });
  // O nome cortado na origem: o fim da linha é um pedaço inicial (próprio) do nome, maior do que o nome público e
  // sem acabar em espaço, e começa numa fronteira de palavra. Fica o maior pedaço que se encontra.
  for (const [k, { nome, publico }] of verdadeiros.entries()) {
    const cs = Array.from(nome);
    const minimo = Math.max(Array.from(publico).length + 1, 4);
    let cortado = false;
    for (let n = cs.length - 1; n >= minimo; n--) {
      const p = cs.slice(0, n).join('');
      if (/\s$/u.test(p)) continue;
      if (!min(l).endsWith(min(p))) continue;
      const antes = Array.from(l.slice(0, l.length - p.length)).pop();
      if (antes !== undefined && eLetra(antes)) continue;
      l = l.slice(0, l.length - p.length) + `nome n.º ${k + 1} (cortado na origem)`;
      conta.cortados++;
      cortado = true;
      break;
    }
    if (cortado) break;
  }
  return l;
}

// Redige o texto inteiro, linha a linha, mantendo os fins de linha tal como estão.
export function redigir(texto, verdadeiros) {
  const conta = { inteiros: 0, minusculas: 0, preposicao: 0, semPreposicao: 0, cortados: 0, linhas: 0 };
  const partes = texto.split(/(\r?\n)/);
  for (let i = 0; i < partes.length; i += 2) {
    const nova = redigirLinha(partes[i], verdadeiros, conta);
    if (nova !== partes[i]) conta.linhas++;
    partes[i] = nova;
  }
  return { texto: partes.join(''), conta };
}

// O n.º de linhas como o `wc -l` dá, mais a última se não acabar em fim de linha.
export const contarLinhas = (t) => (t.match(/\n/g) || []).length + (t === '' || t.endsWith('\n') ? 0 : 1);

export function sobram(texto, verdadeiros) {
  return verdadeiros.reduce((t, { nome }) => t + (min(texto).split(min(nome)).length - 1), 0);
}

// Ordem F66 da sentença da F51: a rede de segurança (saída 3) passa a cobrir também o que a redacção do §2 NÃO redige e
// que ainda assim é o nome. A redacção não muda: isto só se procura no texto JÁ redigido.
//   a) a variante de preposição fora da lista de 5: o nome com a palavra da preposição substituída por outra palavra
//      qualquer (ou com mais de um espaço à volta dela) — as 5 da lista já foram redigidas, por isso o que sobra é de fora;
//   b) o corte a meio da linha: um pedaço inicial do nome com a mesma medida do corte na origem (maior do que o nome
//      público, sem acabar em espaço, a começar numa fronteira de palavra) que acaba numa fronteira de palavra
//      (o carácter a seguir não é letra) — o corte na origem só se redige no fim da linha.
// Ordem F94 da sentença da F66+F68 (os buracos J8–J10, fechados sem mudar a redacção):
//   J9 — a variante com pontuação logo a seguir à palavra substituída («X du, Y», «X d. Y») também é variante; desde
//        a F109 (sentença da F88–F96) também com a pontuação logo antes dela («X, du Y»);
//   J10 — a variante partida por quebra de linha quando o corte é curto (a linha acaba em «X», demasiado curto para o
//         corte na origem, e a seguinte começa em «de Y» ou «du Y»): a variante procura-se no texto todo, e o espaço
//         à volta da palavra do meio pode ser uma quebra de linha. Conta na linha onde começa;
//   J8 — o corte colado a uma letra (o pedaço do nome seguido logo de outra letra, «X de Sq…»): conta quando o pedaço
//        tem pelo menos 2 palavras inteiras do nome e acaba a meio de uma palavra do nome. Com menos, o nome público
//        seguido de qualquer palavra começada pela mesma letra («X diz») disparava a rede.
// Ordem F93: o nome inteiro tal e qual (é da contagem dos inteiros) e as 5 variantes da lista com um espaço só (a
// redacção já as redigiu) NÃO contam como variante fora da lista, e um corte que começa dentro de uma variante não
// conta como corte — uma ocorrência conta uma vez só.
// Ordem F97 (F71+F87+F89):
//   F87 — o nome sem a preposição: o padrão `1.ª parte \s+ última parte`, com fronteira de palavra, conta como resto
//         (apanha também os dois espaços, os tabuladores e a quebra de linha, que a 5.ª forma exacta não apanha). A forma
//         de um espaço não se exclui: se a redacção falhar, a rede ainda sai com 3. O apelido sozinho fica de fora;
//   F89 — a palavra substituta da variante fora da lista é «uma palavra de letras, com ou sem hífenes». Duas ou três
//         palavras no lugar da preposição (já são palavras inseridas) e dígitos continuam fora.
// Devolve as contagens e os n.ºs das linhas (1-based), nunca o texto.
function reVariantesFora(nome) {
  const ps = nome.split(' ');
  const res = [];
  for (let j = 1; j < ps.length - 1; j++) {
    if (!PREPOSICOES.includes(min(ps[j]))) continue;
    const antes = ps.slice(0, j).map(esc).join('\\s+');
    const depois = ps.slice(j + 1).map(esc).join('\\s+');
    // F114 (travar o J10, opção 1 da F108): qualquer separador à volta da palavra do meio casa no máximo um `\n` e nunca
    // `\n\n` — a quebra de linha pode estar antes ou depois da palavra do meio, ou nos dois lados, nunca uma linha em
    // branco.
    const S = '(?=\\s)[^\\S\\n]*\\n?[^\\S\\n]*';
    // F109 (J9-antes, sentença da F88–F96): a pontuação também pode vir ANTES da palavra do meio («X, du Y»), com a
    // mesma forma da de depois (pontuação colada, e a seguir no máximo um `\n`).
    const P = '\\p{P}+[^\\S\\n]*\\n?[^\\S\\n]*';
    res.push(new RegExp(`(?<!\\p{L})${antes}(?:${P}|${S})[\\p{L}'’]+(?:-[\\p{L}'’]+)*(?:${P}|${S})${depois}(?!\\p{L})`, 'giu'));
  }
  return res;
}

// F97 (F87): o nome sem a preposição, com qualquer espaço entre as partes.
function reSemPreposicao(nome) {
  return partesSemPreposicao(nome).map(([antes, depois]) =>
    new RegExp(`(?<!\\p{L})${[...antes, ...depois].map(esc).join('\\s+')}(?!\\p{L})`, 'giu'));
}

// As posições (em caracteres da linha) onde começa um corte a meio da linha.
function cortesNaLinha(l, nome, publico) {
  const cs = Array.from(min(nome));
  const minimo = Math.max(Array.from(publico).length + 1, 4);
  const ls = Array.from(l).map(min);
  const pos = [];
  for (let i = 0; i < ls.length; i++) {
    if (i > 0 && eLetra(ls[i - 1])) continue;
    let c = 0;
    while (c < cs.length && i + c < ls.length && ls[i + c] === cs[c]) c++;
    if (c === cs.length) continue; // o nome inteiro: é da contagem dos inteiros
    while (c > 0 && /\s/u.test(cs[c - 1])) c--; // o pedaço não acaba em espaço
    if (c < minimo) continue;
    if (i + c < ls.length && eLetra(ls[i + c])) {
      // J8: colado a uma letra — só com 2 palavras inteiras do nome no pedaço e o corte a meio de uma palavra do nome.
      const inteiras = cs.slice(0, c).join('').split(/\s+/u).length - 1;
      if (!eLetra(cs[c]) || inteiras < 2) continue;
    }
    pos.push(i);
    i += c - 1;
  }
  return pos;
}

// Só chamar sobre o texto JÁ redigido (como a ferramenta faz): as 5 variantes da lista não contam aqui, porque a
// redacção do §2 já as trocou — num texto cru, uma delas não dá suspeito nenhum (F93).
export function suspeitos(texto, verdadeiros) {
  const t = texto.replace(/\r(?=\n|$)/g, '');
  const inicios = [0];
  for (let p = t.indexOf('\n'); p !== -1; p = t.indexOf('\n', p + 1)) inicios.push(p + 1);
  const linhaDe = (p) => { let a = 0; while (a + 1 < inicios.length && inicios[a + 1] <= p) a++; return a + 1; };
  const r = { inteiros: sobram(texto, verdadeiros), variantes: 0, cortes: 0, semPreposicao: 0,
    linhasVariantes: [], linhasCortes: [], linhasSemPreposicao: [] };
  const vs = [], ss = [], lv = new Set(), lc = new Set(), ls = new Set();
  verdadeiros.forEach(({ nome }) => {
    const exactas = new Set([nome, ...variantesPreposicao(nome)].map(min));
    for (const re of reVariantesFora(nome)) {
      for (const m of t.matchAll(re)) {
        if (exactas.has(min(m[0]))) continue;
        const fim = m.index + m[0].length;
        if (vs.some(([a, b]) => m.index < b && a < fim)) continue; // a mesma ocorrência, por outra preposição do nome
        vs.push([m.index, fim]);
        r.variantes++;
        lv.add(linhaDe(m.index));
      }
    }
    for (const re of reSemPreposicao(nome)) {
      for (const m of t.matchAll(re)) {
        const fim = m.index + m[0].length;
        if (ss.some(([a, b]) => m.index < b && a < fim)) continue; // a mesma ocorrência, por outra preposição do nome
        ss.push([m.index, fim]);
        r.semPreposicao++;
        ls.add(linhaDe(m.index));
      }
    }
  });
  inicios.forEach((ini, i) => {
    const l = t.slice(ini, i + 1 < inicios.length ? inicios[i + 1] - 1 : t.length);
    const cps = Array.from(l);
    verdadeiros.forEach(({ nome, publico }) => {
      for (const p of cortesNaLinha(l, nome, publico)) {
        const abs = ini + cps.slice(0, p).join('').length;
        if ([...vs, ...ss].some(([a, b]) => a <= abs && abs < b)) continue; // dentro de uma variante ou do nome sem a preposição: já contou
        r.cortes++;
        lc.add(i + 1);
      }
    });
  });
  r.linhasVariantes = [...lv].sort((x, y) => x - y);
  r.linhasCortes = [...lc].sort((x, y) => x - y);
  r.linhasSemPreposicao = [...ls].sort((x, y) => x - y);
  return r;
}

const descreverSuspeitos = (s) =>
  `sobram ${s.inteiros} nome(s) inteiro(s), ${s.variantes} variante(s) de preposição fora da lista` +
  `${s.variantes ? ` (linhas ${s.linhasVariantes.join(', ')})` : ''}, ${s.cortes} corte(s) a meio da linha` +
  `${s.cortes ? ` (linhas ${s.linhasCortes.join(', ')})` : ''}, ${s.semPreposicao} nome(s) sem a preposição` +
  `${s.semPreposicao ? ` (linhas ${s.linhasSemPreposicao.join(', ')})` : ''}`;
const haSuspeitos = (s) => s.inteiros + s.variantes + s.cortes + s.semPreposicao > 0;

// A 1.ª linha diferente entre dois Buffers (1-based), ou 0 se são iguais.
function primeiraDiferente(a, b) {
  if (a.equals(b)) return 0;
  const la = a.toString('utf8').split('\n');
  const lb = b.toString('utf8').split('\n');
  for (let i = 0; i < Math.max(la.length, lb.length); i++) if (la[i] !== lb[i]) return i + 1;
  return Math.max(la.length, lb.length);
}

function autoTeste(verdadeiros, publicos, escreve = console.log) {
  // Casos montados em memória a partir das fichas: os nomes nunca vão para disco nem para a saída.
  let corridas = 0, falhas = 0;
  const confere = (desc, cond) => { corridas++; if (!cond) falhas++; escreve(`  ${cond ? 'ok   ' : 'FALHA'} ${desc}`); };
  const r = (t) => redigir(t, verdadeiros).texto;
  const sus = (t) => suspeitos(t, verdadeiros);
  const [a, b] = verdadeiros;
  confere(`as fichas têm ${verdadeiros.length} nome(s) verdadeiro(s) e ${publicos.length} público(s) por inteiro (≥ 2 verdadeiros)`, verdadeiros.length >= 2);
  // F68: com menos de 2 nomes verdadeiros os casos abaixo não se podem montar — o auto-teste falha (sai com 1) em vez
  // de rebentar a meio com um TypeError.
  if (verdadeiros.length < 2) {
    escreve(`auto-teste do redigir-nomes: 0 de ${corridas} verificações passaram (os outros casos precisam de 2 nomes verdadeiros e não correram).`);
    return 1;
  }
  confere('1: o nome inteiro → «nome n.º 1», «nome n.º 2» (também dentro de JSON)',
    r(`  ok    1: «${a.nome}» e «${b.nome}» são canários ["${a.nome}", "${b.nome}"]`) ===
    '  ok    1: «nome n.º 1» e «nome n.º 2» são canários ["nome n.º 1", "nome n.º 2"]');
  confere('1: a forma toda em minúsculas → «nome n.º 1 em minúsculas»',
    r(`traz «${min(a.nome)}»`) === 'traz «nome n.º 1 em minúsculas»');
  confere('1: a forma em maiúsculas → «nome n.º 2» (sem distinguir maiúsculas)',
    r(`x ${b.nome.toLocaleUpperCase('pt')} y`) === 'x nome n.º 2 y');
  const vb = variantesPreposicao(b.nome);
  confere('2: o canário com a preposição mudada → «nome n.º 2 com a preposição mudada»',
    vb.length > 0 && r(`«${b.nome}» → «${vb[0]}»`) === '«nome n.º 2» → «nome n.º 2 com a preposição mudada»');
  const cb = Array.from(b.nome).slice(0, -1).join('');
  confere('3: a linha acaba no nome n.º 2 sem o último carácter → «nome n.º 2 (cortado na origem)»',
    r(`"${a.nome} na linha 50", "${cb}`) === '"nome n.º 1 na linha 50", "nome n.º 2 (cortado na origem)');
  const ca = Array.from(a.nome).slice(0, Array.from(a.publico).length + 2).join('');
  confere('3: a linha acaba no início do nome n.º 1 (maior do que o público) → «nome n.º 1 (cortado na origem)»',
    r(`na linha 39", "${ca}`) === 'na linha 39", "nome n.º 1 (cortado na origem)');
  confere('3: o nome público no fim da linha NÃO se redige (não é um corte do nome)',
    r(`  vez: ${a.publico}`) === `  vez: ${a.publico}` && r(`dá «${a.publico}» e «${b.publico}»`) === `dá «${a.publico}» e «${b.publico}»`);
  confere('3: o pedaço a meio de uma palavra no fim da linha NÃO se redige',
    r(`x${ca}`) === `x${ca}`);
  confere('os nomes públicos por inteiro e as linhas sem nomes ficam iguais',
    publicos.every((p) => r(`«${p}»`) === `«${p}»`) && r('teste: 26 de 26 verificações passaram.') === 'teste: 26 de 26 verificações passaram.');
  const crlf = `a «${a.nome}»\r\nb\r\n\r\nc «${b.nome}»\nfim`;
  const rc = r(crlf);
  confere('os fins de linha ficam como estavam (CRLF, LF, linha vazia, sem fim no fim) e o n.º de linhas não muda',
    rc === 'a «nome n.º 1»\r\nb\r\n\r\nc «nome n.º 2»\nfim' && rc.split('\n').length === crlf.split('\n').length);
  confere('a redacção é idempotente (redigir o redigido não muda nada) e não sobra nenhum nome inteiro',
    r(rc) === rc && sobram(rc, verdadeiros) === 0);
  // Ordem F66/F68 da sentença da F51: a rede de segurança (saída 3) para o que a redacção do §2 não redige.
  const psA = a.nome.split(' ');
  const jA = psA.findIndex((p, j) => j > 0 && j < psA.length - 1 && PREPOSICOES.includes(min(p)));
  const foraA = jA > 0 ? [...psA.slice(0, jA), 'du', ...psA.slice(jA + 1)].join(' ') : null;
  const linhaV = foraA && `x «${foraA}» y`;
  const sV = foraA && sus(r(linhaV));
  confere('F66: a variante do nome n.º 1 com uma preposição fora da lista de 5 não se redige (o §2 não muda), mas a rede apanha-a: 1 variante → saída 3',
    !!foraA && r(linhaV) === linhaV && sV.variantes === 1 && sV.linhasVariantes.join() === '1' && sV.cortes === 0 && sV.inteiros === 0 && haSuspeitos(sV));
  const minimoB = Math.max(Array.from(b.publico).length + 1, 4);
  const csB = Array.from(b.nome);
  let nB = minimoB;
  while (nB < csB.length && /\s/u.test(csB[nB - 1])) nB++;
  const corteB = csB.slice(0, nB).join('');
  const sC = sus(r(`a\n"${corteB}", "resto"`));
  confere('F66: o corte mínimo do nome n.º 2 a meio da linha não se redige, mas a rede apanha-o (1 corte, linha 2 → saída 3); no fim da linha redige-se',
    r(`"${corteB}", "resto"`) === `"${corteB}", "resto"` && sC.cortes === 1 && sC.linhasCortes.join() === '2' && sC.variantes === 0 && haSuspeitos(sC) &&
    r(`fim: ${corteB}`) === 'fim: nome n.º 2 (cortado na origem)');
  const limpos = [r(`  vez: ${a.publico}`), r(`dá «${a.publico}» e «${b.publico}» ao fim`), r(`x${ca} y`), r(`«${b.publico}» diz`), rc,
    r(`«${b.nome}» → «${vb[0]}»`), r(`"${cb}`), r(`fim: ${corteB}`),
    // F94 (J8): o que o corte colado a uma letra NÃO pode apanhar — o nome público seguido de uma palavra que começa
    // pela letra da preposição, e a preposição colada a outra letra.
    ...[a, b].flatMap(({ nome, publico }) => {
      const ps = nome.split(' '), j = ps.findIndex((p, i) => i > 0 && PREPOSICOES.includes(min(p)));
      return j > 0 ? [r(`«${publico} ${Array.from(ps[j])[0]}iz» x`), r(`«${ps.slice(0, j + 1).join(' ')}x» y`)] : [nome]; // sem preposição: o nome cru faz o caso falhar
    })];
  confere('F66: a rede não dispara no que a redacção deixa limpo (o nome público, o pedaço a meio de palavra, as formas já redigidas; F94: o nome público seguido de uma palavra começada pela letra da preposição)',
    limpos.every((t) => !haSuspeitos(sus(t))));
  let semRebentar = true, rc1 = 0;
  try { rc1 = autoTeste([a], publicos, () => {}); } catch { semRebentar = false; }
  confere('F68: com 1 só nome verdadeiro o auto-teste falha (sai com 1) sem rebentar',
    semRebentar && rc1 === 1);
  // Ordem F94/F95 da sentença da F66+F68. Os casos montam-se como os de cima, a partir das fichas.
  // F96 — dependências das fichas: a 13.ª verificação (a variante «du») e as de J9, J10, F93 e dos buracos ainda
  // abertos precisam de o nome n.º 1 ter uma preposição da lista no meio; a 5.ª precisa do mesmo no nome n.º 2 e a
  // 15.ª nos dois; a 14.ª precisa de o nome n.º 2 ser maior do que o mínimo do corte; a de J8 precisa de o nome n.º 2 ter
  // 3 palavras ou mais. F97: as do nome sem a preposição (rede e 5.ª forma no nome n.º 1) e as duas da F89 precisam de
  // o nome n.º 1 ter uma preposição da lista no meio; a da 5.ª forma no nome n.º 2, do mesmo no nome n.º 2. F109: a do
  // J9-antes («X, du Y») também precisa de o nome n.º 1 ter uma preposição da lista no meio.
  // Se as fichas mudarem e isto já não valer, o caso FALHA (falha alto, não se salta).
  const antesA = jA > 0 ? psA.slice(0, jA).join(' ') : null, depoisA = jA > 0 ? psA.slice(jA + 1).join(' ') : null;
  const s1 = (t) => { const s = sus(t); return [s.inteiros, s.variantes, s.cortes, s.linhasVariantes.join(), s.linhasCortes.join()].join('|'); };
  // J8: o corte colado a uma letra. O pedaço do nome n.º 2 até à 1.ª letra da 3.ª palavra, seguido de uma letra que
  // não é a do nome.
  const psB = b.nome.split(' ');
  const pedB = psB.length >= 3 ? `${psB.slice(0, 2).join(' ')} ${Array.from(psB[2])[0]}` : null;
  const seguinte = pedB && Array.from(b.nome)[Array.from(pedB).length];
  const colado = pedB && `${pedB}${min(seguinte) === 'q' ? 'z' : 'q'}xw`;
  confere('F94 (J8): o corte do nome n.º 2 colado a uma letra (2 palavras inteiras e a 3.ª a meio) não se redige, mas a rede apanha-o: 1 corte, linha 2 → saída 3',
    !!colado && r(`a\n«${colado}» b`) === `a\n«${colado}» b` && s1(r(`a\n«${colado}» b`)) === '0|0|1||2');
  // J9: a variante do nome n.º 1 com pontuação logo a seguir à palavra substituída.
  const pont = antesA && [`x «${antesA} du, ${depoisA}» y`, `x «${antesA} d. ${depoisA}» y`, `x «${antesA} du;${depoisA}» y`];
  confere('F94 (J9): a variante do nome n.º 1 com pontuação logo a seguir à palavra substituída («du,», «d.», «du;» sem espaço) → 1 variante por caso → saída 3',
    !!pont && pont.every((t) => r(t) === t && s1(r(t)) === '0|1|0|1|'));
  // J10: a variante partida por quebra de linha, com o corte demasiado curto para se redigir na origem.
  const partidas = antesA && [`fim: ${antesA}\n${psA[jA]} ${depoisA} segue`, `fim: ${antesA} du\n${depoisA} segue`,
    `a\r\nfim: ${antesA}\r\n${psA[jA]} ${depoisA} segue\r\n`];
  confere('F94 (J10): o nome n.º 1 (ou a variante «du») partido por quebra de linha, com o corte curto (LF e CRLF), não se redige, mas a rede apanha-o: 1 variante, na linha onde começa → saída 3',
    !!partidas && partidas.map((t) => r(t) === t).every(Boolean) &&
    s1(r(partidas[0])) === '0|1|0|1|' && s1(r(partidas[1])) === '0|1|0|1|' && s1(r(partidas[2])) === '0|1|0|2|');
  // F114 (travar o J10): qualquer separador à volta da palavra do meio casa no máximo um `\n`, nunca uma linha em branco.
  const tresLinhas = antesA && `fim: ${antesA}\n${psA[jA]}\n${depoisA} segue`;
  confere('F114 (J10 travado): o nome n.º 1 partido por 3 linhas (o início / a preposição sozinha / o apelido) não se redige, mas a rede continua a apanhá-lo: 1 variante, na linha 1 → saída 3',
    !!tresLinhas && r(tresLinhas) === tresLinhas && s1(r(tresLinhas)) === '0|1|0|1|' && haSuspeitos(sus(r(tresLinhas))));
  const emBranco = antesA && `fim: ${antesA}\n\n${psA[jA]} ${depoisA} segue`;
  confere('F114 (J10 travado): o nome n.º 1 partido por uma linha em branco antes da preposição NÃO conta como variante (0 variantes; a travagem tem dentes)',
    !!emBranco && r(emBranco) === emBranco && sus(r(emBranco)).variantes === 0);
  // F116 (sentença da F108): uma linha só com espaços conta como linha em branco — nas duas posições (antes da palavra
  // do meio e antes do apelido) a variante não a atravessa. Antes do apelido usa-se a variante «du»: com a preposição
  // verdadeira a linha de cima já se redige como corte na origem e o caso não teria dentes.
  const soEspacos = antesA && [`fim: ${antesA}\n  \n${psA[jA]} ${depoisA} segue`, `fim: ${antesA} du\n \t \n${depoisA} segue`];
  confere('F116 (J10 travado): o nome n.º 1 partido por uma linha só de espaços (antes da palavra do meio, ou a variante «du» antes do apelido) não se redige e NÃO conta como variante (0 variantes nas duas posições; a travagem tem dentes)',
    !!soEspacos && soEspacos.every((t) => r(t) === t && sus(r(t)).variantes === 0));
  // F109 (J9-antes, sentença da F88–F96): a pontuação ANTES da palavra do meio também é variante.
  const pontAntes = antesA && `x «${antesA}, du ${depoisA}» y`;
  confere('F109 (J9-antes): a variante do nome n.º 1 com pontuação antes da palavra do meio («X, du Y») não se redige, mas a rede apanha-a: 1 variante, linha 1 → saída 3',
    !!pontAntes && r(pontAntes) === pontAntes && s1(r(pontAntes)) === '0|1|0|1|' && haSuspeitos(sus(r(pontAntes))));
  // F93: uma ocorrência conta uma vez só.
  const duploA = antesA && `x «${antesA}  ${psA[jA]} ${depoisA}» y`;
  confere('F93: o nome n.º 1 inteiro (texto cru) conta só como inteiro (0 variantes, 0 cortes); com 2 espaços conta só como 1 variante',
    s1(`x «${a.nome}» y`) === '1|0|0||' && !!duploA && s1(duploA) === '0|1|0|1|');
  // F95: os buracos que ficam abertos. Estes casos passam ENQUANTO o buraco está aberto; quem o fechar tem de os virar
  // (passam a afirmar a saída 3) — é a prova do fecho.
  // F97 (F87) fechou o do nome sem a preposição: o caso virou e afirma a rede (o que a 5.ª forma exacta não redige).
  const s2 = (t) => { const s = sus(t); return [s.semPreposicao, s.linhasSemPreposicao.join(), s.inteiros + s.variantes + s.cortes].join('|'); };
  const semPrep2 = antesA && [`x «${antesA}  ${depoisA}» y`, `a\nx «${antesA}\t${depoisA}» y`, `fim: ${antesA}\n${depoisA} segue`];
  const semPrep1 = antesA && `x «${antesA} ${depoisA}» y`;
  confere('F95 FECHADO (F97, F87): o nome n.º 1 sem a preposição com dois espaços, um tabulador ou partido por quebra de linha não se redige, mas a rede apanha-o (1, na linha onde começa → saída 3); e se a redacção falhar (a forma de um espaço, crua) a rede também sai com 3',
    !!semPrep2 && semPrep2.every((t) => r(t) === t) &&
    s2(r(semPrep2[0])) === '1|1|0' && s2(r(semPrep2[1])) === '1|2|0' && s2(r(semPrep2[2])) === '1|1|0' &&
    s2(semPrep1) === '1|1|0' && haSuspeitos(sus(semPrep1)));
  // F97 (F87): a 5.ª forma da redacção — o nome sem a preposição, exacto, com um espaço só.
  confere('F87: o nome n.º 1 sem a preposição a meio da linha → «nome n.º 1 sem a preposição» (e a rede fica calada)',
    !!semPrep1 && r(semPrep1) === 'x «nome n.º 1 sem a preposição» y' && !haSuspeitos(sus(r(semPrep1))) &&
    r(`x${antesA} ${depoisA}`) === `x${antesA} ${depoisA}` && r(`${antesA} ${depoisA}x`) === `${antesA} ${depoisA}x`);
  const jB = psB.findIndex((p, j) => j > 0 && j < psB.length - 1 && PREPOSICOES.includes(min(p)));
  const semPrepB = jB > 0 ? [...psB.slice(0, jB), ...psB.slice(jB + 1)].join(' ') : null;
  confere('F87: o nome n.º 2 sem a preposição no fim da linha → «nome n.º 2 sem a preposição» (e a rede fica calada)',
    !!semPrepB && r(`a\nfim: ${semPrepB}\r\nb`) === 'a\nfim: nome n.º 2 sem a preposição\r\nb' && !haSuspeitos(sus(r(`fim: ${semPrepB}`))));
  // F97 (F89): a palavra substituta é «uma palavra de letras, com ou sem hífenes».
  const hifen = antesA && `x «${antesA} du-la ${depoisA}» y`;
  confere('F89: a variante do nome n.º 1 com uma palavra hifenizada no lugar da preposição («du-la») não se redige, mas a rede apanha-a: 1 variante → saída 3',
    !!hifen && r(hifen) === hifen && s1(r(hifen)) === '0|1|0|1|' && s2(r(hifen)) === '0||1');
  const duas = antesA && `x «${antesA} du la ${depoisA}» y`;
  confere('F89 AINDA ABERTO: duas palavras no lugar da preposição do nome n.º 1 («du la») não dão suspeito (são palavras inseridas, não a preposição substituída)',
    !!duas && r(duas) === duas && s1(r(duas)) === '0|0|0||' && s2(r(duas)) === '0||0');
  const meio = antesA && [`x «${psA.slice(jA).join(' ')}» y`, `x «${depoisA}» y`];
  confere('F95 AINDA ABERTO: um pedaço que começa a meio do nome n.º 1 (a preposição e o apelido, ou só o apelido) não dá suspeito',
    !!meio && meio.every((t) => r(t) === t && s1(r(t)) === '0|0|0||'));
  escreve(`auto-teste do redigir-nomes: ${corridas - falhas} de ${corridas} verificações passaram.`);
  return falhas ? 1 : 0;
}

const principal = process.argv[1] && import.meta.url.endsWith(process.argv[1].replace(/\\/g, '/').split('/').pop());
if (principal) {
  const args = process.argv.slice(2);
  const opc = (k) => { const a = args.find((x) => x.startsWith(`--${k}=`)); return a ? a.slice(k.length + 3) : null; };
  const fichasCaminho = opc('fichas') ?? 'rascunhos/servidor/autojogo/fichas-bancada.json';
  const { verdadeiros, publicos } = lerFichas(fichasCaminho);
  if (verdadeiros.length === 0) { console.error('as fichas não têm nenhum nome verdadeiro (nome ≠ nomePublico) — nada a redigir'); process.exit(2); }
  if (args.includes('--auto-teste')) process.exit(autoTeste(verdadeiros, publicos));
  const entrada = args.find((x) => !x.startsWith('--'));
  if (!entrada) { console.error('uso: redigir-nomes.mjs <saida-crua.log> [--fichas=…] [--saida=…] [--comparar=<registo.log>] [--ignorar-cr] | --auto-teste'); process.exit(2); }
  const { texto, conta } = redigir(readFileSync(entrada, 'utf8'), verdadeiros);
  const s = suspeitos(texto, verdadeiros);
  console.error(`redigir-nomes: ${entrada}: ${contarLinhas(texto)} linhas, ${conta.linhas} redigidas — ${conta.inteiros} nome(s) inteiro(s), ${conta.minusculas} em minúsculas, ${conta.preposicao} com a preposição mudada, ${conta.semPreposicao} sem a preposição, ${conta.cortados} cortado(s) na origem; ${descreverSuspeitos(s)}`);
  if (haSuspeitos(s)) process.exit(3);
  const saida = opc('saida');
  if (saida) writeFileSync(saida, texto);
  const registo = opc('comparar');
  if (!registo) { if (!saida) process.stdout.write(texto); process.exit(0); }
  const semCR = (buf) => (args.includes('--ignorar-cr') ? Buffer.from(buf.toString('latin1').replace(/\r/g, ''), 'latin1') : buf);
  const a = semCR(Buffer.from(texto, 'utf8'));
  const b = semCR(readFileSync(registo));
  const d = primeiraDiferente(a, b);
  console.log(d === 0
    ? `${registo}: igual byte a byte ao redigido (${a.length} bytes${args.includes('--ignorar-cr') ? ', sem os CR' : ''})`
    : `${registo}: DIFERE do redigido — 1.ª linha diferente: ${d} (${a.length} contra ${b.length} bytes${args.includes('--ignorar-cr') ? ', sem os CR' : ''})`);
  process.exit(d === 0 ? 0 : 1);
}
