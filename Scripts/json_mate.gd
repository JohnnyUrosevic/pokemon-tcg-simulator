extends Node

static func saveJSON(json, id):
	var save_path = "res://jsonData/"+id
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		print("File Error: ", FileAccess.get_open_error())

	file.store_line(JSON.stringify(json))

static func loadJSON(id):
	var save_path = "res://jsonData/"+id
	if FileAccess.file_exists(save_path):
		print("JSON found")
		var file = FileAccess.open(save_path, FileAccess.READ)
		var content = file.get_as_text()
		
		var json = JSON.new()
		var error = json.parse(content)
		if error == OK:
			var data = json.data
			return data
		else:
			print("JSON Parse Error: ", json.get_error_message(), " in ", content, " at line ", json.get_error_line())
			return null
	else:
		print("file not found")
		return null
		
static func jsonExists(id):
	var save_path = "res://jsonData/"+id
	if FileAccess.file_exists(save_path):
		return true
	else:
		return false

	
