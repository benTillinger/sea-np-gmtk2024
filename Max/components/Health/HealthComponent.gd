extends Node2D
class_name HealthComponent

@export var initial_health: float = 100
var collision_shape: CollisionShape2D = null

func _ready():
	for child in get_parent().get_children():
		if child is CollisionShape2D:
			collision_shape = child
			break
	
	assert(collision_shape != null, "%s HealthComponent does not have collision shape" % get_parent())

# Should tell the parent to play death animation if possible
func take_damage(damage: float):
	initial_health -= damage
	if initial_health <= 0:
		get_parent().queue_free()

func increase_health(number: float):
	initial_health += number
