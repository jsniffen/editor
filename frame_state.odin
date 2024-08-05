package main

import rl "vendor:raylib"

FrameState :: struct {
	mouse_position: rl.Vector2,
	mouse_delta: rl.Vector2,

	left_mouse_pressed: bool,
	left_mouse_pressed_pos: rl.Vector2,
	left_mouse_down: bool,
	left_mouse_up: bool,

	middle_mouse_pressed: bool,

	right_mouse_pressed: bool,

	mouse_selection: rl.Rectangle,
	mouse_wheel_move: f32,

	// when there is a mouse selection, this encodes
	// where the mouse is relative to the selection box.
	// [ 1,  1]: top right
	// [ 1, -1]: bottom right
	// [-1, -1]: bottom left
	// [-1,  1]: top left
	mouse_selection_pos: rl.Vector2,
	mouse_select_start: rl.Vector2,
	mouse_select_end: rl.Vector2
}

fs_update :: proc(state: ^FrameState) {
	state.mouse_position = rl.GetMousePosition()

	state.left_mouse_pressed = rl.IsMouseButtonPressed(.LEFT)
	state.left_mouse_down = rl.IsMouseButtonDown(.LEFT)
	state.left_mouse_up = rl.IsMouseButtonUp(.LEFT)
	if state.left_mouse_pressed {
		state.left_mouse_pressed_pos = state.mouse_position
	}

	state.middle_mouse_pressed = rl.IsMouseButtonPressed(.MIDDLE)
	state.right_mouse_pressed = rl.IsMouseButtonPressed(.RIGHT)

	state.mouse_wheel_move = rl.GetMouseWheelMoveV().y

	if state.left_mouse_pressed {
		state.mouse_select_start = state.mouse_position
		state.mouse_select_end = state.mouse_select_start
	} else if rl.IsMouseButtonDown(.LEFT) || rl.IsMouseButtonReleased(.LEFT) {
		state.mouse_select_end = state.mouse_position
	} else {
		state.mouse_select_start = state.mouse_position
		state.mouse_select_end = state.mouse_position
	}

	state.mouse_delta = rl.GetMouseDelta()
	state.mouse_selection.x = min(state.mouse_select_start.x, state.mouse_select_end.x)
	state.mouse_selection.y = min(state.mouse_select_start.y, state.mouse_select_end.y)
	state.mouse_selection.width = abs(state.mouse_select_start.x - state.mouse_select_end.x)
	state.mouse_selection.height = abs(state.mouse_select_start.y - state.mouse_select_end.y)

	state.mouse_selection_pos.x = 1 if state.mouse_select_end.x > state.mouse_select_start.x else -1
	state.mouse_selection_pos.y = 1 if state.mouse_select_end.y > state.mouse_select_start.y else -1 
}
