extends RefCounted

enum BlendMode {
	ADD,
	MIX
}

class ParameterMutation:
	var parameter: String
	var value: float
	var blend: BlendMode

var name: String
var parameters: Dictionary = {}

static func load_from_file(path: String):
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	
	var exp = new()
	exp.name = path.get_file()
	for effect in data.Parameters:
		var mut = ParameterMutation.new()
		mut.parameter = effect.Id
		mut.value = effect.Value
		match effect.Blend:
			"Mix":
				mut.blend = BlendMode.MIX
			_:
				mut.blend = BlendMode.ADD
		exp.parameters[effect.Id] = mut
	return exp
