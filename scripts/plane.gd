@tool

extends AeroBody3D

class_name FlightSimPlane

const PROPELLER_MAX_RADIANS_PER_TICK: float = 150.0/60.0
const PROPELLER_ACCERLERATION: float = 0.003
const PROPELLER_DECERLERATION: float = 0.05

var current_propeller_rotation_percentage: float = 0
var throttle: float = 0

@onready var aero_control_component: AeroControlComponent = $AeroControlComponent

var pitch: float = 0
var roll: float = 0


@onready var yoke: RigidBody3D = $ControlPanel/Joint/Yoke
@onready var throttle_stick: RigidBody3D = $ControlPanel/Joint2/Throttle

func _ready() -> void:
	super._ready()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	super._integrate_forces(state)
	
	pitch = (yoke.position.y)*2
	roll = (yoke.position.x)*2
	throttle = max(throttle_stick.position.x * 2, 0)
	
	aero_control_component.set_control_input("throttle", throttle)
	aero_control_component.set_control_input("pitch", pitch)
	aero_control_component.set_control_input("roll", roll)
	
	print(pitch, "   ", roll)
	
	if throttle > current_propeller_rotation_percentage:
		current_propeller_rotation_percentage = lerp(current_propeller_rotation_percentage, throttle, PROPELLER_ACCERLERATION)
	else:
		current_propeller_rotation_percentage = lerp(current_propeller_rotation_percentage, throttle, PROPELLER_DECERLERATION)
	
	%Propeller.rotate(Vector3.FORWARD, current_propeller_rotation_percentage * PROPELLER_MAX_RADIANS_PER_TICK)
	
	update_labels()



func update_labels() -> void:
	%AltitudeLabel.text = "Altitud: " + "%05d" % floor(global_position.y) + "m"
	%SpeedLabel.text = "Velocidad: " + "%03.1f" % (air_speed * 3.6) + "km/h"
	%BearingLabel.text = "Rumbo: " + "%03.1f" % wrapf(global_rotation_degrees.y, -180, 180) + "°"
	
	%Ball.global_rotation.x = 0
	%Ball.global_rotation.z = 0
	%Ball.global_rotation.y = global_rotation.y
