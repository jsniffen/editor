struct color
{
	int r;
	int g;
	int b;
};

bool ColorEquals(color c1, color c2) {
	return c1.r == c2.r &&
		c1.g == c2.g &&
		c1.b == c2.b;
}

struct cell
{
	color foreground;
	color background;
	char key;
};
