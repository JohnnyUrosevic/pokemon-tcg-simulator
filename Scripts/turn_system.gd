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
	control.generateDeck(cardList)
	await get_tree().create_timer(0.2).timeout
	await control.draw7()
	await pickedBasicPokemon
func gamePlay():
	initializeMatch()
	if(control.playerSlot==str(turnPlayer)):
		await turnEnd #called when an action that would end the turn is taken
		passTurn() #increments turn
func passTurn():
	turn+=0.5
	match turnPlayer:
			1:
				turnPlayer = 2
			2:
				turnPlayer = 1
