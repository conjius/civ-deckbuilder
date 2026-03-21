extends RefCounted

var _w: int = UIHelpers.CONTENT_WIDTH
var _h: int = UIHelpers.DESC_HEIGHT - UIHelpers.SECTION_MARGIN_V * 2


func test_fit_font_size_short_text_gets_max() -> void:
	var size := UIHelpers.fit_font_size("Move", _w, _h, 11, 7)
	TestAssert.assert_eq(size, 11)


func test_fit_font_size_long_text_shrinks() -> void:
	var long_text := "Gather resources from an adjacent tile and add them to your stockpile for later use in construction"
	var max_s := UIHelpers.FONT_BODY
	var min_s := UIHelpers.s(7)
	var size := UIHelpers.fit_font_size(long_text, _w, _h, max_s, min_s)
	TestAssert.assert_true(size < max_s, "should shrink below max")
	TestAssert.assert_true(size >= min_s, "should not go below min")


func test_fit_font_size_empty_gets_max() -> void:
	var size := UIHelpers.fit_font_size("", _w, _h, 12, 7)
	TestAssert.assert_eq(size, 12)


func test_fit_font_size_respects_min() -> void:
	var huge := "a".repeat(500)
	var size := UIHelpers.fit_font_size(huge, _w, _h, 12, 8)
	TestAssert.assert_eq(size, 8)


func test_card_constants_add_up() -> void:
	var total := UIHelpers.HEADER_HEIGHT
	total += UIHelpers.AVATAR_HEIGHT
	total += UIHelpers.DESC_HEIGHT
	total += UIHelpers.FOOTER_HEIGHT
	total += UIHelpers.SECTION_GAP * 3
	TestAssert.assert_eq(total, UIHelpers.CONTAINER_H)
