extends RefCounted
class_name BombInfo

var beat: float
var line_index: int
var line_layer: int

@warning_ignore("shadowed_variable")
func _init(beat: float, line_index: int, line_layer: int) -> void:
	self.beat = beat
	self.line_index = line_index
	self.line_layer = line_layer

static func new_v2(bomb_dict: Dictionary) -> BombInfo:
	return BombInfo.new(
		Utils.get_float(bomb_dict, "_time", 0.0),
		int(Utils.get_float(bomb_dict, "_lineIndex", 0)),
		int(Utils.get_float(bomb_dict, "_lineLayer", 0))
	)

static func new_v3(bomb_dict: Dictionary) -> BombInfo:
	return BombInfo.new(
		Utils.get_float(bomb_dict, "b", 0.0),
		int(Utils.get_float(bomb_dict, "x", 0)),
		int(Utils.get_float(bomb_dict, "y", 0))
	)
