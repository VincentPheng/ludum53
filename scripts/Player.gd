extends CharacterBody2D
class_name Player

@export var SPEED = 300.0
@export var JUMP_VELOCITY = -400.0
@export var health: int = 3
@export var bounce_speed = 300

@onready var animated_sprite = $AnimatedSprite2D

signal package_pickup(type, is_new)
signal update_hud_health(health)
signal death_signal()

var facing = 1
var bounce = false
var bounceDir = 1

var numLightPackages = 0
var numMediumPackages = 0
var numHeavyPackages = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if bounce:
		velocity.x = bounceDir * bounce_speed
		velocity.y = -1 * (bounce_speed / 4.0)
		bounce = false
	else:
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction = Input.get_axis("left", "right")
		if direction:
			should_flip_sprite(direction)
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, 15)

	move_and_slide()

func take_damage():
	health -= 1
	update_hud_health.emit(health)
	if health <= 0:
		death_signal.emit()

func add_package(type, is_new):
	print(type)
	match(type):
		"light":
			numLightPackages += 1
		"medium":
			numMediumPackages += 1
		"heavy":
			numHeavyPackages += 1
	package_pickup.emit(type, is_new)

func should_flip_sprite(direction):
	if direction > 0 and animated_sprite.is_flipped_h():
		facing = 1
		animated_sprite.set_flip_h(false)
	elif direction < 0 and not animated_sprite.is_flipped_h():
		facing = -1
		animated_sprite.set_flip_h(true)
