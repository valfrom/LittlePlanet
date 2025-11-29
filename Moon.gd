extends Node3D

@export var planet: Node3D
@export var orbit_radius: float = 170.0
@export var orbit_speed: float = 0.4
@export var planet_rotation_speed: float = 0.17

var _orbit_angle: float = 0.0
var _planet_rotation_angle: float = 0.0

func _ready() -> void:
	if planet == null:
		push_warning("Moon has no planet to orbit.")
		return
	_update_orbit_position()

func _process(delta: float) -> void:
	if planet == null:
		return
	_orbit_angle = wrapf(_orbit_angle + orbit_speed * delta, 0.0, TAU)
	_planet_rotation_angle = wrapf(_planet_rotation_angle + planet_rotation_speed * delta, 0.0, TAU)
	_update_orbit_position()

func _update_orbit_position() -> void:
	var pivot := planet.global_transform.origin
	var latitude_angle := sin(_planet_rotation_angle) * 0.5 * PI
	var cos_latitude := cos(latitude_angle)
	var x := orbit_radius * cos_latitude * cos(_orbit_angle)
	var y := orbit_radius * sin(latitude_angle)
	var z := orbit_radius * cos_latitude * sin(_orbit_angle)
	var orbit_position := pivot + Vector3(x, y, z)
	global_transform = Transform3D(global_transform.basis, orbit_position)
	look_at(pivot, Vector3.UP)
