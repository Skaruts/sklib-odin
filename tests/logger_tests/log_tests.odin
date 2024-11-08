package log_tests

import "core:fmt"
import rl "vendor:raylib"
import "../../sl"


// NOTE: choice of colors is temporarily weird due to console rendering tests


print :: fmt.println

GW :: 80
GH :: 50

console : sl.Console

init :: proc() {
	sl.window_set_title("Logging Test (sklib-Odin)")
	// sl.log_set_prefix("USER_")

	sl.bind("log_print",      {"1"})
	sl.bind("log_printf",     {"2"})
	sl.bind("log_info",       {"3"})
	sl.bind("log_task",       {"4"})
	sl.bind("log_reminder",   {"5"})
	sl.bind("log_deprecated", {"6"})
	sl.bind("log_warning",    {"7"})
	sl.bind("log_error",      {"8"})

	console = sl.new_console(GW, GH, sl.new_font("data/fonts/cp437_18x18.png"))
	sl.console_print(console, 10, 10, "Logging Test", rl.GOLD, rl.BLACK)
}

input :: proc(event : sl.InputEvent) {
	if sl.action_down(event, "log_print")      {
		sl.print("foooooo!", 2, 69, console.font)
	}
	if sl.action_down(event, "log_printf")     do sl.printf("some more %s", "foooooo!")
	if sl.action_down(event, "log_info")       do sl.info("some info")
	if sl.action_down(event, "log_task")       do sl.task("some task")
	if sl.action_down(event, "log_reminder")   do sl.reminder("some reminder")
	if sl.action_down(event, "log_deprecated") do sl.deprecated("some deprecated")
	if sl.action_down(event, "log_warning")    do sl.warning("some warning")
	if sl.action_down(event, "log_error")      do sl.error("some error")
}

update :: proc(dt:f32) {

}

render :: proc() {
	sl.console_render(console)
}

quit :: proc() {

}
