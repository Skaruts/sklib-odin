package sl

import "core:fmt"
import "core:slice"
import rl "vendor:raylib"




@private _internal := struct {
	rl_log_level:rl.TraceLogLevel,
	window_title:cstring,
	target_fps:int,
	// window_is_running: bool,

	consoles:[dynamic]Console,
	main_console:^Console,
	logger : ^Logger,

	dt    : f32,
	time  : f64,
	frame : int,

	default_render_type:RenderType,
	default_font_layout_name:string,
	font_layouts:map[string]FontLayout,
} {
	window_title = "Default Window Title (sklib-Odin)",
	rl_log_level = .WARNING,
	default_font_layout_name = "cp437",
	target_fps = 60,
	// default_render_type = .TextureRender,
	// default_render_type = .QuadRender,
	default_render_type = .ShaderRender,
}

@private _new_console :: proc { _new_console_wo_render_type, _new_console_impl }

@private _new_console_wo_render_type :: proc(w, h:int, font:Font, cw:Maybe(int)=nil, ch:Maybe(int)=nil) -> Console {
	return _new_console(_internal.default_render_type, w, h, font, cw, ch)
}

@private _new_console_impl :: proc(render_type:RenderType, w, h:int, font:Font, cw:Maybe(int)=nil, ch:Maybe(int)=nil) -> Console {
    console := _init_console(render_type, w, h, font, cw, ch)
    store_console(console)

    if _internal.main_console == nil {
        _internal.main_console = &console
        _resize_window()
    }

    return console
}

@private store_console :: proc(c:Console) {
	append(&_internal.consoles, c)
}

@private _remove_console :: proc(c:Console) {
	for v, i in _internal.consoles {
		if v._id == c._id {
            unordered_remove(&_internal.consoles, i)
			break
		}
	}

    // if 'c' was the 'main_console', then change the 'main_console'
    if c._id == _internal.main_console._id {
        if len(_internal.consoles) == 0 {
            _internal.main_console = nil
        } else {
            _internal.main_console = &_internal.consoles[0]
        }
    }

    _destroy_console(c)
    // TODO: change 'main_console' if this is 'main_console'
}


@private destroy_consoles :: proc() {
	__INFO("destroying consoles on quit: %d", len(_internal.consoles))
	for c in _internal.consoles {
		_destroy_console(c)
	}
	delete(_internal.consoles)
}

