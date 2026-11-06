// O SHA-256 em JS puro do núcleo, conferido contra vetores conhecidos e contra o node:crypto.
// (Os testes podem usar node:*; o núcleo não.)
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createHash, createHmac } from 'node:crypto';
import { sha256Hex, hmacSha256Hex } from '../nucleo/sha256.js';
import { jsonCanonico } from '../nucleo/util.js';
import { rngDeterministico } from './ajudantes.mjs';

test('vetores FIPS 180-4', () => {
  assert.equal(sha256Hex(''), 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
  assert.equal(sha256Hex('abc'), 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
  assert.equal(
    sha256Hex('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'),
    '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
  );
});

test('igual ao node:crypto em todos os comprimentos de 0 a 300 e em texto com acentos', () => {
  const r = rngDeterministico(1234);
  for (let n = 0; n <= 300; n++) {
    const bytes = new Uint8Array(n);
    for (let i = 0; i < n; i++) bytes[i] = r() & 0xff;
    assert.equal(sha256Hex(bytes), createHash('sha256').update(bytes).digest('hex'), `n=${n}`);
  }
  const texto = 'Assimilação: ação, coração, ñ, 漢字, 🐺';
  assert.equal(sha256Hex(texto), createHash('sha256').update(texto, 'utf8').digest('hex'));
  const grande = new Uint8Array(200_000).map((_, i) => (i * 31) & 0xff);
  assert.equal(sha256Hex(grande), createHash('sha256').update(grande).digest('hex'));
});

test('HMAC-SHA256 igual ao node:crypto (chave curta e chave longa)', () => {
  for (const chave of ['k', 'chave-de-teste', 'x'.repeat(200)]) {
    for (const msg of ['', 'mensagem', 'á'.repeat(1000)]) {
      assert.equal(hmacSha256Hex(chave, msg), createHmac('sha256', chave).update(msg, 'utf8').digest('hex'));
    }
  }
});

test('JSON canónico: chaves ordenadas, inteiros como chave na mesma ordem, undefined omitido', () => {
  assert.equal(jsonCanonico({ b: 1, a: [1, undefined, 'x'], c: undefined, 10: true, 2: false }), '{"10":true,"2":false,"a":[1,null,"x"],"b":1}');
  assert.equal(jsonCanonico({ a: { d: 1, c: 2 } }), jsonCanonico({ a: { c: 2, d: 1 } }));
  assert.throws(() => jsonCanonico({ a: Infinity }), TypeError);
});
