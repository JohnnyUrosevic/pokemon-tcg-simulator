extends Control

signal requestComplete

#######################
#-VARIABLES------------
#######################
var rng = RandomNumberGenerator.new()
var json = JSON.new()
var loadedCardDict = {}
var loadedCardImage = Image.new()
var searchTarget = "base1-4"
var url = "https://api.pokemontcg.io/v2/cards/"+searchTarget
var gameScope = "table"
#######################
#-INITIALIZATION-------
#######################
# Called when the node enters the scene tree for the first time.
func _ready():
	print("SCENE START")
	loadRandomCardInViewer()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
#######################
#-API CALLS------------
#######################
func _on_card_request_request_completed(result, response_code, headers, body):
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		print("An error occurred trying to get the card.")
		return
	var response = json.get_data()
	loadedCardDict = response["data"]
	print("[GET CARD] Data Loaded")
	$picRequest.request(loadedCardDict["images"]["large"])
func _on_pic_request_request_completed(result, response_code, headers, body):
	var error = loadedCardImage.load_png_from_buffer(body)
	print("[GET PIC] Data Loaded")
	requestComplete.emit()
	if error != OK:
		print("An error occurred trying to get the card image.")
		return
#######################
#-UI BUTTONS----------
#######################
func _on_card_viewer_pressed():
	print("[BUTTON] Card Viewer Pressed")
	gameScope = "viewer"
	get_node("3D_OBJECTS/viewer/Camera3Dviewer").make_current()
	get_node("3D_OBJECTS/viewer/card").visible = true
	$UI_table.visible = false
	$UI_viewer.visible = true
func _on_table_pressed():
	print("[BUTTON] To Table Pressed")
	gameScope = "table"
	get_node("3D_OBJECTS/table/p1/Camera3Dp1").make_current()
	get_node("3D_OBJECTS/viewer/card").visible = false
	$UI_table.visible = true
	$UI_viewer.visible = false
	loadRandomCardInViewer()
#######################
#-CARD VIEWER----------
#######################
func loadRandomCardInViewer():
	var idInSet = rng.randi_range(1,102)
	searchTarget = "base1-"+str(idInSet)
	url = "https://api.pokemontcg.io/v2/cards/"+searchTarget
	$cardRequest.request(url)
	await requestComplete
	print("[AWAIT FINISHED] requestCompleted")
	var texture = ImageTexture.create_from_image(loadedCardImage)
	var material = StandardMaterial3D.new()
	material.set_texture(0,texture)
	material.no_depth_test = true
	get_node("3D_OBJECTS/viewer/card").set_surface_override_material(0,material)
