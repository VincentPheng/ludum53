extends CanvasLayer

@export var next_scene: String

var scene_tree
func _ready():
	scene_tree = get_tree()

func _input(event):
	if event.is_action_pressed("next level") and $ScoreScreen.visible:
		scene_tree.change_scene_to_file(next_scene)
		get_tree().paused = false
	if event.is_action_pressed("restart") and ($ScoreScreen.visible or $EndScreen.visible or $PauseScreen.visible):
		get_tree().reload_current_scene()
		get_tree().paused = false
	if event.is_action_pressed("pause") and not ($ScoreScreen.visible or $EndScreen.visible):
		$PauseScreen.visible = not $PauseScreen.visible
		get_tree().paused = not get_tree().paused

func _on_level_package_count_change(type, count):
	match(type):
		"light":
			$LightPackageCount.text = str(count)
		"medium":
			$MediumPackageCount.text = str(count)
		"heavy":
			$HeavyPackageCount.text = str(count)

func _on_level_show_end_level_screen(score):
	get_tree().paused = true
	$ScoreScreen.visible = true
	$ScoreScreen/ScoreLabelNum.text = str(score)


func _on_replay_button_pressed():
	get_tree().reload_current_scene()
	get_tree().paused = false

func _on_next_button_pressed():
	scene_tree.change_scene_to_file(next_scene)
	get_tree().paused = false


func _on_player_death_signal():
	$EndScreen.visible = true
	get_tree().paused = true


func _on_player_update_hud_health(health):
	match health:
		2:
			$Hearts/Heart3.visible = false
		1:
			$Hearts/Heart2.visible = false
		0:
			$Hearts/Heart.visible = false
