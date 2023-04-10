extends Node

signal physicsProcess

var messagesBeingDisplayed = []

func _physics_process(delta):
	physicsProcess.emit()

func displayMessage(obj,msg,displayTime):
	messagesBeingDisplayed.erase(self)
	var timer = 0
	obj.visible = true
	obj.get_node("message").text = msg
	messagesBeingDisplayed.append(self)
	await physicsProcess
	while timer<1:
		if messagesBeingDisplayed.size()>1:
			return
		timer+=5.0/144
		await physicsProcess
		obj.modulate = Color(1,1,1,timer)
		obj.get_node("message").visible_ratio = timer
	await get_tree().create_timer(displayTime).timeout
	timer = 0
	while timer<1:
		if messagesBeingDisplayed.size()>1:
			messagesBeingDisplayed.erase(self)
			return
		timer+=5.0/144
		await physicsProcess
		obj.modulate = Color(1,1,1,1-timer)
	obj.visible = false

func updateMessage(obj,msg):
	obj.get_node("message").visible_ratio = 0
	obj.get_node("message").text = msg
	await physicsProcess
	var timer = 0
	obj.visible = true
	messagesBeingDisplayed.append(self)
	await physicsProcess
	while timer<6:
		if messagesBeingDisplayed.size()!=1:
			messagesBeingDisplayed.erase(self)
			return
		timer+=5.0/144
		if(timer>obj.modulate.a):
			obj.modulate = Color(1,1,1,timer)
		obj.get_node("message").visible_ratio = timer/6
		await physicsProcess

func hideMessage(obj):
	messagesBeingDisplayed.clear()
	await get_tree().create_timer(.1).timeout
	var timer = 0
	while timer<1:
		if messagesBeingDisplayed.size()>0:
			return
		timer+=5.0/144
		await physicsProcess
		obj.modulate = Color(1,1,1,1-timer)
	obj.visible = false
