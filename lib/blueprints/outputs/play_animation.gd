extends "../vt_action.gd"

@onready var input: OptionButton = %Animation

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	for m in model.motions:
		input.add_item(m)
		input.set_item_metadata(input.item_count - 1, m)

	if input.get_item_count() == 0:
		queue_free()
	
func get_type() -> StringName:
	return &"animation"
	
func serialize():
	return {
		"name": input.get_item_text(input.selected),
	}
	
func deserialize(data: Dictionary):
	for i in input.item_count:
		if input.get_item_text(i) == data.get("name"):
			input.select(i)
	
func on_animation_completed():
	slot_updated.emit(0)

func invoke_trigger(slot: int) -> void:
	var animation = input.get_selected_metadata()
	if animation == null:
		return
	
	var idle_player: AnimationPlayer = model.get_idle_animation_player()
	var os_player: AnimationPlayer = model.get_animation_player()

	if slot == 0: #play
		if not os_player.has_animation(animation):
			return
			
		var speed_scale = %Speed/Value.value / 100.0
		os_player.stop()
		os_player.play(
			animation, 0, speed_scale
		)
		var provider = model.mixer.get_node("OneShotMotion")
		var fade = %Fade/Value.value / 1000.0
		var duration = os_player.get_animation(animation).length
		var t = provider.create_tween()
		t.set_speed_scale(speed_scale)
		t.tween_property(provider, "weight", 1.0, fade)
		t.tween_callback(idle_player.stop)
		t.tween_property(provider, "weight", 0.0, fade).set_delay(duration - fade)
		t.tween_callback(idle_player.play)
		# t.tween_callback(provider.reset)
	elif slot == 1: #stop
		if os_player.current_animation == animation:
			os_player.stop()
