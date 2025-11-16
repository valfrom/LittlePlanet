@tool
extends MultiMeshInstance3D

@export var planet: Node3D
@export_range(1.0, 1000.0, 0.1) var planet_radius: float = 100.0 : set = _set_planet_radius
@export_range(0, 20000, 1) var density: int = 4000 : set = _set_density
@export_range(0.0, 1.0, 0.01) var polar_cap: float = 0.0 : set = _set_polar_cap
@export_range(0, 1000000, 1) var seed: int = 12345 : set = _set_seed
@export var scale_range := Vector2(0.65, 1.35) : set = _set_scale_range
@export_range(0.0, 500.0, 0.1) var cull_distance: float = 260.0
@export var observer: Node3D
@export var tuft_mesh: Mesh = preload("res://meshes/GrassTuft.tres") : set = _set_tuft_mesh

var _needs_population := false
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
    if not Engine.is_editor_hint():
        _populate_if_needed()
    else:
        _queue_population()

func _process(_delta: float) -> void:
    _update_visibility()

func _notification(what: int) -> void:
    if what == NOTIFICATION_ENTER_TREE and Engine.is_editor_hint():
        _queue_population()

func repopulate() -> void:
    _queue_population()

func _set_planet_radius(value: float) -> void:
    planet_radius = max(value, 0.01)
    _queue_population()

func _set_density(value: int) -> void:
    density = max(value, 0)
    _queue_population()

func _set_polar_cap(value: float) -> void:
    polar_cap = clamp(value, 0.0, 1.0)
    _queue_population()

func _set_seed(value: int) -> void:
    seed = value
    _queue_population()

func _set_scale_range(value: Vector2) -> void:
    scale_range = Vector2(min(value.x, value.y), max(value.x, value.y))
    _queue_population()

func _set_tuft_mesh(value: Mesh) -> void:
    tuft_mesh = value
    _queue_population()

func _queue_population() -> void:
    _needs_population = true
    if Engine.is_editor_hint():
        call_deferred("_populate_if_needed")
    else:
        _populate_if_needed()

func _populate_if_needed() -> void:
    if not _needs_population:
        return
    _needs_population = false
    _populate()

func _populate() -> void:
    if tuft_mesh == null:
        return
    if multimesh == null:
        multimesh = MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.color_format = MultiMesh.COLOR_NONE
    multimesh.custom_data_format = MultiMesh.CUSTOM_DATA_FLOAT
    multimesh.mesh = tuft_mesh

    var instance_total := max(density, 0)
    multimesh.instance_count = instance_total
    if instance_total == 0:
        return

    _rng.seed = seed
    var center := planet.global_position if planet else Vector3.ZERO

    for i in instance_total:
        var normal := _random_normal()
        var polar_limit := polar_cap
        if polar_limit > 0.0:
            while abs(normal.y) > (1.0 - polar_limit):
                normal = _random_normal()
        var position := center + normal * planet_radius
        var basis := _basis_from_normal(normal)
        basis = basis.rotated(normal, _rng.randf_range(0.0, TAU))
        var uniform_scale := _rng.randf_range(scale_range.x, scale_range.y)
        basis = basis.scaled(Vector3(uniform_scale, uniform_scale, uniform_scale))
        var transform := Transform3D(basis, position)
        multimesh.set_instance_transform(i, transform)
        multimesh.set_instance_custom_data(i, Color(_rng.randf(), _rng.randf(), _rng.randf(), _rng.randf()))
    multimesh.visible_instance_count = instance_total

func _random_normal() -> Vector3:
    var u := _rng.randf_range(-1.0, 1.0)
    var theta := _rng.randf_range(0.0, TAU)
    var s := sqrt(1.0 - u * u)
    return Vector3(cos(theta) * s, u, sin(theta) * s)

func _basis_from_normal(normal: Vector3) -> Basis:
    var tangent := normal.cross(Vector3.UP)
    if tangent.length_squared() < 1e-4:
        tangent = normal.cross(Vector3.FORWARD)
    tangent = tangent.normalized()
    var bitangent := normal.cross(tangent).normalized()
    return Basis(tangent, normal, bitangent)

func _update_visibility() -> void:
    if multimesh == null:
        return
    if observer == null or planet == null:
        multimesh.visible_instance_count = multimesh.instance_count
        return
    var center := planet.global_position
    var distance := observer.global_position.distance_to(center)
    if distance > planet_radius + cull_distance:
        multimesh.visible_instance_count = 0
    else:
        multimesh.visible_instance_count = multimesh.instance_count
