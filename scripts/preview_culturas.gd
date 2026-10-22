@tool
extends Node2D

## Pré-visualização das culturas, só para desenvolvimento.
## Abre scenes/preview_culturas.tscn no editor: cada cultura aparece num
## canteiro da fazenda, no estágio escolhido em "estagio". Ao mudares a
## escala ou o offset de um .tres no Inspetor, o resultado aparece aqui
## de imediato (atualiza 4 vezes por segundo), sem correr o jogo.

const PASTA_CULTURAS := "res://resources/culturas"
const ORDEM_CATEGORIAS := ["Grão", "Raiz", "Tubérculo", "Bulbo", "Folha", "Fruto"]

## 1 = semente, 2 = broto, 3 = adulta, 4 = pronta
@export_range(1, 4) var estagio: int = 4

var _culturas: Array = []
var _rotulos: Array = []
var _tempo := 0.0


func _ready() -> void:
	_carregar_culturas()
	_criar_rotulos()
	_aplicar()


func _process(delta: float) -> void:
	_tempo += delta
	if _tempo < 0.25:
		return
	_tempo = 0.0
	_aplicar()


func _carregar_culturas() -> void:
	_culturas.clear()
	var dir := DirAccess.open(PASTA_CULTURAS)
	if dir == null:
		return
	for nome_arquivo in dir.get_files():
		var caminho := "%s/%s" % [PASTA_CULTURAS, nome_arquivo.trim_suffix(".remap")]
		if caminho.ends_with(".tres"):
			var recurso = load(caminho)
			if recurso is Cultura:
				_culturas.append(recurso)
	_culturas.sort_custom(func(a, b):
		var ia := ORDEM_CATEGORIAS.find(a.categoria)
		var ib := ORDEM_CATEGORIAS.find(b.categoria)
		return a.nome < b.nome if ia == ib else ia < ib)


func _canteiros() -> Array:
	var lista: Array = []
	var fazenda := get_node_or_null("Fazenda")
	if fazenda == null:
		return lista
	var grade := fazenda.get_node_or_null("GradeTerrenos")
	if grade == null:
		return lista
	for filho in grade.get_children():
		if String(filho.name).begins_with("Canteiro"):
			lista.append(filho)
	return lista


func _criar_rotulos() -> void:
	for r in _rotulos:
		if is_instance_valid(r):
			r.queue_free()
	_rotulos.clear()
	for canteiro in _canteiros():
		var rotulo := Label.new()
		rotulo.add_theme_font_size_override("font_size", 14)
		rotulo.add_theme_color_override("font_color", Color.WHITE)
		rotulo.add_theme_color_override("font_outline_color", Color.BLACK)
		rotulo.add_theme_constant_override("outline_size", 4)
		rotulo.position = canteiro.position + Vector2(380, 395) * canteiro.scale
		add_child(rotulo)  # sem owner: não é gravado na cena
		_rotulos.append(rotulo)


func _aplicar() -> void:
	var canteiros := _canteiros()
	for i in canteiros.size():
		var visual: Sprite2D = canteiros[i].get_node_or_null("Visual")
		if visual == null:
			continue
		var rotulo: Label = _rotulos[i] if i < _rotulos.size() else null
		if i >= _culturas.size():
			visual.visible = false
			if rotulo:
				rotulo.text = ""
			continue
		var cultura: Cultura = _culturas[i]
		var est: EstagioCultura = cultura.get_estagio(estagio)
		if est == null:
			visual.visible = false
			continue
		visual.texture = est.sprite
		visual.scale = est.escala
		visual.position = est.offset
		visual.modulate = Color.WHITE
		visual.visible = true
		if rotulo:
			rotulo.text = cultura.nome
