extends MeshInstance3D

@export var sun_path: NodePath

var _sun_light: DirectionalLight3D
var _shader_material: ShaderMaterial

func _ready() -> void:
    if sun_path != NodePath(""):
        _sun_light = get_node_or_null(sun_path)
    _shader_material = material_override as ShaderMaterial
    if _shader_material == null and mesh:
        _shader_material = mesh.surface_get_material(0) as ShaderMaterial

func _process(_delta: float) -> void:
    if _shader_material == null or _sun_light == null:
        return
    var sun_dir := -_sun_light.global_transform.basis.z.normalized()
    _shader_material.set_shader_parameter("sun_direction", sun_dir)
    _shader_material.set_shader_parameter("light_intensity", _sun_light.light_energy)
