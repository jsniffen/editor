typedef struct gap_buffer {
	// the data stored by the buffer
	int *data;

	// The start index of the gap
	int start;

	// the end index of the gap
	int end;

	// the capacity of the entire buffer
	int cap;
} gap_buffer;

void gb_init(gap_buffer *gb, int size) {
	gb->data = (int *)MemAlloc(sizeof(int)*size);
	gb->start = 0;
	gb->end = size;
	gb->cap = size;
}

void gb_insert(gap_buffer *gb, int codepoint) {
	gb->data[(gb->start)++] = codepoint;
}

void gb_delete(gap_buffer *gb) {
	--(gb->start);
}

void gb_move_rel(gap_buffer *gb, int diff) {
	if (gb->start + diff < 0 || diff == 0) {
		return;
	}
	
	int i;
	if (diff < 0) {
		for (i = 0; i < (-1*diff); ++i) {
			gb->data[gb->end-1] = gb->data[gb->start-1];
			--(gb->start);
			--(gb->end);
		}
	} else {
		if (gb->end + diff > gb->cap) {
			return;
		}

		for (i = 0; i < diff; ++i) {
			gb->data[(gb->start)++] = gb->data[(gb->end)++];
		}
	}
}

void gb_draw(gap_buffer *gb, frame_state *state, Font font, float font_size, int line_height, int x, int y, int w, int h) {
	int i, codepoint, amount_to_move;
	Vector2 pos;
	Rectangle rect;

	pos.x = x;
	pos.y = y;

	amount_to_move = 0;

	for (i = 0; i < gb->start; ++i) {
		codepoint = gb->data[i];

		if (codepoint == '\n') {
			pos.x = x;
			pos.y += line_height;
			continue;
		}

		DrawTextCodepoint(font, codepoint, pos, font_size, WHITE);

		rect = GetGlyphAtlasRec(font, codepoint);
		rect.x = pos.x;
		rect.y = pos.y;
		if (state->mouse_pressed && CheckCollisionPointRec(state->mouse_position, rect)) {
			amount_to_move = -1*(gb->start-i);
		}

		pos.x += rect.width;
	}

	DrawRectangle(pos.x, pos.y, 2, line_height, BLACK);

	for (i = gb->end; i < gb->cap; ++i) {
		codepoint = gb->data[i];

		if (codepoint == '\n') {
			pos.x = x;
			pos.y += line_height;
			continue;
		}

		DrawTextCodepoint(font, codepoint, pos, font_size, WHITE);

		rect = GetGlyphAtlasRec(font, codepoint);
		rect.x = pos.x;
		rect.y = pos.y;
		if (state->mouse_pressed && CheckCollisionPointRec(state->mouse_position, rect)) {
			amount_to_move = (i - gb->end);
		}

		pos.x += rect.width;
	}

	if (amount_to_move != 0) {
		gb_move_rel(gb, amount_to_move);
	}
}
