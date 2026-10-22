class_name RecuperacaoFazenda
extends Node

enum Estado {
	ABANDONADA,
	LIMPA_EM_CONSTRUCAO,
	CONSTRUIDA,
}

signal ponto_limpo(ponto_id: String, recompensas: Dictionary)
signal limpeza_inicial_concluida
signal estado_alterado(novo_estado: Estado)

@export var plano: PlanoRecuperacao

var estado_atual := Estado.ABANDONADA
var pontos_limpos: Array[String] = []


func registrar_limpeza(ponto_id: String, guardar := true) -> bool:
	if plano == null or ponto_id in pontos_limpos:
		return false
	var recompensas := plano.recompensas_do_ponto(ponto_id)
	if recompensas.is_empty():
		return false
	for item_id in recompensas.keys():
		Inventario.add_item(String(item_id), int(recompensas[item_id]))
	pontos_limpos.append(ponto_id)
	ponto_limpo.emit(ponto_id, recompensas)
	if pontos_limpos.size() >= plano.ids_dos_pontos().size():
		_definir_estado(Estado.LIMPA_EM_CONSTRUCAO)
		limpeza_inicial_concluida.emit()
	if guardar:
		SaveManager.salvar()
	return true


func marcar_construcoes_concluidas(guardar := true) -> void:
	_definir_estado(Estado.CONSTRUIDA)
	if guardar:
		SaveManager.salvar()


func obter_save_data() -> Dictionary:
	return {
		"estado": int(estado_atual),
		"pontos_limpos": pontos_limpos.duplicate(),
	}


func aplicar_save_data(dados: Dictionary) -> void:
	pontos_limpos.clear()
	var pontos: Variant = dados.get("pontos_limpos", [])
	if typeof(pontos) == TYPE_ARRAY:
		for ponto in pontos:
			pontos_limpos.append(String(ponto))
	_definir_estado(clampi(int(dados.get("estado", Estado.ABANDONADA)), Estado.ABANDONADA, Estado.CONSTRUIDA))


func migrar_save_antigo() -> void:
	# A fazenda antiga já apresentava armazém e casinha no fundo. Mantê-la como
	# recuperada evita retirar progresso a jogadores existentes.
	if plano != null:
		pontos_limpos.assign(Array(plano.ids_dos_pontos()))
	_definir_estado(Estado.CONSTRUIDA)


func _definir_estado(novo_estado: Estado) -> void:
	if estado_atual == novo_estado:
		return
	estado_atual = novo_estado
	estado_alterado.emit(estado_atual)
