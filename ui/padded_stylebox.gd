## Decorator style for styleboxes that adds empty padding around the draw area.
##
## @author: erodozer <ero@erodozer.moe>
## [br][br]
## Expands the margins around a stylebox with empty padding. 
## [br]
## Useful for elements such as scrollbars, if you want to have space between
## your content and the grabber.
@tool
class_name PaddedStylebox extends StyleBox

@export var stylebox: StyleBox

var padding: Vector2 :
	get():
		return Vector2(
			content_margin_left + content_margin_right,
			content_margin_top + content_margin_bottom
		)

func _get_minimum_size() -> Vector2:
	return stylebox.get_minimum_size() + padding

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var draw_area = Rect2(rect)
	draw_area.position += get_offset()
	draw_area.size -= padding
	
	stylebox.draw(to_canvas_item, draw_area)
