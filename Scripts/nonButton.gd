extends Sprite2D

var SCALE = global_scale

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_area_2d_mouse_entered():
	print("enter")
	GeneralMate.continuousScale2D(self,SCALE*1.1,0.2,false)
	get_child(0).play(name)
	if name == "casual":
		MessageMate.updateMessage(get_node("/root/Node2D/messages"),"Play a match against trainers from all across the world to enjoy fun games of Pokemon!")
	elif name == "ranked":
		MessageMate.updateMessage(get_node("/root/Node2D/messages"),"Play a match against trainers from all across the world in intensely competitive games of Pokemon!")
	elif name == "friend":
		MessageMate.updateMessage(get_node("/root/Node2D/messages"),"Play a match against a specific person in a game of Pokemon!")
	
	


func _on_area_2d_mouse_exited():
	print("exit")
	get_child(0).stop()
	GeneralMate.continuousScale2D(self,SCALE,0.2,false)
	MessageMate.hideMessage(get_node("/root/Node2D/messages"))
 

func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed == true:
			pass
			#get_node("/root/Node2D").pressedButton(name)
