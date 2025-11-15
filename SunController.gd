extends Node3D

const HALF_PI := PI * 0.5

@export_node_path("Node3D") var planet_path: NodePath
@export_node_path("WorldEnvironment") var world_environment_path: NodePath
@export var rotation_speed_y: float = 0.05
@export var rotation_speed_x: float = 0.0
@export var base_light_energy: float = 2.0
@export var color_gradient: Gradient = Gradient.new()
@export var intensity_curve: Curve = Curve.new()

@onready var sun_light: DirectionalLight3D = $DirectionalLight3D
@onready var planet: Node3D = get_node_or_null(planet_path)
@onready var world_environment: WorldEnvironment = get_node_or_null(world_environment_path)

var _sky_material: ShaderMaterial

func _ready() -> void:
    _initialize_gradient()
    _initialize_intensity_curve()
    _cache_sky_material()
    _update_sun_state()

func _process(delta: float) -> void:
    if planet:
        global_position = planet.global_position
    _rotate_sun(delta)
    _update_sun_state()

func _rotate_sun(delta: float) -> void:
    if rotation_speed_y != 0.0:
        rotate_y(rotation_speed_y * delta)
    if rotation_speed_x != 0.0:
        rotate_x(rotation_speed_x * delta)

func _update_sun_state() -> void:
    var sun_direction := (-global_transform.basis.z).normalized()
    var planet_up := _get_planet_up()
    var clamped := clamp(sun_direction.dot(planet_up), -1.0, 1.0)
    var elevation_angle := asin(clamped)
    var normalized := clamp(elevation_angle / HALF_PI * 0.5 + 0.5, 0.0, 1.0)

    var color := color_gradient.sample(normalized)
    sun_light.light_color = color

    var intensity_multiplier := 1.0
    if intensity_curve and intensity_curve.get_point_count() > 0:
        intensity_multiplier = intensity_curve.sample_baked(normalized)
    sun_light.light_energy = base_light_energy * intensity_multiplier

    _apply_sun_direction_to_environment(sun_direction)

func _get_planet_up() -> Vector3:
    if planet:
        return planet.global_transform.basis.y.normalized()
    return Vector3.UP

func _initialize_gradient() -> void:
    if not color_gradient:
        color_gradient = Gradient.new()
    if color_gradient.get_point_count() == 0:
        color_gradient.add_point(0.0, Color(1.0, 0.4, 0.1))
        color_gradient.add_point(0.35, Color(1.0, 0.75, 0.3))
        color_gradient.add_point(1.0, Color(0.35, 0.55, 1.0))

func _initialize_intensity_curve() -> void:
    if not intensity_curve:
        intensity_curve = Curve.new()
    if intensity_curve.get_point_count() == 0:
        intensity_curve.add_point(0.0, 0.05)
        intensity_curve.add_point(0.45, 0.4)
        intensity_curve.add_point(1.0, 1.0)

func _cache_sky_material() -> void:
    if not world_environment:
        return
    var environment := world_environment.environment
    if not environment:
        return
    var sky := environment.sky
    if not sky:
        return
    var material := sky.sky_material
    if material is ShaderMaterial:
        _sky_material = material

func _apply_sun_direction_to_environment(direction: Vector3) -> void:
    if not _sky_material:
        _cache_sky_material()
    if _sky_material:
        _sky_material.set_shader_parameter("sun_direction", direction)
