#include <stdio.h>
#include <fcntl.h>
#include <signal.h>
#include <termios.h>
#include <unistd.h>
#include <string.h>
#include <sys/ioctl.h>
#include <cstdlib>

#include "editor.cpp"
#include "terminal.cpp"

static int fd;
static int Width;
static int Height;
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

void UpdateSize(int i)
{
	struct winsize WinSize = {};
	if (ioctl(fd, TIOCGWINSZ, &WinSize) < 0) return;

	Width = WinSize.ws_col;
	Height = WinSize.ws_row;
}

int main()
{
	fd = open("/dev/tty", O_RDWR);
	if (fd < 0) return 1;

	struct sigaction sa = {};
	sa.sa_handler = UpdateSize;
	sa.sa_flags = 0;
	sigaction(SIGWINCH, &sa, 0);

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

	UpdateSize(0);

	editor Editor = {};
	Editor.Buffer.Content = "hello world\nhello world";
	Editor.Buffer.ContentLength = 20;
	Editor.Width = Width;
	Editor.Height = Height;
	Editor.Cells = (cell *)malloc(sizeof(cell)*Width*Height);

	bool Running = true;
	while (Running) {
		Render(&Editor);

		TerminalRender(Editor.Cells, Width*Height);

		TerminalEvent Event;
		TerminalGetEvent(&Event);

		if (Event.Key == 'q') {
			Running = false;
		}
	}

	tcsetattr(fd, TCSAFLUSH, &og_tios);
	return 0;
}
