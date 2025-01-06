extends PooledNode3D
class_name Cuttable

var speed: float
var beat: float

# overridden by bombs and cubes
@warning_ignore("unused_parameter")
func set_collision_disabled(value: bool) -> void:
	return

# also overriden by bombs and cubes
@warning_ignore("unused_parameter")
func cut(saber_type: int, cut_speed: Vector3, cut_plane: Plane, controller: BeepSaberController) -> void:
	return

# this too
func on_miss() -> void:
	return

func _physics_process(delta: float) -> void:
	if Scoreboard.paused or not is_visible_in_tree() or not Map.current_info: return
	transform.origin.z += speed * delta
	
	# enable collisions when cuttable gets close enough to player
	if global_transform.origin.z > -3.0:
		set_collision_disabled(false)
	
	# remove children that go to far
	if global_transform.origin.z > Constants.MISS_Z:
		on_miss()
