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

void terminal_set_cursor(int x, int y)
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

	terminal_write(buffer, buffer_length);
}

void terminal_set_color_fg(color c)
{
	char buffer[32];
	int buffer_length = 0;
	int buffer_size = 32;

	buffer[buffer_length++] = '\033';
	buffer[buffer_length++] = '[';
	buffer[buffer_length++] = '3';
	buffer[buffer_length++] = '8';
	buffer[buffer_length++] = ';';
	buffer[buffer_length++] = '2';
	buffer[buffer_length++] = ';';
	write_int_to_ascii(c.r, buffer, &buffer_length);
	buffer[buffer_length++] = ';';
	write_int_to_ascii(c.g, buffer, &buffer_length);
	buffer[buffer_length++] = ';';
	write_int_to_ascii(c.b, buffer, &buffer_length);
	buffer[buffer_length++] = 'm';

	terminal_write(buffer, buffer_length);
}

void terminal_set_color_bg(color c)
{
	char buffer[32];
	int buffer_length = 0;
	int buffer_size = 32;

	buffer[buffer_length++] = '\033';
	buffer[buffer_length++] = '[';
	buffer[buffer_length++] = '4';
	buffer[buffer_length++] = '8';
	buffer[buffer_length++] = ';';
	buffer[buffer_length++] = '2';
	buffer[buffer_length++] = ';';
	write_int_to_ascii(c.r, buffer, &buffer_length);
	buffer[buffer_length++] = ';';
	write_int_to_ascii(c.g, buffer, &buffer_length);
	buffer[buffer_length++] = ';';
	write_int_to_ascii(c.b, buffer, &buffer_length);
	buffer[buffer_length++] = 'm';

	terminal_write(buffer, buffer_length);
}
