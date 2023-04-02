extends Node

var objectsMoving = []

func moveToLocation2D(obj, location, travelTime, finish):
	objectsMoving.append(obj)
	await get_tree().create_timer(1/144).timeout
	var distance = (location-obj.position).length()
	var ogDistance = distance
	var direction = (location-obj.position).normalized()
	var time = 0
	while time < travelTime && objectsMoving.count(obj)<=1:
		distance = (location-obj.position).length()
		obj.position += direction*(1.0/144)*ogDistance/travelTime
		time+=1.0/144
		#print (str(time))
		await get_tree().create_timer(1/144).timeout
	if finish:
		obj.position=location
	objectsMoving.erase(obj)
