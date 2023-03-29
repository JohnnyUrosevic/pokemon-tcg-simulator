extends MeshInstance3D

signal done


#######################
#-VARIABLES------------
#######################
var json = JSON.new()
var id = "null"
var playerSlot = -1
var cardDict = {}
var cardImage = Image.new()
var json_mate = load("res://Scripts/json_mate.gd")
var png_mate = load("res://Scripts/png_mate.gd")
var hovering = false

var cancelMove = false #set to true when card movement must be overwritten by a subsequent movement
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
func _process(delta):
	if get_node("/root/Control").highlightedCard != self && hovering:
		hovering = false
		alignHand()
func initialize():
	if(!json_mate.jsonExists(id)):
		$cardRequest.request("https://api.pokemontcg.io/v2/cards/"+id,['X-Api-Key: ' + API.KEY]);
	else:
		cardDict = json_mate.loadJSON(id)["data"]
		if(!png_mate.pngExists(id,"small")):
			$picRequest.request(cardDict["images"]["small"],['X-Api-Key: ' + API.KEY])
		else:
			cardImage = png_mate.loadPNG(id,"small")
#######################
#-CARD INTERFACING----
#######################
#Handles clicking on cards
func _on_area_3d_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed == true and get_parent().name=="deck":
			drawCardsFrom("deck")
	if get_parent().name=="hand" && !hovering:
		hoverHighlight()

#######################
#-CARD FUNCTIONS-------
#######################
func updateTexture():
	if cardImage == Image.new():
		await done
	var texture = ImageTexture.create_from_image(cardImage)
	var material = StandardMaterial3D.new()
	material.set_texture(0,texture)
	material.no_depth_test = false
	set_surface_override_material(0,material)
func drawCardsFrom(container):
	if get_node("/root/Control").draww:
		return
	get_node("/root/Control").draww  = true
	var drawTarget = get_node("/root/Control/3D_OBJECTS/table/p"+playerSlot+"/"+container)
	var cardToDraw = drawTarget.get_children()[0]
	if(cardToDraw.cardImage==Image.new()):
		return
	cardToDraw.reparent(get_node("/root/Control/3D_OBJECTS/table/p"+playerSlot+"/hand"),true)
	cardToDraw.updateTexture()
	alignHand()
	await get_tree().create_timer(.2).timeout
	get_node("/root/Control").draww  = false
func hoverHighlight():
	if get_node("/root/Control").draww:
		return
	if !hovering:
		moveToLocation(self,global_position+Vector3(0,0,-11),.2,false)
	hovering = true
	get_node("/root/Control").highlightedCard = self
func moveToLocation(obj, location, travelTime, finish):
	cancelMove = true
	await obj.get_tree().create_timer(1/144).timeout
	cancelMove = false
	var distance = (location-obj.global_position).length()
	var ogDistance = distance
	var direction = (location-obj.global_position).normalized()
	var time = 0
	while time < travelTime && !cancelMove:
		distance = (location-obj.global_position).length()
		obj.global_position += direction*(1.0/144)*ogDistance/travelTime
		time+=1.0/144
		#print (str(time))
		await obj.get_tree().create_timer(1/144).timeout
	cancelMove = false
	if finish:
		obj.global_position=location
func alignHand():
	var hand = get_node("/root/Control/3D_OBJECTS/table/p"+playerSlot+"/hand")
	for n in hand.get_child_count():
		var targetLoc =  hand.global_position+Vector3(-12*hand.get_child_count(),0,0)+Vector3(n*24,get_node("/root/Control").CARD_STACK_OFFSET*n,0)+Vector3(8,0,0)
		hand.get_children()[n].moveToLocation(hand.get_children()[n],targetLoc,.2,false)
#######################
#-API CALLS------------
#######################
func _on_card_request_request_completed(result, response_code, headers, body):
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		print("An error occurred trying to get the card.")
		print(error)
		return
	var response = json.get_data()
	cardDict = response["data"]
	json_mate.saveJSON(response,id)
	print("[GET CARD] Data Loaded")
	if(!png_mate.pngExists(id,"small")):
		$picRequest.request(cardDict["images"]["small"],['X-Api-Key: ' + API.KEY])
	else:
		cardImage = png_mate.loadPNG(id,"small")
func _on_pic_request_request_completed(result, response_code, headers, body):
	var error = cardImage.load_png_from_buffer(body)
	png_mate.savePNG(cardImage,id,"small")
	print("[GET PIC] Data Loaded")
	if error != OK:
		print("An error occurred trying to get the card image.")
		return
	done.emit()
