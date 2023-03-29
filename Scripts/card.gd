extends MeshInstance3D

#######################
#-VARIABLES------------
#######################
var json = JSON.new()
var id = "null"
var playerSlot = -1
var cardDict = {}
var cardImage = Image.new()
var doneLoading = false
var json_mate = load("res://Scripts/json_mate.gd")
#######################
#-INITIALIZATION-------
#######################
# Called when the node enters the scene tree for the first time.
func _ready():
	var texture = load("res://.godot/imported/cardBack.png-1d8732877f92ce0c993bbb589758e78d.ctex")
	var material = StandardMaterial3D.new()
	material.set_texture(0,texture)
	material.no_depth_test = false
	set_surface_override_material(0,material)
func initialize():
	if(json_mate.loadJSON(id)==null):
		$cardRequest.request("https://api.pokemontcg.io/v2/cards/"+id,['X-Api-Key: ' + API.KEY]);
	else:
		json = json_mate.loadJSON(id)
		$picRequest.request(json.get_data()["data"]["images"]["small"],['X-Api-Key: ' + API.KEY])
#######################
#-CARD INTERFACING----
#######################
#Handles clicking on cards
func _on_area_3d_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed == true and get_parent().name=="deck":
			drawCardsFrom("deck")
#######################
#-CARD FUNCTIONS-------
#######################
func updateTexture():
	if get_parent().name!="hand"||!doneLoading:
		return
	var texture = ImageTexture.create_from_image(cardImage)
	var material = StandardMaterial3D.new()
	material.set_texture(0,texture)
	material.no_depth_test = false
	set_surface_override_material(0,material)
func drawCardsFrom(container):
	var drawTarget = get_node("/root/Control/3D_OBJECTS/table/p"+playerSlot+"/"+container)
	var cardToDraw = drawTarget.get_children()[drawTarget.get_child_count()-1]
	cardToDraw.reparent(get_node("/root/Control/3D_OBJECTS/table/p"+playerSlot+"/hand"),true)
	updateTexture()
	var hand = cardToDraw.get_parent()
	for n in hand.get_child_count():
		hand.get_children()[n].global_position =  hand.global_position+Vector3(-8*hand.get_child_count(),0,0)+Vector3(n*16,get_node("/root/Control").CARD_STACK_OFFSET*n,0)+Vector3(8,0,0)
#######################
#-API CALLS------------
#######################
func _on_card_request_request_completed(result, response_code, headers, body):
	var error = json.parse(body.get_string_from_utf8())
	json_mate.saveJSON(json,id)
	if error != OK:
		print("An error occurred trying to get the card.")
		print(error)
		return
	var response = json.get_data()
	cardDict = response["data"]
	print("[GET CARD] Data Loaded")
	$picRequest.request(cardDict["images"]["small"],['X-Api-Key: ' + API.KEY])
func _on_pic_request_request_completed(result, response_code, headers, body):
	var error = cardImage.load_png_from_buffer(body)
	print("[GET PIC] Data Loaded")
	updateTexture()
	if error != OK:
		print("An error occurred trying to get the card image.")
		return
	doneLoading = true
