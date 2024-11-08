package fov

import "core:fmt"
import "core:math"


/*******************************************************************************
		Filled Mid-point Circle

 	Used to perform a second pass on square fovs, to make them round.
*/
_apply_fov_circle_mask :: proc(fm:^FovMap, x, y, radius:int, light_walls:=true) {
	size := radius * 2 + 1

	for j in 0..<size {
		for i in 0..<size {
			px := x + i - radius
			py := y + j - radius

			if fm._circle_mask.cells[i+j*size] == 0 {
				if _is_in_bounds(px, py, fm.w, fm.h) {
					_fov_set_visible_nc(fm, px, py, false, light_walls)
				}
			}
		}
	}
}

@private _put_pixel :: proc(cm:^CircleMask, x, y, size:int) {
	cm.cells[x+y*cm.w] = 1
}

@private _line :: proc(cm:^CircleMask, x0, y0, x1, size:int) {
	for x in x0..<x1 {
		_put_pixel(cm, x, y0, size)
	}
}

@private _make_lines :: proc(cm:^CircleMask, cx, cy, x, y, size:int) {
	_line(cm, cx-x, cy+y, cx+x, size)
	if y != 0 {
		_line(cm, cx-x, cy-y, cx+x, size)
	}
}


_make_fov_circle_mask :: proc(fm:^FovMap, radius:int) {
	// fmt.println("_make_fov_circle_mask")

	// TODO: delete the existing mask, if one already exists
	// delete(fm._circle_mask.cells)

	size := radius * 2 +1
	cx   := radius
	cy   := radius
	err  := -radius
	x    := radius
	y    := 0

	fm._circle_mask = CircleMask {
		w = size,
		h = size,
		cells = make([]u8, size*size),
	}

	for x >= y {
		last_y := y

		err += y
		y   += 1
		err += y

		_make_lines(&fm._circle_mask, cx, cy, x, last_y, size)

		if err >= 0 {
			if x != last_y {
				_make_lines(&fm._circle_mask, cx, cy, last_y, x, size)
			}

			err -= x
			x   -= 1
			err -= x
		}
	}
}
