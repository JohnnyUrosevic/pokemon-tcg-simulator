extends Node

enum STATUS {SLEEP, BURN, POISON, PARALYZED, CONFUSED}

class Pokemon:
    var hp
    var status

class Player:
	func getActivePokemon():
		pass

	func getBenchPokemon():
		pass

var currentPlayer
var currentOpponent

func coinFlip(num=1):
	return 100
	var result
	for i in range(num):
		result += randi_range(0,1)
	return result

func damage(target, amount):
	target.hp -= amount