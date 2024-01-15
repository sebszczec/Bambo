extends Node

var bulletScene = preload("res://scenes/bullet.tscn")

@onready var shootingTimer = $ShootingTimer

var canShoot = true
var player = null


func _ready():
	player = owner.find_child("Player")


func _physics_process(delta):
	if Input.is_action_pressed("ui_shoot"):
		if canShoot:
			canShoot = false
			var bullet = bulletScene.instantiate()
			bullet.position = player.position
			bullet.velocity = player.getShootingVector()
			add_child(bullet)
			
			shootingTimer.start()
			


func _on_shooting_timer_timeout():
	canShoot = true
