package rune_tests

import "core:fmt"
import rl "vendor:raylib"
import "../../sl"


console:sl.Console


fill_console :: proc(c:sl.Console, col:=rl.WHITE) {
	bg :: rl.BLACK // rl.Color{0,0,64,255}
	for j in 0..<c.h {
		for i in 0..<c.w {
			g:int = sl.randi(255)
			fg := rl.Color{
				u8(f32(sl.randi(255)) * f32(col.r/255)),
				u8(f32(sl.randi(255)) * f32(col.g/255)),
				u8(f32(sl.randi(255)) * f32(col.b/255)),
				u8(f32(255) * f32(col.a/255)),
			}
			// fmt.println(fg)
			sl.console_set_cell(c, i, j, g, fg, bg)
		}
	}
}


init :: proc() {
	font := sl.new_font("data/fonts/cp437_20x20.png")
	console = sl.new_console(80, 50, font)//, 20, 20)

	// console = sl.new_console("tex", 10, 10)
	// console.x = 2
	// console.y = 3
	// fmt.println("app\t\t\t", console)

	// sl.console_set_cell(console, 10, 10, 64, rl.GOLD)

	fill_console(console, rl.Color{0, 255, 0, 255})
	// sl.console_print(console, 10, 10, "à", rl.GOLD, rl.BLACK)

	cp437_chars : []string = {
		" ☺☻♥♦♣♠•◘○◙♂♀♪♫☼",
		"►◄↕‼¶§▬↨↑↓→←∟↔▲▼",
		" !\"#$%&'()*+,-./",
		"0123456789:;<=>?",
		"@ABCDEFGHIJKLMNO",
		"PQRSTUVWXYZ[\\]^_",
		"`abcdefghijklmno",
		"pqrstuvwxyz{|}~⌂",
		"ÇüéâäàåçêëèïîìÄÅ",
		"ÉæÆôöòûùÿÖÜ¢£¥₧ƒ",
		"áíóúñÑªº¿⌐¬½¼¡«»",
		"░▒▓│┤╡╢╖╕╣║╗╝╜╛┐",
		"└┴┬├─┼╞╟╚╔╩╦╠═╬╧",
		"╨╤╥╙╘╒╓╫╪┘┌█▄▌▐▀",
		"αßΓπΣσµτΦΘΩδ∞φε∩",
		"≡±≥≤⌠⌡÷≈°∙·√ⁿ²■□",
	}

	y := 0
	for s in cp437_chars {
		sl.console_print(console, 30, 10+y, s, rl.GOLD, rl.BLACK)
		y += 1
	}

	idx := 0
	for j in 0..<16 {
		for i in 0..<16 {
			// sl.console_set_cell(console, i, j, rune(), rl.BLUE, rl.DARKBLUE)
			sl.console_set_cell(console, 10+i, 10+j, idx, rl.GOLD)
			idx += 1
		}
	}
	sl.console_set_cell(console, 5, 5, 'à', rl.GOLD)
}

input :: proc(event: sl.InputEvent) {

}

update :: proc(dt:f32) {
	// sl.quick_benchmark_start("update")
	// // fmt.println("update\t\t\t", console)

	// fill_console(console)
	// fill_console(console, rl.Color{0, 255, 0, 255})
	sl.console_update(console)

	// sl.quick_benchmark_stop("update")

}

render :: proc() {
	// sl.quick_benchmark_start("render")

		sl.console_render(console)

	// sl.quick_benchmark_stop("render")

}




// frame_start :: proc() {

// }

// frame_end :: proc() {

// }

quit :: proc() {

}

