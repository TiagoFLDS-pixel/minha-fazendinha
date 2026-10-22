class_name DadosConstrucao
extends Resource

## Dados editáveis de uma construção. As imagens são separadas em base e
## paredes para permitir recoloração sem afetar telhado, portas ou ferragens.

@export_group("Identidade")
@export var id: StringName = &"construcao"
@export var nome := "Construção"
@export_multiline var descricao := ""

@export_group("Construção")
@export var materiais_consumidos: Dictionary = {}
@export var ferramentas_reutilizaveis: PackedStringArray = []
@export_range(0, 100000, 1) var xp_conclusao := 0

@export_group("Modelos: Clássico, Acolhedor, Rústico")
@export var texturas_base: Array[Texture2D] = []
@export var mascaras_paredes: Array[Texture2D] = []
@export var textura_materiais_obra: Texture2D


func textura_base(modelo: int) -> Texture2D:
	if modelo >= 0 and modelo < texturas_base.size():
		return texturas_base[modelo]
	return null


func mascara_paredes(modelo: int) -> Texture2D:
	if modelo >= 0 and modelo < mascaras_paredes.size():
		return mascaras_paredes[modelo]
	return null
