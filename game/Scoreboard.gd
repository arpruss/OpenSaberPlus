extends Node

signal score_changed()
signal points_awarded(position: Vector3, amount: String)

var points: int
var combo: int
var multiplier: int
var in_wall: bool
var right_notes: float
var wrong_notes: float
var full_combo: bool
var paused: bool

func restart() -> void:
	points = 0
	multiplier = 1
	combo = 0
	right_notes = 0.0
	wrong_notes = 0.0
	full_combo = true
	in_wall = false
	score_changed.emit()

func reset_combo() -> void:
	multiplier = 1
	combo = 0
	wrong_notes += 1.0
	full_combo = false
	score_changed.emit()
	
func enter_wall() -> void:
	in_wall = true
	reset_combo()

func exit_wall() -> void:
	in_wall = false

func add_points(position: Vector3, amount: int, comment: String = "") -> void:
	if not in_wall:
		combo += 1
		@warning_ignore("integer_division")
		multiplier = 1 + mini(combo / 10, 7)
	points += amount * multiplier
	
	points_awarded.emit(position, str(amount)+(comment if Settings.explain else ""))
	score_changed.emit()
	# track accuracy percent
	var good = Constants.SWING_GOOD_SCORE if Settings.swing_scoring else Constants.OPENSABER_GOOD_SCORE
	var normalized_points := clampf(float(points)/good, 0.0, 1.0)
	right_notes += normalized_points
	wrong_notes += 1.0-normalized_points
	
func add_swing_score(position: Vector3, accuracy: float, preswing: float, followthrough: float) -> void:
	var score := int(roundf(accuracy + 
					clampf(preswing/Constants.TARGET_PRESWING_ANGLE,0,1.)*Constants.SWING_PRESWING_SCORE + 
					clampf(followthrough/Constants.TARGET_FOLLOWTHROUGH_ANGLE,0.,1.)*Constants.SWING_FOLLOWTHROUGH_SCORE))
	add_points(position, score, "  (%.1f+%.1f)" % [preswing,followthrough])

func chain_link_cut(position: Vector3) -> void:
	add_points(position, Constants.SWING_CHAIN_LINK_SCORE if Settings.swing_scoring else Constants.OPENSABER_CHAIN_LINK_SCORE)

func note_cut(saber: LightSaber, position: Vector3, beat_accuracy: float, cut_angle_accuracy: float, cut_distance_accuracy: float, 
		travel_distance_factor: float, arc_head: bool, arc_tail: bool, chain_head: bool) -> void:
	
	if cut_angle_accuracy >= 1e-10: # and cut_distance_accuracy >= 1e-10:
		if Settings.swing_scoring:
			if chain_head:
				add_points(position, Constants.SWING_CHAIN_HEAD_SCORE)
			else:
				# unless we have arc_head, we need to wait for followthrough to finish scoring
				saber.add_score(position, cut_distance_accuracy * Constants.SWING_ACCURACY_SCORE, arc_head, arc_tail)
		else:
			# point computation based on the accuracy of the swing
			var points_new := beat_accuracy * Constants.OPENSABER_BEAT_ACCURACY_SCORE;
			points_new += cut_angle_accuracy * Constants.OPENSABER_ANGLE_ACCURACY_SCORE;
			points_new += cut_distance_accuracy * Constants.OPENSABER_DISTANCE_ACCURACY_SCORE;
			points_new += points_new * travel_distance_factor
			points_new = roundf(points_new)
			add_points(position, int(points_new))
	else:
		if cut_angle_accuracy < 1e-10: # and cut_distance_accuracy >= 1e-10:
			bad_cut(position, "bad angle")
		#elif cut_angle_accuracy >= 1e-10 and cut_distance_accuracy < 1e-10:
		#	bad_cut(position, "too far")
		#else:
		#	bad_cut(position, "bad angle, too far")

func bad_cut(position: Vector3, description: String) -> void:
	reset_combo()
	points_awarded.emit(position, description if Settings.explain else "x")
