extends Node
## Physical keyboard and mouse bindings shared by both duel implementations.

const CONFIG := "user://controls.cfg"
const DEFAULTS := {
	"arena_forward": {"type": "key", "code": KEY_W},
	"arena_back": {"type": "key", "code": KEY_S},
	"arena_left": {"type": "key", "code": KEY_A},
	"arena_right": {"type": "key", "code": KEY_D},
	"arena_jump": {"type": "key", "code": KEY_SPACE},
	"arena_sprint": {"type": "key", "code": KEY_SHIFT},
	"arena_dodge": {"type": "key", "code": KEY_ALT},
	"arena_attack": {"type": "mouse", "code": MOUSE_BUTTON_LEFT},
	"arena_block": {"type": "mouse", "code": MOUSE_BUTTON_RIGHT},
	"arena_special": {"type": "key", "code": KEY_Q},
	"p1_left": {"type": "key", "code": KEY_A},
	"p1_right": {"type": "key", "code": KEY_D},
	"p1_jump": {"type": "key", "code": KEY_W},
	"p1_block": {"type": "key", "code": KEY_S},
	"p1_attack": {"type": "key", "code": KEY_F},
	"p1_special": {"type": "key", "code": KEY_G},
	"p2_left": {"type": "key", "code": KEY_LEFT},
	"p2_right": {"type": "key", "code": KEY_RIGHT},
	"p2_jump": {"type": "key", "code": KEY_UP},
	"p2_block": {"type": "key", "code": KEY_DOWN},
	"p2_attack": {"type": "key", "code": KEY_COMMA},
	"p2_special": {"type": "key", "code": KEY_PERIOD},
}

var bindings: Dictionary = {}

func _ready() -> void:
	bindings = DEFAULTS.duplicate(true)
	var config := ConfigFile.new()
	if config.load(CONFIG) != OK: return
	for action in DEFAULTS:
		var stored: Variant = config.get_value("bindings", action, null)
		if stored is Dictionary and stored.has("type") and stored.has("code"):
			var kind: String = str(stored["type"])
			var code: int = int(stored["code"])
			if _valid(kind, code): rebind(action, kind, code, false)

func _group(action: String) -> String:
	return action.get_slice("_", 0)

func _valid(kind: String, code: int) -> bool:
	return (kind == "key" and code > 0 and code != KEY_ESCAPE) or (kind == "mouse" and code in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_XBUTTON1, MOUSE_BUTTON_XBUTTON2])

func rebind(action: String, kind: String, code: int, save: bool = true) -> String:
	if not DEFAULTS.has(action) or not _valid(kind, code): return "INVALID"
	var replacement := {"type": kind, "code": code}
	var previous: Dictionary = bindings[action].duplicate()
	var swapped := ""
	for other in DEFAULTS:
		if other != action and _group(other) == _group(action) and bindings[other] == replacement:
			bindings[other] = previous
			swapped = other
			break
	bindings[action] = replacement
	if save: _save()
	return swapped

func reset_bindings() -> void:
	bindings = DEFAULTS.duplicate(true)
	_save()

func _save() -> void:
	var config := ConfigFile.new()
	for action in DEFAULTS:
		config.set_value("bindings", action, bindings[action])
	config.save(CONFIG)

func is_pressed(action: String) -> bool:
	if not bindings.has(action): return false
	var binding: Dictionary = bindings[action]
	return Input.is_physical_key_pressed(int(binding["code"])) if binding["type"] == "key" else Input.is_mouse_button_pressed(int(binding["code"]))

func matches(event: InputEvent, action: String) -> bool:
	if not bindings.has(action): return false
	var binding: Dictionary = bindings[action]
	if binding["type"] == "key" and event is InputEventKey:
		return event.pressed and not event.echo and event.physical_keycode == int(binding["code"])
	if binding["type"] == "mouse" and event is InputEventMouseButton:
		return event.pressed and event.button_index == int(binding["code"])
	return false

func display_name(action: String) -> String:
	if not bindings.has(action): return "?"
	var binding: Dictionary = bindings[action]
	if binding["type"] == "mouse":
		match int(binding["code"]):
			MOUSE_BUTTON_LEFT: return "Mouse Left"
			MOUSE_BUTTON_RIGHT: return "Mouse Right"
			MOUSE_BUTTON_MIDDLE: return "Mouse Middle"
			MOUSE_BUTTON_XBUTTON1: return "Mouse 4"
			MOUSE_BUTTON_XBUTTON2: return "Mouse 5"
	var key := InputEventKey.new()
	key.physical_keycode = int(binding["code"])
	return key.as_text().replace(" (Physical)", "")
