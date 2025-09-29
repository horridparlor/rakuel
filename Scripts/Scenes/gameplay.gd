extends Gameplay

@onready var music_player : AudioStreamPlayer2D = $MusicPlayer;
@onready var top_label : RichTextLabel = $Label;

func init(song_id : int) -> void:
	lyrics = read_lyrics(song_id);
	lyrics.show_phrase.connect(_on_show_phrase);
	lyrics.hide_phrase.connect(_on_hide_phrase);
	lyrics.glow_phrase.connect(_on_glow_phrase);
	music_init(song_id);
	top_label.text = lyrics.get_top_label_text();
	top_label.modulate.a = 0;
	await System.wait(0.8);
	play_karaoke();
	is_fading_top_label = true;

func music_init(song_id : int) -> void:
	var song : Dictionary = System.Json.read_data("Songs/%s" % song_id);
	var stream : Resource = load("res://Assets/%s/%s.wav" % ["Songs" if Config.SONG_MODE else "Instrumentals", song.name]);
	lyrics.name_of_the_song = song.name;
	if song.has("artist"):
		lyrics.created_by = song.artist;
	if song.has("edition"):
		lyrics.edition = song.edition;
	if song.has("language"):
		lyrics.language = song.language;
	if song.has("song_name_raw"):
		lyrics.song_name_raw = song.song_name_raw;
	else:
		lyrics.song_name_raw = song.name;
	if song.has("all_creators"):
		lyrics.all_creators = song.all_creators;
	else:
		lyrics.all_creators = song.artist;
	music_player.stream = stream;
	read_hyphenations(song_id, lyrics);
	read_pitches(song_id, lyrics);

func read_lyrics(lyrics_id : int) -> Lyrics:
	var lyrics : Lyrics = Lyrics.new();
	var parser = XMLParser.new();
	var error = parser.open("res://Data/Lyrics/%s.xml" % lyrics_id);
	if error != OK:
		return lyrics;
	lyrics.id = lyrics_id;
	lyrics.read_parser(parser);
	return lyrics;

func read_hyphenations(lyrics_id : int, lyrics : Lyrics) -> void:
	var data : Dictionary = System.Json.read_text_array("res://Data/Hyphenations/%s.txt" % [lyrics_id]);
	if System.Json.is_error(data):
		return
	lyrics.eat_hyphenation(data.lines);

func read_pitches(lyrics_id : int, lyrics : Lyrics) -> void:
	var data : Dictionary = System.Json.read("res://Data/Pitches/%s.json" % [lyrics_id]);
	if System.Json.is_error(data):
		return;
	lyrics.eat_pitches(data.stamps);
	lyrics.write_ultrastar();

func play_karaoke() -> void:
	System.start_watch();
	lyrics.record() if Config.RECORDING_MODE else lyrics.play();
	music_player.play(Config.START_TIME);
	music_player.finished.connect(_on_end);

func _on_end() -> void:
	await System.wait(1);
	get_tree().quit()

func _on_show_phrase(phrase : Phrase) -> void:
	var karaoke_line : KaraokeLine
	if used_phrases.has(phrase.id):
		return;
	karaoke_line = System.Instance.load_child(System.Paths.KARAOKE_LINE, self);
	karaoke_line.init(phrase);
	karaoke_line.position = get_karaoke_line_position();
	if karaoke_lines.size() > current_karaoke_line_index:
		karaoke_lines[current_karaoke_line_index] = karaoke_line;
	else:
		karaoke_lines.append(karaoke_line);
	lines_map[phrase.id] = karaoke_line;
	used_phrases[phrase.id] = null;

func _on_hide_phrase(phrase_id : int) -> void:
	if !lines_map.has(phrase_id) or !System.Instance.exists(lines_map[phrase_id]):
		return;
	lines_map[phrase_id].roll_out();

func get_karaoke_line_position() -> Vector2:
	current_karaoke_line_index += 1;
	current_karaoke_line_position += KARAOKE_LINE_MARGIN;
	if current_karaoke_line_index >= KARAOKE_LINES_AT_ONCE:
		current_karaoke_line_index = 0;
		current_karaoke_line_position = KARAOKE_LINE_STARTING_POSITION;
	return current_karaoke_line_position;

func _on_glow_phrase(phrase_id : int) -> void:
	if !lines_map.has(phrase_id) or !System.Instance.exists(lines_map[phrase_id]):
		print("111 %s %s" % [phrase_id, lines_map.has(phrase_id)]);
		return;
	lines_map[phrase_id].glow();

func _process(delta : float) -> void:
	process_actions();
	if is_fading_top_label:
		top_label.modulate.a += delta * TOP_LABEL_FADE_SPEED;
		if top_label.modulate.a >= 1:
			top_label.modulate.a = 1;
			is_fading_top_label = false;

func process_actions() -> void:
	if Input.is_action_just_pressed("start_phrase"):
		_on_start_word();
	if Input.is_action_just_pressed("end_phrase"):
		_on_end_word();
	if Input.is_action_just_pressed("save_lyrics"):
		_on_save_lyrics();

func _on_start_word() -> void:
	lyrics.start_next_phrase();

func _on_end_word() -> void:
	lyrics.end_phrase();

func _on_save_lyrics() -> void:
	lyrics.write();
	print("Lyrics saved");
