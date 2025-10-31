extends CharacterBody3D

const GROUND_SPEED = 5.5
const SPRINT_SPEED = 9.0
const AIR_SPEED = 5.5
const GROUND_ACCEL = 10.0
const AIR_ACCEL = 10.0
const FRICTION = 4.0
const STOP_SPEED = 1.5
const JUMP_VELOCITY = 5.0

const MOUSE_SENSITIVITY = 0.002
const MIN_PITCH = -89.0
const MAX_PITCH = 89.0

# Collision fun parameters
const PUSH_FORCE = 15.0
const BOUNCE_MULTIPLIER = 1.2
const SPIN_TORQUE = 5.0
const LAUNCH_FORCE = 8.0

@onready var camera = $Camera3D
var camera_rotation = Vector2.ZERO
var last_velocity = Vector3.ZERO

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_rotation.x -= event.relative.y * MOUSE_SENSITIVITY
		camera_rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		camera_rotation.x = clamp(camera_rotation.x, deg_to_rad(MIN_PITCH), deg_to_rad(MAX_PITCH))
		
		camera.rotation.x = camera_rotation.x
		rotation.y = camera_rotation.y
	
	# Toggle mouse capture
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var wish_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var is_sprinting = Input.is_action_pressed("sprint")
	
	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_pressed("lol"):
		var cat = preload("res://scenes/cat.tscn").instantiate()
		get_parent().add_child(cat)
		
	
	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if is_on_floor():
		ground_move(wish_dir, is_sprinting, delta)
	else:
		air_move(wish_dir, delta)
	
	last_velocity = velocity
	move_and_slide()
	
	$UI/Main/HBoxContainer/Label.text = "Speed: " + str(velocity.length()) + " m/s"
	
	# Handle collisions with RigidBody3D objects
	handle_rigidbody_collisions()

func handle_rigidbody_collisions() -> void:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is RigidBody3D:
			var impact_speed = last_velocity.length()
			var impact_normal = collision.get_normal()
			var push_direction = -impact_normal
			
			# Calculate push force based on impact speed
			var push_strength = PUSH_FORCE * (impact_speed / GROUND_SPEED)
			
			# Apply linear impulse at collision point
			var collision_point = collision.get_position()
			var impulse = push_direction * push_strength
			collider.apply_impulse(impulse, collision_point - collider.global_position)
			
			# Add spinning effect for more chaos
			var spin_axis = Vector3(randf_range(-1, 1), randf_range(0.5, 1), randf_range(-1, 1)).normalized()
			var torque_impulse = spin_axis * SPIN_TORQUE * (impact_speed / GROUND_SPEED)
			collider.apply_torque_impulse(torque_impulse)
			
			# Launch objects upward if hitting from above or moving fast
			if impact_speed > SPRINT_SPEED * 0.8 or velocity.y < -2.0:
				var launch = Vector3.UP * LAUNCH_FORCE * (impact_speed / SPRINT_SPEED)
				collider.apply_central_impulse(launch)

func ground_move(wish_dir: Vector3, sprinting: bool, delta: float) -> void:
	var speed = Vector3(velocity.x, 0, velocity.z).length()
	
	if speed > 0.1:
		var control = max(speed, STOP_SPEED)
		var drop = control * FRICTION * delta
		var new_speed = max(speed - drop, 0)
		if speed > 0:
			velocity.x *= new_speed / speed
			velocity.z *= new_speed / speed
	
	var max_speed = SPRINT_SPEED if sprinting else GROUND_SPEED
	accelerate(wish_dir, max_speed, GROUND_ACCEL, delta)

func air_move(wish_dir: Vector3, delta: float) -> void:
	accelerate(wish_dir, AIR_SPEED, AIR_ACCEL, delta)

func accelerate(wish_dir: Vector3, max_speed: float, accel: float, delta: float) -> void:
	if wish_dir.length() < 0.01:
		return
	
	var current_speed = velocity.dot(wish_dir)
	var add_speed = max_speed - current_speed
	
	if add_speed <= 0:
		return
	
	var accel_speed = accel * max_speed * delta
	accel_speed = min(accel_speed, add_speed)
	
	velocity.x += wish_dir.x * accel_speed
	velocity.z += wish_dir.z * accel_speed
