package main

import rl "vendor:raylib"
import "core:fmt"

window :: struct {
	tag: Buffer,
	body: Buffer,

	// the number of lines to skip when rendering the body
	skip_body_lines: int,

	// we are currently drag scrolling
	drag_scrolling: bool,
	drag_scroll_diff: f32,
}

win_init :: proc(win: ^window) {
	buf_init(&win.tag)
	pt_load(&win.tag.pt, "c:/projects/editor/main.odin")

	buf_init(&win.body)
}

win_draw :: proc(win: ^window, ed: ^Editor, state: FrameState, rec: rl.Rectangle) {
	tag_rec := rec
	rl.DrawRectangleRec(tag_rec, COLOR_TAG_BG)

	button_rec := rec
	button_rec.width = BUTTON_WIDTH
	button_rec.height = LINE_HEIGHT + 2*MARGIN
	rl.DrawRectangleRec(button_rec, COLOR_BUTTON_BG)

	{
		dirty_rec := button_rec
		dirty_rec.x += BUTTON_MARGIN
		dirty_rec.width -= 2*BUTTON_MARGIN
		dirty_rec.y += BUTTON_MARGIN
		dirty_rec.height -= 2*BUTTON_MARGIN
		if win.body.dirty {
			rl.DrawRectangleRec(dirty_rec, COLOR_BUTTON_FG)
		} else {
			rl.DrawRectangleRec(dirty_rec, COLOR_TAG_BG)
		}
	}

	tag_rec.x += button_rec.width
	tag_rec.width -= button_rec.width
	lines_rendered := buf_draw(&win.tag, ed, state, tag_rec, COLOR_TAG_TEXT, COLOR_TAG_TEXT_SELECT)

	body_rec := rec
	body_rec.y += f32(LINE_HEIGHT*lines_rendered) + 2*MARGIN
	body_rec.height -= body_rec.y
	body_rec.x += SCROLLBAR_WIDTH
	body_rec.width -= SCROLLBAR_WIDTH

	rl.DrawRectangleRec(body_rec, COLOR_BODY_BG)
	lines_rendered = buf_draw(&win.body, ed, state, body_rec, COLOR_BODY_TEXT, COLOR_BODY_TEXT_SELECT, lines_to_skip=win.skip_body_lines)

	scrollzone_rec := rec
	scrollzone_rec.y = body_rec.y
	scrollzone_rec.height = body_rec.height
	scrollzone_rec.width = SCROLLBAR_WIDTH

	rl.DrawRectangleRec(scrollzone_rec, COLOR_SCROLLBAR_BG)

	scrollbar_ymin := scrollzone_rec.y
	scrollbar_ymax := scrollbar_ymin + scrollzone_rec.height

	scrollbar_rec := rec
	scrollbar_rec.height *= f32(lines_rendered)/f32(len(win.body.lines))
	scrollbar_rec.y = scrollbar_ymin + f32(win.skip_body_lines)/f32(len(win.body.lines))*f32(scrollbar_ymax - scrollbar_ymin)
	scrollbar_rec.width = SCROLLBAR_WIDTH - 1

	if state.left_mouse_pressed && rl.CheckCollisionPointRec(state.mouse_position, scrollbar_rec) {
		win.drag_scrolling = true
		win.drag_scroll_diff = state.mouse_position.y - scrollbar_rec.y
	} else if state.left_mouse_up {
		win.drag_scrolling = false
	}

	if state.mouse_wheel_move != 0 {
		win.skip_body_lines = max(0, min(win.skip_body_lines - int(state.mouse_wheel_move), len(win.body.lines)-1))
	} else if !win.drag_scrolling && (state.left_mouse_pressed || state.right_mouse_pressed) {
		if rl.CheckCollisionPointRec(state.mouse_position, scrollzone_rec) {
			diff := int((state.mouse_position.y - scrollzone_rec.y)/LINE_HEIGHT)+1
			if state.left_mouse_pressed {
				win.skip_body_lines = max(win.skip_body_lines - diff, 0)
			} else if state.right_mouse_pressed {
				win.skip_body_lines = min(win.skip_body_lines + diff, len(win.body.lines)-1)
			}
		}
	}

	if win.drag_scrolling {
		scrollbar_rec.y = max(scrollbar_ymin, min(scrollbar_ymax, state.mouse_position.y - win.drag_scroll_diff))
		percent_scroll := (scrollbar_rec.y - scrollbar_ymin)/(scrollbar_ymax - scrollbar_ymin)
		win.skip_body_lines = int(percent_scroll*f32(len(win.body.lines)-1))
	}

	rl.DrawRectangleRec(scrollbar_rec, COLOR_SCROLLBAR_FG)

}

