extends KaraokeLine

@onready var label : RichTextLabel = $RichTextLabel;

func init(phrase_ : Phrase) -> void:
	phrase = phrase_;
	shown_index = -1;
	_on_next_letter();
	end_timer.wait_time = phrase.end_time - phrase.time + 1;
	end_timer.start();

func update_text() -> void:
	var text : String = phrase.text;
	label.text = "[center][color=#ffffff]%s[/color][color=#898989]%s[/color][/center]" % [text.substr(0, shown_index), text.substr(shown_index)];
