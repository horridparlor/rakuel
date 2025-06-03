extends Gameplay

@onready var music_player : AudioStreamPlayer2D = $MusicPlayer;

func init(song_id : int) -> void:
	lyrics = read_lyrics(song_id);
	lyrics.write();
	lyrics.show_phrase.connect(_on_show_phrase);
	music_init(song_id);
	play_karaoke();

func music_init(song_id : int) -> void:
	var song : Dictionary = System.Json.read_data("Songs/%s" % song_id);
	var stream : Resource = load("res://Assets/%s/%s.wav" % ["Songs" if Config.SONG_MODE else "Instrumentals", song.name]);
	music_player.stream = stream;

func read_lyrics(lyrics_id : int) -> Lyrics:
	var lyrics : Lyrics = Lyrics.new();
	var parser = XMLParser.new();
	var error = parser.open("res://Data/Lyrics/%s.xml" % lyrics_id);
	if error != OK:
		return lyrics;
	lyrics.id = lyrics_id;
	lyrics.read_parser(parser);
	return lyrics;

func play_karaoke() -> void:
	System.start_watch();
	lyrics.play();
	music_player.play();
	music_player.finished.connect(_on_end);

func _on_end() -> void:
	await System.wait(2);
	get_tree().quit()

func _on_show_phrase(phrase : Phrase) -> void:
	var karaoke_line : KaraokeLine = System.Instance.load_child(System.Paths.KARAOKE_LINE, self);
	karaoke_line.init(phrase);
	karaoke_line.position = get_karaoke_line_position();
	if karaoke_lines.size() > current_karaoke_line_index:
		karaoke_lines[current_karaoke_line_index] = karaoke_line;
	else:
		karaoke_lines.append(karaoke_line);

func get_karaoke_line_position() -> Vector2:
	current_karaoke_line_index += 1;
	current_karaoke_line_position += KARAOKE_LINE_MARGIN;
	if current_karaoke_line_index >= KARAOKE_LINES_AT_ONCE:
		current_karaoke_line_index = 0;
		current_karaoke_line_position = KARAOKE_LINE_STARTING_POSITION;
	return current_karaoke_line_position;
