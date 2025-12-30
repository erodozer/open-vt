extends Popup

var accepted: String

func _ready() -> void:
	%RichTextLabel.text = FileAccess.get_file_as_string("res://LICENSE.txt")
	
func save_settings(settings: Dictionary):
	if not accepted.is_empty():
		queue_free()
	
	settings["accepted_terms"] = accepted
	
func load_settings(settings: Dictionary):
	accepted = settings.get("accepted_terms", "")
	if not accepted.is_empty():
		queue_free()
	else:
		show()
	
func _on_accept_pressed() -> void:
	accepted = "%d" % Time.get_unix_time_from_system()
	Preferences.save_data.call_deferred()
	
func _on_reject_pressed() -> void:
	get_tree().quit()

func _on_close_requested() -> void:
	_on_reject_pressed()
