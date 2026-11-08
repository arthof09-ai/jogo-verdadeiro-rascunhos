// Corrida de ponta a ponta do ecrã do Mestre (I0004, 08/11/2026): o servidor de verdade (WebSocket do
// adaptador node, sem bibliotecas) com o motor FALSO e as fichas fictícias dos testes.
//
//   node e2e/servidor-e2e.mjs 8765
//
// O motor falso devolve sempre falha crítica nos ataques: o golpe da heroína abre um cartão de desgraça,
// que o Mestre (o cliente Godot, testes/e2e_mestre.gd) tem de confirmar pela ligação de verdade.
// Só fichas fictícias; nada do Mestre real.
import { criarSala } from '../nucleo/sala.js';
import { criarServidor, rngNode } from '../adaptadores/node/servidor-ws.js';
import { criarMotorFalso } from '../testes/motor-falso.mjs';
import { fichasDeTeste, INICIATIVA, PIN, SENHAS } from '../testes/ajudantes.mjs';

const porta = Number(process.argv[2] ?? 8765);
const motor = criarMotorFalso({ resultado: 'falha_critica' });
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
