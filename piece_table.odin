package main

import rl "vendor:raylib"
import "core:fmt"
import "core:log"
import "core:strings"
import "core:os"

piece_table_entry :: struct {
	start: int,
	length: int,
	is_original: bool,
}

piece_table :: struct {
	entries: [dynamic]piece_table_entry,
	original_buf: [dynamic]rune,
	append_buf: [dynamic]rune,
	cursor: int,
}

pt_cursor_move :: proc(pt: ^piece_table, i: int) {
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

pt_init :: proc(pt: ^piece_table) {
	contents :: "hello, world"

	pt.entries = make([dynamic]piece_table_entry)
	pt.original_buf = make([dynamic]rune)
	pt.append_buf = make([dynamic]rune)
	pt.cursor = 0
}

pt_draw :: proc(pt: ^piece_table, ed: ^editor, state: frame_state, rec: rl.Rectangle, fg, bg: rl.Color) { 
	if rl.CheckCollisionPointRec(state.mouse_position, rec) {
		ed.focused_buffer = pt
	}

	pos := rl.Vector2{rec.x, rec.y}
	cursor: rl.Rectangle

	codepoint_i := 0
	for entry in pt.entries {
		buf := pt.original_buf if entry.is_original else pt.append_buf

		for i := entry.start; i < entry.start+entry.length; i += 1 {
			if pt.cursor == codepoint_i {
				cursor = {pos.x, pos.y, 2, LINE_HEIGHT}
			}

			r := buf[i]

			if r == '\n' {
				pos.x = rec.x
				pos.y += LINE_HEIGHT
				codepoint_i += 1
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

pt_to_string :: proc(pt: piece_table) -> string {
	builder: strings.Builder
	for entry in pt.entries {
		buf := pt.original_buf if entry.is_original else pt.append_buf
		for i := entry.start; i < entry.start + entry.length; i += 1 {
			strings.write_rune(&builder, buf[i])
		}
	}
	return strings.to_string(builder)
}

pt_load_file :: proc(pt: ^piece_table, filename: string) -> bool {
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

pt_load :: proc(pt: ^piece_table, s: string) {
	for codepoint in s {
		append(&pt.original_buf, codepoint)
	}
	append(&pt.entries, piece_table_entry{
		start=0,
		length=len(s),
		is_original=true,
	})
}

pt_insert :: proc(pt: ^piece_table, codepoint: rune, cursor: int) {
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
			inject_at(&pt.entries, i, piece_table_entry{
				start = len(pt.append_buf)-1,
				length = 1,
				is_original = false,
			})
		}
	} else if i < len(pt.entries) {
		append(&pt.append_buf, codepoint)

		entry := pt.entries[i]

		pivot := cursor - start

		inject_at(&pt.entries, i+1, piece_table_entry{
			start = len(pt.append_buf)-1,
			length = 1,
			is_original = false,
		})

		inject_at(&pt.entries, i+2, piece_table_entry{
			start = pivot,
			length = entry.length - pivot,
			is_original = entry.is_original,
		})

		pt.entries[i].length = pivot
		return
	}
}

pt_delete :: proc(pt: ^piece_table, cursor: int) {
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

			inject_at(&pt.entries, i+1, piece_table_entry{
				start = entry.start + pivot + 1,
				length = entry.length - pivot - 1,
				is_original = entry.is_original,
			})

			pt.entries[i].length = pivot
		}
	}
}

pt_cursor_insert :: proc(pt: ^piece_table, r: rune) {
	pt_insert(pt, r, pt.cursor)
	pt_cursor_move(pt, 1)
}

pt_cursor_delete :: proc(pt: ^piece_table) {
	pt_delete(pt, pt.cursor-1)
	pt_cursor_move(pt, -1)
}
