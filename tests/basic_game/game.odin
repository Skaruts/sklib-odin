package basic_game

import "core:fmt"
import rl "vendor:raylib"
import "../../sl"



print :: fmt.println

GW :: 80
GH :: 50


TileType :: enum { Floor, Wall }

Tile :: struct {
	type        : TileType,
	char        : rune,
	fg, bg      : rl.Color,
	walkable    : bool,
	transparent : bool,
	explored    : bool,
}

GameMap :: struct {
	w, h   : int,
	tiles  : []Tile,
	fovmap : sl.FovMap,
}

Entity :: struct {
	pos    : rl.Vector2,
	char   : rune,
	fg, bg : rl.Color,
}


console : sl.Console
gmap    : GameMap

player := Entity { char = '@', fg = rl.GOLD, bg = rl.BLACK }
enemy  := Entity { char = 'E', fg = rl.BLUE, bg = rl.BLACK }

move_dir := sl.vec2()
player_moved := false
should_redraw := true

fov_radius := 15
tile_darken_percent := 0.7
show_fog_of_war := true



new_tile :: proc(type:TileType, char:rune, fg, bg:rl.Color,
				walkable, transparent:bool) -> Tile {
	return Tile {
		type        = type,
		char        = char,
		fg          = fg,
		bg          = bg,
		walkable    = walkable,
		transparent = transparent,
		explored    = false,
	}
}

init_map :: proc() {
	gmap = GameMap {
		w = GW,
		h = GH,
	}

	gmap.tiles = make([]Tile, gmap.w*gmap.h)
	gmap.fovmap = sl.fov_new(gmap.w, gmap.h)

	for j in 0..<gmap.h {
		for i in 0..<gmap.w {
			idx := i+j*gmap.w
			is_border_or_pillar := sl.randf() < 0.07 || i == 0 || j == 0 || i == gmap.w-1 || j == gmap.h-1

			if is_border_or_pillar {
				gmap.tiles[idx] = new_tile(TileType.Wall, '#', rl.DARKBROWN, rl.BLACK, false, false)
			} else {
				gmap.tiles[idx] = new_tile(TileType.Floor, sl.index_to_char(215), rl.DARKBROWN, rl.BROWN, true, true)
			}
		}
	}
}

init_fov :: proc() {
	for j in 0..<gmap.h {
		for i in 0..<gmap.w {
			tile := gmap.tiles[i+j*gmap.w]
			sl.fov_set_cell(&gmap.fovmap, i, j, tile.transparent, tile.walkable)
		}
	}
}

can_move :: proc(pos:rl.Vector2) -> bool {
	return gmap.tiles[int(pos.x+pos.y*f32(gmap.w))].walkable
}

compute_fov :: proc() {
	pos := player.pos
	sl.fov_compute(&gmap.fovmap, pos, fov_radius, sl.FovType.Restrictive)
	// sl.print2d(gmap.fovmap.grid, GW, GH, proc(c:sl.FovCell) -> bool {return c.visible})
}

// TODO: check if 'show_fog_of_war' conditions are set up correctly
draw_tiles :: proc() {
	for j in 0..<gmap.h {
		for i in 0..<gmap.w {
			tile := &gmap.tiles[i+j*gmap.w]
			in_fov := sl.fov_is_visible(gmap.fovmap, i, j) || !show_fog_of_war

			if in_fov {
				if !tile.explored do tile.explored = true
				sl.console_set_cell(console, i, j, tile.char, tile.fg, tile.bg)
			} else if tile.explored || !show_fog_of_war {
				fg := sl.color_darkened(tile.fg, tile_darken_percent)
				bg := sl.color_darkened(tile.bg, tile_darken_percent)
				sl.console_set_cell(console, i, j, tile.char, fg, bg)
			}
		}
	}
}



/*******************************************************************************

			Loop

*/
init :: proc() {
	sl.window_set_title("Basic Game Example (sklib-Odin)")
	// sl.window_set_target_fps(0)

	sl.bind("foo", {"space", "lctrl d", "rctrl c"})  // input tests

	sl.bind("move_up",    {"w", "up",    "i", "kp_8"})
	sl.bind("move_down",  {"s", "down",  "k", "kp_2"})
	sl.bind("move_left",  {"a", "left",  "j", "kp_4"})
	sl.bind("move_right", {"d", "right", "l", "kp_6"})

	font := sl.new_font("data/fonts/cp437_18x18.png")
	console = sl.new_console(GW, GH, font)//, 10, 10)

	init_map()
	init_fov()

	player.pos = rl.Vector2 {GW/2, GH/2}
	enemy.pos  = rl.Vector2 {GW/2-3, GH/2}
}

input :: proc(event : sl.InputEvent) {
	if sl.action_down(event, "foo") do sl.printn("foo")

	if sl.action_down(event, "move_left")  do move_dir.x -= 1
	if sl.action_down(event, "move_right") do move_dir.x += 1
	if sl.action_down(event, "move_up")    do move_dir.y -= 1
	if sl.action_down(event, "move_down")  do move_dir.y += 1
}

update :: proc(dt:f32) {
	if move_dir != sl.vec2() && can_move(player.pos + move_dir) {
		player.pos += move_dir
		player_moved = true
	}
	move_dir = sl.vec2()

	if !player_moved && !should_redraw do return

	sl.console_clear(console)

	compute_fov()
	draw_tiles()

	sl.console_set_cell(console, int(player.pos.x), int(player.pos.y), player.char, player.fg, player.bg)
	sl.console_set_cell(console, int(enemy.pos.x), int(enemy.pos.y), enemy.char, enemy.fg, enemy.bg)

	player_moved = false
	should_redraw = false
}

render :: proc() {
	// sl.quick_benchmark_start("render")
	sl.console_render(console)
	// sl.quick_benchmark_stop("render")
	rl.DrawFPS(10, 10)
}

quit :: proc() {
	delete(gmap.tiles)
	// print("game - len: ", len(gmap.fovmap._circle_mask.grid))
}
