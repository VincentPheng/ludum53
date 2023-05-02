extends CharacterBody2D

signal package_hit(type: Package)

@export var SPEED = 300.0
@export var health = 999
@export var knockback_val = 100
@export var combo_knockback = 50

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var direction = -1
var chasing = false
var playerLocation: Vector2
var knockback = false

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	if knockback:
		if is_on_floor():
			knockback = false
	else:
		if $PlayerSight.is_colliding():
			$PlayerSightTimer.start()
			chasing = true
			var player: Player = $PlayerSight.get_collider() as CharacterBody2D
			playerLocation = player.position
		if chasing:
			var currDirection = direction
			direction = 1 if get_parent().get_node("Player").position.x > position.x else -1
			if currDirection != direction:
				$Sprite2D.flip_h = not $Sprite2D.flip_h
				$PlayerSight.scale *= -1
		if is_on_wall() or not $FloorChecker.is_colliding():
			chasing = false
			direction *= -1
			$Sprite2D.flip_h = not $Sprite2D.flip_h
			$PlayerSight.scale *= -1
		velocity.x = direction * SPEED

	move_and_slide()


func _on_package_detector_body_entered(body: Package):
	if abs(body.linear_velocity.x) > 30 or abs(body.linear_velocity.y) > 30:
		$BonkSound.play()
		package_hit.emit(body.type)
		body.health -= 1
		health -= body.damage
		body.apply_impulse(body.linear_velocity * -1)
		if health <= 0:
			queue_free()
		velocity.x = (1 if body.linear_velocity.x < 0 else -1) * (-1 * (knockback_val + (combo_knockback * get_parent().combo)))
		velocity.y = -100
		knockback = true
		move_and_slide()


func _on_player_detector_body_entered(body: Player):
	if not body.invincible:
		body.take_damage()
		body.bounce = true
		body.bounceDir = 1 if body.position.x > position.x else -1


func _on_player_sight_timer_timeout():
	chasing = false
