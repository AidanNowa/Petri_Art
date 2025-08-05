# PetriDish.gd
extends Node2D
class_name PetriDish

# Grid dimensions
@export var grid_width: int = 50
@export var grid_height: int = 50
@export var cell_size: int = 16

# Cell states enum
enum CellState {
	EMPTY,
	BACTERIA,
	FOOD,
	ANTIBIOTIC,
	DEAD_BACTERIA
}

# Grid data structures
var current_grid: Array[Array] = []
var next_grid: Array[Array] = []

# Visual components
var tilemap: TileMap
var background_circle: Node2D

# Signals for UI interaction
signal cell_clicked(x: int, y: int, current_state: CellState)
signal simulation_step_complete()

func _ready():
	setup_grid()
	setup_visuals()
	setup_input_handling()

func setup_grid():
	"""Initialize the grid arrays with empty cells"""
	current_grid.clear()
	next_grid.clear()
	
	for x in range(grid_width):
		current_grid.append([])
		next_grid.append([])
		for y in range(grid_height):
			current_grid[x].append(CellState.EMPTY)
			next_grid[x].append(CellState.EMPTY)

func setup_visuals():
	"""Create the visual representation of the petri dish"""
	# Create background petri dish circle
	background_circle = Node2D.new()
	add_child(background_circle)
	
	# Create tilemap for the grid
	tilemap = TileMap.new()
	tilemap.tile_set = load("res://tilesets/petri_tileset.tres") # You'll need to create this
	add_child(tilemap)
	
	# Position the dish in the center of the screen
	var dish_radius = min(grid_width, grid_height) * cell_size / 2
	position = get_viewport().get_visible_rect().size / 2 - Vector2(dish_radius, dish_radius)
	
	draw_background_dish()
	update_visual_grid()

func draw_background_dish():
	"""Draw the circular petri dish background"""
	var dish_radius = min(grid_width, grid_height) * cell_size / 2
	
	# You can either use a custom draw function or a simple ColorRect/TextureRect
	# For now, let's create a simple circular background
	var background_texture = preload("res://assets/sprites/greybox.png") # Create this asset
	var sprite = Sprite2D.new()
	sprite.texture = background_texture
	sprite.position = Vector2(dish_radius, dish_radius)
	background_circle.add_child(sprite)

func setup_input_handling():
	"""Setup mouse input for cell interaction during setup phase"""
	pass # We'll handle this in _unhandled_input

func _unhandled_input(event):
	"""Handle mouse clicks on the grid during setup phase"""
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var local_pos = to_local(event.position)
			var grid_pos = world_to_grid(local_pos)
			
			if is_valid_grid_position(grid_pos.x, grid_pos.y):
				handle_cell_click(grid_pos.x, grid_pos.y)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	"""Convert world position to grid coordinates"""
	return Vector2i(
		int(world_pos.x / cell_size),
		int(world_pos.y / cell_size)
	)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	"""Convert grid coordinates to world position"""
	return Vector2(
		grid_pos.x * cell_size + cell_size / 2.0,
		grid_pos.y * cell_size + cell_size / 2.0
	)

func is_valid_grid_position(x: int, y: int) -> bool:
	"""Check if the given coordinates are within the grid bounds"""
	return x >= 0 and x < grid_width and y >= 0 and y < grid_height

func is_within_petri_dish(x: int, y: int) -> bool:
	"""Check if the position is within the circular petri dish bounds"""
	var center = Vector2(grid_width / 2.0, grid_height / 2.0)
	var pos = Vector2(x, y)
	var radius = min(grid_width, grid_height) / 2.0 - 1
	
	return center.distance_to(pos) <= radius

func handle_cell_click(x: int, y: int):
	"""Handle clicking on a cell during setup phase"""
	if not is_within_petri_dish(x, y):
		return
	
	var current_state = current_grid[x][y]
	cell_clicked.emit(x, y, current_state)

func set_cell_state(x: int, y: int, state: CellState):
	"""Set the state of a specific cell"""
	if is_valid_grid_position(x, y) and is_within_petri_dish(x, y):
		current_grid[x][y] = state
		update_cell_visual(x, y)

func get_cell_state(x: int, y: int) -> CellState:
	"""Get the state of a specific cell"""
	if is_valid_grid_position(x, y):
		return current_grid[x][y]
	return CellState.EMPTY

func update_cell_visual(x: int, y: int):
	"""Update the visual representation of a single cell"""
	var source_id = 0 # Assuming single tileset source
	var atlas_coords = get_atlas_coords_for_state(current_grid[x][y])
	
	if current_grid[x][y] == CellState.EMPTY:
		tilemap.erase_cell(0, Vector2i(x, y))
	else:
		tilemap.set_cell(0, Vector2i(x, y), source_id, atlas_coords)

func get_atlas_coords_for_state(state: CellState) -> Vector2i:
	"""Map cell states to tileset atlas coordinates"""
	match state:
		CellState.EMPTY:
			return Vector2i(-1, -1) # No tile
		CellState.BACTERIA:
			return Vector2i(0, 0)
		CellState.FOOD:
			return Vector2i(1, 0)
		CellState.ANTIBIOTIC:
			return Vector2i(2, 0)
		CellState.DEAD_BACTERIA:
			return Vector2i(0, 1)
		_:
			return Vector2i(-1, -1)

func update_visual_grid():
	"""Update the entire visual grid"""
	tilemap.clear()
	
	for x in range(grid_width):
		for y in range(grid_height):
			update_cell_visual(x, y)

func clear_grid():
	"""Clear all cells in the grid"""
	for x in range(grid_width):
		for y in range(grid_height):
			current_grid[x][y] = CellState.EMPTY
			next_grid[x][y] = CellState.EMPTY
	
	update_visual_grid()

func get_neighbor_count(x: int, y: int, state: CellState) -> int:
	"""Count neighbors of a specific state around a cell"""
	var count = 0
	
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			
			var nx = x + dx
			var ny = y + dy
			
			if is_valid_grid_position(nx, ny) and current_grid[nx][ny] == state:
				count += 1
	
	return count

func copy_current_to_next():
	"""Copy current grid state to next grid for simulation"""
	for x in range(grid_width):
		for y in range(grid_height):
			next_grid[x][y] = current_grid[x][y]

func apply_next_grid():
	"""Apply the next grid state to current grid"""
	for x in range(grid_width):
		for y in range(grid_height):
			current_grid[x][y] = next_grid[x][y]
	
	update_visual_grid()
	simulation_step_complete.emit()

# Utility functions for setup UI
func get_all_cells_of_state(state: CellState) -> Array[Vector2i]:
	"""Get all cells that match a specific state"""
	var cells: Array[Vector2i] = []
	
	for x in range(grid_width):
		for y in range(grid_height):
			if current_grid[x][y] == state:
				cells.append(Vector2i(x, y))
	
	return cells

func set_multiple_cells(positions: Array[Vector2i], state: CellState):
	"""Set multiple cells to a specific state"""
	for pos in positions:
		set_cell_state(pos.x, pos.y, state)
