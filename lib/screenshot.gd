"""
Screenshot.gd
@author erodozer <ero@erodozer.moe>
@description |>
	Simple global tool for capturing crisp screenshots with a hotkey
"""

extends Node

func snap(viewport = get_viewport(), idx = Time.get_unix_time_from_system()):
	var hide_state = {}
	var transparent = get_window().transparent_bg
	for i in get_tree().get_nodes_in_group("hide_screenshot"):
		if "visible" in i:
			hide_state[i] = i.visible
			i.visible = false
	
	get_window().transparent_bg = true
	await RenderingServer.frame_post_draw
	var fp = ProjectSettings.globalize_path("user://screenshots")
	if not DirAccess.dir_exists_absolute(fp):
		DirAccess.make_dir_recursive_absolute(fp)
	var image = viewport.get_texture().get_image()
	image.save_png("%s/frame_%d.png" % [fp, idx])
	
	for i in hide_state.keys():
		i.visible = hide_state[i]
	get_window().transparent_bg = transparent

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_screenshot"):
		snap()
		get_tree().set_input_as_handled()
	
