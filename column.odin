package main

import rl "vendor:raylib"
import "core:fmt"

Column :: struct {
	width: f32,
	tag: Buffer,
	windows: [dynamic]Window,
}

col_init :: proc(c: ^Column) {
	c.windows = make([dynamic]Window, 1)
	buf_init(&c.tag)
	buf_load(&c.tag, "New Cut Paste Snarf Sort Delcol")

	win_init(&c.windows[0])
	c.width = 1.0
}

col_draw :: proc(c: ^Column, e: ^Editor, state: FrameState, rec: rl.Rectangle) {
	tag_rec := rec
	rl.DrawRectangleRec(tag_rec, COLOR_TAG_BG)

	button_rec := rec
	button_rec.width = BUTTON_WIDTH
	button_rec.height = LINE_HEIGHT + 2*MARGIN
	rl.DrawRectangleRec(button_rec, COLOR_BUTTON_BG)

	tag_rec.x += button_rec.width
	tag_rec.width -= button_rec.width
	lines_rendered := buf_draw(&c.tag, e, state, tag_rec, COLOR_TAG_TEXT, COLOR_TAG_TEXT_SELECT)

	start, end: rl.Vector2
	start.x = rec.x
	end.x = rec.x + rec.width
	start.y = tag_rec.y + f32(2*MARGIN) + f32(lines_rendered*LINE_HEIGHT)
	end.y = start.y
	rl.DrawLineEx(start, end, LINE_THICKNESS, LINE_COLOR)

	col_rec := rec
	col_rec.y += (start.y - tag_rec.y + LINE_THICKNESS - 1)
	col_rec.height -= (start.y - tag_rec.y + LINE_THICKNESS - 1)

	window_y := col_rec.y

	for &window in c.windows {
		window_rec := col_rec
		window_rec.height *= window.height
		window_rec.y = window_y

		win_draw(&window, e, state, window_rec)

		window_y += window_rec.height
	}
}
