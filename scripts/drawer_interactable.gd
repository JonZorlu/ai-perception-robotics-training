# Sliding drawer with a 4-state machine: CLOSED → OPENING → OPEN → CLOSING.
# Uses Tween for smooth physics-safe movement via AnimatableBody3D.
class_name DrawerInteractable
extends Interactable

@export_group("Drawer Settings")
@export var open_distance: float = 0.32
@export var animation_duration: float = 0.35

# Input is only accepted in terminal states (CLOSED, OPEN).
# OPENING and CLOSING act as implicit input locks — no timer or debounce needed.
enum State { CLOSED, OPENING, OPEN, CLOSING }
var _state: State = State.CLOSED

@onready var _drawer_body: AnimatableBody3D = $DrawerBody


func get_hint() -> String:
	match _state:
		State.CLOSED: return "Press [E] to open drawer"
		State.OPEN:   return "Press [E] to close drawer"
		_:            return ""


func _on_interact(_interactor: Node3D) -> void:
	match _state:
		State.CLOSED: _set_open(true)
		State.OPEN:   _set_open(false)


func _set_open(opening: bool) -> void:
	_state = State.OPENING if opening else State.CLOSING

	var target_z := open_distance if opening else 0.05
	var ease_type := Tween.EASE_OUT if opening else Tween.EASE_IN

	var tween := create_tween()
	tween.tween_property(_drawer_body, "position:z", target_z, animation_duration) \
		.set_ease(ease_type) \
		.set_trans(Tween.TRANS_CUBIC)
	await tween.finished

	_state = State.OPEN if opening else State.CLOSED
