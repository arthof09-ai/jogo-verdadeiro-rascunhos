// Ordem CAIXA-RELATO-CORRECOES-5 (B1/B2): confere, linha a linha, que um registo (o mutacoes.log cometido) não traz
// nenhum nome verdadeiro das fichas de bancada — nem inteiro, nem um fragmento de 4 ou mais caracteres.
//   node provas/ordem-caixa-relato/ferramentas/conferir-registo.mjs <registo.log> [<fichas.json>]
// Nomes verdadeiros: os das fichas com nome ≠ nomePublico. Fragmento: qualquer pedaço de 4 ou mais letras seguidas de
// uma palavra de um nome verdadeiro (sem distinguir maiúsculas) — apanha um nome cortado a meio («Xxxx d», «Xxxx de
// Yyyyy»), que o filtro, por procurar o nome inteiro, não apanhava. Também se procura o nome inteiro. Única excepção:
// as ocorrências dentro de um nome que nas fichas é público por inteiro (nome = nomePublico); essas apagam-se da linha
// antes de procurar. A saída NÃO repete o texto achado: diz a linha, o n.º do nome e o comprimento do pedaço.
// Sai com 0 se não achar nada, 1 se achar.
import { readFileSync } from 'node:fs';

const [registo, fichasCaminho = 'rascunhos/servidor/autojogo/fichas-bancada.json'] = process.argv.slice(2);
if (!registo) { console.error('uso: conferir-registo.mjs <registo.log> [<fichas.json>]'); process.exit(2); }
const fichas = JSON.parse(readFileSync(fichasCaminho, 'utf8')).fichas;
const verdadeiros = fichas.filter((f) => f.nome && f.nome !== f.nomePublico).map((f) => f.nome);
const publicos = fichas.filter((f) => f.nome && f.nome === f.nomePublico).map((f) => f.nome);
if (verdadeiros.length === 0) { console.error('as fichas não têm nenhum nome verdadeiro (nome ≠ nomePublico) — nada a conferir'); process.exit(2); }

const esc = (k) => k.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const min = (s) => s.toLocaleLowerCase('pt');
// Os pedaços a procurar, por nome: o nome inteiro e todos os pedaços de ≥4 letras de cada palavra.
const pedacos = verdadeiros.map((nome) => {
  const p = new Set([min(nome)]);
  for (const palavra of nome.split(/\s+/)) {
    const letras = Array.from(min(palavra));
    for (let i = 0; i < letras.length; i++) for (let j = i + 4; j <= letras.length; j++) p.add(letras.slice(i, j).join(''));
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
console.log(`${registo}: ${linhas.length} linhas, ${verdadeiros.length} nome(s) verdadeiro(s), ${publicos.length} nome(s) público(s) por inteiro excluído(s); ${achados} achado(s)`);
process.exit(achados ? 1 : 0);
