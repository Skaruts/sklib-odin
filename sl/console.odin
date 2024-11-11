package sl

import "core:fmt"
import rl "vendor:raylib"
// import "console"
import "utils"


DEF_GLYPH :: 0
DEF_FG    :: rl.Color{}
DEF_BG    :: rl.Color{}


Cells :: struct {
	glyphs : []u16,
	fgs    : []rl.Color,
	bgs    : []rl.Color,
}

Vertex :: struct {
	pos   : rl.Vector2,
	color : rl.Color,
	uv    : rl.Vector2,
}

Quads :: struct {
	bg : []Vertex,  // background quads (the color around text characters)
	fg : []Vertex,  // foreground quads (text characters)
}

RenderType :: enum {
	QuadRender,
	TextureRender,
	ShaderRender,
}

Console :: struct {
	x, y, w, h  : int,
	font        : Font,

	_id         : uint,
	_cw, _ch    : int,

	_font_layout : FontLayout,
	// _clip_area   : Rect,   // area to clip drawing (like scizzoring)
	_is_updated  : bool,

	_render_type : RenderType,

	_new_cells  : Cells,
	_old_cells  : Cells,


	/*	quad renderering stuff (slow af)		*/
	_quads      : Quads,


	/*	texture rendering stuff (slow af)		*/
	_glyph_rects   : [256]rl.Rectangle,   // precomputed texture rects
	_render_tex    : rl.RenderTexture2D,
	_render_tex_fg : rl.RenderTexture2D,

	_flip_rect_src : rl.Rectangle,    // for vertically flipping
	_flip_rect_dst : rl.Rectangle,    // the render texture
	_origin_vec    : rl.Vector2,      // on render


	/*	shader rendering stuff (not working)		*/
	_shader        : rl.Shader,
	_shader_tex    : rl.Texture2D,
	_bg_tex        : rl.Texture2D,
	_fg_tex        : rl.Texture2D,
	_chr_tex       : rl.Texture2D,
	_bg_img        : rl.Image,
	_fg_img        : rl.Image,
	_chr_img       : rl.Image,
	_grid_size     : rl.Vector2,
	_font_size     : rl.Vector2,  // vec2(c.font.cols, c.font.rows)
}



// TODO: allow users to choose rendering type
@private _init_console :: proc(render_type:RenderType, w, h:int, font:Font, cw:Maybe(int)=nil, ch:Maybe(int)=nil) -> Console {
	assert(w > 0 && h > 0, "Console width and height must be greater than zero")

	c := Console {
		_id = utils.next_id(),
		w = w,
		h = h,
		font = font,
		_font_layout = _internal.font_layouts[font.layout],

		_render_type = render_type,
	}

	c._new_cells = Cells {
		make([]u16,      w*h),
		make([]rl.Color, w*h),
		make([]rl.Color, w*h),
	}

	c._old_cells = Cells {
		make([]u16,      w*h),
		make([]rl.Color, w*h),
		make([]rl.Color, w*h),
	}

	if _cw, ok := cw.?; ok do c._cw = _cw
	else                   do c._cw = c.font.cw
	assert(c._cw > 0, "Console cell width override must be greater than zero")
	if _ch, ok := ch.?; ok do c._ch = _ch
	else                   do c._ch = c.font.ch
	assert(c._ch > 0, "Console cell height override must be greater than zero")

	switch c._render_type {
		case .QuadRender:    _console_init_quads(&c)
		case .TextureRender: _console_init_render_tex(&c)
		case .ShaderRender:  _console_init_shader_rendering(&c)
	}

	// make sure old_cells are different from new_cells
	for i in 0..<c.w*c.h {
		c._old_cells.glyphs[i] = 255
		c._old_cells.fgs[i] = rl.PINK
		c._old_cells.bgs[i] = rl.PINK
	}
	console_clear(c)

	return c
}

@private _destroy_console :: proc(c:Console) {
	delete(c._new_cells.glyphs)
	delete(c._new_cells.fgs)
	delete(c._new_cells.bgs)

	delete(c._old_cells.glyphs)
	delete(c._old_cells.fgs)
	delete(c._old_cells.bgs)

	#partial switch c._render_type {
		case .QuadRender:
			delete(c._quads.bg)
			delete(c._quads.fg)
		// case .TextureRender:
		case .ShaderRender:
			rl.UnloadShader(c._shader)
			rl.UnloadTexture(c._shader_tex)
			rl.UnloadTexture(c._bg_tex)
			rl.UnloadTexture(c._fg_tex)
			rl.UnloadTexture(c._chr_tex)
			rl.UnloadImage(c._bg_img)
			rl.UnloadImage(c._fg_img)
			rl.UnloadImage(c._chr_img)
	}
}


console_update :: proc(c:Console) {
	c := c
	if c._is_updated do return
	c._is_updated = true

	switch c._render_type {
		case .QuadRender:    _console_update_quads(&c)
		case .TextureRender: _console_update_tex_rendering(&c)
		case .ShaderRender:  _console_update_shader_rendering(&c)
	}
}

console_render :: proc(c:Console) {
	c := c

	if !c._is_updated do console_update(c)

	switch c._render_type {
		case .QuadRender:    _console_render_quads(&c)
		case .TextureRender: _render_using_tex(&c)
		case .ShaderRender:  _console_render_shader(&c)
	}

	c._is_updated = false
}






