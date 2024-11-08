package test2

import "core:fmt"
import rl "vendor:raylib"
import "../../sl"

print :: fmt.println

Entity :: struct {
	pos    : rl.Vector2,
	char   : rune,
	fg, bg : rl.Color,
}


console:sl.Console
paused := true

player := Entity { char = '@', fg = rl.GOLD, bg = rl.GREEN }

player_moved    := false
should_redraw   := true
move_dir   := sl.vec2()


fill_console :: proc(c:sl.Console, col:=rl.WHITE) {
	bg :: rl.BLACK // rl.Color{0,0,64,255}

	for j in 0..<int(c.h) {
		for i in 0..<int(c.w) {
			glyph:int = sl.randi(255)
			fg := rl.Color{
				u8(sl.randi(int(col.r))),
				u8(sl.randi(int(col.g))),
				u8(sl.randi(int(col.b))),
				// u8(f32(255) * f32(col.a/255)),
				255,
			}
			// fmt.println(fg)
			sl.console_set_cell(c, i, j, glyph, fg, bg)
		}
	}
}

init :: proc() {
	sl.window_set_title("Console Stress Tests (sklib-Odin)")
	sl.window_set_target_fps(0)

	scale := 1
	GW := 80 * scale
	GH := 50 * scale

	sl.bind("move_up",    {"w", "up",    "i", "kp_8", "kp_7", "kp_9" })
	sl.bind("move_down",  {"s", "down",  "k", "kp_2", "kp_1", "kp_3" })
	sl.bind("move_left",  {"a", "left",  "j", "kp_4", "kp_7", "kp_1" })
	sl.bind("move_right", {"d", "right", "l", "kp_6", "kp_9", "kp_3" })

	sl.bind("pause", {"space"})
	sl.bind("step", {"g"})

	font := sl.new_font("data/fonts/cp437_18x18.png")
	console = sl.new_console(GW, GH, font)//, 5, 5)

	fill_console(console, rl.Color{0, 0, 255, 255})

	sl.console_set_cell(console, 5, 5, '@', rl.GOLD, rl.GREEN)
}

frame_start :: proc() {
	// sl.console_clear(console)
}

input :: proc(event: sl.InputEvent) {
	if sl.action_down(event, "move_left")  do move_dir.x -= 1
	if sl.action_down(event, "move_right") do move_dir.x += 1
	if sl.action_down(event, "move_up")    do move_dir.y -= 1
	if sl.action_down(event, "move_down")  do move_dir.y += 1

	if sl.action_down(event, "pause")  do paused = !paused
	if sl.action_down(event, "step")  do fill_console(console, rl.Color{0, 0, 255, 255})
}

update :: proc(dt:f32) {
	if move_dir != sl.vec2() {
		player.pos += move_dir
		player_moved = true
	}
	move_dir = sl.vec2()
	// sl.console_clear(console)
	// if !player_moved && !should_redraw do return



	if !paused {
		fill_console(console, rl.Color{0, 0, 255, 255})
	}


	pos := player.pos
	sl.console_set_cell(console, int(pos.x), int(pos.y), player.char, player.fg, player.bg)
}

render :: proc() {
	// sl.quick_benchmark_start("render")

		sl.console_render(console)

	// sl.quick_benchmark_stop("render")
	rl.DrawFPS(10, 10)
}




// frame_start :: proc() {

// }

// frame_end :: proc() {

// }

quit :: proc() {

}

