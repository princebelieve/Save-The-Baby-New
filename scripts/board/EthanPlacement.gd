extends RefCounted

## Read-only placement search: never move or replace live tiles while scoring.
static func choose(board) -> Vector2i:
	for tile in board.get_all_tiles():
		if int(tile.get_tile_type()) == Constants.TileType.ETHAN: return Vector2i(-1,-1)
	var objectives: Array = board._level_data.get("objectives", [])
	var goal := -1
	if not objectives.is_empty() and str(objectives[0].get("type", "")) == "COLLECT_ITEMS":
		goal = int(Constants.TileType.get(str(objectives[0].get("target", "")), -1))
	var best := Vector2i(-1,-1)
	var best_score := -1
	var goal_cells: Array[Vector2i] = []
	for piece in board.get_all_tiles():
		if goal >= 0 and int(piece.get_tile_type()) == goal and not piece.has_powerup() and not board.is_swap_blocked(piece.get_grid_position()):
			goal_cells.append(piece.get_grid_position())
	for y in board.get_height():
		for x in board.get_width():
			var cell := Vector2i(x,y)
			if not eligible(board, cell): continue
			var score := 0
			var nearest := 10000
			var adjacent := 0
			for goal_cell in goal_cells:
				var distance: int = absi(goal_cell.x-x)+absi(goal_cell.y-y)
				if distance == 0: continue
				nearest = mini(nearest, distance)
				if distance == 1: adjacent += 1
			if nearest < 10000: score = 10000-nearest*100
			if adjacent > 0: score = 600000+adjacent*10
			# With one move left, any immediate wildcard match can award relief now.
			for piece in board.get_neighbors(cell):
				var kind := int(piece.get_tile_type())
				if kind not in [Constants.TileType.ETHAN, Constants.TileType.VICTOR] and run_size(board, cell, kind) >= 2:
					score = maxi(score, 700000 if board.get_remaining_moves() <= 1 else 500000)
			if goal >= 0:
				var matched := run_size(board, cell, goal)
				if matched >= 2:
					score = 1000000+matched*100
				elif can_complete_next_move(board, cell, goal):
					score = 800000+adjacent*10
			# Prefer keeping actual clues rather than replacing them with a wildcard.
			if int(board.get_tile(cell).get_tile_type()) == goal: score -= 1000
			if score > best_score:
				best_score = score
				best = cell
	return best


static func eligible(board, cell: Vector2i) -> bool:
	var tile = board.get_tile(cell)
	return tile != null and not board.is_swap_blocked(cell) and not tile.has_powerup() and int(tile.get_tile_type()) not in [Constants.TileType.ETHAN, Constants.TileType.VICTOR]


static func type_at(board, cell: Vector2i, placement: Vector2i, first: Vector2i, second: Vector2i) -> int:
	var source := second if cell == first else (first if cell == second else cell)
	if source == placement: return Constants.TileType.ETHAN
	var tile = board.get_tile(source)
	return int(tile.get_tile_type()) if tile != null else -1


static func run_size(board, placement: Vector2i, goal: int, first := Vector2i(-99,-99), second := Vector2i(-99,-99)) -> int:
	var anchor: Vector2i = second if placement == first else (first if placement == second else placement)
	var best := 0
	for direction in [Vector2i.RIGHT, Vector2i.DOWN]:
		var count := 0
		for sign_value in [-1,1]:
			var cursor: Vector2i = anchor+direction*sign_value
			while board.is_inside(cursor) and not board.is_swap_blocked(cursor) and type_at(board,cursor,placement,first,second) == goal:
				count += 1
				cursor += direction*sign_value
		best = maxi(best,count)
	return best


static func can_complete_next_move(board, placement: Vector2i, goal: int) -> bool:
	for axis in [Vector2i.RIGHT,Vector2i.DOWN]:
		for offset in range(-2,3):
			var first: Vector2i = placement+axis*offset
			if not eligible(board,first): continue
			for direction in [Vector2i.RIGHT,Vector2i.LEFT,Vector2i.UP,Vector2i.DOWN]:
				var second: Vector2i = first+direction
				if eligible(board,second) and run_size(board,placement,goal,first,second) >= 2: return true
	return false
