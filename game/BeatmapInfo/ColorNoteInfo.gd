extends RefCounted
class_name ColorNoteInfo

var beat: float
var line_index: float
var line_layer: float
var color: int # 0=left, 1=right
var cut_angle: float

@warning_ignore("shadowed_variable")
func _init(beat: float, line_index: float, line_layer: float, color: int, cut_angle: float) -> void:
	self.beat = beat
	self.line_index = line_index
	self.line_layer = line_layer + (line_index/3.)
	self.color = color
	self.cut_angle = cut_angle

static func new_v2(note_dict: Dictionary) -> ColorNoteInfo:
	return ColorNoteInfo.new(
		Utils.get_float(note_dict, "_time", 0.0),
		Utils.precise_measurement(Utils.get_float(note_dict, "_lineIndex", 0)),
		Utils.precise_measurement(Utils.get_float(note_dict, "_lineLayer", 0)),
		int(Utils.get_float(note_dict, "_type", -1.0)),
		Utils.precise_angle_rad(Utils.get_float(note_dict, "_cutDirection", 0), 0)
	)

static func new_v3(note_dict: Dictionary) -> ColorNoteInfo:
	return ColorNoteInfo.new(
		Utils.get_float(note_dict, "b", 0.0),
		Utils.precise_measurement(Utils.get_float(note_dict, "x", 0)),
		Utils.precise_measurement(Utils.get_float(note_dict, "y", 0)),
		int(Utils.get_float(note_dict, "c", 0)),
		Utils.precise_angle_rad(Utils.get_float(note_dict, "d", 0), Utils.get_float(note_dict, "a", 0))
	)
