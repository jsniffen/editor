#include <windows.h>
#include <stdint.h>
#include "types.h"
#include "piece_table.cpp"
#include "buffer.cpp"
#include "editor.cpp"
#include "terminal.cpp"

static HANDLE Stdin, Stdout;
static u32 Width, Height;

void TerminalWrite(char *Buffer, int Length)
{
	DWORD Written;
	HANDLE Stdout = GetStdHandle(STD_OUTPUT_HANDLE);
	WriteFile(Stdout, Buffer, Length, &Written, 0);
}

u32 TerminalRead(char *Buffer, int Length)
{
	DWORD Read;
	HANDLE Stdin = GetStdHandle(STD_INPUT_HANDLE);
	ReadConsole(Stdin, Buffer, Length, &Read, 0);
	return Read;
}

void CALLBACK ResizeCallback(HWINEVENTHOOK Hook, DWORD Event,
		HWND Hwnd, LONG Object, LONG Child, DWORD Thread,
		DWORD Time)
{
	CONSOLE_SCREEN_BUFFER_INFO info;
	GetConsoleScreenBufferInfo(Stdout, &info);
	Width = info.srWindow.Right+1;
	Height = info.srWindow.Bottom-info.srWindow.Top+1;
}

int main()
{
	HWND console;
	DWORD mode;

	Stdin = GetStdHandle(STD_INPUT_HANDLE);
	Stdout = GetStdHandle(STD_OUTPUT_HANDLE);

	console = GetConsoleWindow();
	HWINEVENTHOOK Hook = SetWinEventHook(EVENT_CONSOLE_LAYOUT,
			EVENT_CONSOLE_LAYOUT, 0, ResizeCallback,
			0, 0, WINEVENT_OUTOFCONTEXT);

	SetConsoleTitle("Editor");

	if (!GetConsoleMode(Stdout, &mode)) {
		return GetLastError();
	}
	mode |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
	if (!SetConsoleMode(Stdout, mode)) {
		return GetLastError();
	}

	if (!GetConsoleMode(Stdin, &mode)) {
		return GetLastError();
	}
	mode |= ENABLE_VIRTUAL_TERMINAL_INPUT;
	mode &= ~(ENABLE_LINE_INPUT|ENABLE_ECHO_INPUT);
	if (!SetConsoleMode(Stdin, mode)) {
		return GetLastError();
	}


	TerminalHideCursor();

	ResizeCallback(0, 0, 0, 0, 0, 0, 0);

	editor Editor = {};
	Init(&Editor, Width, Height);

	while (Editor.Running) {
		MSG Message;
		while (PeekMessage(&Message, console, EVENT_CONSOLE_LAYOUT, EVENT_CONSOLE_LAYOUT, PM_REMOVE)) {
			DispatchMessage(&Message);
		}

		if (Width != Editor.Width || Height != Editor.Height) {
			VirtualFree(Editor.Cells, 0, MEM_RELEASE);
			Editor.Width = Width;
			Editor.Height = Height;
			Editor.Cells = (cell *)VirtualAlloc(0,
					sizeof(cell)*Width*Height,
					MEM_COMMIT,
					PAGE_READWRITE);
		}

		Render(&Editor);

		TerminalRender(Editor.Cells, Width*Height);

		event Event;
		TerminalGetEvent(&Event);
		Update(&Editor, Event);
	}

	return 0;
}
