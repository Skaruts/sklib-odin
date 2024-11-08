package sl

import "core:strings"
import "core:fmt"
import rl "vendor:raylib"



@private _destroy_action :: proc(action:^InputAction) {
	for bind in &action.binds {
		#partial switch b in bind {
			case KeyboardBind: delete(b.mods)
			case MouseBind:    delete(b.mods)
		}
	}
	delete(action.binds)
}

// TODO: should these functions really crash, or just print out a warning?
@private _action_pressed :: proc(id:string, loc := #caller_location ) -> bool {
	if id not_in actions do fmt.panicf(fmt="invalid action '%s'!", args={id}, loc=loc)
	return id in actions_pressed && actions_pressed[id].frames == 0
}

@private _action_down :: proc(id: string, loc := #caller_location) -> bool {
	if id not_in actions do fmt.panicf(fmt="invalid action '%s'!", args={id}, loc=loc)
	// print(len(actions_pressed))
	return id in actions_pressed
}

@private _action_released :: proc(id: string, loc := #caller_location) -> bool {
	if id not_in actions do fmt.panicf(fmt="invalid action '%s'!", args={id}, loc=loc)
	return id in actions_released
}

@private _event_action_pressed :: proc(event: InputEvent, id:string, loc := #caller_location ) -> bool {
	if id not_in actions do fmt.panicf(fmt="invalid action '%s'!", args={id}, loc=loc)
	if id not_in actions_pressed do return false

	if ev, ok := event.(KeyboardEvent); ok {
		if !ev.pressed do return false

		action := actions_pressed[id]
		if action.frames > 0 do return false

		for bind in action.binds {
			if b, ok := bind.(KeyboardBind); ok {
				if b.key == ev.key {
					return true
				}
			}
		}
	}
	return false
}

@private _event_action_down :: proc(event: InputEvent, id: string, loc := #caller_location) -> bool {
	if id not_in actions do fmt.panicf(fmt="invalid action '%s'!", args={id}, loc=loc)
	if id not_in actions_pressed do return false

	if ev, ok := event.(KeyboardEvent); ok {
		if !ev.pressed do return false
		action := actions_pressed[id]

		for bind in action.binds {
			if b, ok := bind.(KeyboardBind); ok {
				if b.key == ev.key {
					return true
				}
			}
		}
	}
	return false
}

@private _event_action_released :: proc(event: InputEvent, id: string, loc := #caller_location) -> bool {
	if id not_in actions do fmt.panicf(fmt="invalid action '%s'!", args={id}, loc=loc)
	if id not_in actions_released do return false
	if ev, ok := event.(KeyboardEvent); ok {
		if ev.pressed do return false
		action := actions_released[id]

		for bind in action.binds {
			if b, ok := bind.(KeyboardBind); ok {
				if b.key == ev.key || !_are_mods_ok(b) {
					return true
				}
			}
		}
	}
	return false
}

@private _increase_action_timers :: proc(dt:f32) {
	for id, _ in actions_pressed {
		action := &actions_pressed[id]
		action.frames += 1
	}
}

@private _set_action_as_pressed :: proc(action: InputAction) {
	actions_pressed[action.id] = action
}

@private _set_action_as_released :: proc(action: InputAction) {
	// print(action.id, " - setting as released")
	if action.id not_in actions_pressed do return
	actions_released[action.id] = actions_pressed[action.id]
	delete_key(&actions_pressed, action.id)
}


@private _check_action_pressed :: proc(k: rl.KeyboardKey) {
	for id, action in actions {
		for bind in action.binds {
			if b, ok := bind.(KeyboardBind); ok {
				// if b.key == k || _mod_equals_key(b.key, k) then
				if b.key == k && _are_mods_ok(b) {
					_set_action_as_pressed(action)
					return
				}
			}
		} //else if ib, ok := action.binds.(KeyboardBind); ok {

	}
}

@private _is_mod_key :: proc(key : rl.KeyboardKey) -> bool {
	#partial switch key {
		case .LEFT_SHIFT, .RIGHT_SHIFT, .LEFT_CONTROL, .RIGHT_CONTROL, .LEFT_ALT, .RIGHT_ALT:
			return true
	}
	return false
}

@private _check_action_released :: proc(key : rl.KeyboardKey) {
	for id, action in actions_pressed {
		for bind in action.binds {
			if b, ok := bind.(KeyboardBind); ok {
				if b.key == key \
				|| _is_mod_key(key) && !_are_mods_ok(b) {
					_set_action_as_released(action)
					return
				}
			}
		}
	}

	// for id, action in actions {
	// 	for bind in action.binds  {
	// 		if b, ok := bind.(KeyboardBind); ok {
	// 			print(id, key, id in actions_pressed, !_are_mods_ok(b))
	// 			if id in actions_pressed && !_are_mods_ok(b) {
	// 				_set_action_as_released(action)
	// 				print("--------------")
	// 				return
	// 			}
	// 		}
	// 	}
	// }
	// print("--------------")
}

@private _are_mods_ok :: proc(b: InputBinds) -> bool {
	switch type in b {
		case KeyboardBind: if len(b.(KeyboardBind).mods) == 0 do return true
		case MouseBind:    if len(b.(MouseBind).mods) == 0 do return true
		case GamepadBind:  return true
	}

	all_mods_ok := true
	if !_check_mod(b, .LEFT_CONTROL, .RIGHT_CONTROL) { all_mods_ok = false; print("CONTROL", !_check_mod(b, .LEFT_CONTROL, .RIGHT_CONTROL))}
	if !_check_mod(b, .LEFT_SHIFT,   .RIGHT_SHIFT)   { all_mods_ok = false; print("SHIFT", !_check_mod(b, .LEFT_SHIFT,   .RIGHT_SHIFT))}
	if !_check_mod(b, .LEFT_ALT,     .RIGHT_ALT)     { all_mods_ok = false; print("ALT", !_check_mod(b, .LEFT_ALT,     .RIGHT_ALT))}
	return all_mods_ok
}

@private _check_mod :: proc(b: InputBinds, lmod, rmod: rl.KeyboardKey) -> bool {
	mods:map[rl.KeyboardKey]bool
	// defer delete(mods)
	#partial switch type in b {
		case KeyboardBind: mods = b.(KeyboardBind).mods
		case MouseBind:    mods = b.(MouseBind).mods
	}

	if mods[lmod] && mods[rmod] {
		if !(lmod in pressed_states || rmod in pressed_states) {
			return false
		}
	} else if mods[lmod] {
		if lmod not_in pressed_states do return false
		if rmod in pressed_states do return false
	} else if mods[rmod] {
		if rmod not_in pressed_states do return false
		if lmod in pressed_states do return false
	}
	return true
}

// binds the action 'id' to a set of key combos
@private _bind :: proc(id: string, combos: []string) {
	if id in actions {
		__WARNING("action %s is already bound -- skipping", id)
		return
	}

	actions[id] = InputAction {
		id    = id,
		binds = make([dynamic]InputBinds),
	}

	action := &actions[id]

	for b in combos {
		if b == "" {
			__WARNING("invalid key combo for '%s'", id)
			continue
		}

		parts := strings.split(b, " ", context.temp_allocator)

		key_str := strings.to_lower(parts[len(parts)-1], context.temp_allocator)
		mod_strings:[]string

		//if the main key is a mod key, then it can't use mod keys
		if len(parts) > 1 && key_str not_in mod_key_lut {
			mod_strings = parts[:len(parts)-1]
			for i in 0..<len(mod_strings) {
				mod_strings[i] = strings.to_lower(mod_strings[i], context.temp_allocator)
			}
		}

		// check which type of input this is (keyboard, mouse, etc)
		// and create appropriate InputBind
		if key_str in input_keyboard_map {
			key := input_keyboard_map[key_str]
			mods := map[rl.KeyboardKey]bool {
				.LEFT_SHIFT    = false,
				.RIGHT_SHIFT   = false,
				.LEFT_CONTROL  = false,
				.RIGHT_CONTROL = false,
				.LEFT_ALT      = false,
				.RIGHT_ALT     = false,
			}
			for mod_str in mod_strings {
				if mod_str in input_keyboard_map {
					mods[input_keyboard_map[mod_str]] = true
				} else {
					switch mod_str {
						case "ctrl":
							mods[input_keyboard_map["lctrl"]] = true
							mods[input_keyboard_map["rctrl"]] = true
						case "shift":
							mods[input_keyboard_map["lshift"]] = true
							mods[input_keyboard_map["rshift"]] = true
						case "alt":
							mods[input_keyboard_map["lalt"]] = true
							mods[input_keyboard_map["ralt"]] = true
						case:
							__WARNING("unknown mod key '%s' - skipping '%s' binding", mod_str, id)
					}
				}
			}

			append(&action.binds, KeyboardBind {
				key = key,
				mods = mods,
			})


		} else if key_str in input_mouse_map {

		} else {
			__WARNING("unknown key '%s' - skipping '%s' action binding", key_str, id)
		}
	}
	// print(action)
}





@private mod_key_lut := map[string]bool {
	"lshift" = true,
	"rshift" = true,
	"lctrl"  = true,
	"rctrl"  = true,
	"lalt"   = true,
	"ralt"   = true,
}

@private input_keyboard_map := map[string]rl.KeyboardKey {
	"'" = .APOSTROPHE,
	"," = .COMMA,
	"-" = .MINUS,
	"." = .PERIOD,
	"/" = .SLASH,
	"0" = .ZERO,
	"1" = .ONE,
	"2" = .TWO,
	"3" = .THREE,
	"4" = .FOUR,
	"5" = .FIVE,
	"6" = .SIX,
	"7" = .SEVEN,
	"8" = .EIGHT,
	"9" = .NINE,
	";" = .SEMICOLON,
	"=" = .EQUAL,
	"a" = .A,
	"b" = .B,
	"c" = .C,
	"d" = .D,
	"e" = .E,
	"f" = .F,
	"g" = .G,
	"h" = .H,
	"i" = .I,
	"j" = .J,
	"k" = .K,
	"l" = .L,
	"m" = .M,
	"n" = .N,
	"o" = .O,
	"p" = .P,
	"q" = .Q,
	"r" = .R,
	"s" = .S,
	"t" = .T,
	"u" = .U,
	"v" = .V,
	"w" = .W,
	"x" = .X,
	"y" = .Y,
	"z" = .Z,

		// Function keys
	"space"         = .SPACE,
	"escape"        = .ESCAPE,
	"enter"         = .ENTER,
	"tab"           = .TAB,
	"backspace"     = .BACKSPACE,
	"insert"        = .INSERT,
	"delete"        = .DELETE,
	"right"         = .RIGHT,
	"left"          = .LEFT,
	"down"          = .DOWN,
	"up"            = .UP,
	"page_up"       = .PAGE_UP,
	"page_down"     = .PAGE_DOWN,
	"home"          = .HOME,
	"end"           = .END,
	"caps_lock"     = .CAPS_LOCK,
	"scroll_lock"   = .SCROLL_LOCK,
	"num_lock"      = .NUM_LOCK,
	"prtscr"        = .PRINT_SCREEN,
	"print_screen"  = .PRINT_SCREEN,
	"pause"         = .PAUSE,
	"f1"            = .F1,
	"f2"            = .F2,
	"f3"            = .F3,
	"f4"            = .F4,
	"f5"            = .F5,
	"f6"            = .F6,
	"f7"            = .F7,
	"f8"            = .F8,
	"f9"            = .F9,
	"f10"           = .F10,
	"f11"           = .F11,
	"f12"           = .F12,
	"lshift"        = .LEFT_SHIFT,
	"rshift"        = .RIGHT_SHIFT,
	"lctrl"         = .LEFT_CONTROL,
	"rctrl"         = .RIGHT_CONTROL,
	"lalt"          = .LEFT_ALT,
	"ralt"          = .RIGHT_ALT,
	"lsuper"        = .LEFT_SUPER,
	"rsuper"        = .RIGHT_SUPER,
	"kb_menu"       = .KB_MENU,
	"<"             = .LEFT_BRACKET,
	"\\"            = .BACKSLASH,
	">"             = .RIGHT_BRACKET,
	"grave"         = .GRAVE,

		// Keypad keys
	"kp_0"        = .KP_0,
	"kp_1"        = .KP_1,
	"kp_2"        = .KP_2,
	"kp_3"        = .KP_3,
	"kp_4"        = .KP_4,
	"kp_5"        = .KP_5,
	"kp_6"        = .KP_6,
	"kp_7"        = .KP_7,
	"kp_8"        = .KP_8,
	"kp_9"        = .KP_9,
	"kp_decimal"  = .KP_DECIMAL,
	"kp_divide"   = .KP_DIVIDE,
	"kp_multiply" = .KP_MULTIPLY,
	"kp_subtract" = .KP_SUBTRACT,
	"kp_add"      = .KP_ADD,
	"kp_enter"    = .KP_ENTER,
	"kp_equal"    = .KP_EQUAL,

		// Android key buttons
	"back" = .BACK,
	"menu" = .MENU,
	"volume_up" = .VOLUME_UP,
	"volume_down" = .VOLUME_DOWN,
}

@private input_mouse_map := map[string]rl.MouseButton {
	"m1"      = .LEFT,
	"m2"      = .RIGHT,
	"m3"      = .MIDDLE,
	"m4"      = .SIDE,
	"m5"      = .EXTRA,
	"forward" = .FORWARD,
	"back"    = .BACK,
}

@private input_gamepad_map := map[string]rl.GamepadButton {
	"gp_lup"    = .LEFT_FACE_UP,
	"gp_lright" = .LEFT_FACE_RIGHT,
	"gp_ldown"  = .LEFT_FACE_DOWN,
	"gp_lleft"  = .LEFT_FACE_LEFT,
	"gp_rup"    = .RIGHT_FACE_UP,
	"gp_rright" = .RIGHT_FACE_RIGHT,
	"gp_rdown"  = .RIGHT_FACE_DOWN,
	"gp_rleft"  = .RIGHT_FACE_LEFT,
	"gp_lt1"    = .LEFT_TRIGGER_1,
	"gp_lt2"    = .LEFT_TRIGGER_2,
	"gp_rt1"    = .RIGHT_TRIGGER_1,
	"gp_rt2"    = .RIGHT_TRIGGER_2,
	"gp_ml"     = .MIDDLE_LEFT,     // PS3 Select
	"gp_select" = .MIDDLE_LEFT,     // PS3 Select
	"gp_m"      = .MIDDLE,          // PS Button/XBOX Button
	"gp_mr"     = .MIDDLE_RIGHT,    // PS3 Start
	"gp_start"  = .MIDDLE_RIGHT,    // PS3 Start
	"gp_ltb"    = .LEFT_THUMB,
	"gp_rtb"    = .RIGHT_THUMB,
}
