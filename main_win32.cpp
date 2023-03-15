#include <windows.h>
#include "editor.cpp"
#include "terminal.cpp"

static HANDLE Stdin, Stdout;
static int Width, Height;

void TerminalWrite(char *Buffer, int Length)
{
	DWORD Written;
	HANDLE Stdout = GetStdHandle(STD_OUTPUT_HANDLE);
	WriteFile(Stdout, Buffer, Length, &Written, 0);
}

void TerminalRead(char *Buffer, int Length)
{
	DWORD Read;
	HANDLE Stdin = GetStdHandle(STD_INPUT_HANDLE);
	ReadConsole(Stdin, Buffer, Length, &Read, 0);
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


	ResizeCallback(0, 0, 0, 0, 0, 0, 0);
	int BackBufferLength = Width*Height;
	cell *BackBuffer = (cell *)VirtualAlloc(0,
			sizeof(cell)*BackBufferLength,
			MEM_COMMIT,
			PAGE_READWRITE);

	bool Running = true;
	while (Running) {
		MSG Message;
		while (PeekMessage(&Message, console, EVENT_CONSOLE_LAYOUT, EVENT_CONSOLE_LAYOUT, PM_REMOVE)) {
			DispatchMessage(&Message);
		}

		if (Width*Height != BackBufferLength) {
			VirtualFree(BackBuffer, BackBufferLength, MEM_RELEASE);
			BackBufferLength = Width*Height;
			BackBuffer = (cell *)VirtualAlloc(0,
					sizeof(cell)*BackBufferLength,
					MEM_COMMIT,
					PAGE_READWRITE);
		}

		TerminalEvent Event;
		TerminalGetEvent(&Event);

		if (Event.Key == 'q') {
			Running = false;
		}

		Render(BackBuffer, Width, Height);

		TerminalRender(BackBuffer, Width*Height);
	}

	return 0;
}
