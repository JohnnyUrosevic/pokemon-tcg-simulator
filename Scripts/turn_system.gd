extends Control

signal turnEnd
signal clickedConfirm
var mulliganDecision = -1
#######################
#-VARIABLES------------
#######################
#####FOR CONTROLING FLOW######
var control
var turnPlayer = 1
var turn = 1.0
var rng = RandomNumberGenerator.new()
var canSelect
var mulligansTaken = 0
var usedAdditionalMulligan = false
var lastHover = null
#####FOR PLAYER DATA######
var character = "birdTamer"
var deckList
#######################
#-INITIALIZATION-------
#######################
# Called when the node enters the scene tree for the first time.
func randomDeckFromSet(set):
	var setCount
	match set:
		"base1":
			setCount = 102
		"base2":
			setCount = 64
		"base3":
			setCount = 62
		"base5":
			setCount = 82
		"gym1":
			setCount = 132
		"gym2":
			setCount = 132
	var cardList = [] 
	if cardList.size() == 0:
		for n in 60: #makes a random deck
			cardList.append(set+"-"+str(rng.randi_range(1,setCount)))
	return cardList
func _ready():
	control = get_parent()
	deckList= randomDeckFromSet("gym1")
	gamePlay()
func initializeMatch():
	control.generateDeck(deckList,1)
	await get_tree().create_timer(1).timeout
	
	while(true):
		await control.draw7(turnPlayer)
		if(!basicPokemonCheck(1)):
			await MessageMate.displayMessage(get_node("/root/Control/UI_table/messages"),"[center]No Basic Pokemon![/center]",1,)
			await normalMulligan(1) #shuffles hand back into deck
			continue
		elif !usedAdditionalMulligan:
			var cont = await additionalMulliganDecision(1)
			if cont:
				usedAdditionalMulligan = true
				while(true):
					await normalMulligan(1) #shuffles hand back into deck
					await control.draw7(turnPlayer)
					if(!basicPokemonCheck(1)):
						await MessageMate.displayMessage(get_node("/root/Control/UI_table/messages"),"[center]No Basic Pokemon![/center]",1,)
						await normalMulligan(1) #shuffles hand back into deck
						continue
					else:
						break
				break			
			else:
				break
	await pickBasicPokemon(1)
	var hand = get_node("/root/Control/3D_OBJECTS/table/p1/hand")
	for n in hand.get_child_count():
		hand.get_children()[n].lighten()
	await distributePrizeCards()
#######################
#-MAIN PROCESSES-------
#######################
func gamePlay():
	while true:
		await initializeMatch()
		if("1"==str(turnPlayer)):
			await drawCardsFrom("deck",1)
			await turnEnd #called when an action that would end the turn is taken
			passTurn() #increments turn
#######################
#-CONTROL FUNCTIONS----
#######################
func _input(ev):
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_RIGHT:
		if get_node("/root/Control/3D_OBJECTS/table/p"+str(1)+"/designated").get_child_count()>0:
			clickedConfirm.emit()
func drawCardsFrom(container,playerSlot):
	if get_node("/root/Control").draww:
		return
	get_node("/root/Control").draww  = true
	var drawTarget = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/"+container)
	var cardToDraw = drawTarget.get_children()[0]
	if(cardToDraw.cardImage==Image.new()):
		return
	cardToDraw.reparent(get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/hand"),true)
	if container == "deck" or container == "discard":
		cardToDraw.updateTexture()
	alignHand(1)
	await get_tree().create_timer(.2).timeout
	get_node("/root/Control").draww  = false
func passTurn():
	turn+=0.5
	match turnPlayer:
			1:
				turnPlayer = 2
			2:
				turnPlayer = 1
func distributePrizeCards():
	pass
func basicPokemonCheck(playerSlot): #called at the beginning of a match after draw to determine mulligans
	var hand = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/hand")
	var hasBasicPokemon = false
	for n in hand.get_child_count():
		if(!hand.get_children()[n].cardDict.has("subtypes")):
			hand.get_children()[n].darken()
		elif !hand.get_children()[n].cardDict["subtypes"].has("Basic") and !hand.get_children()[n].cardDict["subtypes"].has("Baby") or hand.get_children()[n].cardDict["supertype"]=="Energy":
			hand.get_children()[n].darken()
		else:
			hasBasicPokemon = true
	if(!hasBasicPokemon):
		for n in hand.get_child_count():
			hand.get_children()[n].lighten()
	return hasBasicPokemon
func pickBasicPokemon(playerSlot):
	canSelect = true
	await clickedConfirm
	var designated = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/designated")
	var benchFree = true
	for n in designated.get_child_count():
		if n==0:
			designated.get_children()[0].goActive(playerSlot)
		else:
			benchFree = designated.get_children()[0].goBench(playerSlot)
			if !benchFree:
				break
	var hand = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/hand")
	for n in hand.get_child_count():
		undesignateCard(hand.get_children()[0],playerSlot)
	
func normalMulligan(playerSlot): #called when no basic pokemon are drawn and hand must be redrawn
	mulligansTaken+=1
	var hand = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/hand")
	var handSize = hand.get_children().size()
	for n in handSize:
		returnToDeck(hand.get_children()[handSize-1-n],1)
	await alignDeck(playerSlot)#put cards back in deck
	await shuffleDeck(playerSlot)#rearrange order of cards in deck randomly
func additionalMulliganDecision(playerSlot):
	GeneralMate.moveToLocation2D(get_node("/root/Control/UI_table/mulligan"),Vector2(213,56),0.2,false)
	await GeneralMate.moveToLocation2D(get_node("/root/Control/UI_table/keepHand"),Vector2(487,56),0.2,false)
	while(mulliganDecision == -1):
		await get_tree().create_timer(1.0/144).timeout
	GeneralMate.moveToLocation2D(get_node("/root/Control/UI_table/mulligan"),Vector2(-272,56),0.2,false)
	await GeneralMate.moveToLocation2D(get_node("/root/Control/UI_table/keepHand"),Vector2(965,56),0.2,false)
	if(mulliganDecision == 0):
		mulliganDecision = -1
		return true
	elif(mulliganDecision == 1):
		mulliganDecision = -1
		return false
func alignHand(playerSlot):
	get_node("/root/Control").draww = true
	var hand = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/hand")
	for n in hand.get_child_count():
		var targetLoc =  hand.global_position-hand.basis.x*16*hand.get_child_count()+hand.basis.x*32*n+hand.basis.x*24+Vector3(0,get_node("/root/Control").CARD_STACK_OFFSET*n,0)
		if n!=hand.get_child_count()-1:
			hand.get_children()[n].moveToLocation(hand.get_children()[n],targetLoc,.2,false)
		else:
			await hand.get_children()[n].moveToLocation(hand.get_children()[n],targetLoc,.2,false)
	get_node("/root/Control").draww = false
func alignDesignated(playerSlot):
	var designated = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/designated")
	for n in designated.get_child_count():
		var targetLoc =  designated.global_position+Vector3(-18*designated.get_child_count(),0,0)+Vector3(n*36,get_node("/root/Control").CARD_STACK_OFFSET*n,0)+Vector3(18,0,0)
		if n!=designated.get_child_count()-1:
			designated.get_children()[n].moveToLocation(designated.get_children()[n],targetLoc,.2,true)
		else:
			await designated.get_children()[n].moveToLocation(designated.get_children()[n],targetLoc,.2,true)
func alignDeck(playerSlot):
	var deck = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/deck")
	for n in deck.get_child_count():
		var targetLoc =  deck.global_position+Vector3(0,get_node("/root/Control").CARD_STACK_OFFSET*(deck.get_child_count()-n),0)
		if n!=deck.get_child_count()-1:
			deck.get_children()[n].moveToLocation(deck.get_children()[n],targetLoc,.2,false)
		else:
			await deck.get_children()[n].moveToLocation(deck.get_children()[n],targetLoc,.2,false)
func alignPokemon(container,playerSlot):
	var alignTarget = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/"+container)
	for n in alignTarget.get_child_count():
		var targetLoc =  alignTarget.position+Vector3(0,get_node("/root/Control").CARD_STACK_OFFSET*(n),0)
		if n!=alignTarget.get_child_count()-1:
			alignTarget.get_children()[n].moveToLocation(alignTarget.get_children()[n],targetLoc,.2,false)
		else:
			await alignTarget.get_children()[n].moveToLocation(alignTarget.get_children()[n],targetLoc,.2,false)
func returnToDeck(card, playerSlot): #takes a card from anywhere and returns it to the deck
	var deck = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/deck")
	var texture = load("res://.godot/imported/cardBack.png-1d8732877f92ce0c993bbb589758e78d.ctex")
	var material = StandardMaterial3D.new()
	material.set_texture(0,texture)
	material.no_depth_test = false
	card.set_surface_override_material(0,material)
	card.reparent(deck)
func designateCard(card, playerSlot): #takes a card from anywhere and returns it to the deck
	var designated = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/designated")
	card.reparent(designated)
	alignDesignated(playerSlot)
func undesignateCard(card, playerSlot): #takes a card from anywhere and returns it to the deck
	var undesignated = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/hand")
	card.reparent(undesignated)
	alignHand(playerSlot)
func shuffleDeck(playerSlot):
	randomize()
	get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/deck").get_children().shuffle()
	var deck = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/deck").get_children()
	await alignDeck(playerSlot)

func _on_mulligan_pressed():
	mulliganDecision = 0

func _on_keep_hand_pressed():
	mulliganDecision = 1
