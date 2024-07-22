#include "raylib.h"

static Font font;
static float font_size;
static int LINE_HEIGHT = 25;
static int MARGIN = 5;

typedef struct frame_state {
	Vector2 mouse_position;
	bool mouse_pressed;
} frame_state;

#include "gap_buffer.c"

typedef struct editor {
	gap_buffer *focused_buffer;
} editor;

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

	while (!WindowShouldClose()) {
		state.mouse_position = GetMousePosition();
		state.mouse_pressed = IsMouseButtonPressed(MOUSE_BUTTON_LEFT);

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

		EndDrawing();
	}

	return 0;
}
