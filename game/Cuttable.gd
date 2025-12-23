extends PooledNode3D
class_name Cuttable

var speed_x: float
var speed_z: float
var speed: float
var beat: float

# used to release the cube once both of it's cut pieces have died off
# Note: serves no purpose for bombs
var _piece_death_count := 0

# overridden by bombs and cubes
@warning_ignore("unused_parameter")
func set_collision_disabled(value: bool) -> void:
	return

# overriden by bombs and cubes
@warning_ignore("unused_parameter")
func cut(saber: LightSaber, cut_speed: Vector3, cut_plane: Plane, controller: BeepSaberController) -> void:
	return

# this too
func on_miss() -> void:
	return

func _on_cut_piece_died():
	_piece_death_count += 1
	if _piece_death_count >= 2:
		release()
		
func add_lane_rotation(angle):
	var c := cos(angle)
	var s := sin(angle)
	
	speed_x = -speed * s
	speed_z = speed * c

	var x := transform.origin.x
	var z := transform.origin.z
	transform.origin.x = c * x - s * z
	transform.origin.z = s * x + c * z
	
	rotation.y = -angle
	#transform = transform.rotated(Vector3(0,0,1), note_info.cut_angle).translated(Vector3(x,y,z)).rotated(Vector3(0,1,0), beat/30.)

func _physics_process(delta: float) -> void:
	if Scoreboard.paused or not is_visible_in_tree() or not Map.current_info: return
	
	transform.origin += speed * delta * transform.basis.z
	var rz := global_transform.origin.dot(transform.basis.z)
	
	if rz > -3.0:
		set_collision_disabled(false)
	if rz > Constants.MISS_Z:
		on_miss()

	# enable collisions when cuttable gets close enough to player
	#if global_transform.origin.z > -3.0:
	#	set_collision_disabled(false)
	
	# remove children that go to far
	#if global_transform.origin.z > Constants.MISS_Z:
	#	on_miss()

	#var rz := global_transform.rotated(Vector3(0,1,0), -rotation.y).origin.z
