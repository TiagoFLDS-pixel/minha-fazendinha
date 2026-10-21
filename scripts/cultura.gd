class_name Cultura
extends Resource

## Define os dados de uma cultura plantável (sprites, tempos e economia por
## estágio). Novas culturas são criadas como recursos .tres em
## res://resources/culturas/, sem precisar de código novo.

@export var id: String = ""
@export var nome: String = ""

## Classificação do produto colhido (usada na Loja para agrupar/ordenar).
@export_enum("Raiz", "Tubérculo", "Bulbo", "Folha", "Fruto", "Grão") var categoria: String = ""

@export var estagio_semente: EstagioCultura
@export var estagio_broto: EstagioCultura
@export var estagio_adulta: EstagioCultura
@export var estagio_pronta: EstagioCultura

@export_group("Economia")
@export var quantidade_colhida: int = 1
@export var preco_semente: int = 0
@export var preco_venda: int = 0


func get_estagio(estado: int) -> EstagioCultura:
	match estado:
		1: return estagio_semente
		2: return estagio_broto
		3: return estagio_adulta
		4: return estagio_pronta
		_: return null
