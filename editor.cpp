#include "editor.h"

static int hue;
static int n;

void Update(cell *Cells, int Width, int Height)
{
	for (int i = 0; i < Width*Height; ++i) {
		hue = (hue+1)%255;
		Cells[i].background = {hue, 0, hue};
		Cells[i].foreground = {0, 0, 0};
		Cells[i].key = n % 2 ? 'x' : 'y';
	};
	++n;
}
