extends Node



static func saveJSON(json, id):
	var save_path = "res://jsonData/"+id
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_line(JSON.stringify(json))
static func loadJSON(id):
	var save_path = "res://jsonData/"+id
	if FileAccess.file_exists(save_path):
		print("file found")
		var file = FileAccess.open(save_path, FileAccess.READ)
		var json = JSON.new()
		var data = json.parse()
		return data
	else:
		print("file not found")

	
