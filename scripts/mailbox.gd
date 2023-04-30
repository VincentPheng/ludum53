extends Area2D

@export var required_pkg = ""

func _on_body_entered(body: Package):
	if body.type == required_pkg:
		body.queue_free()
		get_parent().queue_free()
