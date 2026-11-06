// Motor FALSO, determinista, com a mesma forma de saída que a porta dos motores descreve
// (publico.recibo + soDoMestre.alvoDepois). NÃO é o VLAB: não testa regra, testa o servidor.
//
// De propósito, o `publico.recibo` deste falso traz campos que NUNCA podem chegar à Party
// (ca, rd, semente, vidaDepois, campoNovoDoMotor=9137...). Se a projeção os deixar passar,
// os testes de privacidade apanham-nos.

export function criarMotorFalso(opcoes = {}) {
  // cfg é mutável: os testes mudam cfg.resultado / cfg.erro entre passos.
  const cfg = { resultado: 'acerto', dano: 1176, erro: null, ...opcoes };
  const chamadas = [];

  const Vlab = {
    resolverAtaque(entrada) {
      chamadas.push(JSON.parse(JSON.stringify(entrada)));
      const { alvo, tecnica, contexto } = entrada;
      if (cfg.erro) return { erro: cfg.erro };
      const resultado = typeof cfg.resultado === 'function' ? cfg.resultado(entrada) : cfg.resultado;
      const face = Array.isArray(contexto.faces) && contexto.faces.length ? contexto.faces[0] : 1 + (contexto.semente % 20);
      const total = face + 5;
      const defesa = alvo.defesaAplicavel?.valor ?? alvo.ca;
      const recibo = {
        eventId: 'pagina-' + chamadas.length, // como o contadorEventos do DMG real
        total, faces: [face], defesa, ca: alvo.ca ?? null, rd: alvo.rd, bonusCD: alvo.bonusCD ?? null,
        paTotal: alvo.paTotal, semente: contexto.semente, vidaDepois: null,
        campoNovoDoMotor: 9137, // canário: campo novo do motor que não está na lista permitida
      };
      const base = {
        resultado, totalEfectivo: total, rolagem: { faces: [face], expressao: tecnica.expressaoAtaque },
        publico: { recibo }, soDoMestre: {},
      };
      if (resultado === 'falha_critica') {
        if (contexto.modoDesgraca === 'proposta') {
          return {
            ...base, danoAplicado: 0,
            falhaCritica: { requerConfirmacao: true, desgracaProposta: { tipo: 'arma-cai', texto: 'CANARIO-DESGRACA' } },
          };
        }
        const d = contexto.modoDesgraca === 'escolha' ? contexto.desgracaEscolhida : 'cai';
        return { ...base, danoAplicado: 0, falhaCritica: { desgraca: d } };
      }
      if (resultado === 'erro') return { ...base, danoAplicado: 0 };
      const vidaDepois = alvo.vidaActual - cfg.dano;
      recibo.vidaDepois = vidaDepois;
      return { ...base, danoAplicado: cfg.dano, soDoMestre: { alvoDepois: { vidaActual: vidaDepois } } };
    },
    validarCorrer({ deslocamentoBase }) {
      return { valido: true, deslocamentoM: deslocamentoBase * 2 };
    },
    resolverTesteDeMorte() {
      return { soDoMestre: { moribundoDepois: { estadoMorte: { fase: 'estabilizado', sucessos: 3, falhas: 0 } } } };
    },
    resolverSalvaguarda() {
      return { erro: 'NAO_IMPLEMENTADO_NO_FALSO' };
    },
    aplicarCura() {
      return { erro: 'NAO_IMPLEMENTADO_NO_FALSO' };
    },
    validarForcarPassagem() {
      return { valido: false };
    },
    validarSaidaDeAdjacencia() {
      return { valido: true };
    },
  };

  const Dmg = {
    calcularDano() {
      return { erro: 'NAO_IMPLEMENTADO_NO_FALSO' };
    },
    BANDAS_DME: {},
    converterDmeParaDados() {
      return { expressao: '1d6' };
    },
  };

  return { Dmg, Vlab, MOTOR_SHA256: 'falso'.padEnd(64, '0'), DMG_VERSAO: 'falso-0', LEVELUP_SHA: null, chamadas, cfg };
}
