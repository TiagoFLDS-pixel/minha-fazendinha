extends CanvasLayer

@onready var painel: Panel = $Painel
@onready var lista: VBoxContainer = $Painel/Lista
@onready var fechar_button: Button = $Painel/FecharButton

var _canteiro_alvo: Node = null


func _ready() -> void:
	painel.visible = false
	fechar_button.pressed.connect(fechar)


func abrir(canteiro: Node) -> void:
	_canteiro_alvo = canteiro

	for filho in lista.get_children():
		filho.queue_free()

	var alguma_semente := false

	for cultura in Culturas.get_todas():
		var quantidade := Inventario.get_quantity("semente_%s" % cultura.id)
		if quantidade <= 0:
			continue

		alguma_semente = true

		var botao := Button.new()
		botao.text = "%s (sementes: %d)" % [cultura.nome, quantidade]
		botao.pressed.connect(escolher.bind(cultura))
		lista.add_child(botao)

	if not alguma_semente:
		var aviso := Label.new()
		aviso.text = "Sem sementes. Compre na Loja (Armazém)."
		lista.add_child(aviso)

	painel.visible = true


func fechar() -> void:
	painel.visible = false
	_canteiro_alvo = null


func escolher(cultura: Cultura) -> void:
	if _canteiro_alvo:
		_canteiro_alvo.plantar_cultura(cultura)
	fechar()
