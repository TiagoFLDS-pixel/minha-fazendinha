extends Node

## Autoload "Culturas": carrega todo .tres de res://culturas/ na inicialização,
## indexado por Cultura.id. Adicionar uma cultura nova = só criar o .tres na
## pasta; nada aqui precisa mudar.

var registro: Dictionary = {}


func _ready() -> void:
	var dir := DirAccess.open("res://culturas")
	if dir == null:
		push_warning("Pasta res://culturas não encontrada.")
		return

	dir.list_dir_begin()
	var nome_arquivo := dir.get_next()
	while nome_arquivo != "":
		if nome_arquivo.ends_with(".tres"):
			var recurso: Cultura = load("res://culturas/%s" % nome_arquivo)
			if recurso:
				registro[recurso.id] = recurso
		nome_arquivo = dir.get_next()
	dir.list_dir_end()


func get_cultura(id: String) -> Cultura:
	return registro.get(id)


func get_todas() -> Array:
	return registro.values()
