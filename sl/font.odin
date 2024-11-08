package sl

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

import "utils"

Font :: struct {
	name : string,
	w, h:int,
	cols, rows:int,
	cw, ch: int,
	texture:rl.Texture,
	layout:string,
}

// TODO: should this account for both BLACK and PINK backgrounds?
@private _load_font_texture :: proc(filename:string) -> rl.Texture2D {
	img := rl.LoadImage(utils.str_to_cstr(filename))

	if img.data == nil {
		fmt.panicf("couldn't load image at '%s'", filename)
	}

	if img.format != .UNCOMPRESSED_R8G8B8A8 {
		rl.ImageFormat(&img, .UNCOMPRESSED_R8G8B8A8)
	}

	// make img transparent around the glyphs, if needed.
	col := rl.GetImageColor(img, 0, 0) // this should be called 'ImageGetPixel', but ok...
	if col != rl.BLANK do rl.ImageColorReplace(&img, col, {0,0,0,0})

	tex := rl.LoadTextureFromImage(img)

	rl.UnloadImage(img)
	return tex
}

@private _font_init_filepath :: proc(filename:string, layout_name:=_internal.default_font_layout_name) -> Font {
	return _font_init_all_args("", filename, layout_name)
}

// @private font_init :: proc(name:string, cols, rows:int, texture:rl.Texture, void_char:int = 0) -> Font {
@private _font_init_all_args :: proc(name:string, filename:string, layout_name:=_internal.default_font_layout_name) -> Font {
	layout := _get_font_layout(layout_name)

	tex := _load_font_texture(filename)
	cw := int(tex.width)/layout.cols
	ch := int(tex.height)/layout.rows

	ts := Font {
		name      = name != "" ? name : "Unnamed Font",
		cols      = layout.cols,
		rows      = layout.rows,
		texture   = tex,
		cw        = cw,
		ch        = ch,
		layout    = layout_name,
	}

	return ts
}

@private _font_init :: proc { _font_init_filepath, _font_init_all_args }
