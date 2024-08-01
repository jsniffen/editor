package main

import rl "vendor:raylib"

when ODIN_OS == .Windows {
	FONT_PATH :: "C:\\Windows\\Fonts\\consola.ttf"
} else when ODIN_OS == .Linux {
	FONT_PATH :: "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
}

FONT_SIZE :: 32
LINE_HEIGHT :: 32

COLOR_TAG_BG := rl.GetColor(0xEAFFFFFF)
COLOR_TAG_TEXT := rl.GetColor(0x00000FF)
COLOR_TAG_TEXT_SELECT := rl.GetColor(0x9EEEEEFF)

COLOR_BODY_BG := rl.GetColor(0xFFFFEAFF)
COLOR_BODY_TEXT := rl.GetColor(0x000000FF)
COLOR_BODY_TEXT_SELECT := rl.GetColor(0xEEEE9EFF)

SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 720

Editor :: struct {
	focused_buffer: ^Buffer,
	font: rl.Font,
	load_buffer: ^Buffer,
}

FrameState :: struct {
	mouse_position: rl.Vector2,
	left_mouse_pressed: bool,
	middle_mouse_pressed: bool,
	right_mouse_pressed: bool,
	mouse_selection: rl.Rectangle,

	// when there is a mouse selection, this encodes
	// where the mouse is relative to the selection box.
	// [ 1,  1]: top right
	// [ 1, -1]: bottom right
	// [-1, -1]: bottom left
	// [-1,  1]: top left
	mouse_selection_pos: rl.Vector2,
}

window :: struct {
	tag: Buffer,
	body: Buffer,
}

win_init :: proc(win: ^window) {
	buf_init(&win.tag)
	buf_init(&win.body)
}

win_draw :: proc(win: ^window, ed: ^Editor, state: FrameState, rec: rl.Rectangle) {
	rec := rec

	rl.DrawRectangleRec(rec, COLOR_TAG_BG)
	buf_draw(&win.tag, ed, state, rec, COLOR_TAG_TEXT, COLOR_TAG_TEXT_SELECT)

	rec.y += LINE_HEIGHT
	rl.DrawRectangleRec(rec, COLOR_BODY_BG)
	buf_draw(&win.body, ed, state, rec, COLOR_BODY_TEXT, COLOR_BODY_TEXT_SELECT)
}

main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "test")

	rl.SetWindowState({.WINDOW_RESIZABLE})
	rl.SetTargetFPS(60)

	ed: Editor

	ed.font = rl.LoadFontEx(FONT_PATH, FONT_SIZE, nil, 0)

	win: window
	win_init(&win)

	ed.load_buffer = &win.body

	mouse_select_start, mouse_select_end: rl.Vector2

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

		state := FrameState{
			mouse_position = rl.GetMousePosition(),
			left_mouse_pressed = rl.IsMouseButtonPressed(.LEFT),
			middle_mouse_pressed = rl.IsMouseButtonPressed(.MIDDLE),
			right_mouse_pressed = rl.IsMouseButtonPressed(.RIGHT),
		}

		if state.left_mouse_pressed {
			mouse_select_start = state.mouse_position
			mouse_select_end = mouse_select_start
		} else if rl.IsMouseButtonDown(.LEFT) || rl.IsMouseButtonReleased(.LEFT) {
			mouse_select_end = state.mouse_position
		} else {
			mouse_select_start = state.mouse_position
			mouse_select_end = state.mouse_position
		}

		state.mouse_selection.x = min(mouse_select_start.x, mouse_select_end.x)
		state.mouse_selection.y = min(mouse_select_start.y, mouse_select_end.y)
		state.mouse_selection.width = abs(mouse_select_start.x - mouse_select_end.x)
		state.mouse_selection.height = abs(mouse_select_start.y - mouse_select_end.y)

		state.mouse_selection_pos.x = 1 if mouse_select_end.x > mouse_select_start.x else -1
		state.mouse_selection_pos.y = 1 if mouse_select_end.y > mouse_select_start.y else -1 

		rl.BeginDrawing()

		rl.ClearBackground(rl.PURPLE)

		w, h: = f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())

		win_draw(&win, &ed, state, {0, 0, w, h})

		rl.EndDrawing()
	}
}
