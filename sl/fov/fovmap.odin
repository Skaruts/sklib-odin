package fov

import "core:math"
// import "core:slice"
import "../utils"


FovCell :: struct {
	transparent :bool,
	walkable    :bool,
	visible     :bool,
}

@private CircleMask :: struct {
	w, h  : int,
	cells : []u8,
}

FovMap :: struct {
	w, h         : int,
	cells        : []FovCell,
	_id          : uint,
	_last_radius : int,
	_circle_mask : CircleMask,
}

@private _fovmaps:[dynamic]FovMap

// @private
_new_fovmap :: proc(w, h:int) -> FovMap {
	assert(w > 0 && h > 0, "FovMap width and height must be greater than zero")
	fm := FovMap {
		_id = utils.next_id(),
		w = w,
		h = h,
		cells = make([]FovCell, w*h),
	}
	append(&_fovmaps, fm)
	return fm
	// return _fovmaps[len(_fovmaps)-1]
}



_destroy_fovmap :: proc(fm:^FovMap) {
	// print("destroying fovmap")
	for v, i in _fovmaps {
		if v._id == fm._id {
			// print("mask len: ", len(v._circle_mask.cells))
			unordered_remove(&_fovmaps, i)
			break
		}
	}
	// print("mask len: ", len(fm._circle_mask.cells))
	delete(fm._circle_mask.cells)
	delete(fm.cells)
}

_destroy_all_fovmaps :: proc() {
	for len(_fovmaps) > 0 {
		_destroy_fovmap(&_fovmaps[0])
	}
	delete(_fovmaps)
}

_fov_set_cell :: proc(fm:^FovMap, x, y:int, transparent:Maybe(bool)=nil, walkable:Maybe(bool)=nil, visible:Maybe(bool)=nil) {
	cell := &fm.cells[x+y*fm.w]

	if t, ok := transparent.?; ok do cell.transparent = t
	if w, ok := walkable.?;    ok do cell.walkable = w
	if v, ok := visible.?;     ok do cell.visible = v
	// if transparent != nil do cell.transparent = transparent
	// if walkable != nil do cell.walkable = walkable
	// if visible != nil do cell.visible = visible

}

// @private
_fov_clear :: proc(fm:^FovMap, x, y, radius:int) {
	LEFT   := math.max(x-(radius+4), 0)
	RIGHT  := math.min(x+(radius+4), fm.w)
	TOP    := math.max(y-(radius+4), 0)
	BOTTOM := math.min(y+(radius+4), fm.h)

	for j in TOP..<BOTTOM {
		for i in LEFT..<RIGHT {
			idx := i+j*fm.w
			fm.cells[idx].visible = false
		}
	}
}





_fov_set_visible :: proc(fm:^FovMap, x, y:int, visible:bool, light_walls:=true) {
	if !_is_in_bounds(x, y, fm.w, fm.h) do return
	fm.cells[x+y*fm.w].visible = visible
}
// no bounds check
@private _fov_set_visible_nc :: proc(fm:^FovMap, x, y:int, visible:bool, light_walls:=true) {
	fm.cells[x+y*fm.w].visible = visible
}


_fov_is_transparent :: proc(fm:FovMap, x, y:int) -> bool {
	return _is_in_bounds(x, y, fm.w, fm.h) && fm.cells[x+y*fm.w].transparent
}
// no bounds check
@private _fov_is_transparent_nc :: proc(fm:FovMap, x, y:int) -> bool {
	return fm.cells[x+y*fm.w].transparent
}


_fov_is_visible :: proc(fm:FovMap, x, y:int) -> bool {
	return _is_in_bounds(x, y, fm.w, fm.h) && fm.cells[x+y*fm.w].visible
}
// no bounds check
@private _fov_is_visible_nc :: proc(fm:FovMap, x, y:int) -> bool {
	return fm.cells[x+y*fm.w].visible
}
