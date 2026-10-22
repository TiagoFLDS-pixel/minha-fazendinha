class_name PontoLimpeza
extends Node2D

## Obstáculo independente da imagem de fundo. Sem textura, fica invisível e a
## área de clique é desativada, evitando zonas invisíveis a bloquear o mapa.

signal limpeza_solicitada(ponto: PontoLimpeza)

@export var ponto_id := "ponto"
@export var textura: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $AreaInteracao

var limpo := false
var permitir_exibicao := true


func _ready() -> void:
	add_to_group("pontos_limpeza")
	area.input_event.connect(_on_input_event)
	_atualizar_visual()


func definir_limpo(valor: bool) -> void:
	limpo = valor
	_atualizar_visual()


func definir_exibicao_temporaria(valor: bool) -> void:
	permitir_exibicao = valor
	_atualizar_visual()


func _atualizar_visual() -> void:
	sprite.texture = textura
	var ativo := not limpo and permitir_exibicao and textura != null
	sprite.visible = ativo
	area.input_pickable = ativo


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		limpeza_solicitada.emit(self)
