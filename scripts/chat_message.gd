extends VBoxContainer

@onready var line_edit_message: LineEdit = $LineEdit_Message

#func _ready() -> void:
	#pass

func _on_button_sent_pressed() -> void:
	if multiplayer.is_server(): # check if this server
		sent_message.rpc(line_edit_message.text) # server
	else:
		# send to server
		#request_message.rpc(line_edit_message.text) #pass, client doublle copy
		request_message.rpc_id(1,line_edit_message.text) #pass, single message
		pass
	pass

# client to server
@rpc("any_peer","call_remote")
func request_message(message):
	print("any_peer > call_remote > request_message")
	print("is_server: ", multiplayer.is_server())
	sent_message.rpc(message)
	#pass

@rpc("authority","call_local")
func sent_message(message):
	GameNetwork.notify_message(message)
	#pass
