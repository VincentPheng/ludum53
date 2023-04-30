extends Area2D

signal level_passed

func _on_body_entered(_body):
	if get_tree().get_nodes_in_group("Mailbox").size() <= 0:
		level_passed.emit()
