package main

import "core:strings"

PieceTableIterator :: struct {
	// the piece table to iterate over
	pt: PieceTable,

	// entry we're currently pointing at
	entry_index: int,

	// the index into current entry
	cursor: int,

	// the index of the total string
	index: int,
}

pt_iterator :: proc(pt: PieceTable) -> PieceTableIterator {
	return PieceTableIterator{
		pt=pt,
		entry_index=0,
		cursor=-1,
		index=0,
	}
}

pt_iterator_next :: proc(it: ^PieceTableIterator) -> (rune, int, bool) {
	r: rune
	if it.entry_index >= len(it.pt.entries) {
		return r, it.index, false
	}
	entry := it.pt.entries[it.entry_index]
	if it.cursor == -1 {
		it.cursor = entry.start
	}
	if it.cursor >= entry.start + entry.length {
		it.entry_index += 1
		if it.entry_index >= len(it.pt.entries) {
			return r, it.index, false
		}
		entry = it.pt.entries[it.entry_index]
		it.cursor = entry.start
	}
	buf := it.pt.original_buf if entry.is_original else it.pt.append_buf
	r = buf[it.cursor]
	i := it.index
	it.cursor += 1
	it.index += 1
	return r, i, true
}

pt_iterator_len :: proc(it: ^PieceTableIterator) -> int {
	count := 0
	for _ in pt_iterator_next(it) {
		count += 1
	}
	return count
}

PieceTableEntry :: struct {
	start: int,
	length: int,
	is_original: bool,
}

PieceTable :: struct {
	entries: [dynamic]PieceTableEntry,
	original_buf: [dynamic]rune,
	append_buf: [dynamic]rune,
}

pt_init :: proc(pt: ^PieceTable) {
	pt.entries = make([dynamic]PieceTableEntry)
	pt.original_buf = make([dynamic]rune)
	pt.append_buf = make([dynamic]rune)
}

pt_to_string :: proc(pt: PieceTable) -> string {
	builder: strings.Builder
	it := pt_iterator(pt)
	for r in pt_iterator_next(&it) {
		strings.write_rune(&builder, r)
	}
	return strings.to_string(builder)
}

pt_load :: proc(pt: ^PieceTable, s: string) {
	for codepoint in s {
		append(&pt.original_buf, codepoint)
	}
	append(&pt.entries, PieceTableEntry{
		start=0,
		length=len(s),
		is_original=true,
	})
}

pt_insert :: proc(pt: ^PieceTable, codepoint: rune, cursor: int) {
	if cursor < 0 {
		return
	}

	start := 0
	i := 0

	for entry in pt.entries {
		if cursor < start + entry.length {
			break
		}

		start += entry.length
		i += 1
	}

	if cursor == start {
		append(&pt.append_buf, codepoint)
		if i > 0 && !pt.entries[i-1].is_original && pt.entries[i-1].start + pt.entries[i-1].length == len(pt.append_buf)-1 {
			pt.entries[i-1].length += 1
		} else {
			inject_at(&pt.entries, i, PieceTableEntry{
				start = len(pt.append_buf)-1,
				length = 1,
				is_original = false,
			})
		}
	} else if i < len(pt.entries) {
		append(&pt.append_buf, codepoint)

		entry := pt.entries[i]

		pivot := cursor - start

		inject_at(&pt.entries, i+1, PieceTableEntry{
			start = len(pt.append_buf)-1,
			length = 1,
			is_original = false,
		})

		inject_at(&pt.entries, i+2, PieceTableEntry{
			start = pivot,
			length = entry.length - pivot,
			is_original = entry.is_original,
		})

		pt.entries[i].length = pivot
		return
	}
}

pt_delete :: proc(pt: ^PieceTable, cursor: int) {
	if cursor < 0 {
		return
	}

	start := 0
	i := 0

	for entry in pt.entries {
		if cursor < start + entry.length {
			break
		}

		start += entry.length
		i += 1
	}

	if i < len(pt.entries) {
		if cursor == start {
			pt.entries[i].start += 1
			pt.entries[i].length -= 1

			if (pt.entries[i].length == 0) {
				ordered_remove(&pt.entries, i)
			}
		} else if cursor == start + pt.entries[i].length - 1 {
			pt.entries[i].length -= 1
		} else {
			entry := pt.entries[i]

			pivot := cursor - start

			inject_at(&pt.entries, i+1, PieceTableEntry{
				start = entry.start + pivot + 1,
				length = entry.length - pivot - 1,
				is_original = entry.is_original,
			})

			pt.entries[i].length = pivot
		}
	}
}
