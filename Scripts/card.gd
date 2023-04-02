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
var bigImage = Image.new()
var bigTexture
var json_mate = load("res://Scripts/json_mate.gd")
var png_mate = load("res://Scripts/png_mate.gd")
var hovering = false
var darkedOut = false

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
		await get_node("/root/Control/TurnSystem").alignHand(1)
func initialize():
	if(!json_mate.jsonExists(id)):
		$cardRequest.request("https://api.pokemontcg.io/v2/cards/"+id,['X-Api-Key: ' + API.KEY]);
	else:
		cardDict = json_mate.loadJSON(id)["data"]
		if(!png_mate.pngExists(id,"small")):
			$picRequest.request(cardDict["images"]["small"],['X-Api-Key: ' + API.KEY])
		else:
			cardImage = png_mate.loadPNG(id,"small")
		if(!png_mate.pngExists(id,"large")):
			$picRequest2.request(cardDict["images"]["large"],['X-Api-Key: ' + API.KEY])
		else:
			bigImage = png_mate.loadPNG(id,"large")
			bigTexture = ImageTexture.create_from_image(bigImage)
	done.emit()
#######################
#-CARD INTERFACING----
#######################
#Handles clicking on cards
func _on_area_3d_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed == true and get_parent().name=="hand" && get_node("/root/Control/TurnSystem").canSelect:
			#get_node("/root/Control/TurnSystem").drawCardsFrom("deck",1)
			if(get_node("/root/Control").highlightedCard == self):
				get_node("/root/Control/TurnSystem").designateCard(self,1)
				get_node("/root/Control/TurnSystem").alignHand(1)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed == true and get_parent().name=="designated":
			#get_node("/root/Control/TurnSystem").drawCardsFrom("deck",1)
			get_node("/root/Control/TurnSystem").undesignateCard(self,1)
			await get_node("/root/Control/TurnSystem").alignDesignated(1)
	if get_parent().name=="hand" && !hovering && get_node("/root/Control/TurnSystem").canSelect:
		hoverHighlight()
func _on_area_3d_mouse_entered():
	print(name)
	if get_parent().name!="deck":
		if(get_node("/root/Control/TurnSystem").lastHover==self):
			return
		get_node("/root/Control/UI_table/info").texture = bigTexture
		get_node("/root/Control/TurnSystem").lastHover = self
func _on_area_3d_mouse_exited():
	get_node("/root/Control").highlightedCard = null

#######################
#-CARD FUNCTIONS-------
#######################
func goActive(playerSlot):
	var active = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/active")
	reparent(active)
	#await moveToLocation(self,active.global_position,0.2,true)
	get_node("/root/Control/TurnSystem").alignPokemon("active",playerSlot)
func goBench(playerSlot):
	var benchNumber = 1
	while(get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/bench"+str(benchNumber)).get_child_count()>0):
		benchNumber+=1
		if(benchNumber>5):
			return false
	var bench = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/bench"+str(benchNumber))
	reparent(bench)
	#await moveToLocation(self,bench.global_position,0.2,true)
	get_node("/root/Control/TurnSystem").alignPokemon("bench"+str(benchNumber),playerSlot)
	return true
func darken():
	var timer = 0
	darkedOut = true
	while timer<1:
		timer+=5.0/144
		await get_tree().create_timer(1.0/144).timeout
		get_surface_override_material(0).albedo_color = Color(1-timer/2,1-timer/2,1-timer/2,1)
func lighten():
	var timer = 0
	darkedOut = false
	while timer<1:
		timer+=5.0/144
		await get_tree().create_timer(1.0/144).timeout
		get_surface_override_material(0).albedo_color = Color(.5+timer/2,.5+timer/2,.5+timer/2,1)
func updateTexture():
	if cardImage == Image.new():
		await done
	var texture = ImageTexture.create_from_image(cardImage)
	var material = StandardMaterial3D.new()
	material.set_texture(0,texture)
	material.no_depth_test = false
	set_surface_override_material(0,material)
func hoverHighlight():
	if darkedOut:
		return
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
	if(!png_mate.pngExists(id,"large")):
		$picRequest2.request(cardDict["images"]["large"],['X-Api-Key: ' + API.KEY])
	else:
		bigImage = png_mate.loadPNG(id,"large")
		bigTexture = ImageTexture.create_from_image(bigImage)
	done.emit()
func _on_pic_request_request_completed(result, response_code, headers, body):
	var error = cardImage.load_png_from_buffer(body)
	png_mate.savePNG(cardImage,id,"small")
	print("[GET PIC] Data Loaded")
	if error != OK:
		print("An error occurred trying to get the card image.")
		return
	done.emit()
func _on_pic_request_2_request_completed(result, response_code, headers, body):
	var error = bigImage.load_png_from_buffer(body)
	bigTexture = ImageTexture.create_from_image(bigImage)
	png_mate.savePNG(bigImage,id,"large")
	#print("[GET bigPIC] Data Loaded")
	if error != OK:
		print("An error occurred trying to get the card image.")
		return
	done.emit()
