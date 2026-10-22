extends Area2D

@export var cultura: Cultura
@export var textura_estado_seco: Texture2D

var estado := 0
# 0 = vazio
# 1 = semente
# 2 = broto
# 3 = adulta
# 4 = pronta para colher
# 5 = seca

const ESTADO_SECO := 5
## Enquanto false, as culturas nunca secam (marcar_seco não faz nada). O estado
## seco continua a existir para saves antigos: um clique limpa o canteiro.
const PENALIZACOES_ATIVAS := false
var seco := false

var plantado_em := -1.0
# Timestamp Unix (Time.get_unix_time_from_system) do momento do plantio.
# O estágio é sempre recalculado a partir daqui, nunca guardado sozinho —
# é assim que o crescimento continua correto mesmo com o jogo fechado.


@onready var visual: Sprite2D = $Visual
var seletor_sementes: CanvasLayer


func _ready() -> void:
	add_to_group("canteiros")
	# Um canteiro sem planta não tem cultura: o valor por omissão do .tscn não conta.
	cultura = null
	seletor_sementes = get_tree().get_first_node_in_group("seletor_sementes") as CanvasLayer
	if seletor_sementes == null:
		seletor_sementes = get_node_or_null("../SeletorSementesUI") as CanvasLayer
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	atualizar_estado()


func _on_mouse_entered() -> void:
	if estado != 0:
		visual.modulate = Color(1.15, 1.15, 1.15)


func _on_mouse_exited() -> void:
	visual.modulate = Color(0.55, 0.42, 0.25) if seco else Color.WHITE


func _process(_delta: float) -> void:
	atualizar_estado()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if estado == 0:
			if seletor_sementes:
				seletor_sementes.abrir(self)
		elif estado == 4:
			colher()
		elif estado == ESTADO_SECO:
			limpar()
		else:
			Avisos.mostrar("Ainda a crescer…")


func plantar_cultura(nova_cultura: Cultura) -> void:
	if nova_cultura == null:
		return

	var id_semente := "semente_%s" % nova_cultura.id
	if not Inventario.remove_item(id_semente, 1):
		Avisos.mostrar("Sem sementes de %s" % nova_cultura.nome)
		return

	cultura = nova_cultura
	seco = false
	plantado_em = Time.get_unix_time_from_system()
	atualizar_estado()
	Avisos.mostrar("%s plantado!" % cultura.nome)
	SaveManager.salvar()


func colher() -> void:
	if cultura:
		Inventario.add_item(cultura.id, cultura.quantidade_colhida)
		var ganho_xp := cultura.get_xp_colheita()
		Inventario.xp += ganho_xp
		Avisos.mostrar("+%d %s  ·  +%d XP" % [cultura.quantidade_colhida, cultura.nome, ganho_xp])

	cultura = null
	plantado_em = -1.0
	seco = false
	atualizar_estado()

	print("Canteiro vazio. Pode plantar novamente!")
	SaveManager.salvar()


func limpar() -> void:
	cultura = null
	plantado_em = -1.0
	seco = false
	atualizar_estado()
	Avisos.mostrar("Canteiro limpo")
	SaveManager.salvar()


func calcular_estado() -> int:
	if plantado_em < 0.0 or cultura == null:
		return 0
	if seco:
		return ESTADO_SECO

	var decorrido := Time.get_unix_time_from_system() - plantado_em
	var limite := 0.0

	var semente := cultura.estagio_semente
	limite += semente.duracao if semente else 0.0
	if decorrido < limite:
		return 1

	var broto := cultura.estagio_broto
	limite += broto.duracao if broto else 0.0
	if decorrido < limite:
		return 2

	var adulta := cultura.estagio_adulta
	limite += adulta.duracao if adulta else 0.0
	if decorrido < limite:
		return 3

	return 4


func atualizar_estado() -> void:
	var novo_estado := calcular_estado()
	if novo_estado != estado:
		estado = novo_estado
		atualizar_visual()
		# Passar por um estágio conta como marco, mesmo que o jogo estivesse
		# fechado e a planta tenha saltado vários estágios de uma vez.
		if cultura and estado >= 2 and estado <= 4:
			for e in range(2, estado + 1):
				Inventario.alcancar_marco(cultura.id, e)

	set_process(estado == 1 or estado == 2 or estado == 3)


func atualizar_visual() -> void:
	if estado == 0 or cultura == null:
		visual.visible = false
		visual.modulate = Color.WHITE
		return

	if estado == ESTADO_SECO:
		var estagio_base := cultura.estagio_pronta
		visual.visible = true
		visual.texture = textura_estado_seco if textura_estado_seco else (estagio_base.sprite if estagio_base else null)
		if estagio_base:
			visual.scale = estagio_base.escala
			visual.position = estagio_base.offset
		visual.modulate = Color(0.55, 0.42, 0.25)
		return

	var estagio := cultura.get_estagio(estado)
	visual.visible = estagio != null
	visual.modulate = Color.WHITE

	if estagio:
		visual.texture = estagio.sprite
		visual.scale = estagio.escala
		visual.position = estagio.offset


func marcar_seco() -> bool:
	if not PENALIZACOES_ATIVAS:
		return false
	if estado < 1 or estado > 4:
		return false
	seco = true
	atualizar_estado()
	SaveManager.salvar()
	return true


func obter_save_data() -> Dictionary:
	return {
		"plantado_em": plantado_em,
		"cultura_id": cultura.id if cultura else "",
		"seco": seco,
	}


func aplicar_save_data(dados: Dictionary) -> void:
	var cultura_id: String = dados.get("cultura_id", "")
	if cultura_id != "":
		var cultura_salva := Culturas.get_cultura(cultura_id)
		if cultura_salva:
			cultura = cultura_salva
		else:
			push_warning("%s: cultura_id '%s' do save não existe no registo; canteiro fica vazio." % [name, cultura_id])
			plantado_em = -1.0
			atualizar_estado()
			return

	plantado_em = dados.get("plantado_em", -1.0)
	seco = bool(dados.get("seco", false))
	if plantado_em < 0.0:
		# Saves antigos guardavam a cultura por omissão em canteiros vazios.
		cultura = null
	atualizar_estado()
