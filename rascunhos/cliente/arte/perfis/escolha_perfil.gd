extends RefCounted
## escolha_perfil.gd — Ordem 52. A ESCOLHA do perfil gráfico nas definições, num só sítio. Antes vivia só no HUD da
## jogadora (hud/hud.gd, a ⚙: lista, nomes, ficheiro, linha «Gráficos»). Tirou-se de lá sem mudar um valor, para o
## ecrã do Mestre escolher pelo MESMO caminho em vez de uma cópia:
##
##   - `PERFIS` / `NOMES`    os três perfis da ⚙ e os nomes que se lêem («Baixo», «Médio», «Alto»);
##   - `ARQ` / `SECCAO` / `CHAVE`  onde a escolha fica guardada: user://preferencias.cfg, [pref] perfil;
##   - `seletor()`           o OptionButton «Gráficos» (os mesmos itens nas duas ⚙);
##   - `escolhido()`         o perfil guardado, ou "" se ninguém escolheu (sem ficheiro, sem chave, nome estranho);
##   - `guardar(nome)`       escreve a escolha na mesma chave, sem tocar nas outras preferências do ficheiro.
##
## O que cada perfil FAZ é do AplicadorPerfil (arte/perfis/aplicar_perfil.gd, a tabela única). Isto é só a escolha.
## Não lê Estado, Rede nem nada do Mestre.

const PERFIS: Array[String] = ["baixo", "medio", "alto"]
const NOMES: Array[String] = ["Baixo", "Médio", "Alto"]
const ARQ := "user://preferencias.cfg"
const SECCAO := "pref"
const CHAVE := "perfil"


## A linha «Gráficos» da ⚙: um OptionButton com os três perfis, por esta ordem, sem nenhum marcado (quem o monta
## marca o que lhe cabe e liga o item_selected; o índice é o de PERFIS).
static func seletor() -> OptionButton:
	var op := OptionButton.new()
	for i in NOMES.size():
		op.add_item(NOMES[i], i)
	op.select(-1)
	return op


## O perfil que ficou escolhido nas definições ("baixo", "medio" ou "alto"), ou "" se não há escolha guardada.
static func escolhido(arq: String = ARQ) -> String:
	var cfg := ConfigFile.new()
	if cfg.load(arq) != OK or not cfg.has_section_key(SECCAO, CHAVE):
		return ""
	var nome := AplicadorPerfil.normalizar(str(cfg.get_value(SECCAO, CHAVE, "")))
	return nome if PERFIS.has(nome) else ""


## Guarda a escolha na mesma chave da ⚙ da jogadora, deixando o resto do ficheiro como estava.
static func guardar(nome: String, arq: String = ARQ) -> bool:
	var chave := AplicadorPerfil.normalizar(nome)
	if not PERFIS.has(chave):
		return false
	var cfg := ConfigFile.new()
	cfg.load(arq)  # sem ficheiro: começa vazio
	cfg.set_value(SECCAO, CHAVE, chave)
	return cfg.save(arq) == OK
