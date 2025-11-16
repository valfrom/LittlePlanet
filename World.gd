extends Node3D

@export var player_scene: PackedScene
@export var planet: Node3D

var player: Player

func _ready() -> void:
	if player_scene == null:
		player_scene = load("res://player.tscn")

	player = player_scene.instantiate() as Player
	add_child(player)

	#if planet != null:
		#player.planet_center = planet

	player.global_position = Vector3(0.0, 110.0, 0.0)
