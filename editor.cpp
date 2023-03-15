#include "editor.h"

static int hue;
static int n;
static int brightness;

static color StatusBarBackground = {0, 0, 255};
static color StatusBarForeground = {255, 255, 255};
static color ColorBlack = {0, 0, 0};

void ClearColor(cell *BackBuffer, int Width, int Height, color Color)
{
	for (int Y = 0; Y < Height; ++Y) {
		for (int X = 0; X < Width; ++X) {
			BackBuffer[Y*Width + X].background = Color;
			BackBuffer[Y*Width + X].foreground = Color;
			BackBuffer[Y*Width + X].key = ' ';
		}
	}
}

void RenderStatusBar(cell *BackBuffer, int Width, int Height)
{
	cell *Cell = &BackBuffer[(Height-1)*Width];
	for (int X = 0; X < Width; ++X) {
		Cell[X].background = StatusBarBackground;
		Cell[X].foreground = StatusBarForeground;
		Cell[X].key = ' ';
	}
}

void Render(cell *BackBuffer, int Width, int Height)
{
	ClearColor(BackBuffer, Width, Height, ColorBlack);
	RenderStatusBar(BackBuffer, Width, Height);
}
