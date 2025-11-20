extends CharacterBody3D
class_name Enemy

const RUN_VELOCITY_THRESHOLD := 2.0

@export var max_health: float = 20.0
@export var xp_value := 25
@export var critical_rate := 0.05
@export var speed := 5.0
@export var shields: Array[PackedScene]
@export var weapons: Array[PackedScene]

@onready var rig: Rig = $Rig
@onready var health_component: HealthComponent = $HealthComponent
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var player_detector: ShapeCast3D = $Rig/PlayerDetector
@onready var area_attack: ShapeCast3D = $Rig/AreaAttack
@onready var player: Player = get_tree().get_first_node_in_group("Player")
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	rig.set_active_mesh(rig.villager_meshes.pick_random())
	rig.replace_equipment(shields.pick_random(), rig.shield_slot)
	rig.replace_equipment(weapons.pick_random(), rig.weapon_slot)
	health_component.update_max_health(max_health)
	
func _physics_process(delta: float) -> void:
	navigation_agent_3d.target_position = player.global_position
	var velocity_target = Vector3.ZERO
	if rig.is_state("MoveSpace"): 
		check_for_attacks()
		if not navigation_agent_3d.is_target_reached():
			velocity_target = get_local_navigation_direction() * speed
			orient_rig(navigation_agent_3d.get_next_path_position())
	if not is_on_floor(): velocity += get_gravity() * delta
	navigation_agent_3d.velocity = velocity_target

func check_for_attacks(): 
	for collision_index in player_detector.get_collision_count():
		var collider = player_detector.get_collider(collision_index)
		if collider is Player: 
			rig.travel("Overhead")
			navigation_agent_3d.avoidance_mask = 0

func _on_health_component_defeat() -> void:
	player.stats.xp += xp_value
	rig.travel("Defeat")
	collision_shape_3d.disabled = true
	set_physics_process(false)
	navigation_agent_3d.target_position = global_position
	navigation_agent_3d.velocity = Vector3.ZERO

func _on_rig_heavy_attack() -> void:
	area_attack.deal_damage(20.0, critical_rate)
	navigation_agent_3d.avoidance_mask = 1

func orient_rig(target_position: Vector3) -> void:
	target_position.y = rig.global_position.y
	if rig.global_position.is_equal_approx(target_position): return
	rig.look_at(target_position, Vector3.UP, true)

func get_local_navigation_direction() -> Vector3:
	var destination = navigation_agent_3d.get_next_path_position()
	return (destination - global_position).normalized()

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	rig.run_weight_target = 1.0 if safe_velocity.length() > RUN_VELOCITY_THRESHOLD else 0.0
	velocity = safe_velocity
	move_and_slide()
