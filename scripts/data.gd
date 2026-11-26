extends RefCounted
# Shared data: which model files belong to which chess piece, stats and special powers.

const PARTS := {
	"P": ["croc"],
	"N": ["monitor_body"],
	"W": ["monitor_rider"],
	"B": ["wizard"],
	"R": ["bomb"],
	"Q": ["snakegod"],
	"K": ["snakeking"],
}

const NAMES := {
	"P": "Croc Soldier", "N": "Monitor Knight", "W": "Warlord", "B": "Snake Wizard",
	"R": "Lizard Bomber", "Q": "Snake God", "K": "Snake King",
}

# Model heights (world units). Models are normalised to height 1.0 in assets/.
const FIGHT_H := {"P": 2.0, "N": 1.8, "W": 2.2, "B": 2.2, "R": 1.5, "Q": 2.4, "K": 2.4}
const BOARD_H := {"P": 0.95, "N": 0.68, "W": 1.1, "B": 1.1, "R": 0.74, "Q": 1.25, "K": 1.3}
# Body radius used for fighter collision / projectile hits
const RAD := {"P": 0.5, "N": 0.9, "W": 0.65, "B": 0.6, "R": 0.7, "Q": 0.75, "K": 0.75}

# hp, speed, dmg (light attack), reach, cd (attack cooldown),
# special: spear / fire / bomb / charge / smite / quake
const STATS := {
	"W": {"hp": 160.0, "speed": 6.0, "dmg": 22.0, "reach": 1.5, "cd": 0.32, "special": "quake", "sp_name": "King's Wrath", "sp_cd": 6.0, "sp_dmg": 40.0, "block": 0.15},
	"P": {"hp": 70.0, "speed": 4.6, "dmg": 7.0, "reach": 1.2, "cd": 0.42,
		"special": "spear", "sp_name": "Spear Throw", "sp_cd": 3.0, "sp_dmg": 12.0},
	"N": {"hp": 100.0, "speed": 5.2, "dmg": 10.0, "reach": 1.5, "cd": 0.5,
		"special": "charge", "sp_name": "Monitor Charge", "sp_cd": 4.0, "sp_dmg": 20.0},
	"B": {"hp": 85.0, "speed": 4.4, "dmg": 7.0, "reach": 1.0, "cd": 0.45,
		"special": "fire", "sp_name": "Fireball", "sp_cd": 2.6, "sp_dmg": 13.0},
	"R": {"hp": 130.0, "speed": 3.4, "dmg": 11.0, "reach": 1.1, "cd": 0.6,
		"special": "bomb", "sp_name": "Lizard Bomb", "sp_cd": 4.5, "sp_dmg": 24.0},
	"Q": {"hp": 150.0, "speed": 5.0, "dmg": 11.0, "reach": 1.3, "cd": 0.4,
		"special": "smite", "sp_name": "Divine Smite", "sp_cd": 5.0, "sp_dmg": 28.0},
	"K": {"hp": 180.0, "speed": 3.8, "dmg": 14.0, "reach": 1.4, "cd": 0.65,
		"special": "quake", "sp_name": "Royal Quake", "sp_cd": 4.5, "sp_dmg": 18.0},
}

# Stage themes (sky, light, scenery and board colours). Add your own entries here.
const STAGES := [
	{"name": "Floating Island",
		"sky_top": Color(0.25, 0.5, 0.9), "sky_hor": Color(0.78, 0.9, 1.0), "ambient": Color(0.7, 0.72, 0.8),
		"sun": Color(1.0, 0.96, 0.88), "sun_e": 1.0, "cloud": Color(1, 1, 1), "lava": false,
		"grass": Color(0.45, 0.62, 0.2), "rock": Color(0.42, 0.32, 0.24), "frame": Color(0.78, 0.74, 0.55),
		"tile_l": Color(0.92, 0.88, 0.76), "tile_d": Color(0.52, 0.47, 0.42),
		"floor": Color(0.45, 0.5, 0.35), "wall": Color(0.55, 0.52, 0.45)},
	{"name": "Hell Gate",
		"sky_top": Color(0.12, 0.01, 0.03), "sky_hor": Color(0.9, 0.28, 0.08), "ambient": Color(0.55, 0.3, 0.25),
		"sun": Color(1.0, 0.5, 0.3), "sun_e": 0.9, "cloud": Color(0.45, 0.15, 0.12), "lava": true,
		"grass": Color(0.22, 0.1, 0.08), "rock": Color(0.16, 0.09, 0.09), "frame": Color(0.35, 0.12, 0.1),
		"tile_l": Color(0.6, 0.45, 0.4), "tile_d": Color(0.17, 0.09, 0.09),
		"floor": Color(0.2, 0.1, 0.1), "wall": Color(0.3, 0.1, 0.1)},
	{"name": "Dark Desert",
		"sky_top": Color(0.08, 0.06, 0.25), "sky_hor": Color(0.96, 0.55, 0.3), "ambient": Color(0.6, 0.48, 0.5),
		"sun": Color(1.0, 0.75, 0.5), "sun_e": 1.0, "cloud": Color(0.9, 0.6, 0.5), "lava": false,
		"grass": Color(0.78, 0.62, 0.38), "rock": Color(0.55, 0.38, 0.25), "frame": Color(0.7, 0.55, 0.35),
		"tile_l": Color(0.9, 0.8, 0.6), "tile_d": Color(0.45, 0.33, 0.25),
		"floor": Color(0.7, 0.55, 0.35), "wall": Color(0.5, 0.35, 0.25)},
	{"name": "Sanctuary",
		"sky_top": Color(0.7, 0.78, 0.95), "sky_hor": Color(1.0, 0.95, 0.8), "ambient": Color(0.85, 0.85, 0.9),
		"sun": Color(1.0, 0.98, 0.9), "sun_e": 1.0, "cloud": Color(1, 1, 1), "lava": false,
		"grass": Color(0.7, 0.8, 0.5), "rock": Color(0.8, 0.78, 0.72), "frame": Color(0.95, 0.9, 0.7),
		"tile_l": Color(0.97, 0.95, 0.9), "tile_d": Color(0.6, 0.6, 0.7),
		"floor": Color(0.85, 0.83, 0.78), "wall": Color(0.92, 0.9, 0.82)},
	{"name": "Frozen Peak",
		"sky_top": Color(0.08, 0.22, 0.5), "sky_hor": Color(0.7, 0.9, 1.0), "ambient": Color(0.65, 0.75, 0.9),
		"sun": Color(0.85, 0.92, 1.0), "sun_e": 1.0, "cloud": Color(0.95, 0.98, 1.0), "lava": false,
		"grass": Color(0.85, 0.95, 1.0), "rock": Color(0.45, 0.6, 0.75), "frame": Color(0.7, 0.85, 0.95),
		"tile_l": Color(0.9, 0.97, 1.0), "tile_d": Color(0.4, 0.55, 0.7),
		"floor": Color(0.8, 0.9, 0.95), "wall": Color(0.55, 0.7, 0.85)},
]

# Builds the voxel model for a piece. The model faces -Z (local), height = `height`.
static func make_model(t: String, height: float, tint: Color, black: bool = false) -> Node3D:
	var root := Node3D.new()
	for part in PARTS[t]:
		var mi := MeshInstance3D.new()
		mi.mesh = load("res://assets/%s.obj" % part)
		if t == "W":
			mi.position.y = -0.24
			mi.scale = Vector3.ONE / 0.76
			mi.position.y /= 0.76
		var m := StandardMaterial3D.new()
		m.albedo_texture = load("res://assets/%s%s.png" % [part, "_b" if black else ""])
		m.albedo_color = tint
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = m
		root.add_child(mi)
	root.scale = Vector3.ONE * height
	return root
