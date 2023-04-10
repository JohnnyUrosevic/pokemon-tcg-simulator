extends Sprite2D

signal physicsProcess

var SCALE = global_scale
var menu

# Called when the node enters the scene tree for the first time.
func _ready():
	menu = get_node("/root/Node2D")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	physicsProcess.emit()


func _on_area_2d_mouse_entered():
	get_node("select").play()
	print("enter")
	GeneralMate.continuousScale2D(self,SCALE*1.1,0.2,false)
	if name == "casual":
		MessageMate.updateMessage(get_node("/root/Node2D/messages"),"Play a match against trainers from all across the world to enjoy fun games of Pokemon!")
		get_child(0).play(name)
	elif name == "ranked":
		MessageMate.updateMessage(get_node("/root/Node2D/messages"),"Play a match against trainers from all across the world in intensely competitive games of Pokemon!")
		get_child(0).play(name)
	elif name == "friend":
		MessageMate.updateMessage(get_node("/root/Node2D/messages"),"Play a match against a specific person in a game of Pokemon!")
		get_child(0).play(name)
	menu.hovering = self
	


func _on_area_2d_mouse_exited():
	print("exit")
	if name == "casual":
		get_child(0).stop()
	elif name == "ranked":
		get_child(0).stop()
	elif name == "friend":
		get_child(0).stop()
	GeneralMate.continuousScale2D(self,SCALE,0.2,false)
	MessageMate.hideMessage(get_node("/root/Node2D/messages"))
	await physicsProcess
	if menu.hovering==self:
		menu.hovering = null

func _on_area_2d_input_event(viewport, event, shape_idx):
	menu.hovering = self
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed == true:
			await GeneralMate.continuousScale2D(self,SCALE*1.05,0.1,false)
			GeneralMate.continuousScale2D(self,SCALE*1.1,0.3,false)
			if(name=="friend"):
				get_node("/root/Node2D").hideT()
			elif(name=="volumeButton"):
				if get_node("/root/Node2D/VSlider").self_modulate.a>.5:
					GeneralMate.continuousOpac(get_node("/root/Node2D/VSlider"),0,0.2,false)
					get_node("/root/Node2D/VSlider/Sprite2D/Area2D").input_pickable = false
				else:
					get_node("/root/Node2D/VSlider/Sprite2D/Area2D").input_pickable = true
					GeneralMate.continuousOpac(get_node("/root/Node2D/VSlider"),1,0.2,false)
			else:
				MessageMate.updateMessage(get_node("/root/Node2D/messages"),"This feature has not yet been implemented! Please check back later!")
