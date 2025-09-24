extends Node
class_name Lyrics

signal show_phrase(phrase)
signal hide_phrase(phrase_id)
signal glow_phrase(phrase_id)

@onready var music_player : AudioStreamPlayer2D = $MusicPlayer;

const SAVE_FOLDER_PATH : String = "user://lyrics/";
const SAVE_PATH : String = SAVE_FOLDER_PATH + "%s.xml";
const ULTRASTAR_SAVE_FOLDER_PATH : String = "user://ultrastar/";
const ULTRASTAR_SAVE_PATH : String = ULTRASTAR_SAVE_FOLDER_PATH + "%s.txt";
const EXTRA_TIME_TO_SHOW : float = 0.05;

var id : int;
var created_by : String = "Eero Laine";
var name_of_the_song : String;
var version : String;
var source : String;
var is_duet : bool;
var phrases : Array;
var phrase_index : int = -1;
var current_phrase : Phrase;
var edition : String;
var language : String;
var end_beats : int;

func play() -> void:
	phrase_index = 0;
	play_next_phrase();

func record() -> void:
	phrase_index = -1;
	reset_phrase_for_recording(phrases[phrase_index + 1]);
	emit_signal("show_phrase", phrases[phrase_index + 1]);

func reset_phrase_for_recording(phrase : Phrase = current_phrase) -> void:
	phrase.time = System.time;
	phrase.end_time = 0;
	for letter in phrase.letters:
		letter.time = 0;
		letter.end_time = 0;

func start_next_phrase(do_start : bool = true) -> void:
	end_phrase();
	phrase_index += 1;
	if phrase_index >= phrases.size():
		return;
	current_phrase = phrases[phrase_index];
	reset_phrase_for_recording();
	emit_signal("show_phrase", current_phrase);
	emit_signal("glow_phrase", current_phrase.id);
	if phrase_index + 1 < phrases.size():
		reset_phrase_for_recording(phrases[phrase_index + 1]);
		emit_signal("show_phrase", phrases[phrase_index + 1]);
	if !do_start:
		return;

func end_phrase() -> void:
	if current_phrase == null:
		return;
	current_phrase.end_time = System.time;
	current_phrase.auto_time_letters();
	emit_signal("hide_phrase", current_phrase.id);
	if phrases.size() <= phrase_index + 1:
		return;
	emit_signal("show_phrase", phrases[phrase_index + 1]);
	current_phrase = null;

func play_next_phrase() -> void:
	current_phrase = phrases[phrase_index];
	if current_phrase.time < Config.START_TIME:
		phrase_index += 1;
		play_next_phrase();
		return;
	await System.wait(current_phrase.time - System.time - EXTRA_TIME_TO_SHOW);
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
	var xml = '<?xml version="1.0" encoding="UTF-8"?>\n<song created-by="%s" name="%s" version="%s" source="%s" duet="%s">\n' % [
		created_by,
		name_of_the_song,
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

func get_top_label_text() -> String:
	return "[right]" + name_of_the_song + " [i](" + created_by + ")[/i][/right]";

func eat_pitches(pitches : Array) -> void:
	var phrase : Phrase;
	var pitch_index : int;
	var pitch : Dictionary;
	for p in phrases:
		phrase = p;
		while pitch_index < pitches.size():
			pitch = pitches[pitch_index];
			if pitch.startTime >= phrase.time:
				phrase.pitch = pitch.pitch;
				pitch_index += 1;
				break;
			pitch_index += 1;
	end_beats = pitches.back().endTime * Config.BPM_MULTIPLIER;

func write_ultrastar() -> void:
	var ultrastar : String = to_ultrastar();
	var file : FileAccess = FileAccess.open(ULTRASTAR_SAVE_PATH % id, FileAccess.WRITE);
	if !file:
		return;
	file.store_string(ultrastar);
	file.close();

func to_ultrastar() -> String:
	var text : String;
	var gap : int = get_beats_to_start();
	var phrase : Phrase;
	var index : int;
	var next_begins : int;
	text += "#ARTIST:%s
#TITLE:%s
#EDITION:%s
#LANGUAGE:%s
#VIDEO:%s - %s.mp4
#MP3:%s - %s.mp3
#COVER:cover.png
#BPM:%s
#GAP:%s" % [created_by, name_of_the_song, edition, language, created_by, name_of_the_song, created_by, name_of_the_song, Config.BPM, gap];
	for p in phrases:
		phrase = p;
		text += "\n: %s %s %s %s" % [
			phrase.start_beats,
			phrase.beats_duration,
			phrase.pitch,
			phrase.text
		];
		next_begins = phrases[index + 1].start_beats if index < phrases.size() - 1 else end_beats;
		text += "\n- %s" % [next_begins];
		index += 1;
	text += "\nE";
	return text;

func get_beats_to_start() -> int:
	var phrase : Phrase = phrases[0];
	return phrase.start_beats;
