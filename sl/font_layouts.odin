package sl

import "core:fmt"


@private FontLayout :: struct {
	cols, rows :int,
	indices_by_char:map[rune]u16,
	indices_by_codepoints:map[uint]u16,
	chars_by_index:map[u16]rune,
}



_codepoint_to_index_from_layout :: proc(layout:FontLayout, codepoint : uint) -> u16 {
	return layout.indices_by_codepoints[codepoint]
}

_char_to_index_from_layout :: proc(layout:FontLayout, char:rune) -> u16 {
	return layout.indices_by_char[char]
}

_index_to_char_from_layout :: proc(layout:FontLayout, index:int) -> rune {
	return layout.chars_by_index[u16(index)]
}



_codepoint_to_index_from_layout_name :: proc(name:string, codepoint : uint) -> u16 {
	return _codepoint_to_index_from_layout(_internal.font_layouts[name], codepoint)
}

_char_to_index_from_layout_name :: proc(name:string, char:rune) -> u16 {
	return _char_to_index_from_layout(_internal.font_layouts[name], char)
}

_index_to_char_from_layout_name :: proc(name:string, index:int) -> rune {
	return _index_to_char_from_layout(_internal.font_layouts[name], index)
}




_codepoint_to_index_default :: proc(codepoint : uint) -> u16 {
	using _internal
	return _codepoint_to_index_from_layout(font_layouts[default_font_layout_name], codepoint)
}

_char_to_index_default :: proc(char:rune) -> u16 {
	using _internal
	return _char_to_index_from_layout(font_layouts[default_font_layout_name], char)
}

_index_to_char_default :: proc(index:int) -> rune {
	using _internal
	return _index_to_char_from_layout(font_layouts[default_font_layout_name], index)
}


_layout_codepoint_to_index :: proc { _codepoint_to_index_from_layout_name, _codepoint_to_index_from_layout, _codepoint_to_index_default}
_layout_char_to_index      :: proc { _char_to_index_from_layout_name, _char_to_index_from_layout, _char_to_index_default}
_layout_index_to_char      :: proc { _index_to_char_from_layout_name, _index_to_char_from_layout, _index_to_char_default}




@private _add_font_layout_chars :: proc(name:string, cols, rows:int, glyphs:string) {
	// TODO
}

@private _get_font_layout :: proc(name:string) -> FontLayout {
	if name not_in _internal.font_layouts do fmt.panicf("invalid font layout '%s'", name)
	return _internal.font_layouts[name]
}

@private _add_font_layout_codes :: proc(name:string, cols, rows:int, codepoints:[]uint) {
	indices_by_codepoints := make(map[uint]u16)
	indices_by_char := make(map[rune]u16)
	chars_by_index := make(map[u16]rune)

	for i in 0..<len(codepoints) {
		g := codepoints[i]
		indices_by_codepoints[g]        = u16(i)
		indices_by_char[rune(g)]  = u16(i)
		chars_by_index[u16(i)] = rune(g)
	}

	layout := FontLayout {
		cols = cols,
		rows = rows,
		indices_by_char = indices_by_char,
		indices_by_codepoints = indices_by_codepoints,
		chars_by_index = chars_by_index,
	}
	_internal.font_layouts[name] = layout
}

@private _add_font_layout :: proc { _add_font_layout_chars, _add_font_layout_codes }

@private _destroy_font_layouts :: proc() {
	for k in _internal.font_layouts {
		fl := _internal.font_layouts[k]
		delete(fl.indices_by_char)
		delete(fl.indices_by_codepoints)
		delete(fl.chars_by_index)

	}
	delete(_internal.font_layouts)
}


@private _init_font_layouts :: proc() {
	_cp437_str := " ☺☻♥♦♣♠•◘○◙♂♀♪♫☼►◄↕‼¶§▬↨↑↓→←∟↔▲▼ !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~⌂ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜ¢£¥₧ƒáíóúñÑªº¿⌐¬½¼¡«»░▒▓│┤╡╢╖╕╣║╗╝╜╛┐└┴┬├─┼╞╟╚╔╩╦╠═╬╧╨╤╥╙╘╒╓╫╪┘┌█▄▌▐▀αßΓπΣσµτΦΘΩδ∞φε∩≡±≥≤⌠⌡÷≈°∙·√ⁿ²■□"
	// _cp437_str = "\0☺☻♥♦♣♠•ã○Ã♂♀♪♫☼►◄↕‼¶§▬↨↑↓→←∟↔▲▼ !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~⌂ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜ¢£¥₧ƒáíóúñÑªº¿⌐¬½¼¡«»░▒▓│┤╡╢╖╕╣║╗╝╜╛┐└┴┬├─┼╞╟╚╔╩╦╠═╬╧╨╤╥╙╘╒╓╫╪┘┌█▄▌▐▀αßΓπΣσµτΦΘΩδ∞φε∩≡±≥≤⌠⌡÷≈°∙·√ⁿ²■□"
	// _cp437_str := " 0☺☻♥♦♣♠•◘○◙♂♀♪♫☼" + "►◄↕‼¶§▬↨↑↓→←∟↔▲▼"
	//             + " !\"#$%&'()*+,-./" + "0123456789:;<=>?"
	//             + "@ABCDEFGHIJKLMNO"  + "PQRSTUVWXYZ[\\]^_"
	//             + "`abcdefghijklmno"  + "pqrstuvwxyz{|}~⌂"
	//             + "ÇüéâäàåçêëèïîìÄÅ"  + "ÉæÆôöòûùÿÖÜ¢£¥₧ƒ"
	//             + "áíóúñÑªº¿⌐¬½¼¡«»"  + "░▒▓│┤╡╢╖╕╣║╗╝╜╛┐"
	//             + "└┴┬├─┼╞╟╚╔╩╦╠═╬╧"  + "╨╤╥╙╘╒╓╫╪┘┌█▄▌▐▀"
	//             + "αßΓπΣσµτΦΘΩδ∞φε∩"  + "≡±≥≤⌠⌡÷≈°∙·√ⁿ²■□"

	// NIY
	// _add_font_layout_chars("cp437", 16, 16, _cp437_str)


	/*
		The two first rows below are the same row: use one or the other, not both.
		The first one is the original cp437 row. The second one encodes
		the Ã and ã symbols that don't seem to exist in the original cp437.
		TODO: not sure what to do about this. These symbols replace others...
	*/
	_cp437_codepoints :[]uint = {
	    0x00, 0x263A, 0x263B, 0x2665, 0x2666, 0x2663, 0x2660, 0x2022, 0x25D8, 0x25CB, 0x25D9, 0x2642, 0x2640, 0x266A, 0x266B, 0x263C,
	    // 0x00, 0x263A, 0x263B, 0x2665, 0x2666, 0x2663, 0x2660, 0x2022, 0xe3, 0x25CB, 0xc3, 0x2642, 0x2640, 0x266A, 0x266B, 0x263C,
	    0x25BA, 0x25C4, 0x2195, 0x203C, 0xB6, 0xA7, 0x25AC, 0x21A8, 0x2191, 0x2193, 0x2192, 0x2190, 0x221F, 0x2194, 0x25B2, 0x25BC,
	    0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F,
	    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F,
	    0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F,
	    0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A, 0x5B, 0x5C, 0x5D, 0x5E, 0x5F,
	    0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E, 0x6F,
	    0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x7B, 0x7C, 0x7D, 0x7E, 0x2302,
	    0xC7, 0xFC, 0xE9, 0xE2, 0xE4, 0xE0, 0xE5, 0xE7, 0xEA, 0xEB, 0xE8, 0xEF, 0xEE, 0xEC, 0xC4, 0xC5,
	    0xC9, 0xE6, 0xC6, 0xF4, 0xF6, 0xF2, 0xFB, 0xF9, 0xFF, 0xD6, 0xDC, 0xA2, 0xA3, 0xA5, 0x20A7, 0x0192,
	    0xE1, 0xED, 0xF3, 0xFA, 0xF1, 0xD1, 0xAA, 0xBA, 0xBF, 0x2310, 0xAC, 0xBD, 0xBC, 0xA1, 0xAB, 0xBB,
	    0x2591, 0x2592, 0x2593, 0x2502, 0x2524, 0x2561, 0x2562, 0x2556, 0x2555, 0x2563, 0x2551, 0x2557, 0x255D, 0x255C, 0x255B, 0x2510,
	    0x2514, 0x2534, 0x252C, 0x251C, 0x2500, 0x253C, 0x255E, 0x255F, 0x255A, 0x2554, 0x2569, 0x2566, 0x2560, 0x2550, 0x256C, 0x2567,
	    0x2568, 0x2564, 0x2565, 0x2559, 0x2558, 0x2552, 0x2553, 0x256B, 0x256A, 0x2518, 0x250C, 0x2588, 0x2584, 0x258C, 0x2590, 0x2580,
	    0x03B1, 0xDF, 0x0393, 0x03C0, 0x03A3, 0x03C3, 0xB5, 0x03C4, 0x03A6, 0x0398, 0x03A9, 0x03B4, 0x221E, 0x03C6, 0x03B5, 0x2229,
	    0x2261, 0xB1, 0x2265, 0x2264, 0x2320, 0x2321, 0xF7, 0x2248, 0xB0, 0x2219, 0xB7, 0x221A, 0x207F, 0xB2, 0x25A0, 0x25a1,
	}

	_add_font_layout_codes("cp437", 16, 16, _cp437_codepoints)
}
