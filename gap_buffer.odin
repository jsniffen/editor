package main

import rl "vendor:raylib"
import "core:fmt"

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

gb_reset_selection :: proc(gb: ^gap_buffer) {
	gb.select_start = -1
	gb.select_end = -1
}

gb_init :: proc(gb: ^gap_buffer, size: int) {
	gb.data = make([dynamic]rune, size, size)
	gb.start = 0
	gb.end = size
	gb.cap = size
	gb.select_start = -1
	gb.select_end = -1
}

gb_insert :: proc(gb: ^gap_buffer, r: rune) {
	gb.data[gb.start] = r
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
	selected := false

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
			gb_reset_selection(gb)
		}

		// TODO(Julian): Clean this up, I'm pretty sure we don't need
		// to store the state of selected, select_start, and select_end.
		// Also we can probably clean up the control flow.
		if state.mouse_selection.width > 0 && state.mouse_selection.height > 0 {
			// mouse is at top right or bottom left of selection box
			if state.mouse_selection_pos.x == state.mouse_selection_pos.y {
				if rl.CheckCollisionRecs(state.mouse_selection, glyph_rec) {
					rl.DrawRectangleRec(glyph_rec, bg)
					if !selected {
						gb.select_start = i
					}
					selected = true
				}

				if selected {
					if glyph_rec.y + glyph_rec.height < state.mouse_selection.y + state.mouse_selection.height {
						rl.DrawRectangleRec(glyph_rec, bg)
					} else if glyph_rec.y < state.mouse_selection.y + state.mouse_selection.height && glyph_rec.x < state.mouse_selection.x + state.mouse_selection.width {
						rl.DrawRectangleRec(glyph_rec, bg)
						gb.select_end = i
					}
				}
			// mouse is at top left or bottom right of selection box
			} else {
				if glyph_rec.y < state.mouse_selection.y && glyph_rec.y + glyph_rec.height > state.mouse_selection.y && glyph_rec.x > state.mouse_selection.x + state.mouse_selection.width {
						rl.DrawRectangleRec(glyph_rec, bg)
						if !selected {
							gb.select_start = i
						}
						selected = true
				}

				if selected {
					if glyph_rec.y + glyph_rec.height < state.mouse_selection.y + state.mouse_selection.height {
						rl.DrawRectangleRec(glyph_rec, bg)
					} else if glyph_rec.y < state.mouse_selection.y + state.mouse_selection.height && glyph_rec.x < state.mouse_selection.x {
						rl.DrawRectangleRec(glyph_rec, bg)
						gb.select_end = i
					}

				}
			}
		} else if i >= gb.select_start && i <= gb.select_end {
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

	if gb.select_start == -1 && gb.select_end == -1 {
		rl.DrawRectangleRec(cursor, fg)
	}

	if rl.CheckCollisionPointRec(state.mouse_position, rec) {
		ed.focused_gb = gb
	}
}

