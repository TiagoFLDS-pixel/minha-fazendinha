extends Node

## Autoload "SaveManager": persistência local em JSON (user://savegame.json).
## Salva o inventário (moedas + items) e, de cada canteiro do grupo
## "canteiros", só o timestamp de plantio — o estágio nunca é salvo
## diretamente, é sempre recalculado a partir da hora real (ver
## canteiro_01.gd:calcular_estado), então tempo real passado com o jogo
## fechado é refletido corretamente ao reabrir.

const CAMINHO_SAVE := "user://savegame.json"
const VERSAO_SAVE_ATUAL := 2

var intervalo_autosave := 30.0
var _tempo_desde_ultimo_save := 0.0

## Desligado pelo menu inicial: sem canteiros nem save carregado, gravar
## escreveria um save falso (ou apagaria o verdadeiro). Ligado ao abrir a fazenda.
var gravacao_ativa := true


func _ready() -> void:
	get_tree().auto_accept_quit = false


func _process(delta: float) -> void:
	_tempo_desde_ultimo_save += delta
	if _tempo_desde_ultimo_save >= intervalo_autosave:
		_tempo_desde_ultimo_save = 0.0
		salvar()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		salvar()
		get_tree().quit()


func salvar() -> void:
	if not gravacao_ativa:
		return

	var dados := {
		"versao": VERSAO_SAVE_ATUAL,
		"moedas": Inventario.moedas,
		"items": Inventario.items,
		"xp": Inventario.xp,
		"marcos": Inventario.marcos,
		"fazenda": {},
		"construcoes": {},
		"canteiros": {},
	}

	var fazenda := get_tree().get_first_node_in_group("fazenda")
	if fazenda and fazenda.has_method("obter_save_data"):
		dados["fazenda"] = fazenda.obter_save_data()

	for construcao in get_tree().get_nodes_in_group("construcoes"):
		if construcao.has_method("obter_save_data"):
			dados["construcoes"][String(construcao.id_construcao)] = construcao.obter_save_data()

	for canteiro in get_tree().get_nodes_in_group("canteiros"):
		dados["canteiros"][canteiro.name] = canteiro.obter_save_data()

	var arquivo := FileAccess.open(CAMINHO_SAVE, FileAccess.WRITE)
	if arquivo == null:
		push_warning("Não foi possível salvar o jogo em %s" % CAMINHO_SAVE)
		return

	arquivo.store_string(JSON.stringify(dados))
	arquivo.close()


func carregar() -> void:
	if not FileAccess.file_exists(CAMINHO_SAVE):
		return

	var arquivo := FileAccess.open(CAMINHO_SAVE, FileAccess.READ)
	if arquivo == null:
		return

	var texto := arquivo.get_as_text()
	arquivo.close()

	var resultado: Variant = JSON.parse_string(texto)
	if typeof(resultado) != TYPE_DICTIONARY:
		push_warning("Save corrompido ou em formato inesperado, ignorando.")
		return

	var dados: Dictionary = resultado
	var save_antigo := int(dados.get("versao", 0)) < VERSAO_SAVE_ATUAL

	Inventario.moedas = int(dados.get("moedas", Inventario.moedas))

	var items: Variant = dados.get("items")
	if typeof(items) == TYPE_DICTIONARY:
		var items_convertidos: Dictionary = {}
		for chave in (items as Dictionary).keys():
			items_convertidos[chave] = int(items[chave])
		Inventario.items = items_convertidos

	Inventario.xp = int(dados.get("xp", 0))
	var marcos: Variant = dados.get("marcos")
	if typeof(marcos) == TYPE_DICTIONARY:
		var marcos_convertidos: Dictionary = {}
		for chave in (marcos as Dictionary).keys():
			marcos_convertidos[chave] = int(marcos[chave])
		Inventario.marcos = marcos_convertidos

	var fazenda_salva: Variant = dados.get("fazenda")
	var fazenda := get_tree().get_first_node_in_group("fazenda")
	if typeof(fazenda_salva) == TYPE_DICTIONARY and fazenda and fazenda.has_method("aplicar_save_data"):
		fazenda.aplicar_save_data(fazenda_salva)

	var construcoes_salvas: Variant = dados.get("construcoes")
	if typeof(construcoes_salvas) == TYPE_DICTIONARY:
		for construcao in get_tree().get_nodes_in_group("construcoes"):
			var id := String(construcao.id_construcao)
			if (construcoes_salvas as Dictionary).has(id) and construcao.has_method("aplicar_save_data"):
				construcao.aplicar_save_data(construcoes_salvas[id])

	# Saves anteriores não continham a recuperação inicial. A migração mantém
	# as construções que já apareciam no cenário como concluídas e nunca concede
	# novamente a recompensa de XP.
	if save_antigo and fazenda and fazenda.has_method("migrar_save_antigo"):
		fazenda.migrar_save_antigo()

	var canteiros_salvos: Variant = dados.get("canteiros")
	if typeof(canteiros_salvos) != TYPE_DICTIONARY:
		return

	for canteiro in get_tree().get_nodes_in_group("canteiros"):
		if (canteiros_salvos as Dictionary).has(canteiro.name):
			canteiro.aplicar_save_data(canteiros_salvos[canteiro.name])
