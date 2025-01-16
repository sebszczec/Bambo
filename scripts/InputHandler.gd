extends Node

var bulletScene = preload("res://scenes/bullet.tscn")

@onready var shootingTimer = $ShootingTimer

var canShoot = true
var player = null
var informationBox = null

func _ready():
	player = owner.find_child("Player")
	informationBox = owner.find_child("InformationBox")


func _physics_process(_delta):
	if Input.is_action_pressed("ui_shoot"):
		if canShoot:
			canShoot = false
			var bullet = bulletScene.instantiate()
			bullet.position = player.position
			bullet.velocity = player.getShootingVector()
			bullet.connect("freeing", _on_bullet_freeing)
			add_child(bullet)
			shootingTimer.start()
			
			informationBox.increaseBulletCount()
			


func _on_shooting_timer_timeout():
	canShoot = true


func _on_bullet_freeing():
	informationBox.decreaseBulletCount()
