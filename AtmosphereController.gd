extends MeshInstance3D

@export var player: Node3D
@export var planet: Node3D
@export var sun_light: DirectionalLight3D
@export var world_environment: WorldEnvironment
@export var day_zenith_color: Color = Color(0.2, 0.45, 0.95)
@export var day_horizon_color: Color = Color(0.55, 0.75, 1.0)
@export var dusk_zenith_color: Color = Color(0.4, 0.16, 0.26)
@export var dusk_horizon_color: Color = Color(1.0, 0.4, 0.1)
@export var night_zenith_color: Color = Color(0.02, 0.05, 0.1)
@export var night_horizon_color: Color = Color(0.08, 0.04, 0.1)
@export var sun_min_intensity: float = 0.05
@export var sun_max_intensity: float = 2.0

var _material: ShaderMaterial
var _environment: Environment

func _ready() -> void:
    _material = material_override as ShaderMaterial
    if world_environment:
        _environment = world_environment.environment
        if _environment and _environment.background_mode != Environment.BG_COLOR:
            _environment.background_mode = Environment.BG_COLOR

func _process(delta: float) -> void:
    if player == null or planet == null or sun_light == null or _material == null:
        return

    var up_dir: Vector3 = (player.global_position - planet.global_position).normalized()
    var sun_dir: Vector3 = -sun_light.global_transform.basis.z
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
    sun_light.light_color = sun_tint

    var intensity_mix: float = daylight * (1.0 - sunset)
    sun_light.light_energy = lerp(sun_min_intensity, sun_max_intensity, intensity_mix)

    if _environment:
        _environment.background_color = horizon_color
