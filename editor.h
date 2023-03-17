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

struct piece_table_entry
{
	bool Original;
	int StartIndex;
	int Length;
};

struct buffer
{
	char *Content;
	int ContentLength;
	piece_table_entry PieceTable[256];
};

struct editor
{
	cell *Cells;
	int Width;
	int Height;
	buffer Buffer;
};
