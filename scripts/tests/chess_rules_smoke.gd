extends SceneTree
## Legal chess movement and Chess Duel combat-capture variant regression.

const Rules = preload("res://scripts/chess_rules.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: " + label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func has_target(moves: Array[Dictionary], to: Vector2i) -> bool:
	for move in moves:
		if move.to == to: return true
	return false

func run_checks() -> void:
	var r = Rules.new()
	r.reset()
	check(r.to_fen() == "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", "orthodox initial position and FEN")
	var openings: Array[Dictionary] = r.all_legal_moves(true)
	check(openings.size() == 20, "20 legal opening moves")
	var depth_two := 0
	for opening in openings:
		var probe = Rules.new()
		probe.set_fen(r.to_fen())
		probe.play_move(opening.from, opening.to)
		depth_two += probe.all_legal_moves(false).size()
	check(depth_two == 400, "400 legal positions after two plies")
	var depth_three := 0
	for first in openings:
		var after_first = Rules.new()
		after_first.set_fen(r.to_fen())
		after_first.play_move(first.from, first.to)
		var first_fen: String = after_first.to_fen()
		for second in after_first.all_legal_moves(false):
			var after_second = Rules.new()
			after_second.set_fen(first_fen)
			after_second.play_move(second.from, second.to)
			depth_three += after_second.all_legal_moves(true).size()
	check(depth_three == 8902, "8902 legal positions after three plies")
	r.set_fen("4r2k/8/8/8/8/8/4R3/4K3 w - - 0 1")
	check(not has_target(r.legal_moves_from(Vector2i(4, 1)), Vector2i(3, 1)), "pinned rook cannot expose king")
	r.set_fen("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
	check(has_target(r.legal_moves_from(Vector2i(4, 0)), Vector2i(6, 0)) and has_target(r.legal_moves_from(Vector2i(4, 0)), Vector2i(2, 0)), "both castling sides available")
	check(r.play_move(Vector2i(4, 0), Vector2i(6, 0)) and r.pieces[Vector2i(5, 0)].t == "R" and not r.castle_rights.K and not r.castle_rights.Q, "castling relocates rook and revokes rights")
	check(r.move_log[-1] == "O-O", "castling algebraic notation")
	r.set_fen("r3k2r/8/8/8/8/5r2/8/R3K2R w KQkq - 0 1")
	check(not has_target(r.legal_moves_from(Vector2i(4, 0)), Vector2i(6, 0)), "cannot castle through attacked square")
	r.set_fen("4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1")
	check(r.play_move(Vector2i(4, 4), Vector2i(3, 5)) and not r.pieces.has(Vector2i(3, 4)) and r.pieces[Vector2i(3, 5)].t == "P", "en passant removes bypassed pawn")
	check(r.move_log[-1] == "exd6", "en passant algebraic notation")
	r.set_fen("4r2k/8/8/3pP3/8/8/8/4K3 w - d6 0 1")
	check(not has_target(r.legal_moves_from(Vector2i(4, 4)), Vector2i(3, 5)), "en passant cannot expose own king")
	r.set_fen("4k3/P7/8/8/8/8/8/4K3 w - - 0 1")
	var promo := 0
	for move in r.legal_moves_from(Vector2i(0, 6)):
		if move.to == Vector2i(0, 7): promo += 1
	check(promo == 4 and r.play_move(Vector2i(0, 6), Vector2i(0, 7), "N") and r.pieces[Vector2i(0, 7)].t == "N", "promotion has Q/R/B/N choices")
	check(r.move_log[-1].begins_with("a8=N"), "promotion algebraic notation")
	r.set_fen("4k3/8/8/8/8/8/4N1N1/4K3 w - - 0 1")
	check(r.play_move(Vector2i(4, 1), Vector2i(5, 3)) and r.move_log[-1] == "Nef4", "ambiguous knights receive file disambiguation")
	r.reset()
	check(r.play_move(Vector2i(5, 1), Vector2i(5, 2)) and r.play_move(Vector2i(4, 6), Vector2i(4, 4)) and r.play_move(Vector2i(6, 1), Vector2i(6, 3)) and r.play_move(Vector2i(3, 7), Vector2i(7, 3)) and r.result == "black" and r.result_reason == "checkmate", "Fool's Mate ends by checkmate, not king capture")
	check(r.move_log[-1] == "Qh4#", "checkmate algebraic notation")
	r.set_fen("7k/5Q2/6K1/8/8/8/8/8 w - - 0 1")
	check(r.play_move(Vector2i(5, 6), Vector2i(4, 5)) and r.result == "draw" and r.result_reason == "stalemate", "stalemate draw")
	r.set_fen("4k3/8/8/8/8/8/8/4K1B1 w - - 0 1")
	check(r.play_move(Vector2i(6, 0), Vector2i(7, 1)) and r.result == "draw" and r.result_reason == "dead position", "king and bishop versus king is dead position")
	r.set_fen("4k2r/8/8/8/8/8/8/R3K3 w - - 0 1")
	for i in 2:
		r.play_move(Vector2i(0, 0), Vector2i(0, 1))
		r.play_move(Vector2i(7, 7), Vector2i(7, 6))
		r.play_move(Vector2i(0, 1), Vector2i(0, 0))
		r.play_move(Vector2i(7, 6), Vector2i(7, 7))
	check(r.can_claim_draw() and r.claim_draw() and r.result_reason == "threefold repetition", "threefold repetition requires claim")
	r.set_fen("4k2r/8/8/8/8/8/8/R3K3 w - - 99 1")
	check(r.play_move(Vector2i(0, 0), Vector2i(0, 1)) and r.can_claim_draw() and r.claim_draw() and r.result_reason == "50-move rule", "50-move claim after 100 halfmoves")
	r.set_fen("4k2r/8/8/8/8/8/8/R3K3 w - - 0 1")
	for i in 2:
		r.play_move(Vector2i(0, 0), Vector2i(0, 1))
		r.play_move(Vector2i(7, 7), Vector2i(7, 6))
		r.play_move(Vector2i(0, 1), Vector2i(0, 0))
		if i == 0: r.play_move(Vector2i(7, 6), Vector2i(7, 7))
	check(r.claim_draw_with_move(Vector2i(7, 6), Vector2i(7, 7)) and r.result == "draw", "intended third repetition can be claimed")
	r.allow_warlord = true
	r.set_fen("4k3/P7/8/8/8/8/8/4K3 w - - 0 1")
	var warlord_promotion := false
	for move in r.legal_moves_from(Vector2i(0, 6)):
		if move.to == Vector2i(0, 7) and move.promotion == "W": warlord_promotion = true
	check(warlord_promotion and r.play_move(Vector2i(0, 6), Vector2i(0, 7), "W") and r.pieces[Vector2i(0, 7)].t == "W", "Chess Duel Warlord promotion remains legal")
	r.set_fen("4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1")
	check(r.resolve_failed_capture(Vector2i(4, 4), Vector2i(3, 5)) and not r.pieces.has(Vector2i(4, 4)) and r.pieces.has(Vector2i(3, 4)) and not r.white_turn, "defender victory removes attacker in en passant duel")
	r.set_fen("4k3/8/8/8/8/8/4p3/4K3 w - - 0 1")
	check(r.resolve_failed_capture(Vector2i(4, 0), Vector2i(4, 1)) and r.result == "black" and r.result_reason == "king defeated in duel", "king duel loss keeps Chess Duel victory rule")
	print("Chess rules smoke: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
