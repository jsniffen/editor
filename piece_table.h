#define MAX_PIECE_TABLE_LENGTH 256
#define MAX_ADD_BUFFER_LENGTH 256
#define MAX_ORIGINAL_BUFFER_LENGTH 256

struct piece_table_entry
{
	b32 Original;
	u32 StartIndex;
	u32 Length;
};

struct piece_table
{
	u8 OriginalBuffer[MAX_ORIGINAL_BUFFER_LENGTH];
	u32 OriginalBufferLength;

	u8 AddBuffer[MAX_ADD_BUFFER_LENGTH];
	u32 AddBufferLength;

	piece_table_entry PieceTable[MAX_PIECE_TABLE_LENGTH];
	u32 PieceTableLength;
};
