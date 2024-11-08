/*******************************************************************************
*           Mingo's Restrictive Precise Angle Shadowcasting
*
*
*     Original:
*         https://bitbucket.org/umbraprojekt/mrpas (other fovs there too)
*
*     Ported from:
*         https://github.com/domasx2/mrpas-js/blob/master/mrpas.js
*******************************************************************************/
package fov

import "core:math"
import "core:fmt"


@private
_compute_restrictive :: proc(fovmap:^FovMap, x, y, radius:int, light_walls:=true) {
	// make starting point visible
	_fov_set_visible_nc(fovmap, x, y, true, light_walls)

	// compute the 4 quadrants of the fov
	_mrpas_js_compute_quadrant(fovmap, x, y, radius,  1,  1, light_walls)
	_mrpas_js_compute_quadrant(fovmap, x, y, radius,  1, -1, light_walls)
	_mrpas_js_compute_quadrant(fovmap, x, y, radius, -1,  1, light_walls)
	_mrpas_js_compute_quadrant(fovmap, x, y, radius, -1, -1, light_walls)

	// apply a round mask
	if radius != fovmap._last_radius {
		fovmap._last_radius = radius
		_make_fov_circle_mask(fovmap, radius)
	}
 	_apply_fov_circle_mask(fovmap, x, y, radius, light_walls)
}



_mrpas_js_compute_quadrant :: proc(fovmap:^FovMap, pos_x, pos_y, radius, dx, dy:int, light_walls:=true) {
	start_angle : [100]f32
	end_angle : [100]f32

	//  octant: vertical edge:
	//  - - - - - - - - - - - - - - - - - - - - - - -
	iteration       : int = 1
	done            : bool = false
	total_obstacles : int = 0
	obstacles_in_last_line :int = 0
	min_angle       : f32 = 0.0

	x :int = 0
	y :int = pos_y + dy

	slopes_per_cell : f32
	half_slopes     : f32
	start_slope     : f32
	center_slope    : f32
	end_slope       : f32
	processed_cell  : int
	visible         : bool
	idx             : int
	minx            : int
	maxx            : int
	miny            : int
	maxy            : int

	if y < 0 || y >= fovmap.h do done = true

	for !done {

		// process cells in the line
		slopes_per_cell = 1.0 / f32(iteration + 1)
		half_slopes = slopes_per_cell * 0.5
		processed_cell = int(math.floor(min_angle / slopes_per_cell))

		minx = math.max(         0, pos_x - iteration)
		maxx = math.min(fovmap.w-1, pos_x + iteration)

		done = true

		x = pos_x + (processed_cell * dx)

		for x >= minx && x <= maxx {
			visible = true

			start_slope = f32(processed_cell) * slopes_per_cell
			center_slope = start_slope + half_slopes
			end_slope = start_slope + slopes_per_cell

			if obstacles_in_last_line > 0 && !_fov_is_visible_nc(fovmap^, x, y) {
				idx = 0
				for visible && idx < obstacles_in_last_line {
					if _fov_is_transparent_nc(fovmap^, x, y) {
						if center_slope > start_angle[idx] && center_slope < end_angle[idx] {
							visible = false
						}
					} else if start_slope >= start_angle[idx] && end_slope <= end_angle[idx] {
						visible = false
					}

					xdx := x - dx
					ydy := y - dy

					if visible && ( !_fov_is_visible_nc(fovmap^, x, ydy) || !_fov_is_transparent_nc(fovmap^, x, ydy) ) \
					&& ( xdx >= 0 && xdx < fovmap.w	&& ( !_fov_is_visible_nc(fovmap^, xdx, ydy) || !_fov_is_transparent_nc(fovmap^, xdx, ydy)  ))
					{
						visible = false
					}
					idx += 1
				}
			}

			if visible {
				_fov_set_visible_nc(fovmap, x, y, true, light_walls)
				done = false

				// if the cell is opaque, block the adjacent slopes
				if !_fov_is_transparent_nc(fovmap^, x, y) {
					if min_angle >= start_slope {
						min_angle = end_slope
					} else {
						start_angle[total_obstacles] = start_slope
						end_angle[total_obstacles] = end_slope
						// append(&start_angle, start_slope)
						// append(&end_angle, end_slope)
						total_obstacles += 1
					}
				}
			}
			processed_cell += 1
			x += dx
		}

		if iteration >= radius do done = true

		iteration += 1
		obstacles_in_last_line = total_obstacles

		y += dy
		if y < 0 || y >= fovmap.h do done = true
		if min_angle == 1.0 do done = true
	}

	// octant: horizontal edge
	//  - - - - - - - - - - - - - - - - - - - - - - -
	// clear(&start_angle)
	// clear(&end_angle)

	iteration = 1 // iteration of the algo for this octant
	done = false
	total_obstacles = 0
	obstacles_in_last_line = 0
	min_angle = 0.0

	x = pos_x + dx // the outer slope's coordinates (first processed line)
	y = 0

	slopes_per_cell = 0
	half_slopes = 0
	processed_cell = 0
	minx = 0
	maxx = 0
	miny = 0
	maxy = 0
	visible = false
	idx = 0
	start_slope = 0
	center_slope = 0
	end_slope = 0

	if x < 0 || x >= fovmap.w do done = true

	for !done {
		// process cells in the line
		slopes_per_cell = 1.0 / f32(iteration + 1)
		half_slopes = slopes_per_cell * 0.5
		processed_cell = int(math.floor(min_angle / slopes_per_cell))

		miny = math.max(       0, pos_y - iteration)
		maxy = math.min(fovmap.h-1, pos_y + iteration)

		done = true

		y = pos_y + (processed_cell * dy)

		for y >= miny && y <= maxy {
			// pos = vec(x, y)
			visible = true

			start_slope = f32(processed_cell) * slopes_per_cell
			center_slope = start_slope + half_slopes
			end_slope = start_slope + slopes_per_cell

			if obstacles_in_last_line > 0 && !_fov_is_visible_nc(fovmap^, x, y) {
				idx = 0

				for visible && idx < obstacles_in_last_line {
					if _fov_is_transparent_nc(fovmap^, x, y) {
						if center_slope > start_angle[idx] && center_slope < end_angle[idx] {
							visible = false
						}
					} else if start_slope >= start_angle[idx] && end_slope <= end_angle[idx] {
						visible = false
					}

					xdx := x-dx
					ydy := y-dy

					if visible && ( !_fov_is_visible_nc(fovmap^, xdx, y) || !_fov_is_transparent_nc(fovmap^, xdx, y) )  \
					&& ( ydy >= 0 && ydy < fovmap.h && ( !_fov_is_visible_nc(fovmap^, xdx, ydy) || !_fov_is_transparent_nc(fovmap^, xdx, ydy) ) )
					{
						visible = false
					}
					idx += 1
				}
			}
			if visible {
				_fov_set_visible_nc(fovmap, x, y, true, light_walls)
				done = false

				// if the cell is opaque, block the adjacent slopes
				if !_fov_is_transparent_nc(fovmap^, x, y) {
					if min_angle >= start_slope {
						min_angle = end_slope
					} else {
						start_angle[total_obstacles] = start_slope
						end_angle[total_obstacles] = end_slope
						// append(&start_angle, start_slope)
						// append(&end_angle, end_slope)
						total_obstacles = total_obstacles + 1
					}
				}
			}
			processed_cell += 1
			y += dy
		}
		if iteration >= radius do done = true

		iteration += 1
		obstacles_in_last_line = total_obstacles

		x += dx
		if x < 0 || x >= fovmap.w do done = true
		if min_angle == 1.0 do done = true
	}
}



