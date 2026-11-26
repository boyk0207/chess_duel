extends CanvasLayer
## Phase 4 promotion choice overlay. The board keeps ownership of the actual piece change.

signal chosen(kind: String)

const UIStyle = preload("res://scripts/ui_style.gd")
const OPTIONS := [
	{"kind": "N", "name": "KNIGHT", "role": "Swift flanker"},
	{"kind": "B", "name": "BISHOP", "role": "Long-range mage"},
	{"kind": "R", "name": "ROOK", "role": "Heavy guardian"},
	{"kind": "Q", "name": "QUEEN", "role": "Versatile fighter"},
	{"kind": "W", "name": "WARLORD", "role": "Battle commander"},
]

var stage_idx := 0
var white_side := true
var buttons: Dictionary = {}

func configure(stage: int, white: bool) -> void:
	stage_idx = stage
	white_side = white

func _ready() -> void:
	layer = 20
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.theme = UIStyle.make_theme(stage_idx)
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.025, 0.045, 0.90)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(870, 260)
	center.add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.13)
	style.border_color = Color(0.30, 0.83, 1.0) if white_side else Color(1.0, 0.34, 0.25)
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", style)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	panel.add_child(content)
	var title := Label.new()
	title.text = "PROMOTE YOUR PAWN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	content.add_child(title)
	var instruction := Label.new()
	instruction.text = "Choose the warrior who will enter the board"
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(instruction)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(row)
	for option in OPTIONS:
		var kind: String = option["kind"]
		var card := Button.new()
		card.text = "%s\n%s\n%s" % [kind, option["name"], option["role"]]
		card.custom_minimum_size = Vector2(150, 116)
		card.add_theme_font_size_override("font_size", 18)
		card.pressed.connect(_choose.bind(kind))
		row.add_child(card)
		buttons[kind] = card

func _choose(kind: String) -> void:
	chosen.emit(kind)
