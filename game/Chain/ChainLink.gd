extends Cuttable
class_name ChainLink

# unfortunately, doing this instead of creating a .tscn file for pieces is much,
# much faster.  repeatedly instantiating a packed scene every time a single link
# gets cut leads to noticeable stutter.
class CutPiece extends RigidBody3D:
	var mesh := MeshInstance3D.new()
	var coll := CollisionShape3D.new()
	var lifetime: float = 0.0
	
	func _init() -> void:
		collision_layer = 0
		collision_mask = CollisionLayerConstants.Floor_mask
		gravity_scale = 1
		
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
			# copied from cube code.  the "cut_vanish" shader parameter controls
			# how faded-out the piece is.  0.0 is not faded out at all, and
			# higher numbers make it more faded.
			# other than that, not sure exactly what's going on here.
			# todo: figure that out and document it.
			# todo: figure out a better variable name than f.
			# todo: once figured out, do these todos in BeepCube.gd too
			# - steve hocktail
			var f := lifetime*(1.0/0.3)
			(mesh.material_override as ShaderMaterial).set_shader_parameter(&"cut_vanish",ease(f,2)*0.5)

var which_saber: int
@export var min_speed := 0.5

# do not make this a preload.  doing so will make the scene show up as corrupt
# in the editor.
static var CHAIN_LINK_TEMPLATE := load("res://game/Chain/ChainLink.tscn") as PackedScene
static var left_material := load("res://game/Chain/ChainLink.material").duplicate() as ShaderMaterial
static var right_material := left_material.duplicate() as ShaderMaterial

static func construct_chain(chain_info: ChainInfo, track_ref: Node3D, current_beat: float, note_info_refs: Array[ColorNoteInfo], cube_refs: Array[BeepCube]) -> void:
	# instead of just making a new note head for a new chain, beat saber
	# modifies an already-existing note to be the head, which is why we have to
	# do all this garbage with keeping references to other notes that were
	# spawned this frame.
	var i := 0
	while i < note_info_refs.size():
		var info_ref := note_info_refs[i]
		if (
			info_ref.beat == chain_info.head_beat
			and info_ref.line_index == chain_info.head_line_index
			and info_ref.line_layer == chain_info.head_line_layer
		):
			cube_refs[i].make_chain_head()
		i += 1
	
	# the curve of the chain is gotten from a 3-point bezier curve.  the first
	# point is the head position, the last point is the tail position, and the
	# mid point is based on the head and tail points.
	#
	# to get the mid point, draw a straight line from the head note, in the
	# direction the head note is pointing, with length equal to half the length
	# of a straight line from the head to the tail.  the end point of the line
	# you just drew is the mid point of the curve.
	var head_pos := Vector2(
		Constants.LANE_DISTANCE * float(chain_info.head_line_index) + Constants.LANE_ZERO_X,
		Constants.LANE_DISTANCE * float(chain_info.head_line_layer) + Constants.LAYER_ZERO_Y
	)
	var tail_pos := Vector2(
		Constants.LANE_DISTANCE * float(chain_info.tail_line_index) + Constants.LANE_ZERO_X,
		Constants.LANE_DISTANCE * float(chain_info.tail_line_layer) + Constants.LAYER_ZERO_Y
	)
	var mid_pos := head_pos + (Constants.ROTATION_UNIT_VECTORS[chain_info.head_cut_direction] * head_pos.distance_to(tail_pos) * 0.5)
	i = 1
	while i < chain_info.slice_count:
		var chain_link := CHAIN_LINK_TEMPLATE.instantiate() as ChainLink
		chain_link.spawn(chain_info, current_beat, head_pos, tail_pos, mid_pos, i)
		track_ref.add_child(chain_link)
		i += 1

func spawn(chain_info: ChainInfo, current_beat: float, head_pos: Vector2, tail_pos: Vector2, mid_pos: Vector2, link_index: int) -> void:
	speed = Constants.BEAT_DISTANCE * Map.current_info.beats_per_minute * 0.016666666666666667
	which_saber = chain_info.color
	
	var lerp_factor := float(link_index) / float(chain_info.slice_count - 1) * chain_info.squish_factor
	beat = lerpf(chain_info.head_beat, chain_info.tail_beat, lerp_factor)
	
	var q0 := head_pos.lerp(mid_pos, lerp_factor)
	var q1 := mid_pos.lerp(tail_pos, lerp_factor)
	var bezier_pos := q0.lerp(q1, lerp_factor)
	
	transform.origin.x = bezier_pos.x
	transform.origin.y = bezier_pos.y
	transform.origin.z = -(beat - current_beat) * Constants.BEAT_DISTANCE
	
	rotation.z = q0.angle_to_point(q1) - TAU*0.25
	
	# little bit of forgiveness.  if the chain link is more than a meter away
	# from the chain head, its hitbox is extended to halfway between the link
	# and the head.
	var z_distance_from_head := (beat - chain_info.head_beat) * Constants.BEAT_DISTANCE
	if z_distance_from_head > 1.0:
		var collision := $Area3D/CollisionShape3D as CollisionShape3D
		var new_size := z_distance_from_head * 0.5
		(collision.shape as BoxShape3D).size.z = new_size
		collision.transform.origin.z = new_size * 0.5 - 0.25
	
	($Mesh as MeshInstance3D).material_override = left_material if which_saber == 0 else right_material
	
	var anim := $AnimationPlayer as AnimationPlayer
	var anim_speed := Map.current_difficulty.note_jump_movement_speed / 9.0
	anim.speed_scale = maxf(min_speed,anim_speed)
	anim.play(&"Spawn")
	visible = true

func cut(saber_type: int, _cut_speed: Vector3, cut_plane: Plane, _controller: BeepSaberController) -> void:
	set_collision_disabled(true)
	_create_cut_rigid_body(cut_plane)
	if saber_type == which_saber:
		Scoreboard.chain_link_cut(transform.origin)
	else:
		Scoreboard.bad_cut(transform.origin)
	queue_free()

func on_miss() -> void:
	Scoreboard.reset_combo()
	queue_free()

func set_collision_disabled(value: bool) -> void:
	($Area3D/CollisionShape3D as CollisionShape3D).disabled = value

func _create_cut_rigid_body(cutplane: Plane) -> void:
	if !Settings.cube_cuts_falloff:
		return
	var piece_left := CutPiece.new()
	var piece_right := CutPiece.new()
	var mesh_ref := ($Mesh as MeshInstance3D)
	piece_left.mesh.mesh = mesh_ref.mesh
	piece_right.mesh.mesh = mesh_ref.mesh
	piece_left.transform = transform
	piece_right.transform = transform
	
	var left_mat := mesh_ref.material_override.duplicate() as ShaderMaterial
	left_mat.set_shader_parameter(&"cutted", true)
	var right_mat := left_mat.duplicate() as ShaderMaterial
	
	# calculate angle and position of the cut
	var cut_angle_abs := Vector2(cutplane.normal.x, cutplane.normal.y).angle()
	var cut_dist_from_center := cutplane.distance_to(transform.origin)
	var cut_angle_rel := cut_angle_abs - global_rotation.z
	
	left_mat.set_shader_parameter(&"cut_dist_from_center", -cut_dist_from_center)
	right_mat.set_shader_parameter(&"cut_dist_from_center", cut_dist_from_center)
	left_mat.set_shader_parameter(&"cut_angle", cut_angle_rel + PI)
	right_mat.set_shader_parameter(&"cut_angle", cut_angle_rel)
	piece_left.mesh.material_override = left_mat
	piece_right.mesh.material_override = right_mat
	
	# some impulse so the cube half moves
	var cutplane_2d := Vector3(cutplane.x, cutplane.y, 0.0)
	var splitplane_2d := cutplane_2d.cross(piece_left.transform.basis.z)
	piece_left.apply_central_impulse(-splitplane_2d)
	piece_right.apply_central_impulse(splitplane_2d)
	
	get_parent().add_child(piece_left)
	get_parent().add_child(piece_right)
