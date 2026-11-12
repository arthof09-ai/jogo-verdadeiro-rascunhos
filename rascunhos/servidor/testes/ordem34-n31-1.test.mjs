// Ordem 34 do CM-000009 — N31-1 (sentença da bancada, 2026-11-12; prioridade 1): conferência completa do journal na
// restauração, antes de a sala abrir. O V10 (ordem 18) parava na forma de topo do estado; um journal sem chave editado
// à mão e re-assinado, com um campo de dentro estragado, abria a sala e rebentava no primeiro ROOM_JOIN (o processo
// caía, e ao reabrir do mesmo ficheiro voltava a cair).
// Três camadas, todas obrigatórias:
//  (1) esquema completo em profundidade (tipos e campos obrigatórios em todos os níveis);
//  (2) referências que existem (figuras.<id>.fichaId nas fichas; vez.figuraId nas figuras; …);
//  (3) rede final: qualquer excepção na restauração ou no ROOM_JOIN é apanhada pelo adaptador e vira recusa.
// Um campo inválido = a sala não abre: sem reparação automática; o ficheiro fica intacto; os mesmos bytes dão a mesma
// recusa na hora; o erro diz a sala e o caminho do campo (só no registo do Mestre).
// A prova: o fuzz de mutações (3000) — nenhuma pode rebentar; as que rebentavam viram recusas limpas.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { criarSala } from '../nucleo/sala.js';
import { ErroJournal } from '../nucleo/journal.js';
import { jsonCanonico } from '../nucleo/util.js';
import { sha256Hex } from '../nucleo/sha256.js';
import { criarServidor, abrirSalaComJournal, envelopeJournal } from '../adaptadores/node/servidor-ws.js';
import * as Adaptador from '../adaptadores/node/servidor-ws.js';
import { montarMesa, exigirAplicada, rngDeterministico, relogio, fichasDeTeste, INICIATIVA, PIN, SENHAS } from './ajudantes.mjs';
import { criarMotorFalso } from './motor-falso.mjs';
import { ligarWs, mensagensWs, fecho } from './ajudantes-ws.mjs';

const CONFIG = () => ({
  roomId: 'sala-teste', mapa: { largura: 20, altura: 20 }, iniciativa: INICIATIVA, modoPadrao: 'auto', depurar: true,
  lugares: [
    { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
    { papel: 'mestre', nome: 'Mestre', pin: PIN },
  ],
});
const JOIN_MESTRE = { v: 2, type: 'ROOM_JOIN', papel: 'mestre', pin: PIN };
const JOIN_HEROINA = { v: 2, type: 'ROOM_JOIN', papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina };

function criarDe(restaurarDe) {
  return criarSala({ motores: criarMotorFalso(), fichas: fichasDeTeste(), rng: rngDeterministico(7), agora: relogio(), config: CONFIG(), restaurarDe });
}
function assinado(corpo) {
  const t = jsonCanonico(corpo);
  return t + '\n' + 'sha256:' + sha256Hex(t) + '\n';
}
const corpoDe = (exportado) => JSON.parse(exportado.split('\n')[0]);

/** Journals verdadeiros em fases diferentes (o que o servidor escreve de facto). */
function sessoes() {
  const lista = {};
  {
    const m = montarMesa();
    m.entrarTodos();
    lista.lobby = m.sala.exportar();
    m.iniciarCombate([['orc-teste', { x: 2, y: 6 }], ['lobo-teste', { x: 12, y: 2 }]]);
    lista.combate = m.sala.exportar();
    const h = m.clientes.heroina;
    exigirAplicada(m.intencao('heroina', { tipo: 'atacar', alvoId: h.idPorNome('Orc'), arma: 'chicote-teste' }));
    const casa = h.opcoes.mover[0];
    exigirAplicada(m.intencao('heroina', { tipo: 'mover', destino: { x: casa.x, y: casa.y } }));
    lista.combateJogado = m.sala.exportar();
    m.sair('mestre');
    lista.pausa = m.sala.exportar();
  }
  {
    const m = montarMesa({ modoPadrao: 'semi' });
    m.entrarTodos();
    m.iniciarCombate([['orc-teste', { x: 2, y: 3 }]]);
    exigirAplicada(m.intencao('heroina', { tipo: 'encerrar' }));
    lista.cartaoAberto = m.sala.exportar(); // a vez do Orc em semi: cartão de IA à espera do Mestre
    exigirAplicada(m.mestre('MASTER_SUPERVISOR', { op: 'terminar' }));
    lista.fim = m.sala.exportar();
  }
  return lista;
}

/** Entra com os dois lugares e pede o que a primeira entrada pede. Devolve o nº de mensagens recebidas. */
function usar(sala, exigirEntrada = false) {
  let n = 0;
  for (const join of [JOIN_MESTRE, JOIN_HEROINA]) {
    const r = sala.entrar({ ...join, roomId: sala.roomId }, { ip: '10.0.34.9' });
    // A mutação pode ter mexido no nome ou no índice do lugar: aí a entrada é recusada (credenciais), sem rebentar.
    if (!r.ok) {
      if (exigirEntrada) assert.fail('a entrada foi recusada: ' + JSON.stringify(r.mensagens));
      n += r.mensagens.length;
      continue;
    }
    n += r.mensagens.length + r.saidas.length;
    n += sala.conexaoAberta(r.seatId).length;
    n += sala.receber(r.seatId, { v: 2, type: 'ROOM_RESYNC', lastSeq: 0 }).length;
    if (join.papel === 'mestre') n += sala.receber(r.seatId, { v: 2, type: 'MASTER_VIEW' }).length;
  }
  return n;
}

/** Espera um ErroJournal com o caminho do campo. */
function recusaCom(texto, caminho, rotulo) {
  let erro = null;
  try {
    criarDe(texto);
  } catch (e) {
    erro = e;
  }
  assert.ok(erro, `${rotulo}: a sala abriu`);
  assert.ok(erro instanceof ErroJournal, `${rotulo}: veio ${erro?.name}: ${erro?.message}`);
  assert.equal(erro.caminho, caminho, `${rotulo}: caminho do campo`);
}

// ------------------------------------------------------------------ controlo: o que o servidor escreve abre

test('ordem 34 (N31-1, controlo): os journals verdadeiros de todas as fases restauram e aguentam a entrada', () => {
  for (const [fase, exportado] of Object.entries(sessoes())) {
    let sala;
    assert.doesNotThrow(() => { sala = criarDe(exportado); }, fase);
    assert.ok(usar(sala, true) > 0, fase);
    assert.doesNotThrow(() => criarDe(assinado(corpoDe(exportado))), fase + ' (re-assinado igual)');
  }
});

// ------------------------------------------------------------------ camada 1: esquema completo em profundidade

test('ordem 34 (N31-1, falhava antes): camada 1 — um campo de dentro com o tipo errado ou em falta recusa a sala, com o caminho', () => {
  const base = sessoes();
  const caso = (fase, mexer) => {
    const c = corpoDe(base[fase]);
    const caminho = mexer(c.estado);
    return [assinado(c), caminho];
  };
  const fig = (e) => Object.keys(e.figuras)[0];
  const lug = (e) => Object.keys(e.lugares)[0];
  const casos = {
    'paGasto texto': caso('combate', (e) => { e.figuras[fig(e)].paGasto = 'muito'; return `figuras.${fig(e)}.paGasto`; }),
    'paGasto negativo': caso('combate', (e) => { e.figuras[fig(e)].paGasto = -1; return `figuras.${fig(e)}.paGasto`; }),
    'paGasto null': caso('combate', (e) => { e.figuras[fig(e)].paGasto = null; return `figuras.${fig(e)}.paGasto`; }),
    'paGasto em falta': caso('combate', (e) => { delete e.figuras[fig(e)].paGasto; return `figuras.${fig(e)}.paGasto`; }),
    'vez.reservaM em falta': caso('combate', (e) => { delete e.vez.reservaM; return 'vez.reservaM'; }),
    'vez.reservaM texto': caso('combate', (e) => { e.vez.reservaM = '6'; return 'vez.reservaM'; }),
    'vez.atacou número': caso('combate', (e) => { e.vez.atacou = 0; return 'vez.atacou'; }),
    'vez lista': caso('combate', (e) => { e.vez = []; return 'vez'; }),
    'figura.vivo texto': caso('combate', (e) => { e.figuras[fig(e)].vivo = 'sim'; return `figuras.${fig(e)}.vivo`; }),
    'figura.x fraccionado': caso('combate', (e) => { e.figuras[fig(e)].x = 1.5; return `figuras.${fig(e)}.x`; }),
    'figura.vidaActual em falta': caso('lobby', (e) => { delete e.figuras[fig(e)].vidaActual; return `figuras.${fig(e)}.vidaActual`; }),
    'figura.id trocado': caso('lobby', (e) => { e.figuras[fig(e)].id = 'outra'; return `figuras.${fig(e)}.id`; }),
    'mapa.largura zero': caso('lobby', (e) => { e.mapa.largura = 0; return 'mapa.largura'; }),
    'mapa.altura texto': caso('combate', (e) => { e.mapa.altura = '20'; return 'mapa.altura'; }),
    'contadores.cartao texto': caso('combate', (e) => { e.contadores.cartao = 'a'; return 'contadores.cartao'; }),
    'lugar.epoch null': caso('lobby', (e) => { e.lugares[lug(e)].epoch = null; return `lugares.${lug(e)}.epoch`; }),
    'lugar.nome número': caso('lobby', (e) => { e.lugares[lug(e)].nome = 7; return `lugares.${lug(e)}.nome`; }),
    'ambiente null': caso('combate', (e) => { e.ambiente = null; return 'ambiente'; }),
    'fogo.ultimoTick null': caso('combate', (e) => { e.fogo.ultimoTick = null; return 'fogo.ultimoTick'; }),
    'fogo.casas com lixo': caso('combate', (e) => { e.fogo.casas = [7]; return 'fogo.casas.0'; }),
    'rodada texto': caso('combate', (e) => { e.rodada = 'um'; return 'rodada'; }),
    'ordem com número': caso('combate', (e) => { e.ordem[0] = 3; return 'ordem.0'; }),
    'cartão sem estado': caso('cartaoAberto', (e) => { delete e.cartoes[0].estado; return 'cartoes.0.estado'; }),
    'cartão null': caso('cartaoAberto', (e) => { e.cartoes[0] = null; return 'cartoes.0'; }),
    'pausa.motivo número': caso('pausa', (e) => { e.pausa.motivo = 1; return 'pausa.motivo'; }),
  };
  for (const [rotulo, [texto, caminho]] of Object.entries(casos)) recusaCom(texto, caminho, rotulo);
});

// ------------------------------------------------------------------ camada 2: referências que existem

test('ordem 34 (N31-1, falhava antes): camada 2 — fichaId que não existe nas fichas, vez e ordem que não apontam para uma figura', () => {
  const base = sessoes();
  const caso = (fase, mexer) => {
    const c = corpoDe(base[fase]);
    const caminho = mexer(c.estado);
    return [assinado(c), caminho];
  };
  const fig = (e) => Object.keys(e.figuras)[0];
  const jogadora = (e) => Object.values(e.lugares).find((s) => s.papel === 'jogadora');
  const casos = {
    'fichaId inexistente': caso('combate', (e) => { e.figuras[fig(e)].fichaId = 'ficha-que-nao-existe'; return `figuras.${fig(e)}.fichaId`; }),
    'fichaId inexistente no lobby': caso('lobby', (e) => { e.figuras[fig(e)].fichaId = 'ficha-que-nao-existe'; return `figuras.${fig(e)}.fichaId`; }),
    'vez.figuraId sem figura': caso('combate', (e) => { e.vez.figuraId = 'f-ninguem'; return 'vez.figuraId'; }),
    'ordem com id sem figura': caso('combate', (e) => { e.ordem[1] = 'f-ninguem'; return 'ordem.1'; }),
    'lugar da jogadora sem figura': caso('lobby', (e) => { const s = jogadora(e); s.figuraId = 'f-ninguem'; return `lugares.${s.seatId}.figuraId`; }),
    'cartão de figura que não existe': caso('cartaoAberto', (e) => { e.cartoes[0].figuraId = 'f-ninguem'; return 'cartoes.0.figuraId'; }),
  };
  for (const [rotulo, [texto, caminho]] of Object.entries(casos)) recusaCom(texto, caminho, rotulo);
});

// ------------------------------------------------------------------ sem reparação; ficheiro intacto; a mesma recusa na hora

test('ordem 34 (N31-1, falhava antes): a sala não abre, o ficheiro fica intacto e os mesmos bytes dão a mesma recusa na hora', () => {
  const pasta = mkdtempSync(path.join(tmpdir(), 'o34-n31-'));
  try {
    const c = corpoDe(sessoes().combate);
    const id = Object.keys(c.estado.figuras)[0];
    c.estado.figuras[id].paGasto = 'muito';
    const caminho = path.join(pasta, 'registo-MESTRE-ONLY-sala.json');
    const bytes = envelopeJournal(assinado(c));
    writeFileSync(caminho, bytes, 'utf8');
    let criadas = 0;
    const criar = (restaurarDe) => {
      criadas += 1;
      return criarDe(restaurarDe);
    };
    const invalidas = new Map();
    const a = abrirSalaComJournal({ caminho, criar, invalidas });
    assert.equal(a.ok, false);
    assert.equal(a.sala, undefined, 'nenhuma sala, nenhum snapshot');
    assert.equal(a.campo, `figuras.${id}.paGasto`, 'o caminho do campo que falhou');
    assert.equal(a.repetida, false);
    assert.equal(readFileSync(caminho, 'utf8'), bytes, 'o ficheiro fica como estava (nada é reparado nem reescrito)');
    assert.equal(criadas, 1);
    // Reabrir os mesmos bytes: a mesma recusa, na hora (marcada inválida pelo conteúdo; nem se volta a tentar).
    const b = abrirSalaComJournal({ caminho, criar, invalidas });
    assert.equal(b.ok, false);
    assert.equal(b.repetida, true);
    assert.equal(b.campo, a.campo);
    assert.equal(b.erro, a.erro, 'a mesma recusa');
    assert.equal(criadas, 1, 'os mesmos bytes não voltam a ser restaurados');
    assert.equal(readFileSync(caminho, 'utf8'), bytes);
    // O texto do registo (só do Mestre) diz a sala e o caminho do campo.
    const texto = Adaptador.textoRecusaJournal(a);
    assert.match(texto, /sala-teste/);
    assert.ok(texto.includes(`figuras.${id}.paGasto`), texto);
    // Conserto manual (outros bytes): volta a abrir.
    c.estado.figuras[id].paGasto = 0;
    writeFileSync(caminho, envelopeJournal(assinado(c)), 'utf8');
    const d = abrirSalaComJournal({ caminho, criar, invalidas });
    assert.equal(d.ok, true);
    assert.equal(d.restaurada, true);
  } finally {
    rmSync(pasta, { recursive: true, force: true });
  }
});

// ------------------------------------------------------------------ camada 3: a rede final do adaptador

test('ordem 34 (N31-1, falhava antes): camada 3 — qualquer excepção na restauração vira recusa da sala (o adaptador não a deixa subir)', () => {
  const pasta = mkdtempSync(path.join(tmpdir(), 'o34-n31-'));
  try {
    const caminho = path.join(pasta, 'registo-MESTRE-ONLY-sala.json');
    writeFileSync(caminho, envelopeJournal(sessoes().combate), 'utf8');
    let a;
    assert.doesNotThrow(() => {
      a = abrirSalaComJournal({ caminho, invalidas: new Map(), criar: () => { throw new TypeError('rebentou lá dentro'); } });
    });
    assert.equal(a.ok, false);
    assert.equal(a.sala, undefined);
    assert.match(Adaptador.textoRecusaJournal(a), /rebentou lá dentro/);
  } finally {
    rmSync(pasta, { recursive: true, force: true });
  }
});

test('ordem 34 (N31-1, falhava antes): camada 3 — a excepção no ROOM_JOIN vira recusa daquela entrada; o processo e as outras ligações seguem', () => {
  const verdadeira = criarDe(null);
  let rebenta = true;
  const sala = {
    ...verdadeira,
    roomId: verdadeira.roomId,
    entrar: (msg, ctx) => {
      if (rebenta) throw new TypeError('Cannot read properties of undefined (reading \'id\')');
      return verdadeira.entrar(msg, ctx);
    },
  };
  const registos = [];
  const servidor = criarServidor({ sala, registo: (t) => registos.push(t) });
  const a = ligarWs(servidor, '10.0.34.2');
  assert.doesNotThrow(() => a.json(JOIN_HEROINA));
  const msgs = mensagensWs(a.socket);
  assert.equal(msgs.length, 1);
  assert.equal(msgs[0].type, 'ERRO');
  assert.equal(msgs[0].codigo, 'interno');
  assert.ok(!msgs.some((m) => m.type === 'ROOM_SNAPSHOT' || m.type === 'ROOM_WELCOME'), '0 snapshots');
  assert.ok(!JSON.stringify(msgs).includes('undefined'), 'o texto da excepção não vai a quem entra');
  assert.ok(registos.some((t) => t.includes('sala-teste') && t.includes('ROOM_JOIN')), 'registado (só do Mestre): ' + JSON.stringify(registos));
  // A ligação seguinte entra (a sala e o processo seguem vivos).
  rebenta = false;
  const b = ligarWs(servidor, '10.0.34.3');
  b.json(JOIN_HEROINA);
  assert.ok(mensagensWs(b.socket).some((m) => m.type === 'ROOM_WELCOME'));
  assert.equal(fecho(b.socket), null);
  servidor.close();
});

test('ordem 34 (N31-1, falhava antes): camada 3 — a excepção ao fechar uma ligação com lugar não sobe', () => {
  const verdadeira = criarDe(null);
  const sala = { ...verdadeira, roomId: verdadeira.roomId, conexaoFechada: () => { throw new TypeError('rebentou ao fechar'); } };
  const registos = [];
  const servidor = criarServidor({ sala, registo: (t) => registos.push(t) });
  const a = ligarWs(servidor, '10.0.34.4');
  a.json(JOIN_HEROINA);
  assert.ok(mensagensWs(a.socket).some((m) => m.type === 'ROOM_WELCOME'));
  assert.doesNotThrow(() => a.cair());
  assert.ok(registos.some((t) => t.includes('sala-teste')), JSON.stringify(registos));
  servidor.close();
});

// ------------------------------------------------------------------ a prova: o fuzz de mutações

/** Todos os caminhos do estado (contentores e folhas), como listas de chaves. */
function caminhosDe(valor, prefixo = [], out = []) {
  if (valor !== null && typeof valor === 'object') {
    for (const k of Object.keys(valor)) {
      out.push([...prefixo, k]);
      caminhosDe(valor[k], [...prefixo, k], out);
    }
  }
  return out;
}
const VALORES = [null, 0, -1, 1.5, 7, 1e9, '', 'x', 'f-ninguem', 'ficha-que-nao-existe', true, false, [], {}, [1], { x: 'a' }];

/** Uma mutação num campo ao acaso do estado: apagar, ou trocar por um valor de outro feitio. */
function mutar(estado, rng) {
  const caminhos = caminhosDe(estado);
  const c = caminhos[rng() % caminhos.length];
  let alvo = estado;
  for (const k of c.slice(0, -1)) alvo = alvo[k];
  const ultima = c[c.length - 1];
  const op = rng() % 5;
  if (op === 0) {
    if (Array.isArray(alvo)) alvo.splice(Number(ultima), 1);
    else delete alvo[ultima];
  } else {
    alvo[ultima] = JSON.parse(JSON.stringify(VALORES[rng() % VALORES.length]));
  }
  return c.join('.');
}

test('ordem 34 (N31-1, falhava antes): fuzz de 3000 mutações ao estado re-assinado — nenhuma rebenta; ou recusa limpa, ou abre e aguenta a entrada', () => {
  const bases = Object.entries(sessoes()).map(([fase, exportado]) => [fase, corpoDe(exportado)]);
  const rng = rngDeterministico(0x34310001);
  const conta = { recusadas: 0, abriram: 0, rebentaram: 0 };
  const rebentos = [];
  const semCaminho = [];
  for (let i = 0; i < 3000; i++) {
    const [fase, corpo] = bases[i % bases.length];
    const c = JSON.parse(JSON.stringify(corpo));
    const onde = mutar(c.estado, rng);
    let texto;
    try {
      texto = assinado(c);
    } catch {
      continue; // nunca acontece: os valores são JSON puro
    }
    let sala;
    try {
      sala = criarDe(texto);
    } catch (e) {
      if (e instanceof ErroJournal) {
        conta.recusadas += 1;
        // Cada recusa do estado diz o caminho do campo (registada uma a uma).
        if (typeof e.caminho !== 'string' || !e.caminho) semCaminho.push(`${fase} ${onde}: ${e.message}`);
      } else {
        conta.rebentaram += 1;
        rebentos.push(`${fase} ${onde} (restauro): ${e?.name}: ${e?.message}`);
      }
      continue;
    }
    try {
      usar(sala);
      conta.abriram += 1;
    } catch (e) {
      conta.rebentaram += 1;
      rebentos.push(`${fase} ${onde} (entrada): ${e?.name}: ${e?.message}`);
    }
  }
  const resumo = `recusadas ${conta.recusadas}, abriram ${conta.abriram}, rebentaram ${conta.rebentaram}`;
  console.log('ordem 34 N31-1 fuzz: ' + resumo);
  assert.equal(conta.rebentaram, 0, resumo + '\n' + rebentos.slice(0, 25).join('\n'));
  assert.deepEqual(semCaminho.slice(0, 10), [], 'recusas do estado sem o caminho do campo');
  assert.equal(conta.recusadas + conta.abriram, 3000);
});
