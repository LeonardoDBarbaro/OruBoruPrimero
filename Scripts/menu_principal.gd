extends Node3D

var peer = ENetMultiplayerPeer.new()
@export var player_scene: PackedScene
var golEquipo1 = 0
var golEquipo2 = 0

func _process(delta):
	var fps = Engine.get_frames_per_second()
	DisplayServer.window_set_title("Mi Juego de Fútbol - FPS: %d" % fps)

func _on_host_pressed():
	peer.create_server(25565)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_remove_player)
	_add_mapa_lindo()
	if multiplayer.is_server():
		var pelota = preload("res://Scenes/pelota.tscn").instantiate()
		
		pelota.name = "Pelota"
		pelota.set_multiplayer_authority(1)
		pelota.global_position = Vector3(0,5,0)
		pelota.scale = Vector3(3,3,3)
		add_child(pelota)

	_add_player()
	get_node("Button").visible = false
	get_node("Button2").visible = false

func _on_join_pressed():
	peer.create_client("192.168.0.116", 25565)
	multiplayer.multiplayer_peer = peer

	_add_mapa_lindo()

	get_node("Button").visible = false
	get_node("Button2").visible = false

func _add_mapa_lindo():
	if OS.has_feature("editor") or OS.has_feature("windows") or OS.has_feature("x11"):
		var mapa_lindo = preload("res://Scenes/mapa.tscn").instantiate()
		add_child(mapa_lindo)

func _add_player(id = 1):
	var player = player_scene.instantiate()
	player.name = str(id)
	player.global_position = Vector3(0,10,0)
	sync_score.rpc(golEquipo1, golEquipo2)
	call_deferred("add_child", player)
	
func _remove_player(id: int):
	var player = get_node_or_null(str(id))
	if player:
		player.queue_free()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		abrir_chat()

func abrir_chat():
	get_node("ChatBox").visible = not get_node("ChatBox").visible
	get_node("ChatBox/Chat").grab_focus()

func _on_arco_1_body_entered(body: Node3D) -> void:
	if not multiplayer.is_server(): return
	_on_goal_scored(1)
	golEquipo1 += 1
	get_node("Label").text = str(golEquipo1) + " - " + str(golEquipo2)
	sync_score.rpc(golEquipo1, golEquipo2)

func _on_arco_2_body_entered(body: Node3D) -> void:
	if not multiplayer.is_server(): return
	_on_goal_scored(1)
	golEquipo2 += 1
	get_node("Label").text = str(golEquipo1) + " - " + str(golEquipo2)
	sync_score.rpc(golEquipo1, golEquipo2)

@rpc("call_remote")
func sync_score(g1: int, g2: int):
	golEquipo1 = g1
	golEquipo2 = g2
	get_node("Label").text = str(golEquipo1) + " - " + str(golEquipo2)

@onready var players = get_tree().get_nodes_in_group("players")
@onready var ball = $Pelota
@export var player_spawn_positions := [] # Agregá nodos vacíos en el editor

func _on_goal_scored(team_id):
	ball = get_node("Pelota")
	print("¡Gol al equipo", team_id, "!")
	
	# Resetear pelota
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	ball.global_transform.origin = Vector3.ZERO  # o un punto central
	
	# Resetear jugadores
	for i in players.size():
		var player = players[i]
		var spawn_pos = player_spawn_positions[i % player_spawn_positions.size()]
		player.global_transform.origin = spawn_pos.global_position
		player.velocity = Vector3.ZERO  # Si usás CharacterBody3D
