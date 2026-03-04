# First-person camera controller with raycast interaction and physics grab system.
#
# Responsibilities:
#   - WASD movement locked to eye height (no gravity/collision on player)
#   - Mouse-look: yaw on Player Node3D, pitch on Camera3D child
#   - Raycast target detection each physics frame
#   - [E] key: triggers interact() on doors, drawers, switches
#   - [LMB] grab/release: holds GrabbableObject via velocity-based physics pull
#   - UI hint label and crosshair updates
extends Node3D

# ── Exported settings ─────────────────────────────────────────────────────────

@export_group("Movement")
@export var move_speed: float = 4.0
@export var mouse_sensitivity: float = 0.002

@export_group("Interaction")
## Maximum raycast reach in metres.
@export var interaction_range: float = 2.5
## Distance in front of camera where grabbed objects are held.
@export var grab_distance: float = 1.4
## Velocity multiplier pulling grabbed object toward the hold point.
@export var grab_strength: float = 14.0
## Object auto-drops if it drifts further than this from the hold point.
@export var max_grab_drift: float = 3.5

# ── Child node references ──────────────────────────────────────────────────────

@onready var _camera: Camera3D        = $Camera3D
@onready var _raycast: RayCast3D      = $Camera3D/RayCast3D
@onready var _hint_label: Label       = $UI/InteractionLabel

# ── Runtime state ──────────────────────────────────────────────────────────────

var _pitch: float = 0.0
var _current_target: Node3D = null
var _grabbed_object: GrabbableObject = null

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	global_position.y = 1.6
	_hint_label.text = ""


func _unhandled_input(event: InputEvent) -> void:
	_handle_mouse_look(event)
	_handle_mouse_capture(event)
	_handle_interact_input(event)
	_handle_grab_input(event)


func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_update_raycast()
	_update_hint_label()
	if _grabbed_object:
		_pull_grabbed_object()


# ── Movement ───────────────────────────────────────────────────────────────────

func _handle_movement(delta: float) -> void:
	var direction := Vector3.ZERO
	if Input.is_action_pressed("move_forward"): direction -= global_transform.basis.z
	if Input.is_action_pressed("move_back"):    direction += global_transform.basis.z
	if Input.is_action_pressed("move_left"):    direction -= global_transform.basis.x
	if Input.is_action_pressed("move_right"):   direction += global_transform.basis.x

	direction.y = 0.0
	if direction.length() > 0.0:
		global_position += direction.normalized() * move_speed * delta

	# Lock Y to eye height — simple floating camera, no character physics needed
	global_position.y = 1.6


# ── Mouse look ─────────────────────────────────────────────────────────────────

func _handle_mouse_look(event: InputEvent) -> void:
	if not event is InputEventMouseMotion:
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	# Yaw: rotate the whole Player node left/right
	rotate_y(-event.relative.x * mouse_sensitivity)
	# Pitch: tilt only the Camera3D up/down
	_pitch = clamp(_pitch - event.relative.y * mouse_sensitivity, -PI / 2.5, PI / 2.5)
	_camera.rotation.x = _pitch


func _handle_mouse_capture(event: InputEvent) -> void:
	if event.is_action_pressed("cancel_mouse"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# ── Interaction input ──────────────────────────────────────────────────────────

func _handle_interact_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.is_action_pressed("interact") or event.is_echo():
		return
	if _grabbed_object or _current_target == null:
		return
	if _current_target is GrabbableObject:
		return
	if _current_target.is_in_group("interactable") and _current_target.has_method("interact"):
		_current_target.interact(self)


func _handle_grab_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.is_action_pressed("grab"):
		return
	if _grabbed_object:
		_release_object()
	elif _current_target is GrabbableObject:
		_grab_object(_current_target as GrabbableObject)



# ── Raycast target tracking ────────────────────────────────────────────────────

func _update_raycast() -> void:
	if not _raycast.is_colliding():
		_current_target = null
		return

	# Walk up the parent chain because the raycast hits a CollisionBody child
	# (e.g. CabinetBody inside DrawerUnit), not the interactable root node.
	# This decouples collision geometry depth from the interaction system.
	var collider := _raycast.get_collider() as Node3D
	var node: Node3D = collider
	while node != null:
		if node.is_in_group("interactable"):
			_current_target = node
			return
		node = node.get_parent() as Node3D

	# Hit something physical but not interactable (e.g. bare wall)
	_current_target = null



# ── UI hint label ──────────────────────────────────────────────────────────────

func _update_hint_label() -> void:
	# Priority 1: currently holding an object — always show the drop prompt
	if _grabbed_object:
		_hint_label.text = "[LMB] Drop %s" % _grabbed_object.item_name
		_hint_label.visible = true
		return

	# Priority 2: looking at something interactable
	if _current_target and _current_target.is_in_group("interactable") \
			and _current_target.has_method("get_hint"):
		var hint: String = _current_target.get_hint()
		_hint_label.visible = hint != ""
		_hint_label.text = hint
		return

	# Default: hide
	_hint_label.text = ""
	_hint_label.visible = false


# ── Physics grab system ────────────────────────────────────────────────────────

func _grab_object(obj: GrabbableObject) -> void:
	_grabbed_object = obj
	obj.on_grabbed()


func _release_object() -> void:
	# Preserve throw momentum: pass the object's current velocity on release
	_grabbed_object.on_released(_grabbed_object.linear_velocity * 0.9)
	_grabbed_object = null


func _pull_grabbed_object() -> void:
	# Calculate the world-space hold point in front of the camera
	var hold_pos: Vector3 = _camera.global_position + \
		(-_camera.global_transform.basis.z * grab_distance)

	var offset: Vector3 = hold_pos - _grabbed_object.global_position

	# Auto-drop safety: release if object drifts too far (e.g. stuck in geometry)
	if offset.length() > max_grab_drift:
		_release_object()
		return

	# Drive the object toward the hold point via linear velocity
	_grabbed_object.linear_velocity = offset * grab_strength
	# Smoothly damp rotation so it doesn't tumble uncontrollably
	_grabbed_object.angular_velocity *= 0.80
