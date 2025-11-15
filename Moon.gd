extends Node3D

@export var planet: Node3D
@export var orbit_radius: float = 170.0
@export var orbit_speed: float = 0.4
@export var orbit_axis: Vector3 = Vector3.UP

var _orbit_angle: float = 0.0

func _ready() -> void:
    if planet == null:
        push_warning("Moon has no planet to orbit.")
        return
    _update_orbit_position()

func _process(delta: float) -> void:
    if planet == null:
        return
    _orbit_angle = wrapf(_orbit_angle + orbit_speed * delta, 0.0, TAU)
    _update_orbit_position()

func _update_orbit_position() -> void:
    var pivot := planet.global_transform.origin
    var offset := Vector3(orbit_radius, 0.0, 0.0)
    var basis := Basis(orbit_axis.normalized(), _orbit_angle)
    var orbit_position := pivot + basis * offset
    global_transform = Transform3D(global_transform.basis, orbit_position)
    look_at(pivot, Vector3.UP)
