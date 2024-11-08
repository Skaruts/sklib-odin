/*******************************************************************************

		Public API listing

		(some stuff still missing)

*******************************************************************************/
package sl

import "core:fmt"

import "fov"
import "utils"



/*******************************************************************************
		main_loop.odin
*/
start                 :: proc { _start_engine }
set_raylib_log_level  :: proc { _set_raylib_log_level }
get_delta_time        :: proc { _get_delta_time }
window_set_title      :: proc { _window_set_title }
window_set_target_fps :: proc { _window_set_target_fps }



/*******************************************************************************
		consoles / fonts / font-layouts
*/
new_font                   :: _font_init  // font.odin

// internal_data.odin / console.odin
new_console                :: _new_console
remove_console             :: proc { _remove_console }
console_codepoint_to_index :: _console_codepoint_to_index
console_char_to_index      :: _console_char_to_index
console_index_to_char      :: _console_index_to_char

// font_layouts.odin
add_font_layout            :: _add_font_layout
codepoint_to_index         :: _layout_codepoint_to_index
char_to_index              :: _layout_char_to_index
index_to_char              :: _layout_index_to_char



/*******************************************************************************
		benchmark.odin
*/
quick_benchmark_start :: proc { _quick_benchmark_start }
quick_benchmark_stop  :: proc { _quick_benchmark_stop }



/*******************************************************************************
		input.odin
*/
bind                  :: proc { _bind }
input_has_events      :: proc { _input_has_events }
input_pop_event       :: proc { _input_pop_event }
key_pressed           :: proc { _key_pressed }
key_down              :: proc { _key_down }
key_released          :: proc { _key_released }
action_pressed        :: proc { _action_pressed, _event_action_pressed }
action_down           :: proc { _action_down, _event_action_down }
action_released       :: proc { _action_released, _event_action_released }
// event_action_pressed  :: proc { _event_action_pressed }
// event_action_down     :: proc { _event_action_down }
// event_action_released :: proc { _event_action_released }



/*******************************************************************************
		fov/...
*/
FovType            :: fov.FovType
FovCell            :: fov.FovCell
FovMap             :: fov.FovMap
fov_new            :: proc { fov._new_fovmap }
fov_clear          :: proc { fov._fov_clear }
fov_compute        :: proc { fov._fov_compute }
fov_set_cell       :: proc { fov._fov_set_cell }
fov_is_visible     :: proc { fov._fov_is_visible }
fov_remove         :: proc { fov._destroy_fovmap }
// fov_set_visible    :: proc { fov._fov_set_visible }
// fov_is_transparent :: proc { fov._fov_is_transparent }



/*******************************************************************************
		utils/utils.odin
*/
str_to_cstr    :: utils.str_to_cstr
print2d        :: utils.print2d



/*******************************************************************************
		misc.odin
*/
vec2           :: _vec2
rect           :: _rect
randi          :: _randi
randf          :: _randf
color          :: _color
color_darken   :: proc { _color_darken }
color_darkened :: proc { _color_darkened }



/*******************************************************************************
		logger.odin
*/
// same as 'println', but with the current frame number prefixed
printn :: proc(args: ..any) {
	fmt.print(_internal.frame, " ")
	fmt.println(..args)
}

log_set_prefix :: _logger_set_prefix

print      :: _logger_print
printf     :: _logger_printf
info       :: _logger_info
task       :: _logger_task
reminder   :: _logger_reminder
deprecated :: _logger_deprecated
warning    :: _logger_warning
error      :: _logger_error

