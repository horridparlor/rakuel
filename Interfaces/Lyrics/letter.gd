extends Node
class_name Letter

var id : int;
var char : String;
var time : float;
var end_time : float;

static func from_parser(parser : XMLParser) -> Letter:
	var letter : Letter = Letter.new();
	letter.read_parser(parser);
	return letter;

func read_parser(parser : XMLParser) -> void:
	char = parser.get_attribute_value(0);
	id = int(parser.get_attribute_value(1));
	time = float(parser.get_attribute_value(2));
	end_time = float(parser.get_attribute_value(3));

func _to_string() -> String:
	return "{'id': %s, 'char': '%s', 'time': %s}" % [id, char, time];
