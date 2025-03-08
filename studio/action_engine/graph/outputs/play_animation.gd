extends "../vt_action.gd"

const Stage = preload("res://lib/stage.gd")

@onready var input: OptionButton = %Animation
@onready var stage: Stage = get_tree().get_first_node_in_group("system:stage")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	for m in stage.active_model.motions:
		input.add_item(m)
		input.set_item_metadata(input.item_count - 1, m)

	if input.get_item_count() == 0:
		queue_free()
	
func on_animation_completed():
	pass

func invoke_trigger(slot: int) -> void:
	var model = stage.active_model
	
	var animation = input.get_selected_metadata()
	if animation == null:
		return
	
	var player: AnimationPlayer = model.live2d_model.get_animation_player()

	if slot == 2: #play
		if %Delay/Value.value > 0:
			await get_tree().create_timer(%Delay/Value.value / 1000.0).timeout
		
		if not player.has_animation(animation):
			return
			
		player.play(&"RESET")
		player.advance(0)
		player.play(
			animation, 0, %Speed/Value.value / 100.0
		)
	elif slot == 3: #stop
		if player.current_animation == animation:
			player.stop()
