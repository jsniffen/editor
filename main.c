#include "raylib.h"
#include <stdlib.h>

static Font font;
static float font_size;
static int LINE_HEIGHT = 20;
static int MARGIN = 5;

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
	gb->data = (int *)malloc(sizeof(int)*size);
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

void gb_move(gap_buffer *gb, int i) {
	if (i == gb->start || i < 0) {
		return;
	}
	
	int j, diff;
	if (i < gb->start) {
		diff = gb->start - i;

		for (j = 0; j < diff; ++j) {
			gb->data[gb->end-1] = gb->data[gb->start-1];
			--(gb->start);
			--(gb->end);
		}
	} else {
		diff = i - gb->start;

		if (gb->end + diff > gb->cap) {
			return;
		}

		for (j = 0; j < diff; ++j) {
			gb->data[(gb->start)++] = gb->data[(gb->end)++];
		}
	}
}

gb_draw(gap_buffer *gb, int x, int y, int w, int h) {
	DrawRectangle(x, y, w, h, BLACK);
	DrawRectangleLines(x, y, w, h, YELLOW);

	int i, codepoint;
	Vector2 pos;
	Rectangle rect;

	pos.x = x + MARGIN;
	pos.y = y + MARGIN;

	for (i = 0; i < gb->start; ++i) {
		codepoint = gb->data[i];

		if (codepoint == '\n') {
			pos.x = x+5;
			pos.y += LINE_HEIGHT;
			continue;
		}

		DrawTextCodepoint(font, codepoint, pos, font_size, WHITE);

		rect = GetGlyphAtlasRec(font, codepoint);

		pos.x += rect.width;
	}

	DrawRectangle(pos.x, pos.y, 2, LINE_HEIGHT, WHITE);

	for (i = gb->end; i < gb->cap; ++i) {
		codepoint = gb->data[i];

		if (codepoint == '\n') {
			pos.x = x+5;
			pos.y += LINE_HEIGHT;
			continue;
		}

		DrawTextCodepoint(font, codepoint, pos, font_size, WHITE);

		rect = GetGlyphAtlasRec(font, codepoint);

		pos.x += rect.width;
	}
}

void draw_menu(int x, int y, int w, int h) {
	DrawRectangle(x, y, w, h, PURPLE);
}

void draw_status_bar(int x, int y, int w, int h) {
	DrawRectangle(x, y, w, h, BLUE);
}

int main(int argc, char **argv) {
	InitWindow(800, 450, "Test");
	SetTargetFPS(60);

	SetWindowState(FLAG_WINDOW_RESIZABLE);

	font_size = 24;
	font = LoadFontEx("C:\\Windows\\Fonts\\consola.ttf", font_size, 0, 0);

	gap_buffer gb;
	gb_init(&gb, 256);

	int x, y, screen_width, screen_height;
	int key;

	while (!WindowShouldClose()) {
		for (key = GetCharPressed(); key != 0; key = GetCharPressed()) {
			gb_insert(&gb, key);
		}

		for (key = GetKeyPressed(); key != 0; key = GetKeyPressed()) {
			switch (key) {
				case KEY_BACKSPACE:
					gb_delete(&gb);
					break;

				case KEY_ENTER:
					gb_insert(&gb, '\n');
					break;

				case KEY_LEFT:
					gb_move(&gb, gb.start-1);
					break;

				case KEY_RIGHT:
					gb_move(&gb, gb.start+1);
					break;
			}
		}

		BeginDrawing();

		ClearBackground(RAYWHITE);

		screen_width = GetScreenWidth();
		screen_height = GetScreenHeight();

		x = 0;
		y = 0;

		draw_menu(x, y, screen_width, LINE_HEIGHT);
		y += LINE_HEIGHT;

		gb_draw(&gb, x, y, screen_width, screen_height-y-LINE_HEIGHT);

		y = screen_height - LINE_HEIGHT;
		draw_status_bar(x, y, screen_width, LINE_HEIGHT);

		EndDrawing();
	}

	return 0;
}
