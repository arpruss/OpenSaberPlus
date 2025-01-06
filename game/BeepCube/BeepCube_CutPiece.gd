extends RigidBody3D
class_name CutPiece

# structure of nodes that represent a cut piece of a cube (ie. one half)
static var cube_phys_mat := load("res://game/BeepCube/BeepCube_Cut.phymat") as PhysicsMaterial
var mesh := MeshInstance3D.new()
var coll := CollisionShape3D.new()
var lifetime: float = 0.0

func _init(mesh_in: Mesh, mat_in: ShaderMaterial, bouncy: bool) -> void:
	add_to_group(&"cutted_cube")
	mat_in.set_shader_parameter(&"cutted", true)
	collision_layer = 0
	collision_mask = CollisionLayerConstants.Floor_mask
	gravity_scale = 1
	if bouncy:
		# set a phyiscs material for some more bouncy behaviour
		physics_material_override = cube_phys_mat
	
	mesh.mesh = mesh_in
	mesh.layers = 3 # visible to both spectator and player
	mesh.material_override = mat_in
	
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.25, 0.25, 0.125)
	coll.shape = shape
	
	add_child(coll)
	add_child(mesh)

func setup_cut(dist_from_center, angle) -> void:
	lifetime = 0.0
	angular_velocity = Vector3()
	linear_velocity = Vector3()
	mesh.material_override.set_shader_parameter(&"cut_dist_from_center", dist_from_center)
	mesh.material_override.set_shader_parameter(&"cut_angle", angle)

func set_color(new_color: Color) -> void:
	mesh.material_override.set_shader_parameter(&"color", new_color)
	
func set_chain_head(is_chain_head: bool) -> void:
	mesh.material_override.set_shader_parameter(&"is_chain_head", is_chain_head)

const MAX_LIFETIME := 0.3;

func _physics_process(delta: float) -> void:
	lifetime += delta
	if lifetime > MAX_LIFETIME:
		get_parent().remove_child(self)
	else:
		# the "cut_vanish" shader parameter controls how faded-out the
		# piece is. 0.0 is not faded out at all, and higher numbers make it
		# more faded. we use ease() with a curve arguments of 2.0 which starts
		# the fade slowly, but then ramps up more quickly toward the end of the
		# lifetime. see this reddit post for a visual of ease() curve values.
		# https://forum.godotengine.org/t/how-do-i-properly-use-the-ease-function/20396/2
		var fade := lifetime / MAX_LIFETIME
		mesh.material_override.set_shader_parameter(&"cut_vanish",ease(fade,2.0)*0.5)
