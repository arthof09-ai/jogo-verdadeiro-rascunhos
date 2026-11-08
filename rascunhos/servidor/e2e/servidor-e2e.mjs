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
import { criarSala } from '../nucleo/sala.js';
import { criarServidor, rngNode } from '../adaptadores/node/servidor-ws.js';
import { criarMotorFalso } from '../testes/motor-falso.mjs';
import { pathToFileURL } from 'node:url';
import path from 'node:path';
import { fichasDeTeste, INICIATIVA, PIN, SENHAS } from '../testes/ajudantes.mjs';

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
const sala = criarSala({
  motores: motor,
  fichas: fichasDeTeste(),
  rng: rngNode(),
  agora: () => Date.now(),
  config: {
    roomId: 'sala-e2e',
    teste: true, // L9: sala de TESTE (o selo só o Mestre o vê)
    mapa: { largura: 20, altura: 20 },
    iniciativa: INICIATIVA,
    modoPadrao: 'manual', // o orc não joga sozinho: a corrida fica determinista
    lugares: [
      { papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, fichaId: 'heroina-teste', casa: { x: 2, y: 2 } },
      { papel: 'mestre', nome: 'Mestre', pin: PIN },
    ],
  },
});
const servidor = criarServidor({ sala, registo: (t) => console.log('[servidor]', t) });
servidor.listen(porta, '127.0.0.1', () => console.log(`pronto-e2e ${porta}`));
