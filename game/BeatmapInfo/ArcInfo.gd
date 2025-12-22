extends RefCounted
class_name ArcInfo

const MID_ANCHOR_MODE_STRAIGHT := 0
const MID_ANCHOR_MODE_CLOCKWISE := 1
const MID_ANCHOR_MODE_COUNTERCLOCKWISE := 2

var color: int
var head_beat: float
var head_line_index: float
var head_line_layer: float
var head_cut_angle: float
var head_control_point_length_multiplier: float
var tail_beat: float
var tail_line_index: float
var tail_line_layer: float
var tail_cut_angle: float
var tail_control_point_length_multiplier: float
var mid_anchor_mode: int
var head_rotation: float
var tail_rotation: float

@warning_ignore("shadowed_variable")
func _init(
	color: int, head_beat: float, head_line_index: float, head_line_layer: float,
	head_cut_angle: float, head_control_point_length_multiplier: float,
	tail_beat: float, tail_line_index: float, tail_line_layer: float,
	tail_cut_angle: float, tail_control_point_length_multiplier: float,
	mid_anchor_mode: int, head_rotation_degrees: float, tail_rotation_degrees: float
) -> void:
	self.color = color
	self.head_beat = head_beat
	self.head_line_index = Utils.precise_measurement(head_line_index)
	self.head_line_layer = head_line_layer
	self.head_cut_angle = head_cut_angle
	self.head_control_point_length_multiplier = head_control_point_length_multiplier
	self.tail_beat = tail_beat
	self.tail_line_index = tail_line_index
	self.tail_line_layer = tail_line_layer
	self.tail_cut_angle = tail_cut_angle
	self.tail_control_point_length_multiplier = tail_control_point_length_multiplier
	self.mid_anchor_mode = mid_anchor_mode
	self.head_rotation = head_rotation_degrees * (PI/180.)
	self.tail_rotation = tail_rotation_degrees * (PI/180.)
	if abs(Settings.gradual_rotation) > 1e-5:
		self.head_rotation += Settings.gradual_rotation * head_beat
		self.tail_rotation += Settings.gradual_rotation * tail_beat

static func new_v2(arc_dict: Dictionary) -> ArcInfo:
	return ArcInfo.new(
		int(Utils.get_float(arc_dict, "_colorType", 0)),
		Utils.get_float(arc_dict, "_headTime", 0.0),
		Utils.precise_measurement(Utils.get_float(arc_dict, "_headLineIndex", 0)),
		Utils.precise_measurement(Utils.get_float(arc_dict, "_headLineLayer", 0)),
		Utils.precise_angle_rad(Utils.get_float(arc_dict, "_headCutDirection", 0.), 0.),
		Utils.get_float(arc_dict, "_headControlPointLengthMultiplier", 1.0),
		Utils.get_float(arc_dict, "_tailTime", 0.0),
		Utils.precise_measurement(Utils.get_float(arc_dict, "_tailLineIndex", 0)),
		Utils.precise_measurement(Utils.get_float(arc_dict, "_tailLineLayer", 0)),
		Utils.precise_angle_rad(Utils.get_float(arc_dict, "_tailCutDirection", 0), 0),
		Utils.get_float(arc_dict, "_tailControlPointLengthMultiplier", 1.0),
		int(Utils.get_float(arc_dict, "_sliderMidAnchorMode", 0)),
		Utils.get_float(arc_dict, "hr", 0),
		Utils.get_float(arc_dict, "tr", 0)
	)

static func new_v3(arc_dict: Dictionary) -> ArcInfo:
	return ArcInfo.new(
		int(Utils.get_float(arc_dict, "c", 0)),
		Utils.get_float(arc_dict, "b", 0.0),
		Utils.precise_measurement(Utils.get_float(arc_dict, "x", 0)),
		Utils.precise_measurement(Utils.get_float(arc_dict, "y", 0)),
		Utils.precise_angle_rad(Utils.get_float(arc_dict, "d", 0), Utils.get_float(arc_dict, "head_angle_offset", 0)),
		Utils.get_float(arc_dict, "mu", 1.0),
		Utils.get_float(arc_dict, "tb", 0.0),
		Utils.precise_measurement(Utils.get_float(arc_dict, "tx", 0)),
		Utils.precise_measurement(Utils.get_float(arc_dict, "ty", 0)),
		Utils.precise_angle_rad(Utils.get_float(arc_dict, "tc", 0), Utils.get_float(arc_dict, "tail_angle_offset", 0)),
		Utils.get_float(arc_dict, "tmu", 1.0),
		int(Utils.get_float(arc_dict, "m", 0)),
		Utils.get_float(arc_dict, "hr", 0),
		Utils.get_float(arc_dict, "tr", 0)
	)
