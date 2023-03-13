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

void TerminalRead(char *Buffer, int Length)
{
	read(fd, Buffer, Length);
}

void TerminalWrite(char *Buffer, int Length)
{
	write(fd, Buffer, Length);
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

	bool Running = true;
	while (Running) {
		TerminalEvent Event;
		TerminalGetEvent(&Event);

		if (Event.Key == 'q') {
			Running = false;
		}
	}

	tcsetattr(fd, TCSAFLUSH, &og_tios);
	return 0;
}
