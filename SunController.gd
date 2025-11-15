extends Node3D

const TAU := PI * 2.0

@export_node_path("Node3D") var planet_path: NodePath
@export var orbit_radius: float = 400.0
@export var orbit_speed: float = 0.15
@export var azimuth_degrees: float = 0.0
@export var initial_angle_degrees: float = 90.0

var _angle: float
var _planet: Node3D

func _ready() -> void:
    _planet = _resolve_planet()
    _angle = deg_to_rad(initial_angle_degrees)
    _update_transform()

func _process(delta: float) -> void:
    _angle = wrapf(_angle + orbit_speed * delta, 0.0, TAU)
    _update_transform()

func _update_transform() -> void:
    if _planet == null:
        _planet = _resolve_planet()
    if _planet == null:
        return

    var pos := Vector3(
        0.0,
        sin(_angle) * orbit_radius,
        cos(_angle) * orbit_radius
    )

    if azimuth_degrees != 0.0:
        var azimuth_basis := Basis(Vector3.UP, deg_to_rad(azimuth_degrees))
        pos = azimuth_basis * pos

    global_position = _planet.global_position + pos
    look_at(_planet.global_position, Vector3.UP)

func _resolve_planet() -> Node3D:
    if planet_path.is_empty():
        return null
    var planet_node := get_node_or_null(planet_path)
    if planet_node == null:
        push_warning("SunController could not find planet at %s" % planet_path)
    return planet_node
