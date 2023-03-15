#include "terminal.h"

static char digits[] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'};

void write_int_to_ascii(int n, char *buffer, int *buffer_length)
{
	if (n == 0) {
		buffer[(*buffer_length)++] = '0';
	}

	char parse_buffer[4];
	int parse_buffer_length = 0;

	while (n > 0 && parse_buffer_length < 4) {
		parse_buffer[parse_buffer_length++] = digits[n % 10];

		n /= 10;
	}

	for (int i = parse_buffer_length-1; i >= 0; --i) {
		buffer[(*buffer_length)++] = parse_buffer[i];
	}
}

void TerminalSetCursor(int x, int y)
{
	char buffer[32];
	int buffer_length = 0;
	int buffer_size = 32;

	buffer[buffer_length++] = '\033';
	buffer[buffer_length++] = '[';
	write_int_to_ascii(y, buffer, &buffer_length);
	buffer[buffer_length++] = ';';
	write_int_to_ascii(x, buffer, &buffer_length);
	buffer[buffer_length++] = 'H';

	TerminalWrite(buffer, buffer_length);
}

void TerminalSetForeground(char *Buffer, int *BufferLength, color Color)
{
	Buffer[(*BufferLength)++] = '\033';
	Buffer[(*BufferLength)++] = '[';
	Buffer[(*BufferLength)++] = '3';
	Buffer[(*BufferLength)++] = '8';
	Buffer[(*BufferLength)++] = ';';
	Buffer[(*BufferLength)++] = '2';
	Buffer[(*BufferLength)++] = ';';
	write_int_to_ascii(Color.r, Buffer, BufferLength);
	Buffer[(*BufferLength)++] = ';';
	write_int_to_ascii(Color.g, Buffer, BufferLength);
	Buffer[(*BufferLength)++] = ';';
	write_int_to_ascii(Color.b, Buffer, BufferLength);
	Buffer[(*BufferLength)++] = 'm';
}

void TerminalSetBackground(char *Buffer, int *BufferLength, color Color)
{
	Buffer[(*BufferLength)++] = '\033';
	Buffer[(*BufferLength)++] = '[';
	Buffer[(*BufferLength)++] = '4';
	Buffer[(*BufferLength)++] = '8';
	Buffer[(*BufferLength)++] = ';';
	Buffer[(*BufferLength)++] = '2';
	Buffer[(*BufferLength)++] = ';';
	write_int_to_ascii(Color.r, Buffer, BufferLength);
	Buffer[(*BufferLength)++] = ';';
	write_int_to_ascii(Color.g, Buffer, BufferLength);
	Buffer[(*BufferLength)++] = ';';
	write_int_to_ascii(Color.b, Buffer, BufferLength);
	Buffer[(*BufferLength)++] = 'm';
}

void TerminalGetEvent(TerminalEvent *Event)
{
	char Buffer[4];
	TerminalRead(Buffer, 4);
	Event->Key = Buffer[0];
}

void TerminalRender(cell *cells, int length)
{
	char Buffer[2000];
	int BufferLength = 0;

	color bg = {0, 0, 0};
	color fg = {0, 0, 0};

	TerminalSetCursor(0, 0);
	for (int i = 0; i < length; ++i) {
		cell c = *cells++;

		if (!ColorEquals(c.background, bg) || i == 0) {
			TerminalSetBackground(Buffer, &BufferLength, c.background);
			bg = c.background;
		}

		if (!ColorEquals(c.foreground, fg) || i == 0) {
			TerminalSetForeground(Buffer, &BufferLength, c.foreground);
			fg = c.foreground;
		}

		Buffer[BufferLength++] = c.key;

		if (BufferLength >= 1000) {
			TerminalWrite(Buffer, BufferLength);
			BufferLength = 0;
		}
	}

	TerminalWrite(Buffer, BufferLength);
}
