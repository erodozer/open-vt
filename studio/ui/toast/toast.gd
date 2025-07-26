extends PanelContainer

var _queue = []

@onready var anim = $AnimationPlayer

var message: String :
	set(t):
		$Label.text

func alert(msg: String):
	_queue.append(msg)
	
func pop_toast():
	message = _queue.pop_front()
	anim.play("show")

	
func _process(_delta: float) -> void:
	if anim.is_playing():
		return
	if _queue.is_empty():
		return
	
	pop_toast()
