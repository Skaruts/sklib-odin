package main

import "core:fmt"
import "sl"
import rl "vendor:raylib"

/* Choose the project to run */

import game "tests/basic_game"
// import game "tests/logger_tests"
// import game "tests/rune_tests"
// import game "tests/stress_tests"
// import game "tests/test2"



main :: proc() {
	/*   uncomment if you want raylib logs below warning level   */
	// sl.set_raylib_log_level(rl.TraceLogLevel.ALL)

	/*   call 'sl.start' with the existing callbacks   */
	sl.start(
		init   = game.init,
		input  = game.input,
		update = game.update,
		render = game.render,
		// frame_start = game.frame_start,
		quit  = game.quit,
	)
}

