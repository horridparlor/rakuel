extends Node

const Dictionaries : GDScript = preload("res://Scripts/System/dictionaries.gd");
const Display : int = 2;
const Floats : GDScript = preload("res://Scripts/System/floats.gd");
const Instance : GDScript = preload("res://Scripts/System/instance.gd");
const Json : GDScript = preload("res://Scripts/System/json.gd");
const Paths : GDScript = preload("res://Scripts/System/paths.gd");
const Random : GDScript = preload("res://Scripts/System/random.gd");
const Scale : GDScript = preload("res://Scripts/System/scale.gd");
const Vectors : GDScript = preload("res://Scripts/System/vectors.gd");
const Window_ : Vector2 = Vector2(1080, 1920);

var random : RandomNumberGenerator = RandomNumberGenerator.new();
var game_speed : float = 1;
var game_speed_multiplier : float = 1 / game_speed;
var time : float;

func init() -> void:
	Json.create_directories();

func wait(wait : float) -> void:
	var timer : Timer = Timer.new();
	timer.wait_time = wait * game_speed_multiplier;
	timer.one_shot = true;
	add_child(timer);
	timer.start();
	await timer.timeout;
	timer.queue_free();

func wait_range(min : float, max : float) -> void:
	await wait(random.randf_range(min, max));

func start_watch() -> void:
	time = 0;

func _process(delta : float) -> void:
	time += delta;
