extends Area2D
class_name ShootAtTargetComponent

const BULLET = preload("res://Max/enemy/Bullet.tscn")
@export var target: Node = null
@export var vision_radius: float = 200
@export var bullet_speed: float = 6

@export_range(0, 3, 0.05) var fire_rate: float = 0.5
@export_range(0, 3, 0.05) var fire_rate_variance: float = 0.5

@onready var vision_circle_shape = $VisionCircleShape
@onready var fire_rate_timer = $FireRateTimer

# Called when the node enters the scene tree for the first time.
func _ready():
	
	fire_rate_timer.timeout.connect(_fire_rate_event)
	fire_rate_timer.wait_time = fire_rate
	
	if (target == null):
		target = owner.find_child("PackOfRats")

	vision_circle_shape.shape.radius = vision_radius

func shoot_at_target():
	var new_bullet: Bullet = BULLET.instantiate()
	# Added call_deferred to queue the action since there are also collision checks
	self.call_deferred("add_child", new_bullet)
	new_bullet.start(self.position)
	new_bullet.speed = bullet_speed
	new_bullet.direction = get_parent().position.direction_to(target.position)
	new_bullet.start_traveling = true

func _fire_rate_event():
	shoot_at_target()
	# Add variance to how often the shots occur
	fire_rate_timer.wait_time = fire_rate + randf_range(-fire_rate_variance, fire_rate_variance)

func _on_body_entered(body):
	target = body
	shoot_at_target()
	fire_rate_timer.start()
func _on_body_exited(body):
	target = null
	fire_rate_timer.stop()
