struct color
{
	int r;
	int g;
	int b;
};

bool ColorEquals(color c1, color c2) {
	return c1.r == c2.r &&
		c1.g == c2.g &&
		c1.b == c2.b;
}

struct cell
{
	color foreground;
	color background;
	char key;
};

struct editor
{
	cell *Cells;
	int Width;
	int Height;
	b32 Running;
	buffer Buffer;
};

enum key_code
{
	KeyDownArrow, KeyRightArrow, KeyLeftArrow, KeyUpArrow,
	Space = 32, Backspace, DoubleQuote, Pound, Dollar, Percent, Ampersand, Quote, LeftParen, RightParen,
	Asterisk, Plus, Comma, Dash, Period, ForwardSlash, Zero, One, Two, Three, Four, Five, Six,
	Seven, Eight, Nine, Colon, SemiColon, LeftArrow, Equals, RightArrow, Question, At, A, B, C, D, E, F, G, H, I, 
	J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z, LeftBracket, BackSlash, ForwardBracket, Caret, Underscore, BackTick,
	a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z, LeftCurlyBrace, Line, RightCurlyBrace, Tilde,
	Del
};

struct event
{
	key_code KeyCode;
};
