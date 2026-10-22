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

@export_group("Progressão")
## XP ganho por colheita. 0 = automático (1 XP por minuto de crescimento).
@export var xp_colheita: int = 0


func get_estagio(estado: int) -> EstagioCultura:
	match estado:
		1: return estagio_semente
		2: return estagio_broto
		3: return estagio_adulta
		4: return estagio_pronta
		_: return null


func get_xp_colheita() -> int:
	if xp_colheita > 0:
		return xp_colheita
	var total := 0.0
	for estagio in [estagio_semente, estagio_broto, estagio_adulta]:
		if estagio:
			total += estagio.duracao
	return maxi(1, roundi(total / 60.0))
