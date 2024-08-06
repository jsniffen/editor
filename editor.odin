package main

import rl "vendor:raylib"
import "core:fmt"

Editor :: struct {
	header: Buffer,
	focused_buffer: ^Buffer,
	font: rl.Font,
	load_buffer: ^Buffer,
	columns: [dynamic]Column,
}

ed_init :: proc(e: ^Editor) {
	buf_init(&e.header)
	buf_load(&e.header, "Newcol Kill Putall Dump Exit")

	e.columns = make([dynamic]Column, 1)
	col_init(&e.columns[0])

	e.font = rl.LoadFontEx(FONT_PATH, FONT_SIZE, nil, 0)
}

ed_load_file :: proc(e: ^Editor, filename: string) {
	if len(e.columns) > 0 {
		column := &e.columns[0]

		for &w in column.windows {
			if buf_is_empty(&w.body) {
				win_load_file(&w, filename)
				return
			}
		}

		resize(&column.windows, len(column.windows)+1)
		window := &column.windows[len(column.windows)-1]
		win_init(window)
		win_load_file(window, filename)

		for &w in column.windows {
			w.height = 1.0/f32(len(column.windows))
		}
	}
}

ed_draw :: proc(e: ^Editor, state: FrameState, rec: rl.Rectangle) {
	header_rec := rec
	rl.DrawRectangleRec(header_rec, COLOR_TAG_BG)

	header_rec.x += BUTTON_WIDTH
	header_rec.width -= BUTTON_WIDTH
	lines_rendered := buf_draw(&e.header, e, state, header_rec, COLOR_TAG_TEXT, COLOR_TAG_TEXT_SELECT)

	start, end: rl.Vector2
	start.x = rec.x
	end.x = rec.x + rec.width
	start.y = header_rec.y + f32(2*MARGIN) + f32(lines_rendered*LINE_HEIGHT)
	end.y = start.y
	rl.DrawLineEx(start, end, LINE_THICKNESS, LINE_COLOR)

	editor_rec := rec
	editor_rec.y = start.y - rec.y + LINE_THICKNESS - 1
	editor_rec.height -= editor_rec.y

	column_x := editor_rec.x
	for &column in e.columns {
		column_rec := editor_rec
		column_rec.width *= column.width
		column_rec.x = column_x

		col_draw(&column, e, state, column_rec)

		start.x = column_rec.x + column_rec.width
		end.x = column_rec.x + column_rec.width
		start.y = column_rec.y
		end.y = column_rec.y + column_rec.height
		rl.DrawLineEx(start, end, LINE_THICKNESS, LINE_COLOR)

		column_x += column_rec.width + LINE_THICKNESS - 1
	}
}

