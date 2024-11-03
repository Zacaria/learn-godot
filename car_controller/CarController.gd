extends VehicleBody3D

@onready var camera_pivot = $camera_pivot
@onready var camera_follow = $camera_pivot/camera_follow
@onready var camera_reverse = $camera_pivot/camera_reverse

var look_at
# Called when the node enters the scene tree for the first time.
func _ready():
	look_at = global_position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass	
	
var max_rpm = 2500
var max_torque = 1200
var brake_force_max = 2000  # Maximum brake force
var handbrake_force = 100000 # High brake force for handbrake effect
var brake_time = 0.0        # Time counter for normal braking
var rear_wheel_slip = 40

func _physics_process(delta):
	#camera_pivot.global_position = camera_pivot.global_position.lerp(global_position, delta*50)
	#camera_pivot.transform = camera_pivot.transform.interpolate_with(transform, delta *2)
	#
	#look_at = look_at.lerp(global_position + linear_velocity, delta*10)
	#camera_follow.look_at(look_at)
	handle_camera(delta);
	
	steering = lerp(steering, Input.get_axis("move_right", "move_left") * 0.7, 5 * delta)
	var acceleration = Input.get_action_strength("move_forward") * 10
	var deceleration = Input.get_action_strength("move_back") * 10
	var is_handbrake = Input.is_action_pressed("hand_brake")  # Ensure "handbrake" action is set in Input Map

	# Determine average RPM of rear wheels to assess speed and direction
	var avg_rpm = ($rear_left.get_rpm() + $rear_right.get_rpm()) / 2

	if is_handbrake:
		print_debug("handbreaking!!")
		apply_handbrake()
	else:
		$rear_left.wheel_friction_slip = rear_wheel_slip
		$rear_right.wheel_friction_slip = rear_wheel_slip
	
	if deceleration > 0:
		# Apply normal braking or reverse force based on movement direction
		if avg_rpm > 0:
			apply_braking(delta)
		else:
			apply_reverse_force(deceleration)
	else:
		# Reset brake time when no brake is applied
		brake_time = 0.0
		apply_acceleration(avg_rpm, acceleration)


func apply_braking(delta):
	# Increment brake time and calculate asymptotic braking force
	brake_time += delta
	var braking_factor = 1 - exp(-3 * brake_time)  # Controls the approach rate
	var brake_force = lerp(0, brake_force_max, braking_factor)
	brake = brake_force
	# Apply calculated braking force
	#$rear_left.brake = brake_force
	#$rear_right.brake = brake_force
	#$rear_left.engine_force = 0
	#$rear_right.engine_force = 0


func apply_handbrake():
	# Apply a constant, high braking force to lock the rear wheels
	$rear_left.brake = handbrake_force
	$rear_right.brake = handbrake_force
	
	$rear_left.wheel_friction_slip = 0
	$rear_right.wheel_friction_slip = 0
	#$rear_left.engine_force = 0
	#$rear_right.engine_force = 0


func apply_reverse_force(deceleration):
	# Reset brake time when reversing
	brake_time = 0.0
	
	# Apply reverse force to rear wheels
	$rear_left.brake = 0
	$rear_right.brake = 0
	$rear_left.engine_force = -deceleration * max_torque
	$rear_right.engine_force = -deceleration * max_torque


func apply_acceleration(avg_rpm, acceleration):
	# Apply forward acceleration based on average RPM
	$rear_left.brake = 0
	$rear_right.brake = 0
	$rear_left.engine_force = acceleration * max_torque * (1 - avg_rpm / max_rpm)
	$rear_right.engine_force = acceleration * max_torque * (1 - avg_rpm / max_rpm)

func handle_camera(delta):
	camera_pivot.global_position = camera_pivot.global_position.lerp(global_position, delta* 25)
	camera_pivot.transform = camera_pivot.transform.interpolate_with(transform, delta *1.2)
	
	look_at = look_at.lerp(global_position + linear_velocity, delta*1)
	camera_follow.look_at(look_at)
	
