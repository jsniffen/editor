package main

import rl "vendor:raylib"
import "core:fmt"

FONT_PATH :: "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
FONT_SIZE :: 32
LINE_HEIGHT :: 32

frame_state :: struct {
	mouse_position: rl.Vector2,
	mouse_pressed: bool,
	mouse_selection: rl.Rectangle,
}

gap_buffer :: struct {
	// the text data
	data: [dynamic]rune,

	// the start index of the gap, or where
	// the cursor currently is
	start: int,

	// the end index of the gap
	end: int,

	// the capacity of the gap buffer
	cap: int,

	// the start index of a selection
	select_start: int,

	// the end index of a selection
	select_end: int,
}

gb_init :: proc(gb: ^gap_buffer, size: int) {
	gb.data = make([dynamic]rune, size, size)
	gb.start = 0
	gb.end = size
	gb.cap = size
}

gb_insert :: proc(gb: ^gap_buffer, r: rune) {
	gb.data[gb.start] =  r
	gb.start += 1
}

gb_delete :: proc(gb: ^gap_buffer) {
	gb.start -= 1
}

gb_move :: proc(gb: ^gap_buffer, diff: int) {
	if gb.start + diff < 0 || diff == 0 {
		return
	}

	if diff < 0 {
		for i := 0; i < -1*diff; i += 1 {
			gb.data[gb.end-1] = gb.data[gb.start-1];
			gb.start -= 1
			gb.end -= 1
		}
	} else {
		if gb.end + diff > gb.cap {
			return;
		}

		for i := 0; i < diff; i += 1 {
			gb.data[gb.start] = gb.data[gb.end];
			gb.start += 1
			gb.end += 1
		}
	}
}

gb_draw :: proc(gb: ^gap_buffer, font: rl.Font, state: frame_state, x, y, w, h: i32) {
	pos := rl.Vector2{f32(x), f32(y)}

	to_move := 0
	cursor: rl.Rectangle

	for i := 0; i < gb.cap; i += 1 {
		if i == gb.start {
			cursor = {x = pos.x, y = pos.y, width = 2, height = LINE_HEIGHT}
			i = gb.end - 1
			continue
		}
		r := gb.data[i]

		if r == '\n' {
			pos.x = f32(x)
			pos.y += LINE_HEIGHT
			continue
		}

		info := rl.GetGlyphInfo(font, r)

		rect := rl.Rectangle{pos.x, pos.y, f32(info.advanceX), LINE_HEIGHT}

		if state.mouse_pressed && rl.CheckCollisionPointRec(state.mouse_position, rect) {
			to_move = i
		}

		if rl.CheckCollisionRecs(state.mouse_selection, rect) {
			rl.DrawRectangleRec(rect, rl.RED)
		}

		rl.DrawTextCodepoint(font, r, pos, FONT_SIZE, rl.WHITE)

		pos.x += f32(info.advanceX)
	}

	if to_move != 0 {
		if to_move > gb.end {
			to_move -= gb.end
		} else {
			to_move -= gb.start
		}
		gb_move(gb, to_move)
	}

	rl.DrawRectangleRec(cursor, rl.BLACK)
}

main :: proc() {
	rl.InitWindow(400, 400, "test")

	rl.SetWindowState({.WINDOW_RESIZABLE})

	font := rl.LoadFontEx(FONT_PATH, FONT_SIZE, nil, 0)

	gb: gap_buffer
	gb_init(&gb, 256)

	mouse_select_start, mouse_select_end: rl.Vector2

	for !rl.WindowShouldClose() {
		for r := rl.GetCharPressed(); r != 0; r = rl.GetCharPressed() {
			gb_insert(&gb, r)
		}

		for k := rl.GetKeyPressed(); k != .KEY_NULL; k = rl.GetKeyPressed() {
			#partial switch k {
			case .ENTER:
				gb_insert(&gb, '\n')
			case .BACKSPACE:
				gb_delete(&gb)
			case .LEFT:
				gb_move(&gb, -1)
			case .RIGHT:
				gb_move(&gb, 1)
			}
		}

		state := frame_state{
			mouse_position = rl.GetMousePosition(),
			mouse_pressed = rl.IsMouseButtonPressed(.LEFT),
		}

		if state.mouse_pressed {
			mouse_select_start = state.mouse_position
			mouse_select_end = mouse_select_start
		} else if rl.IsMouseButtonDown(.LEFT) || rl.IsMouseButtonReleased(.LEFT) {
			mouse_select_end = state.mouse_position
		}

		state.mouse_selection.x = min(mouse_select_start.x, mouse_select_end.x)
		state.mouse_selection.y = min(mouse_select_start.y, mouse_select_end.y)
		state.mouse_selection.width = abs(mouse_select_start.x - mouse_select_end.x)
		state.mouse_selection.height = abs(mouse_select_start.y - mouse_select_end.y)

		rl.BeginDrawing()

		rl.ClearBackground(rl.PURPLE)

		w, h := rl.GetScreenWidth(), rl.GetScreenHeight()

		gb_draw(&gb, font, state, 0, 0, w, h)

		rl.EndDrawing()
	}
}
