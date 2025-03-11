extends Node

signal score_changed()
signal points_awarded(position: Vector3, amount: String)

var points: int
var combo: int
var multiplier: int
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
	score_changed.emit()

func reset_combo() -> void:
	multiplier = 1
	combo = 0
	wrong_notes += 1.0
	full_combo = false
	score_changed.emit()

func add_points(position: Vector3, amount: int) -> void:
	combo += 1
	@warning_ignore("integer_division")
	multiplier = 1 + mini(combo / 10, 7)
	points += amount * multiplier
	
	points_awarded.emit(position, str(amount))
	score_changed.emit()
	# track accuracy percent
	var normalized_points := clampf(float(points)/80.0, 0.0, 1.0);
	right_notes += normalized_points
	wrong_notes += 1.0-normalized_points

func chain_link_cut(position: Vector3) -> void:
	add_points(position, 20)

func note_cut(position: Vector3, beat_accuracy: float, cut_angle_accuracy: float, cut_distance_accuracy: float, travel_distance_factor: float) -> void:# point computation based on the accuracy of the swing
	var points_new := 0.0
	
	if cut_angle_accuracy >= 1e-10 and cut_distance_accuracy >= 1e-10:
		points_new += beat_accuracy * 50.0
		points_new += cut_angle_accuracy * 50.0
		points_new += cut_distance_accuracy * 50.0
		points_new += points_new * travel_distance_factor
		points_new = roundf(points_new)

	add_points(position, int(points_new))

func bad_cut(position: Vector3) -> void:
	reset_combo()
	points_awarded.emit(position, "x")
