extends Package

func _on_player_detector_body_entered(body):
	body.add_package("light", is_new)
	is_new = false
	queue_free()
