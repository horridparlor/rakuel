const MIN_JUMP : int = 1;

static func move_towards(current : float, target : float, speed : float) -> float:
	var distance : float = target - current;
	var direction : int = 1 if distance >= 0 else -1;
	var jump : float = speed * direction;
	return jump if abs(jump) < abs(distance) else distance;

static func direction(value : float) -> int:
	return 1 if value >= 0 else -1;

static func direction_safe_min(value : float, min : float) -> float:
	var direction : int = direction(value);
	return direction * max(min, abs(value));

static func to_str(value: float, decimals: int = -1) -> String:
	var message : String = str(value);
	if decimals < 0:
		return message;
	var decimal_index : int = message.find(".");
	var decimal_part_length : int = message.length() - decimal_index - 1;
	for i in range(decimals - decimal_part_length):
		message += "0";
	return message;
