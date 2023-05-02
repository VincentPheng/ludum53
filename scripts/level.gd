extends Node

@onready var player: Player = get_node("Player")
@onready var light_package = preload("res://Projectiles/light_package.tscn")
@onready var medium_package = preload("res://Projectiles/medium_package.tscn")
@onready var heavy_package = preload("res://Projectiles/heavy_package.tscn")

@export var startingLightPkgs = 0
@export var startingMediumPkgs = 0
@export var startingHeavyPkgs = 0

var lightPkgHealth = 0
var mediumPkgHealth = 0
var heavyPkgHealth = 0

var combo = 1
var numMailboxesStart = 0
var currNumMailboxes = 0

var rng = RandomNumberGenerator.new()

signal package_count_change(type, count)
signal combo_increase(combo_val)
signal show_end_level_screen(score)

func _ready():
	var player = get_node("Player")
	var hud = get_node("HUD")
	var exit = get_node("Exit")
	var muggers = get_tree().get_nodes_in_group("Mugger")
	var mailboxes = get_tree().get_nodes_in_group("Mailbox")
	var thieves = get_tree().get_nodes_in_group("Thief")
	
	package_count_change.connect(hud._on_level_package_count_change)
	combo_increase.connect(hud._on_combo_increase)
	show_end_level_screen.connect(hud._on_level_show_end_level_screen)
	player.update_package_count.connect(_on_package_count_change)
	player.reset_combo.connect(_on_reset_combo)
	player.death_signal.connect(hud._on_player_death_signal)
	player.package_pickup.connect(_on_player_package_pickup)
	player.update_hud_health.connect(hud._on_player_update_hud_health)
	exit.level_passed.connect(_on_exit_level_passed)
	for mugger in muggers:
		mugger.package_hit.connect(_on_mugger_package_hit)
	for mailbox in mailboxes:
		mailbox.get_child(0).package_delivered.connect(_on_package_delievered)
	for thief in thieves:
		thief.drop_package.connect(_on_drop_package)
	
	
	player.numLightPackages = startingLightPkgs
	player.numMediumPackages = startingMediumPkgs
	player.numHeavyPackages = startingHeavyPkgs
	
	package_count_change.emit("light", player.numLightPackages)
	package_count_change.emit("medium", player.numMediumPackages)
	package_count_change.emit("heavy", player.numHeavyPackages)
	
	lightPkgHealth = startingLightPkgs * light_package.instantiate().health
	mediumPkgHealth = startingMediumPkgs * medium_package.instantiate().health
	heavyPkgHealth = startingHeavyPkgs * heavy_package.instantiate().health
	
	numMailboxesStart = get_tree().get_nodes_in_group("Mailbox").size()
	currNumMailboxes = numMailboxesStart
	combo_increase.emit(currNumMailboxes, combo)

func _input(event):
	if event.is_action_pressed("throw light"):
		throw_package("light")
	if event.is_action_pressed("throw medium"):
		throw_package("medium")
	if event.is_action_pressed("throw heavy"):
		throw_package("heavy")

func instance_package(type, should_check) -> Package:
	var pkg_instance: Package
	match(type):
		"light":
			if should_check:
				if player.numLightPackages > 0:
					pkg_instance = light_package.instantiate()
			else:
				pkg_instance = light_package.instantiate()
		"medium":
			if should_check:
				if player.numMediumPackages > 0:
					pkg_instance = medium_package.instantiate()
			else:
				pkg_instance = medium_package.instantiate()
		"heavy":
			if should_check:
				if player.numHeavyPackages > 0:
					pkg_instance = heavy_package.instantiate()
			else:
				pkg_instance = heavy_package.instantiate()
	return pkg_instance

func throw_package(type):
	var pkg_instance = instance_package(type, true)
	if pkg_instance:
		pkg_instance.position = Vector2(
			player.position.x + (player.facing * 20), player.position.y)
		pkg_instance.rotation = rng.randf_range(-180.0, 180.0)
		pkg_instance.apply_impulse(
			Vector2(
				pkg_instance.impulse_x * player.facing, pkg_instance.impulse_y))
		pkg_instance.is_new = false
		add_child(pkg_instance)
		remove_package(type)

func _on_drop_package(type, pkgPosition):
	var pkg_instance = instance_package(type, false)
	if pkg_instance:
		pkg_instance.position = Vector2(
			pkgPosition.x, pkgPosition.y - 20)
		pkg_instance.rotation = rng.randf_range(-180.0, 180.0)
		pkg_instance.apply_impulse(
			Vector2(
				500 * (1 if player.position.x > pkgPosition.x else -1), 0))
		pkg_instance.is_new = false
		call_deferred("add_child", pkg_instance)

func _on_package_count_change(type, count):
	match(type):
		"light":
			package_count_change.emit("light", count)
		"medium":
			package_count_change.emit("medium", count)
		"heavy":
			package_count_change.emit("heavy", count)

func remove_package(type):
	match(type):
		"light":
			player.numLightPackages -= 1
			package_count_change.emit("light", player.numLightPackages)
		"medium":
			player.numMediumPackages -= 1
			package_count_change.emit("medium", player.numMediumPackages)
		"heavy":
			player.numHeavyPackages -= 1
			package_count_change.emit("heavy", player.numHeavyPackages)

func _on_package_delievered():
	combo += 1
	currNumMailboxes -= 1
	combo_increase.emit(currNumMailboxes, combo)

func _on_mugger_package_hit(type):
	match(type):
		"light":
			lightPkgHealth -= 1
		"medium":
			mediumPkgHealth -= 1
		"heavy":
			heavyPkgHealth -= 1

func _on_reset_combo():
	if combo > 1:
		combo -= 1
	combo_increase.emit(currNumMailboxes, combo)

func _on_player_package_pickup(type, is_new):
	match(type):
		"light":
			package_count_change.emit("light", player.numLightPackages)
			if is_new:
				lightPkgHealth += light_package.instantiate().health
		"medium":
			package_count_change.emit("medium", player.numMediumPackages)
			if is_new:
				mediumPkgHealth += medium_package.instantiate().health
		"heavy":
			package_count_change.emit("heavy", player.numHeavyPackages)
			if is_new:
				heavyPkgHealth += heavy_package.instantiate().health


func _on_exit_level_passed():
	var baseScore = (numMailboxesStart * 100) + (lightPkgHealth * 500) + (mediumPkgHealth * 300) + (heavyPkgHealth * 100)
	show_end_level_screen.emit(baseScore * combo)
