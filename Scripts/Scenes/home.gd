extends Home

func _ready() -> void:
	System.init();
	gameplay = System.Instance.load_child(System.Paths.GAMEPLAY, self);
	gameplay.init(5);
