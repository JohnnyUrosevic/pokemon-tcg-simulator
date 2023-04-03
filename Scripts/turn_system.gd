extends Control

signal turnEnd
signal clickedConfirm
signal physicsProcess

var mulliganDecision = -1

#######################
#-VARIABLES------------
#######################
#####FOR CONTROLING FLOW######
var isHost = true
var control
var turnPlayer = 1
var turn = 0
var turnText 
var turnLabel
var rng = RandomNumberGenerator.new()
var canSelect
var mulligansTaken = 0
var mulligansTakenByOpponent = 0
var usedAdditionalMulligan = false
var lastHover = null
var online = true
var opponentReady= false

#####FOR PLAYER DATA######
var character = "birdTamer"
var deckList
var globalPlayer = -1

#######################
#-INITIALIZATION-------
#######################
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
	turnText = get_parent().get_node("UI_table/turnText")
	turnLabel = get_parent().get_node("UI_table/turnLabel")
	control = get_parent()
	deckList= randomDeckFromSet("gym1")
	gamePlay()
func _physics_process(delta):
	physicsProcess.emit()
func initializeOnline():
	turnText.text = "RNG SEED"
	while true:
		if isHost:
			rng.seed = rng.randi()
			turnLabel.text = str(rng.seed)
		await physicsProcess
		continue
func initializeMatch():
	if(online):
		await initializeOnline()
	turnText.text = "[center]000[/center]"
	control.generateDeck(deckList,1)
	await get_tree().create_timer(1).timeout
	await control.drawAmt(1,7)
	if isHost:
		if coinFlip():
			globalPlayer = 1
			await MessageMate.displayMessage(get_node("/root/Control/UI_table/messages"),"[center]Heads! -- Going First![/center]",1,)
		else:
			globalPlayer = 2
			await MessageMate.displayMessage(get_node("/root/Control/UI_table/messages"),"[center]Tails! -- Going Second![/center]",1,)
	while(true):
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
					if(!basicPokemonCheck(1)):
						await MessageMate.displayMessage(get_node("/root/Control/UI_table/messages"),"[center]No Basic Pokemon![/center]",1,)
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
	await drawForOpponentMulligans()
	await MessageMate.displayMessage(get_node("/root/Control/UI_table/messages"),"[center]Battle Start![/center]",1,)
	revealAllPokemon()
func coinFlip():
	var result = rng.randf_range(0,1.0)
	var heads = false
	if result > 0.5:
		heads = true
	return heads
func drawForOpponentMulligans():
	while !opponentReady:
		await physicsProcess
		continue
	await control.drawAmt(1,mulligansTakenByOpponent)
#######################
#-MAIN PROCESSES-------
#######################
func gamePlay():
	await initializeMatch()
	turn=0.5
	var integerString
	var digits
	while true:
		integerString = str(int(round(turn)))
		digits = integerString.length()
		turnText.text = "[center]"+integerString.pad_zeros(4-digits)+"[/center]"
		if("1"==str(turnPlayer)):#1 is our turn, 2 is the opponents turn
			canSelect = true
			GeneralMate.lighten(get_node("/root/Control/UI_table/p1Face"))
			GeneralMate.darken(get_node("/root/Control/UI_table/p2Face"))
			await drawCardsFrom("deck",1)
			await playCards(1)
			await turnEnd #called when an action that would end the turn is taken
		else:
			canSelect = false
			GeneralMate.lighten(get_node("/root/Control/UI_table/p2Face"))
			GeneralMate.darken(get_node("/root/Control/UI_table/p1Face"))
			await turnEnd #called when an action that would end the turn is taken
	passTurn() #increments turn
#######################
#-CONTROL FUNCTIONS----
#######################
func changeControl():
	match turnPlayer:
			1:
				turnPlayer = 2
			2:
				turnPlayer = 1
func _input(ev):
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_RIGHT:
		if get_node("/root/Control/3D_OBJECTS/table/p"+str(1)+"/designated").get_child_count()>0:
			clickedConfirm.emit()
func drawCardsFrom(container,playerSlot):
	get_node("/root/Control").draww  +=1
	var drawTarget = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/"+container)
	var cardToDraw = drawTarget.get_children()[0]
	if(cardToDraw.cardImage==Image.new()):
		return
	cardToDraw.reparent(get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/hand"),true)
	if container == "deck" or container == "discard":
		if playerSlot == 1:
			cardToDraw.updateTexture()
	alignHand(playerSlot)
	await get_tree().create_timer(.2).timeout
	get_node("/root/Control").draww -=1
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
		designated.get_children()[0].get_active_material(0).set_texture(0,get_parent().cardBack)
		if n==0:
			designated.get_children()[0].goActive(playerSlot)
		else:
			benchFree = designated.get_children()[0].goBench(playerSlot)
			if !benchFree:
				break
	for n in designated.get_child_count():
		undesignateCard(designated.get_children()[0],playerSlot)
func normalMulligan(playerSlot): #called when no basic pokemon are drawn and hand must be redrawn
	mulligansTaken+=1
	var hand = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/hand")
	var handSize = hand.get_children().size()
	for n in handSize:
		returnToDeck(hand.get_children()[handSize-1-n],1)
	await alignDeck(playerSlot)#put cards back in deck
	await shuffleDeck(playerSlot)#rearrange order of cards in deck randomly
	await control.drawAmt(turnPlayer,handSize)
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
	get_node("/root/Control").draww +=1
	var hand = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/hand")
	for n in hand.get_child_count():
		var targetLoc =  hand.global_position-hand.basis.x*16*hand.get_child_count()+hand.basis.x*32*n+hand.basis.x*24+Vector3(0,get_node("/root/Control").CARD_STACK_OFFSET*n*3,0)
		if playerSlot == 1:
			targetLoc += Vector3(-38,0,0)
		if n!=hand.get_child_count()-1:
			hand.get_children()[n].moveToLocation(hand.get_children()[n],targetLoc,.2,false)
			hand.get_children()[n].revealed = false
		else:
			await hand.get_children()[n].moveToLocation(hand.get_children()[n],targetLoc,.2,false)
	get_node("/root/Control").draww -=1
	for n in hand.get_child_count():
		hand.get_children()[n].handPosition = hand.get_children()[n].global_position
func alignDesignated(playerSlot):
	get_node("/root/Control").draww +=1
	var designated = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/designated")
	for n in designated.get_child_count():
		var targetLoc =  designated.global_position+Vector3(-18*designated.get_child_count(),0,0)+Vector3(n*36,get_node("/root/Control").CARD_STACK_OFFSET*n,0)+Vector3(18,0,0)
		if n!=designated.get_child_count()-1:
			designated.get_children()[n].moveToLocation(designated.get_children()[n],targetLoc,.2,false)
		else:
			await designated.get_children()[n].moveToLocation(designated.get_children()[n],targetLoc,.2,false)
	get_node("/root/Control").draww -=1
func alignDeck(playerSlot):
	var deck = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/deck")
	for n in deck.get_child_count():
		var targetLoc =  deck.global_position+Vector3(0,get_node("/root/Control").CARD_STACK_OFFSET*(deck.get_child_count()-n),0)
		if n!=deck.get_child_count()-1:
			deck.get_children()[n].moveToLocation(deck.get_children()[n],targetLoc,.2,false)
			deck.get_children()[n].revealed = false
		else:
			await deck.get_children()[n].moveToLocation(deck.get_children()[n],targetLoc,.2,false)
func alignPokemon(container,playerSlot):
	var alignTarget = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/"+container)
	for n in alignTarget.get_child_count():
		var targetLoc =  alignTarget.global_position+Vector3(0,get_node("/root/Control").CARD_STACK_OFFSET*(5+n*5),0)
		if n!=alignTarget.get_child_count()-1:
			alignTarget.get_children()[n].moveToLocation(alignTarget.get_children()[n],targetLoc,.2,false)
			if(turn>0):
				alignTarget.get_children()[n].revaled = true
		else:
			await alignTarget.get_children()[n].moveToLocation(alignTarget.get_children()[n],targetLoc,.2,false)
func returnToDeck(card, playerSlot): #takes a card from anywhere and returns it to the deck
	var deck = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/deck")
	var material = StandardMaterial3D.new()
	material.set_texture(0,get_node("/root/Control/").cardBack)
	material.no_depth_test = false
	card.set_surface_override_material(0,material)
	card.reparent(deck)
func designateCard(card, playerSlot): #takes a card from anywhere and returns it to the deck
	var designated = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/designated")
	card.reparent(designated)
	designated.move_child(card,0)
	await alignDesignated(playerSlot)
func undesignateCard(card, playerSlot): 
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
func revealAllPokemon():
	var pokemon = getInPlayPokemon()
	for n in pokemon.size():
		pokemon[n].revealed = true
		pokemon[n].get_active_material(0).set_texture(0,pokemon[n].smallTexture)
func getInPlayPokemon():
	var n = 1
	var k = 1
	var inPlayPokemon = []
	while (n<3):
		while (k<6):
			inPlayPokemon+=(get_node("/root/Control/3D_OBJECTS/table/p"+str(n)+"/bench"+str(k)).get_children())
			k+=1
		inPlayPokemon+=(get_node("/root/Control/3D_OBJECTS/table/p"+str(n)+"/active").get_children())
		n+=1
	return inPlayPokemon
func playCards(playerSlot):
	var designated = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/designated")
	var hand = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/designated")
	while(true):
		if designated.get_child_count()>1:
			await physicsProcess
			undesignateCard(designated.get_children()[1],playerSlot)
		await physicsProcess
