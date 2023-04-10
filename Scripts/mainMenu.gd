extends Node2D

signal physicsProcess

func _ready():
	await get_tree().create_timer(.25).timeout
	showT()
# Called when the node enters the scene tree for the first time.

func _physics_process(delta):
	physicsProcess.emit()


func showT():
	while(true):
		await get_tree().create_timer(.025).timeout
		if get_node("black2").global_position!=Vector2(479,1500):
			GeneralMate.moveToLocation2D(get_node("black2"),Vector2(479,1500),1.2,false)
		if get_node("black").global_position!=Vector2(479,1500):
			GeneralMate.moveToLocation2D(get_node("black"),Vector2(479,1500),.6,false)
		if get_node("Oak").global_position!=Vector2(159,295):
			GeneralMate.moveToLocation2D(get_node("Oak"),Vector2(159,295),.2,false)
		await physicsProcess
