extends Area2D

@export var required_pkg = ""

signal package_delivered

func _on_body_entered(body: Package):
	if body.type == required_pkg:
		body.queue_free()
		get_parent().queue_free()
		package_delivered.emit()
