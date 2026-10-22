class_name PainelFazenda
extends CanvasLayer

## Base dos painéis de ecrã inteiro (Armazém, Marcos): moldura de madeira,
## título na tábua, subtítulo, botão de fechar e uma área de conteúdo.

const FUNDO := preload("res://resources/ui/painel_fundo.png")
const SHADER_CINZA := preload("res://resources/ui/cinzento.gdshader")

const COR_TEXTO := Color(0.36, 0.2, 0.09)
const COR_TITULO := Color(1.0, 0.95, 0.82)
const COR_CONTORNO := Color(0.33, 0.17, 0.06)

## Área útil dentro da moldura (coordenadas da imagem 1536×1024).
const AREA := Rect2(78, 162, 1382, 798)
## Tamanho do painel em relação ao ecrã (1.0 = ecrã inteiro).
const ESCALA := 0.85

var raiz: Control
var quadro: Control
var titulo_label: Label
var subtitulo_label: Label
var conteudo: Control


func _construir_moldura(titulo: String, subtitulo: String) -> void:
	layer = 10
	raiz = Control.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(raiz)

	# Escurece a fazenda por trás e bloqueia cliques nos canteiros.
	var sombra := ColorRect.new()
	sombra.color = Color(0, 0, 0, 0.35)
	sombra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sombra.mouse_filter = Control.MOUSE_FILTER_STOP
	raiz.add_child(sombra)

	quadro = Control.new()
	quadro.size = Vector2(1536, 1024)
	quadro.scale = Vector2(ESCALA, ESCALA)
	quadro.position = Vector2(1536, 1024) * (1.0 - ESCALA) / 2.0
	quadro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(quadro)

	var fundo := TextureRect.new()
	fundo.texture = FUNDO
	fundo.size = Vector2(1536, 1024)
	fundo.stretch_mode = TextureRect.STRETCH_SCALE
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quadro.add_child(fundo)

	titulo_label = _label(titulo, 64, COR_TITULO, Rect2(486, 6, 462, 96))
	titulo_label.add_theme_color_override("font_outline_color", COR_CONTORNO)
	titulo_label.add_theme_constant_override("outline_size", 18)
	titulo_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	titulo_label.add_theme_constant_override("shadow_offset_y", 4)

	subtitulo_label = _label(subtitulo, 24, COR_TEXTO, Rect2(440, 106, 660, 46))

	var fechar := Button.new()
	fechar.flat = true
	fechar.position = Vector2(1418, 10)
	fechar.size = Vector2(100, 96)
	fechar.tooltip_text = "Fechar"
	fechar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	fechar.pressed.connect(fechar_painel)
	quadro.add_child(fechar)

	conteudo = Control.new()
	conteudo.position = AREA.position
	conteudo.size = AREA.size
	quadro.add_child(conteudo)
	raiz.visible = false


func _label(texto: String, tamanho: int, cor: Color, rect: Rect2) -> Label:
	var l := Label.new()
	l.text = texto
	l.position = rect.position
	l.size = rect.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quadro.add_child(l)
	return l


func esta_aberto() -> bool:
	return raiz != null and raiz.visible


func fechar_painel() -> void:
	raiz.visible = false


static func estilo_cartao(fundo: Color, borda: Color, largura_borda: int = 2) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = fundo
	e.border_color = borda
	e.set_border_width_all(largura_borda)
	e.set_corner_radius_all(16)
	e.content_margin_left = 10
	e.content_margin_right = 10
	e.content_margin_top = 8
	e.content_margin_bottom = 8
	e.shadow_color = Color(0.45, 0.3, 0.15, 0.18)
	e.shadow_size = 3
	e.shadow_offset = Vector2(0, 2)
	return e


static func icone(cultura_id: String, estagio: String) -> Texture2D:
	var caminho := "res://resources/icones/%s_%s.png" % [cultura_id, estagio]
	if ResourceLoader.exists(caminho):
		return load(caminho)
	return null


static func material_cinza(cinza: bool) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER_CINZA
	m.set_shader_parameter("cinza", 1.0 if cinza else 0.0)
	return m
