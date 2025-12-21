extends Node

func get_str(dict: Dictionary, key: String, default: String, platform_defaults: Dictionary = {}) -> String:
	if dict.has(key) and dict[key] is String:
		@warning_ignore("unsafe_cast")
		return dict[key] as String
	if OS.get_name() in platform_defaults.keys():
		return platform_defaults[OS.get_name()]
	return default

func get_bool(dict: Dictionary, key: String, default: bool, platform_defaults: Dictionary = {}) -> bool:
	if dict.has(key) and dict[key] is bool:
		@warning_ignore("unsafe_cast")
		return dict[key] as bool
	if OS.get_name() in platform_defaults.keys():
		return platform_defaults[OS.get_name()]
	return default

func get_float(dict: Dictionary, key: String, default: float, platform_defaults: Dictionary = {}) -> float:
	if dict.has(key) and dict[key] is float:
		@warning_ignore("unsafe_cast")
		return dict[key] as float
	if OS.get_name() in platform_defaults.keys():
		return platform_defaults[OS.get_name()]
	return default

func get_array(dict: Dictionary, key: String, default: Array, platform_defaults: Dictionary = {}) -> Array:
	if dict.has(key) and dict[key] is Array:
		@warning_ignore("unsafe_cast")
		return dict[key] as Array
	if OS.get_name() in platform_defaults.keys():
		return platform_defaults[OS.get_name()]
	return default

func get_dict(dict: Dictionary, key: String, default: Dictionary, platform_defaults: Dictionary = {}) -> Dictionary:
	if dict.has(key) and dict[key] is Dictionary:
		@warning_ignore("unsafe_cast")
		return dict[key] as Dictionary
	if OS.get_name() in platform_defaults.keys():
		return platform_defaults[OS.get_name()]
	return default
	
func ends_in(name: String, exts: Array) -> bool:
	for ext in exts:
		if name.to_lower().ends_with(ext.to_lower()):
			return true
	return false

func unzip(zip_file: String, destination: String) -> void:
	var zreader := ZIPReader.new()
	if zreader.open(zip_file) != OK:
		vr.log_warning("unable to open zip file %s" % zip_file)
		return
	for file in zreader.get_files():
		if not Settings.not_music_dl or not ends_in(file, [".ogg", ".egg", ".mp3"]):
			var buffer := zreader.read_file(file)
			if buffer:
				var filea := FileAccess.open(destination+"/"+file, FileAccess.WRITE)
				filea.store_buffer(buffer)
				filea.close()
	@warning_ignore("return_value_discarded")
	zreader.close()
	
func file_exists(base: String, file: String) -> bool:
	if DirAccess.dir_exists_absolute(base):
		var path : String
		if base.ends_with("/"):
			path = base + file
		else:
			path = base + "/" + file
		return FileAccess.file_exists(path)
	elif base.to_lower().ends_with(".zip") and FileAccess.file_exists(base):
		var zreader := ZIPReader.new()
		if zreader.open(base) == OK:
			var exists := zreader.file_exists(file)
			zreader.close()
			return exists
	return false
	
		
func read_binary_file(base: String, file: String) -> PackedByteArray:
	if DirAccess.dir_exists_absolute(base):
		var path : String
		if base.ends_with("/"):
			path = base + file
		else:
			path = base + "/" + file
		if FileAccess.file_exists(path):
			return FileAccess.get_file_as_bytes(path)
	else:
			var zreader := ZIPReader.new()
			if zreader.open(base) == OK:
				var data := zreader.read_file(file)
				zreader.close()
				return data
	return PackedByteArray()
	
func binary_to_json(data: PackedByteArray) -> Dictionary:
	if len(data) == 0:
		return {}
	else:
		var dict := JSON.parse_string(data.get_string_from_ascii()) as Dictionary
		return dict
	
var thread_finished : Array[Thread] = []
var fake_thread_finished = {}

func custom_thread_wait_to_finish(thread : Thread):
	if thread in thread_finished:
		var r = thread.wait_to_finish()
		thread_finished.remove_at(thread_finished.find(thread))
		return r
	elif thread in fake_thread_finished:
		var r = fake_thread_finished[thread]
		fake_thread_finished.erase(thread)
		return r
	return null

func custom_thread_call(thread : Thread, function : Callable, params := []):
	if OS.get_name() == &"Web":
		fake_thread_finished[thread] = function.callv(params)
		return 0
	else:
		thread_finished.append(thread)
		return thread.start(function.bindv(params))

func precise_measurement(x : int) -> float:
	if x < 1000:
		return x
	else:
		return (x-1000.)/1000.

func precise_angle_rad(direction: int, offset: int) -> float:
	var angle : float
	if direction < 1000:
		angle = Constants.CUBE_ROTATIONS[direction]
	else:
		angle = direction - 1000
	return angle + offset * (PI/180.)

func rotation_unit_vector(angle: float) -> Vector2:
	return Vector2(sin(angle), -cos(angle))
