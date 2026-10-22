class_name ConstrucaoEvolutiva
extends Node2D

## Construção independente: ciclo inexistente -> disponível -> construída,
## personalização por modelo/cor e evolução de nível. Base e máscara de parede
## são camadas distintas para preservar os detalhes ao recolorir.

enum Estado { INEXISTENTE, DISPONIVEL, CONSTRUIDA }

const NOMES_MODELOS := ["Clássico", "Acolhedor", "Rústico"]
const NOMES_CORES := ["Vermelho", "Azul", "Verde", "Amarelo", "Creme", "Castanho"]
const CORES_PAREDES := [Color("c95b52"), Color("5d86b8"), Color("6d9b67"), Color("d6b85b"), Color("e4d6b9"), Color("8a6247")]

signal interagida(construcao: ConstrucaoEvolutiva)
signal personalizacao_solicitada(construcao: ConstrucaoEvolutiva)
signal nivel_alterado(novo_nivel: int)
signal construcao_concluida(construcao: ConstrucaoEvolutiva, xp_recebido: int)
signal personalizacao_alterada(modelo: int, cor: int)

@export_group("Identidade")
@export var id_construcao: StringName = &"construcao"
@export var nome_exibicao := "Construção"
@export var dados: DadosConstrucao

@export_group("Evolução")
@export_range(1, 99, 1) var niveis_disponiveis := 3
@export_range(1, 99, 1) var nivel_inicial := 1
@export var texturas_niveis: Array[Texture2D] = []

@export_group("Estado inicial")
@export var estado_inicial := Estado.INEXISTENTE
@export_range(0, 2, 1) var modelo_inicial := 0
@export_range(0, 5, 1) var cor_inicial := 4

@export_group("Interação")
@export var interativa := true

@onready var visual: Node2D = get_node_or_null("Visual")
@onready var sprite_base: Sprite2D = get_node_or_null("Visual/SpriteBase")
@onready var sprite_paredes: Sprite2D = get_node_or_null("Visual/Paredes")
@onready var materiais_obra: Sprite2D = get_node_or_null("MateriaisConstrucao")
@onready var area_interacao: Area2D = get_node_or_null("AreaInteracao")

var estado_atual := Estado.INEXISTENTE
var modelo_atual := 0
var cor_atual := 4
var xp_atribuido := false
var nivel_atual := 1
var permitir_materiais_temporarios := true


func _ready() -> void:
	add_to_group("construcoes")
	if dados != null:
		id_construcao = dados.id
		nome_exibicao = dados.nome
	estado_atual = estado_inicial
	modelo_atual = clampi(modelo_inicial, 0, NOMES_MODELOS.size() - 1)
	cor_atual = clampi(cor_inicial, 0, NOMES_CORES.size() - 1)
	nivel_atual = clampi(nivel_inicial, 1, nivel_maximo())
	if area_interacao != null:
		area_interacao.input_event.connect(_on_area_input_event)
	_atualizar_visual()


func disponibilizar(guardar := true) -> bool:
	if estado_atual != Estado.INEXISTENTE:
		return false
	estado_atual = Estado.DISPONIVEL
	_atualizar_visual()
	if guardar:
		SaveManager.salvar()
	return true


func pode_construir() -> bool:
	if estado_atual != Estado.DISPONIVEL or dados == null:
		return false
	for item_id in dados.materiais_consumidos.keys():
		if Inventario.get_quantity(String(item_id)) < int(dados.materiais_consumidos[item_id]):
			return false
	for ferramenta in dados.ferramentas_reutilizaveis:
		if Inventario.get_quantity(String(ferramenta)) < 1:
			return false
	return true


func concluir_construcao(modelo: int, cor: int, guardar := true) -> bool:
	if not pode_construir():
		return false
	for item_id in dados.materiais_consumidos.keys():
		Inventario.remove_item(String(item_id), int(dados.materiais_consumidos[item_id]))
	modelo_atual = clampi(modelo, 0, NOMES_MODELOS.size() - 1)
	cor_atual = clampi(cor, 0, NOMES_CORES.size() - 1)
	estado_atual = Estado.CONSTRUIDA
	var xp_recebido := 0
	if not xp_atribuido:
		xp_recebido = dados.xp_conclusao
		Inventario.xp += xp_recebido
		xp_atribuido = true
	_atualizar_visual()
	construcao_concluida.emit(self, xp_recebido)
	Avisos.mostrar("Construção concluída! Recebeste +%d XP!" % xp_recebido)
	if guardar:
		SaveManager.salvar()
	return true


func definir_personalizacao(modelo: int, cor: int, guardar := true) -> bool:
	if estado_atual != Estado.CONSTRUIDA:
		return false
	var novo_modelo := clampi(modelo, 0, NOMES_MODELOS.size() - 1)
	var nova_cor := clampi(cor, 0, NOMES_CORES.size() - 1)
	if novo_modelo == modelo_atual and nova_cor == cor_atual:
		return false
	modelo_atual = novo_modelo
	cor_atual = nova_cor
	_atualizar_visual()
	personalizacao_alterada.emit(modelo_atual, cor_atual)
	if guardar:
		SaveManager.salvar()
	return true


func descricao_requisitos() -> String:
	if estado_atual == Estado.INEXISTENTE:
		return "Conclui primeiro a limpeza inicial da fazenda."
	if estado_atual == Estado.CONSTRUIDA:
		return "Construída — modelo %s, cor %s." % [NOMES_MODELOS[modelo_atual], NOMES_CORES[cor_atual]]
	if dados == null:
		return "Configuração da construção em falta."
	var linhas: Array[String] = ["Materiais necessários:"]
	for item_id in dados.materiais_consumidos.keys():
		linhas.append("• %s: %d/%d" % [String(item_id).trim_prefix("material_").capitalize(), Inventario.get_quantity(String(item_id)), int(dados.materiais_consumidos[item_id])])
	for ferramenta in dados.ferramentas_reutilizaveis:
		linhas.append("• %s (reutilizável): %s" % [String(ferramenta).trim_prefix("ferramenta_").capitalize(), "sim" if Inventario.get_quantity(String(ferramenta)) > 0 else "não"])
	return "\n".join(linhas)


func nivel_maximo() -> int:
	return maxi(1, maxi(niveis_disponiveis, texturas_niveis.size()))


func definir_nivel(novo_nivel: int, guardar := true) -> bool:
	var nivel_validado := clampi(novo_nivel, 1, nivel_maximo())
	if nivel_validado == nivel_atual:
		return false
	nivel_atual = nivel_validado
	_atualizar_visual()
	nivel_alterado.emit(nivel_atual)
	if guardar and not Engine.is_editor_hint():
		SaveManager.salvar()
	return true


func fazer_upgrade() -> bool:
	if estado_atual != Estado.CONSTRUIDA or nivel_atual >= nivel_maximo():
		return false
	return definir_nivel(nivel_atual + 1)


func migrar_como_construida() -> void:
	estado_atual = Estado.CONSTRUIDA
	xp_atribuido = true
	_atualizar_visual()


func definir_exibicao_temporaria(valor: bool) -> void:
	permitir_materiais_temporarios = valor
	_atualizar_visual()


func _atualizar_visual() -> void:
	var construida := estado_atual == Estado.CONSTRUIDA
	if visual != null:
		visual.visible = construida
	if materiais_obra != null:
		materiais_obra.texture = dados.textura_materiais_obra if dados != null else null
		materiais_obra.visible = permitir_materiais_temporarios and estado_atual == Estado.DISPONIVEL and materiais_obra.texture != null
	if sprite_base != null:
		var textura: Texture2D = null
		if dados != null:
			textura = dados.textura_base(modelo_atual)
		if textura == null and nivel_atual - 1 < texturas_niveis.size():
			textura = texturas_niveis[nivel_atual - 1]
		sprite_base.texture = textura
	if sprite_paredes != null:
		sprite_paredes.texture = dados.mascara_paredes(modelo_atual) if dados != null else null
		sprite_paredes.visible = sprite_paredes.texture != null
		sprite_paredes.modulate = CORES_PAREDES[cor_atual]
	if area_interacao != null:
		area_interacao.input_pickable = interativa and estado_atual != Estado.INEXISTENTE


func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not interativa or estado_atual == Estado.INEXISTENTE:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			interagida.emit(self)
		elif event.button_index == MOUSE_BUTTON_RIGHT and estado_atual == Estado.CONSTRUIDA:
			personalizacao_solicitada.emit(self)


func obter_save_data() -> Dictionary:
	return {"nivel": nivel_atual, "estado": int(estado_atual), "modelo": modelo_atual, "cor": cor_atual, "xp_atribuido": xp_atribuido}


func aplicar_save_data(dados_save: Dictionary) -> void:
	definir_nivel(int(dados_save.get("nivel", nivel_inicial)), false)
	if dados_save.has("estado"):
		estado_atual = clampi(int(dados_save.get("estado", estado_inicial)), Estado.INEXISTENTE, Estado.CONSTRUIDA)
	modelo_atual = clampi(int(dados_save.get("modelo", modelo_inicial)), 0, NOMES_MODELOS.size() - 1)
	cor_atual = clampi(int(dados_save.get("cor", cor_inicial)), 0, NOMES_CORES.size() - 1)
	xp_atribuido = bool(dados_save.get("xp_atribuido", estado_atual == Estado.CONSTRUIDA))
	_atualizar_visual()
