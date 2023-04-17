struct buffer
{
	u32 X0;
	u32 Y0;
	u32 Height;
	u32 Width;

	u32 CursorX;
	u32 CursorY;

	piece_table PieceTable;
	u8 String[256];
	u32 StringLength;

	u32 Lines[256];
	u32 LinesLength;
};

