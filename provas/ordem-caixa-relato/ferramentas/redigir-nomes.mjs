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
//      (o nome público, sozinho, não se redige) → «nome n.º N (cortado na origem)».
// Nada mais muda: nem linhas acrescentadas ou tiradas, nem os fins de linha (CRLF fica CRLF, LF fica LF).
// --saida escreve o redigido (sem --saida nem --comparar, vai para a saída padrão). --comparar compara byte a byte o
// redigido com um registo e diz só o n.º da 1.ª linha diferente, nunca o texto. --ignorar-cr tira os CR dos dois antes
// de comparar (o Godot do CI, em Linux, escreve LF; os registos cometidos foram escritos no Windows, com CRLF).
// Sai com 0 se tudo bate, 1 se a comparação (ou o auto-teste) falha, 2 por uso errado, 3 se sobrar no redigido um nome
// inteiro, uma variante de preposição fora da lista de 5 ou um corte a meio da linha (estes dois desde a F66; ver
// `suspeitos`). A saída 3 só diz contagens e n.ºs de linha, nunca o texto.
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
  const conta = { inteiros: 0, minusculas: 0, preposicao: 0, cortados: 0, linhas: 0 };
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
// Devolve as contagens e os n.ºs das linhas (1-based), nunca o texto.
function reVariantesFora(nome) {
  const ps = nome.split(' ');
  const res = [];
  for (let j = 1; j < ps.length - 1; j++) {
    if (!PREPOSICOES.includes(min(ps[j]))) continue;
    const antes = ps.slice(0, j).map(esc).join('\\s+');
    const depois = ps.slice(j + 1).map(esc).join('\\s+');
    res.push(new RegExp(`(?<!\\p{L})${antes}\\s+[\\p{L}'’]+\\s+${depois}(?!\\p{L})`, 'giu'));
  }
  return res;
}

function cortesNaLinha(l, nome, publico) {
  const cs = Array.from(min(nome));
  const minimo = Math.max(Array.from(publico).length + 1, 4);
  const ls = Array.from(min(l));
  let n = 0;
  for (let i = 0; i < ls.length; i++) {
    if (i > 0 && eLetra(ls[i - 1])) continue;
    let c = 0;
    while (c < cs.length && i + c < ls.length && ls[i + c] === cs[c]) c++;
    if (c === cs.length) continue; // o nome inteiro: é da contagem dos inteiros
    while (c > 0 && /\s/u.test(cs[c - 1])) c--; // o pedaço não acaba em espaço
    if (c < minimo) continue;
    if (i + c < ls.length && eLetra(ls[i + c])) continue; // continua noutra palavra: não é um pedaço do nome
    n++;
    i += c - 1;
  }
  return n;
}

export function suspeitos(texto, verdadeiros) {
  const r = { inteiros: sobram(texto, verdadeiros), variantes: 0, cortes: 0, linhasVariantes: [], linhasCortes: [] };
  const res = verdadeiros.map(({ nome }) => reVariantesFora(nome));
  texto.split('\n').forEach((linha, i) => {
    const l = linha.replace(/\r$/, '');
    let v = 0, c = 0;
    verdadeiros.forEach(({ nome, publico }, k) => {
      for (const re of res[k]) v += (l.match(re) || []).length;
      c += cortesNaLinha(l, nome, publico);
    });
    if (v) { r.variantes += v; r.linhasVariantes.push(i + 1); }
    if (c) { r.cortes += c; r.linhasCortes.push(i + 1); }
  });
  return r;
}

const descreverSuspeitos = (s) =>
  `sobram ${s.inteiros} nome(s) inteiro(s), ${s.variantes} variante(s) de preposição fora da lista` +
  `${s.variantes ? ` (linhas ${s.linhasVariantes.join(', ')})` : ''}, ${s.cortes} corte(s) a meio da linha` +
  `${s.cortes ? ` (linhas ${s.linhasCortes.join(', ')})` : ''}`;
const haSuspeitos = (s) => s.inteiros + s.variantes + s.cortes > 0;

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
    r(`«${b.nome}» → «${vb[0]}»`), r(`"${cb}`), r(`fim: ${corteB}`)];
  confere('F66: a rede não dispara no que a redacção deixa limpo (o nome público, o pedaço a meio de palavra, as formas já redigidas)',
    limpos.every((t) => !haSuspeitos(sus(t))));
  let semRebentar = true, rc1 = 0;
  try { rc1 = autoTeste([a], publicos, () => {}); } catch { semRebentar = false; }
  confere('F68: com 1 só nome verdadeiro o auto-teste falha (sai com 1) sem rebentar',
    semRebentar && rc1 === 1);
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
  console.error(`redigir-nomes: ${entrada}: ${contarLinhas(texto)} linhas, ${conta.linhas} redigidas — ${conta.inteiros} nome(s) inteiro(s), ${conta.minusculas} em minúsculas, ${conta.preposicao} com a preposição mudada, ${conta.cortados} cortado(s) na origem; ${descreverSuspeitos(s)}`);
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
