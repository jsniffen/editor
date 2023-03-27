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

struct piece_table_entry_old
{
	bool Original;
	int StartIndex;
	int Length;
};

struct buffer
{
	u8 *Content;
	u32 ContentLength;
	piece_table_entry_old PieceTable[256];
};

struct editor
{
	cell *Cells;
	int Width;
	int Height;
	piece_table PieceTable;
};
