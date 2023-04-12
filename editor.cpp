#include "editor.h"

static color CursorBackground = {255, 255, 255};
static color StatusBarBackground = {0, 0, 255};
static color StatusBarForeground = {255, 255, 255};
static color ColorBlack = {0, 0, 0};

void Init(editor *Editor, u32 Width, u32 Height)
{
	Init(&Editor->Buffer.PieceTable, (u8 *)"hello world\nhello julian!", 25);
	Editor->Buffer.X0 = 2;
	Editor->Buffer.Y0 = 2;
	Editor->Buffer.Width = 5;
	Editor->Buffer.Height = 5;

	Editor->Width = Width;
	Editor->Height = Height;
	Editor->Cells = (cell *)VirtualAlloc(0,
			sizeof(cell)*Width*Height,
			MEM_COMMIT,
			PAGE_READWRITE);

	Editor->Running = true;
	Editor->CursorX = 0;
	Editor->CursorY = 0;
}

void ClearColor(editor *Editor, color Color)
{
	for (int Y = 0; Y < Editor->Height; ++Y) {
		for (int X = 0; X < Editor->Width; ++X) {
			Editor->Cells[Y*Editor->Width + X].background = Color;
			Editor->Cells[Y*Editor->Width + X].foreground = Color;
			Editor->Cells[Y*Editor->Width + X].key = ' ';
		}
	}
}

void MoveCursorLeft(editor *Editor)
{
	if (Editor->CursorX > 0) {
		--Editor->CursorX;
	}
}

void MoveCursorRight(editor *Editor)
{
	if (Editor->CursorX < Editor->Width - 1) {
		++Editor->CursorX;
	}
}

void MoveCursorUp(editor *Editor)
{
	if (Editor->CursorY > 0) {
		--Editor->CursorY;
	}
}

void MoveCursorDown(editor *Editor)
{
	if (Editor->CursorY < Editor->Height - 2) {
		++Editor->CursorY;
	}
}

void RenderCursor(editor *Editor)
{
	cell *Cell = &Editor->Cells[Editor->Width*Editor->CursorY + Editor->CursorX];

	Cell->background = CursorBackground;
	Cell->key = ' ';
}

void RenderStatusBar(editor *Editor)
{
	cell *Cell = &Editor->Cells[(Editor->Height-1)*Editor->Width];
	for (int X = 0; X < Editor->Width; ++X) {
		Cell[X].background = StatusBarBackground;
		Cell[X].foreground = StatusBarForeground;
		Cell[X].key = ' ';
	}
}

void RenderBuffer(editor *Editor)
{
	buffer Buffer = Editor->Buffer;

	u8 Content[256];
	u32 BytesRead;
	Read(&Buffer.PieceTable, Content, 256, &BytesRead);

	u32 Y = Buffer.Y0;
	u32 X = Buffer.X0;
	u32 Index;
	for (Index = 0; Index < BytesRead; ++Index) {
		u8 Key = Content[Index];

		if (Key == '\n') {
			Y += 1;
			X = Buffer.X0;
			continue;
		}

		if (X < Buffer.X0 + Buffer.Width && Y < Buffer.Y0 + Buffer.Height) {
			Editor->Cells[Y*Editor->Width + X].key = Key;
			Editor->Cells[Y*Editor->Width + X].foreground = {255, 255, 255};
		}

		++X;
	}
}

void Render(editor *Editor)
{
	ClearColor(Editor, ColorBlack);
	RenderBuffer(Editor);
	RenderStatusBar(Editor);
	RenderCursor(Editor);
}

void Update(editor *Editor, event Event)
{
	if (Event.KeyCode == 'q') {
		Editor->Running = false;
	} else if (Event.KeyCode == KeyUpArrow) {
		MoveCursorUp(Editor);
	} else if (Event.KeyCode == KeyDownArrow) {
		MoveCursorDown(Editor);
	} else if (Event.KeyCode == KeyLeftArrow) {
		MoveCursorLeft(Editor);
	} else if (Event.KeyCode == KeyRightArrow) {
		MoveCursorRight(Editor);
	} else {
		Insert(&Editor->Buffer.PieceTable, 0, (u8 *)&Event.KeyCode, 1);
	}
}
