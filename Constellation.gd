extends Node3D

@export var player: Node3D
@export var planet: Node3D
@export var sun_light: Node3D
@export var latitude_visibility: Vector2 = Vector2(-90.0, 90.0)
@export var longitude_visibility: Vector2 = Vector2(-180.0, 180.0)
@export var face_planet: bool = true
@export_range(0.0, 1.0, 0.01) var day_dim_strength: float = 0.05
@export_range(0.1, 10.0, 0.1) var night_emission: float = 3.0

var _star_materials: Array[BaseMaterial3D] = []

func _ready() -> void:
	_cache_star_materials()
	_update_orientation()
	_update_visibility()

func _process(delta: float) -> void:
	_update_orientation()
	_update_visibility()

func _update_orientation() -> void:
	if not face_planet:
		return
	if planet == null:
		return
	look_at(planet.global_position, Vector3.UP)

func _update_visibility() -> void:
	if player == null or planet == null:
		visible = false
		_apply_star_brightness(0.0)
		return

	var local_pos := planet.to_local(player.global_position)
	if local_pos.length() == 0.0:
		visible = false
		return

	var dir := local_pos.normalized()
	var lat := rad_to_deg(asin(dir.y))
	var lon := rad_to_deg(atan2(dir.x, dir.z))

	var lat_ok: bool = _is_angle_in_range(lat, latitude_visibility)
	var lon_ok: bool = _is_longitude_in_range(lon)
	visible = lat_ok and lon_ok

	var brightness := 0.0
	if visible:
		brightness = _calculate_star_brightness()
	_apply_star_brightness(brightness)

func _is_angle_in_range(angle: float, angle_range: Vector2) -> bool:
	var min_angle := min(angle_range.x, angle_range.y)
	var max_angle := max(angle_range.x, angle_range.y)
	return angle >= min_angle and angle <= max_angle

func _is_longitude_in_range(lon: float) -> bool:
	var start := longitude_visibility.x
	var end := longitude_visibility.y

	if abs(end - start) >= 360.0:
		return true

	if start <= end:
		return lon >= start and lon <= end

	return lon >= start or lon <= end

func _calculate_star_brightness() -> float:
	if player == null or planet == null or sun_light == null:
		return 1.0

	var up_dir := (player.global_position - planet.global_position).normalized()
	var sun_dir := (sun_light.global_position - planet.global_position).normalized()
	var daylight := clamp((sun_dir.dot(up_dir) + 0.1) / 0.9, 0.0, 1.0)
	var night_factor := 1.0 - daylight
	return lerp(day_dim_strength, 1.0, night_factor)

func _apply_star_brightness(strength: float) -> void:
	var emission := night_emission * clamp(strength, 0.0, 1.0)
	for material in _star_materials:
		if material:
			material.emission_enabled = true
			material.emission_energy_multiplier = emission

func _cache_star_materials() -> void:
	_star_materials.clear()
	var stack: Array[Node] = [self]
	while stack.size() > 0:
		var node := stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if node is GeometryInstance3D:
			var material := (node as GeometryInstance3D).material_override
			if material != null and not _star_materials.has(material):
				_star_materials.append(material)
