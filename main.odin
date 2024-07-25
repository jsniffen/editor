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

gb_get_word :: proc(gb: ^gap_buffer, i: int) -> [dynamic]rune {
	start, end := 0, 0

	for j := i; j >= 0; j -= 1 {
		if j == gb.end - 1 {
			j = gb.start
			continue
		}

		r := gb.data[j]

		if r == '\n' || r == ' ' || r == '\t' {
			break
		}

		start = j
	}

	for j := i; j < gb.cap; j += 1 {
		if j == gb.start {
			j = gb.end - 1
			continue
		}

		r := gb.data[j]

		if r == '\n' || r == ' ' || r == '\t' {
			break
		}

		end = j
	}

	buffer := make([dynamic]rune)
	for j := start; j <= end; j += 1 {
		if j == gb.start {
			j = gb.end - 1
		}
		append(&buffer, gb.data[j])
	}

	return buffer
}

gb_execute :: proc (gb: ^gap_buffer, cmd: [dynamic]rune) {
	if len(cmd) == 3 {

		if cmd[0] == 'P' && cmd[1] == 'u' && cmd[2] == 't' {
			fmt.println("Save buffer")
		}

		if cmd[0] == 'D' && cmd[1] == 'e' && cmd[2] == 'l' {
			fmt.println("Delete buffer")
		}

	}
}

gb_draw :: proc(gb: ^gap_buffer, ed: ^editor, state: frame_state, rec: rl.Rectangle, fg, bg: rl.Color) {
	pos := rl.Vector2{rec.x, rec.y}

	to_move := 0
	cursor: rl.Rectangle

	for i := 0; i < gb.cap; i += 1 {
		if i == gb.start {
			cursor = {pos.x, pos.y, 2, LINE_HEIGHT}
			i = gb.end - 1
			continue
		}
		r := gb.data[i]

		if r == '\n' {
			pos.x = rec.x
			pos.y += LINE_HEIGHT
			continue
		}

		info := rl.GetGlyphInfo(ed.font, r)
		glyph_rec := rl.Rectangle{pos.x, pos.y, f32(info.advanceX), LINE_HEIGHT}

		if r == '\t' {
			info = rl.GetGlyphInfo(ed.font, ' ')
			glyph_rec = rl.Rectangle{pos.x, pos.y, f32(info.advanceX*4), LINE_HEIGHT}
		}

		if state.middle_mouse_pressed && rl.CheckCollisionPointRec(state.mouse_position, glyph_rec) {
			word := gb_get_word(gb, i)
			gb_execute(gb, word)
		}

		if state.left_mouse_pressed && rl.CheckCollisionPointRec(state.mouse_position, glyph_rec) {
			to_move = i
		}

		if rl.CheckCollisionRecs(state.mouse_selection, glyph_rec) {
			rl.DrawRectangleRec(glyph_rec, bg)
		}

		if r != ' ' && r != '\t' {
			rl.DrawTextCodepoint(ed.font, r, pos, FONT_SIZE, fg)
		}

		pos.x += f32(glyph_rec.width)
	}

	if to_move != 0 {
		if to_move > gb.end {
			to_move -= gb.end
		} else {
			to_move -= gb.start
		}
		gb_move(gb, to_move)
	}

	rl.DrawRectangleRec(cursor, fg)

	if rl.CheckCollisionPointRec(state.mouse_position, rec) {
		ed.focused_gb = gb
	}
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
					gb_move(ed.focused_gb, -1)
				case .RIGHT:
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
		}

		state.mouse_selection.x = min(mouse_select_start.x, mouse_select_end.x)
		state.mouse_selection.y = min(mouse_select_start.y, mouse_select_end.y)
		state.mouse_selection.width = abs(mouse_select_start.x - mouse_select_end.x)
		state.mouse_selection.height = abs(mouse_select_start.y - mouse_select_end.y)

		rl.BeginDrawing()

		rl.ClearBackground(rl.PURPLE)

		w, h: = f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())

		win_draw(&win, &ed, state, {0, 0, w, h})

		rl.EndDrawing()
	}
}
