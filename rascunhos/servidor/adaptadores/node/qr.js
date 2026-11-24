// Ordem PLANO-2-F2 (JV3.4): o QR do link da mesa, sem bibliotecas (como o resto do adaptador).
// Código QR modelo 2 (ISO/IEC 18004), modo byte, correcção M, versões 1 a 10 (até 213 bytes: chega para
// «http://192.168.100.200:65535/?medir=1» com folga). O desenho segue o algoritmo público de referência (Nayuki):
// padrões fixos, Reed-Solomon em GF(256) com 0x11D, entrelaçar dos blocos, máscara de menor penalidade.
// Puro: não toca em node:*. A prova de que se lê está no teste (decodificador independente no CI) e na foto da F2.

const ECC_M = [-1, 10, 16, 26, 18, 24, 16, 18, 22, 22, 26]; // codewords de correcção por bloco (nível M)
const BLOCOS_M = [-1, 1, 1, 1, 2, 2, 4, 4, 4, 5, 5]; // número de blocos (nível M)
const FORMATO_M = 0; // bits do nível no campo de formato (L=1, M=0, Q=3, H=2)
export const VERSAO_MAX = 10;

function modulosDeDados(ver) {
  let r = (16 * ver + 128) * ver + 64;
  if (ver >= 2) {
    const n = Math.floor(ver / 7) + 2;
    r -= (25 * n - 10) * n - 55;
    if (ver >= 7) r -= 36;
  }
  return r;
}

const codewordsDeDados = (ver) => Math.floor(modulosDeDados(ver) / 8) - ECC_M[ver] * BLOCOS_M[ver];

/** Capacidade em bytes (modo byte, nível M) da versão. */
export function capacidade(ver) {
  const cc = ver <= 9 ? 8 : 16;
  return Math.floor((codewordsDeDados(ver) * 8 - 4 - cc) / 8);
}

function mulGF(x, y) {
  let z = 0;
  for (let i = 7; i >= 0; i--) {
    z = (z << 1) ^ ((z >>> 7) * 0x11d);
    z ^= ((y >>> i) & 1) * x;
  }
  return z & 0xff;
}

function divisorRS(grau) {
  const r = new Array(grau).fill(0);
  r[grau - 1] = 1;
  let raiz = 1;
  for (let i = 0; i < grau; i++) {
    for (let j = 0; j < r.length; j++) {
      r[j] = mulGF(r[j], raiz);
      if (j + 1 < r.length) r[j] ^= r[j + 1];
    }
    raiz = mulGF(raiz, 0x02);
  }
  return r;
}

function restoRS(dados, divisor) {
  const r = new Array(divisor.length).fill(0);
  for (const b of dados) {
    const f = b ^ r.shift();
    r.push(0);
    divisor.forEach((c, i) => { r[i] ^= mulGF(c, f); });
  }
  return r;
}

function posicoesAlinhamento(ver) {
  if (ver === 1) return [];
  const n = Math.floor(ver / 7) + 2;
  const passo = Math.ceil((ver * 4 + 4) / (n * 2 - 2)) * 2;
  const r = [6];
  for (let pos = ver * 4 + 17 - 7; r.length < n; pos -= passo) r.splice(1, 0, pos);
  return r;
}

const bit = (x, i) => ((x >>> i) & 1) !== 0;

const MASCARAS = [
  (x, y) => (x + y) % 2 === 0,
  (x, y) => y % 2 === 0,
  (x) => x % 3 === 0,
  (x, y) => (x + y) % 3 === 0,
  (x, y) => (Math.floor(x / 3) + Math.floor(y / 2)) % 2 === 0,
  (x, y) => ((x * y) % 2) + ((x * y) % 3) === 0,
  (x, y) => (((x * y) % 2) + ((x * y) % 3)) % 2 === 0,
  (x, y) => (((x + y) % 2) + ((x * y) % 3)) % 2 === 0,
];

/**
 * Codifica um texto (UTF-8) num QR. Devolve {versao, tamanho, modulos: boolean[][]} (modulos[y][x], true = escuro).
 * Lança se o texto não couber na versão 10.
 */
export function codificarQR(texto) {
  const dados = [...new TextEncoder().encode(String(texto))];
  let ver = 1;
  while (ver <= VERSAO_MAX && dados.length > capacidade(ver)) ver++;
  if (ver > VERSAO_MAX) throw new Error(`QR: ${dados.length} bytes não cabem na versão ${VERSAO_MAX}`);
  const tam = ver * 4 + 17;

  // Os bits: modo byte (0100), contagem, dados, terminador, enchimento.
  const bits = [];
  const por = (v, n) => { for (let i = n - 1; i >= 0; i--) bits.push((v >>> i) & 1); };
  por(0x4, 4);
  por(dados.length, ver <= 9 ? 8 : 16);
  for (const b of dados) por(b, 8);
  const cap = codewordsDeDados(ver) * 8;
  por(0, Math.min(4, cap - bits.length));
  por(0, (8 - (bits.length % 8)) % 8);
  for (let p = 0xec; bits.length < cap; p ^= 0xec ^ 0x11) por(p, 8);
  const cw = [];
  for (let i = 0; i < bits.length; i += 8) cw.push(bits.slice(i, i + 8).reduce((a, b) => (a << 1) | b, 0));

  // Reed-Solomon por bloco e entrelaçar.
  const nBlocos = BLOCOS_M[ver];
  const eccLen = ECC_M[ver];
  const total = Math.floor(modulosDeDados(ver) / 8);
  const curtos = nBlocos - (total % nBlocos);
  const lenCurto = Math.floor(total / nBlocos);
  const div = divisorRS(eccLen);
  const blocos = [];
  for (let i = 0, k = 0; i < nBlocos; i++) {
    const d = cw.slice(k, k + lenCurto - eccLen + (i < curtos ? 0 : 1));
    k += d.length;
    const e = restoRS(d, div);
    if (i < curtos) d.push(0);
    blocos.push(d.concat(e));
  }
  const final = [];
  for (let i = 0; i < blocos[0].length; i++) {
    for (let j = 0; j < blocos.length; j++) {
      if (i !== lenCurto - eccLen || j >= curtos) final.push(blocos[j][i]);
    }
  }

  // A matriz e os padrões fixos.
  const mod = Array.from({ length: tam }, () => new Array(tam).fill(false));
  const fixo = Array.from({ length: tam }, () => new Array(tam).fill(false));
  const pos = (x, y, escuro) => { mod[y][x] = escuro; fixo[y][x] = true; };
  for (let i = 0; i < tam; i++) {
    pos(6, i, i % 2 === 0);
    pos(i, 6, i % 2 === 0);
  }
  for (const [cx, cy] of [[3, 3], [tam - 4, 3], [3, tam - 4]]) {
    for (let dy = -4; dy <= 4; dy++) {
      for (let dx = -4; dx <= 4; dx++) {
        const x = cx + dx;
        const y = cy + dy;
        const d = Math.max(Math.abs(dx), Math.abs(dy));
        if (x >= 0 && x < tam && y >= 0 && y < tam) pos(x, y, d !== 2 && d !== 4);
      }
    }
  }
  const al = posicoesAlinhamento(ver);
  for (let i = 0; i < al.length; i++) {
    for (let j = 0; j < al.length; j++) {
      if ((i === 0 && j === 0) || (i === 0 && j === al.length - 1) || (i === al.length - 1 && j === 0)) continue;
      for (let dy = -2; dy <= 2; dy++) {
        for (let dx = -2; dx <= 2; dx++) pos(al[i] + dx, al[j] + dy, Math.max(Math.abs(dx), Math.abs(dy)) !== 1);
      }
    }
  }
  const formato = (mascara) => {
    const d = (FORMATO_M << 3) | mascara;
    let r = d;
    for (let i = 0; i < 10; i++) r = (r << 1) ^ ((r >>> 9) * 0x537);
    const b = ((d << 10) | r) ^ 0x5412;
    for (let i = 0; i <= 5; i++) pos(8, i, bit(b, i));
    pos(8, 7, bit(b, 6));
    pos(8, 8, bit(b, 7));
    pos(7, 8, bit(b, 8));
    for (let i = 9; i < 15; i++) pos(14 - i, 8, bit(b, i));
    for (let i = 0; i < 8; i++) pos(tam - 1 - i, 8, bit(b, i));
    for (let i = 8; i < 15; i++) pos(8, tam - 15 + i, bit(b, i));
    pos(8, tam - 8, true);
  };
  formato(0); // reserva
  if (ver >= 7) {
    let r = ver;
    for (let i = 0; i < 12; i++) r = (r << 1) ^ ((r >>> 11) * 0x1f25);
    const b = (ver << 12) | r;
    for (let i = 0; i < 18; i++) {
      const a = tam - 11 + (i % 3);
      const c = Math.floor(i / 3);
      pos(a, c, bit(b, i));
      pos(c, a, bit(b, i));
    }
  }

  // Os dados em zigue-zague.
  let i = 0;
  for (let dir = tam - 1; dir >= 1; dir -= 2) {
    if (dir === 6) dir = 5;
    for (let v = 0; v < tam; v++) {
      for (let j = 0; j < 2; j++) {
        const x = dir - j;
        const sobe = ((dir + 1) & 2) === 0;
        const y = sobe ? tam - 1 - v : v;
        if (!fixo[y][x] && i < final.length * 8) {
          mod[y][x] = bit(final[i >>> 3], 7 - (i & 7));
          i++;
        }
      }
    }
  }

  // A máscara de menor penalidade (regras 1, 2 e 4 da norma; a 3 não muda a leitura, só a escolha).
  const aplicar = (m) => {
    for (let y = 0; y < tam; y++) for (let x = 0; x < tam; x++) if (!fixo[y][x] && MASCARAS[m](x, y)) mod[y][x] = !mod[y][x];
  };
  let melhor = 0;
  let menor = Infinity;
  for (let m = 0; m < 8; m++) {
    aplicar(m);
    formato(m);
    const p = penalidade(mod, tam);
    if (p < menor) {
      menor = p;
      melhor = m;
    }
    aplicar(m); // desfaz (XOR)
  }
  aplicar(melhor);
  formato(melhor);
  return { versao: ver, tamanho: tam, mascara: melhor, modulos: mod };
}

function penalidade(mod, tam) {
  let p = 0;
  for (let k = 0; k < 2; k++) {
    for (let a = 0; a < tam; a++) {
      let cor = null;
      let n = 0;
      for (let b = 0; b < tam; b++) {
        const v = k === 0 ? mod[a][b] : mod[b][a];
        if (v === cor) n++;
        else {
          if (n >= 5) p += n - 2;
          cor = v;
          n = 1;
        }
      }
      if (n >= 5) p += n - 2;
    }
  }
  let escuros = 0;
  for (let y = 0; y < tam; y++) {
    for (let x = 0; x < tam; x++) {
      if (mod[y][x]) escuros++;
      if (y < tam - 1 && x < tam - 1) {
        const c = mod[y][x];
        if (c === mod[y][x + 1] && c === mod[y + 1][x] && c === mod[y + 1][x + 1]) p += 3;
      }
    }
  }
  const k = Math.ceil(Math.abs(escuros * 20 - tam * tam * 10) / (tam * tam)) - 1;
  return p + Math.max(0, k) * 10;
}

/** O QR em SVG (margem de 4 módulos, como a norma pede). */
export function qrEmSvg(texto, { modulo = 8 } = {}) {
  const q = codificarQR(texto);
  const lado = (q.tamanho + 8) * modulo;
  let caminho = '';
  for (let y = 0; y < q.tamanho; y++) {
    for (let x = 0; x < q.tamanho; x++) if (q.modulos[y][x]) caminho += `M${(x + 4) * modulo},${(y + 4) * modulo}h${modulo}v${modulo}h-${modulo}z`;
  }
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${lado}" height="${lado}" viewBox="0 0 ${lado} ${lado}" `
    + `shape-rendering="crispEdges"><rect width="100%" height="100%" fill="#fff"/><path d="${caminho}" fill="#000"/></svg>`;
}

/** O QR para o terminal: meio bloco por linha (2 linhas de módulos por linha de texto), margem de 4 (a da norma). */
export function qrNoTerminal(texto) {
  const q = codificarQR(texto);
  const m = 4;
  const escuro = (x, y) => x >= 0 && y >= 0 && x < q.tamanho && y < q.tamanho && q.modulos[y][x];
  const linhas = [];
  for (let y = -m; y < q.tamanho + m; y += 2) {
    let l = '';
    for (let x = -m; x < q.tamanho + m; x++) {
      const a = escuro(x, y);
      const b = escuro(x, y + 1);
      // Fundo claro no terminal escuro: o módulo escuro é o espaço; o claro é o bloco.
      l += !a && !b ? '█' : !a && b ? '▀' : a && !b ? '▄' : ' ';
    }
    linhas.push(l);
  }
  return linhas.join('\n');
}

/** A matriz em PGM (P2, texto), para o decodificador independente do teste. */
export function qrEmPgm(texto, { modulo = 6 } = {}) {
  const q = codificarQR(texto);
  const lado = (q.tamanho + 8) * modulo;
  const px = [];
  for (let y = 0; y < lado; y++) {
    const yy = Math.floor(y / modulo) - 4;
    for (let x = 0; x < lado; x++) {
      const xx = Math.floor(x / modulo) - 4;
      const e = yy >= 0 && xx >= 0 && yy < q.tamanho && xx < q.tamanho && q.modulos[yy][xx];
      px.push(e ? 0 : 255);
    }
  }
  return `P2\n${lado} ${lado}\n255\n${px.join('\n')}\n`;
}
