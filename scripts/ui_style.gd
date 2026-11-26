extends RefCounted

static func panel(bg: Color, edge: Color, margin: int = 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = edge
	s.set_border_width_all(1)
	s.set_corner_radius_all(6)
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin
	s.content_margin_bottom = margin
	return s

static func make_theme(stage: int = 0) -> Theme:
	var t := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Arial Black", "Impact", "Georgia", "Arial"])
	font.font_weight = 800
	t.default_font = font
	t.default_font_size = 20
	var gold: Color = [Color("c6edac"), Color("ffd6a0"), Color("edc080"), Color("fff0ba"), Color("c6efff")][stage]
	var bg: Color = [Color("142d24"), Color("1b100e"), Color("302018"), Color("302b20"), Color("102b40")][stage]
	t.set_color("font_color", "Label", gold.lightened(0.35))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(state, "Button", gold)
	t.set_stylebox("normal", "Button", panel(bg, gold.darkened(0.45), 10))
	t.set_stylebox("hover", "Button", panel(bg.lightened(0.18), gold, 10))
	t.set_stylebox("pressed", "Button", panel(bg.lightened(0.28), gold, 10))
	t.set_stylebox("disabled", "Button", panel(Color("20252a"), Color("444444"), 10))
	var focus := panel(Color.TRANSPARENT, gold, 0)
	focus.set_border_width_all(2)
	t.set_stylebox("focus", "Button", focus)
	t.set_stylebox("panel", "PanelContainer", panel(Color(bg, 0.97 if stage == 1 else 0.90), gold.darkened(0.45), 24))
	return t

static func decorate(root: Node, stage: int) -> void:
	if root is Label and not root.has_meta("plain_text"):
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://shaders/map_title.gdshader")
		mat.set_shader_parameter("effect", stage)
		root.material = mat
		root.add_theme_color_override("font_color", Color.WHITE)
		root.add_theme_constant_override("outline_size", 0)
	elif root is Button:
		var overlay := root.get_node_or_null("MapInk") as Label
		if overlay == null:
			overlay = Label.new()
			overlay.name = "MapInk"
			overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			overlay.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			root.add_child(overlay)
			overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			var button := root as Button
			overlay.text = button.text
			overlay.add_theme_font_size_override("font_size", button.get_theme_font_size("font_size"))
			button.draw.connect(func(): overlay.text = button.text)
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color", "font_hover_pressed_color"]:
			root.add_theme_color_override(state, Color.TRANSPARENT)
	for child in root.get_children():
		decorate(child, stage)
