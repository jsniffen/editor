package main

import rl "vendor:raylib"
import "core:fmt"

piece_table_entry_kind :: enum {
	ORIGINAL,
	APPEND
}

piece_table_entry :: struct {
	start: int,
	len: int,
	kind: piece_table_entry_kind,
}

piece_table :: struct {
	entries: [dynamic]piece_table_entry,
	original_buf: [dynamic]rune,
	append_buf: [dynamic]rune,
	cursor: int,
}

pt_init :: proc(pt: ^piece_table) {
	contents :: "hello, world"

	pt.entries = make([dynamic]piece_table_entry)
	pt.original_buf = make([dynamic]rune)
	pt.append_buf = make([dynamic]rune)
	pt.cursor = len(contents)

	entry := piece_table_entry{
		start=0,
		len=len(contents),
		kind=.ORIGINAL,
	}
	append(&pt.entries, entry)

	for codepoint in contents {
		append(&pt.original_buf, codepoint)
	}
}

pt_move_left :: proc(pt: ^piece_table) {
	if pt.cursor > 0 {
		pt.cursor -= 1
	}
}

pt_move_right :: proc(pt: ^piece_table) {
	total_length := 0
	for entry in pt.entries {
		total_length += entry.len
	}
	if pt.cursor < total_length {
		pt.cursor += 1
	}
}

pt_insert :: proc(pt: ^piece_table, codepoint: rune) {
	append(&pt.append_buf, codepoint)

	l := 0
	for &entry, i in pt.entries {
		l += entry.len
		if pt.cursor < l {
			pivot := entry.len - (l - pt.cursor)

			if pivot == 1 {
				new := piece_table_entry{
					kind=.APPEND,
					start=len(pt.append_buf)-1,
					len=1,
				}
				inject_at(&pt.entries, i, new)
			} else {
				new := piece_table_entry{
					kind=.APPEND,
					start=len(pt.append_buf)-1,
					len=1,
				}
				inject_at(&pt.entries, i+1, new)

				next := piece_table_entry{
					kind=entry.kind,
					start=pivot,
					len=entry.len-pivot,
				}
				inject_at(&pt.entries, i+2, next)

				entry.len = pivot
			}

			break
		}
	}

	if pt.cursor == l {
		// we're adding a codepoint to the very end of the file
		entry := piece_table_entry{
			kind=.APPEND,
			start=len(pt.append_buf)-1,
			len=1,
		}
		append(&pt.entries, entry)
	}

	pt.cursor += 1
}

pt_delete :: proc(pt: ^piece_table, i: int) {
}

pt_draw :: proc(pt: ^piece_table, ed: ^editor, state: frame_state, rec: rl.Rectangle, fg, bg: rl.Color) { 
	pos := rl.Vector2{rec.x, rec.y}
	cursor: rl.Rectangle

	codepoint_i := 0
	for entry in pt.entries {
		buf := pt.original_buf if entry.kind == .ORIGINAL else pt.append_buf

		for i := entry.start; i < entry.start+entry.len; i += 1 {
			if pt.cursor == codepoint_i {
				cursor = {pos.x, pos.y, 2, LINE_HEIGHT}
			}

			r := buf[i]

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

			if r != ' ' && r != '\t' {
				rl.DrawTextCodepoint(ed.font, r, pos, FONT_SIZE, fg)
			}

			pos.x += f32(glyph_rec.width)
			codepoint_i += 1
		}
	}


	if pt.cursor == codepoint_i {
		cursor = {pos.x, pos.y, 2, LINE_HEIGHT}
	}
	rl.DrawRectangleRec(cursor, fg)
}
