class_name Player
extends CharacterBody3D

@export var planet_center: Node3D
@export var gravity_strength: float = 40.0
@export var move_speed: float = 10.0
@export var jump_speed: float = 14.0
@export var blast_scene: PackedScene
@export var fire_cooldown: float = 0.18

var _fire_timer: float = 0.0

@onready var _muzzle: Node3D = get_node_or_null("Camera3D/Muzzle")

func _get_move_input() -> Vector2:
	var dir := Vector2.ZERO

	if Input.is_action_pressed("move_forward"):
		dir.y += 1.0
	if Input.is_action_pressed("move_back"):
		dir.y -= 1.0
	if Input.is_action_pressed("move_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("move_right"):
		dir.x += 1.0

	return dir.normalized()

func _physics_process(delta: float) -> void:
        if planet_center == null:
                return

        _fire_timer = max(0.0, _fire_timer - delta)

        var up_dir := (global_position - planet_center.global_position).normalized()

	var basis := global_transform.basis
	basis.y = up_dir
	basis.x = up_dir.cross(-basis.z).normalized()
	basis.z = -basis.x.cross(basis.y).normalized()
	global_transform.basis = basis

	var gravity_vec := -up_dir * gravity_strength
	velocity += gravity_vec * delta

	var input_dir := _get_move_input()

	var forward := -global_transform.basis.z
	forward = (forward - up_dir * forward.dot(up_dir)).normalized()
	var right := up_dir.cross(forward).normalized()

	var move_vec := Vector3.ZERO
	if input_dir != Vector2.ZERO:
		move_vec = (forward * input_dir.y + right * input_dir.x).normalized() * move_speed

	var radial := velocity.project(-up_dir)
	var tangential := move_vec
	velocity = tangential + radial

	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity += up_dir * jump_speed

        up_direction = up_dir
        move_and_slide()

        if Input.is_action_pressed("shoot"):
                _try_fire()

func _try_fire() -> void:
        if _fire_timer > 0.0:
                return
        if blast_scene == null or _muzzle == null:
                return

        var blast := blast_scene.instantiate()
        if blast == null:
                return

        var world := get_tree().current_scene
        if world == null:
                return

        world.add_child(blast)
        blast.global_transform = _muzzle.global_transform
        _fire_timer = fire_cooldown
