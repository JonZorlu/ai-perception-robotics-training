# Cabinet door on a hinge pivot using a parent Node3D rotated on Y.
# The DoorHinge node sits at the physical hinge edge — rotating it swings the door.
class_name DoorInteractable
extends Interactable

@export_group("Door Settings")
@export var open_angle_degrees: float = -105.0
@export var animation_duration: float = 0.45

# Input is only accepted in terminal states (CLOSED, OPEN).
# OPENING and CLOSING act as implicit input locks — no timer or debounce needed.
enum State { CLOSED, OPENING, OPEN, CLOSING }
var _state: State = State.CLOSED

@onready var _door_hinge: Node3D = $DoorHinge


func get_hint() -> String:
	match _state:
		State.CLOSED: return "Press [E] to open cabinet"
		State.OPEN:   return "Press [E] to close cabinet"
		_:            return ""


func _on_interact(_interactor: Node3D) -> void:
	match _state:
		State.CLOSED: _set_open(true)
		State.OPEN:   _set_open(false)


func _set_open(opening: bool) -> void:
	_state = State.OPENING if opening else State.CLOSING

	var target_angle := deg_to_rad(open_angle_degrees) if opening else 0.0
	var ease_type := Tween.EASE_OUT if opening else Tween.EASE_IN

	var tween := create_tween()
	tween.tween_property(_door_hinge, "rotation:y", target_angle, animation_duration) \
		.set_ease(ease_type) \
		.set_trans(Tween.TRANS_QUART)
	await tween.finished

	_state = State.OPEN if opening else State.CLOSED
