extends Node

var items: Dictionary = {}
var moedas := 0
var xp := 0

## Marcos (conquistas) por cultura e estágio: chave "id:estado" (2 = broto,
## 3 = adulta, 4 = pronta). Valor MARCO_PENDENTE quando a planta chegou ao
## estágio pela primeira vez, MARCO_RECEBIDO depois de o jogador o reclamar.
const MARCO_PENDENTE := 1
const MARCO_RECEBIDO := 2
const MULTIPLICADOR_XP_MARCO := 3
var marcos: Dictionary = {}

signal marcos_mudaram


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


func estado_marco(cultura_id: String, estado: int) -> int:
	return int(marcos.get("%s:%d" % [cultura_id, estado], 0))


## Chamado pelos canteiros quando uma planta entra num estágio.
func alcancar_marco(cultura_id: String, estado: int) -> void:
	if estado < 2 or estado > 4:
		return
	var chave := "%s:%d" % [cultura_id, estado]
	if marcos.has(chave):
		return
	marcos[chave] = MARCO_PENDENTE
	marcos_mudaram.emit()


## Reclama um marco pendente; devolve o XP ganho (0 se não estava pendente).
func receber_marco(cultura: Cultura, estado: int) -> int:
	var chave := "%s:%d" % [cultura.id, estado]
	if int(marcos.get(chave, 0)) != MARCO_PENDENTE:
		return 0
	marcos[chave] = MARCO_RECEBIDO
	var ganho := cultura.get_xp_colheita() * MULTIPLICADOR_XP_MARCO
	xp += ganho
	marcos_mudaram.emit()
	return ganho


func contar_marcos_pendentes() -> int:
	var n := 0
	for valor in marcos.values():
		if int(valor) == MARCO_PENDENTE:
			n += 1
	return n
