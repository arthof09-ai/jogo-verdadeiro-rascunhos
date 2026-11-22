// Ordem CAIXA-RELATO-CORRECOES-5 (B1/B2): confere, linha a linha, que um registo (o mutacoes.log cometido) não traz
// nenhum nome verdadeiro das fichas de bancada — nem inteiro, nem um fragmento de 4 ou mais caracteres.
//   node provas/ordem-caixa-relato/ferramentas/conferir-registo.mjs [--velho] <registo.log> [<fichas.json>]
// Nomes verdadeiros: os das fichas com nome ≠ nomePublico. Fragmento: qualquer pedaço de 4 ou mais letras seguidas de
// uma palavra de um nome verdadeiro (sem distinguir maiúsculas) — apanha um nome cortado a meio («Xxxx d», «Xxxx de
// Yyyyy»), que o filtro, por procurar o nome inteiro, não apanhava. Também se procura o nome inteiro. Única excepção:
// as ocorrências dentro de um nome que nas fichas é público por inteiro (nome = nomePublico); essas apagam-se da linha
// antes de procurar. A saída NÃO repete o texto achado: diz a linha, o n.º do nome e o comprimento do pedaço.
// Sai com 0 se não achar nada, 1 se achar.
// CAIXA-RELATO-CORRECOES-6 (B2): o critério literal da ordem — também os pedaços A CAVALO DE PALAVRAS. Antes só se
// geravam pedaços dentro de cada palavra do nome; um fragmento como «x de Y» (num nome «Xxxx de Yyyyy»: o fim de uma
// palavra, o espaço, a palavra do meio, o início da seguinte) não tem 4 letras seguidas numa só palavra e escapava.
// (CAIXA-RELATO-CORRECOES-7, B3: o exemplo usa letras de marcação, não um pedaço real dos nomes das fichas.) Agora gera-se todo o pedaço contíguo do nome
// inteiro (espaços incluídos, como estão no nome) que tenha 4 ou mais letras; os de dentro de uma palavra continuam lá.
// `--velho` usa o critério antigo (só dentro de cada palavra), para comparar.
import { readFileSync } from 'node:fs';

const args = process.argv.slice(2);
const velho = args.includes('--velho');
const [registo, fichasCaminho = 'rascunhos/servidor/autojogo/fichas-bancada.json'] = args.filter((a) => a !== '--velho');
if (!registo) { console.error('uso: conferir-registo.mjs [--velho] <registo.log> [<fichas.json>]'); process.exit(2); }
const fichas = JSON.parse(readFileSync(fichasCaminho, 'utf8')).fichas;
const verdadeiros = fichas.filter((f) => f.nome && f.nome !== f.nomePublico).map((f) => f.nome);
const publicos = fichas.filter((f) => f.nome && f.nome === f.nomePublico).map((f) => f.nome);
if (verdadeiros.length === 0) { console.error('as fichas não têm nenhum nome verdadeiro (nome ≠ nomePublico) — nada a conferir'); process.exit(2); }

const esc = (k) => k.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const min = (s) => s.toLocaleLowerCase('pt');
// Os pedaços a procurar, por nome: o nome inteiro; todos os pedaços de ≥4 letras de cada palavra; e (B2) todos os
// pedaços contíguos do nome inteiro com ≥4 letras, a cavalo de palavras (contam só as letras, \p{L}; os espaços entram
// no pedaço mas não contam para as 4).
const eLetra = (c) => /\p{L}/u.test(c);
const pedacos = verdadeiros.map((nome) => {
  const p = new Set([min(nome)]);
  for (const palavra of nome.split(/\s+/)) {
    const letras = Array.from(min(palavra));
    for (let i = 0; i < letras.length; i++) for (let j = i + 4; j <= letras.length; j++) p.add(letras.slice(i, j).join(''));
  }
  if (!velho) {
    const cs = Array.from(min(nome));
    for (let i = 0; i < cs.length; i++) {
      let n = 0;
      for (let j = i; j < cs.length; j++) { if (eLetra(cs[j])) n++; if (n >= 4) p.add(cs.slice(i, j + 1).join('')); }
    }
  }
  return [...p];
});
const rePublicos = publicos.length ? new RegExp(publicos.map(esc).join('|'), 'giu') : null;

const linhas = readFileSync(registo, 'utf8').split('\n');
let achados = 0;
linhas.forEach((l, i) => {
  const limpa = min(rePublicos ? l.replace(rePublicos, ' ') : l);
  pedacos.forEach((ps, k) => {
    if (!ps.some((p) => limpa.includes(p))) return;
    // achado: o comprimento é o do maior pedaço contíguo do nome (pode atravessar palavras) que está na linha
    const n = Array.from(min(verdadeiros[k]));
    let maior = 0;
    for (let a = 0; a < n.length; a++) for (let b = n.length; b - a > maior; b--) if (limpa.includes(n.slice(a, b).join(''))) { maior = b - a; break; }
    {
      achados++;
      console.log(`linha ${i + 1}: nome verdadeiro n.º ${k + 1} (${Array.from(verdadeiros[k]).length} caracteres) — pedaço de ${maior} caracteres${maior === Array.from(verdadeiros[k]).length ? ' (o nome inteiro)' : ''}`);
    }
  });
});
console.log(`${registo}: critério ${velho ? 'antigo (só dentro de cada palavra)' : 'alargado (também a cavalo de palavras)'}, ${pedacos.reduce((t, ps) => t + ps.length, 0)} pedaços; ${linhas.length} linhas, ${verdadeiros.length} nome(s) verdadeiro(s), ${publicos.length} nome(s) público(s) por inteiro excluído(s); ${achados} achado(s)`);
process.exit(achados ? 1 : 0);
