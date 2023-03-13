struct color
{
	int r;
	int g;
	int b;
};

struct TerminalEvent
{
	char Key;
};

void TerminalWrite(char *Buffer, int Length);

void TerminalRead(char *Buffer, int Length);

