class_name Player
extends CharacterBody3D


enum Animations {
    JUMP_UP,
    JUMP_DOWN,
    STRAFE,
    WALK,
}

const MOTION_INTERPOLATE_SPEED: float = 10.0
const ROTATION_INTERPOLATE_SPEED: float = 10.0

const MIN_AIRBORNE_TIME: float = 0.1
const JUMP_SPEED: float = 5.0

var airborne_time: float = 100.0

var orientation := Transform3D()
var root_motion := Transform3D()
var motion := Vector2()

@export var planet_center: Node3D
@export var gravity_strength: float = 40.0

@onready var initial_position: Vector3 = transform.origin

@onready var player_input: PlayerInputSynchronizer = $InputSynchronizer
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var player_model: Node3D = $PlayerModel
@onready var shoot_from: Marker3D = player_model.get_node(^"Robot_Skeleton/Skeleton3D/GunBone/ShootFrom")
@onready var crosshair: TextureRect = $Crosshair
@onready var fire_cooldown: Timer = $FireCooldown

@onready var sound_effects: Node = $SoundEffects
@onready var sound_effect_jump: AudioStreamPlayer = sound_effects.get_node(^"Jump")
@onready var sound_effect_land: AudioStreamPlayer = sound_effects.get_node(^"Land")
@onready var sound_effect_shoot: AudioStreamPlayer = sound_effects.get_node(^"Shoot")

@export var player_id: int = 1:
    set(value):
        player_id = value
        $InputSynchronizer.set_multiplayer_authority(value)

@export var current_animation := Animations.WALK


func _ready() -> void:
    # Pre-initialize orientation transform.
    orientation = player_model.global_transform
    orientation.origin = Vector3()
    if not multiplayer.is_server():
        set_process(false)


func _physics_process(delta: float) -> void:
    if multiplayer.is_server():
        apply_input(delta)
    else:
        animate(current_animation, delta)


func animate(anim: int, _delta: float) -> void:
    current_animation = anim as Animations

    if anim == Animations.JUMP_UP:
        animation_tree["parameters/state/transition_request"] = "jump_up"

    elif anim == Animations.JUMP_DOWN:
        animation_tree["parameters/state/transition_request"] = "jump_down"

    elif anim == Animations.STRAFE:
        animation_tree["parameters/state/transition_request"] = "strafe"
        # Change aim according to camera rotation.
        animation_tree["parameters/aim/add_amount"] = player_input.get_aim_rotation()
        # The animation's forward/backward axis is reversed.
        animation_tree["parameters/strafe/blend_position"] = Vector2(motion.x, -motion.y)

    elif anim == Animations.WALK:
        # Aim to zero (no aiming while walking).
        animation_tree["parameters/aim/add_amount"] = 0
        # Change state to walk.
        animation_tree["parameters/state/transition_request"] = "walk"
        # Blend position for walk speed based checked motion.
        animation_tree["parameters/walk/blend_position"] = Vector2(motion.length(), 0)


func apply_input(delta: float) -> void:
    var up_dir: Vector3 = Vector3.UP
    if planet_center:
        up_dir = (global_transform.origin - planet_center.global_transform.origin).normalized()

    var body_basis: Basis = global_transform.basis
    body_basis.y = up_dir
    body_basis.x = up_dir.cross(-body_basis.z).normalized()
    body_basis.z = -body_basis.x.cross(body_basis.y).normalized()
    global_transform.basis = body_basis
    set_up_direction(up_dir)

    motion = motion.lerp(player_input.motion, MOTION_INTERPOLATE_SPEED * delta)

    var camera_basis: Basis = player_input.get_camera_rotation_basis()
    var camera_z: Vector3 = camera_basis.z - up_dir * camera_basis.z.dot(up_dir)
    camera_z = camera_z.normalized()
    var camera_x: Vector3 = camera_basis.x - up_dir * camera_basis.x.dot(up_dir)
    camera_x = camera_x.normalized()

    # Jump/in-air logic.
    airborne_time += delta
    if is_on_floor():
        if airborne_time > 0.5:
            land.rpc()
        airborne_time = 0

    var on_air: bool = airborne_time > MIN_AIRBORNE_TIME

    var radial_velocity: Vector3 = velocity.project(up_dir)

    if not on_air and player_input.jumping:
        radial_velocity = up_dir * JUMP_SPEED
        on_air = true
        # Increase airborne time so next frame on_air is still true.
        airborne_time = MIN_AIRBORNE_TIME
        jump.rpc()

    player_input.jumping = false

    var vertical_velocity: float = radial_velocity.dot(up_dir)

    if on_air:
        if vertical_velocity > 0:
            animate(Animations.JUMP_UP, delta)
        else:
            animate(Animations.JUMP_DOWN, delta)
    elif player_input.aiming:
        # Convert orientation to quaternions for interpolating rotation.
        var q_from: Quaternion = orientation.basis.get_rotation_quaternion()
        var q_to: Quaternion = player_input.get_camera_base_quaternion()
        # Interpolate current rotation with desired one.
        orientation.basis = Basis(q_from.slerp(q_to, delta * ROTATION_INTERPOLATE_SPEED))

        # Change state to strafe.
        animate(Animations.STRAFE, delta)

        root_motion = Transform3D(animation_tree.get_root_motion_rotation(), animation_tree.get_root_motion_position())

        if player_input.shooting and fire_cooldown.time_left == 0:
            var shoot_origin: Vector3 = shoot_from.global_transform.origin
            var shoot_dir: Vector3 = (player_input.shoot_target - shoot_origin).normalized()

            var bullet: CharacterBody3D = preload("res://player/bullet/bullet.tscn").instantiate()
            get_parent().add_child(bullet, true)
            bullet.global_transform.origin = shoot_origin
            # If we don't rotate the bullets there is no useful way to control the particles ..
            bullet.look_at(shoot_origin + shoot_dir)
            bullet.add_collision_exception_with(self)
            shoot.rpc()

    else: # Not in air or aiming, idle.
        # Convert orientation to quaternions for interpolating rotation.
        var target: Vector3 = camera_x * motion.x + camera_z * motion.y
        if target.length() > 0.001:
            var q_from: Quaternion = orientation.basis.get_rotation_quaternion()
            var q_to: Quaternion = Basis.looking_at(target, up_dir).get_rotation_quaternion()
            # Interpolate current rotation with desired one.
            orientation.basis = Basis(q_from.slerp(q_to, delta * ROTATION_INTERPOLATE_SPEED))

        animate(Animations.WALK, delta)

        root_motion = Transform3D(animation_tree.get_root_motion_rotation(), animation_tree.get_root_motion_position())

    # Apply root motion to orientation.
    orientation *= root_motion

    var h_velocity: Vector3 = orientation.origin / delta
    var tangential_velocity: Vector3 = h_velocity - up_dir * h_velocity.dot(up_dir)
    velocity = tangential_velocity + radial_velocity
    velocity += -up_dir * gravity_strength * delta
    set_velocity(velocity)
    move_and_slide()

    orientation.origin = Vector3() # Clear accumulated root motion displacement (was applied to speed).
    orientation = orientation.orthonormalized() # Orthonormalize orientation.

    var forward_dir: Vector3 = -orientation.basis.z
    forward_dir = (forward_dir - up_dir * forward_dir.dot(up_dir)).normalized()
    var oriented_basis: Basis = orientation.basis
    oriented_basis.y = up_dir
    oriented_basis.z = -forward_dir
    oriented_basis.x = oriented_basis.y.cross(oriented_basis.z).normalized()
    oriented_basis.z = -oriented_basis.x.cross(oriented_basis.y).normalized()
    orientation.basis = oriented_basis

    player_model.global_transform.basis = orientation.basis

    # If we're below -40, respawn (teleport to the initial position).
    if transform.origin.y < -40.0:
        transform.origin = initial_position


@rpc("call_local")
func jump() -> void:
    animate(Animations.JUMP_UP, 0.0)
    sound_effect_jump.play()


@rpc("call_local")
func land() -> void:
    animate(Animations.JUMP_DOWN, 0.0)
    sound_effect_land.play()


@rpc("call_local")
func shoot() -> void:
    var shoot_particle = $PlayerModel/Robot_Skeleton/Skeleton3D/GunBone/ShootFrom/ShootParticle
    shoot_particle.restart()
    shoot_particle.emitting = true
    var muzzle_particle = $PlayerModel/Robot_Skeleton/Skeleton3D/GunBone/ShootFrom/MuzzleFlash
    muzzle_particle.restart()
    muzzle_particle.emitting = true
    fire_cooldown.start()
    sound_effect_shoot.play()
