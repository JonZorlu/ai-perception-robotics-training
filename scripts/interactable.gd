# Base class for all stationary interactable objects in the kitchen scene.
# Extend this class and override _on_interact() to implement behaviour.
class_name Interactable
extends Node3D

## Emitted when interaction begins. Connect to drive audio, particles, etc.
signal interaction_started(interactor: Node3D)

@export_group("Interaction Settings")
@export var interaction_hint: String = "Press [E] to interact"
@export var interaction_enabled: bool = true


func _ready() -> void:
	add_to_group("interactable")


func interact(interactor: Node3D) -> void:
	if not interaction_enabled:
		return
	interaction_started.emit(interactor)
	_on_interact(interactor)


## Override in subclasses to implement specific behaviour.
func _on_interact(_interactor: Node3D) -> void:
	pass


func get_hint() -> String:
	return interaction_hint
