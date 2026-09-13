extends Node

var items: Dictionary = {}
var moedas := 0


func _ready() -> void:
	# Estoque inicial só para a v0.4 (economia) ser jogável antes de existir
	# um fluxo real de novo jogo/persistência (v0.5). Ajustar ou remover
	# quando isso existir.
	moedas = 20
	add_item("semente_milho", 3)


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


func adicionar_milho(quantidade: int = 1) -> void:
	add_item("milho", quantidade)


func adicionar_moedas(quantidade: int) -> void:
	moedas += quantidade
	print("Moedas: ", moedas)
