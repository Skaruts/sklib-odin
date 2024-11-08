/*******************************************************************************
	Convenience procedures for
		- Vectors
		- Rectangles
		- Random
		- Colors
*******************************************************************************/
package sl

import "core:fmt"
import "core:intrinsics"
import rl "vendor:raylib"

// PROBLEM: 'intrinsics.type_is_numeric' accepts quats and arrays


/*******************************************************************************
		Vectors

	TODO:
		- dot, cross, etc
*/
@private _vec2_xy :: proc(x:$TA, y:$TB) -> rl.Vector2 where
			intrinsics.type_is_numeric(TA),
			intrinsics.type_is_numeric(TB) {
	return rl.Vector2{f32(x), f32(y)}
}

@private _vec2_0 :: proc() -> rl.Vector2 {
	return rl.Vector2{}
}

@private _vec2 :: proc { _vec2_xy, _vec2_0 }



/*******************************************************************************
		Rectangles

	TODO:
		intersect, etc
*/
@private _rect4 :: proc(x:$TA, y:$TB, w:$TC, h:$TD) -> rl.Rectangle where
			intrinsics.type_is_numeric(TA),
			intrinsics.type_is_numeric(TB),
			intrinsics.type_is_numeric(TC),
			intrinsics.type_is_numeric(TD) {
	return rl.Rectangle{f32(x), f32(y), f32(w), f32(h)}
}

@private _rectv :: proc(pos:rl.Vector2, size:rl.Vector2) -> rl.Rectangle {
	return rl.Rectangle{pos.x, pos.y, size.x, size.y}
}

@private _rect0 :: proc() -> rl.Rectangle {
	return rl.Rectangle{}
}

@private _rect :: proc { _rect4, _rectv, _rect0 }



/*******************************************************************************
		Random

	All procs below return a random int or float between 'min' and 'max'
	Arguments can be ommitted, defaults to '0' and '1'
*/
@private _randi :: proc{_randi_range, _randi_max, _randi_default}
@private _randf :: proc{_randf_range, _randf_max, _randf_default}


@private _randi_range :: proc(min:$TA, max:$TB) -> int where
			intrinsics.type_is_numeric(TA),
			intrinsics.type_is_numeric(TB) {
	return int(rl.GetRandomValue(i32(min), i32(max)))
}

@private _randi_max :: proc(max:$T) -> int where
			intrinsics.type_is_numeric(T) {
	return _randi_range(0, max)
}

@private _randi_default :: proc() -> int {
	return _randi_range(0, 1)
}


@private _randf_range :: proc(min:$TA, max:$TB) -> f64 where
			intrinsics.type_is_numeric(TA),
			intrinsics.type_is_numeric(TB) {
	max_rand := f64(max*100)
	val := f64( rl.GetRandomValue(0, i32(max_rand)) )
	normalized_val := val / max_rand
	return normalized_val * (f64(max) + f64(min))
}

@private _randf_max :: proc(max:$T) -> f64 where
			intrinsics.type_is_numeric(T) {
	return _randf_range(0, max)
}

@private _randf_default :: proc() -> f64 {
	return _randf_range(0, 1)
}





/*******************************************************************************
        Colors

    TODO:
		- brightened()
		- check what already exists in raylib
*/

@private _color4 :: proc(r:$TA, g:$TB, b:$TC, a:$TD) -> rl.Color where
		intrinsics.type_is_numeric(TA),
		intrinsics.type_is_numeric(TB),
		intrinsics.type_is_numeric(TC),
		intrinsics.type_is_numeric(TD) {
	return rl.Color{u8(r), u8(g), u8(b), u8(a)}
}

@private _color3 :: proc(r:$TA, g:$TB, b:$TC) -> rl.Color where
		intrinsics.type_is_numeric(TA),
		intrinsics.type_is_numeric(TB),
		intrinsics.type_is_numeric(TC) {
	return rl.Color{u8(r), u8(g), u8(b), u8(a)}
}

@private _color :: proc { _color4, _color3 }


@private _color_darken :: proc(c:^rl.Color, percent:$T)
		where intrinsics.type_is_float(T) {
    c.r = u8(T(c.r) * (1-percent))
    c.g = u8(T(c.g) * (1-percent))
    c.b = u8(T(c.b) * (1-percent))
}

@private _color_darkened :: proc(c:rl.Color, percent:$T) -> rl.Color
		where intrinsics.type_is_float(T) {
    return rl.Color {
        u8(T(c.r) * (1-percent)),
        u8(T(c.g) * (1-percent)),
        u8(T(c.b) * (1-percent)),
        c.a,
    }
}

