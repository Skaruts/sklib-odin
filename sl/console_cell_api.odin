package sl

import "core:fmt"
import "core:strings"
import "core:unicode/utf8"
import "core:math"
import rl "vendor:raylib"
// import "sl"

@private _console_is_in_inbounds :: proc(c:Console, x, y:int) -> bool {
	return x >= 0 && x < c.w && y >= 0 && y < c.h
}

@private _console_get_cell_size :: proc(c:Console) -> (int, int) {
	CW := c._cw > 0 ? c._cw : c.font.cw
	CH := c._ch > 0 ? c._ch : c.font.ch
	return CW, CH
}


@private _get_glyph :: proc(c:Console, idx:int) -> rune {
	glyph_index := int(c._new_cells.glyphs[u16(idx)])
	return _console_index_to_char(c, glyph_index)
}
@private _get_fg    :: proc(c:Console, idx:int) -> rl.Color { return c._new_cells.fgs[idx]    }
@private _get_bg    :: proc(c:Console, idx:int) -> rl.Color { return c._new_cells.bgs[idx]    }

// @private _set_glyph :: proc(c:Console, idx:int, glyph:Maybe(u16)) {
@private _set_glyph :: proc(c:Console, idx:int, glyph:u16) {
	// if g, ok := glyph.?; ok do
		c._new_cells.glyphs[idx] = glyph
}


@private _set_fg :: proc(c:Console, idx:int, fg:Maybe(rl.Color)) {
	if f, ok := fg.?; ok do c._new_cells.fgs[idx] = f
}

@private _set_bg :: proc(c:Console, idx:int, bg:Maybe(rl.Color)) {
	if f, ok := bg.?; ok do c._new_cells.bgs[idx] = f
}


console_clear :: proc(c:Console) {
	for i in 0..<c.w*c.h {
		_set_glyph(c, i, 0)
		_set_fg(c, i, rl.WHITE)
		_set_bg(c, i, rl.BLACK)
	}
}


/*******************************************************************************

		get

*/
console_get_cell :: proc(c:Console, x, y:int) -> (rune, rl.Color, rl.Color) {
	idx := x+y*c.w
	return _get_glyph(c, idx), _get_fg(c, idx), _get_bg(c, idx)
}

// console_get_char :: proc(c:Console, x, y, glyph:int) -> int {
// 	return _get_glyph(c, x+y*c.w)
// }

console_get_fg :: proc(c:Console, x, y:int, fg:rl.Color) -> rl.Color {
	return _get_fg(c, x+y*c.w)
}

console_get_bg :: proc(c:Console, x, y:int, bg:rl.Color) -> rl.Color {
	return _get_bg(c, x+y*c.w)
}








_console_codepoint_to_index :: proc(c:Console, code:uint) -> u16 {
	return _layout_codepoint_to_index(c._font_layout, code)
}

_console_char_to_index :: proc(c:Console, char:rune) -> u16 {
	return _layout_char_to_index(c._font_layout, char)
}

_console_index_to_char :: proc(c:Console, index:int) -> rune {
	return _layout_index_to_char(c._font_layout, index)
}


/*******************************************************************************

		set



	TODO: might be able to do some overloading with a union, eg:

		Glyph :: Union { int, rune }
		console_set_cell :: proc(c:Console, x, y:int, glyph:Glyph, ...) {
			// now determine if it's a rune or int
			switch v in glyph {
				case int:       get_char_from_int(c, glyph) // this proc doesn't exist yet
				case rune:		_console_char_to_index(c, glyph)
			}
		}

*/

@private _console_set_rune :: proc(c:Console, x, y:int, glyph:rune, fg:Maybe(rl.Color)=nil, bg:Maybe(rl.Color)=nil) {
	_console_set_index(c, x, y, int(_console_char_to_index(c, glyph)), fg, bg)
}

@private _console_set_index :: proc(c:Console, x, y:int, glyph:Maybe(int)=nil, fg:Maybe(rl.Color)=nil, bg:Maybe(rl.Color)=nil) {
	idx := x+y*c.w

	if g, ok := glyph.?; ok {
		_set_glyph(c, idx, u16(g))
	}

	_set_fg(c, idx, fg)
	_set_bg(c, idx, bg)
}

console_set_cell :: proc {_console_set_rune, _console_set_index}


// console_set_char :: proc(c:Console, x, y, glyph:int) {
// 	_set_glyph(c, x+y*c.w, glyph)
// }

console_set_fg :: proc(c:Console, x, y:int, fg:rl.Color) {
	_set_fg(c, x+y*c.w, fg)
}

console_set_bg :: proc(c:Console, x, y:int, bg:rl.Color) {
	_set_bg(c, x+y*c.w, bg)
}

console_print :: proc(c:Console, x, y:int, text:string, fg:rl.Color, bg:rl.Color) {
	if y < 0 || y >= c.h do return

	length := strings.rune_count(text)
	if x + length < 0 || x >= c.w do return

	runes := utf8.string_to_runes(text, context.temp_allocator)

	for i in 0..<len(runes) {
		xi := x + i
		if xi < 0 do continue // probably redundant
		if xi >= c.w do break
		idx := xi+y*c.w

		// TODO: layout shouldn't be hardcoded
		// glyph := _internal.font_layouts["cp437"].chars[ runes[i] ]
		glyph := _console_char_to_index(c, runes[i])

		_set_glyph(c, idx, glyph)
		_set_fg(c, idx, fg)
		_set_bg(c, idx, bg)
	}
}
