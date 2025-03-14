extends RefCounted
class_name Map

# this would have basically been impossible to figure out without constantly
# referencing the beat saber modding group wiki.
# https://bsmg.wiki/mapping/map-format.html

static var current_info: MapInfo
static var current_difficulty: DifficultyInfo

static var note_stack: Array[ColorNoteInfo]
static var bomb_stack: Array[BombInfo]
static var obstacle_stack: Array[ObstacleInfo]
static var arc_stack: Array[ArcInfo]
static var chain_stack: Array[ChainInfo]
static var event_stack: Array[EventInfo]

static var color_left: Color
static var color_right: Color
static var last_beat := 0.

# some simple multithreading, since larger maps can take a very long time to
# load.  one particulary notable outlier is the beatmap of shrek, which took
# around 48 milliseconds to load before even on a 7800x3d, and now takes around
# 29 milliseconds.  takes just over half as long as before, very worth the
# nightmare code i've written.
#
# long story short, each beatmap-element loading func splits into two threads:
# one for parsing the top half of the array of dicts, and one for parsing the
# bottom half.  these run concurrently, not quite halfing the time, but
# getting pretty close to halfing it.
static var note_thread_0 := Thread.new()
static var note_thread_1 := Thread.new()
static var bomb_thread_0 := Thread.new()
static var bomb_thread_1 := Thread.new()
static var obstacle_thread_0 := Thread.new()
static var obstacle_thread_1 := Thread.new()
static var arc_thread_0 := Thread.new()
static var arc_thread_1 := Thread.new()
static var chain_thread_0 := Thread.new()
static var chain_thread_1 := Thread.new()
static var event_thread_0 := Thread.new()
static var event_thread_1 := Thread.new()

# not officially part of the spec, but used by mods a lot
static func set_colors_from_custom_data() -> void:
	if Settings.disable_map_color:
		Map.color_left = Settings.color_left
		Map.color_right = Settings.color_right
		return
	
	var set_colors := func(data: Dictionary, color_name: String) -> bool:
		var left_name := color_name % "Left"
		var right_name := color_name % "Right"
		if (
			data.has(left_name) and data.has(right_name)
			and data[left_name] is Dictionary and data[right_name] is Dictionary
		):
			@warning_ignore("unsafe_cast")
			var left := data[left_name] as Dictionary
			@warning_ignore("unsafe_cast")
			var right := data[right_name] as Dictionary
			Map.color_left = Color(
				Utils.get_float(left, "r", Settings.color_left.r),
				Utils.get_float(left, "g", Settings.color_left.g),
				Utils.get_float(left, "b", Settings.color_left.b)
			)
			Map.color_right = Color(
				Utils.get_float(right, "r", Settings.color_right.r),
				Utils.get_float(right, "g", Settings.color_right.g),
				Utils.get_float(right, "b", Settings.color_right.b)
			)
			return true
		return false
	var info_data := current_info.custom_data
	var diff_data := current_difficulty.custom_data
	var custom_colors_found := false
	if set_colors.call(info_data, "_envColor%sBoost"): custom_colors_found = true
	if set_colors.call(diff_data, "_envColor%sBoost"): custom_colors_found = true
	if set_colors.call(info_data, "_envColor%s"): custom_colors_found = true
	if set_colors.call(diff_data, "_envColor%s"): custom_colors_found = true
	if set_colors.call(info_data, "_color%s"): custom_colors_found = true
	if set_colors.call(diff_data, "_color%s"): custom_colors_found = true
	if not custom_colors_found:
		Map.color_left = Settings.color_left
		Map.color_right = Settings.color_right

static func load_map_info(load_path: String) -> MapInfo:
	var info_dict := {}
	if FileAccess.file_exists(load_path + "Info.dat"):
		info_dict = vr.load_json_file(load_path + "Info.dat")
	elif FileAccess.file_exists(load_path + "info.dat"):
		info_dict = vr.load_json_file(load_path + "info.dat")
	if (info_dict.is_empty()):
		vr.log_error("Invalid info.dat found in " + load_path)
		return null
	
	if info_dict.has("_version"):
		return MapInfo.new_v2(info_dict, load_path)
	elif info_dict.has("version"):
		vr.log_warning("%s is an unsupported beatmap version: %s" % [load_path, info_dict["version"]])
		return null
	else:
		vr.log_warning("%s is an unknown beatmap version" % load_path)
		return null

# speed for the speed gods.  please forgive me for this.
# - steve hocktail
static func load_note_stack_v2(note_data: Array) -> void:
	var load_range := func(start: int, end: int) -> Array[Array]:
		var note_array: Array[ColorNoteInfo] = []
		var bomb_array: Array[BombInfo] = []
		var i := start
		while i < end:
			if not note_data[i] is Dictionary: continue
			@warning_ignore("unsafe_cast")
			var note_dict := note_data[i] as Dictionary
			var note_type := int(Utils.get_float(note_dict, "_type", -1.0))
			if note_type == 3 and Settings.bombs_enabled:
				bomb_array.append(BombInfo.new_v2(note_dict))
			elif note_type == 0 or note_type == 1:
				note_array.append(ColorNoteInfo.new_v2(note_dict))
			i += 1
		return [note_array, bomb_array]
	var midpoint := note_data.size() >> 1
	#note_thread_1.start(load_range.bind(0, midpoint))
	Utils.custom_thread_call(note_thread_1, load_range, [0, midpoint])
	var total_second_half : Array[Array] = load_range.bind(midpoint, note_data.size()).call()
	#var total_first_half : Array[Array] = note_thread_1.wait_to_finish()
	var total_first_half : Array[Array] = Utils.custom_thread_wait_to_finish(note_thread_1)
	note_stack = total_first_half[0] + total_second_half[0]
	bomb_stack = total_first_half[1] + total_second_half[1]
	note_stack.reverse()
	bomb_stack.reverse()

static func load_obstacle_stack_v2(obstacle_data: Array) -> void:
	var last_index := obstacle_data.size() - 1
	var load_range := func(start: int, end: int) -> void:
		var i := start
		while i < end:
			if obstacle_data[i] is Dictionary:
				@warning_ignore("unsafe_cast")
				obstacle_stack[last_index - i] = ObstacleInfo.new_v2(obstacle_data[i] as Dictionary)
			i += 1
	var midpoint := obstacle_data.size() >> 1
	obstacle_stack.resize(obstacle_data.size())
	#obstacle_thread_1.start(load_range.bind(0, midpoint))
	Utils.custom_thread_call(obstacle_thread_1, load_range, [0, midpoint])
	load_range.bind(midpoint, obstacle_data.size()).call()
	#obstacle_thread_1.wait_to_finish()
	Utils.custom_thread_wait_to_finish(obstacle_thread_1)

static func load_arc_stack_v2(arc_data: Array) -> void:
	var last_index := arc_data.size() - 1
	var load_range := func(start: int, end: int) -> void:
		var i := start
		while i < end:
			if arc_data[i] is Dictionary:
				@warning_ignore("unsafe_cast")
				arc_stack[last_index - i] = ArcInfo.new_v2(arc_data[i] as Dictionary)
			i += 1
	var midpoint := arc_data.size() >> 1
	arc_stack.resize(arc_data.size())
	#arc_thread_1.start(load_range.bind(0, midpoint))
	Utils.custom_thread_call(arc_thread_1, load_range, [0, midpoint])
	load_range.bind(midpoint, arc_data.size()).call()
	#arc_thread_1.wait_to_finish()
	Utils.custom_thread_wait_to_finish(arc_thread_1)
	

static func load_event_stack_v2(event_data: Array) -> void:
	var last_index := event_data.size() - 1
	var load_range := func(start: int, end: int) -> void:
		var i := start
		while i < end:
			if event_data[i] is Dictionary:
				@warning_ignore("unsafe_cast")
				event_stack[last_index - i] = EventInfo.new_v2(event_data[i] as Dictionary)
			i += 1
	var midpoint := event_data.size() >> 1
	event_stack.resize(event_data.size())
	#event_thread_1.start(load_range.bind(0, midpoint))
	Utils.custom_thread_call(event_thread_1, load_range, [0, midpoint])
	load_range.bind(midpoint, event_data.size()).call()
	#event_thread_1.wait_to_finish()
	Utils.custom_thread_wait_to_finish(event_thread_1)

static func load_note_stack_v3(note_data: Array) -> void:
	var last_index := note_data.size() - 1
	var load_range := func(start: int, end: int) -> void:
		var i := start
		while i < end:
			if note_data[i] is Dictionary:
				@warning_ignore("unsafe_cast")
				note_stack[last_index - i] = ColorNoteInfo.new_v3(note_data[i] as Dictionary)
			i += 1
	var midpoint := note_data.size() >> 1
	note_stack.resize(note_data.size())
	#note_thread_1.start(load_range.bind(0, midpoint))
	Utils.custom_thread_call(note_thread_1, load_range, [0, midpoint])
	load_range.bind(midpoint, note_data.size()).call()
	#note_thread_1.wait_to_finish()
	Utils.custom_thread_wait_to_finish(note_thread_1)

static func load_bomb_stack_v3(bomb_data: Array) -> void:
	if not Settings.bombs_enabled:
		bomb_stack.clear()
		return
	var last_index := bomb_data.size() - 1
	var load_range := func(start: int, end: int) -> void:
		var i := start
		while i < end:
			if bomb_data[i] is Dictionary:
				@warning_ignore("unsafe_cast")
				bomb_stack[last_index - i] = BombInfo.new_v3(bomb_data[i] as Dictionary)
			i += 1
	var midpoint := bomb_data.size() >> 1
	bomb_stack.resize(bomb_data.size())
	#bomb_thread_1.start(load_range.bind(0, midpoint))
	Utils.custom_thread_call(bomb_thread_1, load_range, [0, midpoint])
	load_range.bind(midpoint, bomb_data.size()).call()
	#bomb_thread_1.wait_to_finish()
	Utils.custom_thread_wait_to_finish(bomb_thread_1)

static func load_obstacle_stack_v3(obstacle_data: Array) -> void:
	var last_index := obstacle_data.size() - 1
	var load_range := func(start: int, end: int) -> void:
		var i := start
		while i < end:
			if obstacle_data[i] is Dictionary:
				@warning_ignore("unsafe_cast")
				obstacle_stack[last_index - i] = ObstacleInfo.new_v3(obstacle_data[i] as Dictionary)
			i += 1
	var midpoint := obstacle_data.size() >> 1
	obstacle_stack.resize(obstacle_data.size())
	#obstacle_thread_1.start(load_range.bind(0, midpoint))
	Utils.custom_thread_call(obstacle_thread_1, load_range, [0, midpoint])
	load_range.bind(midpoint, obstacle_data.size()).call()
	#obstacle_thread_1.wait_to_finish()
	Utils.custom_thread_wait_to_finish(obstacle_thread_1)

static func load_arc_stack_v3(arc_data: Array) -> void:
	var last_index := arc_data.size() - 1
	var load_range := func(start: int, end: int) -> void:
		var i := start
		while i < end:
			if arc_data[i] is Dictionary:
				@warning_ignore("unsafe_cast")
				arc_stack[last_index - i] = ArcInfo.new_v3(arc_data[i] as Dictionary)
			i += 1
	var midpoint := arc_data.size() >> 1
	arc_stack.resize(arc_data.size())
	#arc_thread_1.start(load_range.bind(0, midpoint))
	Utils.custom_thread_call(arc_thread_1, load_range, [0, midpoint])
	load_range.bind(midpoint, arc_data.size()).call()
	#arc_thread_1.wait_to_finish()
	Utils.custom_thread_wait_to_finish(arc_thread_1)

static func load_chain_stack_v3(chain_data: Array) -> void:
	var last_index := chain_data.size() - 1
	var load_range := func(start: int, end: int) -> void:
		var i := start
		while i < end:
			if chain_data[i] is Dictionary:
				@warning_ignore("unsafe_cast")
				chain_stack[last_index - i] = ChainInfo.new_v3(chain_data[i] as Dictionary)
			i += 1
	var midpoint := chain_data.size() >> 1
	chain_stack.resize(chain_data.size())
	#chain_thread_1.start(load_range.bind(0, midpoint))
	Utils.custom_thread_call(chain_thread_1, load_range, [0, midpoint])
	load_range.bind(midpoint, chain_data.size()).call()
	#chain_thread_1.wait_to_finish()
	Utils.custom_thread_wait_to_finish(chain_thread_1)

static func load_event_stack_v3(event_data: Array) -> void:
	var last_index := event_data.size() - 1
	var load_range := func(start: int, end: int) -> void:
		var i := start
		while i < end:
			if event_data[i] is Dictionary:
				@warning_ignore("unsafe_cast")
				event_stack[last_index - i] = EventInfo.new_v3(event_data[i] as Dictionary)
			i += 1
	var midpoint := event_data.size() >> 1
	event_stack.resize(event_data.size())
	#event_thread_1.start(load_range.bind(0, midpoint))
	Utils.custom_thread_call(event_thread_1, load_range, [0, midpoint])
	load_range.bind(midpoint, event_data.size()).call()
	#event_thread_1.wait_to_finish()
	Utils.custom_thread_wait_to_finish(event_thread_1)
	
static func get_last_beat() -> void:
	current_info.last_beat = 0.
	for note_info in note_stack:
		if note_info.beat + 0.5 > current_info.last_beat:
			current_info.last_beat = note_info.beat + 0.5
	for obstacle in obstacle_stack:
		var beat := obstacle.beat + obstacle.duration
		if beat > current_info.last_beat:
			current_info.last_beat = beat
	for bomb in bomb_stack:
		if bomb.beat > current_info.last_beat:
			current_info.last_beat = bomb.beat

static func load_beatmap(info: MapInfo, difficulty: DifficultyInfo, map_data: Dictionary) -> bool:
	# Ensures the map_data dict has a version (some maps include the version only on info but not in the data)
	if !map_data.has("_version") and !map_data.has("version"):
		if info.version.begins_with("2.") or info.version.begins_with("1."):
			map_data["_version"] = info.version
		else:
			map_data["version"] = info.version
	
	if map_data.has("_version"):
		#note_thread_0.start(load_note_stack_v2.bind(Utils.get_array(map_data, "_notes", [])))
		Utils.custom_thread_call(note_thread_0, load_note_stack_v2, [Utils.get_array(map_data, "_notes", [])])
		#obstacle_thread_0.start(load_obstacle_stack_v2.bind(Utils.get_array(map_data, "_obstacles", [])))
		Utils.custom_thread_call(obstacle_thread_0, load_obstacle_stack_v2, [Utils.get_array(map_data, "_obstacles", [])])
		#event_thread_0.start(load_event_stack_v2.bind(Utils.get_array(map_data, "_events", [])))
		Utils.custom_thread_call(event_thread_0, load_event_stack_v2, [Utils.get_array(map_data, "_events", [])])
		#arc_thread_0.start(load_arc_stack_v2.bind(Utils.get_array(map_data, "_sliders", [])))
		Utils.custom_thread_call(arc_thread_0, load_arc_stack_v2, [Utils.get_array(map_data, "_sliders", [])])
		chain_stack.clear()
		current_info = info
		current_difficulty = difficulty
		Map.set_colors_from_custom_data()
		#note_thread_0.wait_to_finish()
		Utils.custom_thread_wait_to_finish(note_thread_0)
		#obstacle_thread_0.wait_to_finish()
		Utils.custom_thread_wait_to_finish(obstacle_thread_0)
		#event_thread_0.wait_to_finish()
		Utils.custom_thread_wait_to_finish(event_thread_0)
		#arc_thread_0.wait_to_finish()
		Utils.custom_thread_wait_to_finish(arc_thread_0)
		get_last_beat()
		return true
	elif map_data.has("version"):
		var version := Utils.get_str(map_data, "version", "")
		if version.begins_with("3."):
			#note_thread_0.start(load_note_stack_v3.bind(Utils.get_array(map_data, "colorNotes", [])))
			Utils.custom_thread_call(note_thread_0, load_note_stack_v3, [Utils.get_array(map_data, "colorNotes", [])])
			#bomb_thread_0.start(load_bomb_stack_v3.bind(Utils.get_array(map_data, "bombNotes", [])))
			Utils.custom_thread_call(bomb_thread_0, load_bomb_stack_v3, [Utils.get_array(map_data, "bombNotes", [])])
			#obstacle_thread_0.start(load_obstacle_stack_v3.bind(Utils.get_array(map_data, "obstacles", [])))
			Utils.custom_thread_call(obstacle_thread_0, load_obstacle_stack_v3, [Utils.get_array(map_data, "obstacles", [])])
			#arc_thread_0.start(load_arc_stack_v3.bind(Utils.get_array(map_data, "sliders", [])))
			Utils.custom_thread_call(arc_thread_0, load_arc_stack_v3, [Utils.get_array(map_data, "sliders", [])])
			#chain_thread_0.start(load_chain_stack_v3.bind(Utils.get_array(map_data, "burstSliders", [])))
			Utils.custom_thread_call(chain_thread_0, load_chain_stack_v3, [Utils.get_array(map_data, "burstSliders", [])])
			#event_thread_0.start(load_event_stack_v3.bind(Utils.get_array(map_data, "basicBeatmapEvents", [])))
			Utils.custom_thread_call(event_thread_0, load_event_stack_v3, [Utils.get_array(map_data, "basicBeatmapEvents", [])])
			current_info = info
			current_difficulty = difficulty
			Map.set_colors_from_custom_data()
			#note_thread_0.wait_to_finish()
			Utils.custom_thread_wait_to_finish(note_thread_0)
			#bomb_thread_0.wait_to_finish()
			Utils.custom_thread_wait_to_finish(bomb_thread_0)
			#obstacle_thread_0.wait_to_finish()
			Utils.custom_thread_wait_to_finish(obstacle_thread_0)
			#arc_thread_0.wait_to_finish()
			Utils.custom_thread_wait_to_finish(arc_thread_0)
			#chain_thread_0.wait_to_finish()
			Utils.custom_thread_wait_to_finish(chain_thread_0)
			#event_thread_0.wait_to_finish()
			Utils.custom_thread_wait_to_finish(event_thread_0)
			get_last_beat()
			return true
	vr.log_warning("selected map is an unsupported version")
	return false
