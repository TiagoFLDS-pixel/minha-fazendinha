class_name ConstrucaoUI
extends CanvasLayer

var _construcao: ConstrucaoEvolutiva
var _painel: PanelContainer
var _titulo: Label
var _estado: Label
var _modelo: OptionButton
var _cor: OptionButton
var _confirmar: Button


func _ready() -> void:
	layer = 40
	_criar_interface()
	visible = false


func abrir(construcao: ConstrucaoEvolutiva) -> void:
	_construcao = construcao
	_titulo.text = construcao.nome_exibicao
	_modelo.select(construcao.modelo_atual)
	_cor.select(construcao.cor_atual)
	_atualizar_estado()
	visible = true


func fechar() -> void:
	visible = false
	_construcao = null


func _criar_interface() -> void:
	_painel = PanelContainer.new()
	_painel.set_anchors_preset(Control.PRESET_CENTER)
	_painel.position = Vector2(-220, -180)
	_painel.custom_minimum_size = Vector2(440, 360)
	add_child(_painel)

	var margem := MarginContainer.new()
	margem.add_theme_constant_override("margin_left", 24)
	margem.add_theme_constant_override("margin_right", 24)
	margem.add_theme_constant_override("margin_top", 20)
	margem.add_theme_constant_override("margin_bottom", 20)
	_painel.add_child(margem)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 12)
	margem.add_child(coluna)

	_titulo = Label.new()
	_titulo.add_theme_font_size_override("font_size", 28)
	coluna.add_child(_titulo)

	_estado = Label.new()
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_estado.custom_minimum_size.y = 90
	coluna.add_child(_estado)

	_modelo = OptionButton.new()
	for nome in ConstrucaoEvolutiva.NOMES_MODELOS:
		_modelo.add_item(nome)
	coluna.add_child(_modelo)

	_cor = OptionButton.new()
	for nome in ConstrucaoEvolutiva.NOMES_CORES:
		_cor.add_item(nome)
	coluna.add_child(_cor)

	_confirmar = Button.new()
	_confirmar.text = "Construir"
	_confirmar.pressed.connect(_on_confirmar)
	coluna.add_child(_confirmar)

	var cancelar := Button.new()
	cancelar.text = "Fechar"
	cancelar.pressed.connect(fechar)
	coluna.add_child(cancelar)


func _atualizar_estado() -> void:
	if _construcao == null:
		return
	_estado.text = _construcao.descricao_requisitos()
	var construida := _construcao.estado_atual == ConstrucaoEvolutiva.Estado.CONSTRUIDA
	_confirmar.text = "Aplicar personalização" if construida else "Construir"
	_confirmar.disabled = not construida and not _construcao.pode_construir()


func _on_confirmar() -> void:
	if _construcao == null:
		return
	var modelo := _modelo.get_selected_id()
	var cor := _cor.get_selected_id()
	if _construcao.estado_atual == ConstrucaoEvolutiva.Estado.CONSTRUIDA:
		_construcao.definir_personalizacao(modelo, cor)
	else:
		_construcao.concluir_construcao(modelo, cor)
	_atualizar_estado()
