extends PanelContainer

var _queue = []

func alert(msg: String):
	_queue.append(msg)
	
func _process(delta: float) -> void:
	if $AnimationPlayer.is_playing():
		return
	if _queue.is_empty():
		return
	
	$Label.text = _queue.pop_front()
	$AnimationPlayer.play("show")
