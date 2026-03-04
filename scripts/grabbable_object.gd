# Physics-enabled kitchen item that can be grabbed by the player.
# The player camera detects this via the "interactable" group and GrabbableObject class check.
class_name GrabbableObject
extends RigidBody3D

@export_group("Interaction")
@export var interaction_hint: String = "[LMB] to grab"
@export var item_name: String = "Item"

@export_group("Physics")
@export var item_mass: float = 0.5

var is_grabbed: bool = false

var _original_linear_damp: float
var _original_angular_damp: float


func _ready() -> void:
	add_to_group("interactable")
	mass = item_mass
	_original_linear_damp = linear_damp
	_original_angular_damp = angular_damp


func get_hint() -> String:
	return "[LMB] to drop %s" % item_name if is_grabbed else interaction_hint


# on_grabbed() / on_released() are called externally by PlayerCamera.
func on_grabbed() -> void:
	is_grabbed = true
	gravity_scale = 0.0
	linear_damp = 20.0
	angular_damp = 20.0


func on_released(release_velocity: Vector3 = Vector3.ZERO) -> void:
	is_grabbed = false
	gravity_scale = 1.0
	linear_damp = _original_linear_damp
	angular_damp = _original_angular_damp
	linear_velocity = release_velocity
