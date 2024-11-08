package fov

import "core:fmt"
import rl "vendor:raylib"



FovType :: enum {
	Raycast,
	Shadowcast,
	Restrictive,
	Permissive,
	// Diamond,
}


// @private
_fov_compute :: proc(fm:^FovMap, pos:rl.Vector2, radius:int, type:FovType, light_walls:=true) {
 	x := int(pos.x)
 	y := int(pos.y)
 	_fov_clear(fm, x, y, radius)

	// #partial switch type {
	// 	case .Raycast:
	// 	case .Shadowcast:
	// 	case .Restrictive:
		_compute_restrictive(fm, x, y, radius, light_walls)
	// 	case .Permissive:
	// }

}

@private _is_in_bounds :: proc(x, y, w, h:int) -> bool {
	return x >= 0 && y >= 0 && x < w && y < h
}





