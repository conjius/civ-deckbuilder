class_name UIHelpers
extends RefCounted

const CARD_WIDTH: int = 115
const CARD_HEIGHT: int = 165
const SECTION_GAP: int = 2
const HEADER_HEIGHT: int = 30
const AVATAR_HEIGHT: int = 55
const DESC_HEIGHT: int = 46
const FOOTER_HEIGHT: int = 28
const CONTENT_WIDTH: int = CARD_WIDTH - 12


static func fit_font_size(
	text: String, max_width: int, max_height: int,
	max_size: int = 12, min_size: int = 7,
) -> int:
	var avg_char_w := 0.6
	var line_h_factor := 1.3
	for s in range(max_size, min_size - 1, -1):
		var char_w := s * avg_char_w
		var chars_per_line := int(max_width / char_w)
		if chars_per_line < 1:
			continue
		@warning_ignore("integer_division")
		var lines := (text.length() + chars_per_line - 1) / chars_per_line
		var total_h := lines * s * line_h_factor
		if total_h <= max_height:
			return s
	return min_size
