extends Control

var items: Array[Node] = []:
	set(_i):
		items = _i
		do_filter()

var text: String :
	get():
		return %ItemSearch.text.to_lower().strip_edges()

## signal for when the text input has been updated
## occasionally more complex search UIs may benefit from custom control over filtering beyond 
signal text_changed(new_text: String)

func _ready():
	do_filter()

func do_filter():
	var _txt = text
	for item in items:
		var i: String
		if "text" in item:
			i = item.text
		elif item.has_meta("text"):
			i = item.get_meta("text")
		else:
			i = item.name
		var text_matches = i.to_lower().contains(_txt) if not _txt.is_empty() else true
		item.visible = text_matches

func _on_item_search_text_changed(new_text: String) -> void:
	text_changed.emit(new_text)
	do_filter()

func _on_visibility_changed() -> void:
	%ItemSearch.text = ""
