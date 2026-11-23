// ORDEM MAPA-JOGÁVEL-CUSTO-CÂMARA (A4, 23/11/2026): CÓPIA ADAPTADA de rascunhos/servidor/e2e/servidor-e2e.mjs, só nesta
// pasta de provas (nunca em e2e/, nunca no CI). Duas mudanças, e só estas: (1) a config não dá `mapa` — a sala nasce
// com a grelha-mapa (50 × 50 de 1,5 m), como a config real do Mestre deve fazer; (2) os imports e o terreno apontam
// para rascunhos/servidor a partir daqui. O resto é o original, linha a linha.
// Corrida de ponta a ponta do ecrã do Mestre (I0004, 08/11/2026): o servidor de verdade (WebSocket do
// adaptador node, sem bibliotecas) com o motor FALSO ou com o MOTOR REAL, e as fichas fictícias dos testes.
//
//   node e2e/servidor-e2e.mjs 8765                                  (motor falso)
//   MOTOR_MJS=<módulo de embrulhar.mjs> node e2e/servidor-e2e.mjs 8766  (VLAB real, como o job motor-real)
//
// Com o VLAB real, os três dados da verificação de crítico da HEROÍNA vêm carregados a [1, 1, 1] (falha
// crítica), como dados físicos de teste: sem isso a corrida só abriria o cartão por sorte. Vale para a
// proposta e para a confirmação (a mesma semente e os mesmos dados). Tudo o resto é o motor como é.
//
// O motor falso devolve sempre falha crítica nos ataques: o golpe da heroína abre um cartão de desgraça,
// que o Mestre (o cliente Godot, testes/e2e_mestre.gd) tem de confirmar pela ligação de verdade.
// Só fichas fictícias; nada do Mestre real.
import { criarSala } from '../../../../rascunhos/servidor/nucleo/sala.js';
import { criarServidor, rngNode } from '../../../../rascunhos/servidor/adaptadores/node/servidor-ws.js';
import { criarMotorFalso } from '../../../../rascunhos/servidor/testes/motor-falso.mjs';
import { pathToFileURL } from 'node:url';
import path from 'node:path';
import { readFileSync } from 'node:fs';
import { fichasDeTeste, INICIATIVA, PIN, SENHAS } from '../../../../rascunhos/servidor/testes/ajudantes.mjs';

const porta = Number(process.argv[2] ?? 8765);
const MOTOR_MJS = process.env.MOTOR_MJS || null;

async function motorReal() {
  const mod = await import(pathToFileURL(path.resolve(MOTOR_MJS)).href);
  const Vlab = Object.create(mod.Vlab);
  Vlab.resolverAtaque = (entrada) => {
    const e = entrada.atacante?.id === 'heroina-teste'
      ? { ...entrada, contexto: { ...entrada.contexto, verificacaoCritico: [1, 1, 1] } }
      : entrada;
    const s = mod.Vlab.resolverAtaque(e);
    console.log('[motor-real] ' + JSON.stringify({ atacante: entrada.atacante?.id, modo: entrada.contexto?.modoDesgraca,
      resultado: s?.resultado, erro: s?.erro?.codigo ?? s?.erro ?? null,
      desgraca: s?.soDoMestre?.falhaCritica?.desgraca?.id ?? null, aplicado: s?.soDoMestre?.falhaCritica?.aplicado ?? null }));
    return s;
  };
  return { Dmg: mod.Dmg, Vlab, MOTOR_SHA256: mod.MOTOR_SHA256, DMG_VERSAO: 'real', LEVELUP_SHA: null };
}

const motor = MOTOR_MJS ? await motorReal() : criarMotorFalso({ resultado: 'falha_critica' });
console.log(`[servidor] motor ${MOTOR_MJS ? 'REAL ' + String(motor.MOTOR_SHA256).slice(0, 12) : 'falso'}`);
// Ordem 44: o servidor de verdade conhece o terreno do mapa (o pacote gerado pelo cliente). Na grelha desta corrida
// (20 × 20 de 1,5 m, a zona livre) não há casas bloqueadas: a corrida é a mesma de antes.
const terreno = JSON.parse(readFileSync(new URL('../../../../rascunhos/servidor/dados/terreno-floresta.json', import.meta.url), 'utf8'));
const sala = criarSala({
  terreno,
  motores: motor,
  fichas: fichasDeTeste(),
  rng: rngNode(),
  agora: () => Date.now(),
  config: {
    roomId: 'sala-e2e',
    teste: true, // L9: sala de TESTE (o selo só o Mestre o vê)
    // A4: sem `mapa` — a sala nasce com a grelha-mapa (MAPA-JOGÁVEL §0).
    iniciativa: INICIATIVA,
    modoPadrao: 'manual', // o orc não joga sozinho: a corrida fica determinista
    lugares: [
      { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
      { papel: 'mestre', nome: 'Mestre', pin: PIN },
    ],
  },
});
// Ordem 49 (B): a fuga plantada, SÓ para provar a jogadora (jogadora-e2e.mjs). Com E2E_FUGA=voltar|fim|recomeco, a
// primeira mensagem dessa fase que vai a um lugar que não é o do Mestre (o snapshot do «voltar», o evento fim, o
// snapshot do «Recomeçar») leva um canário do Mestre num campo a mais. Sem a variável (o CI) a sala é a de sempre.
const FUGA = process.env.E2E_FUGA || null;
function comFuga(salaReal, fase) {
  const mestres = new Set();
  let viuEvento = false;
  let plantou = false;
  const alvo = (msg) => (fase === 'fim'
    ? msg.type === 'ROOM_EVENT' && msg.tipo === 'fim'
    : msg.type === 'ROOM_SNAPSHOT' && viuEvento);
  const evento = fase === 'voltar' ? 'revertido' : 'recomeco';
  const plantar = (saidas) => saidas.map((s) => {
    if (s.msg?.type === 'ROOM_EVENT' && s.msg.tipo === evento) viuEvento = true;
    if (plantou || mestres.has(s.seatId) || !alvo(s.msg)) return s;
    plantou = true;
    console.log(`[servidor] FUGA PLANTADA na fase ${fase}: ${s.msg.type}${s.msg.tipo ? ' ' + s.msg.tipo : ''}`);
    return { ...s, msg: { ...s.msg, fugaPlantada: 'Orc Verdadeiro' } };
  });
  return Object.freeze({
    get roomId() { return salaReal.roomId; },
    ...Object.fromEntries(Object.entries(salaReal).filter(([k]) => k !== 'roomId')),
    entrar: (msg, ctx) => {
      const r = salaReal.entrar(msg, ctx);
      if (r.ok && msg?.papel === 'mestre') mestres.add(r.seatId);
      return r;
    },
    receber: (seatId, msg) => plantar(salaReal.receber(seatId, msg)),
  });
}
if (FUGA && !['voltar', 'fim', 'recomeco'].includes(FUGA)) throw new Error(`E2E_FUGA desconhecida: ${FUGA}`);
const servidor = criarServidor({ sala: FUGA ? comFuga(sala, FUGA) : sala, registo: (t) => console.log('[servidor]', t) });
servidor.listen(porta, '127.0.0.1', () => console.log(`pronto-e2e ${porta}`));
