package main

import rl "vendor:raylib"
import "core:fmt"

window :: struct {
	tag: Buffer,
	body: Buffer,
}

win_init :: proc(win: ^window) {
	buf_init(&win.tag)
	buf_init(&win.body)
}

win_draw :: proc(win: ^window, ed: ^Editor, state: FrameState, rec: rl.Rectangle) {
	rec := rec

	rl.DrawRectangleRec(rec, COLOR_TAG_BG)
	buf_draw(&win.tag, ed, state, rec, COLOR_TAG_TEXT, COLOR_TAG_TEXT_SELECT)

	rec.y += LINE_HEIGHT*f32(win.tag.lines)

	rl.DrawRectangleRec(rec, COLOR_BODY_BG)
	buf_draw(&win.body, ed, state, rec, COLOR_BODY_TEXT, COLOR_BODY_TEXT_SELECT)
}

