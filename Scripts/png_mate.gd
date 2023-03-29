extends Node

static func savePNG(png, id, size):
	var save_path = "res://pngData/"+id+"-"+size+"-"
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		print("File Error: ", FileAccess.get_open_error())
		
	file.store_buffer(png.save_png_to_buffer())

static func loadPNG(id, size):
	var buffer
	if(size=="small"):
		buffer = 400000
	else:
		buffer = 1000000
	var save_path = "res://pngData/"+id+"-"+size+"-"
	if FileAccess.file_exists(save_path):
		print("PNG found")
		var file = FileAccess.open(save_path, FileAccess.READ)
		var content = file.get_buffer(buffer)
		var img = Image.new()
		var error = img.load_png_from_buffer(content)
		if error != OK:
			print("An error occurred trying to get the card image.")
			return null
		return img
	else:
		print("file not found")
		return null
		
static func pngExists(id,size):
	var save_path = "res://pngData/"+id+"-"+size+"-"
	if FileAccess.file_exists(save_path):
		return true
	else:
		return false

