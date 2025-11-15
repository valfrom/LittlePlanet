extends CanvasLayer

@export var player: Node3D
@export var planet: Node3D

@onready var label: Label = $Label

func _process(delta: float) -> void:
	var fps := Engine.get_frames_per_second()

	var lat_deg := 0.0
	var lon_deg := 0.0

	if player != null and planet != null:
		var local_pos := planet.to_local(player.global_position)
		if local_pos.length() > 0.0:
			var dir := local_pos.normalized()
			var lat := asin(dir.y)
			var lon := atan2(dir.x, dir.z)
			lat_deg = rad_to_deg(lat)
			lon_deg = rad_to_deg(lon)

	label.text = "FPS: %d\nLat: %.2f\nLon: %.2f" % [
		fps,
		lat_deg,
		lon_deg
	]
