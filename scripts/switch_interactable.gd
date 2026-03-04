# Two-state toggle switch. Controls a stove burner OmniLight3D and knob visuals.
class_name SwitchInteractable
extends Interactable

@export_group("Switch Settings")
@export var on_color: Color  = Color(1.0, 0.45, 0.05)  # warm flame orange
@export var off_color: Color = Color(0.25, 0.25, 0.25)

## Emitted whenever the switch is toggled.
## Connect to drive additional systems (e.g. sound, particles).
signal state_changed(is_on: bool)

var is_on: bool = false

@onready var _knob_mesh:    MeshInstance3D = $SwitchKnob
@onready var _burner_light: OmniLight3D    = $BurnerLight


func _ready() -> void:
	super()  # calls Interactable._ready() → add_to_group("interactable")
	_apply_state()


func get_hint() -> String:
	return "Press [E] to turn off burner" if is_on else "Press [E] to turn on burner"


func _on_interact(_interactor: Node3D) -> void:
	is_on = not is_on
	_apply_state()
	state_changed.emit(is_on)


func _apply_state() -> void:
	_knob_mesh.rotation_degrees.z = 45.0 if is_on else 0.0

	var mat := StandardMaterial3D.new()
	mat.albedo_color = on_color if is_on else off_color
	if is_on:
		mat.emission_enabled = true
		mat.emission = on_color
		mat.emission_energy_multiplier = 0.6
	_knob_mesh.set_surface_override_material(0, mat)

	_burner_light.visible = is_on
