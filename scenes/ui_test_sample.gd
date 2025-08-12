extends Control

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _on_button_pressed() -> void:
	GameNetwork.notify_message("test")
	pass

func _on_btn_auth_local_pressed() -> void:
	request_shoot_0.rpc()
	pass

func _on_btn_auth_local_1_pressed() -> void:
	request_shoot_1.rpc()
	pass
	
func _on_btn_auth_local_2_pressed() -> void:
	request_shoot_2.rpc_id(1)
	pass

@rpc("authority","call_local")
func request_shoot_0():
	GameNetwork.notify_message("request_shoot 0")
	pass

@rpc("authority","call_remote")
func request_shoot_1():
	# server pass
	# client fail
	GameNetwork.notify_message("request_shoot 1")
	pass
	
@rpc("any_peer","call_remote")
func request_shoot_2():
	GameNetwork.notify_message("request_shoot 2")
	boardcast_projectile.rpc()
	pass
	
@rpc("authority","call_local")
func boardcast_projectile():
	print("authority > call_local > is_server:",multiplayer.is_server())
	GameNetwork.notify_message("boardcast projectile")
	pass
	
# 
