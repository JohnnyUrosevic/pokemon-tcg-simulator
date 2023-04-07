extends MeshInstance3D


signal done
signal physicsProcess

#######################
#-VARIABLES------------
#######################
var json = JSON.new()
var id = "null"
var ownerOf
var cardDict = {}
var cardImage = Image.new()
var bigImage = Image.new()
var bigTexture
var smallTexture
var json_mate = load("res://Scripts/json_mate.gd")
var png_mate = load("res://Scripts/png_mate.gd")
var hovering = false
var darkedOut = false
var revealed = false
var handPosition

var cancelMove = false #set to true when card movement must be overwritten by a subsequent movement
#######################
#-INITIALIZATION-------
#######################
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
func _physics_process(delta):
	physicsProcess.emit()
	if get_node("/root/Control").highlightedCard != self && hovering:
		hovering = false
		if get_parent().name=="hand":
			moveToLocation(self,newHandPosition()+Vector3(0,0,0),.1,true)
func newHandPosition():
	if get_parent().name!="hand":
		return
	
	for n in get_parent().get_child_count():
		var targetLoc = get_parent().global_position-get_parent().basis.x*16*get_parent().get_child_count()+get_parent().basis.x*32*n+get_parent().basis.x*24+Vector3(0,get_node("/root/Control").CARD_STACK_OFFSET*n*3,0)+Vector3(-38,0,0)
		if get_parent().get_children()[n]==self:
			return targetLoc	
func initialize():
	if(!json_mate.jsonExists(id)):
		$cardRequest.request("https://api.pokemontcg.io/v2/cards/"+id,['X-Api-Key: ' + API.KEY]);
	else:
		cardDict = json_mate.loadJSON(id)["data"]
		if(!png_mate.pngExists(id,"small")):
			$picRequest.request(cardDict["images"]["small"],['X-Api-Key: ' + API.KEY])
		else:
			cardImage = png_mate.loadPNG(id,"small")
			smallTexture = ImageTexture.create_from_image(cardImage)
		if(!png_mate.pngExists(id,"large")):
			$picRequest2.request(cardDict["images"]["large"],['X-Api-Key: ' + API.KEY])
		else:
			bigImage = png_mate.loadPNG(id,"large")
			bigTexture = ImageTexture.create_from_image(bigImage)
	ownerOf=self.get_parent().get_parent()
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
				await get_node("/root/Control/TurnSystem").alignHand(1)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed == true and get_parent().name=="designated":
			#get_node("/root/Control/TurnSystem").drawCardsFrom("deck",1)
			get_node("/root/Control/TurnSystem").undesignateCard(self,1)
			await get_node("/root/Control/TurnSystem").alignDesignated(1)
	#CHANGE PICTURE###############
	if get_parent().name!="deck" && get_parent().name.substr(0,5)!="prize" && get_owner_name()==str(1):
		get_node("/root/Control/UI_table/info").texture = bigTexture
	elif get_parent().name!="deck" && get_parent().name.substr(0,5)!="prize" && get_owner_name()==str(2):
		if revealed:
			get_node("/root/Control/UI_table/info").texture = bigTexture
		else:
			get_node("/root/Control/UI_table/info").texture = load ("res://Textures/smallerBack.png")
	else:
		if revealed:
			get_node("/root/Control/UI_table/info").texture = bigTexture
		else:
			get_node("/root/Control/UI_table/info").texture = load ("res://Textures/smallerBack.png")
	#HOVER Highlight CARD##################
	if get_parent().name=="hand" && !hovering && get_node("/root/Control/TurnSystem").canSelect && get_owner_name()==str(1):
		#await physicsProcess
		hoverHighlight()
func _on_area_3d_mouse_entered():
	print(name)
	#HOVER CARD##################
	get_node("/root/Control").hoveringCard = self
func _on_area_3d_mouse_exited():
	if get_node("/root/Control").highlightedCard==self:
		get_node("/root/Control").highlightedCard = null
	if get_node("/root/Control").hoveringCard==self:
		get_node("/root/Control").hoveringCard = null

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
	if darkedOut || get_node("/root/Control").highlightedCard == self || get_node("/root/Control").draww>0:
		return
	if !hovering:
		moveToLocation(self,newHandPosition()+Vector3(0,0,-11),.1,true)
	hovering = true
	get_node("/root/Control").highlightedCard = self
func moveToLocation(obj, location, travelTime, finish):
	get_node("/root/Control").draww +=1
	cancelMove = true
	await physicsProcess
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
		await physicsProcess
	cancelMove = false
	if finish:
		obj.global_position=location
	get_node("/root/Control").draww -=1
func get_owner_name():
	return get_parent().get_parent().name.substr(1,-1)
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
		smallTexture = ImageTexture.create_from_image(cardImage)
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
