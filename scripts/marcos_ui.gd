extends PainelFazenda

## Painel de Marcos: para cada cultura, os estágios broto, adulta e pronta.
## Um estágio fica disponível (a saltar) quando uma planta passa por ele pela
## primeira vez; ao clicar, o jogador recebe XP (3× o XP da colheita) e o
## estágio passa a colorido, com fundo verde e visto.

const COLUNAS := 4
const ESTAGIOS := [[2, "broto", "Broto"], [3, "adulta", "Adulta"], [4, "pronta", "Pronta"]]
const VISTO := preload("res://resources/ui/visto.png")
const CIRCULO := preload("res://resources/ui/circulo.png")

@onready var armazem_ui: CanvasLayer = $"../ArmazemUI"

var _grelha: GridContainer
var _xp_label: Label


func _ready() -> void:
	_construir_moldura("Marcos", "As culturas que já conquistou na fazenda")

	var scroll := ScrollContainer.new()
	scroll.size = Vector2(AREA.size.x, AREA.size.y - 64)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	conteudo.add_child(scroll)

	_grelha = GridContainer.new()
	_grelha.columns = COLUNAS
	_grelha.add_theme_constant_override("h_separation", 12)
	_grelha.add_theme_constant_override("v_separation", 12)
	scroll.add_child(_grelha)

	var barra := HBoxContainer.new()
	barra.position = Vector2(0, AREA.size.y - 52)
	barra.size = Vector2(AREA.size.x, 50)
	conteudo.add_child(barra)

	var voltar := Button.new()
	voltar.text = "Armazém"
	voltar.custom_minimum_size = Vector2(170, 48)
	voltar.add_theme_font_size_override("font_size", 24)
	voltar.add_theme_color_override("font_color", COR_TITULO)
	var estilo := estilo_cartao(Color(0.74, 0.45, 0.2), Color(0.45, 0.24, 0.08), 3)
	voltar.add_theme_stylebox_override("normal", estilo)
	voltar.add_theme_stylebox_override("hover", estilo_cartao(Color(0.82, 0.52, 0.25), Color(0.45, 0.24, 0.08), 3))
	voltar.add_theme_stylebox_override("pressed", estilo)
	voltar.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	voltar.pressed.connect(_voltar_armazem)
	barra.add_child(voltar)

	var espaco := Control.new()
	espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra.add_child(espaco)

	_xp_label = Label.new()
	_xp_label.add_theme_font_size_override("font_size", 26)
	_xp_label.add_theme_color_override("font_color", COR_TEXTO)
	barra.add_child(_xp_label)


func abrir() -> void:
	atualizar()
	raiz.visible = true


func fechar() -> void:
	fechar_painel()


func _voltar_armazem() -> void:
	fechar()
	armazem_ui.abrir()


func atualizar() -> void:
	_xp_label.text = "XP: %d" % Inventario.xp
	for filho in _grelha.get_children():
		filho.queue_free()
	for cultura in Culturas.get_todas():
		_grelha.add_child(_criar_grupo(cultura))


func _criar_grupo(cultura: Cultura) -> PanelContainer:
	var algum_recebido := false
	for e in ESTAGIOS:
		if Inventario.estado_marco(cultura.id, e[0]) == Inventario.MARCO_RECEBIDO:
			algum_recebido = true

	var grupo := PanelContainer.new()
	grupo.custom_minimum_size = Vector2(336, 0)
	if algum_recebido:
		grupo.add_theme_stylebox_override("panel", estilo_cartao(Color(0.87, 0.96, 0.81), Color(0.6, 0.83, 0.48)))
	else:
		grupo.add_theme_stylebox_override("panel", estilo_cartao(Color(0.98, 0.9, 0.82), Color(0.91, 0.8, 0.69)))

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 4)
	grupo.add_child(coluna)

	var nome := Label.new()
	nome.text = cultura.nome
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.add_theme_font_size_override("font_size", 22)
	nome.add_theme_color_override("font_color", COR_TEXTO)
	coluna.add_child(nome)

	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 6)
	coluna.add_child(linha)
	for e in ESTAGIOS:
		linha.add_child(_criar_estagio(cultura, e[0], e[1], e[2]))
	return grupo


func _criar_estagio(cultura: Cultura, estado: int, sufixo: String, rotulo: String) -> Control:
	var marco := Inventario.estado_marco(cultura.id, estado)
	var recebido := marco == Inventario.MARCO_RECEBIDO
	var pendente := marco == Inventario.MARCO_PENDENTE

	var celula := VBoxContainer.new()
	celula.custom_minimum_size = Vector2(100, 0)
	celula.add_theme_constant_override("separation", 2)

	var caixa := Button.new()
	caixa.custom_minimum_size = Vector2(100, 100)
	caixa.focus_mode = Control.FOCUS_NONE
	var fundo := Color(1, 1, 1, 0.75) if not recebido else Color(0.95, 1, 0.92)
	var borda := Color(1.0, 0.78, 0.3) if pendente else Color(0.88, 0.84, 0.78)
	var est := estilo_cartao(fundo, borda, 4 if pendente else 1)
	est.shadow_size = 0
	for nome_estilo in ["normal", "hover", "pressed", "disabled"]:
		caixa.add_theme_stylebox_override(nome_estilo, est)
	caixa.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	caixa.disabled = not pendente
	if pendente:
		caixa.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		caixa.tooltip_text = "Clique para receber a recompensa"
		caixa.pressed.connect(_receber.bind(cultura, estado))
	celula.add_child(caixa)

	var imagem := TextureRect.new()
	imagem.texture = icone(cultura.id, sufixo)
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	imagem.offset_left = 8
	imagem.offset_top = 8
	imagem.offset_right = -8
	imagem.offset_bottom = -8
	imagem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	imagem.material = material_cinza(not recebido)
	if marco == 0:
		imagem.modulate = Color(1, 1, 1, 0.45)
	caixa.add_child(imagem)

	if pendente:
		imagem.pivot_offset = Vector2(42, 42)
		var salto := imagem.create_tween().set_loops()
		salto.tween_property(imagem, "scale", Vector2(1.15, 1.15), 0.4).set_trans(Tween.TRANS_SINE)
		salto.tween_property(imagem, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_SINE)

	var texto := Label.new()
	texto.text = rotulo
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.add_theme_font_size_override("font_size", 17)
	texto.add_theme_color_override("font_color", COR_TEXTO)
	celula.add_child(texto)

	var estado_icone := TextureRect.new()
	estado_icone.texture = VISTO if recebido else CIRCULO
	estado_icone.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	estado_icone.custom_minimum_size = Vector2(0, 36)
	celula.add_child(estado_icone)
	return celula


func _receber(cultura: Cultura, estado: int) -> void:
	var ganho := Inventario.receber_marco(cultura, estado)
	if ganho > 0:
		Avisos.mostrar("Marco conquistado! +%d XP" % ganho)
		SaveManager.salvar()
	atualizar()
