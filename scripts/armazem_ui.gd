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

	if Inventario.items.is_empty():
		var vazio := Label.new()
		vazio.text = "Estoque vazio."
		lista.add_child(vazio)
		return

	for id in Inventario.items.keys():
		var linha := Label.new()
		linha.text = "%s: %d" % [String(id).capitalize(), Inventario.items[id]]
		lista.add_child(linha)
