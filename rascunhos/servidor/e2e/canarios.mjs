// O detector de canários do arnês e2e da jogadora (ORDEM-PLANO-2-F1-F8, 26/11/2026), à parte do arnês para se poder
// testar sem servidor (testes/e2e-canarios.test.mjs).
//
// Antes (até à F8) era `texto.includes(c)` sobre a mensagem crua, para todos os canários. Um id hexadecimal que
// trouxesse «9137» por acaso (um UUID como «…-9137-…» ou um «a9137f…») acusava uma fuga que não existia. Agora:
//  - os canários de texto («Orc Verdadeiro», «CANARIO-…») continuam a casar em qualquer sítio da mensagem;
//  - os numéricos («7777», «9137») só casam como **número inteiro**: um valor numérico JSON igual a eles, ou o número
//    inteiro dentro de um texto, com fronteiras (nem letra, nem algarismo, nem «_», «-» ou ponto decimal encostados);
//  - os valores dos campos de id (`id`, `*Id`, `*Ids`) não se olham para os numéricos: são opacos e não trazem
//    números do Mestre.
// Quem acusa recebe a mensagem acusada completa, para o log.

export const CANARIOS = ['Orc Verdadeiro', '7777', 'CANARIO-DESGRACA', 'CANARIO-FANTASMA', '9137'];

const NUMERICO = /^\d+$/;
const eCampoId = (k) => k === 'id' || /Ids?$/.test(k);
// O «.» só conta como encostado quando é ponto decimal («9137.5», «1.9137»); o ponto final de uma frase não.
const inteiroEm = (c) => new RegExp(`(?<![0-9A-Za-z_\\-]|\\d\\.)${c}(?![0-9A-Za-z_\\-]|\\.\\d)`);

function numericosEm(valor, canarios, achados) {
  if (typeof valor === 'number') {
    for (const c of canarios) if (Number.isInteger(valor) && String(valor) === c) achados.add(c);
  } else if (typeof valor === 'string') {
    for (const c of canarios) if (inteiroEm(c).test(valor)) achados.add(c);
  } else if (Array.isArray(valor)) {
    for (const v of valor) numericosEm(v, canarios, achados);
  } else if (valor && typeof valor === 'object') {
    for (const [k, v] of Object.entries(valor)) {
      if (eCampoId(k)) continue; // o valor de um campo de id não se olha
      for (const c of canarios) if (inteiroEm(c).test(k)) achados.add(c); // um número como chave
      numericosEm(v, canarios, achados);
    }
  }
}

/** Os canários que a mensagem crua `texto` traz (lista vazia se nenhum). */
export function canariosEm(texto, canarios = CANARIOS) {
  const achados = new Set();
  const numericos = canarios.filter((c) => NUMERICO.test(c));
  for (const c of canarios) if (!NUMERICO.test(c) && texto.includes(c)) achados.add(c);
  if (numericos.length) {
    let m;
    try {
      m = JSON.parse(texto);
    } catch {
      m = undefined;
    }
    if (m === undefined) {
      for (const c of numericos) if (inteiroEm(c).test(texto)) achados.add(c); // não é JSON: só as fronteiras
    } else {
      numericosEm(m, numericos, achados);
    }
  }
  return canarios.filter((c) => achados.has(c));
}

/**
 * Confere uma lista de mensagens cruas. Devolve null se estiverem limpas; senão, o texto da acusação, com cada
 * mensagem acusada inteira (não só o valor do canário).
 */
export function acusacao(mensagens, onde, canarios = CANARIOS) {
  const acusadas = [];
  mensagens.forEach((texto, i) => {
    const vazados = canariosEm(texto, canarios);
    if (vazados.length) acusadas.push({ i, vazados, texto });
  });
  if (!acusadas.length) return null;
  const todos = [...new Set(acusadas.flatMap((a) => a.vazados))];
  const linhas = acusadas.map((a) => `  mensagem acusada #${a.i + 1} de ${mensagens.length} (${a.vazados.join(', ')}, `
    + `${a.texto.length} caracteres): ${a.texto}`);
  return `canários do Mestre no fio dela (${onde}): ${todos.join(', ')}\n${linhas.join('\n')}`;
}
