extends CanvasLayer

@export var player: Node3D
@export var planet: Node3D
@export var sun: Node3D

@onready var label: Label = $Label

func _process(delta: float) -> void:
    var fps := Engine.get_frames_per_second()

    var player_lat_lon := _get_lat_lon_for(player)
    var sun_lat_lon := _get_lat_lon_for(sun)

    label.text = "FPS: %d\nPlayer Lat: %.2f\nPlayer Lon: %.2f\nSun Lat: %.2f\nSun Lon: %.2f" % [
        fps,
        player_lat_lon.x,
        player_lat_lon.y,
        sun_lat_lon.x,
        sun_lat_lon.y
    ]

func _get_lat_lon_for(target: Node3D) -> Vector2:
    if target == null or planet == null:
        return Vector2.ZERO

    var local_pos := planet.to_local(target.global_position)
    if local_pos.length() == 0.0:
        return Vector2.ZERO

    var dir := local_pos.normalized()
    var lat := asin(dir.y)
    var lon := atan2(dir.x, dir.z)
    return Vector2(rad_to_deg(lat), rad_to_deg(lon))
