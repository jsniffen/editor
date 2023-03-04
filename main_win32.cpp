#include <windows.h>
#include "terminal.cpp"

void terminal_write(char *buffer, int len) 
{
	DWORD bytes_written;
	HANDLE stdout = GetStdHandle(STD_OUTPUT_HANDLE);
	WriteFile(stdout, buffer, len, &bytes_written, 0);
}

void terminal_read(char *buffer, int len)
{
	DWORD bytes_read;
	HANDLE stdin = GetStdHandle(STD_INPUT_HANDLE);
	ReadConsole(stdin, buffer, len, &bytes_read, 0);
}

int main()
{
	HANDLE stdin, stdout;
	DWORD mode;

	stdin = GetStdHandle(STD_INPUT_HANDLE);
	stdout = GetStdHandle(STD_OUTPUT_HANDLE);

	SetConsoleTitle("Editor");

	if (!GetConsoleMode(stdout, &mode)) {
		return GetLastError();
	}
	mode |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
	if (!SetConsoleMode(stdout, mode)) {
		return GetLastError();
	}

	terminal_set_cursor(15, 15);
	terminal_set_color_fg({0, 0, 255});
	terminal_set_color_bg({0, 255, 0});
	terminal_write("hello", 5);
	return 0;
}
