extends RefCounted
class_name MapInfo

var version: String
var song_name: String
var song_sub_name: String
var song_author_name: String
var level_author_name: String
var beats_per_minute: float
#var shuffle: float
#var shuffle_period: float
var preview_start_time: float
var preview_duration: float
var song_filename: String
var cover_image_filename: String
var environment_name: String
var song_time_offset: float
var custom_data: Dictionary
var last_beat: float
var have_song: bool

var filepath: String
var difficulty_beatmaps: Array[DifficultyInfo]

@warning_ignore("shadowed_variable")
func _init(
	version: String, song_name: String, song_sub_name: String,
	song_author_name: String, level_author_name: String, beats_per_minute: float,
	preview_start_time: float, preview_duration: float, song_filename: String,
	cover_image_filename: String, environment_name: String,
	song_time_offset: float, custom_data: Dictionary, filepath: String,
	difficulty_beatmaps: Array[DifficultyInfo]
) -> void:
	self.version = version
	self.song_name = song_name
	self.song_sub_name = song_sub_name
	self.song_author_name = song_author_name
	self.level_author_name = level_author_name
	self.beats_per_minute = beats_per_minute
	# shuffle and shuffle period maybe in the future?
	self.preview_start_time = preview_start_time
	self.preview_duration = preview_duration
	self.song_filename = song_filename
	self.cover_image_filename = cover_image_filename
	self.environment_name = environment_name
	self.song_time_offset = song_time_offset
	self.custom_data = custom_data
	self.filepath = filepath
	self.difficulty_beatmaps = difficulty_beatmaps
	self.have_song = Utils.file_exists(filepath, song_filename)

func is_empty() -> bool:
	return (
		song_name.is_empty()
		and song_author_name.is_empty()
		and song_sub_name.is_empty()
		and level_author_name.is_empty()
	)

func get_key() -> String:
	return "[%s,%s,%s,%s]" % [
		song_author_name,
		song_name,
		song_sub_name,
		level_author_name
	]

static func new_v2(info_dict: Dictionary, load_path: String) -> MapInfo:
	# mix all the difficulty sets into a single one
	var diffs: Array[DifficultyInfo] = []
	var difficulty_beatmap_sets := Utils.get_array(info_dict, "_difficultyBeatmapSets", [])
	if (difficulty_beatmap_sets.is_empty()):
		vr.log_warning("No _difficultyBeatmapSets in info.dat")
	
	for difficulty_set: Variant in difficulty_beatmap_sets:
		if difficulty_set is Dictionary:
			var beatmaps := Utils.get_array(difficulty_set as Dictionary, "_difficultyBeatmaps", [])
			for i: Variant in beatmaps:
				if i is Dictionary:
					diffs.append(DifficultyInfo.load_v2(i as Dictionary))
	return MapInfo.new(
		Utils.get_str(info_dict, "_version", "2.0.0"),
		Utils.get_str(info_dict, "_songName", ""),
		Utils.get_str(info_dict, "_songSubName", ""),
		Utils.get_str(info_dict, "_songAuthorName", ""),
		Utils.get_str(info_dict, "_levelAuthorName", ""),
		Utils.get_float(info_dict, "_beatsPerMinute", 60.0),
		Utils.get_float(info_dict, "_previewStartTime", 0.0),
		Utils.get_float(info_dict, "_previewDuration", 0.0),
		Utils.get_str(info_dict, "_songFilename", ""),
		Utils.get_str(info_dict, "_coverImageFilename", ""),
		Utils.get_str(info_dict, "_environmentName", ""),
		Utils.get_float(info_dict, "_songTimeOffset", 0.0),
		Utils.get_dict(info_dict, "_customData", {}),
		load_path,
		diffs
	)

static func new_v4(info_dict: Dictionary, load_path: String) -> MapInfo:
	var diffs := {}
	var difficulty_beatmaps := Utils.get_array(info_dict, "difficultyBeatmaps", [])
	if (difficulty_beatmaps.is_empty()):
		vr.log_warning("No difficultyBeatmaps in info.dat")
	var beatmap_author: String

	for difficulty_beatmap: Variant in difficulty_beatmaps:
		if difficulty_beatmap is Dictionary:
			# TODO: each beatmap can have different authors / lighters - for now, just take the first one
			if not beatmap_author:
				var beatmap_authors: Dictionary = Utils.get_dict(difficulty_beatmap, "beatmapAuthors", { "mappers": [""] })
				beatmap_author = beatmap_authors["mappers"][0]

			var difficulty_set_name : String = difficulty_beatmap["characteristic"]
			diffs[difficulty_set_name] = {
				difficulty_beatmap["difficulty"]: DifficultyInfo.load_v4(difficulty_beatmap)
			}

	var song: Dictionary = Utils.get_dict(info_dict, "song", {})
	var audio: Dictionary = Utils.get_dict(info_dict, "audio", {})
	var environment_names: Array = Utils.get_array(info_dict, "environmentNames", [""])

	# TODO: colorSchemes
	# TODO: audio/songDuration
	# TODO: audio/audioDataFilename
	# TODO: audio/lufs
	# TODO: songPreviewFilename
	return MapInfo.new(
		Utils.get_str(info_dict, "version", "4.0.0"),
		Utils.get_str(song, "title", ""),
		Utils.get_str(song, "subTitle", ""),
		Utils.get_str(song, "author", ""),
		beatmap_author,
		Utils.get_float(audio, "bpm", 60.0),
		Utils.get_float(audio, "previewStartTime", 0.0),
		Utils.get_float(audio, "previewDuration", 0.0),
		Utils.get_str(audio, "songFilename", ""),
		Utils.get_str(info_dict, "coverImageFilename", ""),
		environment_names[0],	# TODO: each beatmap can have different environments - for now, just take the first one
		Utils.get_float(info_dict, "_songTimeOffset", 0.0),	# TODO: does this exist in v4?
		Utils.get_dict(info_dict, "_customData", {}),	# TODO: does this exist in v4?
		load_path,
		diffs
	)
