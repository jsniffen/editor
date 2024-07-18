package main

import "core:strings"
import "core:fmt"
import "core:unicode/utf8"

GapBuffer :: struct {
	data: [256]rune,
	start: int,
	end: int,
	len: int,
}

gb_move :: proc(gb: ^GapBuffer, i: int) {
	// TODO(Julian): handle right overflow
	if i < 0 || i == gb.start {
		return
	}

	if i < gb.start {
		for j := 0; j < gb.start - i; j += 1 {
			gb.data[gb.end-1] = gb.data[gb.start-1]
			gb.start -= 1
			gb.end -= 1
		}
	} else {
		for j := 0; j < i - gb.start; j += 1 {
			gb.data[gb.start] = gb.data[gb.end]
			gb.start += 1
			gb.end += 1
		}
	}
}

gb_insert :: proc(gb: ^GapBuffer, r: rune) {
	gb.data[gb.start] = r
	gb.start += 1
}

gb_delete :: proc(gb: ^GapBuffer) {
	if gb.start > 0 {
		gb.start -= 1
	}
}

gb_text :: proc(gb: ^GapBuffer) -> ([]rune, []rune) {
	prefix := gb.data[:gb.start]
	suffix := gb.data[gb.end:]

	return prefix, suffix
}
