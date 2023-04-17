#include "buffer.h"

void Init(buffer *Buffer, u32 X0, u32 Y0, u32 Height, u32 Width)
{
	Buffer->X0 = X0;
	Buffer->Y0 = Y0;
	Buffer->Height = Height;
	Buffer->Width = Width;
	Buffer->LinesLength = 0;

	Init(&Buffer->PieceTable, (u8 *)"hello\nworld", 11);
	Read(&Buffer->PieceTable, Buffer->String, 256, &Buffer->StringLength);
}

void Insert(buffer *Buffer, u8 Character)
{
}
