extends Object

## fetch values from nested dictionaries using dot-path traversal
static func path(dict: Dictionary, key: String, defaultValue: Variant = null) -> Variant:
	var levels = key.split(".")
	var level = levels[0]
	
	if len(levels) > 1:
		if dict.get(level) is Dictionary:
			return path(dict.get(level), ".".join(levels.slice(1)), defaultValue)
		return null
	return dict.get(level, defaultValue)
	
## determine if a nested dictionary contains a key by its dot-path
static func has_path(dict: Dictionary, key: String) -> bool:
	var levels = key.split(".")
	var level = levels[0]
	
	if len(levels) > 1:
		if dict.get(level) is Dictionary:
			return has_path(dict.get(level), ".".join(levels.slice(1)))
		return false
	return level in dict

## fetch against multiple dictionaries, returning the first found value
static func get_deep(dicts: Array[Dictionary], key: String, defaultValue: Variant):
	for i in dicts:
		if has_path(i, key):
			return path(i, key, defaultValue)
	return defaultValue
