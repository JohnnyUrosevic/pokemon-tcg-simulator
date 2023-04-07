extends Node

signal physicsProcess

var messageBeingDisplayed = false

func _physics_process(delta):
	physicsProcess.emit()

func displayMessage(obj,msg,displayTime):
	var timer = 0
	obj.visible = true
	obj.get_node("message").text = msg
	messageBeingDisplayed= true
	await physicsProcess
	await physicsProcess
	messageBeingDisplayed = false
	while timer<1:
		if messageBeingDisplayed:
			return
		timer+=5.0/144
		await physicsProcess
		obj.modulate = Color(1,1,1,timer)
		obj.get_node("message").visible_ratio = timer
	await get_tree().create_timer(displayTime).timeout
	timer = 0
	while timer<1:
		if messageBeingDisplayed:
			return
		timer+=5.0/144
		await physicsProcess
		obj.modulate = Color(1,1,1,1-timer)
	obj.visible = false
