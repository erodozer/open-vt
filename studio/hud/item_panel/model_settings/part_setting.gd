extends PanelContainer

const VtModel = preload("res://lib/model/vt_model.gd")
const Math = preload("res://lib/utils/math.gd")

var model: VtModel
var part: StringName

func _ready():
	%PartName.text = part
	%Opacity.value = model.get("parts/%s" % [part])
	%Opacity.value_changed.connect(
		func (v):
			model.set("parts/%s" % [part], v)
	)
