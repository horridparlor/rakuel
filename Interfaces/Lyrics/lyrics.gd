extends Node
class_name Lyrics

signal show_phrase(phrase)

@onready var music_player : AudioStreamPlayer2D = $MusicPlayer;

const SAVE_FOLDER_PATH : String = "user://lyrics/";
const SAVE_PATH : String = SAVE_FOLDER_PATH + "%s.xml";
const EXTRA_TIME_TO_SHOW : float = 0.05;

var id : int;
var created_by : String = "Eero Laine";
var version : String;
var source : String;
var is_duet : bool;
var phrases : Array;
var phrase_index : int = -1;
var current_phrase : Phrase;

func play() -> void:
	phrase_index = 0;
	play_next_phrase();

func play_next_phrase() -> void:
	current_phrase = phrases[phrase_index];
	await System.wait(current_phrase.time - System.get_time() - EXTRA_TIME_TO_SHOW);
	_on_show_phrase();

func _on_show_phrase() -> void:
	emit_signal("show_phrase", current_phrase);
	phrase_index += 1;
	if phrase_index < phrases.size():
		play_next_phrase();

func read_parser(parser : XMLParser) -> void:
	var key : String;
	while parser.read() == OK:
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				key = parser.get_node_name();
				match key:
					"phrase":
						phrases.append(Phrase.from_parser(parser));
						phrase_index += 1;
					"letter":
						phrases[phrase_index].read_letter(parser);

func write() -> void:
	var xml = '<?xml version="1.0" encoding="UTF-8"?>\n<song created-by="%s" version="%s" source="%s" duet="%s">\n' % [
		created_by,
		version,
		source,
		"yes" if is_duet else "no"
	];
	var phrase : Phrase;
	var letter : Letter;
	for p in phrases:
		phrase = p;
		xml += '  <phrase text="%s" i="%s" time="%s" pos="%s" flags="%s">\n' % [
			phrase.text, str(phrase.id), str(phrase.time), System.Vectors.to_fraction(phrase.position), phrase.flags
		]
		for l in phrase.letters:
			letter = l;
			var line : String = '    <letter char="%s" i="%s" time="%s"' % [
				letter.char, str(letter.id), System.Floats.to_str(letter.time, 3)
			]
			if letter.end_time > 0:
				line += ' end-time="%s"' % System.Floats.to_str(letter.end_time, 3)
			line += "/>\n"
			xml += line
		xml += '  </phrase>\n'
	xml += '</song>\n'
	var file : FileAccess = FileAccess.open(SAVE_PATH % id, FileAccess.WRITE);
	if !file:
		return;
	file.store_string(xml);
	file.close();
