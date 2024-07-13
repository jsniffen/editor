package main

import "core:strings"
import "core:unicode/utf8"

GapBuffer :: struct {
	data: [256]rune,
	start: u32,
	end: u32,
	len: u32,
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

gb_text :: proc(gb: ^GapBuffer) -> (cstring) {
	prefix := utf8.runes_to_string(gb.data[:gb.start])
	suffix := utf8.runes_to_string(gb.data[gb.end:])
	
	result, _ := strings.concatenate([]string{prefix, suffix})
	return strings.clone_to_cstring(result)
}
