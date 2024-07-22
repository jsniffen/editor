typedef struct window {
	gap_buffer header_buffer;
	gap_buffer body_buffer;
} window;

void win_init(window *w) {
	gb_init(&(w->header_buffer), 256);
	gb_init(&(w->body_buffer), 256);
}

void win_draw(window *w, editor *ed, frame_state *state, int x, int y, int width, int height) {
	int header_height = LINE_HEIGHT;

	Rectangle rect;
	rect.x = x;
	rect.y = y;
	rect.width = width;
	rect.height = header_height;

	DrawRectangleRec(rect, BLUE);
	DrawRectangleLinesEx(rect, 1, BLACK);
	gb_draw(&(w->header_buffer), state, font, font_size, LINE_HEIGHT, x+5, y+5, width, height);

	if (state->mouse_pressed && CheckCollisionPointRec(state->mouse_position, rect)) {
		ed->focused_buffer = &(w->header_buffer);
	}
	
	y += LINE_HEIGHT;

	rect.x = x;
	rect.y = y;
	rect.width = width;
	rect.height = height;

	DrawRectangleRec(rect, GRAY);
	gb_draw(&(w->body_buffer), state, font, font_size, LINE_HEIGHT, x+5, y+5, width, height);

	if (state->mouse_pressed && CheckCollisionPointRec(state->mouse_position, rect)) {
		ed->focused_buffer = &(w->body_buffer);
	}
}

void win_handle_char_pressed(window *w, int codepoint) {
	gb_insert(&(w->body_buffer), codepoint);
}
