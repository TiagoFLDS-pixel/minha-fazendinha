extends Area2D

@onready var armazem_ui: CanvasLayer = $"../ArmazemUI"


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		armazem_ui.abrir()
