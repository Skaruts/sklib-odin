package sl

import "core:slice"
import rl "vendor:raylib"


@private KEY_REPEAT_COOLDOWN :: 0.08
@private KEY_REPEAT_INITIAL_COOLDOWN :: 0.28


KeyboardEvent :: struct {
	key       : rl.KeyboardKey,
	pressed   : bool,
	is_repeat : bool,
}

MouseButtonEvent :: struct {
	button  : rl.MouseButton,
	x, y    : int,
	pressed : bool,
	istouch : bool,
	presses : int,
}

MouseMoveEvent :: struct {
	x, y, dx, dy:int,
}

// MouseWheelEvent :: struct {
// 	// GetMouseWheelMove     :: proc() -> f32
// 	x, y : int,
// }

TextEvent :: struct {
	char : rune,
}


InputEvent :: union {
	KeyboardEvent,
	MouseButtonEvent,
	MouseMoveEvent,
	// MouseWheelEvent,
	TextEvent,
}

KeyboardBind :: struct {
	key : rl.KeyboardKey,
	mods : map[rl.KeyboardKey]bool,
}

MouseBind :: struct {
	button : rl.MouseButton,
	mods : map[rl.KeyboardKey]bool,
}

GamepadBind :: struct {
	button : rl.GamepadButton,
}

InputBinds :: union {
	KeyboardBind,
	MouseBind,
	GamepadBind,
}

InputAction :: struct {
	id     : string,
	frames : int,
	binds  : [dynamic]InputBinds,
}


@private EventState :: struct {
	key       : rl.KeyboardKey,
	frames    : int,
	is_repeat : bool,
	time      : f32,
}


@private input_events     : [dynamic]InputEvent
@private pressed_states   : map[rl.KeyboardKey]EventState
@private released_states  : map[rl.KeyboardKey]EventState
@private actions          : map[string]InputAction
@private actions_pressed  : map[string]InputAction
@private actions_released : map[string]InputAction



@private store_keyboard_event :: proc(k:rl.KeyboardKey, pressed:bool, is_repeat:=false) {
	append(&input_events, KeyboardEvent {
		key = k,
		pressed = pressed,
		is_repeat = is_repeat,
	})
}

@private _init_input :: proc() {
	pressed_states  = make(map[rl.KeyboardKey]EventState)
	released_states = make(map[rl.KeyboardKey]EventState)
}

@private _destroy_input :: proc() {
	delete(input_events)
	delete(pressed_states)
	delete(released_states)

	for _, action in &actions {
		_destroy_action(&action)
	}

	delete(actions)
	delete(actions_pressed)
	delete(actions_released)
}


// GetGamepadButtonPressed
// GetCharPressed
@private _update_input :: proc(dt:f32) {
	clear(&input_events)
	clear(&released_states)
	clear(&actions_released)

	_increase_action_timers(dt)

	// get all currrently pressed keys
	keys := make([dynamic]rl.KeyboardKey)
	defer delete(keys)
	new_k := rl.GetKeyPressed()
	for new_k != nil {
		append(&keys, new_k)
		new_k = rl.GetKeyPressed()
	}

	// any previous pressed keys not currently pressed were released
	for k, kp in pressed_states {
		_, found := slice.linear_search(keys[:], k)
		if !found && !rl.IsKeyDown(k) {
			released_states[k] = kp
			delete_key(&pressed_states, k)
			store_keyboard_event(k, false)
			_check_action_released(k)
		}
	}
	// printn(keys, pressed_states, released_states)

	// store new keys and update key timers
	for k in keys {
		if k not_in pressed_states {
			pressed_states[k] = EventState {
				key = k,
				time = KEY_REPEAT_INITIAL_COOLDOWN,
			}
			store_keyboard_event(k, true)
			_check_action_pressed(k)
		}
	}

	for k, kp in &pressed_states {
		kp.is_repeat = false
		kp.frames += 1
		kp.time -= dt

		if kp.time <= 0 {
			kp.is_repeat = true
			kp.time      = KEY_REPEAT_COOLDOWN
			// add an input event when repeat happens
			store_keyboard_event(k, true)
			// _check_action_pressed(k)
		}
	}


	// printf("%d    ies: %d | ps: %d | rs: %d | as: %d | ap: %d | ar: %d\n", _internal.frame, len(input_events), len(pressed_states), len(released_states), len(actions), len(actions_pressed), len(actions_released))


	// for k, kp in &pressed_states {

	// }


	// print(keys)
	// print(pressed_states)
	// print(released_states)
	// print("-----------------------")
}




/*******************************************************************************

		Public-facing API (listed in sl_api.odin)

*/

@private _input_has_events :: proc() -> bool {
	return len(input_events) > 0
}

@private _input_pop_event :: proc() -> InputEvent {
	event := input_events[0]
	ordered_remove(&input_events, 0)
	return event
}


// TODO: add code to test an array of keys
@private _key_pressed :: proc(k: rl.KeyboardKey) -> bool {
	return k in pressed_states && pressed_states[k].frames == 0
}

@private _key_down :: proc(k: rl.KeyboardKey) -> bool {
	return k in pressed_states && pressed_states[k].frames > 0
}

@private _key_released :: proc(k: rl.KeyboardKey) -> bool {
	return k in released_states
}



