extends Node
class_name Phrase

const EXTRA_RECORDING_START_TIME : float = 1.6;
const RECORDING_LAG : float = 0.4;

var id : int;
var text : String;
var time : float;
var end_time : float;
var position : Vector2;
var flags : String; 
var letters : Array;
var current_letter_index : int;
var color : String = "#FFFFFF";

static func from_parser(parser : XMLParser) -> Phrase:
	var phrase : Phrase = Phrase.new();
	phrase.read_parser(parser);
	return phrase;

func read_parser(parser : XMLParser) -> void:
	text = parser.get_attribute_value(0);
	if !text.is_empty() and text[0] == "*":
		color = "a7efab";
	id = int(parser.get_attribute_value(1));
	time = float(parser.get_attribute_value(2));
	position = System.Vectors.parse_fraction(parser.get_attribute_value(3));
	flags = parser.get_attribute_value(4);

func read_letter(parser : XMLParser) -> void:
	var letter : Letter = Letter.from_parser(parser);
	end_time = letter.end_time;
	letters.append(letter);

func get_next_letter_wait() -> float:
	var wait_time : float;
	var letter : Letter;
	if current_letter_index >= letters.size():
		return wait_time;
	letter = letters[current_letter_index];
	current_letter_index += 1;
	if letter.time == 0:
		return 0;
	return letter.time - System.time;

func _to_string() -> String:
	return "{'id': %s, 'text': '%s', 'time': %s, 'end_time': %s, 'pos': %s}" % [id, text, time, end_time, position];

func auto_time_letters() -> void:
	var letter : Letter;
	var duration : float = end_time - time;
	var between_letters = duration / (letters.size() + 1);
	var time_i : float = time - RECORDING_LAG;
	for l in letters:
		letter = l;
		time_i += between_letters;
		letter.time = time_i;
	letter = letters.back();
	letter.end_time = end_time;
	time -= EXTRA_RECORDING_START_TIME;
	time = max(0.2, time);
