extends Node

var messageBeingDisplayed = false

func displayMessage(obj,msg,displayTime):
	
	
	var timer = 0
	obj.get_node("message").text = msg
	while timer<1:
		timer+=5.0/144
		await get_tree().create_timer(1.0/144).timeout
		obj.modulate = Color(1,1,1,timer)
		obj.get_node("message").visible_ratio = timer
	await get_tree().create_timer(displayTime).timeout
	timer = 0
	while timer<1:
		timer+=5.0/144
		await get_tree().create_timer(1.0/144).timeout
		obj.modulate = Color(1,1,1,1-timer)
