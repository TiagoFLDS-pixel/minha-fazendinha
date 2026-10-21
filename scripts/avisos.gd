extends CanvasLayer

## Autoload "Avisos": mensagens curtas de feedback no ecrã.
## Avisos.mostrar("texto") junta uma mensagem ao fundo-centro do ecrã; várias
## mensagens seguidas empilham-se e cada uma desaparece sozinha ao fim de
## DURACAO segundos.

const DURACAO := 2.0
const FADE := 0.3
const MARGEM_INFERIOR := 90

var _pilha: VBoxContainer


func _ready() -> void:
	layer = 100
	_pilha = VBoxContainer.new()
	_pilha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pilha.add_theme_constant_override("separation", 6)
	_pilha.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_pilha.offset_bottom = -MARGEM_INFERIOR
	_pilha.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_pilha)


func mostrar(texto: String) -> void:
	var caixa := PanelContainer.new()
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0.7)
	estilo.set_corner_radius_all(8)
	estilo.content_margin_left = 16
	estilo.content_margin_right = 16
	estilo.content_margin_top = 8
	estilo.content_margin_bottom = 8
	caixa.add_theme_stylebox_override("panel", estilo)

	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotulo.add_theme_font_size_override("font_size", 22)
	caixa.add_child(rotulo)
	_pilha.add_child(caixa)

	var tween := caixa.create_tween()
	tween.tween_interval(DURACAO - FADE)
	tween.tween_property(caixa, "modulate:a", 0.0, FADE)
	tween.tween_callback(caixa.queue_free)
