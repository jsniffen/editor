package main

import rl "vendor:raylib"
import "core:fmt"
import "core:log"
import "core:strings"
import "core:os"

TextSelection :: struct {
	start: int,
	end: int,
	valid: bool,
}

PieceTableIterator :: struct {
	// the piece table to iterate over
	pt: PieceTable,

	// entry we're currently pointing at
	entry_index: int,

	// the index into current entry
	cursor: int,

	// the index of the total string
	index: int,
}

pt_iterator :: proc(pt: PieceTable) -> PieceTableIterator {
	return PieceTableIterator{
		pt=pt,
		entry_index=0,
		cursor=-1,
		index=0,
	}
}

pt_iterator_next :: proc(it: ^PieceTableIterator) -> (rune, int, bool) {
	r: rune
	if it.entry_index >= len(it.pt.entries) {
		return r, it.index, false
	}
	entry := it.pt.entries[it.entry_index]
	if it.cursor == -1 {
		it.cursor = entry.start
	}
	if it.cursor >= entry.start + entry.length {
		it.entry_index += 1
		if it.entry_index >= len(it.pt.entries) {
			return r, it.index, false
		}
		entry = it.pt.entries[it.entry_index]
		it.cursor = entry.start
	}
	buf := it.pt.original_buf if entry.is_original else it.pt.append_buf
	r = buf[it.cursor]
	i := it.index
	it.cursor += 1
	it.index += 1
	return r, i, true
}

PieceTableEntry :: struct {
	start: int,
	length: int,
	is_original: bool,
}

PieceTable :: struct {
	entries: [dynamic]PieceTableEntry,
	original_buf: [dynamic]rune,
	append_buf: [dynamic]rune,
	cursor: int,
	selection: TextSelection,
}

pt_cursor_move :: proc(pt: ^PieceTable, i: int) {
	if pt.cursor + i < 0 {
		return
	}

	total_length := 0
	for entry in pt.entries {
		total_length += entry.length
	}

	if pt.cursor + i > total_length {
		return
	}

	pt.cursor += i
}

pt_init :: proc(pt: ^PieceTable) {
	contents :: "hello, world"

	pt.entries = make([dynamic]PieceTableEntry)
	pt.original_buf = make([dynamic]rune)
	pt.append_buf = make([dynamic]rune)
	pt.cursor = 0
}

pt_draw :: proc(pt: ^PieceTable, ed: ^editor, state: frame_state, rec: rl.Rectangle, fg, bg: rl.Color) {
	if rl.CheckCollisionPointRec(state.mouse_position, rec) {
		ed.focused_buffer = pt
	}

	pos := rl.Vector2{rec.x, rec.y}
	cursor: rl.Rectangle
	it := pt_iterator(pt^)
	select_start := -1
	select_end := -1

	for r, i in pt_iterator_next(&it) {
		if pt.cursor == i {
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
		} else if pt.selection.valid {
			if i >= pt.selection.start && i <= pt.selection.end {
				rl.DrawRectangleRec(glyph_rec, bg)
			}
		}

		if r != ' ' && r != '\t' {
			rl.DrawTextCodepoint(ed.font, r, pos, FONT_SIZE, fg)
		}

		pos.x += f32(glyph_rec.width)
	}

	if select_start != -1 && select_end != -1 {
		pt.selection.start = select_start
		pt.selection.end = select_end
		pt.selection.valid = true
	}

	if !pt.selection.valid {
		if cursor.height == 0 {
			// if we didn't set the cursor rect, the cursor is at the end of the buffer
			cursor = {pos.x, pos.y, 2, LINE_HEIGHT}
		}
		rl.DrawRectangleRec(cursor, fg)
	}
}

pt_to_string :: proc(pt: PieceTable) -> string {
	builder: strings.Builder
	it := pt_iterator(pt)
	for r in pt_iterator_next(&it) {
		strings.write_rune(&builder, r)
	}
	return strings.to_string(builder)
}

pt_load_file :: proc(pt: ^PieceTable, filename: string) -> bool {
	b, ok := os.read_entire_file(filename)
	if !ok {
		return false
	}

	contents, err := strings.clone_from_bytes(b)
	if err != nil {
		return false
	}

	pt_load(pt, contents)
	return true
}

pt_load :: proc(pt: ^PieceTable, s: string) {
	for codepoint in s {
		append(&pt.original_buf, codepoint)
	}
	append(&pt.entries, PieceTableEntry{
		start=0,
		length=len(s),
		is_original=true,
	})
}

pt_insert :: proc(pt: ^PieceTable, codepoint: rune, cursor: int) {
	if cursor < 0 {
		return
	}

	start := 0
	i := 0

	for entry in pt.entries {
		if cursor < start + entry.length {
			break
		}

		start += entry.length
		i += 1
	}

	if cursor == start {
		append(&pt.append_buf, codepoint)
		if i > 0 && !pt.entries[i-1].is_original && pt.entries[i-1].start + pt.entries[i-1].length == len(pt.append_buf)-1 {
			pt.entries[i-1].length += 1
		} else {
			inject_at(&pt.entries, i, PieceTableEntry{
				start = len(pt.append_buf)-1,
				length = 1,
				is_original = false,
			})
		}
	} else if i < len(pt.entries) {
		append(&pt.append_buf, codepoint)

		entry := pt.entries[i]

		pivot := cursor - start

		inject_at(&pt.entries, i+1, PieceTableEntry{
			start = len(pt.append_buf)-1,
			length = 1,
			is_original = false,
		})

		inject_at(&pt.entries, i+2, PieceTableEntry{
			start = pivot,
			length = entry.length - pivot,
			is_original = entry.is_original,
		})

		pt.entries[i].length = pivot
		return
	}
}

pt_delete :: proc(pt: ^PieceTable, cursor: int) {
	if cursor < 0 {
		return
	}

	start := 0
	i := 0

	for entry in pt.entries {
		if cursor < start + entry.length {
			break
		}

		start += entry.length
		i += 1
	}

	if i < len(pt.entries) {
		if cursor == start {
			pt.entries[i].start += 1
			pt.entries[i].length -= 1

			if (pt.entries[i].length == 0) {
				ordered_remove(&pt.entries, i)
			}
		} else if cursor == start + pt.entries[i].length - 1 {
			pt.entries[i].length -= 1
		} else {
			entry := pt.entries[i]

			pivot := cursor - start

			inject_at(&pt.entries, i+1, PieceTableEntry{
				start = entry.start + pivot + 1,
				length = entry.length - pivot - 1,
				is_original = entry.is_original,
			})

			pt.entries[i].length = pivot
		}
	}
}

pt_cursor_insert :: proc(pt: ^PieceTable, r: rune) {
	pt_insert(pt, r, pt.cursor)
	pt_cursor_move(pt, 1)
}

pt_cursor_delete :: proc(pt: ^PieceTable) {
	pt_delete(pt, pt.cursor-1)
	pt_cursor_move(pt, -1)
}
