extends RefCounted
class_name ArcInfo

const MID_ANCHOR_MODE_STRAIGHT := 0
const MID_ANCHOR_MODE_CLOCKWISE := 1
const MID_ANCHOR_MODE_COUNTERCLOCKWISE := 2

var color: int
var head_beat: float
var head_line_index: int
var head_line_layer: int
var head_cut_direction: int
var head_control_point_length_multiplier: float
var tail_beat: float
var tail_line_index: int
var tail_line_layer: int
var tail_cut_direction: int
var tail_control_point_length_multiplier: float
var mid_anchor_mode: int

@warning_ignore("shadowed_variable")
func _init(
	color: int, head_beat: float, head_line_index: int, head_line_layer: int,
	head_cut_direction: int, head_control_point_length_multiplier: float,
	tail_beat: float, tail_line_index: int, tail_line_layer: int,
	tail_cut_direction: int, tail_control_point_length_multiplier: float,
	mid_anchor_mode: int
) -> void:
	self.color = color
	self.head_beat = head_beat
	self.head_line_index = head_line_index
	self.head_line_layer = head_line_layer
	self.head_cut_direction = head_cut_direction
	self.head_control_point_length_multiplier = head_control_point_length_multiplier
	self.tail_beat = tail_beat
	self.tail_line_index = tail_line_index
	self.tail_line_layer = tail_line_layer
	self.tail_cut_direction = tail_cut_direction
	self.tail_control_point_length_multiplier = tail_control_point_length_multiplier
	self.mid_anchor_mode = mid_anchor_mode

static func new_v2(arc_dict: Dictionary) -> ArcInfo:
	return ArcInfo.new(
		int(Utils.get_float(arc_dict, "_colorType", 0)),
		Utils.get_float(arc_dict, "_headTime", 0.0),
		int(Utils.get_float(arc_dict, "_headLineIndex", 0)),
		int(Utils.get_float(arc_dict, "_headLineLayer", 0)),
		int(Utils.get_float(arc_dict, "_headCutDirection", 0)),
		Utils.get_float(arc_dict, "_headControlPointLengthMultiplier", 1.0),
		Utils.get_float(arc_dict, "_tailTime", 0.0),
		int(Utils.get_float(arc_dict, "_tailLineIndex", 0)),
		int(Utils.get_float(arc_dict, "_tailLineLayer", 0)),
		int(Utils.get_float(arc_dict, "_tailCutDirection", 0)),
		Utils.get_float(arc_dict, "_tailControlPointLengthMultiplier", 1.0),
		int(Utils.get_float(arc_dict, "_sliderMidAnchorMode", 0))
	)

static func new_v3(arc_dict: Dictionary) -> ArcInfo:
	return ArcInfo.new(
		int(Utils.get_float(arc_dict, "c", 0)),
		Utils.get_float(arc_dict, "b", 0.0),
		int(Utils.get_float(arc_dict, "x", 0)),
		int(Utils.get_float(arc_dict, "y", 0)),
		int(Utils.get_float(arc_dict, "d", 0)),
		Utils.get_float(arc_dict, "mu", 1.0),
		Utils.get_float(arc_dict, "tb", 0.0),
		int(Utils.get_float(arc_dict, "tx", 0)),
		int(Utils.get_float(arc_dict, "ty", 0)),
		int(Utils.get_float(arc_dict, "tc", 0)),
		Utils.get_float(arc_dict, "tmu", 1.0),
		int(Utils.get_float(arc_dict, "m", 0))
	)
