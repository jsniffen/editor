#include "terminal.h"

static char digits[] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'};

void parse_int_to_ascii(int x, char *buffer, int buffer_length, int *written)
{
	*written = 0;
	while (x > 0 && *written < buffer_length) {
		buffer[(*written)++] = digits[x%10];
		x /= 10;
	}
}

void terminal_set_cursor(int x, int y)
{
	char buffer[32];
	char parse_buffer[4];
	int buffer_length = 0;
	int written;

	buffer[buffer_length++] = '\033';
	buffer[buffer_length++] = '[';

	parse_int_to_ascii(y, parse_buffer, 4, &written);
	for (int i = written-1; i >= 0; --i) {
		buffer[buffer_length++] = parse_buffer[i];
	}

	buffer[buffer_length++] = ';';
	parse_int_to_ascii(x, parse_buffer, 4, &written);
	for (int i = written-1; i >= 0; --i) {
		buffer[buffer_length++] = parse_buffer[i];
	}

	buffer[buffer_length++] = 'H';

	terminal_write(buffer, buffer_length);
}
