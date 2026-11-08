extends RefCounted
## Palavras visíveis do ecrã do Mestre (emenda 1 da revisão do Muse ao desenho JV3.1, 08/11/2026).
##
## Seguem as palavras da superfície do Mestre do site (jogo-t1/jogo.js vivo, REF_25, lido por sonda
## no CI): o Mestre autoriza com «Confirmar»; «Voltar» desiste; «Registo da batalha», «Exportar
## registo», «Voltar ao último estado bom», «Modo automático». E a regra de linguagem da casa:
## «aperta», «quebrar», «atualiza»; nada de «prime» nem «carregar» em texto visível.
##
## Tratamento: até à resposta do Mestre à pergunta 13 (tu ou você), os textos do Mestre ficam em
## forma neutra, sem verbo dirigido a ninguém.

# ---------------------------------------------------------------- botões dos cartões
const CONFIRMAR := "Confirmar"
const ESCOLHER_OUTRA := "Escolher outra"
## Recusar a desgraça aplica hoje «nenhuma» (PERGUNTA PARA O MESTRE 11). O rótulo muda com a resposta.
const SEM_DESGRACA := "Sem desgraça"
const JOGO_EU := "Jogo eu"
const ENCERRAR_A_VEZ := "Encerrar a vez"
const CONTINUAR := "Continuar"
## L6 (D4 do Plano A): numa proposta de marcha pura (andar ou encerrar), o Mestre deixa as marchas puras
## desta rodada seguir sem cartão. Os ataques continuam a pedir cartão.
const CONTINUAR_RODADA := "Continuar a rodada"
const NAO_ACEITAR := "Não aceitar"
const VOLTAR := "Voltar"
## Segundo toque (Escolher outra e Sem desgraça pedem confirmação).
const DE_NOVO_PARA := "De novo: %s"
const A_ENVIAR := "A enviar..."

# ---------------------------------------------------------------- títulos dos cartões
const TITULO := {
	"desgraca": "Falha crítica · desgraça por decidir",
	"ia": "Proposta da criatura",
	"progresso": "Duas recusas nesta vez",
	"dados": "Dados físicos por confirmar",
}
const SEM_CARTAO := "Nada por decidir."
const FILA := "+%d por decidir"
const A_PARTY_VAI_LER := "A Party vai ler: «%s»"
const PROPOSTA := "Proposta: %s"
const RAZAO := "Razão: %s"
const FACES := "Faces declaradas: %s"
const ENCERRAR_PERGUNTA := "Encerrar a vez de %s?"
const ESCOLHER_TITULO := "Escolher outra desgraça"

## Nomes das desgraças no «Escolher outra» (os ids são do motor e não se traduzem).
const NOME_DESGRACA := {
	"cai": "Cai ao chão",
	"arma-cai": "A arma cai",
	"arma-quebra": "A arma quebra",
	"acerta-se": "Atinge-se a si",
	"quebra-corpo": "Quebra algo no corpo",
	"acerta-amigo": "Atinge um aliado",  # PERGUNTA PARA O MESTRE 12: quem conta como amigo ao alcance
	"nenhuma": "Sem desgraça",
}

# ---------------------------------------------------------------- abas e secções
const ABA_FIGURAS := "Figuras"
const ABA_AMBIENTE := "Ambiente"
const ABA_REGISTO := "Registo da batalha"
## Nome curto na barra das abas (o título inteiro aparece dentro da aba): a barra nunca se corta.
const ABA_REGISTO_CURTA := "Registo"
const ABA_SALA := "Sala"
const EXPORTAR_REGISTO := "Exportar registo"
const REGISTO_EXPORTADO := "Registo exportado: %s"
const PAUSAR := "Pausar"
const ATUALIZAR := "Atualizar"
const SOM_LIGADO := "Aviso de cartão: ligado"
const SOM_DESLIGADO := "Aviso de cartão: desligado"
const PARTY_VE := "A Party vê: %s"
const HORA := "Hora: %s"
const CLIMA := "Clima: %s"
const FUTURO := "A seguir: %s"
const SEM_VALOR := "—"
const JOURNAL := "Ponto actual do registo: %d"

# ---------------------------------------------------------------- aba Agir (§12 do desenho)
const ABA_AGIR := "Agir"
const AGIR_SEM_VEZ := "Nada para jogar: não é a vez de uma criatura."
const AGIR_VEZ := "Vez de %s"
const AGIR_MODO := "Modo:"
const AGIR_EDITAR := "Escolher outra acção para a proposta da criatura (o cartão continua aberto até escolher)."
const AGIR_MARCHA_LIVRE := "Marchas puras livres nesta rodada («Continuar a rodada»)."
const AGIR_SEM_OPCOES := "As opções chegam do servidor quando a criatura está «À mão» (ou depois de «Jogo eu»)."
const MOVER := "Mover"
const MOVER_ESCOLHER := "Mover: escolher a casa no tabuleiro (%d casas)."
const ATACAR := "Atacar %s (%s)"
const CANCELAR := "Cancelar"
const NOME_ACAO := {
	"encerrar": "Encerrar a vez",
	"correr": "Correr",
	"defender": "Defender",
	"desvincular": "Sair com segurança",
	"transformar": "Transformação",
	"apanhar_arma": "Apanhar a arma",
}

# ---------------------------------------------------------------- aba Mesa (Lobby/Colocar)
const ABA_MESA := "Mesa"
const PROCURAR := "Procurar"
const PROCURAR_DICA := "Nome da criatura ou do NPC"
const NA_MESA := "Na mesa"
const GUARDAR_MESA := "Guardar a mesa"
const COMECAR := "Começar a batalha"
const COLOCAR := "Colocar %s"
const COLOCAR_ESCOLHER := "%s: escolher a casa no tabuleiro. Aparece à Party logo que for colocada."
const PARAR_COLOCAR := "Parar de colocar"
const RESULTADO := "%s · %s · %s"
const SEM_RESULTADOS := "Sem resultados."
const PAPEL_FICHA := {"criatura": "criatura", "npc": "NPC"}

# ---------------------------------------------------------------- esquema de colocação (L5, D5)
const MONTAR_ESQUEMA := "Montar esquema"
const ESQUEMA_LIGADO := "Esquema: cada casa tocada junta-se à lista (nada vai ao servidor até «Colocar o esquema»)."
const ESQUEMA := "Esquema: %d por colocar"
const COLOCAR_ESQUEMA := "Colocar o esquema"
const LIMPAR_ESQUEMA := "Limpar o esquema"
const ESQUEMA_PAROU := "O esquema parou: o servidor não aceitou uma colocação."

# ---------------------------------------------------------------- selo e estatísticas (L9, C-28)
const SELO := "[%s] "
const ESTATISTICAS := "Estatísticas (só o Mestre)"
const ESTAT_FIGURA := "%s: %d ataque(s) · dano causado %s · sofrido %s"
const ESTAT_CARTOES := "Cartões: %s"
const ESTAT_SEM := "Ainda sem ataques nem cartões."
const NOME_DECISAO := {"aprovar": "confirmados", "recusar": "recusados", "editar": "trocados", "aceitar": "dados aceites",
	"revertido": "desfeitos pelo voltar"}

# ---------------------------------------------------------------- «Voltar até aqui» (L8)
const PONTO := "Rodada %d · vez de %s · %s"
const PONTO_INICIO := "Início da sala"
const VOLTAR_PERGUNTA := "Voltar até aqui? Todos vão ver a batalha voltar a este ponto."
const VOLTAR_ATE_AQUI := "Voltar até aqui"
const SEM_PONTOS := "Ainda não há pontos para voltar."
const NOME_EVENTO := {
	"inicio": "início", "colocacao": "colocação", "turno": "vez nova", "movimento": "movimento",
	"ataque": "ataque", "dano": "dano", "desgraca": "desgraça", "cartao": "cartão", "cartao_fechado": "cartão decidido",
	"ambiente": "ambiente", "ambiente_mestre": "ambiente", "estado": "estado", "entrada": "entrada",
	"revertido": "voltar", "modo": "modo", "lobby": "mesa", "fim": "fim", "teste_morte": "teste de morte",
	"recusa": "recusa", "reacao": "reacção", "consumivel": "consumível", "pausa": "pausa", "retomada": "continuar",
}

# ---------------------------------------------------------------- estado da sala e alertas
const FASE := {"lobby": "Sala: à espera de começar", "combate": "Sala: em combate", "fim": "Sala: batalha acabada",
	"pausa": "Sala: em pausa"}
const RODADA_VEZ := "Rodada %d · vez de %s"
const ALERTAS := "Alertas: %d"
const ALERTA := {
	"bloqueio_join": "Muitas entradas erradas (%s).",
	"segunda_ligacao": "%s abriu outra ligação.",
	"ligacao": "A ligação caiu; a tentar de novo.",
	"pausa": "Sala em pausa.",
	"recusa": "O servidor não aceitou: %s",
	"sem_envio": "Sem ligação: o comando não saiu.",
}

# ---------------------------------------------------------------- figuras
const LADO := {"jogadora": "jogadora", "criatura": "criatura", "npc": "NPC"}
const MODO := {"manual": "À mão", "semi": "Com o meu Confirmar", "auto": "Automático"}
const VIDA := "vida %s/%s"
const PA := "PA %s/%s"
const NAO_COLOCADA := "não colocada"
const OCULTA := "oculta"
const CAIDA := "caída"
const MORTA := "morta"
const ARMA_CAIDA := "arma caída"
const ARMA_QUEBRADA := "arma quebrada"
const CORPO := "corpo quebrado"

# ---------------------------------------------------------------- aviso da primeira entrada (emenda 2)
const AVISO_PRIMEIRA := "Este ecrã é só do Mestre."
const ENTENDIDO := "Entendido"

# TODO(N4-TERMINAR): «Terminar/recomeçar a batalha» NÃO existe aqui. Depende da pergunta N4 ao Mestre
# (emenda 3 do Muse). No site existe o fim declarado (terminarBatalha, M-014: «Terminar» → «Sim,
# terminar» ou «Voltar»; o automático nunca termina sozinho). Sem resposta, não há botão nem comando.
