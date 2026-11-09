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
  const chamadasCura = [];

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
        resultado, totalEfectivo: total, rolagem: { faces: [face], expressao: tecnica.expressaoAtaque, total },
        publico: { recibo }, soDoMestre: {},
      };
      if (resultado === 'falha_critica') {
        if (contexto.modoDesgraca === 'proposta') {
          return {
            ...base, danoAplicado: 0,
            falhaCritica: { requerConfirmacao: true, desgracaProposta: { tipo: 'arma-cai', texto: 'CANARIO-DESGRACA' } },
          };
        }
        const d = contexto.modoDesgraca === 'escolha' ? contexto.desgracaEscolhida : (cfg.desgraca ?? 'cai');
        const tipos = Array.isArray(tecnica.tipos) ? tecnica.tipos : tecnica.tipo ? [tecnica.tipo] : [];
        const derivado = cfg.danoDerivado ?? cfg.dano; // o falso não rola: o «DMG» do dano derivado é este número
        if (d === 'acerta-amigo') {
          // Como o VLAB real: só os elegíveis (adjacente | naLinha); o declarado ou o primeiro da lista.
          const eleg = (contexto.aliadosAoAlcance ?? []).filter((x) => x && x.id && (x.posicao === 'adjacente' || x.posicao === 'naLinha'));
          const aliado = contexto.aliadoAtingidoId ? eleg.find((x) => x.id === contexto.aliadoAtingidoId) : eleg[0];
          if (!aliado) return { erro: contexto.aliadoAtingidoId ? 'ALIADO_ATINGIDO_NAO_ELEGIVEL' : 'DESGRACA_NAO_APLICAVEL' };
          return {
            ...base, danoAplicado: 0, totalEfectivo: 0, falhaCritica: { desgraca: d, aplicado: true },
            desgracaPendente: { tipo: 'acertaAmigo', aliadoId: aliado.id, danoBruto: derivado, danoAntesDaRD: Math.floor(derivado / 2), tipos, reflectivel: false, verificavel: false },
          };
        }
        if (d === 'acerta-se' && cfg.acertaSePendente) {
          return {
            ...base, danoAplicado: 0, totalEfectivo: 0, falhaCritica: { desgraca: d, aplicado: true },
            desgracaPendente: { tipo: 'acertaSiProprio', danoBruto: derivado, danoAntesDaRD: Math.floor(derivado / 2), tipos, reflectivel: false, verificavel: false },
          };
        }
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
    // Ordem 7: a cura do falso segue as recusas e a forma de saída do VLAB real (site REF_31, aplicarCura), mas não rola:
    // a face é cfg.faceCura e o total é cfg.cura. O total vai SÓ em soDoMestre (curaRolada:null no topo, como o real).
    aplicarCura(entrada) {
      chamadasCura.push(JSON.parse(JSON.stringify(entrada)));
      const falha = (codigo) => ({ curaRolada: null, publico: null, soDoMestre: null, erro: { codigo } });
      const { origem, quemCura, alvo, expressaoCura } = entrada || {};
      if (!origem || !origem.nome) return falha('CURA_SEM_ORIGEM');
      const fase = alvo?.estadoMorte?.fase;
      if (alvo.vidaActual <= 0) {
        if (fase === 'aMorrer') return falha('CURA_SOBRE_QUEM_ESTA_A_MORRER');
        if (fase !== 'estabilizado') return falha('CURA_NAO_RESSUSCITA');
      }
      if (alvo.vidaActual >= alvo.vidaTotal) return falha('CURA_ALVO_VIDA_CHEIA');
      const custo = Number.isInteger(entrada.custoPA) ? entrada.custoPA : 0;
      if (!Number.isFinite(quemCura?.paLivre)) return falha('PA_EM_FALTA');
      if (quemCura.paLivre < custo) return falha('PA_INSUFICIENTE');
      const curaRolada = cfg.cura ?? 7;
      const efectiva = Math.min(curaRolada, alvo.vidaTotal - alvo.vidaActual);
      const eraEstabilizado = fase === 'estabilizado' && alvo.vidaActual <= 0;
      return {
        curaRolada: null,
        publico: { recibo: `cura ${expressaoCura} → [${cfg.faceCura ?? 5}] (origem: ${origem.nome})` },
        soDoMestre: {
          curaRolada, curaEfectiva: efectiva, excesso: curaRolada - efectiva,
          pa: { custo, paLivreAntes: quemCura.paLivre, paLivreDepois: quemCura.paLivre - custo, exaustaoEspiritual: false },
          alvoDepois: { vidaActual: alvo.vidaActual + efectiva, estadosRemovidos: [], ...(eraEstabilizado ? { estadoMorte: null } : {}) },
        },
        erro: null,
      };
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

  return { Dmg, Vlab, MOTOR_SHA256: 'falso'.padEnd(64, '0'), DMG_VERSAO: 'falso-0', LEVELUP_SHA: null, chamadas, chamadasCura, cfg };
}
