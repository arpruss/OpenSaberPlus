extends Node3D
class_name Wall

var despawn_z: float
var speed: float

func _physics_process(delta: float) -> void:
	if Scoreboard.paused: return
	transform.origin.z += speed * delta
	
	# remove children that go to far
	if transform.origin.z > despawn_z:
		queue_free()

func spawn(wall_info: ObstacleInfo, current_beat: float) -> void:
	var mesh := $WallMeshOrientation/WallMesh as MeshInstance3D
	var m := mesh.mesh as BoxMesh
	var shape := ($WallMeshOrientation/WallArea/CollisionShape3D as CollisionShape3D).shape as BoxShape3D
	
	var x_size := wall_info.width * Settings.LANE_DISTANCE_X
	# ARP: TODO is this right?
	var y_size := wall_info.height * Constants.LANE_DISTANCE_Y
	var z_size := wall_info.duration * Constants.BEAT_DISTANCE
	var depth := z_size * 0.5
	m.size.x = x_size
	shape.size.x = x_size
	m.size.y = y_size
	shape.size.y = y_size
	m.size.z = z_size
	shape.size.z = z_size
	despawn_z = Constants.MISS_Z + depth
	(mesh.material_override as ShaderMaterial).set_shader_parameter(&"size", Vector3(x_size, y_size, z_size))
	
	transform.origin.x = (0.5 * wall_info.width + wall_info.line_index - 2) * Settings.LANE_DISTANCE_X
	transform.origin.y = (0.5 * wall_info.height + wall_info.line_layer) * Constants.LANE_DISTANCE_Y
	transform.origin.z = (current_beat - wall_info.beat) * Constants.BEAT_DISTANCE - depth
	
	speed = Constants.BEAT_DISTANCE * Map.current_info.beats_per_minute / 60.0
	($AnimationPlayer as AnimationPlayer).play(&"Spawn")
