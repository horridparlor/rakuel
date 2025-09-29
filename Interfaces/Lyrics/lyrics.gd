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
var song_name_raw : String;
var all_creators : String;

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
	var phrase : Phrase;
	while parser.read() == OK:
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				key = parser.get_node_name();
				match key:
					"phrase":
						phrase = Phrase.from_parser(parser);
						phrases.append(phrase);
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
			phrase.text.replace("\"", "'"), str(phrase.id), str(phrase.time), System.Vectors.to_fraction(phrase.position), phrase.flags
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
	var character : String;
	var syllable : Syllable;
	for p in phrases:
		phrase = p;
		for s in phrase.syllables:
			syllable = s;
			while pitch_index < pitches.size():
				pitch = pitches[pitch_index];
				if pitch.pitch <= -12 or pitch.pitch >= 12:
					pitch_index += 1;
					continue;
				if pitch.startTime >= syllable.start_time:
					syllable.pitch = pitch.pitch;
					break;
				pitch_index += 1;
		#phrase.combine_syllables();
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
	var syllable : Syllable;
	var text_on_this_line : int;
	var is_first_syllable : bool;
	var extra_phrase_length : int;
	text += "#ARTIST:%s
#TITLE:%s
#EDITION:%s
#LANGUAGE:%s
#CREATOR:saunaeero
#VIDEO:%s - %s.mp4
#MP3:%s - %s.mp3
#PREVIEWSTART:60
#COVER:cover.png
#BPM:%s
#GAP:%s" % [all_creators, song_name_raw, edition, language, created_by, name_of_the_song, created_by, name_of_the_song, Config.BPM, gap];
	for p in phrases:
		phrase = p;
		is_first_syllable = true;
		extra_phrase_length = 0;
		for s in phrase.syllables:
			syllable = s;
			text += "\n%s %s %s %s %s" % [
				syllable.line_symbol,
				syllable.start_beats - int(Config.BPM_MULTIPLIER),
				int(max(1, syllable.beats_duration * Config.NOTE_LENGTH)),
				12 if syllable.is_max_pitch else syllable.pitch,
				replace_macrons_with_tilde((" " if is_first_syllable else "") + syllable.text + (" " if syllable.ends_with_space else ""))
			];
			if is_first_syllable:
				is_first_syllable = false;
			elif !syllable.ends_with_space:
				extra_phrase_length += 1;
			if syllable.ends_with_space:
				is_first_syllable = true;
			if syllable.ends_line:
				text_on_this_line += 99;
		next_begins = phrases[index + 1].syllables[0].start_beats - int(Config.DELAY_START * Config.BPM_MULTIPLIER) if index < phrases.size() - 1 else end_beats;
		text_on_this_line += phrase.text.length() + extra_phrase_length;
		if text_on_this_line > 45:
			text += "\n- %s" % [next_begins];
			text_on_this_line = 0;
		else:
			text += " ";
		index += 1;
	text += "\nE";
	text = fix_overlapping_lines(text);
	return text.replace("5\u0004", "e");

func replace_macrons_with_tilde(s : String) -> String:
	var map: Dictionary = {
		"ā": "a~", "ē": "e~", "ī": "i~", "ō": "o~", "ū": "u~",
		"Ā": "A~", "Ē": "E~", "Ī": "I~", "Ō": "O~", "Ū": "U~",
		"ȳ": "y~", "Ȳ": "Y~"
	};
	for k in map.keys():
		s = s.replace(k, map[k]);
	var cp : PackedByteArray = s.to_utf32_buffer();
	var out : String = "";
	var i : int = 0;
	while i < cp.size():
		if i + 1 < cp.size() and cp[i + 1] == 0x0304:
			out += String.chr(cp[i]) + "~";
			i += 2;
		else:
			out += String.chr(cp[i]);
			i += 1;
	return out;


func is_note_line(l : String) -> bool:
	var trimmed: String = l.lstrip(" \t");
	return trimmed.begins_with(":") or trimmed.begins_with("*");

func parse_note_line(l : String) -> Dictionary:
	var leading_ws : String = "";
	var i: int = 0;
	while i < l.length() and (l[i] == " " or l[i] == "\t"):
		leading_ws += l[i];
		i += 1;
	var trimmed : String = l.substr(i);
	var tokens : Array = trimmed.split(" ", true);
	if tokens.size() < 3:
		return {"ok": false};
	var marker : String = tokens[0];
	if not tokens[1].is_valid_int() or not tokens[2].is_valid_int():
		return {"ok": false};
	var start : int = int(tokens[1]);
	var dur : int = int(tokens[2]);
	var rest_tokens : Array = tokens.slice(3, tokens.size()) if tokens.size() > 3 else [];
	return {
		"ok": true,
		"leading_ws": leading_ws,
		"marker": marker,
		"start": start,
		"dur": dur,
		"rest": rest_tokens
	};

func build_note_line(p: Dictionary) -> String:
	var pieces: Array = [p.marker, str(p.start), str(max(p.dur, 0))];
	for t in p.rest:
		pieces.append(str(t));
	return p.leading_ws + " ".join(pieces);

func fix_overlapping_lines(text: String) -> String:
	var lines: Array = text.split("\n", false);
	if lines.size() <= 1:
		return text;
	for i in range(lines.size()):
		if not is_note_line(lines[i]):
			continue;
		var cur: Dictionary = parse_note_line(lines[i]);
		if not cur.ok:
			continue;
		var j: int = i + 1;
		while j < lines.size() and not is_note_line(lines[j]):
			j += 1;
		if j >= lines.size():
			continue;
		var nxt: Dictionary = parse_note_line(lines[j]);
		if not nxt.ok:
			continue;
		var cur_end: int = cur.start + cur.dur;
		var next_start: int = nxt.start;
		if next_start < cur_end:
			cur.dur = max(0, next_start - cur.start);
			lines[i] = build_note_line(cur);
	return "\n".join(lines);

func get_beats_to_start() -> int:
	var phrase : Phrase = phrases[0];
	return phrase.syllables[0].start_beats;

func eat_hyphenation(lines : Array) -> void:
	var index : int;
	var phrase : Phrase;
	for p in phrases:
		phrase = p;
		index += phrase.eat_hyphonation(lines, index);
