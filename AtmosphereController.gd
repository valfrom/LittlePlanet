extends MeshInstance3D

@export var player: Node3D
@export var planet: Node3D
@export var moon_light: OmniLight3D
@export var moon_mesh: MeshInstance3D
@export var world_environment: WorldEnvironment
@export var day_zenith_color: Color = Color(0.2, 0.45, 0.95)
@export var day_horizon_color: Color = Color(0.55, 0.75, 1.0)
@export var dusk_zenith_color: Color = Color(0.4, 0.16, 0.26)
@export var dusk_horizon_color: Color = Color(1.0, 0.4, 0.1)
@export var night_zenith_color: Color = Color(0.02, 0.05, 0.1)
@export var night_horizon_color: Color = Color(0.08, 0.04, 0.1)
@export var sun_max_intensity: float = 2.0
@export_range(0.0, 1.0, 0.01) var moon_brightness_boost: float = 0.2
@export_range(0.0, 1.0, 0.01) var ambient_zenith_influence: float = 0.35
@export_range(0.0, 4.0, 0.01) var ambient_light_strength: float = 1.2
@export_range(0.0, 1.0, 0.01) var ambient_night_factor: float = 0.25

var _material: ShaderMaterial
var _environment: Environment
var _moon_material: BaseMaterial3D

func _ready() -> void:
    _material = material_override as ShaderMaterial
    if world_environment:
        _environment = world_environment.environment
        if _environment:
            if _environment.background_mode != Environment.BG_COLOR:
                _environment.background_mode = Environment.BG_COLOR
            _environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
            _environment.ambient_light_color = night_horizon_color
            _environment.ambient_light_energy = ambient_light_strength * ambient_night_factor
    if moon_mesh:
        _moon_material = moon_mesh.material_override as BaseMaterial3D

func _process(delta: float) -> void:
    if player == null or planet == null or moon_light == null or _material == null:
        return

    var up_dir: Vector3 = (player.global_position - planet.global_position).normalized()
    var sun_dir: Vector3 = (moon_light.global_position - planet.global_position).normalized()
    var elevation: float = clamp(sun_dir.dot(up_dir), -1.0, 1.0)

    var daylight: float = clamp((elevation + 0.1) / 0.9, 0.0, 1.0)
    var sunset: float = clamp(1.0 - abs(elevation) / 0.55, 0.0, 1.0)

    var zenith_color: Color = night_zenith_color.lerp(day_zenith_color, daylight)
    zenith_color = zenith_color.lerp(dusk_zenith_color, sunset)

    var horizon_color: Color = night_horizon_color.lerp(day_horizon_color, daylight)
    horizon_color = horizon_color.lerp(dusk_horizon_color, sunset)

    _material.set_shader_parameter("sun_direction", sun_dir)
    _material.set_shader_parameter("zenith_color", zenith_color)
    _material.set_shader_parameter("horizon_color", horizon_color)

    var sun_tint: Color = horizon_color.lerp(Color.WHITE, daylight)
    var moon_glow: Color = sun_tint.lerp(Color.WHITE, moon_brightness_boost)
    moon_light.light_color = moon_glow
    moon_light.light_energy = sun_max_intensity
    if _moon_material:
        _moon_material.albedo_color = moon_glow
        if "emission_enabled" in _moon_material:
            _moon_material.emission_enabled = true
            _moon_material.emission = moon_glow
            _moon_material.emission_energy = 1.0 + moon_brightness_boost * 2.0

    if _environment:
        _environment.background_color = horizon_color
        var ambient_color: Color = horizon_color.lerp(zenith_color, ambient_zenith_influence)
        var ambient_energy: float = lerp(ambient_light_strength * ambient_night_factor, ambient_light_strength, daylight)
        _environment.ambient_light_color = ambient_color
        _environment.ambient_light_energy = ambient_energy
