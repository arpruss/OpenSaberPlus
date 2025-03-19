extends Panel
class_name SettingsPanel

signal apply()
@export var beepsaber_game : BeepSaber_Game

@onready var saber_control := $ScrollContainer/VBox/SaberTypeRow/saber as OptionButton
@onready var glare_control := $ScrollContainer/VBox/glare as CheckButton
@onready var saber_tail_control := $ScrollContainer/VBox/saber_tail as CheckButton
@onready var saber_thickness := $ScrollContainer/VBox/SaberThicknessRow/saber_thickness as HSlider
@onready var cut_blocks := $ScrollContainer/VBox/cut_blocks as CheckButton
@onready var d_background := $ScrollContainer/VBox/d_background as CheckButton
@onready var left_saber_col := $ScrollContainer/VBox/SaberColorsRow/left_saber_col as ColorPickerButton
@onready var right_saber_col := $ScrollContainer/VBox/SaberColorsRow/right_saber_col as ColorPickerButton
@onready var show_debug_control := $ScrollContainer/VBox/show_debug as CheckButton
@onready var mixed_reality_control := $ScrollContainer/VBox/mixed_reality as CheckButton
@onready var explain_control := $ScrollContainer/VBox/explain as CheckButton
@onready var not_music_dl_control := $ScrollContainer/VBox/not_music_dl as CheckButton
@onready var swing_scoring_control := $ScrollContainer/VBox/swing_scoring as CheckButton
@onready var show_collisions := $ScrollContainer/VBox/show_collisions as CheckButton
@onready var bombs_enabled_control := $ScrollContainer/VBox/bombs_enabled as CheckButton
@onready var ui_volume_slider := $ScrollContainer/VBox/UI_VolumeRow/ui_volume_slider as HSlider
@onready var disable_map_color_control := $ScrollContainer/VBox/disable_map_color as CheckButton
@onready var left_saber_posx_control := $ScrollContainer/VBox/left_saber_offset/posx as SpinBox
@onready var left_saber_posy_control := $ScrollContainer/VBox/left_saber_offset/posy as SpinBox
@onready var left_saber_posz_control := $ScrollContainer/VBox/left_saber_offset/posz as SpinBox
@onready var left_saber_rotx_control := $ScrollContainer/VBox/left_saber_offset/rotx as SpinBox
@onready var left_saber_roty_control := $ScrollContainer/VBox/left_saber_offset/roty as SpinBox
@onready var left_saber_rotz_control := $ScrollContainer/VBox/left_saber_offset/rotz as SpinBox
@onready var right_saber_posx_control := $ScrollContainer/VBox/right_saber_offset/posx as SpinBox
@onready var right_saber_posy_control := $ScrollContainer/VBox/right_saber_offset/posy as SpinBox
@onready var right_saber_posz_control := $ScrollContainer/VBox/right_saber_offset/posz as SpinBox
@onready var right_saber_rotx_control := $ScrollContainer/VBox/right_saber_offset/rotx as SpinBox
@onready var right_saber_roty_control := $ScrollContainer/VBox/right_saber_offset/roty as SpinBox
@onready var right_saber_rotz_control := $ScrollContainer/VBox/right_saber_offset/rotz as SpinBox
@onready var player_height_offset_control := $ScrollContainer/VBox/player_height_offset/pos as SpinBox
@onready var audio_master_control := $ScrollContainer/VBox/audio/master/master_slider as HSlider
@onready var audio_music_control := $ScrollContainer/VBox/audio/music/music_slider as HSlider
@onready var audio_music_preview_control := $ScrollContainer/VBox/audio/music_preview/music_preview_slider as HSlider
@onready var audio_sfx_control := $ScrollContainer/VBox/audio/sfx/sfx_slider as HSlider
@onready var spectator_view_control := $ScrollContainer/VBox/spectator_view as CheckButton
@onready var spectator_hud_control := $ScrollContainer/VBox/spectator_hud as CheckButton
@onready var calm_control := $ScrollContainer/VBox/calm as CheckButton

var _play_ui_sound_demo := false
var left_saber_col_state := false
var right_saber_col_state := false

func _ready() -> void:
	UI_AudioEngine.attach_children(self)
	
	set_controls_from_settings()
	_play_ui_sound_demo = true
	for picker in [left_saber_col.get_picker(),right_saber_col.get_picker()]:
		picker.sampler_visible = false
		picker.presets_visible = true
		picker.picker_shape = ColorPicker.SHAPE_NONE
		picker.add_recent_preset(Color("ff1a1a"))
		picker.add_recent_preset(Color("1a1aff"))
	
	if OS.get_name() == &"Web":
		# way too heavy for webxr
		$ScrollContainer/VBox/glare.hide()

func set_controls_from_settings() -> void:
	saber_control.clear()
	for s in Settings.SABER_VISUALS:
		saber_control.add_item(s[0])
	
	show_collisions.button_pressed = get_tree().debug_collisions_hint
	show_collisions.visible = OS.is_debug_build()
	
	# set the selections to the loaded values
	await get_tree().process_frame
	saber_thickness.value = Settings.thickness
	cut_blocks.button_pressed = Settings.cube_cuts_falloff
	left_saber_col.color = Settings.color_left
	right_saber_col.color = Settings.color_right
	saber_tail_control.button_pressed = Settings.saber_tail
	glare_control.button_pressed = Settings.glare
	d_background.button_pressed = Settings.events
	saber_control.select(Settings.saber_visual)
	show_debug_control.button_pressed = Settings.show_debug_info
	mixed_reality_control.button_pressed = Settings.mixed_reality
	explain_control.button_pressed = Settings.explain
	not_music_dl_control.button_pressed = Settings.not_music_dl
	swing_scoring_control.button_pressed = Settings.swing_scoring
	bombs_enabled_control.button_pressed = Settings.bombs_enabled
	ui_volume_slider.value = Settings.ui_volume
	disable_map_color_control.button_pressed = Settings.disable_map_color
	left_saber_posx_control.value = Settings.left_saber_offset_pos.x
	left_saber_posy_control.value = Settings.left_saber_offset_pos.y
	left_saber_posz_control.value = Settings.left_saber_offset_pos.z
	left_saber_rotx_control.value = Settings.left_saber_offset_rot.x
	left_saber_roty_control.value = Settings.left_saber_offset_rot.y
	left_saber_rotz_control.value = Settings.left_saber_offset_rot.z
	right_saber_posx_control.value = Settings.right_saber_offset_pos.x
	right_saber_posy_control.value = Settings.right_saber_offset_pos.y
	right_saber_posz_control.value = Settings.right_saber_offset_pos.z
	right_saber_rotx_control.value = Settings.right_saber_offset_rot.x
	right_saber_roty_control.value = Settings.right_saber_offset_rot.y
	right_saber_rotz_control.value = Settings.right_saber_offset_rot.z
	player_height_offset_control.value = Settings.player_height_offset
	audio_master_control.value = Settings.audio_master
	audio_music_control.value = Settings.audio_music
	audio_music_preview_control.value = Settings.audio_music_preview
	audio_sfx_control.value = Settings.audio_sfx
	spectator_view_control.button_pressed = Settings.spectator_view
	spectator_hud_control.button_pressed = Settings.spectator_hud
	calm_control.button_pressed = Settings.calm

func _restore_defaults() -> void:
	Settings.restore_defaults()
	set_controls_from_settings()

#settings down here
func _on_thickness_value_changed(value: float) -> void:
	Settings.thickness = value

func _on_cut_blocks_toggled(button_pressed: bool) -> void:
	Settings.cube_cuts_falloff = button_pressed

func _on_left_saber_color_changed(color: Color) -> void:
	Settings.color_left = color

func _on_right_saber_color_changed(color: Color) -> void:
	Settings.color_right = color

func _on_saber_tail_toggled(button_pressed: bool) -> void:
	Settings.saber_tail = button_pressed

func _on_glare_toggled(button_pressed: bool) -> void:
	Settings.glare = button_pressed

func _on_d_background_toggled(button_pressed: bool) -> void:
	Settings.events = button_pressed

func _on_saber_item_selected(index: int) -> void:
	Settings.saber_visual = index

func _on_show_debug_toggled(button_pressed: bool) -> void:
	Settings.show_debug_info = button_pressed

func _on_mixed_reality_toggled(button_pressed: bool) -> void:
	Settings.mixed_reality = button_pressed
	MixedReality.set_mixed_reality()

func _on_explain_toggled(button_pressed: bool) -> void:
	Settings.explain = button_pressed

func _on_swing_scoring_toggled(button_pressed: bool) -> void:
	Settings.swing_scoring = button_pressed

func _on_bombs_enabled_toggled(button_pressed: bool) -> void:
	Settings.bombs_enabled = button_pressed

func _on_ui_volume_slider_value_changed(value: float) -> void:
	UI_AudioEngine.set_volume(linear_to_db(float(value)/10.0))
	if _play_ui_sound_demo:
		UI_AudioEngine.play_click()
	
	Settings.ui_volume = value

func _on_left_saber_pos_x_changed(value: float) -> void:
	Settings.left_saber_offset_pos.x = value

func _on_left_saber_pos_y_changed(value: float) -> void:
	Settings.left_saber_offset_pos.y = value

func _on_left_saber_pos_z_changed(value: float) -> void:
	Settings.left_saber_offset_pos.z = value

func _on_left_saber_rot_x_changed(value: float) -> void:
	Settings.left_saber_offset_rot.x = value

func _on_left_saber_rot_y_changed(value: float) -> void:
	Settings.left_saber_offset_rot.y = value

func _on_left_saber_rot_z_changed(value: float) -> void:
	Settings.left_saber_offset_rot.z = value

func _on_right_saber_pos_x_changed(value: float) -> void:
	Settings.right_saber_offset_pos.x = value

func _on_right_saber_pos_y_changed(value: float) -> void:
	Settings.right_saber_offset_pos.y = value

func _on_right_saber_pos_z_changed(value: float) -> void:
	Settings.right_saber_offset_pos.z = value

func _on_right_saber_rot_x_changed(value: float) -> void:
	Settings.right_saber_offset_rot.x = value

func _on_right_saber_rot_y_changed(value: float) -> void:
	Settings.right_saber_offset_rot.y = value

func _on_right_saber_rot_z_changed(value: float) -> void:
	Settings.right_saber_offset_rot.z = value

func _on_player_height_offset_changed(value: float) -> void:
	Settings.player_height_offset = value

func _on_disable_map_color_toggled(toggled_on: bool) -> void:
	Settings.disable_map_color = toggled_on

func _force_update_show_coll_shapes(node: Node) -> void:
	# toggle enable to make engine show collision shapes
	if node is CollisionShape3D:
		var col := node as CollisionShape3D
		col.disabled = not col.disabled
		col.disabled = not col.disabled
	elif node is RayCast3D:
		var ray := node as RayCast3D
		ray.enabled = not ray.enabled
		ray.enabled = not ray.enabled
	
	for c in node.get_children():
		_force_update_show_coll_shapes(c)

func _on_show_collisions_toggled(button_pressed: bool) -> void:
	get_tree().debug_collisions_hint = button_pressed
	# must toggle 
	_force_update_show_coll_shapes(get_tree().root)

func _on_apply_pressed() -> void:
	Settings.save()
	apply.emit()
	left_saber_col.get_popup().hide()
	right_saber_col.get_popup().hide()
	left_saber_col_state = false
	right_saber_col_state = false

func _on_master_slider_value_changed(value: float) -> void:
	Settings.audio_master = value

func _on_music_slider_value_changed(value: float) -> void:
	Settings.audio_music = value

func _on_music_preview_slider_value_changed(value: float) -> void:
	Settings.audio_music_preview = value

func _on_sfx_slider_value_changed(value: float) -> void:
	Settings.audio_sfx = value

func _on_spectator_view_toggled(value: bool) -> void:
	Settings.spectator_view = value

func _on_spectator_hud_toggled(value: bool) -> void:
	Settings.spectator_hud = value


func _on_recenter_button_up() -> void:
	var recenter_button : Button = $ScrollContainer/VBox/recenter
	recenter_button.disabled = true
	recenter_button.text = "3.."
	await get_tree().create_timer(1).timeout
	recenter_button.text = "2.."
	await get_tree().create_timer(1).timeout
	recenter_button.text = "1.."
	await get_tree().create_timer(1).timeout
	recenter_button.text = "Recenter"
	recenter_button.disabled = false
	beepsaber_game.recenter()

func _on_left_saber_col_pressed() -> void:
	if left_saber_col_state:
		left_saber_col.get_popup().hide()
	left_saber_col_state = not left_saber_col_state

func _on_right_saber_col_pressed() -> void:
	if right_saber_col_state:
		right_saber_col.get_popup().hide()
	right_saber_col_state = not right_saber_col_state

func _on_not_music_dl_toggled(button_pressed: bool) -> void:
	Settings.not_music_dl = button_pressed

func _on_calm_toggled(button_pressed: bool) -> void:
	Settings.calm = button_pressed
