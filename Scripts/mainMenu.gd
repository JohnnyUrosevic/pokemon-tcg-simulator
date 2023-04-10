extends Node2D

signal physicsProcess
var cancel
var hovering = null

func _ready():
	await get_tree().create_timer(.25).timeout
	get_node("bgm").play()
	get_node("bgm").volume_db = -40+64*get_node("/root/Node2D/VSlider").value/104
	showT()
# Called when the node enters the scene tree for the first time.

func _physics_process(delta):
	physicsProcess.emit()
	get_node("bgm").volume_db = -40+64*get_node("/root/Node2D/VSlider").value/104
	if get_node("/root/Node2D/VSlider").value<=0:
		get_node("bgm").volume_db = -80

func _input(ev):
	if ev is InputEventMouseButton && hovering == null:
		#GeneralMate.continuousOpac(get_node("/root/Node2D/VSlider"),0,0.2,false)
		pass
		
func showT():
	var timer = 0
	cancel = true
	await physicsProcess
	await physicsProcess
	cancel = false
	while(timer<5 && !cancel):
		await get_tree().create_timer(.025).timeout
		if get_node("black2").global_position!=Vector2(479,1500):
			GeneralMate.moveToLocation2D(get_node("black2"),Vector2(479,1500),1.2,false)
		if get_node("black").global_position!=Vector2(479,1500):
			GeneralMate.moveToLocation2D(get_node("black"),Vector2(479,1500),.6,false)
		if get_node("Oak").global_position!=Vector2(159,295):
			GeneralMate.moveToLocation2D(get_node("Oak"),Vector2(159,295),.2,false)
		await physicsProcess
		timer += 1.0/144
		
func hideT():
	var timer = 0
	cancel = true
	await get_tree().create_timer(.025).timeout
	await physicsProcess
	await physicsProcess
	cancel = false
	while(timer<5 && !cancel):
		await get_tree().create_timer(.025).timeout
		if get_node("black2").global_position!=Vector2(479,1500):
			GeneralMate.moveToLocation2D(get_node("black2"),Vector2(479,31),.1,false)
		if get_node("black").global_position!=Vector2(479,1500):
			GeneralMate.moveToLocation2D(get_node("black"),Vector2(479,0),.5,false)
		if get_node("Oak").global_position!=Vector2(159,295):
			GeneralMate.moveToLocation2D(get_node("Oak"),Vector2(-160,295),.5,false)
		await physicsProcess
