extends Node
class_name Phrase

const EXTRA_RECORDING_START_TIME : float = 1.6;
const RECORDING_LAG : float = 0.4;
const BEATS_OFFSET : float = EXTRA_RECORDING_START_TIME + 0.1;

var id : int;
var text : String;
var time : float;
var end_time : float;
var position : Vector2;
var flags : String; 
var letters : Array;
var current_letter_index : int;
var color : String = "#FFFFFF";
var start_beats : int;
var end_beats : int;
var beats_duration : int;
var pitch : int;
var syllables : Array;

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
	start_beats = time * Config.BPM_MULTIPLIER;
	position = System.Vectors.parse_fraction(parser.get_attribute_value(3));
	flags = parser.get_attribute_value(4);

func read_letter(parser : XMLParser) -> void:
	var letter : Letter = Letter.from_parser(parser);
	end_time = letter.end_time;
	end_beats = (end_time - BEATS_OFFSET) * Config.BPM_MULTIPLIER;
	beats_duration = end_beats - start_beats;
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

func eat_hyphonation(lines : Array, line_index : int) -> int:
	var syllable_text : String;
	var lenght_left : int = text.replace(" ", "").length();
	var syllable : Syllable;
	var real_letters : Array = letters.filter(func(letter : Letter): return letter.char != " ");
	var index : int;
	var letters_index : int;
	while line_index + index < lines.size():
		syllable_text = lines[line_index + index];
		syllable = Syllable.new();
		syllable.text = syllable_text;
		syllable.start_time = real_letters[real_letters.size() - lenght_left].time;
		lenght_left -= syllable_text.length();
		letters_index += syllable_text.length();
		if letters.size() < letters_index and letters[letters_index].char == " ":
			letters_index += 1;
		syllable.end_time = real_letters[real_letters.size() - lenght_left].time if real_letters.size() - lenght_left < real_letters.size() else end_time;
		syllable.ends_with_space = letters_index + 1 < letters.size() and letters[letters_index + 1].char == " ";
		syllable.calculate_beats();
		syllables.append(syllable);
		index += 1;
		if lenght_left <= 0:
			return index;
	return index;

func combine_syllables() -> void:
	var syllable : Syllable;
	var previous_syllable : Syllable;
	for s in syllables.duplicate():
		syllable = s;
		if previous_syllable != null and abs(previous_syllable.pitch - syllable.pitch) < 1:
			syllable.combine_with(previous_syllable);
			syllables.erase(previous_syllable);
		previous_syllable = syllable;
