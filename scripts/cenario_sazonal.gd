@tool
class_name CenarioSazonal
extends Sprite2D

## Fundo modular da fazenda. As quatro texturas são opcionais para que o
## projeto continue a abrir enquanto a arte definitiva não estiver disponível.

enum Estacao {
	PRIMAVERA,
	VERAO,
	OUTONO,
	INVERNO,
}

signal estacao_alterada(nova_estacao: Estacao)

@export_group("Cenários sazonais")
@export var textura_primavera: Texture2D
@export var textura_verao: Texture2D
@export var textura_outono: Texture2D
@export var textura_inverno: Texture2D
@export var estacao_inicial: Estacao = Estacao.PRIMAVERA
@export var usar_textura_atual_como_fallback := true

var estacao_atual: Estacao = Estacao.PRIMAVERA
var _textura_fallback: Texture2D


func _ready() -> void:
	_textura_fallback = texture
	estacao_atual = estacao_inicial
	_aplicar_textura(estacao_atual, false)


func mudar_estacao(nova_estacao: Estacao) -> bool:
	if nova_estacao < Estacao.PRIMAVERA or nova_estacao > Estacao.INVERNO:
		push_warning("Estação inválida: %s" % nova_estacao)
		return false

	estacao_atual = nova_estacao
	var aplicada := _aplicar_textura(nova_estacao)
	estacao_alterada.emit(nova_estacao)
	return aplicada


func _aplicar_textura(estacao: Estacao, avisar := true) -> bool:
	var nova_textura := textura_da_estacao(estacao)
	if nova_textura != null:
		texture = nova_textura
		return true
	if usar_textura_atual_como_fallback and _textura_fallback != null:
		texture = _textura_fallback
		if avisar and not Engine.is_editor_hint():
			push_warning("Sem textura para %s; a usar o cenário de fallback." % nome_estacao(estacao))
		return true
	if avisar:
		push_warning("Sem textura nem fallback para %s." % nome_estacao(estacao))
	return false


func textura_da_estacao(estacao: Estacao) -> Texture2D:
	match estacao:
		Estacao.PRIMAVERA: return textura_primavera
		Estacao.VERAO: return textura_verao
		Estacao.OUTONO: return textura_outono
		Estacao.INVERNO: return textura_inverno
		_: return null


static func nome_estacao(estacao: Estacao) -> String:
	match estacao:
		Estacao.PRIMAVERA: return "Primavera"
		Estacao.VERAO: return "Verão"
		Estacao.OUTONO: return "Outono"
		Estacao.INVERNO: return "Inverno"
		_: return "Desconhecida"
