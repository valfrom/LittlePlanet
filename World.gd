extends Node3D

@export var player_scene: PackedScene
@export var planet: Node3D

var player: Player

func _ready() -> void:
        if player_scene == null:
                player_scene = load("res://player/player.tscn")

        if planet == null:
                planet = get_node_or_null(^"Planet")

        player = player_scene.instantiate() as Player
        if planet != null:
                player.planet = planet
        else:
                push_warning("World has no planet assigned. Player will use default gravity.")

        add_child(player)
        player.global_position = Vector3(0.0, 110.0, 0.0)
