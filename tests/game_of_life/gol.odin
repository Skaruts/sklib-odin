package gol

import "core:fmt"
import "core:math"
import rl "vendor:raylib"
import "../../sl"


GW :: 256 // 400 //  480
GH :: 153 // 220 //  270

paused : bool
console : sl.Console

init :: proc() {
	sl.window_set_title("Simple Game Of Life (sklib-Odin)")
	sl.window_set_target_fps(0)

	sl.bind("randomize",   {"r"})
	sl.bind("pause",       {"space"})
	sl.bind("next_gen",    {"g"})
	sl.bind("clear",       {"c"})
	sl.bind("prev_char",   {"left"})
	sl.bind("next_char",   {"right"})

	font := sl.new_font("data/fonts/Kein_5x5.png")
	console = sl.new_console(GW, GH, font)//, 3, 3)

	life_init()
	life_randomize_cells()
}

input :: proc(event : sl.InputEvent) {
	if      sl.action_down(event, "randomize") do life_randomize_cells()
	else if sl.action_pressed(event, "pause")  do paused = !paused
	else if sl.action_down(event, "next_gen")  { if paused do life_compute_gen() }
	else if sl.action_pressed(event, "clear")  do life_clear_grid()
	else if sl.action_down(event, "prev_char")  {
		glyph_index = math.floor_mod((glyph_index-1), 256)
		sl.print(glyph_index)
	}
	else if sl.action_down(event, "next_char")  {
		glyph_index = math.floor_mod((glyph_index+1), 256)
		sl.print(glyph_index)
	}
}

update :: proc(dt:f32) {
	mpos := sl.console_get_mouse_position(console)

	if      rl.IsMouseButtonDown(.LEFT) do life_set_cell(int(mpos.x), int(mpos.y))
	else if rl.IsMouseButtonDown(.RIGHT) do life_erase_cell(int(mpos.x), int(mpos.y))

	sl.console_clear(console)
	if !paused do life_compute_gen()
	life_draw_grid()
}

render :: proc() {
	sl.console_render(console)
	rl.DrawFPS(10, 10)
}

quit :: proc() {
	life_destroy()
}






/*******************************************************************************

	Life stuff


	Simplest life algorithm

		- iterates the entire array to apply rules
		- swaps borders to avoid checking bounds
		- alternates between two boards to avoid slow copying

*/


ALIVE :: 1
DEAD  :: 0

curr  := 1
prev  := 0
alive_color   := rl.GREEN
// dead_color    := rl.Color{16, 10, 6, 255}
wrap_around := true
glyph_index := 64                       // the glyph used to represent living cells

cells    : [2][][]int


life_init :: proc() {
	sl.info("initing SIMPLE algorithm")
	life_create_cells()
}

life_inbounds :: proc(x, y:int) -> bool {
	// keep in mind the 1 cell border all around
	return x > 0 && x < GW-1 && y > 0 && y < GH-1
}

life_destroy :: proc() {
	for j in 0 ..< GH {
		delete(cells[0][j])
		delete(cells[1][j])
	}
	delete(cells[0])
	delete(cells[1])
}

life_create_cells :: proc() {
	s1 := make([][]int, GH)
	s2 := make([][]int, GH)
	for j in 0 ..<GH {
		s1[j] = make([]int, GW)
		s2[j] = make([]int, GW)
	}

	cells = [2][][]int{s1, s2}

	if wrap_around {
		/*
			Since I use row-major order, the horizontal borders (top & bottom)
			only need to be swapped once here.
			So the arrays at 0 and GH are actually the same array, and so
			are 1 and GH-1.
		*/
		delete(cells[0][GH-1] )
		delete(cells[0][0]    )  // gotta get rid of these
		delete(cells[1][GH-1] )  // or there's gonna be memory leaks
		delete(cells[1][0]    )

		cells[0][GH-1] = cells[0][1]
		cells[0][0]    = cells[0][GH-2]

		cells[1][GH-1] = cells[1][1]
		cells[1][0]    = cells[1][GH-2]
	}
}


/***************************************************
		Compute Generation
*/
life_compute_gen :: proc() {
	curr, prev = prev, curr
	p := cells[prev]
	c := cells[curr]

	l, r, u, d:int
	n:int // alive neighbor count

	for j in 1..<GH-1 {
		u, d = j-1, j+1
		for i in 1..<GW-1 {
			l, r = i-1, i+1

			n = (		// seems parentesis are needed for this ?!
				p[u][l]
			  + p[u][i]
			  + p[u][r]
			  + p[j][l]
			  + p[j][r]
			  + p[d][l]
			  + p[d][i]
			  + p[d][r]
			)

			c[j][i] = (n==3 || (n==2 && p[j][i]==1)) ? ALIVE : DEAD
		}
	}

	if wrap_around do _swap_borders()
}




/***************************************************
		Rendering
*/
life_draw_grid :: proc() {
	c := cells[curr]
	for j in 1..<GH-1 {
		for i in 1..<GW-1 {
			// sl.print(glyph_index)
			if bool(c[j][i]) do sl.console_set_cell(console, i, j, glyph_index, alive_color)
		}
	}

	// TODO: add a way to turn this off without leaving a blank border
	_draw_border_cells()
}


_draw_border_cells :: proc() {
	c := cells[curr]

	for j in 0..<GH {
		if bool(c[j][0])    do sl.console_set_cell(console, 0, j, glyph_index, rl.RED)
		if bool(c[j][GW-1]) do sl.console_set_cell(console, GW-1, j, glyph_index, rl.RED)
	}

	for i in 0..<GW {
		if bool(c[0][i])    do sl.console_set_cell(console, i, 0, glyph_index, rl.RED)
		if bool(c[GH-1][i]) do sl.console_set_cell(console, i, GH-1, glyph_index, rl.RED)
	}
}



_swap_borders :: proc() {
	c := cells[curr]

	for j in 0..<GH {
		cj := c[j]
		cj[ 0  ] = cj[GW-2]
		cj[GW-1] = cj[ 1  ]
	}

	// no need to swap vertical borders when using slices
	// c[GH-1] = c[1]
	// c[0]    = c[GH-2]
}

life_set_cell :: proc(x, y:int) {
	if !life_inbounds(x, y) do return

	cy := cells[curr][y]
	cy[x] = ALIVE

	// update vertical borders
	if x ==  1   do cy[GW-1] = ALIVE
	if x == GW-2 do cy[ 0  ] = ALIVE
}

life_erase_cell :: proc(x, y:int) {
	if !life_inbounds(x, y) do return

	cy := cells[curr][y]
	cy[x] = DEAD

	// update vertical borders
	if x ==  1   do cy[GW-1] = DEAD
	if x == GW-2 do cy[ 0  ] = DEAD
}

life_randomize_cells :: proc() {
	c := cells[curr]

	life_clear_grid(DEAD)

	for j in 1..<GH-1 {
		for i in 1..<GW-1 {
			alive := sl.randf() < 0.5
			c[j][i] = alive ? ALIVE : DEAD
		}
	}
}

life_fill_grid :: proc() {
	life_clear_grid(ALIVE)
}


life_clear_grid :: proc(val:=DEAD) {
	c := cells[curr]

	for j in 0..<GH {
		for i in 0..<GW {
			c[j][i] = val
		}
	}
}

