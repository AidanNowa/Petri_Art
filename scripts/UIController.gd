# PetriUIController.gd
extends Control
class_name PetriUIController

# References
@onready var petri_dish: PetriDish = $PetriDish
@onready var tool_buttons: HBoxContainer = $ToolPanel/ToolButtons
@onready var run_button: Button = $ControlPanel/RunButton
@onready var clear_button: Button = $ControlPanel/ClearButton
@onready var step_button: Button = $ControlPanel/StepButton

# Tool selection
enum PlacementTool {
	BACTERIA,
	FOOD,
	ANTIBIOTIC,
	ERASER
}

var current_tool: PlacementTool = PlacementTool.BACTERIA
var is_simulating: bool = false

# Tool buttons
var bacteria_button: Button
var food_button: Button
var antibiotic_button: Button
var eraser_button: Button

func _ready():
	setup_ui()
	connect_signals()

func setup_ui():
	"""Initialize the UI components"""
	create_tool_buttons()
	setup_control_panel()
	
	# Highlight the default tool
	update_tool_selection()

func create_tool_buttons():
	"""Create the tool selection buttons"""
	bacteria_button = create_tool_button("Bacteria", "res://icons/bacteria.png")
	bacteria_button.pressed.connect(_on_bacteria_selected)
	
	food_button = create_tool_button("Food", "res://icons/food.png")
	food_button.pressed.connect(_on_food_selected)
	
	antibiotic_button = create_tool_button("Antibiotic", "res://icons/antibiotic.png")
	antibiotic_button.pressed.connect(_on_antibiotic_selected)
	
	eraser_button = create_tool_button("Eraser", "res://icons/eraser.png")
	eraser_button.pressed.connect(_on_eraser_selected)

func create_tool_button(text: String, icon_path: String) -> Button:
	"""Create a tool button with icon and text"""
	var button = Button.new()
	button.text = text
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(80, 60)
	
	# Try to load icon if it exists
	if ResourceLoader.exists(icon_path):
		button.icon = load(icon_path)
	
	tool_buttons.add_child(button)
	return button

func setup_control_panel():
	"""Setup the simulation control buttons"""
	run_button.text = "Run Simulation"
	run_button.pressed.connect(_on_run_pressed)
	
	clear_button.text = "Clear All"
	clear_button.pressed.connect(_on_clear_pressed)
	
	step_button.text = "Step"
	step_button.pressed.connect(_on_step_pressed)
	step_button.disabled = true

func connect_signals():
	"""Connect petri dish signals"""
	petri_dish.cell_clicked.connect(_on_cell_clicked)
	petri_dish.simulation_step_complete.connect(_on_simulation_step_complete)

func _on_bacteria_selected():
	current_tool = PlacementTool.BACTERIA
	update_tool_selection()

func _on_food_selected():
	current_tool = PlacementTool.FOOD
	update_tool_selection()

func _on_antibiotic_selected():
	current_tool = PlacementTool.ANTIBIOTIC
	update_tool_selection()

func _on_eraser_selected():
	current_tool = PlacementTool.ERASER
	update_tool_selection()

func update_tool_selection():
	"""Update visual state of tool buttons"""
	bacteria_button.button_pressed = (current_tool == PlacementTool.BACTERIA)
	food_button.button_pressed = (current_tool == PlacementTool.FOOD)
	antibiotic_button.button_pressed = (current_tool == PlacementTool.ANTIBIOTIC)
	eraser_button.button_pressed = (current_tool == PlacementTool.ERASER)

func _on_cell_clicked(x: int, y: int, current_state: PetriDish.CellState):
	"""Handle cell clicks during setup phase"""
	if is_simulating:
		return
	
	var new_state: PetriDish.CellState
	
	match current_tool:
		PlacementTool.BACTERIA:
			new_state = PetriDish.CellState.BACTERIA
		PlacementTool.FOOD:
			new_state = PetriDish.CellState.FOOD
		PlacementTool.ANTIBIOTIC:
			new_state = PetriDish.CellState.ANTIBIOTIC
		PlacementTool.ERASER:
			new_state = PetriDish.CellState.EMPTY
	
	# Toggle off if clicking same type, otherwise set new type
	if current_state == new_state and current_tool != PlacementTool.ERASER:
		new_state = PetriDish.CellState.EMPTY
	
	petri_dish.set_cell_state(x, y, new_state)

func _on_run_pressed():
	"""Start or stop the simulation"""
	if is_simulating:
		stop_simulation()
	else:
		start_simulation()

func _on_clear_pressed():
	"""Clear the entire grid"""
	if is_simulating:
		stop_simulation()
	
	petri_dish.clear_grid()

func _on_step_pressed():
	"""Perform a single simulation step"""
	if is_simulating:
		# This will be implemented when we add the simulation logic
		pass

func start_simulation():
	"""Start the simulation"""
	is_simulating = true
	run_button.text = "Stop Simulation"
	step_button.disabled = false
	
	# Disable tool buttons during simulation
	set_tools_enabled(false)
	
	# Start simulation timer or step-by-step mode
	# This will be expanded when we implement the simulation logic

func stop_simulation():
	"""Stop the simulation"""
	is_simulating = false
	run_button.text = "Run Simulation"
	step_button.disabled = true
	
	# Re-enable tool buttons
	set_tools_enabled(true)

func set_tools_enabled(enabled: bool):
	"""Enable or disable tool buttons"""
	bacteria_button.disabled = not enabled
	food_button.disabled = not enabled
	antibiotic_button.disabled = not enabled
	eraser_button.disabled = not enabled

func _on_simulation_step_complete():
	"""Handle completion of a simulation step"""
	# This can be used for updating UI, checking win conditions, etc.
	pass

# Utility functions for level loading
func load_preset_pattern(pattern_data: Dictionary):
	"""Load a preset pattern into the dish"""
	petri_dish.clear_grid()
	
	if pattern_data.has("bacteria"):
		for pos in pattern_data.bacteria:
			petri_dish.set_cell_state(pos.x, pos.y, PetriDish.CellState.BACTERIA)
	
	if pattern_data.has("food"):
		for pos in pattern_data.food:
			petri_dish.set_cell_state(pos.x, pos.y, PetriDish.CellState.FOOD)
	
	if pattern_data.has("antibiotics"):
		for pos in pattern_data.antibiotics:
			petri_dish.set_cell_state(pos.x, pos.y, PetriDish.CellState.ANTIBIOTIC)

func get_current_pattern() -> Dictionary:
	"""Get the current pattern as data"""
	return {
		"bacteria": petri_dish.get_all_cells_of_state(PetriDish.CellState.BACTERIA),
		"food": petri_dish.get_all_cells_of_state(PetriDish.CellState.FOOD),
		"antibiotics": petri_dish.get_all_cells_of_state(PetriDish.CellState.ANTIBIOTIC)
	}
