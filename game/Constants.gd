extends Node

const LANE_ZERO_X := -0.9
const LAYER_ZERO_Y := 0.8
const BEAT_DISTANCE := 4.0
const LANE_DISTANCE := 0.6
const MISS_Z := 2.5
var CUBE_ROTATIONS := PackedFloat64Array([PI, 0.0, -TAU*0.25, TAU*0.25, -TAU*0.375, TAU*0.375, -TAU*0.125, TAU*0.125, 0.0])
var ROTATION_UNIT_VECTORS := PackedVector2Array([
	Vector2(0, 1), Vector2(0, -1), Vector2(-1, 0), Vector2(1, 0),
	Vector2(-0.70710678, 0.70710678), Vector2(0.70710678, 0.70710678),
	Vector2(-0.70710678, -0.70710678), Vector2(0.70710678, -0.70710678), Vector2(0,1)
])
var _global_path := ProjectSettings.globalize_path("user://")
var APPDATA_PATH := ( "user://OpenSaber/" if (OS.get_name() != "Android" or 
	  not _global_path.begins_with("/data/data/")) else "/sdcard/Android/data"+_global_path.substr(10) )
var CONFIG_ROOT_PATH := "user://" if APPDATA_PATH.begins_with("user://") else APPDATA_PATH
const OPENSABER_BEAT_ACCURACY_SCORE := 50.
const OPENSABER_ANGLE_ACCURACY_SCORE := 50.
const OPENSABER_DISTANCE_ACCURACY_SCORE := 50.
const OPENSABER_GOOD_SCORE := 88.
const OPENSABER_CHAIN_LINK_SCORE := 20
const SWING_CHAIN_HEAD_SCORE = 90
const SWING_ACCURACY_SCORE = 20.
const SWING_PRESWING_SCORE = 90.
const SWING_FOLLOWTHROUGH_SCORE = 40.
const TARGET_PRESWING_ANGLE = 100.
const TARGET_FOLLOWTHROUGH_ANGLE = 60.
const SWING_GOOD_SCORE := 95.
const SWING_CHAIN_LINK_SCORE := 25
const HEALTH_MISS := -12.5
const HEALTH_HIT  := 5.
const HEALTH_OBSTACLE_PER_BEAT := -5.
const HEALTH_MAX := 100.
const HEALTH_START := 50.
