extends Node

# Network configuration
const DEFAULT_IP = "127.0.0.1"  # Localhost for testing
const DEFAULT_PORT = 4242
const MAX_PLAYERS = 32

# Mock user database for demonstration (replace with real auth system)
const USER_DATABASE = {
	"player1": "pass123",
	"player2": "pass456"
}

# Player data storage
var players: Dictionary = {}  # Key: peer_id (int), Value: player_info (Dictionary)
var local_player_id: int = 0  # Local peer ID

# Signals for game logic
signal player_connected(peer_id: int, player_info: Dictionary)
signal player_failed_connected
signal player_disconnected(peer_id: int)
signal server_disconnected()

# Signals for login events
signal login_succeeded(peer_id: int, token: String)
signal login_failed(peer_id: int, reason: String)

func _ready():
	# Connect multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	# Initialize local player ID
	local_player_id = multiplayer.get_unique_id()

# Start a server
func start_server(port: int = DEFAULT_PORT, max_players: int = MAX_PLAYERS) -> bool:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, max_players)
	if error != OK:
		print("Failed to start server: %s" % error)
		return false
	
	multiplayer.multiplayer_peer = peer
	_add_player(local_player_id, {"username": "Server", "position": Vector2.ZERO})
	print("Server started on port %d" % port)
	return true

# Join a server as a client
func join_server(ip: String = DEFAULT_IP, port: int = DEFAULT_PORT) -> bool:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, port)
	if error != OK:
		print("Failed to join server: %s" % error)
		return false
	
	multiplayer.multiplayer_peer = peer
	local_player_id = multiplayer.get_unique_id()
	_add_player(local_player_id, {"username": "Player_%d" % local_player_id, "position": Vector2.ZERO})
	print("Attempting to join server at %s:%d" % [ip, port])
	return true

# Add player to the players dictionary
func _add_player(peer_id: int, info: Dictionary):
	players[peer_id] = info
	emit_signal("player_connected", peer_id, info)

# Remove player from the players dictionary
func _remove_player(peer_id: int):
	if players.has(peer_id):
		players.erase(peer_id)
		emit_signal("player_disconnected", peer_id)

# Signal handlers
func _on_peer_connected(peer_id: int):
	if multiplayer.is_server():
		print("Peer %d connected" % peer_id)
		# Request player info from the new peer
		request_player_info.rpc_id(peer_id)
		notify_message("Peer %d connected" % peer_id)

func _on_peer_disconnected(peer_id: int):
	if multiplayer.is_server():
		print("Peer %d disconnected" % peer_id)
		_remove_player(peer_id)
		# Notify all clients to remove the player
		sync_remove_player.rpc(peer_id)

func _on_connected_to_server():
	print("Connected to server, local peer ID: %d" % local_player_id)
	Global.hide_connection_status()
	sent_notify_message(local_player_id, "Connected to server, local peer ID: %d" % local_player_id)

func _on_connection_failed():
	print("Connection to server failed")
	multiplayer.multiplayer_peer = null
	Global.hide_connection_status()
	sent_notify_message(local_player_id, "Connection to server failed")
	player_failed_connected.emit()

func _on_server_disconnected():
	print("Disconnected from server")
	players.clear()
	multiplayer.multiplayer_peer = null
	emit_signal("server_disconnected")

# RPC to request player info from a newly connected peer
@rpc("authority", "call_remote", "reliable")
func request_player_info():
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 1:  # Only respond to server
		var info = players[local_player_id]
		send_player_info.rpc_id(1, local_player_id, info)

# RPC to send player info to the server
@rpc("any_peer", "call_remote", "reliable")
func send_player_info(peer_id: int, info: Dictionary):
	if multiplayer.is_server():
		var sender_id = multiplayer.get_remote_sender_id()
		if sender_id != peer_id:
			print("Warning: Sender ID mismatch for peer %d" % sender_id)
			return
		_add_player(peer_id, info)
		# Sync new player to all clients
		sync_player_info.rpc(peer_id, info)

# RPC to sync player info to all peers
@rpc("authority", "call_local", "reliable")
func sync_player_info(peer_id: int, info: Dictionary):
	print("authority > call_local > sync_player_info")
	_add_player(peer_id, info)

# RPC to sync player removal to all peers
@rpc("authority", "call_local", "reliable")
func sync_remove_player(peer_id: int):
	_remove_player(peer_id)

# Update player position (called by game logic)
#func update_player_position(peer_id: int, position: Vector2):
	#if multiplayer.is_server():
		#if players.has(peer_id):
			#players[peer_id]["position"] = position
			#sync_player_position.rpc(peer_id, position)
		#else:
			#print("Player %d not found" % peer_id)

# this just refs
# RPC to sync player position
#@rpc("authority", "call_local", "reliable")
#func sync_player_position(peer_id: int, position: Vector2):
	#if players.has(peer_id):
		#players[peer_id]["position"] = position

# Example: Send chat message (called by game logic)
#func send_chat_message(message: String):
	#if not multiplayer.is_server():
		## Clients send to server
		#submit_chat_message.rpc_id(1, local_player_id, message)
	#else:
		## Server broadcasts directly
		#broadcast_chat_message.rpc(local_player_id, message)

# RPC for clients to submit chat messages to server
#@rpc("any_peer", "call_remote", "reliable")
#func submit_chat_message(peer_id: int, message: String):
	#if multiplayer.is_server():
		#var sender_id = multiplayer.get_remote_sender_id()
		#if sender_id != peer_id:
			#print("Warning: Sender ID mismatch for peer %d" % sender_id)
			#return
		#if players.has(peer_id):
			#broadcast_chat_message.rpc(peer_id, message)
		#else:
			#print("Player %d not found" % peer_id)

# RPC to broadcast chat messages to all peers
#@rpc("authority", "call_local", "reliable")
#func broadcast_chat_message(peer_id: int, message: String):
	#if players.has(peer_id):
		#var username = players[peer_id]["username"]
		#print("%s: %s" % [username, message])
	#else:
		#print("Chat from unknown peer %d: %s" % [peer_id, message])

@rpc("any_peer", "call_remote", "reliable")
func login_request(username: String, password: String):
	print("login_request is_server: ", multiplayer.is_server())
	if multiplayer.is_server():
		var peer_id = multiplayer.get_remote_sender_id()
		print("Received login request from peer %d: username=%s" % [peer_id, username])
		
		 # Validate credentials
		var result: bool = false
		var token: String = ""
		var reason: String = ""
		
		#var result = username == "player1" and password == "pass123" # Simple check
		#var token = "abc123" if result else ""
		#login_response.rpc_id(peer_id, result, token)
		
		if USER_DATABASE.has(username) and USER_DATABASE[username] == password:
			result = true
			token = "token_%d_%s" % [peer_id, username]  # Simple token generation
			# Update player data
			_add_player(peer_id, {"username": username, "position": Vector2.ZERO, "token": token})
			print("Login successful for peer %d (%s)" % [peer_id, username])
			sent_notify_message(peer_id,"Login successful for peer %d (%s)" % [peer_id, username])
		else:
			reason = "Invalid username or password"
			print("Login failed for peer %d: %s" % [peer_id, reason])
			sent_notify_message(peer_id,reason)
		
		# Respond to the client
		login_response.rpc_id(peer_id, result, token, reason)
		
		# If login succeeded, sync player info to all peers
		if result:
			sync_player_info.rpc(peer_id, players[peer_id])
		
# Respond to client with login result
@rpc("authority", "call_local", "reliable")
func login_response(result: bool, token: String, reason: String):
	var peer_id = multiplayer.get_unique_id()
	if result:
		players[peer_id]["token"] = token
		emit_signal("login_succeeded", peer_id, token)
		print("Login succeeded for peer %d, token: %s" % [peer_id, token])
	else:
		emit_signal("login_failed", peer_id, reason)
		print("Login failed for peer %d: %s" % [peer_id, reason])
	
# Client-side function to initiate login
func attempt_login(username: String, password: String):
	if not multiplayer.is_server():
		print("Sending login request for %s" % username)
		login_request.rpc_id(1, username, password)
	else:
		print("Server does not need to login")
		login_request( username, password)
	
@rpc("any_peer", "call_remote", "reliable")
func notify_message(_message:String)->void:
	var notifies = get_tree().get_nodes_in_group("notify")
	if len(notifies) == 1:
		notifies[0].add_message(_message)
	pass

# testing if the authority server is for remote not other peers
func sent_notify_message(pid:int, _message:String)->void:
	print("sent_notify_message id: ", pid)
	print("multiplayer.is_server(): ", multiplayer.is_server())
	if multiplayer.is_server():
		if pid == 0:
			notify_message(_message)
		else: 
			notify_message.rpc_id(pid,_message)
	else:
		notify_message(_message)
