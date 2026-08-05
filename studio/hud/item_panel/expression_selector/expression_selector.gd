extends ConfirmationDialog

const VtModel = preload("res://lib/model/vt_model.gd")

var item: VtModel

func _ready():
	for e in item.get_expression_controller().expressions:
		var idx = %Expressions.item_count
		%Expressions.add_item(e.get_name())
		%Expressions.set_item_metadata(idx, e)
	
func _on_confirmed() -> void:
	var selected = %Expressions.get_selected_metadata()
	item.toggle_expression(selected.get_name(), true, %Duration.value)
	close_requested.emit()

func _on_canceled() -> void:
	close_requested.emit()

func _on_close_requested() -> void:
	queue_free()
