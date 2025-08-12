extends VBoxContainer

@onready var line_edit_message: LineEdit = $LineEdit_Message

#func _ready() -> void:
	#pass

#func _process(delta: float) -> void:
	#pass

func _on_button_sent_pressed() -> void:
	if multiplayer.is_server():
		sent_message.rpc(line_edit_message.text)
	else:
		request_message.rpc(line_edit_message.text)
	#pass

@rpc("any_peer","call_remote")
func request_message(message):
	sent_message.rpc(message)
	#pass

@rpc("authority","call_local")
func sent_message(message):
	GameNetwork.notify_message(message)
	#pass
