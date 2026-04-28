extends CharacterBody3D

var current_states = player_states.MOVE
enum player_states {MOVE, JUMP, SWORD, FALLING, HURT, DEAD}


@export var speed := 4.0
@export var gravity = 4.0
@export var jump_force := 7.0

@onready var player_body = $CharacterArmature
@onready var anim = $AnimationPlayer
@onready var camera = $"../cam_gimball"
@onready var sword_collider = $CharacterArmature/Skeleton3D/Middle1_R/Weapon_Cutlass/sword/sword_collider
@onready var anim_tree = $AnimationTree
@onready var anim_state = anim_tree.get("parameters/playback")
@onready var camera_shake = $"../cam_gimball/Camera3D"

var angular_speed = 10

var movement
var direction
var sprint_speed = 10.0
var health = health_manager.life

func _ready():
	print("the number of life is : ", health)


func _physics_process(delta):
	match current_states:
		player_states.MOVE:
			move(delta) 
		player_states.JUMP:
			jump()
		player_states.SWORD:
			sword(delta)
		player_states.FALLING:
			falling(delta)
		player_states.HURT:
			hurt()
		player_states.DEAD:
			dead()
			
func anim_set():
	anim_tree.set("parameters/air_state/mid_jump/blend_position", movement)
	anim_tree.set("parameters/attack_state/Sword/blend_position", movement)
	anim_tree.set("parameters/ground_state/Idle/blend_position", movement)
	anim_tree.set("parameters/ground_state/Walk/blend_position", movement)
	anim_tree.set("parameters/ground_state/Running/blend_position", movement)
	anim_tree.set("parameters/damage_state/hurt/blend_position", movement)
	anim_tree.set("parameters/ground_state/Dead/blend_position", movement)

func _input(event):
	if Input.is_action_just_pressed("ui_sword"):
		current_states = player_states.SWORD
	if Input.is_action_just_pressed("ui_accept"):
		#current_states = player_states.JUMP
		jump()

func input_movement(delta):
	movement = Input.get_vector("ui_left", "ui_right","ui_up", "ui_down")
	direction = Vector3(movement.x, 0, movement.y).rotated(Vector3.UP,camera.rotation.y).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		player_body.rotation.y = lerp_angle(player_body.rotation.y, atan2(velocity.x, velocity.z), delta * angular_speed)
	else:   
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()
	
func move(delta):
	anim_tree["parameters/ground_state/conditions/standing"] = true
	movement = Input.get_vector("ui_left", "ui_right","ui_up", "ui_down")
	#direction = (transform.basis * Vector3(movement.x, 0, movement.y)).normalized() 
	direction = Vector3(movement.x, 0, movement.y).rotated(Vector3.UP,camera.rotation.y).normalized()
	var sprint = false
	
	if Input.is_action_pressed("ui_sprint"):
		sprint = true
	if Input.is_action_just_released("ui_sprint"):
		sprint = true
	
	if direction && sprint == false:
		anim_set()
		#anim.play("Walk")
		anim_tree["parameters/ground_state/conditions/moving"] = true
		anim_state.travel("ground_state/Walk")
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		player_body.rotation.y = lerp_angle(player_body.rotation.y, atan2(velocity.x, velocity.z), delta * angular_speed)
	elif direction && sprint == true:
		#anim.play("Run")
		anim_tree["parameters/ground_state/conditions/running"] = true
		anim_state.travel("ground_state/Running")
		velocity.x = direction.x * sprint_speed
		velocity.z = direction.z * sprint_speed
		player_body.rotation.y = lerp_angle(player_body.rotation.y, atan2(velocity.x, velocity.z), delta * angular_speed)
	else:   
		#anim.play("Idle")
		anim_tree["parameters/ground_state/conditions/standing"] = true
		anim_state.travel("ground_state/Idle")
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		

	
	velocity.y -= gravity * delta
	move_and_slide()

func jump():
		velocity.y = jump_force
		anim_tree["parameters/conditions/jumping"] = true
		anim_state.travel("air_state/start_jump")
	
		if velocity.y > 5.0: 
			current_states = player_states.FALLING
			
		move_and_slide()
		
		
func falling(delta):
	var new_gravity = gravity * 2
	velocity.y -= new_gravity * delta
	input_movement(delta)
	if is_on_floor():
		anim_tree["parameters/conditions/on_ground"] = true
		anim_state.travel("landing")
		current_states = player_states.MOVE 

	move_and_slide()

func sword(delta):
	input_movement(delta)
	anim_state.travel("attack_state/Sword")
	#anim.play("Sword")
	#await anim.animation_finished
	reset_states()
	
func hurt():
	if health_manager.life >= 1:
		anim_state.travel("damage_state/hurt")
	if health_manager.life >=0:
		current_states = player_states.DEAD
		
func dead():
	anim_state.travel("ground_state/Dead")
	velocity = Vector3.ZERO
	
func reload_scene():
	if get_tree():
		get_tree().reload_current_scene()
		health_manager.life = 4
	
func reset_states():
	current_states = player_states.MOVE


func _on_hitbox_area_entered(area: Area3D) -> void:
	camera_shake._camera_shake() 
	current_states = player_states.HURT
