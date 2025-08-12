extends Node

#func _ready() -> void:
	#pass

func show_connection_status()-> void:
	#connectionstatus
	var connectionstatuses = get_tree().get_nodes_in_group("connectionstatus")
	if len(connectionstatuses) == 1:
		connectionstatuses[0].show()
	#pass

func hide_connection_status()-> void:
	#connectionstatus
	var connectionstatuses = get_tree().get_nodes_in_group("connectionstatus")
	if len(connectionstatuses) == 1:
		connectionstatuses[0].hide()
	#pass
