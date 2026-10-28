extends Node
class_name PowerupFactory


# =========================================================
# PURPOSE
# Creates and manages Powerup runtime instances.
#
# Responsibilities:
# - Create powerups
# - Duplicate powerups
# - Reset powerups
# - Destroy/recycle powerups
#
# Contains:
# - No gameplay logic
# - No placement decisions
# - No board coordination
# =========================================================


# =========================================================
# INTERNAL DEPENDENCIES
# =========================================================

var _database: PowerupDatabase
var _container: Node
var _behavior_map: Dictionary = {}


# =========================================================
# INITIALIZATION
# =========================================================

func initialize(
	database: PowerupDatabase,
	container: Node = null
) -> void:

	_database = database
	_container = container

	# =====================================================
	# BEHAVIOR REGISTRY
	# =====================================================

	_behavior_map = {

		Constants.PowerupType.ROCKET: RocketBehavior,

		Constants.PowerupType.BOMB: PowerupBombBehavior,

		Constants.PowerupType.THUNDER: ThunderBehavior

	}

func set_container(container: Node) -> void:
	_container = container


# =========================================================
# CREATION
# =========================================================

func create_powerup(type) -> Powerup:
	var powerup := Powerup.new()

	_setup_powerup(powerup, type)

	if _container != null:
		_container.add_child(powerup)

	return powerup


func create_powerup_at(type, position: Vector2i) -> Powerup:
	var powerup := create_powerup(type)

	powerup.set_grid_position(position)

	return powerup


# =========================================================
# COPY
# =========================================================

func duplicate_powerup(powerup: Powerup) -> Powerup:
	if powerup == null:
		return null


	var duplicate := Powerup.new()

	var state := powerup.duplicate_powerup_state()

	duplicate.set_powerup_state(state)


	_apply_database_data(
		duplicate,
		duplicate.get_powerup_type()
	)

	if _container != null:
		_container.add_child(duplicate)

	return duplicate


# =========================================================
# LIFECYCLE
# =========================================================

func destroy_powerup(powerup: Powerup) -> void:
	if powerup == null:
		return

	powerup.queue_free()


func recycle_powerup(powerup: Powerup) -> void:
	if powerup == null:
		return

	reset_powerup(powerup)

	powerup.hide()


func reset_powerup(powerup: Powerup) -> void:
	if powerup == null:
		return

	powerup.reset()


# =========================================================
# INTERNAL SETUP
# =========================================================

func _setup_powerup(powerup: Powerup, type) -> void:
	if powerup == null:
		return

	powerup.initialize(type, Vector2i.ZERO)

	_apply_database_data(powerup, type)


func _apply_database_data(powerup: Powerup, type) -> void:
	if powerup == null:
		return

	_assign_texture(powerup, type)
	_assign_animation_set(powerup, type)
	_assign_metadata(powerup, type)
	_assign_behavior(powerup, type)


func _assign_texture(powerup: Powerup, type) -> void:
	if _database == null:
		return

	var path: String = _database.get_texture_path(type)

	if path.is_empty():
		return

	var texture := ResourceManager.load_texture(path)

	if texture != null:
		powerup.set_texture(texture)


func _assign_animation_set(powerup: Powerup, type) -> void:
	if _database == null:
		return
	powerup.set_meta("animation_set", _database.get_animation_set(type))


func _assign_metadata(powerup: Powerup, type) -> void:
	powerup.set_powerup_type(type)


func _assign_behavior(powerup: Powerup, type) -> void:
	if powerup == null:
		return

	if not _behavior_map.has(type):
		return

	var behavior_class: Script = _behavior_map[type]

	if behavior_class == null:
		return

	var behavior: PowerupBehavior = behavior_class.new()

	behavior.initialize(powerup)

	powerup.set_behavior(behavior)
