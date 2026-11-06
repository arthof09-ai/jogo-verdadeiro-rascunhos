// Utilitários puros do núcleo.
// REGRA: este arquivo não importa node:* (tem de rodar também no workerd).

/**
 * JSON canónico: chaves ordenadas por código (sort padrão), sem espaços,
 * `undefined` e funções omitidos nos objetos e trocados por null nos arrays.
 * Usado no hashAcao (E-C1), no hash de revisão e na exportação do journal.
 * Escrito à mão (sem JSON.stringify do objeto inteiro) porque o JSON.stringify
 * põe as chaves de tipo inteiro antes das outras, e aqui queremos uma ordem única.
 */
export function jsonCanonico(valor) {
  if (valor === null) return 'null';
  switch (typeof valor) {
    case 'number':
      if (!Number.isFinite(valor)) throw new TypeError('JSON canónico: número não finito');
      return JSON.stringify(valor);
    case 'string':
      return JSON.stringify(valor);
    case 'boolean':
      return valor ? 'true' : 'false';
    case 'object': {
      if (Array.isArray(valor)) {
        const partes = valor.map((x) =>
          x === undefined || typeof x === 'function' ? 'null' : jsonCanonico(x),
        );
        return '[' + partes.join(',') + ']';
      }
      const chaves = Object.keys(valor)
        .filter((k) => valor[k] !== undefined && typeof valor[k] !== 'function')
        .sort();
      return '{' + chaves.map((k) => JSON.stringify(k) + ':' + jsonCanonico(valor[k])).join(',') + '}';
    }
    default:
      throw new TypeError('JSON canónico: tipo não serializável: ' + typeof valor);
  }
}

/** Cópia profunda por JSON. O estado da sala é sempre JSON puro, de propósito. */
export function clonarJson(valor) {
  return valor === undefined ? undefined : JSON.parse(JSON.stringify(valor));
}

/** Object.freeze profundo (as fichas ficam imutáveis depois de carregadas). */
export function congelarProfundo(valor) {
  if (valor === null || typeof valor !== 'object') return valor;
  for (const k of Reflect.ownKeys(valor)) congelarProfundo(valor[k]);
  return Object.freeze(valor);
}

/** Inteiro de 32 bits sem sinal em 8 dígitos hexadecimais. */
export function hex8(n) {
  return (n >>> 0).toString(16).padStart(8, '0');
}

/** Comparação de strings em tempo (quase) constante, para hashes. */
export function iguaisTempoConstante(a, b) {
  if (typeof a !== 'string' || typeof b !== 'string') return false;
  let dif = a.length ^ b.length;
  const n = Math.max(a.length, b.length);
  for (let i = 0; i < n; i++) dif |= (a.charCodeAt(i) || 0) ^ (b.charCodeAt(i) || 0);
  return dif === 0;
}
