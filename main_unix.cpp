#include <stdio.h>
#include <fcntl.h>
#include <signal.h>
#include <termios.h>
#include <unistd.h>
#include <string.h>
#include "terminal.cpp"

static int fd;
static struct termios tios;
static struct termios og_tios;

void terminal_read(char *buffer, int len)
{
	read(fd, buffer, len);
}

void terminal_write(char *buffer, int len)
{
	write(fd, buffer, len);
}

int main()
{
	fd = open("/dev/tty", O_RDWR);
	if (fd < 0) return 1;

	tcgetattr(fd, &og_tios);
	memcpy(&tios, &og_tios, sizeof(struct termios));

	tios.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON);
	tios.c_oflag &= ~OPOST;
	tios.c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
	tios.c_cflag &= ~(CSIZE | PARENB);
	tios.c_cflag |= CS8;
	tios.c_cc[VMIN] = 1;
	tios.c_cc[VTIME] = 0;
	tcsetattr(fd, TCSAFLUSH, &tios);

	terminal_set_cursor(15, 15);
	terminal_set_color_fg({0, 0, 255});
	terminal_set_color_bg({0, 255, 0});
	terminal_write("hello", 5);

	tcsetattr(fd, TCSAFLUSH, &og_tios);
	return 0;
}
