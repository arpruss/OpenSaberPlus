extends RefCounted
class_name ChainInfo

var color: int
var head_beat: float
var head_line_index: int
var head_line_layer: int
var head_cut_direction: int
var tail_beat: float
var tail_line_index: int
var tail_line_layer: int
var slice_count: int
var squish_factor: float

@warning_ignore("shadowed_variable")
func _init(
	color: int, head_beat: float, head_line_index: int, head_line_layer: int,
	head_cut_direction: int, tail_beat: float, tail_line_index: int,
	tail_line_layer: int, slice_count: int, squish_factor: float
) -> void:
	self.color = color
	self.head_beat = head_beat
	self.head_line_index = head_line_index
	self.head_line_layer = head_line_layer
	self.head_cut_direction = head_cut_direction
	self.tail_beat = tail_beat
	self.tail_line_index = tail_line_index
	self.tail_line_layer = tail_line_layer
	self.slice_count = slice_count
	self.squish_factor = squish_factor

static func new_v3(chain_dict: Dictionary) -> ChainInfo:
	return ChainInfo.new(
		int(Utils.get_float(chain_dict, "c", 0)),
		Utils.get_float(chain_dict, "b", 0.0),
		int(Utils.get_float(chain_dict, "x", 0)),
		int(Utils.get_float(chain_dict, "y", 0)),
		int(Utils.get_float(chain_dict, "d", 0)),
		Utils.get_float(chain_dict, "tb", 0.0),
		int(Utils.get_float(chain_dict, "tx", 0)),
		int(Utils.get_float(chain_dict, "ty", 0)),
		int(Utils.get_float(chain_dict, "sc", 0)),
		Utils.get_float(chain_dict, "s", 1.0)
	)
