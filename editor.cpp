#include "editor.h"

static int hue;
static int n;
static int brightness;

void Update(cell *Cells, int Width, int Height)
{
	brightness = (brightness + 100)%255;
	for (int i = 0; i < Width*Height; ++i) {
		if (i%10 == 0) hue = (hue + 1)%3;

		if (hue == 0) {
			Cells[i].background = {brightness, 0, 0};
		} else if (hue == 1) {
			Cells[i].background = {0, brightness, 0};
		} else {
			Cells[i].background = {0, 0, brightness};
		}

		Cells[i].foreground = {0, 0, 0};
		Cells[i].key = n % 2 ? 'x' : 'y';
	};
	++n;
}
