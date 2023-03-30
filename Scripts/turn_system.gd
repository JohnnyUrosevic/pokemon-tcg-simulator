extends Control

signal pickedBasicPokemon
signal turnEnd
#######################
#-VARIABLES------------
#######################
var control
var turnPlayer = 1
var turn = 1.0
var rng = RandomNumberGenerator.new()
#######################
#-INITIALIZATION-------
#######################
# Called when the node enters the scene tree for the first time.
func _ready():
	control = get_parent()
	gamePlay()
func initializeMatch():
	var cardList = [] #your deck here
	if cardList.size() == 0:
		for n in 60: #makes a random deck
			cardList.append("base1-"+str(rng.randi_range(1,102)))
	control.generateDeck(cardList,1)
	await get_tree().create_timer(.5).timeout
	var usedAdditionalMulligan = false
	while(true):
		await control.draw7(turnPlayer)
		await get_tree().create_timer(0.5).timeout
		if(await !basicPokemonCheck()):
			await normalMulligan() #shuffles hand back into deck
			continue
		elif !usedAdditionalMulligan:
			var cont = await additionalMulliganDecision()
			if cont:
				usedAdditionalMulligan = true
				continue			
	await pickedBasicPokemon
	await distributePrizeCards()
#######################
#-MAIN PROCESSES-------
#######################
func gamePlay():
	while true:
		await initializeMatch()
		if(control.playerSlot==str(turnPlayer)):
			await drawCardsFrom("deck",1)
			await turnEnd #called when an action that would end the turn is taken
			passTurn() #increments turn
#######################
#-CONTROL FUNCTIONS----
#######################
func drawCardsFrom(container,playerSlot):
	if get_node("/root/Control").draww:
		return
	get_node("/root/Control").draww  = true
	var drawTarget = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/"+container)
	var cardToDraw = drawTarget.get_children()[0]
	if(cardToDraw.cardImage==Image.new()):
		return
	cardToDraw.reparent(get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/hand"),true)
	cardToDraw.updateTexture()
	alignHand(turnPlayer)
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
func basicPokemonCheck(): #called at the beginning of a match after draw to determine mulligans
	pass
func normalMulligan(): #called when no basic pokemon are drawn and hand must be redrawn
	pass
func additionalMulliganDecision():
	pass
func alignHand(playerSlot):
	var hand = get_node("/root/Control/3D_OBJECTS/table/p"+str(playerSlot)+"/hand")
	for n in hand.get_child_count():
		var targetLoc =  hand.global_position+Vector3(-18*hand.get_child_count(),0,0)+Vector3(n*36,get_node("/root/Control").CARD_STACK_OFFSET*n,0)+Vector3(18,0,0)
		hand.get_children()[n].moveToLocation(hand.get_children()[n],targetLoc,.2,false)
