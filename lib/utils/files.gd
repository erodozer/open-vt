extends Object
	
static func walk_files(dir: String, extension: String) -> Array[String]:
	var files: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(extension):
			files.append(dir.path_join(f))
		
	for d in DirAccess.get_directories_at(dir):
		files.append_array(walk_files(dir.path_join(d), extension))
	
	return files

## safely parses JSON data from a file
static func read_json(filepath: String) -> Dictionary:
	if not FileAccess.file_exists(filepath):
		return {}

	var file = FileAccess.get_file_as_string(filepath)
	if file.strip_edges().is_empty():
		return {}

	var data = JSON.parse_string(file)
	if data == null:
		push_error("Unable to parse JSON from file: ", filepath)
		return {}
	if not data is Dictionary:
		push_error("Expected a JSON object in file: ", filepath)
		return {}
	return data

## persists data into a readable JSON file
static func write_json(filepath: String, data: Dictionary) -> Error:
	var f = FileAccess.open(filepath, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	
	var out = JSON.stringify(data, "  ")
	f.store_string(out)
	f.close()
	
	return OK
