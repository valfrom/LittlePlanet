extends Node3D

@export var player: Node3D
@export var planet: Node3D
@export var latitude_visibility: Vector2 = Vector2(-90.0, 90.0)
@export var longitude_visibility: Vector2 = Vector2(-180.0, 180.0)
@export var face_planet: bool = true

func _ready() -> void:
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
