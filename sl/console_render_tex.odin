package sl

import rl "vendor:raylib"


@private init_rects :: proc(c:^Console) {
	for j in 0..<c.font.rows {
		for i in 0..<c.font.cols {
			c._glyph_rects[i+j*c.font.cols] = rl.Rectangle{f32(i*c._cw), f32(j*c._ch), f32(c._cw), f32(c._ch)}
		}
	}
}


@private _console_init_render_tex :: proc(c:^Console) {
	init_rects(c)

	CW, CH := _console_get_cell_size(c^)

	c._render_tex = rl.LoadRenderTexture(i32(c.w*CW), i32(c.h*CH))
	c._render_tex_fg = rl.LoadRenderTexture(i32(c.w*CW), i32(c.h*CH))

	c._bg_img  = rl.GenImageColor(i32(c.w), i32(c.h), rl.RED)   // color is arbitray
	c._bg_tex  = rl.LoadTextureFromImage(c._bg_img)

	c._flip_rect_src = rl.Rectangle{0, 0, f32(c._render_tex.texture.width), f32(-c._render_tex.texture.height)}
	c._flip_rect_dst = rl.Rectangle{f32(c.x*CW), f32(c.y*CH), f32(c._render_tex.texture.width), f32(c._render_tex.texture.height)}
	c._origin_vec = rl.Vector2{0, 0}
}


// 0.350ms on average - drawing bg rectangles
_console_update_tex_rendering :: proc(c:^Console) {
	// quick_benchmark_start("_console_update_tex_rendering")
	rl.BeginTextureMode(c._render_tex_fg)      // Initializes render texture for drawing
		// rl.ClearBackground( rl.BLACK )
		for j in 0..<c.h {
			for i in 0..<c.w {
				idx := i+j*c.w
				pos := rl.Vector2{f32(i*c._cw), f32(j*c._ch)}
				ng, nfg, nbg := c._new_cells.glyphs[idx], c._new_cells.fgs[idx], c._new_cells.bgs[idx]
				og, ofg, obg := c._old_cells.glyphs[idx], c._old_cells.fgs[idx], c._old_cells.bgs[idx]

				if nbg != obg {
					rl.ImageDrawPixel(&c._bg_img,  i32(i), i32(j), nbg)
					c._old_cells.bgs[idx] = nbg
				}

				if ng != og || nfg != ofg {
					rl.BeginScissorMode(i32(i*c._cw), i32(j*c._ch), i32(c._cw), i32(c._ch))
					rl.ClearBackground( rl.BLANK )

					rl.DrawTextureRec(c.font.texture, c._glyph_rects[ng], pos, nfg)
					c._old_cells.glyphs[idx] = ng
					c._old_cells.fgs[idx] = nfg

					rl.EndScissorMode()
				}
			}
		}

	rl.EndTextureMode()

	rl.UpdateTexture(c._bg_tex, c._bg_img.data)

	// quick_benchmark_stop("_console_update_tex_rendering")
	// print("--------------------------------")
}

_render_using_tex :: proc(c:^Console) {
	rl.BeginTextureMode(c._render_tex)      // Initializes render texture for drawing
		rl.ClearBackground( rl.BLANK )
		rl.DrawTextureEx(c._bg_tex, {}, 0, f32(c._cw), rl.WHITE)
		rl.DrawTexturePro(c._render_tex_fg.texture, c._flip_rect_src, c._flip_rect_dst, c._origin_vec, 0.0, rl.WHITE)
	rl.EndTextureMode()

	rl.DrawTexturePro(c._render_tex.texture, c._flip_rect_src, c._flip_rect_dst, c._origin_vec, 0.0, rl.WHITE)
}

