extends Control

const CENA_FAZENDA := "res://scenes/fazenda.tscn"

@onready var continuar_button: Button = $Centro/Caixa/ContinuarButton
@onready var novo_jogo_button: Button = $Centro/Caixa/NovoJogoButton
@onready var sair_button: Button = $Centro/Caixa/SairButton
@onready var confirmacao: ConfirmationDialog = $Confirmacao


func _ready() -> void:
	# O menu nunca grava: o Inventario ainda tem os valores iniciais e não há
	# canteiros, por isso gravar aqui apagaria ou criaria um save errado.
	SaveManager.gravacao_ativa = false

	continuar_button.disabled = not _existe_save()
	continuar_button.pressed.connect(_abrir_fazenda)
	novo_jogo_button.pressed.connect(_on_novo_jogo)
	sair_button.pressed.connect(get_tree().quit)
	confirmacao.confirmed.connect(_comecar_novo_jogo)

	if continuar_button.disabled:
		novo_jogo_button.grab_focus()
	else:
		continuar_button.grab_focus()


func _existe_save() -> bool:
	return FileAccess.file_exists(SaveManager.CAMINHO_SAVE)


func _on_novo_jogo() -> void:
	if _existe_save():
		confirmacao.popup_centered()
	else:
		_comecar_novo_jogo()


func _comecar_novo_jogo() -> void:
	if _existe_save():
		var erro := DirAccess.remove_absolute(SaveManager.CAMINHO_SAVE)
		if erro != OK:
			push_warning("Não foi possível apagar o save (erro %d)." % erro)
			Avisos.mostrar("Não foi possível apagar o save")
			return
	_abrir_fazenda()


func _abrir_fazenda() -> void:
	SaveManager.gravacao_ativa = true
	get_tree().change_scene_to_file(CENA_FAZENDA)
