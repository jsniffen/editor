package main

import rl "vendor:raylib"
import "core:strings"
import "core:os"

TextSelection :: struct {
	start: int,
	end: int,
	valid: bool,
}

Buffer :: struct {
	pt: PieceTable,
	cursor: int,
	selection: TextSelection,
}

buf_init :: proc(b: ^Buffer) {
	pt_init(&b.pt)
}

buf_cursor_move :: proc(b: ^Buffer, i: int) {
	if b.cursor + i < 0 {
		return
	}

	it := pt_iterator(b.pt)
	length := pt_iterator_len(&it)

	if b.cursor + i > length {
		return
	}

	b.cursor += i
}

buf_draw :: proc(b: ^Buffer, ed: ^editor, state: frame_state, rec: rl.Rectangle, fg, bg: rl.Color) {
	if rl.CheckCollisionPointRec(state.mouse_position, rec) {
		ed.focused_buffer = b
	}

	pos := rl.Vector2{rec.x, rec.y}
	cursor: rl.Rectangle
	it := pt_iterator(b.pt)
	select_start := -1
	select_end := -1

	for r, i in pt_iterator_next(&it) {
		if b.cursor == i {
			cursor = {pos.x, pos.y, 2, LINE_HEIGHT}
		}

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

		if state.mouse_selection.width > 0 && state.mouse_selection.height > 0 {
			// TODO(Julian): 
			// There is currently a bug where you start a selection over a span of text but end it
			// on a blank line. We need to handle cases where selection start and end over blank lines.

			// TODO(Julian):
			// This isn't a robust solution. We need to distinguish when a mouse selection
			// spans multiple lines or not, not just if it's taller than a single LINE_HEIGHT.
			// This will have to do for now until we figure out if we're able to calculate lines ahead of time.
			if state.mouse_selection.height <= LINE_HEIGHT {
				if rl.CheckCollisionRecs(state.mouse_selection, glyph_rec) {
					rl.DrawRectangleRec(glyph_rec, bg)
					if select_start == -1 {
						select_start = i
					}
					select_end = i
				}
			} else if state.mouse_selection_pos.x == state.mouse_selection_pos.y {
				// mouse is at top left or bottom right of selection box
				if rl.CheckCollisionRecs(state.mouse_selection, glyph_rec) {
					rl.DrawRectangleRec(glyph_rec, bg)
					if select_start == -1 {
						select_start = i
					}
					select_end = i
				} else if select_start != -1 {
					if glyph_rec.y + glyph_rec.height < state.mouse_selection.y + state.mouse_selection.height {
						// the bottom of the glyph is higher than the bottom of the mouse selection
						rl.DrawRectangleRec(glyph_rec, bg)
						select_end = i
					} else if glyph_rec.y < state.mouse_selection.y + state.mouse_selection.height && glyph_rec.x < state.mouse_selection.x + state.mouse_selection.width {
						// the top of the glyph is higher than the bottom of the mouse selection and
						// the left of the glyph is further left than the right side of the mouse selection
						rl.DrawRectangleRec(glyph_rec, bg)
						select_end = i
					}
				}
			} else {
				// mouse is at bottom left or top right of selection box
				if glyph_rec.y < state.mouse_selection.y && glyph_rec.y + glyph_rec.height > state.mouse_selection.y && glyph_rec.x > state.mouse_selection.x + state.mouse_selection.width {
					// the top of the glyph is higher than the top of the mouse selection and
					// the bottom of the glyph is lower than the top of the mouse selection and
					// the left of the glyph is further left than the mouse selection
					rl.DrawRectangleRec(glyph_rec, bg)
					if select_start == -1 {
						select_start = i
					}
					select_end = i
				} else if select_start != -1 {
					if glyph_rec.y + glyph_rec.height < state.mouse_selection.y + state.mouse_selection.height {
						// the bottom of the glyph is higher than the top of the mouse selection
						rl.DrawRectangleRec(glyph_rec, bg)
						select_end = i
					} else if glyph_rec.y < state.mouse_selection.y + state.mouse_selection.height && glyph_rec.x < state.mouse_selection.x {
						// the top of the glyph is higher than the bottom of the mouse selection and
						// the left of the glyph is further left than the left side of the mouse selection
						rl.DrawRectangleRec(glyph_rec, bg)
						select_end = i
					}
				}
			}
		} else if b.selection.valid {
			if i >= b.selection.start && i <= b.selection.end {
				rl.DrawRectangleRec(glyph_rec, bg)
			}
		}

		if r != ' ' && r != '\t' {
			rl.DrawTextCodepoint(ed.font, r, pos, FONT_SIZE, fg)
		}

		pos.x += f32(glyph_rec.width)
	}

	if select_start != -1 && select_end != -1 {
		b.selection.start = select_start
		b.selection.end = select_end
		b.selection.valid = true
	}

	if !b.selection.valid {
		if cursor.height == 0 {
			// if we didn't set the cursor rect, the cursor is at the end of the buffer
			cursor = {pos.x, pos.y, 2, LINE_HEIGHT}
		}
		rl.DrawRectangleRec(cursor, fg)
	}
}

buf_insert :: proc(b: ^Buffer, r: rune) {
	if b.selection.valid {
		pt_delete_range(&b.pt, b.selection.start, b.selection.end+1)
		b.cursor = b.selection.start
		b.selection.valid = false
	}
	pt_insert(&b.pt, r, b.cursor)
	buf_cursor_move(b, 1)
}

buf_delete :: proc(b: ^Buffer) {
	if b.selection.valid {
		pt_delete_range(&b.pt, b.selection.start, b.selection.end+1)
		b.cursor = b.selection.start
		b.selection.valid = false
	} else {
		pt_delete(&b.pt, b.cursor-1)
		buf_cursor_move(b, -1)
	}
}

buf_load_file :: proc(b: ^Buffer, filename: string) -> bool {
	bytes, ok := os.read_entire_file(filename)
	if !ok {
		return false
	}

	contents, err := strings.clone_from_bytes(bytes)
	if err != nil {
		return false
	}

	pt_load(&b.pt, contents)
	return true
}

