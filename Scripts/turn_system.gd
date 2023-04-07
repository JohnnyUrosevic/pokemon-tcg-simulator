extends Control

signal turnEnd
signal clickedConfirm
signal physicsProcess
signal decideDrawSignal


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
var mulliganDecision = -1
var mulligansTaken = 0
var mulligansTakenByOpponent = 0
var usedAdditionalMulligan = false
var usedSupporter = false
var attacked = false
var attachedEnergy = false
var lastHover = null
var online = false
var opponentReady= false
var decideDraw = false
var clicked = false
var targetConfirmed = false
var cardTarget
#####FOR PLAYER DATA######
var character = "birdTamer"
var deckList
var globalPlayer = -1
var cardBack = load("res://Textures/smallerBack.png")
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
		for n in 40: #makes a random deck
			cardList.append(set+"-"+str(rng.randi_range(1,setCount)))
		for n in 20: #makes a random deck
			cardList.append("base1-102")
	cardList.shuffle()
	return cardList
func _ready():
	turnText = get_parent().get_node("UI_table/turnText")
	turnLabel = get_parent().get_node("UI_table/turnLabel")
	control = get_parent()
	deckList= randomDeckFromSet("gym1")
	gamePlay()
func _physics_process(delta):
	physicsProcess.emit()
	clicked = false
	targetConfirmed = false
func initializeOnline():
	turnText.text = "RNG SEED"
	while true:
		if isHost:
			rng.seed = rng.randi()
			turnLabel.text = str(rng.seed)
		await physicsProcess
		continue
#####################################################################################@
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
	await distributePrizeCards(1)
	await drawForOpponentMulligans()
	await MessageMate.displayMessage(get_node("/root/Control/UI_table/messages"),"[center]Battle Start![/center]",1,)
	revealAllPokemon()
#############################################################
func coinFlip():
	return true
	var result = rng.randf_range(0,1.0)
	var heads = false
	if result > 0.5:
		heads = true
	return heads
func drawForOpponentMulligans():
	############DEBUGGING CODE####
	opponentReady = true
	mulligansTakenByOpponent= 2
	##############################
	while !opponentReady:
		await physicsProcess
		continue
	
	if mulligansTakenByOpponent == 0:
		return
	await MessageMate.displayMessage(get_node("/root/Control/UI_table/messages"),"[center]Draw for opponent's "+str(mulligansTakenByOpponent)+" mulligans?[/center]",1,)
	for n in mulligansTakenByOpponent:
		GeneralMate.moveToLocation2D(get_node("/root/Control/UI_table/mulliganDraw"),Vector2(353,16),0.2,false)
		await GeneralMate.moveToLocation2D(get_node("/root/Control/UI_table/skipDraw"),Vector2(552,16),0.2,false)
		await decideDrawSignal
		GeneralMate.moveToLocation2D(get_node("/root/Control/UI_table/mulliganDraw"),Vector2(353,-39),0.2,false)
		await GeneralMate.moveToLocation2D(get_node("/root/Control/UI_table/skipDraw"),Vector2(552,-39),0.2,false)
		if !decideDraw:
			return
		await control.drawAmt(1,1)
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
		if(globalPlayer==turnPlayer):#1 is our turn, 2 is the opponents turn
			canSelect = true
			GeneralMate.lighten(get_node("/root/Control/UI_table/p1Face"))
			GeneralMate.darken(get_node("/root/Control/UI_table/p2Face"))
			await drawCardsFrom("deck",1)
			while(!attacked):
				await playCards(1)
			hideAttackButtons()
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
			clicked = true
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if control.hoveringCard!=null:
			targetConfirmed=true
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
	pass
func passTurn():
	turn+=0.5
	match turnPlayer:
		1:
			turnPlayer = 2
		2:
			turnPlayer = 1
	usedSupporter = false
	attachedEnergy = false
	attacked = false
func distributePrizeCards(playerSlot):
	for n in 6:
		var deck = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/deck")
		var cardToDraw = deck.get_children()[0]
		cardToDraw.reparent(get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/prize"+str(n+1)))
		await cardToDraw.moveToLocation(cardToDraw,cardToDraw.get_parent().global_position,0.2,false)
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
	GeneralMate.moveToLocation2D(get_node("/root/Control/UI_table/mulligan"),Vector2(353,16),0.2,false)
	await GeneralMate.moveToLocation2D(get_node("/root/Control/UI_table/keepHand"),Vector2(552,16),0.2,false)
	while(mulliganDecision == -1):
		await get_tree().create_timer(1.0/144).timeout
	GeneralMate.moveToLocation2D(get_node("/root/Control/UI_table/mulligan"),Vector2(353,-39),0.2,false)
	await GeneralMate.moveToLocation2D(get_node("/root/Control/UI_table/keepHand"),Vector2(552,-39),0.2,false)
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
	for n in hand.get_child_count():
		hand.get_children()[n].handPosition = hand.get_children()[n].global_position
	get_node("/root/Control").draww -=1
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
func alignPokemon(container,playerSlot):#called by Card.gd
	var alignTarget = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/"+container)
	for n in alignTarget.get_child_count():
		var targetLoc =  alignTarget.global_position+Vector3(0,get_node("/root/Control").CARD_STACK_OFFSET*(5+n*5),0)
		if n!=alignTarget.get_child_count()-1:
			alignTarget.get_children()[n].moveToLocation(alignTarget.get_children()[n],targetLoc,.2,false)
		else:
			await alignTarget.get_children()[n].moveToLocation(alignTarget.get_children()[n],targetLoc,.2,false)
		if(turn>0):
			revealPokemon(alignTarget.get_children()[n])
func alignEnergy(container, playerSlot):
	var alignTarget = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/"+container.name)
	for n in alignTarget.get_child_count():
		var targetLoc
		if(playerSlot==1):
			targetLoc =  alignTarget.get_children()[0].global_position+Vector3(0,-control.CARD_STACK_OFFSET*(n),-control.CARD_STACK_OFFSET*(n+1)*26)
		else:
			targetLoc =  alignTarget.get_children()[0].global_position+Vector3(0,-control.CARD_STACK_OFFSET*(n),control.CARD_STACK_OFFSET*(n+1)*26)
		if n!=alignTarget.get_child_count()-1:
			alignTarget.get_children()[0].get_children()[n+5].moveToLocation(alignTarget.get_children()[0].get_children()[n+5],targetLoc,.2,false)
		else:
			await alignTarget.get_children()[0].get_children()[n+5].moveToLocation(alignTarget.get_children()[0].get_children()[n+5],targetLoc,.2,false)
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
	if(turn>0):
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
func revealAllPokemon():
	var pokemon = getInPlayPokemon()
	for n in pokemon.size():
		revealPokemon(pokemon[n])
func revealPokemon(card):
	card.revealed = true
	card.get_active_material(0).set_texture(0,card.smallTexture)
func concealPokemon(card):
	card.revealed = false
	card.get_active_material(0).set_texture(0,cardBack)
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
func getActivePokemon(playerSlot):
	return get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/active").get_children()[get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/active").get_child_count()-1]
####################PLAYING CARDS###########################
func showAttackButtons():
	var active = getActivePokemon(1)
	if !active.cardDict.has("attacks"):#no attacks
		return
	if active.cardDict["attacks"].size()==2:#2 attacks:
		GeneralMate.moveToLocation2D(get_node("/root/Control/UI_table/move1"),Vector2(353,12),0.2,false)
		GeneralMate.moveToLocation2D(get_node("/root/Control/UI_table/move2"),Vector2(552,12),0.2,false)
	else:#1 attack
		GeneralMate.moveToLocation2D(get_node("/root/Control/UI_table/move1Big"),Vector2(353,12),0.2,false)
	updateAttackText(active)
func hideAttackButtons():
	GeneralMate.moveToLocation2D(get_node("/root/Control/UI_table/move1"),Vector2(353,-39),0.2,false)
	GeneralMate.moveToLocation2D(get_node("/root/Control/UI_table/move2"),Vector2(552,-39),0.2,false)
func updateAttackText(active):
	if active.cardDict["attacks"].size()==2:#2 attacks:
		get_node("/root/Control/UI_table/move1").text = active.cardDict["attacks"][0]["name"]
		get_node("/root/Control/UI_table/move2").text = active.cardDict["attacks"][1]["name"]
	else:#1 attack
		get_node("/root/Control/UI_table/move1Big").text = active.cardDict["attacks"][0]["name"]
		print("set text to"+active.cardDict["attacks"][0]["name"])
func playCards(playerSlot):
	showAttackButtons()
	var designated = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/designated")
	var hand = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/designated")
	while(!clicked||designated.get_child_count()==0):
		if designated.get_child_count()>1:
			await physicsProcess
			undesignateCard(designated.get_children()[1],playerSlot)
		await physicsProcess
	clicked = false
	var chosenCard = designated.get_children()[0]
	await playByKind(chosenCard,playerSlot)
func playByKind(card,playerSlot):
	match card.cardDict["supertype"]:
		"Pokémon":
			await playPokemon(card,playerSlot)
		"Energy":
			await playEnergy(card,playerSlot)
		"Trainer":
			await playTrainer(card,playerSlot)
func playPokemon(card,playerSlot):
	print("Play pokemon")
	if card.cardDict.has("subtypes"):
		if !card.cardDict["subtypes"].has("Basic"):
			await playEvolution(card, playerSlot)
			return
	revealPokemon(card)
	card.goBench(playerSlot)
	return
func playEnergy(card,playerSlot):
	if attachedEnergy:
		MessageMate.displayMessage(get_node("/root/Control/UI_table/messages"),"[center]Already attached an Energy![/center]",.75,)
		await undesignateCard(card, playerSlot)
		return
	var hand = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/hand")
	for n in hand.get_child_count():
		hand.get_children()[n].darken()
	cardTarget = await confirmTarget(playerSlot,["active","bench1","bench2","bench3","bench4","bench5"])
	if cardTarget!=null:
		revealPokemon(card)
		card.reparent(cardTarget)
		alignEnergy(cardTarget.get_parent(),playerSlot)
		attachedEnergy = true
	canSelect = true
	for n in hand.get_child_count():
		hand.get_children()[n].lighten()
func confirmTarget(playerSlot,acceptableContainers):
	canSelect = false
	var designated = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/designated")
	while designated.get_child_count()==1:
		while (!targetConfirmed || control.hoveringCard == null)&&designated.get_child_count()==1:
			await physicsProcess
		targetConfirmed = false
		if control.hoveringCard.get_parent().get_parent().name=="p"+str(playerSlot):
			for n in acceptableContainers.size():
				if acceptableContainers[n]==control.hoveringCard.get_parent().name:
					return control.hoveringCard
	return null
func playStadium(card,playerSlot):
	print("Play stadium")
	revealPokemon(card)
	if(get_node("/root/Control/3D_OBJECTS/table/stadium").get_child_count()>0):
		var discard = get_node("/root/Control/3D_OBJECTS/table/p/stadium").get_children()[0].ownerOf.get_node("discard")
		get_node("/root/Control/3D_OBJECTS/table/stadium").get_children()[0].reparent(discard)
		for n in discard.get_child_count():
			discard.get_children()[n].moveToLocation(discard.get_children()[n],get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/discard").global_position+Vector3(0,get_node("/root/Control").CARD_STACK_OFFSET*n,0),0.2,false)
	card.reparent(get_node("/root/Control/3D_OBJECTS/table/stadium"))
	await card.moveToLocation(card,get_node("/root/Control/3D_OBJECTS/table/stadium").global_position,0.2,false)
	await MessageMate.displayMessage(get_node("/root/Control/UI_table/messages"),"[center]No card effects exist.[/center]",.75,)
func playTrainer(card,playerSlot):
	print("Play trainer")
	if card.cardDict.has("subtypes"):
		if card.cardDict["subtypes"].has("Supporter"):
			await playSupporter(card, playerSlot)
			return
		if card.cardDict["subtypes"].has("Stadium"):
			await playStadium(card, playerSlot)
			return
	revealPokemon(card)
	card.reparent(get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/trainer"))
	await card.moveToLocation(card,get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/trainer").global_position,0.2,false)
	await MessageMate.displayMessage(get_node("/root/Control/UI_table/messages"),"[center]No card effects exist.[/center]",.75,)
	discardArea(get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/trainer"),playerSlot)
func playSupporter(card,playerSlot):
	if usedSupporter:
		MessageMate.displayMessage(get_node("/root/Control/UI_table/messages"),"[center]Already played a Supporter![/center]",.75,)
		await undesignateCard(card, playerSlot)
		return
	usedSupporter = true
	revealPokemon(card)
	card.reparent(get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/supporter"))
	await card.moveToLocation(card,get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/supporter").global_position,0.2,false)
	await MessageMate.displayMessage(get_node("/root/Control/UI_table/messages"),"[center]No card effects exist.[/center]",.75,)
	discardArea(get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/supporter"),playerSlot)
func playEvolution(card, playerSlot):
	return
func discardArea(container, playerSlot):
	var discard = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/discard")
	for n in container.get_child_count():
		#concealPokemon(container.get_children()[n])
		container.get_children()[n].reparent(discard)
	for n in discard.get_child_count():
		discard.get_children()[n].moveToLocation(discard.get_children()[n],get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/discard").global_position+Vector3(0,get_node("/root/Control").CARD_STACK_OFFSET*n,0),0.2,false)
############################################################
func _on_mulligan_draw_pressed():
	decideDraw = true
	decideDrawSignal.emit()
func _on_skip_draw_pressed():
	decideDraw = false
	decideDrawSignal.emit()
func _on_mulligan_pressed():
	mulliganDecision = 0
func _on_keep_hand_pressed():
	mulliganDecision = 1
