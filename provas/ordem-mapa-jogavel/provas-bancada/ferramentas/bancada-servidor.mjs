// ORDEM PROVAS-MAPA (prova 2): o servidor de verdade (WebSocket do adaptador node) para a batalha de bancada com a
// GRELHA-MAPA — a sala nasce SEM tamanho na config (= o mapa inteiro, 50 × 50 de 1,5 m) e com o pacote do terreno.
// Ferramenta de prova (fora de cliente/ e de servidor/); o código do jogo não muda. Só fichas fictícias.
//
//   node bancada-servidor.mjs 8791
//
// A heroína nasce em TERRA a norte do lago (38,4); o Mestre (bancada-mestre.mjs) põe o orc DENTRO do lago (38,11).
import { readFileSync } from 'node:fs';
import { criarSala } from '../../../../rascunhos/servidor/nucleo/sala.js';
import { criarServidor, rngNode } from '../../../../rascunhos/servidor/adaptadores/node/servidor-ws.js';
import { criarMotorFalso } from '../../../../rascunhos/servidor/testes/motor-falso.mjs';
import { fichasDeTeste, INICIATIVA, PIN, SENHAS } from '../../../../rascunhos/servidor/testes/ajudantes.mjs';

const porta = Number(process.argv[2] ?? 8791);
const terreno = JSON.parse(readFileSync(new URL('../../../../rascunhos/servidor/dados/terreno-floresta.json', import.meta.url), 'utf8'));
const sala = criarSala({
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
const servidor = criarServidor({ sala, registo: (t) => console.log('[servidor]', t) });
servidor.listen(porta, '127.0.0.1', () => console.log(`pronto-bancada ${porta}`));
