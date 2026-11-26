extends RefCounted
## Legal chess movement for Chess Duel, with its optional Warlord promotion and combat capture outcome.
## Board coordinates: a1=(0,0), h8=(7,7). Competition/physical-board rules live outside this model.

const INVALID := Vector2i(-1, -1)
const PROMOTIONS := ["Q", "R", "B", "N"]
const KNIGHT_STEPS := [Vector2i(1, 2), Vector2i(2, 1), Vector2i(-1, 2), Vector2i(-2, 1), Vector2i(1, -2), Vector2i(2, -1), Vector2i(-1, -2), Vector2i(-2, -1)]
const STRAIGHT := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const DIAGONAL := [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]

var pieces: Dictionary = {}
var allow_warlord := false
var white_turn := true
var castle_rights := {"K": true, "Q": true, "k": true, "q": true}
var ep_target := INVALID
var halfmove_clock := 0
var fullmove_number := 1
var repetition: Dictionary = {}
var result := ""  # white, black, draw; empty while playing
var result_reason := ""
var move_log: Array[String] = []

func _inside(p: Vector2i) -> bool:
	return p.x >= 0 and p.x < 8 and p.y >= 0 and p.y < 8

func _piece(t: String, w: bool) -> Dictionary:
	return {"t": t, "w": w}

func reset() -> void:
	pieces.clear()
	var back := ["R", "N", "B", "Q", "K", "B", "N", "R"]
	for x in 8:
		pieces[Vector2i(x, 0)] = _piece(back[x], true)
		pieces[Vector2i(x, 1)] = _piece("P", true)
		pieces[Vector2i(x, 6)] = _piece("P", false)
		pieces[Vector2i(x, 7)] = _piece(back[x], false)
	white_turn = true
	castle_rights = {"K": true, "Q": true, "k": true, "q": true}
	ep_target = INVALID
	halfmove_clock = 0
	fullmove_number = 1
	repetition.clear()
	result = ""
	result_reason = ""
	move_log.clear()
	_record_position()

func set_fen(fen: String) -> bool:
	var fields := fen.strip_edges().split(" ", false)
	if fields.size() < 4: return false
	var rows := fields[0].split("/")
	if rows.size() != 8: return false
	var next_pieces: Dictionary = {}
	for row_idx in 8:
		var x := 0
		for ch in rows[row_idx]:
			if ch.is_valid_int():
				x += int(ch)
			else:
				var t := ch.to_upper()
				if t not in (["P", "N", "B", "R", "Q", "K", "W"] if allow_warlord else ["P", "N", "B", "R", "Q", "K"]) or x > 7: return false
				next_pieces[Vector2i(x, 7 - row_idx)] = _piece(t, ch == t)
				x += 1
		if x != 8: return false
	if fields[1] not in ["w", "b"]: return false
	pieces = next_pieces
	white_turn = fields[1] == "w"
	castle_rights = {"K": false, "Q": false, "k": false, "q": false}
	for ch in fields[2]:
		if castle_rights.has(ch): castle_rights[ch] = true
	ep_target = parse_square(fields[3]) if fields[3] != "-" else INVALID
	halfmove_clock = int(fields[4]) if fields.size() > 4 else 0
	fullmove_number = int(fields[5]) if fields.size() > 5 else 1
	repetition.clear()
	result = ""
	result_reason = ""
	move_log.clear()
	_record_position()
	return true

func square_name(p: Vector2i) -> String:
	if not _inside(p): return "-"
	return "abcdefgh"[p.x] + str(p.y + 1)

func parse_square(name: String) -> Vector2i:
	if name.length() != 2: return INVALID
	var x := "abcdefgh".find(name[0])
	var y := "12345678".find(name[1])
	return Vector2i(x, y) if x >= 0 and y >= 0 else INVALID

func to_fen() -> String:
	var ranks := []
	for y in range(7, -1, -1):
		var row := ""
		var empty := 0
		for x in 8:
			var p := Vector2i(x, y)
			if not pieces.has(p):
				empty += 1
			else:
				if empty > 0:
					row += str(empty)
					empty = 0
				var pc: Dictionary = pieces[p]
				row += pc.t if pc.w else String(pc.t).to_lower()
		if empty > 0: row += str(empty)
		ranks.append(row)
	var rights := ""
	for key in ["K", "Q", "k", "q"]:
		if castle_rights[key]: rights += key
	if rights.is_empty(): rights = "-"
	return "%s %s %s %s %d %d" % ["/".join(ranks), "w" if white_turn else "b", rights, square_name(ep_target), halfmove_clock, fullmove_number]

func _king(w: bool, state: Dictionary) -> Vector2i:
	for p in state:
		if state[p].t == "K" and state[p].w == w: return p
	return INVALID

func attacked(target: Vector2i, by_white: bool, state: Dictionary = {}) -> bool:
	var board: Dictionary = pieces if state.is_empty() else state
	var pawn_y := target.y - (1 if by_white else -1)
	for dx in [-1, 1]:
		var p := Vector2i(target.x + dx, pawn_y)
		if board.has(p) and board[p].w == by_white and board[p].t == "P": return true
	for step in KNIGHT_STEPS:
		var p: Vector2i = target + step
		if board.has(p) and board[p].w == by_white and board[p].t == "N": return true
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0: continue
			var p := target + Vector2i(dx, dy)
			if board.has(p) and board[p].w == by_white and board[p].t in ["K", "W"]: return true
	for direction in STRAIGHT + DIAGONAL:
		var p: Vector2i = target + direction
		while _inside(p):
			if board.has(p):
				if board[p].w == by_white:
					var t: String = board[p].t
					if t == "Q" or (t == "R" and direction in STRAIGHT) or (t == "B" and direction in DIAGONAL): return true
				break
			p += direction
	return false

func in_check(w: bool, state: Dictionary = {}) -> bool:
	var board: Dictionary = pieces if state.is_empty() else state
	var pos := _king(w, board)
	return pos != INVALID and attacked(pos, not w, board)

func _move(from: Vector2i, to: Vector2i, promotion: String = "", castle: String = "", ep: bool = false) -> Dictionary:
	return {"from": from, "to": to, "promotion": promotion, "castle": castle, "ep": ep}

func _append_pawn(moves: Array[Dictionary], from: Vector2i, to: Vector2i, ep: bool = false) -> void:
	if to.y == 0 or to.y == 7:
		for kind in PROMOTIONS + (["W"] if allow_warlord else []): moves.append(_move(from, to, kind))
	else:
		moves.append(_move(from, to, "", "", ep))

func _pseudo_from(from: Vector2i, state: Dictionary) -> Array[Dictionary]:
	var moves: Array[Dictionary] = []
	if not state.has(from): return moves
	var pc: Dictionary = state[from]
	var w: bool = pc.w
	match pc.t:
		"P":
			var dir := 1 if w else -1
			var one := from + Vector2i(0, dir)
			if _inside(one) and not state.has(one):
				_append_pawn(moves, from, one)
				var two := from + Vector2i(0, 2 * dir)
				if from.y == (1 if w else 6) and not state.has(two): moves.append(_move(from, two))
			for dx in [-1, 1]:
				var to := from + Vector2i(dx, dir)
				if not _inside(to): continue
				if state.has(to) and state[to].w != w and state[to].t != "K":
					_append_pawn(moves, from, to)
				elif to == ep_target and state.has(Vector2i(to.x, from.y)) and state[Vector2i(to.x, from.y)].t == "P" and state[Vector2i(to.x, from.y)].w != w:
					_append_pawn(moves, from, to, true)
		"N":
			for step in KNIGHT_STEPS:
				var to: Vector2i = from + step
				if _inside(to) and (not state.has(to) or (state[to].w != w and state[to].t != "K")): moves.append(_move(from, to))
		"K", "W":
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					if dx == 0 and dy == 0: continue
					var to := from + Vector2i(dx, dy)
					if _inside(to) and (not state.has(to) or (state[to].w != w and state[to].t != "K")): moves.append(_move(from, to))
			if pc.t == "K" and from == Vector2i(4, 0 if w else 7) and not in_check(w, state):
				var y := from.y
				var king_side := "K" if w else "k"
				if castle_rights[king_side] and state.has(Vector2i(7, y)) and state[Vector2i(7, y)].t == "R" and state[Vector2i(7, y)].w == w and not state.has(Vector2i(5, y)) and not state.has(Vector2i(6, y)) and not attacked(Vector2i(5, y), not w, state) and not attacked(Vector2i(6, y), not w, state):
					moves.append(_move(from, Vector2i(6, y), "", king_side))
				var queen_side := "Q" if w else "q"
				if castle_rights[queen_side] and state.has(Vector2i(0, y)) and state[Vector2i(0, y)].t == "R" and state[Vector2i(0, y)].w == w and not state.has(Vector2i(1, y)) and not state.has(Vector2i(2, y)) and not state.has(Vector2i(3, y)) and not attacked(Vector2i(3, y), not w, state) and not attacked(Vector2i(2, y), not w, state):
					moves.append(_move(from, Vector2i(2, y), "", queen_side))
		_:
			var dirs: Array[Vector2i] = []
			if pc.t in ["R", "Q"]: dirs.append_array(STRAIGHT)
			if pc.t in ["B", "Q"]: dirs.append_array(DIAGONAL)
			for direction in dirs:
				var to: Vector2i = from + direction
				while _inside(to):
					if state.has(to):
						if state[to].w != w and state[to].t != "K": moves.append(_move(from, to))
						break
					moves.append(_move(from, to))
					to += direction
	return moves

func _after_state(state: Dictionary, move: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	var from: Vector2i = move.from
	var to: Vector2i = move.to
	var pc: Dictionary = next[from]
	next.erase(from)
	if move.ep: next.erase(Vector2i(to.x, from.y))
	if not String(move.castle).is_empty():
		var rook_from := Vector2i(7 if to.x == 6 else 0, from.y)
		var rook_to := Vector2i(5 if to.x == 6 else 3, from.y)
		next[rook_to] = next[rook_from]
		next.erase(rook_from)
	if not String(move.promotion).is_empty(): pc.t = move.promotion
	next[to] = pc
	return next

func legal_moves_from(from: Vector2i) -> Array[Dictionary]:
	var result_moves: Array[Dictionary] = []
	if not pieces.has(from): return result_moves
	var w: bool = pieces[from].w
	for move in _pseudo_from(from, pieces):
		if not in_check(w, _after_state(pieces, move)): result_moves.append(move)
	return result_moves

func all_legal_moves(w: bool) -> Array[Dictionary]:
	var moves: Array[Dictionary] = []
	for pos in pieces:
		if pieces[pos].w == w: moves.append_array(legal_moves_from(pos))
	return moves

func find_move(from: Vector2i, to: Vector2i, promotion: String = "Q") -> Dictionary:
	if not pieces.has(from) or pieces[from].w != white_turn or not result.is_empty(): return {}
	for move in legal_moves_from(from):
		if move.to == to and (String(move.promotion).is_empty() or move.promotion == promotion): return move
	return {}

func _position_key() -> String:
	var fen_fields := to_fen().split(" ")
	var ep := "-"
	if ep_target != INVALID:
		for dx in [-1, 1]:
			var from := ep_target + Vector2i(dx, -1 if white_turn else 1)
			if pieces.has(from) and pieces[from].t == "P" and pieces[from].w == white_turn:
				for move in legal_moves_from(from):
					if move.ep: ep = square_name(ep_target)
	return "%s %s %s %s" % [fen_fields[0], fen_fields[1], fen_fields[2], ep]

func _record_position() -> void:
	var key := _position_key()
	repetition[key] = int(repetition.get(key, 0)) + 1

func _dead_position() -> bool:
	var minors := []
	for pos in pieces:
		var t: String = pieces[pos].t
		if t in ["P", "R", "Q", "W"]: return false
		if t in ["N", "B"]: minors.append({"t": t, "square": pos})
	if minors.size() <= 1: return true
	if minors.size() == 2 and minors[0].t == "B" and minors[1].t == "B":
		return (minors[0].square.x + minors[0].square.y) % 2 == (minors[1].square.x + minors[1].square.y) % 2
	return false

func _san_before(move: Dictionary, captured: bool) -> String:
	if not String(move.castle).is_empty(): return "O-O" if move.to.x == 6 else "O-O-O"
	var from: Vector2i = move.from
	var to: Vector2i = move.to
	var t: String = pieces[from].t
	var notation := ""
	if t == "P":
		if captured: notation = "abcdefgh"[from.x]
	else:
		notation = t
		var alternatives: Array[Vector2i] = []
		for other in pieces:
			if other == from or pieces[other].t != t or pieces[other].w != pieces[from].w: continue
			for candidate in legal_moves_from(other):
				if candidate.to == to:
					alternatives.append(other)
					break
		if not alternatives.is_empty():
			var same_file := false
			var same_rank := false
			for other in alternatives:
				if other.x == from.x: same_file = true
				if other.y == from.y: same_rank = true
			if not same_file: notation += "abcdefgh"[from.x]
			elif not same_rank: notation += str(from.y + 1)
			else: notation += "abcdefgh"[from.x] + str(from.y + 1)
	if captured: notation += "x"
	notation += square_name(to)
	if not String(move.promotion).is_empty(): notation += "=" + String(move.promotion)
	return notation

func play_move(from: Vector2i, to: Vector2i, promotion: String = "Q") -> bool:
	var move := find_move(from, to, promotion)
	if move.is_empty(): return false
	var pc: Dictionary = pieces[from]
	var captured: bool = pieces.has(to) or bool(move.ep)
	var san := _san_before(move, captured)
	if pc.t == "K":
		castle_rights["K" if pc.w else "k"] = false
		castle_rights["Q" if pc.w else "q"] = false
	elif pc.t == "R":
		if from == Vector2i(0, 0): castle_rights["Q"] = false
		if from == Vector2i(7, 0): castle_rights["K"] = false
		if from == Vector2i(0, 7): castle_rights["q"] = false
		if from == Vector2i(7, 7): castle_rights["k"] = false
	if to == Vector2i(0, 0): castle_rights["Q"] = false
	if to == Vector2i(7, 0): castle_rights["K"] = false
	if to == Vector2i(0, 7): castle_rights["q"] = false
	if to == Vector2i(7, 7): castle_rights["k"] = false
	pieces = _after_state(pieces, move)
	ep_target = from + Vector2i(0, 1 if pc.w else -1) if pc.t == "P" and abs(to.y - from.y) == 2 else INVALID
	halfmove_clock = 0 if pc.t == "P" or captured else halfmove_clock + 1
	if not white_turn: fullmove_number += 1
	white_turn = not white_turn
	if in_check(white_turn): san += "+"
	var replies := all_legal_moves(white_turn)
	if replies.is_empty():
		if in_check(white_turn):
			result = "black" if white_turn else "white"
			result_reason = "checkmate"
			san = san.trim_suffix("+") + "#"
		else:
			result = "draw"
			result_reason = "stalemate"
	elif _dead_position():
		result = "draw"
		result_reason = "dead position"
	move_log.append(san)
	_record_position()
	return true

func can_claim_draw() -> bool:
	return result.is_empty() and (int(repetition.get(_position_key(), 0)) >= 3 or halfmove_clock >= 100)

func claim_draw() -> bool:
	if not can_claim_draw(): return false
	result = "draw"
	result_reason = "threefold repetition" if int(repetition.get(_position_key(), 0)) >= 3 else "50-move rule"
	return true

func claim_draw_with_move(from: Vector2i, to: Vector2i, promotion: String = "Q") -> bool:
	var move := find_move(from, to, promotion)
	if move.is_empty(): return false
	var probe = get_script().new()
	probe.pieces = pieces.duplicate(true)
	probe.white_turn = white_turn
	probe.castle_rights = castle_rights.duplicate()
	probe.ep_target = ep_target
	probe.halfmove_clock = halfmove_clock
	probe.fullmove_number = fullmove_number
	probe.repetition = repetition.duplicate()
	if not probe.play_move(from, to, promotion): return false
	if int(probe.repetition.get(probe._position_key(), 0)) < 3 and probe.halfmove_clock < 100: return false
	result = "draw"
	result_reason = "intended-move draw claim"
	return true

func agree_draw() -> void:
	if result.is_empty():
		result = "draw"
		result_reason = "agreement"

func resign(white: bool) -> void:
	if result.is_empty():
		result = "black" if white else "white"
		result_reason = "resignation"

func resolve_failed_capture(from: Vector2i, to: Vector2i) -> bool:
	## The defender wins the duel: the attacking piece is removed. This is Chess Duel's variant rule.
	var move := find_move(from, to)
	if move.is_empty() or (not pieces.has(to) and not bool(move.ep)): return false
	var attacker: Dictionary = pieces[from]
	pieces.erase(from)
	if attacker.t == "K":
		castle_rights["K" if attacker.w else "k"] = false
		castle_rights["Q" if attacker.w else "q"] = false
		result = "black" if attacker.w else "white"
		result_reason = "king defeated in duel"
	elif attacker.t == "R":
		if from == Vector2i(0, 0): castle_rights["Q"] = false
		if from == Vector2i(7, 0): castle_rights["K"] = false
		if from == Vector2i(0, 7): castle_rights["q"] = false
		if from == Vector2i(7, 7): castle_rights["k"] = false
	ep_target = INVALID
	halfmove_clock += 1
	if not white_turn: fullmove_number += 1
	white_turn = not white_turn
	if result.is_empty():
		var replies := all_legal_moves(white_turn)
		if replies.is_empty():
			if in_check(white_turn):
				result = "black" if white_turn else "white"
				result_reason = "checkmate"
			else:
				result = "draw"
				result_reason = "stalemate"
		elif _dead_position():
			result = "draw"
			result_reason = "dead position"
	_record_position()
	return true
