class_name GalinhaAdulta
extends CharacterBody2D

## Galinha adulta reutilizável. A deslocação só acontece nos quadros em que
## uma pata está levantada ou a avançar, evitando que o sprite deslize durante
## as poses de apoio.

enum Estado {
	IDLE,
	WALK,
}

signal estado_alterado(novo_estado: Estado)
signal interagida(galinha: GalinhaAdulta)

const QUADROS_COM_DESLOCAMENTO := [1, 2, 4, 5]

@export_group("Movimento")
@export_range(1.0, 200.0, 1.0) var velocidade := 36.0
@export_range(0.1, 30.0, 0.1) var idle_minimo := 1.4
@export_range(0.1, 30.0, 0.1) var idle_maximo := 2.6
@export_range(0.1, 30.0, 0.1) var caminhada_minima := 2.4
@export_range(0.1, 30.0, 0.1) var caminhada_maxima := 4.2
@export var iniciar_automaticamente := true
@export var semente_aleatoria := 0

@export_group("Limites opcionais")
@export var limitar_movimento := false
@export var limites_movimento := Rect2()

@export_group("Interação")
@export var interativa := true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_interacao: Area2D = $AreaInteracao

var estado_atual := Estado.IDLE
var _tempo_estado := 0.0
var _direcao := Vector2.RIGHT
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if semente_aleatoria == 0:
		_rng.randomize()
	else:
		_rng.seed = semente_aleatoria
	area_interacao.input_pickable = interativa
	area_interacao.input_event.connect(_on_area_interacao_input_event)
	_entrar_idle()
	if not iniciar_automaticamente:
		_tempo_estado = INF


func _physics_process(delta: float) -> void:
	_tempo_estado -= delta
	if iniciar_automaticamente and _tempo_estado <= 0.0:
		if estado_atual == Estado.IDLE:
			_entrar_walk()
		else:
			_entrar_idle()

	if estado_atual == Estado.WALK:
		_mover_sincronizado_com_passos()
	else:
		velocity = Vector2.ZERO


func definir_estado(novo_estado: Estado) -> void:
	if novo_estado == Estado.WALK:
		_entrar_walk()
	else:
		_entrar_idle()


func _entrar_idle() -> void:
	estado_atual = Estado.IDLE
	velocity = Vector2.ZERO
	_tempo_estado = _rng.randf_range(idle_minimo, maxf(idle_minimo, idle_maximo))
	sprite.play(&"idle")
	estado_alterado.emit(estado_atual)


func _entrar_walk() -> void:
	estado_atual = Estado.WALK
	_tempo_estado = _rng.randf_range(caminhada_minima, maxf(caminhada_minima, caminhada_maxima))
	var sentido_horizontal := -1.0 if _rng.randf() < 0.5 else 1.0
	_direcao = Vector2(sentido_horizontal, _rng.randf_range(-0.28, 0.28)).normalized()
	sprite.flip_h = _direcao.x < 0.0
	sprite.play(&"walk")
	estado_alterado.emit(estado_atual)


func _mover_sincronizado_com_passos() -> void:
	if sprite.frame in QUADROS_COM_DESLOCAMENTO:
		velocity = _direcao * velocidade
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	_aplicar_limites()


func _aplicar_limites() -> void:
	if not limitar_movimento or limites_movimento.size == Vector2.ZERO:
		return
	var anterior := position
	position.x = clampf(position.x, limites_movimento.position.x, limites_movimento.end.x)
	position.y = clampf(position.y, limites_movimento.position.y, limites_movimento.end.y)
	if not is_equal_approx(anterior.x, position.x):
		_direcao.x *= -1.0
		sprite.flip_h = _direcao.x < 0.0
	if not is_equal_approx(anterior.y, position.y):
		_direcao.y *= -1.0


func _on_area_interacao_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not interativa:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		interagida.emit(self)

