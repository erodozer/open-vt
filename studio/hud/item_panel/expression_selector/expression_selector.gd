extends ConfirmationDialog

const VtItem = preload("res://lib/items/vt_item.gd")

var item: VtItem

func _ready():
	for e in item.render.expressions:
		var idx = %Expressions.item_count
		%Expressions.add_item(e)
		%Expressions.set_item_metadata(idx, e)
	
func _on_confirmed() -> void:
	var selected = %Expressions.get_selected_metadata()
	item.render.toggle_expression(selected, true, %Duration.value, %Exclusive.button_pressed)
	close_requested.emit()

func _on_canceled() -> void:
	close_requested.emit()

func _on_close_requested() -> void:
	queue_free()
