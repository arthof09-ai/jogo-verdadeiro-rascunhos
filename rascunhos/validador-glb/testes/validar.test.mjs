/**
 * Testes do validador GLB-JOGO-v1 (node:test). Rodar com:
 *   node --test testes/validar.test.mjs
 * Opcional, com o UAL1 real:  UAL1_GLB="<caminho>/UAL1_Standard.glb" node --test testes/validar.test.mjs
 *
 * Tudo em memória: nenhum arquivo é escrito.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import crypto from 'node:crypto';
import {
  validarGlb,
  carregarOssosUal1,
  extrairOssosUal1,
  dimensoesJpeg,
  dimensoesPng,
  OSSOS_OBRIGATORIOS_UAL1,
} from '../validar-glb-jogo.mjs';
import { gerarGlb, ISCAS, derivarDeUal1, pngCinza } from '../gerar-iscas.mjs';

const OSSOS = carregarOssosUal1(new URL('../ossos-ual1.json', import.meta.url));
const validar = (buf, nome = 'teste') => validarGlb(buf, { nomeArquivo: `${nome}__v01.glb`, ossosUal1: OSSOS });
const codigos = (r) => [...new Set(r.falhas.map((f) => f.codigo))].sort();
const explicar = (r) => JSON.stringify({ falhas: r.falhas, avisos: r.avisos }, null, 1);

// ------------------------------------------------------------------ o GLB correto

test('GLB correto mínimo é APROVADO, sem falhas', () => {
  const r = validar(gerarGlb(), 'correto-minimo');
  assert.equal(r.veredito, 'APROVADO', explicar(r));
  assert.deepEqual(r.falhas, []);
  assert.equal(r.contrato, 'GLB-JOGO-v1');
  assert.equal(r.arquivo, 'correto-minimo__v01.glb');
});

test('o relatório tem a forma do §7 e medidas coerentes', () => {
  const r = validar(gerarGlb(), 'correto-minimo');
  for (const k of ['contrato', 'arquivo', 'sha256', 'veredito', 'falhas', 'avisos', 'medidas']) assert.ok(k in r, `falta ${k}`);
  assert.ok(Math.abs(r.medidas.alturaM - 1.8) < 1e-3, `altura ${r.medidas.alturaM}`);
  assert.equal(r.medidas.triangulos, 24);
  assert.equal(r.medidas.pesos.influenciasMax, 2);
  assert.ok(Math.abs(r.medidas.frente.desvioGraus) < 1e-6, `frente ${r.medidas.frente.desvioGraus}°`);
  assert.deepEqual(r.medidas.texturas.map((t) => [t.largura, t.altura]), [[1024, 1024]]);
  assert.equal(Object.keys(r.medidas.verificacoes).length, 18);
});

test('V18: o SHA-256 do relatório é o do arquivo, e o resultado é determinístico', () => {
  const buf = gerarGlb();
  const r1 = validar(buf, 'correto-minimo');
  const r2 = validar(Buffer.from(buf), 'correto-minimo');
  assert.equal(r1.sha256, crypto.createHash('sha256').update(buf).digest('hex'));
  assert.equal(JSON.stringify(r1), JSON.stringify(r2));
  // o gerador também é determinístico (mesmos bytes em qualquer máquina)
  assert.equal(crypto.createHash('sha256').update(gerarGlb()).digest('hex'), r1.sha256);
});

// ------------------------------------------------------------------ as iscas do §8

for (const [nome, isca] of Object.entries(ISCAS)) {
  test(`${nome} (${isca.descricao}) é REPROVADO por ${isca.falha}`, () => {
    const r = validar(gerarGlb(isca.opcoes), nome);
    assert.equal(r.veredito, 'REPROVADO', explicar(r));
    assert.ok(codigos(r).includes(isca.falha), `esperava ${isca.falha}; veio ${explicar(r)}`);
  });

  test(`${nome} reprova SÓ em ${isca.falha} (a isca isola um defeito)`, () => {
    const r = validar(gerarGlb(isca.opcoes), nome);
    assert.deepEqual(codigos(r), [isca.falha], explicar(r));
  });
}

test('isca sem Head dá o aviso da V06 pedido pelo §7', () => {
  const r = validar(gerarGlb(ISCAS['isca-sem-head'].opcoes), 'isca-sem-head');
  assert.ok(r.avisos.some((a) => a.codigo === 'V06'), explicar(r));
});

// ------------------------------------------------------------------ outras verificações

test('V01: lixo e GLB truncado reprovam na leitura', () => {
  const r1 = validarGlb(Buffer.from('isto não é um GLB, é texto simples'), { ossosUal1: OSSOS });
  assert.deepEqual(codigos(r1), ['V01']);
  assert.equal(r1.medidas.verificacoes.V02, 'nao_executada');
  const buf = gerarGlb();
  const r2 = validarGlb(buf.subarray(0, buf.length - 8), { ossosUal1: OSSOS });
  assert.deepEqual(codigos(r2), ['V01']);
});

test('V02: Draco em extensionsRequired reprova', () => {
  const buf = gerarGlb({
    mutarJson: (j) => {
      j.extensionsUsed = ['KHR_draco_mesh_compression'];
      j.extensionsRequired = ['KHR_draco_mesh_compression'];
    },
  });
  assert.deepEqual(codigos(validar(buf)), ['V02']);
});

test('V03: sem asset.extras.contrato reprova', () => {
  const buf = gerarGlb({ mutarJson: (j) => { delete j.asset.extras.contrato; } });
  assert.deepEqual(codigos(validar(buf)), ['V03']);
});

test('V07: rotação no nó da malha reprova', () => {
  const buf = gerarGlb({
    mutarJson: (j) => {
      const corpo = j.nodes.find((n) => n.name === 'corpo');
      corpo.rotation = [0, 0.7071068, 0, 0.7071068];
    },
  });
  assert.deepEqual(codigos(validar(buf)), ['V07']);
});

test('V14: faltar "morrer" reprova', () => {
  const buf = gerarGlb({ mutarJson: (j) => { j.animations = j.animations.filter((a) => a.name !== 'morrer'); } });
  assert.deepEqual(codigos(validar(buf)), ['V14']);
});

test('V15: "parado" sem o sufixo _loop reprova', () => {
  const buf = gerarGlb({
    mutarJson: (j) => {
      j.animations.find((a) => a.name === 'parado_loop').name = 'parado';
    },
  });
  assert.deepEqual(codigos(validar(buf)), ['V15']);
});

test('V06: modelo virado para −Z reprova', () => {
  // Espelha os pés: a ponta (ball) fica atrás do pé.
  const buf = gerarGlb({
    mutarJson: (j) => {
      for (const n of j.nodes) if (n.name === 'ball_l' || n.name === 'ball_r') n.translation[2] = -n.translation[2];
    },
  });
  assert.deepEqual(codigos(validar(buf)), ['V06']);
});

test('V16: extras.anexo com valor inválido reprova', () => {
  const buf = gerarGlb({ mutarJson: (j) => { j.nodes.find((n) => n.name === 'espada').extras.anexo = 'costas'; } });
  assert.deepEqual(codigos(validar(buf)), ['V16']);
});

// ------------------------------------------------------------------ leitura de imagens

test('V09: dimensões do PNG lidas do IHDR', () => {
  assert.deepEqual(dimensoesPng(pngCinza(64, 64)), { formato: 'png', largura: 64, altura: 64, alfa: false });
});

test('V09: dimensões do JPEG lidas do marcador SOF0', () => {
  const jpeg = Buffer.from([
    0xff, 0xd8, // SOI
    0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, // APP0 (JFIF)
    0xff, 0xc0, 0x00, 0x11, 0x08, 0x04, 0x00, 0x08, 0x00, 0x03, // SOF0: altura 1024, largura 2048
    0x01, 0x22, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01,
    0xff, 0xd9, // EOI
  ]);
  assert.deepEqual(dimensoesJpeg(jpeg), { formato: 'jpeg', altura: 1024, largura: 2048, alfa: false });
});

// ------------------------------------------------------------------ lista de ossos

test('ossos-ual1.json: 65 ossos, todos os obrigatórios incluídos, sem repetição', () => {
  assert.equal(OSSOS.completa.length, 65);
  assert.equal(new Set(OSSOS.completa).size, 65);
  for (const o of OSSOS_OBRIGATORIOS_UAL1) assert.ok(OSSOS.completa.includes(o), `falta ${o}`);
  assert.deepEqual([...OSSOS.obrigatorios].sort(), [...OSSOS_OBRIGATORIOS_UAL1].sort());
});

// ------------------------------------------------------------------ UAL1 real (opcional)

const UAL1 = process.env.UAL1_GLB;
const semUal1 = UAL1 ? false : 'defina UAL1_GLB com o caminho do UAL1_Standard.glb';

test('UAL1 real: a lista extraída confere com ossos-ual1.json', { skip: semUal1 }, () => {
  const ext = extrairOssosUal1(fs.readFileSync(UAL1), UAL1);
  assert.deepEqual(ext.completa, OSSOS.completa);
  assert.deepEqual(ext.faltamObrigatorios, []);
  if (OSSOS.fonte.sha256) assert.equal(ext.fonte.sha256, OSSOS.fonte.sha256);
  console.log(`UAL1_Standard.glb sha256 = ${ext.fonte.sha256} (${ext.fonte.bytes} bytes)`);
});

test('UAL1 derivado (clips renomeados): esqueleto e pesos passam; só falta cair/levantar (V14)', { skip: semUal1 }, () => {
  const r = validarGlb(derivarDeUal1(fs.readFileSync(UAL1)), { nomeArquivo: 'ual1-derivado__v01.glb', ossosUal1: OSSOS });
  console.log(explicar(r));
  const c = codigos(r);
  for (const v of ['V01', 'V03', 'V11', 'V12']) assert.ok(!c.includes(v), `não esperava ${v}: ${explicar(r)}`);
  assert.ok(c.includes('V14'), 'esperava V14 (cair/levantar ainda não existem)');
});
