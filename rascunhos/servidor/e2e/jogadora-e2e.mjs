// A jogadora da corrida de ponta a ponta (I0004, 08/11/2026): um cliente WebSocket em Node (o WebSocket
// global do Node ≥ 22) que entra como a heroína, espera o orc que o Mestre coloca ao lado dela e ataca.
// O golpe abre um cartão de desgraça; o recibo dela fica AGUARDANDO_MESTRE até o Mestre (o cliente Godot)
// o confirmar, e depois APLICADA. No fim espera o «voltar» do Mestre (evento revertido).
// Confere também a privacidade no fio: nenhum canário do Mestre chega a ela.
//
//   node e2e/jogadora-e2e.mjs 8765
//
// Código de saída 0 se tudo acontecer antes do tempo limite (120 s), 1 se não.
import { randomUUID } from 'node:crypto';
import { SENHAS } from '../testes/ajudantes.mjs';

const porta = Number(process.argv[2] ?? 8765);
const CANARIOS = ['Orc Verdadeiro', '7777', 'CANARIO-DESGRACA', 'CANARIO-FANTASMA', '9137'];
const marcos = [];
const marcar = (t) => {
  if (!marcos.includes(t)) {
    marcos.push(t);
    console.log(`[jogadora] ${t}`);
  }
};
let revision = 0;
let minha = null;
let orc = null;
let vez = null;
let ataqueId = null;
let atacou = false;
const recebido = [];

const limite = setTimeout(() => {
  console.error('[jogadora] FALHA: tempo esgotado; marcos: ' + marcos.join(' → '));
  process.exit(1);
}, 120000);

function ligar() {
  const ws = new WebSocket(`ws://127.0.0.1:${porta}/ws`);
  ws.onopen = () => ws.send(JSON.stringify({
    v: 2, type: 'ROOM_JOIN', papel: 'jogadora', nome: 'Heroína Teste', senha: SENHAS.heroina, cliente: 'e2e-jogadora',
  }));
  ws.onerror = () => {};
  ws.onclose = () => {
    if (!marcos.includes('voltar visto')) setTimeout(ligar, 500); // o servidor pode ainda não estar de pé
  };
  ws.onmessage = (ev) => {
    const texto = String(ev.data);
    recebido.push(texto);
    const m = JSON.parse(texto);
    if (Number.isInteger(m.revision) && m.revision > revision) revision = m.revision;
    if (m.type === 'ROOM_WELCOME') marcar('entrou');
    if (m.type === 'ROOM_SNAPSHOT') {
      if (m.propria) minha = m.propria.figuraId;
      vez = m.vezId;
      const o = (m.figuras ?? []).find((f) => f.nomePublico === 'Orc');
      if (o) orc = o.id;
    }
    if (m.type === 'ROOM_EVENT') {
      if (m.tipo === 'colocacao' && m.dados?.nomePublico === 'Orc') orc = m.dados.figuraId;
      if (m.tipo === 'turno' && m.dados?.figuraId) vez = m.dados.figuraId;
      if (m.tipo === 'revertido') marcar('voltar visto');
    }
    if ((m.type === 'ROOM_RECEIPT' || m.type === 'ROOM_REJECT') && m.intentId === ataqueId) {
      marcar(`recibo do ataque: ${m.estado ?? m.motivo}`);
      if (m.estado === 'APLICADA') marcar('o Mestre decidiu a desgraça');
    }
    if (minha && orc && !atacou && vez === minha) {
      atacou = true;
      ataqueId = randomUUID();
      marcar('o orc está na mesa e é a vez dela: ataca');
      ws.send(JSON.stringify({
        v: 2, type: 'ROOM_INTENT', roomId: m.roomId, intentId: ataqueId, revision,
        acao: { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' },
      }));
    }
    if (marcos.includes('o Mestre decidiu a desgraça') && marcos.includes('voltar visto')) {
      const tudo = recebido.join('\n');
      const vazados = CANARIOS.filter((c) => tudo.includes(c));
      if (vazados.length) {
        console.error('[jogadora] FALHA: canários do Mestre no fio dela: ' + vazados.join(', '));
        process.exit(1);
      }
      console.log(`[jogadora] OK: ${recebido.length} mensagens, nenhum canário do Mestre; marcos: ${marcos.join(' → ')}`);
      clearTimeout(limite);
      process.exit(0);
    }
  };
}
ligar();
