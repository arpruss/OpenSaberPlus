extends Node3D
class_name SaberTail

@onready var material := ($Mesh as MeshInstance3D).material_override as StandardMaterial3D
@onready var imm_geo := ($Mesh as MeshInstance3D).mesh as ImmediateMesh

@export var size := 1.0

# for the math in _process to work properly and the tail to be drawn in the
# right spot,the mesh has to be reparented to root.
# TODO: reparenting to root like this is difficult for any future coders to
# follow.  the math should be rewritten to work without reparenting.
func _ready() -> void:
	var mesh := $Mesh as MeshInstance3D
	remove_child(mesh)
	get_tree().get_root().add_child.call_deferred(mesh)

func set_color(color: Color) -> void:
	material.albedo_color = color
	material.emission = color

class HistoricalPositions:
	extends RefCounted
	
	var base_pos := Vector3() # global position of blade at the base (near handle)
	var tip_pos := Vector3()  # blogal position of blade at the tip
	var age := 0.0 as float
	
	func _init(base: Vector3, tip: Vector3):
		base_pos = base
		tip_pos = tip

var last_pos: Array[HistoricalPositions] = []
const MAX_AGE := 0.15 as float
func _process(delta: float) -> void:
	if visible and size > 0:
		var pos := HistoricalPositions.new(global_position, to_global(position + Vector3(0,size,0)))
		imm_geo.clear_surfaces()
		if last_pos.size() > 0:
			imm_geo.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

			var new_size = -1 as int
			for i in range(last_pos.size()):
				var posA := pos
				if i > 0:
					posA = last_pos[i-1]
				var posB := last_pos[i]
				
				var t := clampf(last_pos[i].age / MAX_AGE, 0.02, 0.98)
				var offsetted := clampf(t + (1.0/last_pos.size()), 0.02, 0.98)

				imm_geo.surface_set_uv(Vector2(t,0.98))
				imm_geo.surface_add_vertex(posA.base_pos)
				imm_geo.surface_set_uv(Vector2(t,0.02))
				imm_geo.surface_add_vertex(posA.tip_pos)
				imm_geo.surface_set_uv(Vector2(offsetted,0.02))
				imm_geo.surface_add_vertex(posB.tip_pos)

				imm_geo.surface_set_uv(Vector2(t,0.98))
				imm_geo.surface_add_vertex(posA.base_pos)
				imm_geo.surface_set_uv(Vector2(offsetted,0.98))
				imm_geo.surface_add_vertex(posB.base_pos)
				imm_geo.surface_set_uv(Vector2(offsetted,0.02))
				imm_geo.surface_add_vertex(posB.tip_pos)
				
				last_pos[i].age += delta
				if new_size < 0 && last_pos[i].age > MAX_AGE:
					new_size = i

			imm_geo.surface_end()
			
			if new_size >= 0:
				last_pos.resize(new_size)

		last_pos.push_front(pos)
	elif last_pos.size() > 0:
		imm_geo.clear_surfaces()
		last_pos = []
