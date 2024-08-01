package main

import "core:testing"

@(test)
test_pt_load :: proc(t: ^testing.T) {
	value :: "hello world"
	pt: PieceTable
	pt_init(&pt)
	pt_load(&pt, value)
	testing.expect_value(t, pt_to_string(pt), value)
}

@(test)
test_pt_insert :: proc(t: ^testing.T) {
	pt: PieceTable
	pt_init(&pt)

	pt_insert(&pt, 'x', -1)
	pt_insert(&pt, 'x', 10)
	pt_insert(&pt, 'h', 0)
	pt_insert(&pt, 'o', 1)
	pt_insert(&pt, 'l', 1)
	pt_insert(&pt, 'l', 2)
	pt_insert(&pt, 'e', 1)

	testing.expect_value(t, pt_to_string(pt), "hello")
}

@(test)
test_pt_delete :: proc(t: ^testing.T) {
	pt: PieceTable
	pt_init(&pt)

	value :: "hello"
	pt_load(&pt, value)

	pt_delete(&pt, -1)
	pt_delete(&pt, 5)
	testing.expect_value(t, pt_to_string(pt), value)

	pt_delete(&pt, 0)
	testing.expect_value(t, pt_to_string(pt), "ello")

	pt_delete(&pt, 3)
	testing.expect_value(t, pt_to_string(pt), "ell")

	pt_delete(&pt, 1)
	testing.expect_value(t, pt_to_string(pt), "el")

	pt_delete(&pt, 1)
	testing.expect_value(t, pt_to_string(pt), "e")

	pt_delete(&pt, 0)
	testing.expect_value(t, pt_to_string(pt), "")

	testing.expect_value(t, len(pt.entries), 0)
}
