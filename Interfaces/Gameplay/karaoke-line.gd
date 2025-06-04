extends Node2D
class_name KaraokeLine

const ROLL_OUT_SPEED : int = 1600;
const ROLL_OUT_FADE_SPEED : float = 1.2;
const SIZE : Vector2 = Vector2(1920, 80);
const ROLL_IN_FADE_SPEED : float = 1.6;
const EXTRA_WAIT_BEFORE_END : float = 0.9;

var is_rolling_out : bool;
var is_rolling_in : bool;
var end_timer : Timer = Timer.new();
var next_letter_timer : Timer = Timer.new();
var phrase : Phrase;
var shown_index : int;

func _ready() -> void:
	for node in [
		end_timer,
		next_letter_timer
	]:
		add_child(node);
	end_timer.timeout.connect(roll_out);
	next_letter_timer.timeout.connect(_on_next_letter);
	modulate.a = 0;
	is_rolling_in = true;

func init(phrase_ : Phrase) -> void:
	pass;

func roll_out() -> void:
	end_timer.stop();
	is_rolling_out = true;

func _process(delta : float) -> void:
	if is_rolling_out:
		roll_out_frame(delta);
	if is_rolling_in:
		roll_in_frame(delta);

func roll_in_frame(delta : float) -> void:
	modulate.a += ROLL_IN_FADE_SPEED * delta;

func roll_out_frame(delta : float) -> void:
	position.x += ROLL_OUT_SPEED * delta;
	modulate.a -= ROLL_OUT_FADE_SPEED * delta;
	if !System.Vectors.is_inside_window(position, SIZE):
		queue_free();

func _on_next_letter() -> void:
	var next_wait : float;
	next_letter_timer.stop();
	shown_index += 1;
	update_text();
	next_wait = phrase.get_next_letter_wait();
	if next_wait <= 0:
		return;
	next_letter_timer.wait_time = next_wait;
	next_letter_timer.start();

func update_text() -> void:
	pass;

func glow() -> void:
	shown_index = 99;
	update_text();
