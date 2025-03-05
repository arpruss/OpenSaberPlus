extends Node3D
class_name PooledNode3D

# reference to the node's ScenePool that belongs to
# this will be set by the ScenePool class when the node is first instantiated
var _parent_pool : ScenePool = null

# set true when the node is released (ie. can be acquired again)
var _is_released = true

func is_released() -> bool:
	return _is_released

func release() -> void:
	if _is_released:
		vr.log_warning("%s was already released. ignoring duplicate call." % [name])
		return
	
	_parent_pool._on_scene_released(self)
	_is_released = true
