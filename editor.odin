package main

import rl "vendor:raylib"
import "core:fmt"

Editor :: struct {
	header: Buffer,
	focused_buffer: ^Buffer,
	font: rl.Font,
	load_buffer: ^Buffer,
	windows: [dynamic]Window,
}

ed_init :: proc(e: ^Editor) {
	buf_init(&e.header)
	buf_load(&e.header, "Newcol Kill Putall Dump Exit")

	e.font = rl.LoadFontEx(FONT_PATH, FONT_SIZE, nil, 0)
	e.windows = make([dynamic]Window)
}

ed_load_file :: proc(e: ^Editor, filename: string) {
	resize(&e.windows, len(e.windows) + 1)
	w := &e.windows[len(e.windows)-1]
	win_init(w)
	fmt.println(w)
	win_load_file(w, filename)
}

ed_draw :: proc(e: ^Editor, state: FrameState, rec: rl.Rectangle) {
	header_rec := rec
	rl.DrawRectangleRec(header_rec, COLOR_TAG_BG)

	button_rec := rec
	button_rec.width = BUTTON_WIDTH
	button_rec.height = LINE_HEIGHT + 2*MARGIN
	rl.DrawRectangleRec(button_rec, COLOR_BUTTON_BG)

	header_rec.x += button_rec.width
	header_rec.width -= button_rec.width
	lines_rendered := buf_draw(&e.header, e, state, header_rec, COLOR_TAG_TEXT, COLOR_TAG_TEXT_SELECT)

	start, end: rl.Vector2
	start.x = rec.x
	end.x = rec.x + rec.width
	start.y = header_rec.y + f32(2*MARGIN) + f32(lines_rendered*LINE_HEIGHT)
	end.y = start.y
	rl.DrawLineEx(start, end, LINE_THICKNESS, LINE_COLOR)

	windows_rec := rec
	windows_rec.y = start.y - rec.y + LINE_THICKNESS - 1
	for &w in e.windows {
		lines_rendered = win_draw(&w, e, state, windows_rec)
		windows_rec.y += f32(2*MARGIN) + f32(lines_rendered*LINE_HEIGHT)
	}
}

