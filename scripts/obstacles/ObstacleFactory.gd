extends Node
class_name ObstacleFactory

# =========================================================
# INTERNAL DEPENDENCIES
# =========================================================

var _database: ObstacleDatabase
var _animation_manager: ObstacleAnimator
var _behavior_map: Dictionary = {}


# =========================================================
# INITIALIZATION
# =========================================================

func initialize(database: ObstacleDatabase, animation_manager: ObstacleAnimator = null) -> void:
	_database = database
	_animation_manager = animation_manager

	# =====================================================
	# BEHAVIOR REGISTRY (TYPE → CLASS)
	# =====================================================
	_behavior_map = {
		Constants.ObstacleType.CHAIN: ChainBehavior,
		Constants.ObstacleType.LOCK: LockBehavior,
		Constants.ObstacleType.TAPE: TapeBehavior,
		Constants.ObstacleType.BOMB: ObstacleBombBehavior,
		Constants.ObstacleType.MISSILE: MissileBehavior,
		Constants.ObstacleType.ELECTRIC_TRAP: ElectricTrapBehavior
	}


# =========================================================
# CREATION
# =========================================================

func create_obstacle(type) -> Obstacle:
	var obstacle := _create_obstacle_node()
	obstacle.initialize(type, Vector2i.ZERO)
	_apply_database_data(obstacle, type)
	return obstacle


func create_obstacle_at(type, position: Vector2i) -> Obstacle:
	var obstacle := create_obstacle(type)
	obstacle.set_grid_position(position)
	return obstacle


# =========================================================
# DUPLICATION
# =========================================================

func duplicate_obstacle(obstacle: Obstacle) -> Obstacle:
	if obstacle == null:
		return null

	var new_obstacle := _create_obstacle_node()
	var state_copy = obstacle.duplicate_obstacle_state()

	new_obstacle.set_obstacle_state(state_copy)

	_apply_database_data(new_obstacle, state_copy.get_obstacle_type())

	return new_obstacle


# =========================================================
# LIFECYCLE
# =========================================================

func destroy_obstacle(obstacle: Obstacle) -> void:
	if obstacle == null:
		return

	obstacle.queue_free()


func recycle_obstacle(obstacle: Obstacle) -> void:
	reset_obstacle(obstacle)


func reset_obstacle(obstacle: Obstacle) -> void:
	if obstacle == null:
		return

	var state = obstacle.get_obstacle_state()
	if state != null:
		state.reset()

	obstacle.reset()


# =========================================================
# INTERNAL CREATION
# =========================================================

func _create_obstacle_node() -> Obstacle:
	return Obstacle.new()


# =========================================================
# DATABASE PIPELINE
# =========================================================

func _apply_database_data(obstacle: Obstacle, type) -> void:
	if obstacle == null or _database == null:
		return

	_assign_metadata(obstacle, type)
	_assign_texture(obstacle, type)
	_assign_animation_set(obstacle, type)
	_assign_behavior(obstacle, type)


# =========================================================
# METADATA
# =========================================================

func _assign_metadata(obstacle: Obstacle, type) -> void:
	obstacle.set_obstacle_type(type)


# =========================================================
# TEXTURE
# =========================================================

func _assign_texture(obstacle: Obstacle, type) -> void:
	var path: String = _database.get_texture_path(type)
	if path == "":
		return

	var texture := ResourceManager.load_texture(path)
	if texture != null:
		obstacle.set_texture(texture)


# =========================================================
# ANIMATION SET (DATA ONLY)
# =========================================================

func _assign_animation_set(obstacle: Obstacle, type) -> void:
	var anim_set = _database.get_animation_set(type)
	if anim_set == null:
		return

	# V1 rule: informational only
	# runtime animation handled by ObstacleAnimator
	pass


# =========================================================
# BEHAVIOR WIRING (CRITICAL MISSING PIECE FIXED)
# =========================================================

func _assign_behavior(obstacle: Obstacle, type) -> void:
	if obstacle == null:
		return

	if not _behavior_map.has(type):
		return

	var behavior_class = _behavior_map[type]
	if behavior_class == null:
		return

	var behavior: ObstacleBehavior = behavior_class.new()
	behavior.initialize(obstacle)

	obstacle.set_behavior(behavior)
