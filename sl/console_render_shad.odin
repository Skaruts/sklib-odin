package sl

import "core:math"
import rl "vendor:raylib"

// TODO: check how to do this in Odin
// #if defined(PLATFORM_DESKTOP)
//     #define GLSL_VERSION            330
// #else   // PLATFORM_ANDROID, PLATFORM_WEB
//     #define GLSL_VERSION            100
// #endif

_shader_loc :: proc(shader:rl.Shader, property:cstring) -> rl.ShaderLocationIndex {
	return rl.ShaderLocationIndex(rl.GetShaderLocation(shader, property))
}
_console_init_shader_rendering :: proc(c:^Console) {
	CW, CH := c._cw, c._ch

	// c._shader = rl.LoadShader("sl/console_shader.vs", "sl/console_shader.fs");
	c._shader = rl.LoadShader(nil, "sl/console_shader.fs");

	c._grid_size = rl.Vector2 { f32(c.w), f32(c.h) }
	c._font_size = rl.Vector2 { f32(c.font.cols), f32(c.font.rows) }

	img := rl.GenImageColor(i32(c.w*CW), i32(c.h*CH), rl.LIME)  // color is arbitray
	c._shader_tex = rl.LoadTextureFromImage(img)
	rl.UnloadImage(img)

	c._bg_img  = rl.GenImageColor(i32(c.w), i32(c.h), rl.RED)   // color is arbitray
	c._fg_img  = rl.GenImageColor(i32(c.w), i32(c.h), rl.GREEN) // color is arbitray
	c._chr_img = rl.GenImageColor(i32(c.w), i32(c.h), rl.BLUE)  // color is arbitray
	c._bg_tex  = rl.LoadTextureFromImage(c._bg_img)
	c._fg_tex  = rl.LoadTextureFromImage(c._fg_img)
	c._chr_tex = rl.LoadTextureFromImage(c._chr_img)

	// rl.SetShaderValueV(c._shader, _shader_loc(c._shader, "grid_size"), &c._grid_size, .VEC2, 1)
	// rl.SetShaderValueV(c._shader, _shader_loc(c._shader, "font_size"), &c._font_size, .VEC2, 1)
	// rl.SetShaderValue(c._shader, _shader_loc(c._shader, "cw"), &CW, .FLOAT)
	// rl.SetShaderValue(c._shader, _shader_loc(c._shader, "ch"), &CH, .FLOAT)
	// rl.SetShaderValueTexture(c._shader, _shader_loc(c._shader, "font"), c.font.texture)
	// rl.SetShaderValueTexture(c._shader, _shader_loc(c._shader, "bg_tex"),  c._bg_tex)
	// rl.SetShaderValueTexture(c._shader, _shader_loc(c._shader, "fg_tex"),  c._fg_tex)
	// rl.SetShaderValueTexture(c._shader, _shader_loc(c._shader, "chr_tex"), c._chr_tex)
	// print("------------------------")
}


_console_update_shader_rendering :: proc(c:^Console) {
	for j in 0..<i32(c.h) {
		for i in 0..<i32(c.w) {
			idx := int(i)+int(j)*c.w
			ng, nfg, nbg := c._new_cells.glyphs[idx], c._new_cells.fgs[idx], c._new_cells.bgs[idx]
			og, ofg, obg := c._old_cells.glyphs[idx], c._old_cells.fgs[idx], c._old_cells.bgs[idx]

			if nbg != obg {
				rl.ImageDrawPixel(&c._bg_img,  i, j, nbg)
				c._old_cells.bgs[idx] = nbg
				c._old_cells.bgs[idx] = nbg
			}

			if nfg != ofg {
				rl.ImageDrawPixel(&c._fg_img,  i, j, nfg)
				c._old_cells.fgs[idx] = nfg
			}

			if ng != og {
				// glyph value encoded in two color channels
				// TODO: might be worth considering other color formats for this?
				r := u8(math.min(255, ng))
				g := u8(math.max(0, (int(ng)-255)))
				rl.ImageDrawPixel(&c._chr_img, i, j, {r, g, 0, 255})
				c._old_cells.glyphs[idx] = ng
			}
		}
	}

	// rl.ImageDrawPixel(&c._bg_img,  10, 10, rl.BLUE)

	rl.UpdateTexture(c._bg_tex, c._bg_img.data)
	rl.UpdateTexture(c._fg_tex, c._fg_img.data)
	rl.UpdateTexture(c._chr_tex, c._chr_img.data)
}

_console_render_shader :: proc(c:^Console) {
	CW, CH := c._cw, c._ch

	rl.BeginShaderMode(c._shader)

		rl.SetShaderValueV(c._shader, _shader_loc(c._shader, "grid_size"), &c._grid_size, .VEC2, 1)
		rl.SetShaderValueV(c._shader, _shader_loc(c._shader, "font_size"), &c._font_size, .VEC2, 1)
		rl.SetShaderValue(c._shader, _shader_loc(c._shader, "cw"), &c.font.cw, .FLOAT)
		rl.SetShaderValue(c._shader, _shader_loc(c._shader, "ch"), &c.font.ch, .FLOAT)
		rl.SetShaderValueTexture(c._shader, _shader_loc(c._shader, "font"), c.font.texture)
		rl.SetShaderValueTexture(c._shader, _shader_loc(c._shader, "bg_tex"), c._bg_tex)
		rl.SetShaderValueTexture(c._shader, _shader_loc(c._shader, "fg_tex"), c._fg_tex)
		rl.SetShaderValueTexture(c._shader, _shader_loc(c._shader, "chr_tex"), c._chr_tex)

		rl.DrawTexture(c._shader_tex, i32(c.x), i32(c.y), rl.WHITE)

	rl.EndShaderMode()
}
