extends Control

@onready var line_edit_user_name: LineEdit = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/LineEdit_UserName
@onready var line_edit_passphrase: LineEdit = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer4/LineEdit_Passphrase

func _on_btn_login_pressed() -> void:
	GameNetwork.attempt_login(line_edit_user_name.text, line_edit_passphrase.text)

func _on_btn_register_pressed() -> void:
	GameNetwork.attempt_login(line_edit_user_name.text, line_edit_passphrase.text)
