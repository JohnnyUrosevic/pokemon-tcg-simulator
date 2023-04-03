extends Node

signal physicsProcess

var active
var turnSys
var control
var deckList = []

# Called when the node enters the scene tree for the first time.
func _ready():
	turnSys = get_node("/root/Control/TurnSystem")
	control = get_node("/root/Control")
	#print("calling AI")
	#callAI()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	physicsProcess.emit()

func callAI():
	while(true):
		deckList = turnSys.randomDeckFromSet("base5")
		print("created random AI deckList")
		control.generateDeck(deckList,2)
		print("successfully generated opponent AI deck")
		await get_tree().create_timer(1).timeout
		await control.drawAmt(2,7)
		while(true):
			# no decisionMakingImplemented
			await physicsProcess
			if(turnSys.turnPlayer==1):
				continue
			elif(turnSys.turnPlayer==2):
				continue
