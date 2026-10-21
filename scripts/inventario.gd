extends Node

var items: Dictionary = {}
var moedas := 0


func _ready() -> void:
	# Defaults de "novo jogo": usados quando SaveManager.carregar() não
	# encontra save (user://savegame.json inexistente). Se houver save,
	# esses valores são sobrescritos por carregar() logo em seguida.
	moedas = 40
	add_item("semente_rabanete", 4)
	add_item("semente_alface", 3)
	add_item("semente_trigo", 3)
	add_item("semente_tomate", 2)


func add_item(id: String, quantidade: int = 1) -> void:
	items[id] = get_quantity(id) + quantidade
	print(id, " no inventário: ", items[id])


func remove_item(id: String, quantidade: int = 1) -> bool:
	var atual := get_quantity(id)
	if atual < quantidade:
		return false
	items[id] = atual - quantidade
	return true


func get_quantity(id: String) -> int:
	return items.get(id, 0)
