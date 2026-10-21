extends Area2D

@export var cultura: Cultura

var estado := 0
# 0 = vazio
# 1 = semente
# 2 = broto
# 3 = adulta
# 4 = pronta para colher

var plantado_em := -1.0
# Timestamp Unix (Time.get_unix_time_from_system) do momento do plantio.
# O estágio é sempre recalculado a partir daqui, nunca guardado sozinho —
# é assim que o crescimento continua correto mesmo com o jogo fechado.

var _tween: Tween

@onready var visual: Sprite2D = $Visual
@onready var seletor_sementes: CanvasLayer = $"../SeletorSementesUI"


func _ready() -> void:
	add_to_group("canteiros")
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	atualizar_estado()


func _on_mouse_entered() -> void:
	if estado != 0:
		visual.modulate = Color(1.15, 1.15, 1.15)


func _on_mouse_exited() -> void:
	visual.modulate = Color(1, 1, 1)


func _process(_delta: float) -> void:
	atualizar_estado()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if estado == 0:
			seletor_sementes.abrir(self)
		elif estado == 4:
			colher()
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
	plantado_em = Time.get_unix_time_from_system()
	atualizar_estado()
	Avisos.mostrar("%s plantado!" % cultura.nome)
	SaveManager.salvar()


func colher() -> void:
	if cultura:
		Inventario.add_item(cultura.id, cultura.quantidade_colhida)
		Avisos.mostrar("+%d %s" % [cultura.quantidade_colhida, cultura.nome])

	plantado_em = -1.0
	atualizar_estado()

	print("Canteiro vazio. Pode plantar novamente!")
	SaveManager.salvar()


func calcular_estado() -> int:
	if plantado_em < 0.0 or cultura == null:
		return 0

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

	set_process(estado == 1 or estado == 2 or estado == 3)


func atualizar_visual() -> void:
	if _tween:
		_tween.kill()
		_tween = null

	if estado == 0 or cultura == null:
		visual.visible = false
		return

	var estagio := cultura.get_estagio(estado)
	visual.visible = estagio != null

	if estagio:
		visual.texture = estagio.sprite
		visual.scale = estagio.escala
		visual.position = estagio.offset

		if estado == 4:
			_iniciar_pulso(estagio.escala)


func _iniciar_pulso(escala_base: Vector2) -> void:
	_tween = create_tween()
	_tween.set_loops()
	_tween.tween_property(visual, "scale", escala_base * 1.15, 0.4).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(visual, "scale", escala_base, 0.4).set_trans(Tween.TRANS_SINE)


func obter_save_data() -> Dictionary:
	return {
		"plantado_em": plantado_em,
		"cultura_id": cultura.id if cultura else "",
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
	atualizar_estado()
