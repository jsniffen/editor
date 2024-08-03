package main

import rl "vendor:raylib"
import "core:fmt"

/*
when ODIN_OS == .Windows {
	FONT_PATH :: "C:\\Windows\\Fonts\\consola.ttf"
} else when ODIN_OS == .Linux {
	FONT_PATH :: "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
}
*/
FONT_PATH :: "Go-Regular.ttf"

FONT_SIZE :: 32
LINE_HEIGHT :: FONT_SIZE
MARGIN :: 5

COLOR_TAG_BG := rl.GetColor(0xEAFFFFFF)
COLOR_TAG_TEXT := rl.GetColor(0x00000FF)
COLOR_TAG_TEXT_SELECT := rl.GetColor(0x9EEEEEFF)

COLOR_BODY_BG := rl.GetColor(0xFFFFEAFF)
COLOR_BODY_TEXT := rl.GetColor(0x000000FF)
COLOR_BODY_TEXT_SELECT := rl.GetColor(0xEEEE9EFF)

COLOR_SCROLLBAR_FG := rl.GetColor(0xFFFFEAFF)
COLOR_SCROLLBAR_BG := rl.GetColor(0x99994CFF)
COLOR_SCROLLBAR_BORDER := rl.GetColor(0x000000FF)
SCROLLBAR_WIDTH :: 5*LINE_HEIGHT/6

COLOR_BUTTON_BG := rl.GetColor(0x8888CCFF)
COLOR_BUTTON_FG := rl.GetColor(0x000099FF)
BUTTON_WIDTH :: SCROLLBAR_WIDTH
BUTTON_MARGIN :: BUTTON_WIDTH/8

SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 720

Editor :: struct {
	focused_buffer: ^Buffer,
	font: rl.Font,
	load_buffer: ^Buffer,
}

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
}

main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "test")

	rl.SetWindowState({.WINDOW_RESIZABLE})
	rl.SetTargetFPS(60)

	ed: Editor

	ed.font = rl.LoadFontEx(FONT_PATH, FONT_SIZE, nil, 0)

	win: Window
	win_init(&win)

	ed.load_buffer = &win.body

	mouse_select_start, mouse_select_end: rl.Vector2

	state := FrameState{}

	for !rl.WindowShouldClose() {
		if ed.focused_buffer != nil {
			for r := rl.GetCharPressed(); r != 0; r = rl.GetCharPressed() {
				buf_insert(ed.focused_buffer, r)
			}

			for k := rl.GetKeyPressed(); k != .KEY_NULL; k = rl.GetKeyPressed() {
				#partial switch k {
				case .ENTER:
					buf_insert(ed.focused_buffer, '\n')
				case .TAB:
					buf_insert(ed.focused_buffer, '\t')
				case .LEFT:
					buf_cursor_move(ed.focused_buffer, -1)
				case .RIGHT:
					buf_cursor_move(ed.focused_buffer, 1)
				case .BACKSPACE:
					buf_delete(ed.focused_buffer)
				}
			}
		}

		state.mouse_position = rl.GetMousePosition()

		state.left_mouse_pressed = rl.IsMouseButtonPressed(.LEFT)
		state.left_mouse_down = rl.IsMouseButtonDown(.LEFT)
		state.left_mouse_up = rl.IsMouseButtonUp(.LEFT)

		state.middle_mouse_pressed = rl.IsMouseButtonPressed(.MIDDLE)
		state.right_mouse_pressed = rl.IsMouseButtonPressed(.RIGHT)

		state.mouse_wheel_move = rl.GetMouseWheelMoveV().y

		if state.left_mouse_pressed {
			mouse_select_start = state.mouse_position
			mouse_select_end = mouse_select_start
		} else if rl.IsMouseButtonDown(.LEFT) || rl.IsMouseButtonReleased(.LEFT) {
			mouse_select_end = state.mouse_position
		} else {
			mouse_select_start = state.mouse_position
			mouse_select_end = state.mouse_position
		}

		state.mouse_delta = rl.GetMouseDelta()
		state.mouse_selection.x = min(mouse_select_start.x, mouse_select_end.x)
		state.mouse_selection.y = min(mouse_select_start.y, mouse_select_end.y)
		state.mouse_selection.width = abs(mouse_select_start.x - mouse_select_end.x)
		state.mouse_selection.height = abs(mouse_select_start.y - mouse_select_end.y)

		state.mouse_selection_pos.x = 1 if mouse_select_end.x > mouse_select_start.x else -1
		state.mouse_selection_pos.y = 1 if mouse_select_end.y > mouse_select_start.y else -1 

		rl.BeginDrawing()

		rl.ClearBackground(rl.ORANGE)

		w, h: = f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())

		win_draw(&win, &ed, state, {0, 0, w, h})

		rl.EndDrawing()
	}
}
