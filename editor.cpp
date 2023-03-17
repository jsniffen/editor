#include "editor.h"

static color StatusBarBackground = {0, 0, 255};
static color StatusBarForeground = {255, 255, 255};
static color ColorBlack = {0, 0, 0};

void ClearColor(editor *Editor, color Color)
{
	for (int Y = 0; Y < Editor->Height; ++Y) {
		for (int X = 0; X < Editor->Width; ++X) {
			Editor->Cells[Y*Editor->Width + X].background = Color;
			Editor->Cells[Y*Editor->Width + X].foreground = Color;
			Editor->Cells[Y*Editor->Width + X].key = ' ';
		}
	}
}

void RenderStatusBar(editor *Editor)
{
	cell *Cell = &Editor->Cells[(Editor->Height-1)*Editor->Width];
	for (int X = 0; X < Editor->Width; ++X) {
		Cell[X].background = StatusBarBackground;
		Cell[X].foreground = StatusBarForeground;
		Cell[X].key = ' ';
	}
}

void RenderBuffer(editor *Editor)
{
	int X = 0;
	int Y = 0;
	for (int Index = 0; Index < Editor->Buffer.ContentLength; ++Index) {
		char Key = Editor->Buffer.Content[Index];

		if (Key == '\n') {
			Y += 1;
			X = 0;
			continue;
		}

		Editor->Cells[Y*Editor->Width + X].key = Key;
		Editor->Cells[Y*Editor->Width + X].foreground = {255, 255, 255};


		++X;
	}
}

void Render(editor *Editor)
{
	ClearColor(Editor, ColorBlack);
	RenderBuffer(Editor);
	RenderStatusBar(Editor);
}
