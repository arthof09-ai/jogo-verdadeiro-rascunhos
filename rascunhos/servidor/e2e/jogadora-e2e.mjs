// A jogadora da corrida de ponta a ponta (I0004, 08/11/2026): um cliente WebSocket em Node (o WebSocket
// global do Node ≥ 22) que entra como a heroína, espera o orc que o Mestre coloca ao lado dela e ataca.
// O golpe abre um cartão de desgraça; o recibo dela fica AGUARDANDO_MESTRE até o Mestre (o cliente Godot)
// o confirmar, e depois APLICADA. Depois segue o Mestre até ao fim do guião dele: o «voltar» (evento revertido e o
// snapshot do instante antigo), o «Terminar» (evento fim) e o «Recomeçar» (evento recomeco e o snapshot novo).
// Confere também a privacidade no fio: nenhum canário do Mestre chega a ela.
//
// Ordem 49 (B, achado M5 da Ordem 36): antes saía com 0 ao ver o evento do «voltar», e o snapshot do voltar, o fim e
// o recomeço nunca passavam pelos canários. Agora cada mensagem passa pelos canários ao chegar (uma fuga falha logo e
// diz a fase), e só sai com 0 depois de ver as três fases, cada uma com mensagens conferidas.
//
//   node e2e/jogadora-e2e.mjs 8765
//
// Código de saída 0 se tudo acontecer antes do tempo limite (120 s), 1 se não (ou se um canário chegar).
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
// Ordem 49 (B): a fase do guião em que cada mensagem chegou, e quantas se conferiram em cada uma.
const FASES = ['jogo', 'voltar', 'fim', 'recomeço'];
let fase = 'jogo';
const conferidas = Object.fromEntries(FASES.map((f) => [f, 0]));
let acabou = false;
// A transacção do «Recomeçar» manda o evento, o snapshot e as opções seguidas: espera um pouco pelas que faltam.
const FOLGA_FIM_MS = 500;
const GUIAO = ['o Mestre decidiu a desgraça', 'voltar visto', 'snapshot do voltar visto', 'fim visto', 'recomeço visto',
  'snapshot do recomeço visto'];

function falhar(texto) {
  console.error('[jogadora] FALHA: ' + texto + '; marcos: ' + marcos.join(' → '));
  process.exit(1);
}

function conferirCanarios(texto, onde) {
  const vazados = CANARIOS.filter((c) => texto.includes(c));
  if (vazados.length) falhar(`canários do Mestre no fio dela (${onde}): ${vazados.join(', ')}`);
}

function terminar() {
  conferirCanarios(recebido.join('\n'), 'tudo junto, no fim'); // a rede de trás
  const vazias = FASES.filter((f) => conferidas[f] === 0);
  if (vazias.length) falhar('fases sem mensagens conferidas: ' + vazias.join(', '));
  const resumo = FASES.map((f) => `${f} ${conferidas[f]}`).join(', ');
  console.log(`[jogadora] OK: ${recebido.length} mensagens, nenhum canário do Mestre (por fase: ${resumo}); `
    + `marcos: ${marcos.join(' → ')}`);
  clearTimeout(limite);
  process.exit(0);
}

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
    if (!acabou) setTimeout(ligar, 500); // o servidor pode ainda não estar de pé
  };
  ws.onmessage = (ev) => {
    const texto = String(ev.data);
    recebido.push(texto);
    const m = JSON.parse(texto);
    // Ordem 49 (B): a fase muda no evento que a abre; o snapshot e as opções da mesma transacção ficam nela.
    if (m.type === 'ROOM_EVENT' && m.tipo === 'revertido') fase = 'voltar';
    if (m.type === 'ROOM_EVENT' && m.tipo === 'fim' && fase === 'voltar') fase = 'fim';
    if (m.type === 'ROOM_EVENT' && m.tipo === 'recomeco') fase = 'recomeço';
    conferidas[fase] += 1;
    conferirCanarios(texto, `fase ${fase}, ${m.type}${m.tipo ? ' ' + m.tipo : ''}`);
    if (m.type === 'ROOM_SNAPSHOT' && fase === 'voltar') marcar('snapshot do voltar visto');
    if (m.type === 'ROOM_SNAPSHOT' && fase === 'recomeço') marcar('snapshot do recomeço visto');
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
      if (m.tipo === 'fim' && fase === 'fim') marcar('fim visto');
      if (m.tipo === 'recomeco') marcar('recomeço visto');
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
    if (!acabou && GUIAO.every((t) => marcos.includes(t))) {
      acabou = true;
      setTimeout(terminar, FOLGA_FIM_MS);
    }
  };
}
ligar();
