extends Control

signal requestComplete

#######################
#-VARIABLES------------
#######################
var rng = RandomNumberGenerator.new()
var json = JSON.new()
var loadedSetDict = {}
var loadedCardDict = {}
var loadedCardImage = Image.new()
var searchTarget = "base1-4"
var url = "https://api.pokemontcg.io/v2/cards/"+searchTarget
var json_mate = load("res://Scripts/json_mate.gd")

var gameScope = "table"
var playerSlot = "1"
var CARD_STACK_OFFSET = 0.35
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
func _on_set_request_request_completed(result, response_code, headers, body):
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		print("An error occurred trying to get the set.")
		return
	var response = json.get_data()
	loadedSetDict = response["data"]
	print("[GET SET] Data Loaded")
func _on_card_request_request_completed(result, response_code, headers, body):
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		print("An error occurred trying to get the card.")
		return
	var response = json.get_data()
	loadedCardDict = response["data"]
	json_mate.saveJSON(response,response["data"]["id"])
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
func _on_gen_deck_pressed():
	var cardList = []
	for n in 60:
		cardList.append("base1-"+str(rng.randi_range(1,102)))
	generateDeck(cardList)
#######################
#-CARD VIEWER----------
#######################
func loadRandomCardInViewer():
	var texture = load("res://.godot/imported/cardBack.png-1d8732877f92ce0c993bbb589758e78d.ctex")
	var material = StandardMaterial3D.new()
	material.set_texture(0,texture)
	material.no_depth_test = true
	get_node("3D_OBJECTS/viewer/card").set_surface_override_material(0,material)
	var idInSet = rng.randi_range(1,102)
	searchTarget = "base1-"+str(idInSet)
	url = "https://api.pokemontcg.io/v2/cards/"+searchTarget
	if(json_mate.loadJSON(searchTarget)==null):
		$cardRequest.request("https://api.pokemontcg.io/v2/cards/"+searchTarget,['X-Api-Key: ' + API.KEY]);
	else:
		json = json_mate.loadJSON(searchTarget)
		$picRequest.request(json["data"]["images"]["large"],['X-Api-Key: ' + API.KEY])
	await requestComplete
	print("[AWAIT FINISHED] requestCompleted")
	texture = ImageTexture.create_from_image(loadedCardImage)
	material = StandardMaterial3D.new()
	material.set_texture(0,texture)
	material.no_depth_test = true
	get_node("3D_OBJECTS/viewer/card").set_surface_override_material(0,material)
#######################
#-GAME FUNCTIONS-------
#######################
func generateDeck(cardList):
	var deckLocation = get_node("3D_OBJECTS/table/p"+playerSlot+"/deck").global_position
	var card
	var cardsInDeck = get_node("3D_OBJECTS/table/p"+playerSlot+"/deck").get_children()
	for n in get_node("3D_OBJECTS/table/p"+playerSlot+"/deck").get_child_count():
		var thisCard = cardsInDeck[n]
		get_node("3D_OBJECTS/table/p"+playerSlot+"/deck").remove_child(thisCard)
		thisCard.queue_free()
	var deckCount
	for n in cardList.size():
		card = preload("res://Scenes/card.tscn").instantiate()
		get_node("3D_OBJECTS/table/p"+playerSlot+"/deck").add_child(card)
		deckCount = get_node("3D_OBJECTS/table/p"+playerSlot+"/deck").get_child_count()
		card.scale = Vector3(1,1,1)
		card.global_position = deckLocation + Vector3(0,CARD_STACK_OFFSET*deckCount,0)
		card.id = cardList[n]
		card.playerSlot = playerSlot
		print(card.id+","+str(playerSlot))
		card.initialize()
	cardsInDeck.reverse()
	for n in cardList.size():
		card.global_position = deckLocation + Vector3(0,CARD_STACK_OFFSET*deckCount,0)
	
