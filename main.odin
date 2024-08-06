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

FONT_SIZE :: 20
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

WINDOW_DIVIDER_THICKNESS :: 1
LINE_THICKNESS :: 2
LINE_COLOR := rl.GetColor(0x000000FF)

SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 720

main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "test")

	rl.SetWindowState({.WINDOW_RESIZABLE})
	rl.SetTargetFPS(60)

	ed: Editor
	ed_init(&ed)

	frame_state: FrameState

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

		fs_update(&frame_state)

		rl.BeginDrawing()

		rl.ClearBackground(rl.ORANGE)

		w, h: = f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())

		ed_draw(&ed, frame_state, {0, 0, w, h})

		rl.EndDrawing()
	}
}
