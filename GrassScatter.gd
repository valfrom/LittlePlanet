@tool
extends MultiMeshInstance3D

@export_range(100, 20000, 1) var blade_count := 8000 : set = _set_blade_count
@export_range(50.0, 200.0, 0.01) var radius := 100.4 : set = _set_radius
@export_range(-1.0, 1.0, 0.01) var min_normal_y := -0.3 : set = _set_min_normal
@export var random_scale := Vector2(0.8, 1.3) : set = _set_random_scale

const BLADE_MESH := preload("res://GrassBladeMesh.tres")

var _rng := RandomNumberGenerator.new()
var _needs_update := true

func _ready() -> void:
    _rng.seed = 1
    _ensure_multimesh()
    _populate()

func _notification(what: int) -> void:
    if what == NOTIFICATION_ENTER_TREE and Engine.is_editor_hint():
        _needs_update = true
        call_deferred("_populate")

func _ensure_multimesh() -> void:
    if multimesh == null:
        multimesh = MultiMesh.new()
    multimesh.mesh = BLADE_MESH
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.color_format = MultiMesh.COLOR_8BIT
    multimesh.custom_data_format = MultiMesh.CUSTOM_DATA_NONE

func _populate() -> void:
    if !_needs_update:
        return
    _needs_update = false
    _ensure_multimesh()
    multimesh.instance_count = blade_count
    var i := 0
    var attempts := 0
    while i < blade_count and attempts < blade_count * 10:
        attempts += 1
        var dir := _random_on_sphere()
        if dir.y < min_normal_y:
            continue
        var transform := _blade_transform(dir)
        multimesh.set_instance_transform(i, transform)
        var tone := _rng.randf_range(0.85, 1.1)
        multimesh.set_instance_color(i, Color(tone, tone, tone, 1.0))
        i += 1
    multimesh.instance_count = i
    multimesh.visible_instance_count = -1

func _random_on_sphere() -> Vector3:
    var z := _rng.randf_range(-1.0, 1.0)
    var angle := _rng.randf_range(0.0, TAU)
    var r := sqrt(max(0.0, 1.0 - z * z))
    return Vector3(cos(angle) * r, z, sin(angle) * r)

func _blade_transform(dir: Vector3) -> Transform3D:
    var normal := dir.normalized()
    var right := normal.cross(Vector3.FORWARD)
    if right.length_squared() < 0.0001:
        right = normal.cross(Vector3.RIGHT)
    right = right.normalized()
    var forward := right.cross(normal).normalized()
    var basis := Basis(right, normal, forward)
    var rot := Basis(normal, _rng.randf_range(0.0, TAU))
    basis = rot * basis
    var scale := _rng.randf_range(random_scale.x, random_scale.y)
    basis = basis.scaled(Vector3(1.0, scale, 1.0))
    return Transform3D(basis, normal * radius)

func _set_blade_count(value: int) -> void:
    blade_count = value
    _needs_update = true
    _populate()

func _set_radius(value: float) -> void:
    radius = value
    _needs_update = true
    _populate()

func _set_min_normal(value: float) -> void:
    min_normal_y = clamp(value, -1.0, 1.0)
    _needs_update = true
    _populate()

func _set_random_scale(value: Vector2) -> void:
    random_scale = value
    _needs_update = true
    _populate()
