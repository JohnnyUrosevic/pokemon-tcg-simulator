extends Sprite2D

signal physicsProcess

var rng = RandomNumberGenerator.new()
var blinking

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	blink()
	talk()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	physicsProcess.emit()
	
func blink():
	while(true):
		if rng.randi_range(1,400)==1:
			if rng.randf_range(0,1)<(0.8):
				get_child(0).get_child(0).play("Blink")
			else:
				get_child(0).get_child(0).play("DoubleBlink")
			await get_tree().create_timer(rng.randf_range(.5,6)).timeout
		await physicsProcess

func talk():
	while(true):
		#print(get_node("/root/Node2D/messages").modulate.a)
		if get_node("/root/Node2D/messages").modulate.a>=.75:
			if get_node("/root/Node2D/messages/message").visible_ratio<1:
				await physicsProcess
				get_child(1).get_child(0).play("Talk")
				get_child(1).visible = true
				await physicsProcess	
				continue
		get_child(1).get_child(0).stop()
		get_child(1).visible = false
		await physicsProcess	
