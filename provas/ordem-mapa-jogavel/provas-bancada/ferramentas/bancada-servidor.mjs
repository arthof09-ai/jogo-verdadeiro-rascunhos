// ORDEM PROVAS-MAPA (prova 2): o servidor de verdade (WebSocket do adaptador node) para a batalha de bancada com a
// GRELHA-MAPA — a sala nasce SEM tamanho na config (= o mapa inteiro, 50 × 50 de 1,5 m) e com o pacote do terreno.
// Ferramenta de prova (fora de cliente/ e de servidor/); o código do jogo não muda. Só fichas fictícias.
//
//   node bancada-servidor.mjs 8791 [escuta.jsonl]
//
// A heroína nasce em TERRA a norte do lago (38,4); o Mestre (bancada-mestre.mjs) põe o orc DENTRO do lago (38,11).
//
// ORDEM-F2: A ESCUTA DO FIO É PERMANENTE. O invólucro de escuta da CORR8 (bancada-servidor-canario.mjs) mudou-se para
// aqui, SEM as mensagens de teste: este servidor não põe nada no fio, só OUVE o que a sala entrega. Por cada chamada à
// sala (um «lote»: entrar, conexaoAberta, conexaoFechada, receber) escreve em <escuta.jsonl>, pela ordem:
//   - uma linha `{lote, onde, entrada, porPapel}` — quem mandou o quê (papel, type, op/casaM; nunca credenciais) e
//     quantas mensagens a sala entregou a cada papel nesse lote (com os types do Mestre);
//   - uma linha `{n, lote, onde, msg}` por cada mensagem entregue ao lugar da HEROÍNA — o fio dela, antes da Rede do
//     cliente (o seatToken da entrada sai da escuta: é uma credencial, mesmo de teste).
// No fim do guião, sonda-fio.mjs varre esta escuta (procurarCanarios) e confere as linhas do contrato.
// As funções criarSalaBancada / escutar exportam-se para a prova da escuta (ordem-f2), que liga à MESMA escuta um
// invólucro com os canários K1–K5 — fora da corrida padrão.
import { readFileSync, writeFileSync, appendFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { criarSala } from '../../../../rascunhos/servidor/nucleo/sala.js';
import { criarServidor, rngNode } from '../../../../rascunhos/servidor/adaptadores/node/servidor-ws.js';
import { criarMotorFalso } from '../../../../rascunhos/servidor/testes/motor-falso.mjs';
import { fichasDeTeste, INICIATIVA, PIN, SENHAS } from '../../../../rascunhos/servidor/testes/ajudantes.mjs';

export function criarSalaBancada() {
  const terreno = JSON.parse(readFileSync(new URL('../../../../rascunhos/servidor/dados/terreno-floresta.json', import.meta.url), 'utf8'));
  return criarSala({
    terreno,
    motores: criarMotorFalso({ resultado: 'falha_critica' }),
    fichas: fichasDeTeste(),
    rng: rngNode(),
    agora: () => Date.now(),
    config: {
      roomId: 'sala-bancada-mapa',
      teste: true,
      // SEM `mapa`: a sala nasce com a grelha-mapa (ORDEM MAPA-JOGÁVEL §0).
      iniciativa: INICIATIVA,
      modoPadrao: 'manual',
      lugares: [
        { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 38, y: 4 } },
        { papel: 'espectador', nome: 'Visita', senha: SENHAS.espectador },
        { papel: 'mestre', nome: 'Mestre', pin: PIN },
      ],
    },
  });
}

/**
 * O invólucro de escuta (ORDEM-F2): devolve uma sala que se comporta como `sala` e escreve o fio da heroína em `escuta`.
 * `alterar(saidas, contexto)` é só para a prova da escuta (os canários K1–K5); a corrida padrão não o passa, e então
 * as saídas da sala vão para o fio tal como saem.
 */
export function escutar(sala, escuta, { alterar = null } = {}) {
  writeFileSync(escuta, '');
  const lugares = Object.values(sala.depuracao.estado().lugares);
  const papelDe = (seatId) => lugares.find((l) => l.seatId === seatId)?.papel ?? '?';
  const HEROINA = lugares.find((l) => l.papel === 'jogadora')?.seatId;
  let n = 0;
  let lote = 0; // uma entrega do servidor (uma chamada à sala): o que chega junto
  const resumoEntrada = (seatId, msg) => (msg && typeof msg === 'object'
    ? { papel: seatId ? papelDe(seatId) : (msg.papel ?? '?'), type: msg.type ?? null,
      ...(msg.op !== undefined ? { op: msg.op } : {}), ...(msg.casaM !== undefined ? { casaM: msg.casaM } : {}) }
    : null);
  const ouvir = (saidas, onde, entrada) => {
    lote += 1;
    const porPapel = {};
    for (const { seatId, msg } of saidas) {
      const p = papelDe(seatId);
      (porPapel[p] ??= { n: 0, types: [] }).n += 1;
      if (p === 'mestre') porPapel[p].types.push(msg?.type === 'ROOM_EVENT' ? `ROOM_EVENT:${msg.tipo}` : msg?.type);
    }
    appendFileSync(escuta, JSON.stringify({ lote, onde, entrada, porPapel }) + '\n');
    for (const { seatId, msg } of saidas) {
      if (seatId !== HEROINA) continue;
      const gravar = msg?.seatToken ? { ...msg, seatToken: '<retirado da escuta>' } : msg;
      appendFileSync(escuta, JSON.stringify({ n: n++, lote, onde, msg: gravar }) + '\n');
    }
  };
  return {
    ...sala,
    entrar(msg, opcoes) {
      const r = sala.entrar(msg, opcoes);
      const entrada = resumoEntrada(r.ok ? r.seatId : null, msg);
      const saidas = [...(r.ok ? r.mensagens.map((m) => ({ seatId: r.seatId, msg: m })) : []), ...(r.saidas ?? [])];
      ouvir(saidas, 'entrar', entrada);
      return r;
    },
    conexaoAberta(seatId) { const s = sala.conexaoAberta(seatId); ouvir(s, 'conexaoAberta', { papel: papelDe(seatId), type: null }); return s; },
    conexaoFechada(seatId) { const s = sala.conexaoFechada(seatId); ouvir(s, 'conexaoFechada', { papel: papelDe(seatId), type: null }); return s; },
    receber(seatId, msg) {
      let saidas = sala.receber(seatId, msg);
      if (alterar) saidas = alterar(saidas, { seatId, msg, HEROINA });
      ouvir(saidas, 'receber', resumoEntrada(seatId, msg));
      return saidas;
    },
  };
}

// corre como servidor só quando é chamado directamente (a prova da escuta importa-o sem o arrancar)
const mesmo = (a, b) => (process.platform === 'win32' ? a.toLowerCase() === b.toLowerCase() : a === b);
if (process.argv[1] && mesmo(fileURLToPath(import.meta.url), resolve(process.argv[1]))) {
  const porta = Number(process.argv[2] ?? 8791);
  const escuta = process.argv[3] ?? 'escuta-jogadora.jsonl';
  const sala = escutar(criarSalaBancada(), escuta);
  const servidor = criarServidor({ sala, registo: (t) => console.log('[servidor]', t) });
  servidor.listen(porta, '127.0.0.1', () => console.log(`pronto-bancada ${porta} (escuta do fio em ${escuta})`));
}
