# BeepCube is the standard cube that will get cut by the sabers
extends Cuttable
class_name BeepCube

# emitted when the cube is 'destroyed'. this signal is required by ScenePool to
# manage when an instanced scene is free again.
signal scene_released(this: BeepCube)

# emitted when the cube gets cutted, correct_saber is true if the right saber was used
signal cutted(correct_saber: bool)

# the animation player contains the span animation that is applied to the CubeMeshAnimation node
@onready var collision_big := $BeepCube_Big/CollisionBig as CollisionShape3D
@onready var collision_small := $BeepCube_Small/CollisionSmall as CollisionShape3D

var which_saber: int
var is_dot: bool

static var particles_scene := load("res://game/BeepCube/BeepCube_SliceParticles.tscn") as PackedScene
# structure of nodes that represent a cut piece of a cube (ie. one half)
class CutPiece extends RigidBody3D:
	static var cube_phys_mat := load("res://game/BeepCube/BeepCube_Cut.phymat") as PhysicsMaterial
	var mesh := MeshInstance3D.new()
	var coll := CollisionShape3D.new()
	var lifetime: float = 0.0
	
	func _init() -> void:
		add_to_group(&"cutted_cube")
		collision_layer = 0
		collision_mask = CollisionLayerConstants.Floor_mask
		gravity_scale = 1
		# set a phyiscs material for some more bouncy behaviour
		physics_material_override = cube_phys_mat
		
		mesh.layers = 3 # visible to both spectator and player
		
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.25, 0.25, 0.125)
		coll.shape = shape
		
		add_child(coll)
		add_child(mesh)
	
	func _physics_process(delta: float) -> void:
		lifetime += delta
		if lifetime > 0.3:
			queue_free()
		else:
			var f := lifetime*(1.0/0.3)
			(mesh.material_override as ShaderMaterial).set_shader_parameter(&"cut_vanish",ease(f,2)*0.5)


# we store the mesh here as part of the BeepCube for easier access because we will
# reuse it when we create the cut cube pieces
var _mesh: Mesh
var _mat: ShaderMaterial
@export var min_speed := 0.5

func _ready() -> void:
	var mi := $BeepCubeMesh as MeshInstance3D
	_mat = mi.material_override as ShaderMaterial
	_mesh = mi.mesh

func spawn(note_info: ColorNoteInfo, current_beat: float, color: Color) -> void:
	speed = Constants.BEAT_DISTANCE * Map.current_info.beats_per_minute * 0.016666666666666667
	beat = note_info.beat
	which_saber = note_info.color
	is_dot = note_info.cut_direction == 8
	
	if is_dot:
		(collision_big.shape as BoxShape3D).size.y = 0.8
	else:
		(collision_big.shape as BoxShape3D).size.y = 0.5
	
	transform.origin.x = Constants.LANE_DISTANCE * float(note_info.line_index) + Constants.LANE_ZERO_X
	transform.origin.y = Constants.LANE_DISTANCE * float(note_info.line_layer) + Constants.LAYER_ZERO_Y
	transform.origin.z = -(note_info.beat - current_beat) * Constants.BEAT_DISTANCE
	
	rotation.z = Constants.CUBE_ROTATIONS[note_info.cut_direction] + deg_to_rad(note_info.angle_offset)
	
	_mat.set_shader_parameter(&"color", color)
	_mat.set_shader_parameter(&"is_dot", is_dot)
	# since cube instances get recycled, we gotta reset cubes that were chain
	# heads in a past life
	_mat.set_shader_parameter(&"is_chain_head", false)
	
	# separate cube collision layers to allow a diferent collider on right/wrong cuts.
	# opposing collision layers (ie. right note & left saber) will be placed on the
	# smalling collision shape, while similar collision layers (ie right note &
	# right saber) are placed on the larger collision shape.
	var is_left_note := note_info.color == 0
	var big_coll_area := $BeepCube_Big as Area3D
	big_coll_area.collision_layer = 0x0
	big_coll_area.set_collision_layer_value(CollisionLayerConstants.LeftNote_bit, is_left_note)
	big_coll_area.set_collision_layer_value(CollisionLayerConstants.RightNote_bit, not is_left_note)
	var small_coll_area := $BeepCube_Small as Area3D
	small_coll_area.collision_layer = 0x0
	small_coll_area.set_collision_layer_value(CollisionLayerConstants.LeftNote_bit, not is_left_note)
	small_coll_area.set_collision_layer_value(CollisionLayerConstants.RightNote_bit, is_left_note)
	
	visible = true
	
	# play the spawn animation when this cube enters the scene
	var anim := $AnimationPlayer as AnimationPlayer
	var anim_speed := Map.current_difficulty.note_jump_movement_speed / 9.0
	anim.speed_scale = maxf(min_speed,anim_speed)
	anim.play(&"Spawn")

func release() -> void:
	visible = false
	set_collision_disabled(true)
	scene_released.emit(self)

func make_chain_head() -> void:
	_mat.set_shader_parameter(&"is_chain_head", true)

func on_miss() -> void:
	Scoreboard.reset_combo()
	release()

func set_collision_disabled(value: bool) -> void:
	collision_big.disabled = value
	collision_small.disabled = value

func cut(saber_type: int, cut_speed: Vector3, cut_plane: Plane, controller: BeepSaberController) -> void:
	set_collision_disabled(true)
	
	# compute the angle between the cube orientation and the cut direction
	var cut_direction_xy := -Vector3(cut_speed.x, cut_speed.y, 0.0).normalized()
	var base_cut_angle_accuracy := global_transform.basis.y.dot(cut_direction_xy)
	var cut_distance := cut_plane.distance_to(global_transform.origin)
	
	_create_cut_rigid_body(cut_plane)
	
	if saber_type == which_saber:
		var cut_angle_accuracy := clampf((base_cut_angle_accuracy-0.7)/0.3, 0.0, 1.0)
		if is_dot: #ignore angle if is a dot
			cut_angle_accuracy = 1.0
		var cut_distance_accuracy := clampf((0.1 - absf(cut_distance))/0.1, 0.0, 1.0)
		var travel_distance_factor := controller.movement_aabb.get_longest_axis_size()
		travel_distance_factor = clampf((travel_distance_factor-0.5)/0.5, 0.0, 1.0)
		# allows a bit of save margin where the beat is considered 100% correct
		var beat_accuracy := clampf((1.0 - absf(global_transform.origin.z)) / 0.5, 0.0, 1.0)
		Scoreboard.note_cut(transform.origin, beat_accuracy, cut_angle_accuracy, cut_distance_accuracy, travel_distance_factor)
		cutted.emit(true)
	else:
		Scoreboard.bad_cut(transform.origin)
		cutted.emit(false)
	
	# reset the movement tracking volume for the next cut
	controller.reset_movement_aabb()
	
	release()

# cut the cube by creating two rigid bodies and using a CSGBox to create
# the cut plane
func _create_cut_rigid_body(cutplane: Plane) -> void:
	if !Settings.cube_cuts_falloff:
		return
	var piece_left := CutPiece.new()
	var piece_right := CutPiece.new()
	piece_left.global_transform = global_transform
	piece_right.global_transform = global_transform
	
	# the original cube mesh
	piece_left.mesh.mesh = _mesh
	piece_right.mesh.mesh = _mesh
	
	var left_mat := _mat.duplicate(true) as ShaderMaterial
	var right_mat := _mat.duplicate(true) as ShaderMaterial
	left_mat.set_shader_parameter(&"cutted", true)
	right_mat.set_shader_parameter(&"cutted", true)
	
	# calculate angle and position of the cut
	var cut_angle_abs := Vector2(cutplane.normal.x, cutplane.normal.y).angle()
	# multiply by 1.25 to make up for the mesh being at 0.8 scale
	var cut_dist_from_center := cutplane.distance_to(global_transform.origin)# * 1.25
	var cut_angle_rel := cut_angle_abs - global_rotation.z
	
	left_mat.set_shader_parameter(&"cut_dist_from_center", -cut_dist_from_center)
	right_mat.set_shader_parameter(&"cut_dist_from_center", cut_dist_from_center)
	left_mat.set_shader_parameter(&"cut_angle", cut_angle_rel + PI)
	right_mat.set_shader_parameter(&"cut_angle", cut_angle_rel)
	piece_left.mesh.material_override = left_mat
	piece_right.mesh.material_override = right_mat
	
	# transform the normal into the orientation of the actual cube mesh
	var normal := piece_left.mesh.transform.basis.inverse() * cutplane.normal
	
	# Next we are adding a simple collision cube to the rigid body. Note that
	# his is really just a very crude approximation of the actual cut geometry
	# but for now it's enough to give them some physics behaviour
	piece_left.coll.look_at_from_position(cutplane.normal*0.125, cutplane.normal, Vector3(0,1,0))
	piece_right.coll.look_at_from_position(-cutplane.normal*0.125, cutplane.normal, Vector3(0,1,0))
	
	# some impulse so the cube half moves
	var cutplane_2d := Vector3(cutplane.x * 2.0,cutplane.y * 2.0,0.0)
	var splitplane_2d := cutplane_2d.cross(piece_left.transform.basis.z)
	piece_left.apply_central_impulse(-splitplane_2d)
	piece_right.apply_central_impulse(splitplane_2d)
	
	get_parent().add_child(piece_left)
	get_parent().add_child(piece_right)
	var particles := particles_scene.instantiate() as BeepCubeSliceParticles
	get_parent().add_child(particles)
	particles.global_transform.origin = global_transform.origin
	particles.rotation.z = cut_angle_abs+TAU*0.25
	particles.fire()
