extends Node2D
class_name Gameplay

const KARAOKE_LINE_STARTING_POSITION : Vector2 = Vector2(0, -200);
const KARAOKE_LINE_MARGIN : Vector2 = Vector2(0, 128);
const KARAOKE_LINES_AT_ONCE : int = 4;

var lyrics : Lyrics;
var current_karaoke_line_position : Vector2 = KARAOKE_LINE_STARTING_POSITION;
var current_karaoke_line_index : int = KARAOKE_LINES_AT_ONCE;
var karaoke_lines : Array;
var lines_map : Dictionary;
var used_phrases : Dictionary;

func init(lyrics_id : int) -> void:
	pass;
