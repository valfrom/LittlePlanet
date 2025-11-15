extends Camera3D

@export var sensitivity: float = 0.005

var pitch: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var player := get_parent() as Player

		if player != null:
			var planet_center := player.planet_center
			if planet_center != null:
				var up_dir := (player.global_position - planet_center.global_position).normalized()
				var rot := Basis(up_dir, 	event.relative.x * sensitivity)
				player.global_transform.basis = rot * player.global_transform.basis

		pitch -= event.relative.y * sensitivity
		pitch = clamp(pitch, deg_to_rad(-70.0), deg_to_rad(70.0))

func _process(delta: float) -> void:
	rotation.x = pitch
	rotation.y = 0.0
