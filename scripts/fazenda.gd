extends Node2D

@onready var cenario_fundo: CenarioSazonal = $CenarioFundo
@onready var lote_residencial: Node2D = $ElementosYSort/LoteResidencial
@onready var lote_armazem: Node2D = $ElementosYSort/LoteArmazem
@onready var casa_principal: ConstrucaoEvolutiva = $ElementosYSort/LoteResidencial/CasaPrincipal
@onready var casa_cachorro: ConstrucaoEvolutiva = $ElementosYSort/LoteResidencial/CasaCachorro
@onready var armazem: ConstrucaoEvolutiva = $ElementosYSort/LoteArmazem/Armazem
@onready var recuperacao: RecuperacaoFazenda = $RecuperacaoFazenda
@onready var construcao_ui: ConstrucaoUI = $ConstrucaoUI
@onready var armazem_ui: CanvasLayer = $ArmazemUI


func _ready() -> void:
	add_to_group("fazenda")
	recuperacao.limpeza_inicial_concluida.connect(_on_limpeza_inicial_concluida)
	cenario_fundo.estacao_alterada.connect(_on_estacao_alterada)
	for ponto in get_tree().get_nodes_in_group("pontos_limpeza"):
		ponto.limpeza_solicitada.connect(_on_limpeza_solicitada)
	for construcao in _construcoes():
		construcao.interagida.connect(_on_construcao_interagida)
		construcao.personalizacao_solicitada.connect(_on_personalizacao_solicitada)
		construcao.construcao_concluida.connect(_on_construcao_concluida)
	SaveManager.carregar()
	_sincronizar_estado_recuperacao()
	_atualizar_elementos_temporarios()


func mudar_estacao(nova_estacao: CenarioSazonal.Estacao) -> bool:
	var mudou := cenario_fundo.mudar_estacao(nova_estacao)
	if mudou:
		SaveManager.salvar()
	return mudou


func registrar_limpeza(ponto_id: String) -> bool:
	return recuperacao.registrar_limpeza(ponto_id)


func melhorar_armazem() -> bool:
	return armazem.fazer_upgrade()


func melhorar_casa_cachorro() -> bool:
	return casa_cachorro.fazer_upgrade()


func obter_save_data() -> Dictionary:
	return {
		"estacao": int(cenario_fundo.estacao_atual),
		"recuperacao": recuperacao.obter_save_data(),
	}


func aplicar_save_data(dados: Dictionary) -> void:
	var estacao := int(dados.get("estacao", int(cenario_fundo.estacao_inicial)))
	cenario_fundo.mudar_estacao(estacao)
	var dados_recuperacao: Variant = dados.get("recuperacao")
	if typeof(dados_recuperacao) == TYPE_DICTIONARY:
		recuperacao.aplicar_save_data(dados_recuperacao)
	else:
		migrar_save_antigo()


func migrar_save_antigo() -> void:
	recuperacao.migrar_save_antigo()
	for construcao in _construcoes():
		construcao.migrar_como_construida()


func _construcoes() -> Array[ConstrucaoEvolutiva]:
	return [casa_principal, armazem, casa_cachorro]


func _on_limpeza_inicial_concluida() -> void:
	for construcao in _construcoes():
		construcao.disponibilizar(false)
	Avisos.mostrar("Limpeza concluída! Os locais de construção estão disponíveis.")
	SaveManager.salvar()


func _on_limpeza_solicitada(ponto: Node) -> void:
	if recuperacao.registrar_limpeza(ponto.ponto_id):
		ponto.definir_limpo(true)


func _on_estacao_alterada(_nova_estacao: CenarioSazonal.Estacao) -> void:
	_atualizar_elementos_temporarios()


func _on_construcao_interagida(construcao: ConstrucaoEvolutiva) -> void:
	# Preserva o comportamento anterior do armazém depois de construído.
	if construcao == armazem and construcao.estado_atual == ConstrucaoEvolutiva.Estado.CONSTRUIDA:
		armazem_ui.abrir()
		return
	construcao_ui.abrir(construcao)


func _on_personalizacao_solicitada(construcao: ConstrucaoEvolutiva) -> void:
	construcao_ui.abrir(construcao)


func _on_construcao_concluida(_construcao: ConstrucaoEvolutiva, _xp: int) -> void:
	if _todas_construidas():
		recuperacao.marcar_construcoes_concluidas(false)
	SaveManager.salvar()


func _todas_construidas() -> bool:
	for construcao in _construcoes():
		if construcao.estado_atual != ConstrucaoEvolutiva.Estado.CONSTRUIDA:
			return false
	return true


func _sincronizar_estado_recuperacao() -> void:
	if recuperacao.estado_atual == RecuperacaoFazenda.Estado.LIMPA_EM_CONSTRUCAO:
		for construcao in _construcoes():
			if construcao.estado_atual == ConstrucaoEvolutiva.Estado.INEXISTENTE:
				construcao.disponibilizar(false)
	elif recuperacao.estado_atual == RecuperacaoFazenda.Estado.CONSTRUIDA:
		for construcao in _construcoes():
			if construcao.estado_atual != ConstrucaoEvolutiva.Estado.CONSTRUIDA:
				construcao.migrar_como_construida()
	for ponto in get_tree().get_nodes_in_group("pontos_limpeza"):
		ponto.definir_limpo(ponto.ponto_id in recuperacao.pontos_limpos)


func _atualizar_elementos_temporarios() -> void:
	var primavera := cenario_fundo.estacao_atual == CenarioSazonal.Estacao.PRIMAVERA
	for construcao in _construcoes():
		construcao.definir_exibicao_temporaria(primavera)
	for ponto in get_tree().get_nodes_in_group("pontos_limpeza"):
		ponto.definir_exibicao_temporaria(primavera)
