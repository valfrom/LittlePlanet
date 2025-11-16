@tool
extends ArrayMesh

const GRASS_SHADER := preload("res://GrassWind.gdshader")

@export_range(0.05, 1.0, 0.01) var blade_height: float = 0.6 : set = _set_blade_height
@export_range(0.02, 0.6, 0.01) var blade_width: float = 0.2 : set = _set_blade_width

func _init() -> void:
    _rebuild()

func _set_blade_height(value: float) -> void:
    blade_height = value
    _queue_rebuild()

func _set_blade_width(value: float) -> void:
    blade_width = value
    _queue_rebuild()

func _queue_rebuild() -> void:
    if Engine.is_editor_hint():
        call_deferred("_rebuild")
    else:
        _rebuild()

func _rebuild() -> void:
    clear_surfaces()
    var half_width := blade_width * 0.5
    var h := blade_height

    var vertices := PackedVector3Array([
        Vector3(-half_width, 0.0, 0.0),
        Vector3(half_width, 0.0, 0.0),
        Vector3(half_width, h, 0.0),
        Vector3(-half_width, h, 0.0),
        Vector3(0.0, 0.0, -half_width),
        Vector3(0.0, 0.0, half_width),
        Vector3(0.0, h, half_width),
        Vector3(0.0, h, -half_width),
    ])

    var normals := PackedVector3Array([
        Vector3(0, 0, 1),
        Vector3(0, 0, 1),
        Vector3(0, 0, 1),
        Vector3(0, 0, 1),
        Vector3(1, 0, 0),
        Vector3(1, 0, 0),
        Vector3(1, 0, 0),
        Vector3(1, 0, 0),
    ])

    var uvs := PackedVector2Array([
        Vector2(0, 0),
        Vector2(1, 0),
        Vector2(1, 1),
        Vector2(0, 1),
        Vector2(0, 0),
        Vector2(1, 0),
        Vector2(1, 1),
        Vector2(0, 1),
    ])

    var indices := PackedInt32Array([
        0, 1, 2,
        0, 2, 3,
        4, 5, 6,
        4, 6, 7,
    ])

    var arrays: Array = []
    arrays.resize(ArrayMesh.ARRAY_MAX)
    arrays[ArrayMesh.ARRAY_VERTEX] = vertices
    arrays[ArrayMesh.ARRAY_NORMAL] = normals
    arrays[ArrayMesh.ARRAY_TEX_UV] = uvs
    arrays[ArrayMesh.ARRAY_INDEX] = indices

    add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    var shader_material := ShaderMaterial.new()
    shader_material.shader = GRASS_SHADER
    surface_set_material(0, shader_material)
