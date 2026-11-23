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
// Sai com 0 se tudo bate, 1 se a comparação (ou o auto-teste) falha, 2 por uso errado, 3 se sobrar um nome inteiro.
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

// A 1.ª linha diferente entre dois Buffers (1-based), ou 0 se são iguais.
function primeiraDiferente(a, b) {
  if (a.equals(b)) return 0;
  const la = a.toString('utf8').split('\n');
  const lb = b.toString('utf8').split('\n');
  for (let i = 0; i < Math.max(la.length, lb.length); i++) if (la[i] !== lb[i]) return i + 1;
  return Math.max(la.length, lb.length);
}

function autoTeste(verdadeiros, publicos) {
  // Casos montados em memória a partir das fichas: os nomes nunca vão para disco nem para a saída.
  let corridas = 0, falhas = 0;
  const confere = (desc, cond) => { corridas++; if (!cond) falhas++; console.log(`  ${cond ? 'ok   ' : 'FALHA'} ${desc}`); };
  const r = (t) => redigir(t, verdadeiros).texto;
  const [a, b] = verdadeiros;
  confere(`as fichas têm ${verdadeiros.length} nome(s) verdadeiro(s) e ${publicos.length} público(s) por inteiro (≥ 2 verdadeiros)`, verdadeiros.length >= 2);
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
  console.log(`auto-teste do redigir-nomes: ${corridas - falhas} de ${corridas} verificações passaram.`);
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
  const resto = sobram(texto, verdadeiros);
  console.error(`redigir-nomes: ${entrada}: ${contarLinhas(texto)} linhas, ${conta.linhas} redigidas — ${conta.inteiros} nome(s) inteiro(s), ${conta.minusculas} em minúsculas, ${conta.preposicao} com a preposição mudada, ${conta.cortados} cortado(s) na origem; sobram ${resto} nome(s) inteiro(s)`);
  if (resto) process.exit(3);
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
