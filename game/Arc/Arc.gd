extends Node3D
class_name Arc

static var left_material := load("res://game/Arc/Arc.material").duplicate() as ShaderMaterial
static var right_material := left_material.duplicate() as ShaderMaterial

static var left_material_magnet := left_material.duplicate() as ShaderMaterial
static var right_material_magnet := right_material.duplicate() as ShaderMaterial

@onready var visual: CSGPolygon3D = $Path3D/Visual

@export var arc_angle_force := 2.0
@export var mid_points := 3

var arc_info: ArcInfo
var activator_cube: BeepCube

var speed: float
var despawn_z: float

func spawn(info: ArcInfo, current_beat: float, _activator_cube: BeepCube = null) -> void:
	arc_info = info
	speed = Constants.BEAT_DISTANCE * Map.current_info.beats_per_minute * 0.016666666666666667
	visual = $Path3D/Visual
	visual.material_override = right_material if arc_info.color == 1 else left_material
	activator_cube = _activator_cube
	if activator_cube:
		activator_cube.cutted.connect(_on_activator_cube_cutted)
	else:
		start_magnet()
	
	var head_pos := Vector3(
		Settings.LANE_DISTANCE_X * float(info.head_line_index) + Settings.LANE_ZERO_X,
		Constants.LANE_DISTANCE_Y * float(info.head_line_layer) + Constants.LAYER_ZERO_Y,
		-(info.head_beat - current_beat) * Constants.BEAT_DISTANCE
	)
	var tail_pos := Vector3(
		Settings.LANE_DISTANCE_X * float(info.tail_line_index) + Settings.LANE_ZERO_X,
		Constants.LANE_DISTANCE_Y * float(info.tail_line_layer) + Constants.LAYER_ZERO_Y,
		-(info.tail_beat - current_beat) * Constants.BEAT_DISTANCE
	)
	despawn_z = Constants.MISS_Z - tail_pos.z
	
	var head_rotation: Vector2
	var tail_rotation: Vector2
	if info.head_cut_direction == 8:
		head_rotation = Vector2.ZERO
	else:
		head_rotation = Constants.ROTATION_UNIT_VECTORS[info.head_cut_direction] * info.head_control_point_length_multiplier
	if info.tail_cut_direction == 8:
		tail_rotation = Vector2.ZERO
	else:
		tail_rotation = -Constants.ROTATION_UNIT_VECTORS[info.tail_cut_direction] * info.tail_control_point_length_multiplier
	
	var curve := ($Path3D as Path3D).curve
	curve.clear_points()
	
	# sets the origin of the tail at the tail point to use in the shader for a fade out effect
	$Path3D.position = tail_pos
	
	curve.add_point(head_pos - tail_pos, Vector3.ZERO, Vector3(head_rotation.x, head_rotation.y, 0.0) * arc_angle_force)
	
	if info.mid_anchor_mode > 0:
		for midpoint_id in range(mid_points):
			var range : float = (float(midpoint_id+1) / (mid_points+1))
			var head_rot := Constants.CUBE_ROTATIONS[info.head_cut_direction]
			
			var point_pos :=  head_pos.lerp(tail_pos, range)
			point_pos += Vector3(head_rotation.x, head_rotation.y, 0.0).rotated(Vector3(0,0,1), 
					(
						(PI if info.head_cut_direction == info.tail_cut_direction else TAU)
						*(-range if info.mid_anchor_mode == 1 else range)
					)
				) * arc_angle_force
			
			curve.add_point(point_pos - tail_pos, Vector3.ZERO, Vector3.ZERO)
		# calculate smooth in out directions after all points have been set
		for smoothpoint_id in range(mid_points):
			var prev_point_pos := curve.get_point_position(smoothpoint_id)
			var current_point_pos := curve.get_point_position(smoothpoint_id + 1)
			var next_point_pos := curve.get_point_position(smoothpoint_id + 2)
			# Calculate vectors to previous and next points and the average direction
			var to_prev := (prev_point_pos - current_point_pos).normalized()
			var to_next := (next_point_pos - current_point_pos).normalized()
			var smooth_dir := (to_next - to_prev).normalized()
			var distance := (prev_point_pos.distance_to(current_point_pos) + 
							current_point_pos.distance_to(next_point_pos)) * 0.25
			curve.set_point_in(smoothpoint_id + 1, smooth_dir * -distance)
			curve.set_point_out(smoothpoint_id + 1, smooth_dir * distance)
	
	curve.add_point(tail_pos - tail_pos, Vector3(tail_rotation.x, tail_rotation.y, 0.0) * arc_angle_force, Vector3.ZERO)

func _on_activator_cube_cutted(correct_saber: bool) -> void:
	if activator_cube and activator_cube.cutted.is_connected(_on_activator_cube_cutted):
		activator_cube.cutted.disconnect(_on_activator_cube_cutted)
	if correct_saber:
		start_magnet()

# sets the magnet version of the material (and ensures correct magnet parameter)
func start_magnet() -> void:
	visual.material_override = right_material_magnet if arc_info.color == 1 else left_material_magnet
	visual.material_override.set_shader_parameter(&"saber_magnet", arc_info.color+1)

func _process(delta: float) -> void:
	if Scoreboard.paused or not is_visible_in_tree() or not Map.current_info: return
	transform.origin.z += speed * delta
	if transform.origin.z >= despawn_z:
		if activator_cube and activator_cube.cutted.is_connected(_on_activator_cube_cutted):
			activator_cube.cutted.disconnect(_on_activator_cube_cutted)
		queue_free()
