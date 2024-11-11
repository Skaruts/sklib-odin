package sl


import "core:mem"
import rl "vendor:raylib"

import "fov"
import "utils"



@private _user_init:proc()
@private _user_input:proc(event:InputEvent)
@private _user_update:proc(dt:f32)
@private _user_render:proc()
@private _user_frame_start:proc()
@private _user_frame_end:proc()
@private _user_quit:proc()


@private _start_engine :: proc(
			init:proc(),
			input:proc(event: InputEvent),
			update:proc(dt: f32),
			render:proc(),
			frame_start:proc() = nil,
			frame_end:proc() = nil,
			quit:proc() = nil)
{
	_init_engine(init, input, update, render, frame_start, frame_end, quit)
}



@private _init_engine :: proc(
								init:proc(),
								input:proc(event:InputEvent),
								update:proc(dt:f32),
								render:proc(),
								frame_start:proc()=nil,
								frame_end:proc()=nil,
								quit:proc()=nil,
							)
{
	_user_init        = init
	_user_input       = input
	_user_update      = update
	_user_render      = render
	_user_frame_start = frame_start != nil ? frame_start : proc() {}
	_user_frame_end   = frame_end   != nil ? frame_end   : proc() {}
	_user_quit        = quit        != nil ? quit        : proc() {}

	default_alloc := context.allocator
	context.allocator = init_track_alloc()  // track_alloc.odin

	rl.SetTraceLogLevel(_internal.rl_log_level)

	// 'main_console' will change the window size, so size here is arbitrary
	rl.InitWindow(800, 600, _internal.window_title)
	defer rl.CloseWindow()

	if rl.IsWindowReady() {
		rl.SetTargetFPS(i32(_internal.target_fps))

		_initialize_sl()

			_internal_run() // main loop
			_internal_quit()

		_destroy_sl()
	} else {
		// TODO: maybe deal with this better
		__ERROR("something went wrong initializing the window")
	}

	finish_track_alloc()
}

@private _set_raylib_log_level :: proc(level: rl.TraceLogLevel) {
	_internal.rl_log_level = level
	rl.SetTraceLogLevel(level)
}

@private _initialize_sl :: proc() {
	_init_logging()

	__INFO("initializing sl...") // don't call this before 'init_logging'
	_init_font_layouts()
	init_benchmarks()
	// init_consoles()
	_init_input()
}

@private _destroy_sl :: proc() {
	__INFO("finishing sl...")
	destroy_consoles()
	destroy_benchmarks()
	_destroy_font_layouts()
	fov._destroy_all_fovmaps()
	_destroy_input()
	_destroy_logging()
}

@private _internal_run :: proc() {
	_user_init()

	t1 := rl.GetTime()

	main_loop: for !rl.WindowShouldClose() {
		/*
			TODO:
				- add input blocking option
				- compare delta with rl.GetFrameTime()
				- separate render / update ?
		*/

		t2 := rl.GetTime()
		_internal.dt = f32(t2-t1)
		t1 = t2
		_internal.time += f64(_internal.dt)
		_internal.frame += 1

		{ // process frame
			_user_frame_start()

			_internal_input(_internal.dt)  // TODO: better to do this last on roguelikes?
			_internal_update(_internal.dt)
			_internal_render()

			_user_frame_end()
		}

		free_all(context.temp_allocator)
		check_bad_frees()
	}
}

@private _internal_input :: proc(dt:f32) {
	_update_input(dt)

	for _input_has_events() {
		event := _input_pop_event()
		_user_input(event)
	}
}

@private _internal_update :: proc(dt:f32) {
	_user_update(dt)
}

@private _internal_render :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.VIOLET)

		_user_render()

	rl.EndDrawing()
}

@private _internal_quit :: proc() {
	_user_quit()
}

@private _resize_window :: proc() {
	c := _internal.main_console
	CW, CH := _console_get_cell_size(c^)

    mon_size := rl.Vector2{f32(rl.GetMonitorWidth(0)), f32(rl.GetMonitorHeight(0))}
    win_size := rl.Vector2{f32(c.w*CW), f32(c.h*CH)}
    pos := (mon_size - win_size) / 2
    if win_size.x > mon_size.x do pos.x = 0
    if win_size.y > mon_size.y do pos.y = 0

    // set position first to avoid occasional weird effects
    rl.SetWindowPosition(i32(pos.x), i32(pos.y))
    rl.SetWindowSize(i32(win_size.x), i32(win_size.y))
}

@private _window_set_title :: proc(title:string) {
    _internal.window_title = utils.str_to_cstr(title)
    rl.SetWindowTitle(_internal.window_title)
}

@private _window_set_target_fps :: proc(fps:int=0) {
	_internal.target_fps = fps
    rl.SetTargetFPS(i32(fps))
}

@private _get_delta_time :: proc() -> f32 {
	return _internal.dt
}

@private _get_mouse_position :: proc() -> rl.Vector2 {
	return rl.GetMousePosition()
}
