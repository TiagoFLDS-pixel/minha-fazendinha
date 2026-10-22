class_name PlanoRecuperacao
extends Resource

## Recompensas determinísticas da limpeza inicial. A soma dos seis pontos é
## exatamente suficiente para as três construções configuradas atualmente.

@export var pontos_limpeza: Array[Dictionary] = [
	{
		"id": "entrada",
		"recompensas": {"material_madeira": 5, "material_pregos": 2, "ferramenta_martelo": 1},
	},
	{
		"id": "arbusto_norte",
		"recompensas": {"material_madeira": 4, "material_pedra": 2},
	},
	{
		"id": "cerca_velha",
		"recompensas": {"material_madeira": 6, "material_pregos": 5, "ferramenta_serrote": 1},
	},
	{
		"id": "residuos_casa",
		"recompensas": {"material_madeira": 4, "material_pregos": 3, "material_pedra": 3},
	},
	{
		"id": "ervas_armazem",
		"recompensas": {"material_madeira": 4, "material_pregos": 3, "material_pedra": 3},
	},
	{
		"id": "caminho_cercado",
		"recompensas": {"material_madeira": 3, "material_pregos": 3, "material_pedra": 2},
	},
]


func ids_dos_pontos() -> PackedStringArray:
	var ids := PackedStringArray()
	for ponto in pontos_limpeza:
		ids.append(String(ponto.get("id", "")))
	return ids


func recompensas_do_ponto(ponto_id: String) -> Dictionary:
	for ponto in pontos_limpeza:
		if String(ponto.get("id", "")) == ponto_id:
			var recompensas: Variant = ponto.get("recompensas", {})
			if typeof(recompensas) == TYPE_DICTIONARY:
				return (recompensas as Dictionary).duplicate(true)
	return {}


func totais_disponiveis() -> Dictionary:
	var totais: Dictionary = {}
	for ponto in pontos_limpeza:
		var recompensas: Variant = ponto.get("recompensas", {})
		if typeof(recompensas) != TYPE_DICTIONARY:
			continue
		for item_id in (recompensas as Dictionary).keys():
			totais[item_id] = int(totais.get(item_id, 0)) + int(recompensas[item_id])
	return totais
