extends CanvasLayer

func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
		
func _process(delta: float) -> void:
	$Label.text = "FPS: %d" % [Engine.get_frames_per_second()]
