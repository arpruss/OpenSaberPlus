extends Node
class_name ScenePool

# emitted when the ScenePool intances a new scene for the first time
# obj - the reference to the newly instanced scene
# during_presizing - true if the obj was created during a presize() call
#             false if the obj was created during an acquire() call due to the
#             pool being completly exhausted.
signal new_scene_instanced(obj: Node3D, during_presizing: bool)

@export var scene : PackedScene = null

var _total_objs := 0
var _free_list: Array[PooledNode3D] = []

func total_count() -> int:
	return _total_objs

func free_count() -> int:
	return _free_list.size()

# adds 'new_size' # of nodes to the pool to allow for initialization at startup
func presize(new_size: int):
	if _total_objs > 0:
		vr.log_warning("pool already has objects. ignoring presize request.")
		return
	
	for nn in new_size:
		_free_list.push_back(_instance_new_scene(true))
	vr.log_info("%s - size = %d" % [name, _free_list.size()])

func acquire() -> PooledNode3D:
	var node = _free_list.pop_back() as PooledNode3D
	if not node:
		node = _instance_new_scene(false)
	node._is_released = false
	return node

func _instance_new_scene(during_presizing: bool) -> Node3D:
	_total_objs += 1
	var new_node := scene.instantiate() as PooledNode3D
	new_node._parent_pool = self
	new_scene_instanced.emit(new_node, during_presizing)
	return new_node

func _on_scene_released(node: PooledNode3D) -> void:
	_free_list.push_back(node)
