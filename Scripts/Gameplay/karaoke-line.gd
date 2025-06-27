extends KaraokeLine

@onready var label : RichTextLabel = $RichTextLabel;

func init(phrase_ : Phrase) -> void:
	phrase = phrase_;
	shown_index = -1;
	_on_next_letter();
	end_timer.wait_time = phrase.end_time - phrase.time + EXTRA_WAIT_BEFORE_END;
	if phrase.end_time == 0:
		return;
	end_timer.start();

func update_text() -> void:
	var text : String = phrase.text;
	if text.length() and text[0] == "*":
		text = text.substr(1);
	var color : String = phrase.color;
	label.text = "[center][color=%s]%s[/color][color=#898989]%s[/color][/center]" % [color, text.substr(0, shown_index), text.substr(shown_index)];
