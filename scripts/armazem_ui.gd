extends PainelFazenda

## Painel do Armazém: uma carta por cultura com a quantidade guardada.
## Culturas que o jogador ainda não teve aparecem a cinzento com cadeado.

const COLUNAS := 5
const CADEADO := preload("res://resources/ui/cadeado.png")

@onready var loja_ui: CanvasLayer = $"../LojaUI"
@onready var marcos_ui: CanvasLayer = $"../MarcosUI"

var _grelha: GridContainer
var _moedas_label: Label
var _marcos_button: Button
var _pulso_marcos: Tween


func _ready() -> void:
	_construir_moldura("Armazém", "Guarde aqui as colheitas da sua fazenda!")

	var scroll := ScrollContainer.new()
	scroll.size = Vector2(AREA.size.x, AREA.size.y - 64)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	conteudo.add_child(scroll)

	_grelha = GridContainer.new()
	_grelha.columns = COLUNAS
	_grelha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grelha.add_theme_constant_override("h_separation", 14)
	_grelha.add_theme_constant_override("v_separation", 14)
	scroll.add_child(_grelha)

	var barra := HBoxContainer.new()
	barra.position = Vector2(0, AREA.size.y - 52)
	barra.size = Vector2(AREA.size.x, 50)
	barra.add_theme_constant_override("separation", 14)
	conteudo.add_child(barra)

	var loja := _botao("Loja")
	loja.pressed.connect(abrir_loja)
	barra.add_child(loja)

	_marcos_button = _botao("Marcos")
	_marcos_button.pressed.connect(abrir_marcos)
	barra.add_child(_marcos_button)

	var espaco := Control.new()
	espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra.add_child(espaco)

	_moedas_label = Label.new()
	_moedas_label.add_theme_font_size_override("font_size", 26)
	_moedas_label.add_theme_color_override("font_color", COR_TEXTO)
	_moedas_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	barra.add_child(_moedas_label)

	Inventario.marcos_mudaram.connect(_atualizar_botao_marcos)


func _botao(texto: String) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(170, 48)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", COR_TITULO)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	var normal := estilo_cartao(Color(0.74, 0.45, 0.2), Color(0.45, 0.24, 0.08), 3)
	var hover := estilo_cartao(Color(0.82, 0.52, 0.25), Color(0.45, 0.24, 0.08), 3)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", normal)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b


func abrir() -> void:
	loja_ui.fechar()
	marcos_ui.fechar()
	atualizar()
	raiz.visible = true


func fechar() -> void:
	fechar_painel()


func abrir_loja() -> void:
	fechar()
	loja_ui.abrir()


func abrir_marcos() -> void:
	fechar()
	marcos_ui.abrir()


func atualizar() -> void:
	_moedas_label.text = "Moedas: %d     XP: %d" % [Inventario.moedas, Inventario.xp]
	_atualizar_botao_marcos()

	for filho in _grelha.get_children():
		filho.queue_free()
	for cultura in Culturas.get_todas():
		_grelha.add_child(_criar_carta(cultura))


func _atualizar_botao_marcos() -> void:
	if _marcos_button == null:
		return
	var pendentes := Inventario.contar_marcos_pendentes()
	_marcos_button.text = "Marcos (%d)" % pendentes if pendentes > 0 else "Marcos"
	if _pulso_marcos:
		_pulso_marcos.kill()
		_pulso_marcos = null
	_marcos_button.scale = Vector2.ONE
	if pendentes > 0:
		_marcos_button.pivot_offset = _marcos_button.custom_minimum_size / 2
		_pulso_marcos = _marcos_button.create_tween().set_loops()
		_pulso_marcos.tween_property(_marcos_button, "scale", Vector2(1.08, 1.08), 0.45).set_trans(Tween.TRANS_SINE)
		_pulso_marcos.tween_property(_marcos_button, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE)


func _desbloqueada(cultura: Cultura) -> bool:
	return Inventario.estado_marco(cultura.id, 4) > 0 \
		or Inventario.get_quantity(cultura.id) > 0 \
		or Inventario.get_quantity("semente_%s" % cultura.id) > 0


func _criar_carta(cultura: Cultura) -> PanelContainer:
	var aberta := _desbloqueada(cultura)
	var carta := PanelContainer.new()
	carta.custom_minimum_size = Vector2(265, 250)
	if aberta:
		carta.add_theme_stylebox_override("panel", estilo_cartao(Color(0.87, 0.96, 0.81), Color(0.6, 0.83, 0.48)))
	else:
		carta.add_theme_stylebox_override("panel", estilo_cartao(Color(0.98, 0.9, 0.82), Color(0.91, 0.8, 0.69)))

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 4)
	carta.add_child(coluna)

	var nome := Label.new()
	nome.text = cultura.nome
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.add_theme_font_size_override("font_size", 24)
	nome.add_theme_color_override("font_color", COR_TEXTO)
	coluna.add_child(nome)

	var moldura := PanelContainer.new()
	var interior := estilo_cartao(Color(1, 1, 1, 0.55), Color(0, 0, 0, 0), 0)
	interior.shadow_size = 0
	moldura.add_theme_stylebox_override("panel", interior)
	moldura.custom_minimum_size = Vector2(0, 150)
	coluna.add_child(moldura)

	var imagem := TextureRect.new()
	imagem.texture = icone(cultura.id, "pronta")
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagem.custom_minimum_size = Vector2(130, 130)
	imagem.material = material_cinza(not aberta)
	moldura.add_child(imagem)

	if aberta:
		var qtd := Label.new()
		qtd.text = "× %d" % Inventario.get_quantity(cultura.id)
		qtd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		qtd.add_theme_font_size_override("font_size", 24)
		qtd.add_theme_color_override("font_color", COR_TEXTO)
		coluna.add_child(qtd)

		var sementes := Inventario.get_quantity("semente_%s" % cultura.id)
		if sementes > 0:
			var s := Label.new()
			s.text = "Sementes: %d" % sementes
			s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			s.add_theme_font_size_override("font_size", 16)
			s.add_theme_color_override("font_color", COR_TEXTO.lightened(0.25))
			coluna.add_child(s)
	else:
		var cadeado := TextureRect.new()
		cadeado.texture = CADEADO
		cadeado.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		cadeado.custom_minimum_size = Vector2(0, 44)
		coluna.add_child(cadeado)

	return carta
