#include "piece_table.h"

b32 Init(piece_table *Table, u8 *String, u32 Length) {
	if (Length > MAX_ORIGINAL_BUFFER_LENGTH) {
		return false;
	}

	for (u32 Index = 0; Index < Length; ++Index) {
		Table->OriginalBuffer[Table->OriginalBufferLength++] = String[Index];
	}

	Table->OriginalBufferLength = Length;
	Table->AddBufferLength = 0;

	Table->PieceTable[0].Original = true;
	Table->PieceTable[0].StartIndex = 0;
	Table->PieceTable[0].Length = Length;
	Table->PieceTableLength = 1;
	return true;
}

b32 ShiftRight(piece_table *Table, u32 ShiftIndex, u32 ShiftCount) {
	if (Table->PieceTableLength + ShiftCount > MAX_PIECE_TABLE_LENGTH) {
		return false;
	}

	for (u32 Shift = 0; Shift < ShiftCount; ++Shift) {
		for (u32 Index = Table->PieceTableLength; Index > ShiftIndex; --Index) {
			Table->PieceTable[Index] = Table->PieceTable[Index-1];
		}
		++Table->PieceTableLength;
	}


	return true;
}

b32 Insert(piece_table *Table, u32 Index, u8 *String, u32 Length)
{
	if (Table->AddBufferLength + Length > MAX_ADD_BUFFER_LENGTH) {
		return false;
	}

	u32 Count = 0;
	for (u32 PieceTableIndex = 0; PieceTableIndex < Table->PieceTableLength; ++PieceTableIndex) {
		piece_table_entry Entry = Table->PieceTable[PieceTableIndex];

		Count += Entry.Length;

		if (Index < Count) {
			u32 Pivot = Index - (Count - Entry.Length);
			// u32 Pivot = Count - Index;

			if (Pivot == Entry.Length) {
				// Split at the end of the entry.
				// Creates 1 Entry.
				if (ShiftRight(Table, PieceTableIndex, 1)) {
					Table->PieceTable[PieceTableIndex+1].Length = Length;
					Table->PieceTable[PieceTableIndex+1].Original = false;
					Table->PieceTable[PieceTableIndex+1].StartIndex = Table->AddBufferLength;
				}
			} else if (Pivot == 0) {
				// Split at the beginning of the entry.
				// Creates 1 Entry.
				if (ShiftRight(Table, PieceTableIndex, 1)) {
					Table->PieceTable[PieceTableIndex].Length = Length;
					Table->PieceTable[PieceTableIndex].Original = false;
					Table->PieceTable[PieceTableIndex].StartIndex = Table->AddBufferLength;
				}
			} else {
				// Split somewhere in the middle.
				// Creates 2 Entries.
				if (ShiftRight(Table, PieceTableIndex, 2)) {
					Table->PieceTable[PieceTableIndex].Length = Pivot;

					Table->PieceTable[PieceTableIndex+1].Length = Length;
					Table->PieceTable[PieceTableIndex+1].Original = false;
					Table->PieceTable[PieceTableIndex+1].StartIndex = Table->AddBufferLength;

					Table->PieceTable[PieceTableIndex+2].StartIndex = Pivot;
					Table->PieceTable[PieceTableIndex+2].Length = Entry.Length - Pivot;
				}
			}

			for (i32 StringIndex = 0; StringIndex < Length; ++StringIndex) {
				Table->AddBuffer[Table->AddBufferLength++] = String[StringIndex];
			}

			return true;
		}
	}

	return false;
}

b32 Delete(piece_table *Table, u32 Index)
{
	u32 Count = 0;
	for (u32 PieceTableIndex = 0; PieceTableIndex < Table->PieceTableLength; ++PieceTableIndex) {
		piece_table_entry Entry = Table->PieceTable[PieceTableIndex];

		Count += Entry.Length;

		if (Index < Count) {
			u32 Pivot = Index - (Count - Entry.Length);
			// u32 Pivot = Count - Index;

			if (Pivot == Entry.Length) {
				--Table->PieceTable[PieceTableIndex].Length;
			} else if (Pivot == 0) {
				--Table->PieceTable[PieceTableIndex].Length;
				++Table->PieceTable[PieceTableIndex].StartIndex;
			} else {
				// Split somewhere in the middle.
				if (ShiftRight(Table, PieceTableIndex, 1)) {
					Table->PieceTable[PieceTableIndex].Length = Pivot;

					Table->PieceTable[PieceTableIndex+1].StartIndex += Pivot + 1;
					Table->PieceTable[PieceTableIndex+1].Length -= Pivot + 1;
				}
			}

			return true;
		}
	}
}

void Read(piece_table *Table, u8 *OutBuffer, u32 OutBufferLength, u32 *BytesRead)
{
	*BytesRead = 0;
	for (int Index = 0; Index < Table->PieceTableLength; ++Index) {
		piece_table_entry Entry = Table->PieceTable[Index];

		u8 *Buffer = Entry.Original ? Table->OriginalBuffer : Table->AddBuffer;
		
		for (int BufferIndex = Entry.StartIndex; BufferIndex < Entry.Length+Entry.StartIndex; ++BufferIndex) {
			if (*BytesRead < OutBufferLength) {
				OutBuffer[(*BytesRead)++] = Buffer[BufferIndex];
			}
		}
	}
}
