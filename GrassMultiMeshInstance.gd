@tool
extends MultiMeshInstance3D

@export var planet_radius: float = 100.0
@export var instance_count: int = 6000
@export var surface_offset: float = 0.5
@export var random_seed: int = 1
@export var min_width_scale: float = 0.8
@export var max_width_scale: float = 1.2
@export var min_height_scale: float = 0.8
@export var max_height_scale: float = 1.4
@export var blade_mesh: Mesh
@export var grass_material: ShaderMaterial
@export var wind_speed: float = 1.2
@export var wind_direction: Vector3 = Vector3(0.7, 0.0, 0.4)
@export var bend_strength: float = 0.35
@export var top_color: Color = Color(0.2, 0.66, 0.27, 1.0)
@export var bottom_color: Color = Color(0.28, 0.19, 0.07, 1.0)
@export var soil_height: float = 0.18
@export var color_variation_strength: float = 0.18
@export var bend_variation_strength: float = 0.25

var _update_scheduled := false

func _ready() -> void:
        _apply_settings()

func _notification(what: int) -> void:
        if what == NOTIFICATION_EDITOR_PROPERTY_CHANGED:
                _schedule_update()

func _schedule_update() -> void:
        if _update_scheduled:
                return
        _update_scheduled = true
        call_deferred("_apply_settings")

func _apply_settings() -> void:
        _update_scheduled = false
        _apply_material_settings()
        _rebuild_multimesh()

func _apply_material_settings() -> void:
        if grass_material == null:
                return
        material_override = grass_material
        grass_material.set_shader_parameter("wind_speed", wind_speed)
        grass_material.set_shader_parameter("wind_direction", wind_direction)
        grass_material.set_shader_parameter("bend_strength", bend_strength)
        grass_material.set_shader_parameter("top_color", top_color)
        grass_material.set_shader_parameter("bottom_color", bottom_color)
        grass_material.set_shader_parameter("soil_height", soil_height)
        grass_material.set_shader_parameter("color_variation_strength", color_variation_strength)
        grass_material.set_shader_parameter("bend_variation_strength", bend_variation_strength)

func _rebuild_multimesh() -> void:
        if blade_mesh == null:
                return
        if instance_count <= 0:
                multimesh = null
                return
        if multimesh == null:
                multimesh = MultiMesh.new()
        multimesh.transform_format = MultiMesh.TRANSFORM_3D
        multimesh.custom_data_format = MultiMesh.CUSTOM_DATA_FLOAT
        multimesh.mesh = blade_mesh
        multimesh.instance_count = instance_count

        var rng := RandomNumberGenerator.new()
        rng.seed = int(random_seed)
        for index in instance_count:
                var normal := _random_unit_vector(rng)
                var position := normal * (planet_radius + surface_offset)
                var rotation := rng.randf() * TAU
                var basis := _basis_from_normal(normal)
                basis = basis.rotated(normal, rotation)

                var width_scale := lerp(min_width_scale, max_width_scale, rng.randf())
                var height_scale := lerp(min_height_scale, max_height_scale, rng.randf())
                basis = basis.scaled(Vector3(width_scale, height_scale, width_scale))

                var transform := Transform3D(basis, position)
                multimesh.set_instance_transform(index, transform)

                var color_variation := rng.randf()
                var bend_variation := rng.randf()
                var phase := rng.randf()
                var unused := rng.randf()
                multimesh.set_instance_custom_data(index, Color(color_variation, bend_variation, phase, unused))

func _random_unit_vector(rng: RandomNumberGenerator) -> Vector3:
	var u := rng.randf_range(-1.0, 1.0)
	var angle := rng.randf() * TAU
	var radius := sqrt(max(0.0, 1.0 - u * u))
	return Vector3(cos(angle) * radius, u, sin(angle) * radius)

func _basis_from_normal(normal: Vector3) -> Basis:
        var tangent := normal.cross(Vector3.UP)
        if tangent.length_squared() < 0.001:
                tangent = normal.cross(Vector3.RIGHT)
        tangent = tangent.normalized()
        var bitangent := normal.cross(tangent).normalized()
        return Basis(tangent, normal, bitangent)
