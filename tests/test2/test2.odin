package test2

import "core:fmt"

import rl "vendor:raylib"
import "../../sl"

print :: fmt.println

console:sl.Console


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
	scale := 1
	GW := 80 * scale
	GH := 50 * scale

	font := sl.new_font("cp437_20x20", 16, 16, "data/fonts/cp437_20x20.png")
	console = sl.new_console(GW, GH, font)//, 5, 5)

	fill_console(console, rl.Color{0, 255, 0, 255})

	sl.console_set_cell(console, 5, 5, '@', rl.GOLD, rl.BLACK)
}

input :: proc() {

}

update :: proc(dt:f32) {
	fill_console(console, rl.Color{0, 255, 0, 255})

	sl.console_set_cell(console, 5, 5, '@', rl.GOLD, rl.BLACK)


	// sl.quick_benchmark_start("update")
	// sl.console_update(console)

	// sl.quick_benchmark_stop("update")
}

render :: proc() {
	sl.quick_benchmark_start("render")

		sl.console_render(console)

	sl.quick_benchmark_stop("render")

}




// frame_start :: proc() {

// }

// frame_end :: proc() {

// }

quit :: proc() {

}

