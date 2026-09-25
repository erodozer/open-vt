extends "res://lib/model/modifier.gd"

var skeleton: Skeleton3D
var bone_idx: int

func _init(sk: Skeleton3D, bone: int):
	skeleton = sk
	bone_idx = bone
	var name = skeleton.get_bone_name(bone).to_camel_case()

func _get_property_list() -> Array[Dictionary]:
	return [
		{
			"name": "parent_bone",
			"type": TYPE_STRING_NAME,
			"hint": PROPERTY_HINT_NONE,
			"usage": PROPERTY_USAGE_READ_ONLY
		},
	]
	
func _get(property: StringName) -> Variant:
	if property == "parent_bone":
		var parent = skeleton.get_bone_parent(bone_idx)
		if parent != -1:
			return skeleton.get_bone_name(parent)
		else:
			return skeleton.get_bone_name(bone_idx)
	return null
