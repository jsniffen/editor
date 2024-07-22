#include "raylib.h"

static Font font;
static float font_size;
static int LINE_HEIGHT = 25;
static int MARGIN = 5;

float min(float a, float b) {
	return a < b ? a : b;
}

float max(float a, float b) {
	return a > b ? a : b;
}

float diff(float a, float b) {
	return max(a, b) - min(a, b);
}

typedef struct frame_state {
	Vector2 mouse_position;
	bool mouse_pressed;
	Rectangle mouse_selection;
} frame_state;

#include "gap_buffer.c"

typedef struct editor {
	gap_buffer *focused_buffer;
} editor;

#include "window.c"


int main(int argc, char **argv) {
	InitWindow(800, 450, "Test");
	SetTargetFPS(60);

	SetWindowState(FLAG_WINDOW_RESIZABLE);

	font_size = 24;
	font = LoadFontEx("C:\\Windows\\Fonts\\consola.ttf", font_size, 0, 0);

	window win;
	win_init(&win);

	editor ed;
	ed.focused_buffer = &(win.header_buffer);

	int x, y, screen_width, screen_height;
	int codepoint, key;
	frame_state state;
	Vector2 mouse_select_start;
	Vector2 mouse_select_end;

	while (!WindowShouldClose()) {
		state.mouse_position = GetMousePosition();
		state.mouse_pressed = IsMouseButtonPressed(MOUSE_BUTTON_LEFT);

		if (state.mouse_pressed) {
			mouse_select_start = state.mouse_position;
			mouse_select_end = mouse_select_start;
		} else if (IsMouseButtonDown(MOUSE_BUTTON_LEFT) || IsMouseButtonReleased(MOUSE_BUTTON_LEFT)) {
			mouse_select_end = state.mouse_position;
		}

		state.mouse_selection.x = min(mouse_select_start.x, mouse_select_end.x);
		state.mouse_selection.y = min(mouse_select_start.y, mouse_select_end.y);
		state.mouse_selection.width = diff(mouse_select_start.x, mouse_select_end.x);
		state.mouse_selection.height = diff(mouse_select_start.y, mouse_select_end.y);

		for (codepoint = GetCharPressed(); codepoint != 0; codepoint = GetCharPressed()) {
			gb_insert(ed.focused_buffer, codepoint);
		}

		for (key = GetKeyPressed(); key != 0; key = GetKeyPressed()) {
			switch (key) {
				case KEY_BACKSPACE:
					gb_delete(ed.focused_buffer);
					break;

				case KEY_ENTER:
					gb_insert(ed.focused_buffer, '\n');
					break;

				case KEY_LEFT:
					gb_move_rel(ed.focused_buffer, -1);
					break;

				case KEY_RIGHT:
					gb_move_rel(ed.focused_buffer, 1);
					break;
			}
		}

		BeginDrawing();

		ClearBackground(RAYWHITE);

		screen_width = GetScreenWidth();
		screen_height = GetScreenHeight();

		x = 0;
		y = 0;

		win_draw(&win, &ed, &state, x, y, screen_width, screen_height);

		/* Color c = ORANGE; */
		/* c.a = 100; */
		/* DrawRectangleRec(state.mouse_selection, c); */

		EndDrawing();
	}

	return 0;
}
