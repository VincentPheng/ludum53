extends CharacterBody2D
class_name Player

@export var SPEED = 300.0
@export var JUMP_VELOCITY = -400.0
@export var health: int = 3
@export var bounce_speed = 300

@onready var animated_sprite = $AnimatedSprite2D

signal package_pickup(type, is_new)
signal reset_combo
signal update_hud_health(health)
signal death_signal()
signal update_package_count(type, count)

var facing = 1
var bounce = false
var bounceDir = 1
var invincible = false
var can_jump = true
var rng = RandomNumberGenerator.new()

var numLightPackages = 0
var numMediumPackages = 0
var numHeavyPackages = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _input(event):
	if event.is_action_pressed("throw light"):
		$ThrowAudio.play()
	if event.is_action_pressed("throw medium"):
		$ThrowAudio.play()
	if event.is_action_pressed("throw heavy"):
		$ThrowAudio.play()

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		if $JumpTimer.time_left <= 0:
			$JumpTimer.start()
		velocity.y += gravity * delta
	else:
		can_jump = true

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
	floor_snap_length = 0.0
	move_and_slide()

func take_damage():
	if not invincible:
		$BlinkingAnimation.play("blinking")
		$InvincibilityTimer.start()
		invincible = true
		health -= 1
		update_hud_health.emit(health)
		reset_combo.emit()
		if health <= 0:
			death_signal.emit()

func steal_package():
	if not invincible:
		$BlinkingAnimation.play("blinking")
		$InvincibilityTimer.start()
		reset_combo.emit()
		var packages_available = []
		if numLightPackages > 0:
			packages_available.append("light")
		if numMediumPackages > 0:
			packages_available.append("medium")
		if numHeavyPackages > 0:
			packages_available.append("heavy")
		if len(packages_available) > 0:
			var package_to_steal = packages_available[rng.randi_range(0, len(packages_available) - 1)]
			if package_to_steal:
				invincible = true
				match(package_to_steal):
					"light":
						numLightPackages -= 1
						update_package_count.emit("light", numLightPackages)
					"medium":
						numMediumPackages -= 1
						update_package_count.emit("medium", numMediumPackages)
					"heavy":
						numHeavyPackages -= 1
						update_package_count.emit("heavy", numHeavyPackages)
				return package_to_steal
		else:
			take_damage()
			invincible = true

func add_package(type, is_new):
	$CollectAudio.play()
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


func _on_invincibility_timer_timeout():
	invincible = false
	self.visible = true
	$BlinkingAnimation.stop()


func _on_jump_timer_timeout():
	can_jump = false
