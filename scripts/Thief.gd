extends CharacterBody2D

signal package_hit(type: Package)

@export var baseSpeed = 100.0
@export var health = 999
@export var knockback_val = 100
@export var combo_knockback = 50

@onready var light_package = preload("res://Projectiles/light_package.tscn")
@onready var medium_package = preload("res://Projectiles/medium_package.tscn")
@onready var heavy_package = preload("res://Projectiles/heavy_package.tscn")
@onready var lightPackageSprite = preload("res://sprites/packages/light_package.png")
@onready var mediumPackageSprite = preload("res://sprites/packages/med_package.png")
@onready var heavyPackageSprite = preload("res://sprites/packages/heavy_package.png")

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
signal drop_package(type, position)

var currSpeed = baseSpeed
var direction = -1
var chasing = false
var running = false
var playerLocation: Vector2
var knockback = false
var carryingPackage = null

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
		if carryingPackage or running:
			var currDirection = direction
			direction = -1 if get_parent().get_node("Player").position.x > position.x else 1
			if currDirection != direction:
				$Sprite2D.flip_h = not $Sprite2D.flip_h
				$PlayerSight.scale *= -1
		elif chasing:
			var currDirection = direction
			direction = 1 if get_parent().get_node("Player").position.x > position.x else -1
			if currDirection != direction:
				$Sprite2D.flip_h = not $Sprite2D.flip_h
				$PlayerSight.scale *= -1
		elif is_on_wall() or not $FloorChecker.is_colliding():
			chasing = false
			direction *= -1
			$Sprite2D.flip_h = not $Sprite2D.flip_h
			$PlayerSight.scale *= -1

		if position.x >= playerLocation.x - 5 && position.x <= playerLocation.x + 5:
			chasing = false
		velocity.x = direction * currSpeed

	move_and_slide()


func _on_package_detector_body_entered(body: Package):
	if abs(body.linear_velocity.x) > 30 or abs(body.linear_velocity.y) > 30:
		package_hit.emit(body.type)
		$BonkSound.play()
		if carryingPackage:
			$RunningStateTimer.start()
			$CurrentPackageSprite.visible = false
			drop_package.emit(carryingPackage, position)
			currSpeed = baseSpeed
			carryingPackage = null
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
		if carryingPackage == null and not running:
			var stolen_package = body.steal_package()
			body.bounce = true
			body.bounceDir = 1 if body.position.x > position.x else -1
			if stolen_package:
				carryingPackage = stolen_package
				currSpeed = 30
				running = true
				match(stolen_package):
					"light":
						$CurrentPackageSprite.texture = lightPackageSprite
					"medium":
						$CurrentPackageSprite.texture = mediumPackageSprite
					"heavy":
						$CurrentPackageSprite.texture = heavyPackageSprite
				$CurrentPackageSprite.visible = true
		else:
			$RunningStateTimer.start()
			$CurrentPackageSprite.visible = false
			drop_package.emit(carryingPackage, position)
			currSpeed = baseSpeed
			carryingPackage = null
			velocity.x = 300 * (-1 if body.position.x > position.x else 1)
			velocity.y = -100
			knockback = true
			move_and_slide()

func _on_player_sight_timer_timeout():
	chasing = false


func _on_running_state_timer_timeout():
	running = false
