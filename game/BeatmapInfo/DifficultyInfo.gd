extends RefCounted
class_name DifficultyInfo

var difficulty: String
var difficulty_rank: int
var beatmap_filename: String
var lightshow_filename: String
var note_jump_movement_speed: float
var note_jump_start_beat_offset: float
var custom_data: Dictionary
# not officially part of the spec, but used by mods a lot
var custom_name: String

func _init(
	difficulty: String, difficulty_rank: int, beatmap_filename: String,
	note_jump_movement_speed: float, note_jump_start_beat_offset: float,
	custom_data: Dictionary, custom_name: String, lightshow_filename = ""
) -> void:
	self.difficulty = difficulty
	self.difficulty_rank = difficulty_rank
	self.beatmap_filename = beatmap_filename
	self.lightshow_filename = lightshow_filename
	self.note_jump_movement_speed = note_jump_movement_speed
	self.note_jump_start_beat_offset = note_jump_start_beat_offset
	self.custom_data = custom_data
	# not officially part of the spec, but used by mods a lot
	self.custom_name = custom_name

static func load_v2(diff_dict: Dictionary) -> DifficultyInfo:
	var diff := Utils.get_str(diff_dict, "_difficulty", "")
	var data := Utils.get_dict(diff_dict, "_customData", {})
	
	var name := ""
	# not officially part of the spec, but used by mods a lot
	if not data.is_empty():
		name = Utils.get_str(data, "_difficultyLabel", "")
	if name.is_empty():
		name = diff
	
	return DifficultyInfo.new(
		diff,
		int(Utils.get_float(diff_dict, "_difficultyRank", 0)),
		Utils.get_str(diff_dict, "_beatmapFilename", ""),
		Utils.get_float(diff_dict, "_noteJumpMovementSpeed", 1.0),
		Utils.get_float(diff_dict, "_noteJumpStartBeatOffset", 0.0),
		data,
		name
	)

static func load_v4(diff_dict: Dictionary) -> DifficultyInfo:
	var diff := Utils.get_str(diff_dict, "difficulty", "")
	var name := Utils.get_str(diff_dict, "difficulty", diff)

	# TODO: each v4 beatmap can have a different environment - environmentNameIdx
	# TODO: each v4 beatmap can have a different color scheme - beatmapColorSchemeIdx
	return DifficultyInfo.new(
		diff,
		{ "Easy": 1, "Normal": 3, "Hard": 5, "Expert": 7, "ExpertPlus": 9 }.get(diff, 1),
		Utils.get_str(diff_dict, "beatmapDataFilename", ""),
		Utils.get_float(diff_dict, "noteJumpMovementSpeed", 1.0),
		Utils.get_float(diff_dict, "noteJumpStartBeatOffset", 0.0),
		{},		# TODO: find out if the v4 spec also allows for custom data
		name,	# TODO: find out if the v4 spec also allows for/has mods using custom difficulty labels
		Utils.get_str(diff_dict, "lightshowDataFilename", "")
	)
