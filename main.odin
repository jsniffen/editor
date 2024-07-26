package main

import rl "vendor:raylib"
import "core:fmt"

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

editor :: struct {
	focused_gb: ^gap_buffer,
	font: rl.Font,
}

frame_state :: struct {
	mouse_position: rl.Vector2,
	left_mouse_pressed: bool,
	middle_mouse_pressed: bool,
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
	tag: gap_buffer,
	body: gap_buffer,
}

win_init :: proc(win: ^window) {
	gb_init(&win.tag, 256)
	gb_init(&win.body, 256)
}

win_draw :: proc(win: ^window, ed: ^editor, state: frame_state, rec: rl.Rectangle) {
	rec := rec

	rl.DrawRectangleRec(rec, COLOR_TAG_BG)
	gb_draw(&win.tag, ed, state, rec, COLOR_TAG_TEXT, COLOR_TAG_TEXT_SELECT)

	rec.y += LINE_HEIGHT
	rl.DrawRectangleRec(rec, COLOR_BODY_BG)
	gb_draw(&win.body, ed, state, rec, COLOR_BODY_TEXT, COLOR_BODY_TEXT_SELECT)
}

main :: proc() {
	rl.InitWindow(400, 400, "test")

	rl.SetWindowState({.WINDOW_RESIZABLE})
	rl.SetTargetFPS(60)

	ed: editor

	ed.font = rl.LoadFontEx(FONT_PATH, FONT_SIZE, nil, 0)

	win: window
	win_init(&win)

	mouse_select_start, mouse_select_end: rl.Vector2

	for !rl.WindowShouldClose() {
		if ed.focused_gb != nil {
			for r := rl.GetCharPressed(); r != 0; r = rl.GetCharPressed() {
				gb_insert(ed.focused_gb, r)
			}

			for k := rl.GetKeyPressed(); k != .KEY_NULL; k = rl.GetKeyPressed() {
				#partial switch k {
				case .ENTER:
					gb_insert(ed.focused_gb, '\n')
				case .TAB:
					gb_insert(ed.focused_gb, '\t')
				case .BACKSPACE:
					gb_delete(ed.focused_gb)
				case .LEFT:
					gb_reset_selection(ed.focused_gb)
					gb_move(ed.focused_gb, -1)
				case .RIGHT:
					gb_reset_selection(ed.focused_gb)
					gb_move(ed.focused_gb, 1)
				}
			}
		}

		state := frame_state{
			mouse_position = rl.GetMousePosition(),
			left_mouse_pressed = rl.IsMouseButtonPressed(.LEFT),
			middle_mouse_pressed = rl.IsMouseButtonPressed(.MIDDLE),
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
