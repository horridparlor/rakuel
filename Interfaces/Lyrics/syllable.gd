extends Node
class_name Syllable

var start_time : float;
var end_time : float;
var text : String;
var start_beats : int;
var end_beats : int;
var beats_duration : int;
var pitch : int;
var ends_with_space : bool;

func calculate_beats() -> void:
	start_beats = start_time * Config.BPM_MULTIPLIER;
	end_beats = end_time * Config.BPM_MULTIPLIER;
	beats_duration = end_beats - start_beats;

func combine_with(syllable : Syllable) -> void:
	start_time = syllable.start_time;
	text = syllable.text + (" " if syllable.ends_with_space else "") + text;
	pitch = syllable.pitch;
	calculate_beats();
