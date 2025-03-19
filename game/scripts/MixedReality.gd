extends Node

const to_hide := [ "/root/BeepSaber/event_driver/Level/Sphere", 
	"/root/BeepSaber/event_driver/Level/floor" 
	]
const make_transparent := [ "/root/BeepSaber/StandingGround/Node3D/cutFloor",
	#"/root/BeepSaber/event_driver/Level/floor" 
	]

func set_mixed_reality():
	var xr_interface := XRServer.find_interface("OpenXR") as XRInterface
	if xr_interface and xr_interface.is_passthrough_supported():
		if Settings.mixed_reality:
			if xr_interface.start_passthrough():
				get_viewport().transparent_bg = true
				#var environment : Environment = $WorldEnvironment.environment
				#environment.background_mode = Environment.BG_COLOR
				#environment.background_color = Color(0,0,0,0)
				#environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		else:
			xr_interface.stop_passthrough()
			
	for n in to_hide:
		if Settings.mixed_reality:
			get_node(n).hide()
		else:
			get_node(n).show()
			
	var transparency := 1 if Settings.mixed_reality else 0

	for n in make_transparent:
		var material := (get_node(n) as MeshInstance3D).material_override as StandardMaterial3D
		material.transparency = transparency
