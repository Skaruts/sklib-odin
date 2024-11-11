package sl
import "core:fmt"
import rl "vendor:raylib"
/*******************************************************************************

		Quad Rendering

*/

// TODO: backgrounds should maybe be an image, and not rely on glyph 219
// as 219 is only a full block in the cp437 layout
BG_GLYPH :: 219


@private _console_init_quads :: proc(c:^Console) {
	// fmt.println("_console_init_quads")

	c._quads.bg = make([]Vertex, (c.w * c.h) * 4) // reset sequences if they have anything already
	c._quads.fg = make([]Vertex, (c.w * c.h) * 4)

	CW, CH := _console_get_cell_size(c^)

	COLS := int(c.font.cols)      // font width, in tiles
	UVS : f32 = 1.0/f32(COLS)   // UV size  - TODO: should account for different width and height (UVW, UVH)

	bg_u  : f32 = f32(int(BG_GLYPH) % COLS) * UVS
	bg_v  : f32 = f32(int(BG_GLYPH) / COLS) * UVS
	bg_u2 : f32 = bg_u + UVS
	bg_v2 : f32 = bg_v + UVS

	bg_uv_a := vec2(bg_u,  bg_v)
	bg_uv_b := vec2(bg_u2, bg_v)
	bg_uv_c := vec2(bg_u2, bg_v2)
	bg_uv_d := vec2(bg_u,  bg_v2)

	fg_u  : f32 = f32(int(DEF_GLYPH) % COLS) * UVS
	fg_v  : f32 = f32(int(DEF_GLYPH) / COLS) * UVS
	fg_u2 : f32 = fg_u + UVS
	fg_v2 : f32 = fg_v + UVS

	fg_uv_a := vec2(fg_u,  fg_v)
	fg_uv_b := vec2(fg_u2, fg_v)
	fg_uv_c := vec2(fg_u2, fg_v2)
	fg_uv_d := vec2(fg_u,  fg_v2)

	fmt.println(CW, CH, COLS, UVS, "  |  ", bg_u, bg_v, bg_u2, bg_v2, "  |  ", bg_u*16, bg_v*16, bg_u2*16, bg_v2*16)

	for j in 0..<c.h {
		for i in 0..<c.w {
			//   A --- B
			//   |     |
			//   D --- C
			va := vec2( i    * CW,  j    * CH)
			vb := vec2((i+1) * CW,  j    * CH)
			vc := vec2((i+1) * CW, (j+1) * CH)
			vd := vec2( i    * CW, (j+1) * CH)

			idx := (i+j*c.w) * 4
			c._quads.bg[idx+0] = Vertex{ va,    DEF_BG,    bg_uv_a }  // a
			c._quads.bg[idx+1] = Vertex{ vb,    DEF_BG,    bg_uv_b }  // b
			c._quads.bg[idx+2] = Vertex{ vc,    DEF_BG,    bg_uv_c }  // c
			c._quads.bg[idx+3] = Vertex{ vd,    DEF_BG,    bg_uv_d }  // d

			c._quads.fg[idx+0] = Vertex{ va,    DEF_FG,     fg_uv_a } // a
			c._quads.fg[idx+1] = Vertex{ vb,    DEF_FG,     fg_uv_b } // b
			c._quads.fg[idx+2] = Vertex{ vc,    DEF_FG,     fg_uv_c } // c
			c._quads.fg[idx+3] = Vertex{ vd,    DEF_FG,     fg_uv_d } // d
		}
	}

	// fmt.println("_console_init_quads Done")
}


@private _console_update_quads :: proc(c:^Console) {
	// fmt.println("_console_update_quads")
	// quick_benchmark_start("update_quads")

	CW, CH := _console_get_cell_size(c^)
	COLS := int(c.font.cols)      // font width, in tiles
	UVS := 1.0/f32(COLS)           // UV size  - TODO: should account for different width and height (UVW, UVH)

	for i in 0..< c.w*c.h {
		idx := i * 4

		ng, nfg, nbg := c._new_cells.glyphs[i], c._new_cells.fgs[i], c._new_cells.bgs[i]
		og, ofg, obg := c._old_cells.glyphs[i], c._old_cells.fgs[i], c._old_cells.bgs[i]

		if nbg != obg {
			c._quads.bg[idx  ].color = nbg
			c._quads.bg[idx+1].color = nbg
			c._quads.bg[idx+2].color = nbg
			c._quads.bg[idx+3].color = nbg
			c._new_cells.bgs[i] = nbg
		}

		if nfg != ofg {
			c._quads.fg[idx  ].color = nfg
			c._quads.fg[idx+1].color = nfg
			c._quads.fg[idx+2].color = nfg
			c._quads.fg[idx+3].color = nfg
			c._new_cells.fgs[i] = nfg
		}

		if ng != og {
			u  := f32(int(ng) % COLS) * UVS
			v  := f32(int(ng) / COLS) * UVS
			u2 := u + UVS
			v2 := v + UVS

			c._quads.fg[idx  ].uv = vec2(u , v )
			c._quads.fg[idx+1].uv = vec2(u2, v )
			c._quads.fg[idx+2].uv = vec2(u2, v2)
			c._quads.fg[idx+3].uv = vec2(u , v2)
			c._new_cells.glyphs[i] = ng
		}
	}
	// quick_benchmark_stop("update_quads")

	// fmt.println("--------------------------------------")
}




@private _add_vertex :: proc(v:Vertex) {
	rl.rlColor4ub(v.color.r, v.color.g, v.color.b, v.color.a)
    rl.rlTexCoord2f(v.uv.x, v.uv.y)
    rl.rlVertex2f(v.pos.x, v.pos.y)
}

@private _console_render_quads :: proc(c:^Console) {
	// fmt.println("_console_render_quads")

	/*
		gl VAO's :
			https://discord.com/channels/426912293134270465/427518168995725317/1107328540594159687

		raylib VAOs:
			https://www.reddit.com/r/raylib/comments/vs6qcx/rldrawvertexarrayelements_not_working_as_expected/

		potentially useful
			https://www.raylib.com/examples/text/loader.html?name=text_draw_3d
	*/

	CW, CH := _console_get_cell_size(c^)

	// quick_benchmark_start("update_quads")

	rl.rlSetTexture(c.font.texture.id)
		rl.rlPushMatrix()
			rl.rlTranslatef(f32(c.x*CW), f32(c.y*CH), 0.0)
		    //   A --- B
		    //   |     |
		    //   D --- C
			rl.rlBegin(rl.RL_QUADS)
				for i in 0 ..< c.w*c.h {
					// no clue how tf this thing works, but seems to be
					// working fine as it is
					if rl.rlCheckRenderBatchLimit(i32((c.w+1)*(c.h+1)*8)) {
					// 	rl.rlDrawRenderBatchActive()
					}

					idx := i * 4

					// background
					_add_vertex( c._quads.bg[idx    ] )  // A
					_add_vertex( c._quads.bg[idx + 3] )  // D
					_add_vertex( c._quads.bg[idx + 2] )  // C
					_add_vertex( c._quads.bg[idx + 1] )  // B

					// // foreground
					_add_vertex( c._quads.fg[idx    ] )  // A
					_add_vertex( c._quads.fg[idx + 3] )  // D
					_add_vertex( c._quads.fg[idx + 2] )  // C
					_add_vertex( c._quads.fg[idx + 1] )  // B
				}
			rl.rlEnd()
		rl.rlPopMatrix()
	rl.rlSetTexture(0)
	// quick_benchmark_stop("update_quads")
}

