extends Node

signal physicsProcess

var objectsMoving = []

func _physics_process(delta):
	physicsProcess.emit()

func moveToLocation2D(obj, location, travelTime, finish):
	objectsMoving.append(obj)
	await physicsProcess
	var distance = (location-obj.position).length()
	var ogDistance = distance
	var direction = (location-obj.position).normalized()
	var time = 0
	while time < travelTime && objectsMoving.count(obj)<=1:
		distance = (location-obj.position).length()
		obj.position += direction*(1.0/144)*ogDistance/travelTime
		time+=1.0/144
		#print (str(time))
		await physicsProcess
	if finish:
		obj.position=location
	objectsMoving.erase(obj)
	
func darken(sprite):
	var timer = 0
	while timer<1:
		timer+=5.0/144
		await get_tree().create_timer(1.0/144).timeout
		sprite.modulate = Color(1-timer/1.5,1-timer/1.5,1-timer/1.5,1)
		
func lighten(sprite):
	if sprite.modulate == Color(1,1,1,1):
		return 
	var timer = 0
	while timer<1:
		timer+=5.0/144
		await get_tree().create_timer(1.0/144).timeout
		sprite.modulate = Color(.5+timer/2,.5+timer/2,.5+timer/2,1)
