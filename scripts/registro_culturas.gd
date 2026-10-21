extends Node

## Autoload "Culturas": carrega todo .tres de res://resources/culturas/ na
## inicialização, indexado por Cultura.id. Adicionar uma cultura nova = só
## criar o .tres na pasta; nada aqui precisa mudar.

const PASTA_CULTURAS := "res://resources/culturas"

var registro: Dictionary = {}


func _ready() -> void:
	var dir := DirAccess.open(PASTA_CULTURAS)
	if dir == null:
		push_warning("Pasta %s não encontrada." % PASTA_CULTURAS)
		return

	dir.list_dir_begin()
	var nome_arquivo := dir.get_next()
	while nome_arquivo != "":
		if nome_arquivo.ends_with(".tres"):
			var recurso: Cultura = load("%s/%s" % [PASTA_CULTURAS, nome_arquivo])
			if recurso:
				registro[recurso.id] = recurso
		nome_arquivo = dir.get_next()
	dir.list_dir_end()


func get_cultura(id: String) -> Cultura:
	return registro.get(id)


const ORDEM_CATEGORIAS := ["Grão", "Raiz", "Tubérculo", "Bulbo", "Folha", "Fruto"]


## Todas as culturas, ordenadas por categoria e depois por nome.
func get_todas() -> Array:
	var todas := registro.values()
	todas.sort_custom(_comparar)
	return todas


func _comparar(a: Cultura, b: Cultura) -> bool:
	var ia := ORDEM_CATEGORIAS.find(a.categoria)
	var ib := ORDEM_CATEGORIAS.find(b.categoria)
	if ia != ib:
		return ia < ib
	return a.nome < b.nome
