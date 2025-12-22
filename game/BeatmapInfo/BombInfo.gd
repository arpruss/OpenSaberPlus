extends RefCounted
class_name BombInfo

var beat: float
var line_index: float
var line_layer: float
var rotation: float

@warning_ignore("shadowed_variable")
func _init(beat: float, line_index: int, line_layer: int, rotation_degrees: float) -> void:
	self.beat = beat
	self.line_index = line_index if line_index < 1000 else (line_index-1000.)/1000.
	self.line_layer = line_layer if line_layer < 1000 else (line_layer-1000.)/1000.
	self.rotation = rotation_degrees * (PI/180.)
	if abs(Settings.gradual_rotation) > 1e-5:
		self.rotation += Settings.gradual_rotation * beat
		self.rotation += Settings.gradual_rotation * beat

static func new_v2(bomb_dict: Dictionary) -> BombInfo:
	return BombInfo.new(
		Utils.get_float(bomb_dict, "_time", 0.0),
		int(Utils.get_float(bomb_dict, "_lineIndex", 0)),
		int(Utils.get_float(bomb_dict, "_lineLayer", 0)),
		Utils.get_float(bomb_dict, "r", 0)
	)

static func new_v3(bomb_dict: Dictionary) -> BombInfo:
	return BombInfo.new(
		Utils.get_float(bomb_dict, "b", 0.0),
		int(Utils.get_float(bomb_dict, "x", 0)),
		int(Utils.get_float(bomb_dict, "y", 0)),
		Utils.get_float(bomb_dict, "r", 0)
	)
