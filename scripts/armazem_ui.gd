extends CanvasLayer

@onready var painel: Panel = $Painel
@onready var moedas_label: Label = $Painel/MoedasLabel
@onready var lista: VBoxContainer = $Painel/Lista
@onready var loja_button: Button = $Painel/LojaButton
@onready var fechar_button: Button = $Painel/FecharButton
@onready var loja_ui: CanvasLayer = $"../LojaUI"


func _ready() -> void:
	painel.visible = false
	loja_button.pressed.connect(abrir_loja)
	fechar_button.pressed.connect(fechar)


func abrir() -> void:
	# Fecha a loja se estiver aberta
	loja_ui.fechar()
	atualizar()
	painel.visible = true


func fechar() -> void:
	painel.visible = false


func abrir_loja() -> void:
	painel.visible = false
	loja_ui.abrir()


func atualizar() -> void:
	moedas_label.text = "Moedas: %d" % Inventario.moedas

	for filho in lista.get_children():
		filho.queue_free()

	var linhas := 0
	for id in Inventario.items.keys():
		var quantidade: int = Inventario.items[id]
		if quantidade <= 0:
			continue
		var linha := Label.new()
		linha.text = "%s: %d" % [_nome_do_item(String(id)), quantidade]
		lista.add_child(linha)
		linhas += 1

	if linhas == 0:
		var vazio := Label.new()
		vazio.text = "Estoque vazio."
		lista.add_child(vazio)


func _nome_do_item(id: String) -> String:
	if id.begins_with("semente_"):
		var da_semente := Culturas.get_cultura(id.trim_prefix("semente_"))
		if da_semente:
			return "Sementes de %s" % da_semente.nome
		return id.capitalize()

	var produto := Culturas.get_cultura(id)
	if produto:
		return produto.nome
	return id.capitalize()
