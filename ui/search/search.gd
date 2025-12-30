extends Control

var items: Array = []:
	set(_i):
		items = _i
		do_filter()

var text: String :
	get():
		return %ItemSearch.text.to_lower().strip_edges()

# cache current search results
var _result: Array

## signal for when the text input has been updated
## occasionally more complex search UIs may benefit from custom control over filtering beyond 
signal text_changed(new_text: String)

## emits result of search filter
signal result(found: Array)

func _ready():
	do_filter()

func get_filtered_items():
	return _result

func do_filter():
	var text = %ItemSearch.text
	_result = items.filter(
		func (item):
			var i: String
			if item is Node:
				if item.has_meta("text"):
					i = item.get_meta("text")
				else:
					i = item.name
			elif item is String:
				i = item
			else:
				assert(false, "item is not searchable type String or Node with text")
			return i.to_lower().contains(text) if not text.is_empty() else true
	)
	result.emit(_result)

func _on_item_search_text_changed(text: String) -> void:
	text_changed.emit(text)
	do_filter()

func _on_visibility_changed() -> void:
	%ItemSearch.text = ""
