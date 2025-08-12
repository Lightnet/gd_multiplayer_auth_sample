extends Control

@onready var ui_multiplayer: Control = $"."
@onready var ui_access: Control = $"../UIAccess"
@onready var line_edit_address: LineEdit = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/LineEdit_Address
@onready var line_edit_port: LineEdit = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/LineEdit_Port
@onready var label_network_type: Label = $"../UIDebug/VBoxContainer/HBoxContainer/Label_NetworkType"
@onready var client_counts: Label = $"../UIDebug/VBoxContainer/HBoxContainer2/ClientCounts"
@onready var ui_test_sample: Control = $"../UITestSample"


func _ready() -> void:
	GameNetwork.player_failed_connected.connect(_on_failed_connected)
	ui_multiplayer.show()
	ui_access.hide()
	ui_test_sample.hide()
	#pass

func _exit_tree() -> void:
	GameNetwork.player_failed_connected.disconnect(_on_failed_connected)

func _on_failed_connected()->void:
	ui_multiplayer.show()
	ui_access.hide()
	ui_test_sample.hide()
	#pass

func _on_btn_host_pressed() -> void:
	label_network_type.text = "SERVER"
	GameNetwork.start_server(line_edit_port.text.to_int())
	ui_multiplayer.hide()
	#ui_access.show()
	ui_test_sample.show()
	#pass
	
func _on_btn_join_pressed() -> void:
	label_network_type.text = "CLIENT"
	GameNetwork.join_server(line_edit_address.text,line_edit_port.text.to_int())
	Global.show_connection_status()
	ui_multiplayer.hide()
	#ui_access.show()
	ui_test_sample.show()
	#pass
	
