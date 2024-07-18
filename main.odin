package main

import "core:fmt"

import rl "vendor:raylib"

SCREEN_WIDTH :: 1024
SCREEN_HEIGHT :: 512

LINE_HEIGHT :: 30
MARGIN :: 5

// TODO(Julian): Configuration management...
FONT_FILENAME :: "C:\\Windows\\Fonts\\consola.ttf"
FONT_SPACING :: 1
FONT_SIZE :: 24

Mode :: enum {INSERT, NORMAL, MODAL}

main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Editor")
	defer rl.CloseWindow()

	rl.SetExitKey(rl.KeyboardKey.KEY_NULL)
	rl.SetTargetFPS(30)
	rl.SetWindowState({.WINDOW_RESIZABLE})

	font := rl.LoadFontEx(FONT_FILENAME, FONT_SIZE, nil, 0)

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

			case .F5:
				mode = .MODAL

			case .ENTER:
				gb_insert(&gap_buffer, '\n')

			case .I:
				if mode == .NORMAL || mode == .MODAL {
					mode = .INSERT
				}

			case .LEFT:
				gb_move(&gap_buffer, gap_buffer.start-1)

			case .RIGHT:
				gb_move(&gap_buffer, gap_buffer.start+1)

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

			// Draw the modal
			if mode == .MODAL {
				x, y = screen_width/4, screen_height/4
				w, h = x*2, y*2

				draw_modal(x, y, w, h)
			}
		}
		rl.EndDrawing()
	}
}

draw_gap_buffer :: proc(gb: ^GapBuffer, font: rl.Font, x, y, w, h: i32) {
	rl.DrawRectangle(x, y, w, h, rl.DARKGRAY)

	prefix, suffix := gb_text(gb)

	pos := rl.Vector2{f32(x+MARGIN), f32(y+MARGIN)}

	index_to_move := gb.start
	mouse_is_down := rl.IsMouseButtonPressed(.LEFT)
	mouse_position := rl.GetMousePosition()
	fmt.println(mouse_is_down, mouse_position)

	for codepoint, i in prefix {
		if codepoint == '\n' {
			pos.x = MARGIN
			pos.y += LINE_HEIGHT
		} else {
			rl.DrawTextCodepoint(font, codepoint, pos, FONT_SIZE, rl.WHITE)
			rect := rl.GetGlyphAtlasRec(font, codepoint)

			if mouse_is_down {
				if rl.CheckCollisionPointRec(mouse_position, {
					x = pos.x, y = pos.y, width = rect.width, height = rect.height,
				}) {
					index_to_move = i
				}
			}

			pos.x += rect.width
		}

	}

	rl.DrawRectangle(i32(pos.x), i32(pos.y), 4, LINE_HEIGHT, rl.BLACK)

	for codepoint, i in suffix {
		if codepoint == '\n' {
			pos.x = MARGIN
			pos.y += LINE_HEIGHT
		} else {
			rl.DrawTextCodepoint(font, codepoint, pos, FONT_SIZE, rl.WHITE)
			rect := rl.GetGlyphAtlasRec(font, codepoint)

			if mouse_is_down {
				if rl.CheckCollisionPointRec(mouse_position, {
					x = pos.x, y = pos.y, width = rect.width, height = rect.height,
				}) {
					index_to_move = i+len(prefix)
				}
			}

			pos.x += rect.width
		}
	}

	gb_move(gb, index_to_move)
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
	case .MODAL:
		text = "MODAL"
	}
	rl.DrawTextEx(font, text, pos, FONT_SIZE, FONT_SPACING, rl.WHITE)
}

draw_modal :: proc(x, y, w, h: i32) {
	round :: 0.5
	segs :: 50
	r := rl.Rectangle{f32(x), f32(y), f32(w), f32(h)}

	rl.DrawRectangleRounded(r, round, segs, rl.BLACK)
	rl.DrawRectangleRoundedLines(r, round, segs, 1, rl.YELLOW)
}
