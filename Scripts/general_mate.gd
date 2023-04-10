extends Node

signal physicsProcess

var objectsMoving = []
var objectsScaling = []
func _physics_process(delta):
	physicsProcess.emit()

func moveToLocation2D(obj, location, travelTime, finish):
	objectsMoving.append(obj)
	await physicsProcess
	var distance = (location-obj.position).length()
	var ogDistance = distance
	var direction = (location-obj.position).normalized()
	var time = 0
	while time < travelTime && !checkDupe(objectsMoving,obj):
		distance = (location-obj.position).length()
		obj.position += direction*(1.0/144)*ogDistance/travelTime
		time+=1.0/144
		#print (str(time))
		await physicsProcess
	if finish:
		obj.position=location
	objectsMoving.erase(obj)

func checkDupe(objs,obj):
	var count = 0
	for n in objs.size():
		if objs[n]==obj:
			count+=1
	if count>=2:
		return true
	return false
		

func continuousScale2D(obj, newScale, travelTime, finish):
	objectsScaling.append(obj)
	await physicsProcess
	var distance = (newScale-obj.global_scale).length()
	var ogDistance = distance
	var time = 0
	while time < travelTime && objectsScaling.count(obj)<=1:
		distance = (newScale-obj.global_scale).length()
		if newScale.length()<obj.global_scale.length():
			obj.global_scale -= Vector2(1,1)*(1.0/144)*ogDistance/travelTime
		elif newScale.length()>=obj.global_scale.length():
			obj.global_scale += Vector2(1,1)*(1.0/144)*ogDistance/travelTime
		time+=1.0/144
		#print (str(time))
		await physicsProcess
	if finish:
		obj.global_scale=newScale
	objectsScaling.erase(obj)
	
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
