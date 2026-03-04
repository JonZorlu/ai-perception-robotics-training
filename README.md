# AI Perception and Robotics Training

A first-person interactive kitchen scene built in **Godot 4.6.1** demonstrating physics-based object manipulation, state-driven mechanics, and a modular interaction architecture. Built as an environment suitable for AI perception and robotics training data collection.

---

## Demo

> 📹 [Watch the walkthrough (Loom)](https://www.loom.com/share/8a2dbcec4dfb471e905dd9160725554d)

Controls:
| Input | Action |
|---|---|
| `WASD` | Move |
| `Mouse` | Look |
| `E` | Interact (drawer, cabinet, switch) |
| `LMB` | Grab / Drop physics objects |
| `ESC` | Release mouse cursor |

---

## Scene Hierarchy

```
KitchenMain (Node3D)
├── Environment (Node3D)
│   ├── Floor, Ceiling, Wall_Back, Wall_Left, Wall_Right  (StaticBody3D)
│   ├── CounterBase, CounterTop                           (StaticBody3D)
│   ├── FixtureDisc_Center, FixtureDisc_Counter           (MeshInstance3D)
├── Lighting (Node3D)
│   ├── DirectionalLight3D
│   ├── WorldEnvironment
│   ├── CeilingLight_Center, CeilingLight_Counter         (OmniLight3D)
│   └── UnderCabinetLight                                 (OmniLight3D)
├── PhysicsObjects (Node3D)
│   ├── Pot          (RigidBody3D ← GrabbableObject)
│   ├── Mug          (RigidBody3D ← GrabbableObject)
│   └── CuttingBoard (RigidBody3D ← GrabbableObject)
├── Interactables (Node3D)
│   ├── DrawerUnit   (Node3D ← DrawerInteractable)
│   ├── CabinetDoor  (Node3D ← DoorInteractable)
│   └── StoveSwitch  (Node3D ← SwitchInteractable)
└── Player (Node3D ← PlayerCamera)
    ├── Camera3D
    │   └── RayCast3D
    └── UI (CanvasLayer)
        ├── InteractionLabel (Label)
        └── Crosshair (Label)
```

---

## Interaction Systems

### Physics Grab (LMB)
Three `RigidBody3D` objects — a pot, mug, and cutting board — can be picked up and carried. The grab system drives objects toward a hold point in front of the camera using `linear_velocity` each physics frame rather than reparenting, keeping full physics simulation active throughout. Objects are released with preserved momentum, enabling natural throw behaviour.

**Jolt Physics** (enabled by default in Godot 4.6) provides stable, high-fidelity simulation for all rigid body interactions.

### Sliding Drawer (E key)
A four-state machine (`CLOSED → OPENING → OPEN → CLOSING`) using `AnimatableBody3D`. A `Tween` with cubic easing drives the sliding motion. Input is blocked mid-animation — the hint label returns an empty string during transitions, hiding the prompt cleanly.

### Hinge Cabinet Door (E key)
Door rotation is implemented via a **pivot node pattern**: a `DoorHinge` Node3D is placed at the physical hinge edge of the cabinet. Rotating this node on the Y axis swings the door panel (a child offset to one side) in a physically correct arc. Same four-state machine as the drawer.

### Stove Switch (E key)
Two-state toggle. On activation: the knob `MeshInstance3D` rotates 45° via `rotation_degrees`, a new `StandardMaterial3D` with emission is applied programmatically, and an `OmniLight3D` becomes visible to simulate burner glow. On deactivation, all states revert. Emits a `state_changed(is_on: bool)` signal for any external system to hook into.

---

## Architecture

### Interaction Interface
The project uses a two-tier interaction design:

**Tier 1 — `Interactable` base class** (door, drawer, switch):
`DoorInteractable`, `DrawerInteractable`, and `SwitchInteractable` all extend `Interactable`, which handles group registration, the `interaction_enabled` guard, and signal emission. Subclasses override `_on_interact()` to implement their specific behaviour and `get_hint()` to return context-aware UI strings.

**Tier 2 — Duck typing** (`GrabbableObject`):
`GrabbableObject` must extend `RigidBody3D` and cannot use the base class. It joins the `"interactable"` group manually and implements `get_hint()` and the grab interface directly. The camera identifies it specifically via `is GrabbableObject` for the physics grab path.

```gdscript
# Camera interaction dispatch — two separate paths:
if _current_target is GrabbableObject:
    _grab_object(...)                          # physics grab (LMB)
elif _current_target.has_method("interact"):
    _current_target.interact(self)             # stationary mechanic (E key)
```

### Parent Chain Traversal
The `RayCast3D` hits collision bodies directly (e.g. `CabinetBody` inside `DrawerUnit`), not the interactable root. The camera walks up the scene tree from the hit node until it finds an `"interactable"` group member — decoupling collision geometry structure from interaction logic.

### State Machines
Both drawer and door use a GDScript `enum` with four states. The `_on_interact()` override only acts on terminal states (`CLOSED` / `OPEN`), making rapid input safe without timers or debounce flags. The hint returns an empty string during transitions, which hides the UI label automatically.

### Collision Layers
| Layer | Name | Used By |
|---|---|---|
| 1 | `environment` | Walls, floor, ceiling, counter |
| 2 | `interactables` | Drawer, cabinet, switch collision bodies |
| 3 | `physics_objects` | Pot, mug, cutting board |

The `RayCast3D` mask covers layers 2 and 3 only — environment geometry is invisible to the interaction system.

### State Machines
Both the drawer and cabinet door use a GDScript `enum` with four states. The `interact()` method only acts on terminal states (`CLOSED` / `OPEN`), making rapid input safe without timers or debounce flags.

---

## Project Structure

```
res://
├── scenes/
│   ├── main.tscn               # Root scene — run this
│   └── objects/
│       ├── kitchen_item.tscn   # Reusable RigidBody3D physics object template
│       ├── DrawerUnit.tscn     # Sliding drawer with cabinet body
│       ├── CabinetDoor.tscn    # Hinged door with pivot-based rotation
│       └── StoveSwitch.tscn    # Toggle switch with burner light
└── scripts/
    ├── player_camera.gd        # First-person controller, raycast, grab system
    ├── grabbable_object.gd     # RigidBody3D with grab/release interface
    ├── drawer_interactable.gd  # Sliding drawer state machine
    ├── door_interactable.gd    # Hinge door state machine
    ├── switch_interactable.gd  # Two-state toggle with emission and light
    └── interactable.gd         # Base class (reference — not directly instantiated)
```

---

## How to Run

1. Download and install **[Godot 4.6.1](https://godotengine.org/download/windows/)** (Windows x64 recommended)
2. Clone this repository:
   ```bash
   git clone https://github.com/JonZorlu/ai-perception-robotics-training.git
   ```
3. Open Godot → **Import** → select the `project.godot` file in the cloned folder
4. Press **F5** or click the **Play** button to run

> Godot will reimport assets on first open — this takes ~10 seconds and is expected.

---

## Technical Notes

- **Engine:** Godot 4.6.1 — Forward+ renderer
- **Physics:** Jolt Physics 3D (default in Godot 4.6, replaces GodotPhysics3D)
- **Platform:** Developed and tested on Windows x64
- **No external assets or plugins** — entirely built with Godot primitives and GDScript
- **No baked lighting** — all lighting is fully real-time (OmniLight3D + DirectionalLight3D + SSAO + Glow)
