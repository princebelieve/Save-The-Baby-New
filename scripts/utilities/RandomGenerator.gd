extends Node
class_name RandomGenerator

# =========================================================
# INTERNAL RNG
# =========================================================
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


# =========================================================
# INITIALIZATION
# =========================================================
func initialize(seed: int = -1) -> void:
	# If seed is -1, use a truly random seed
	if seed == -1:
		_rng.randomize()
	else:
		_rng.seed = seed


# =========================================================
# BASIC RANDOMS
# =========================================================
func random_int(min: int, max: int) -> int:
	# inclusive range
	return _rng.randi_range(min, max)


func random_float(min: float, max: float) -> float:
	return _rng.randf_range(min, max)


func random_bool() -> bool:
	return _rng.randi() % 2 == 0


func chance(percent: float) -> bool:
	# percent expected in 0–100
	if percent <= 0:
		return false
	if percent >= 100:
		return true
	return _rng.randf() * 100.0 < percent


# =========================================================
# ARRAY OPERATIONS
# =========================================================
func random_index(array: Array) -> int:
	if array.is_empty():
		return -1
	return _rng.randi_range(0, array.size() - 1)


func random_item(array: Array):
	if array.is_empty():
		return null
	return array[random_index(array)]


func shuffle(array: Array) -> Array:
	# Fisher–Yates shuffle (in-place)
	for i in range(array.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var temp = array[i]
		array[i] = array[j]
		array[j] = temp
	return array


func pick_multiple(array: Array, count: int) -> Array:
	if array.is_empty() or count <= 0:
		return []

	var copy := array.duplicate()
	var result := []

	shuffle(copy)

	var limit := min(count, copy.size())
	for i in range(limit):
		result.append(copy[i])

	return result


# =========================================================
# WEIGHTED RANDOM
# =========================================================
func weighted_choice(items: Array, weights: Array):
	# items[i] has weight weights[i]
	if items.is_empty() or weights.is_empty():
		return null

	var size := min(items.size(), weights.size())
	if size == 0:
		return null

	var total_weight := 0.0
	for i in range(size):
		total_weight += max(weights[i], 0)

	if total_weight <= 0:
		return items[0]

	var roll := _rng.randf() * total_weight
	var cumulative := 0.0

	for i in range(size):
		cumulative += max(weights[i], 0)
		if roll <= cumulative:
			return items[i]

	return items[size - 1]


# =========================================================
# DIRECTION HELPERS
# (Engine-level utility, no gameplay meaning assumed)
# =========================================================
func random_direction() -> Vector2i:
	# 4-direction grid unit vectors
	var directions := [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]
	return random_item(directions)


# =========================================================
# TILE TYPE HELPERS
# IMPORTANT: This does NOT define gameplay rules.
# It ONLY randomly selects from enum ranges.
# =========================================================
func random_tile_type(include_ethan: bool = false) -> int:
	# Assumes Constants.TileType is contiguous integer enum
	# You control actual enum values in Constants.gd

	var min_type := 0
	var max_type := 4 # adjust if your enum expands

	if include_ethan:
		max_type += 1

	return random_int(min_type, max_type)