extends CanvasLayer

@onready var painel: Panel = $Painel
@onready var moedas_label: Label = $Painel/MoedasLabel
@onready var lista: VBoxContainer = $Painel/Scroll/Lista
@onready var fechar_button: Button = $Painel/FecharButton
@onready var armazem_ui: CanvasLayer = $"../ArmazemUI"


func _ready() -> void:
	painel.visible = false
	fechar_button.pressed.connect(fechar)


func abrir() -> void:
	# Fecha o armazém se estiver aberto
	armazem_ui.fechar()
	atualizar()
	painel.visible = true


func fechar() -> void:
	painel.visible = false


func atualizar() -> void:
	moedas_label.text = "Moedas: %d" % Inventario.moedas

	for filho in lista.get_children():
		filho.queue_free()

	for cultura in Culturas.get_todas():
		lista.add_child(criar_linha(cultura))


func criar_linha(cultura: Cultura) -> HBoxContainer:
	var linha := HBoxContainer.new()

	var label := Label.new()
	label.text = "%s (%s) — Semente: %dc | Venda: %dc | Estoque: %d" % [
		cultura.nome,
		cultura.categoria,
		cultura.preco_semente,
		cultura.preco_venda,
		Inventario.get_quantity(cultura.id),
	]
	label.custom_minimum_size = Vector2(360, 0)
	linha.add_child(label)

	var botao_comprar := Button.new()
	botao_comprar.text = "Comprar semente"
	botao_comprar.pressed.connect(comprar_semente.bind(cultura))
	linha.add_child(botao_comprar)

	var botao_vender := Button.new()
	botao_vender.text = "Vender 1"
	botao_vender.pressed.connect(vender_produto.bind(cultura))
	linha.add_child(botao_vender)

	return linha


func comprar_semente(cultura: Cultura) -> void:
	if Inventario.moedas < cultura.preco_semente:
		print("Moedas insuficientes para comprar semente de %s." % cultura.nome)
		return

	Inventario.moedas -= cultura.preco_semente
	Inventario.add_item("semente_%s" % cultura.id, 1)
	atualizar()
	SaveManager.salvar()


func vender_produto(cultura: Cultura) -> void:
	if not Inventario.remove_item(cultura.id, 1):
		print("Sem estoque de %s para vender." % cultura.nome)
		return

	Inventario.moedas += cultura.preco_venda
	atualizar()
	SaveManager.salvar()
