extends Control
var stage := 0
var elapsed := 0.0
const COLORS := [Color("b8efad"), Color("ff752b"), Color("e5b26b"), Color("fff0a8"), Color("c5f4ff")]
func _process(delta: float) -> void:
	if is_visible_in_tree():
		elapsed += delta
		queue_redraw()
func _draw() -> void:
	var tint: Color = COLORS[stage]
	for i in range(34):
		var seed_x := fposmod(sin(float(i)*127.1)*43758.5, 1.0)
		var seed_y := fposmod(sin(float(i)*311.7)*23561.7, 1.0)
		var direction := -1.0 if stage == 1 else 1.0
		var y := fposmod(seed_y*size.y+elapsed*direction*(15.0+float(i%5)*9.0), maxf(size.y,1.0))
		var x := fposmod(seed_x*size.x+sin(elapsed*0.7+float(i))*18.0,maxf(size.x,1.0))
		var a := 0.18+0.22*(0.5+0.5*sin(elapsed*2.0+float(i)))
		var p := Vector2(x,y)
		if stage == 4:
			for j in range(3):
				var d := Vector2.from_angle(float(j)*PI/3.0)*3.0
				draw_line(p-d,p+d,Color(tint,a),1.0,true)
		else:
			draw_circle(p,1.0+float(i%3),Color(tint,a))
