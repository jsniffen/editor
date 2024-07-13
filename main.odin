package main

import "core:fmt"

import rl "vendor:raylib"

LINE_HEIGHT :: 30
MARGIN :: 5

// TODO(Julian): Configuration management...
FONT_FILENAME :: "C:\\Windows\\Fonts\\consola.ttf"
FONT_SPACING :: 1
FONT_SIZE :: 24

Mode :: enum {INSERT, NORMAL}

main :: proc() {
	rl.SetWindowState({.WINDOW_RESIZABLE})

	rl.InitWindow(512, 512, "Editor")
	defer rl.CloseWindow()

	rl.SetTargetFPS(30)
	rl.SetExitKey(rl.KeyboardKey.KEY_NULL)

	font := rl.LoadFontEx(FONT_FILENAME, FONT_SIZE, nil, 0)
	fmt.println(font)

	gap_buffer: GapBuffer = {
		end = 256,
		len = 256,
	}

	mode: Mode = .INSERT

	for !rl.WindowShouldClose() {
		for r := rl.GetCharPressed(); r != 0; r = rl.GetCharPressed() {
			gb_insert(&gap_buffer, r)
		}

		for key := rl.GetKeyPressed(); key != .KEY_NULL; key = rl.GetKeyPressed() {
			#partial switch key {
			case .BACKSPACE:
				gb_delete(&gap_buffer)

			case .ESCAPE:
				mode = .NORMAL

			case .ENTER:
				gb_insert(&gap_buffer, '\n')

			case .I:
				if mode == .NORMAL {
					mode = .INSERT
				}
			}
		}

		rl.ClearBackground(rl.BLACK)

		rl.BeginDrawing()
		{
			screen_height := rl.GetScreenHeight()
			screen_width  := rl.GetScreenWidth()

			x, y, w, h: i32

			w = screen_width
			h = LINE_HEIGHT

			{
				// Draw the Title Bar
				draw_title_bar(font, x, y, w, h)
				y += h
			}

			{
				// Draw all of the buffers
				h = screen_height-y
				draw_gap_buffer(&gap_buffer, font, x, y, w, h)
				y += h-LINE_HEIGHT
			}

			{
				// Draw the Status Bar
				h = LINE_HEIGHT
				draw_status_bar(mode, font, x, y, w, h)
			}
		}
		rl.EndDrawing()
	}
}

draw_gap_buffer :: proc(gb: ^GapBuffer, font: rl.Font, x, y, w, h: i32) {
	rl.DrawRectangle(x, y, w, h, rl.DARKGRAY)

	text := gb_text(gb)
	pos := rl.Vector2{f32(x+MARGIN), f32(y+MARGIN)}
	rl.DrawTextEx( font, text, pos, FONT_SIZE, FONT_SPACING, rl.WHITE)
}

draw_title_bar :: proc(font: rl.Font, x, y, w, h: i32) {
	rl.DrawRectangle(x, y, w, h, rl.PURPLE)

	pos := rl.Vector2{f32(x+MARGIN), f32(y+MARGIN)}
	rl.DrawTextEx(font, "Editor", pos, FONT_SIZE, FONT_SPACING, rl.WHITE)
}

draw_status_bar :: proc(m: Mode, font: rl.Font, x, y, w, h: i32) {
	rl.DrawRectangle(x, y, w, h, rl.BLUE)

	pos := rl.Vector2{f32(x+MARGIN), f32(y+MARGIN)}
	text: cstring

	switch m {
	case .INSERT:
		text = "INSERT"
	case .NORMAL:
		text = "NORMAL"
	}
	rl.DrawTextEx(font, text, pos, FONT_SIZE, FONT_SPACING, rl.WHITE)
}
