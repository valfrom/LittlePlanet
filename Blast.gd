extends Node3D

@export var speed: float = 80.0
@export var lifetime: float = 2.5

var _age: float = 0.0

func _physics_process(delta: float) -> void:
        global_position += -global_transform.basis.z * speed * delta
        _age += delta
        if _age >= lifetime:
                queue_free()
