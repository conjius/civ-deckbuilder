class_name UIHelpers
extends RefCounted

const UI_SCALE: float = 4.0

const CARD_WIDTH: int = int(115 * UI_SCALE)
const CARD_HEIGHT: int = int(165 * UI_SCALE)
const CARD_BORDER: int = int(2 * UI_SCALE)
const CARD_PADDING: int = int(2 * UI_SCALE)
const SECTION_TOP: int = CARD_BORDER + CARD_PADDING
const SECTION_GAP: int = int(2 * UI_SCALE)
const CARD_CORNER_RADIUS: int = int(6 * UI_SCALE)
const SECTION_MARGIN_H: int = int(6 * UI_SCALE)
const SECTION_MARGIN_V: int = int(4 * UI_SCALE)
const CONTENT_WIDTH: int = CARD_WIDTH - SECTION_MARGIN_H * 2

const FONT_TITLE: int = int(13 * UI_SCALE)
const FONT_BODY: int = int(11 * UI_SCALE)
const FONT_SMALL: int = int(10 * UI_SCALE)
const FONT_LABEL: int = int(11 * UI_SCALE)
const FONT_TURN: int = int(14 * UI_SCALE)
const FONT_INFO: int = int(11 * UI_SCALE)
const FONT_UNIT_NAME: int = int(12 * UI_SCALE)
const FONT_UNIT_STAT: int = int(10 * UI_SCALE)

const MARGIN: int = int(10 * UI_SCALE)
const SPACING: int = int(8 * UI_SCALE)
const SPACING_LARGE: int = int(12 * UI_SCALE)
const SPACING_SMALL: int = int(6 * UI_SCALE)

const PANEL_MARGIN_H: int = int(10 * UI_SCALE)
const PANEL_MARGIN_V: int = int(8 * UI_SCALE)
const AVATAR_SIZE: int = int(48 * UI_SCALE)
const BUTTON_SIZE: int = int(40 * UI_SCALE)
const PILE_WIDTH: int = int(120 * UI_SCALE)
const BOTTOM_BAR_HEIGHT: int = int(190 * UI_SCALE)
const LEFT_PANEL_WIDTH: int = int(180 * UI_SCALE)
const LEFT_PANEL_HEIGHT: int = int(200 * UI_SCALE)
const RESOURCE_WIDTH: int = int(150 * UI_SCALE)
const RESOURCE_HEIGHT: int = int(60 * UI_SCALE)
const STACK_OFFSET: int = int(2 * UI_SCALE)

const SETTLEMENT_FONT_SIZE: int = int(48 * UI_SCALE)
const SETTLEMENT_OUTLINE: int = int(8 * UI_SCALE)

const _INNER_H: int = (
	CARD_HEIGHT - SECTION_TOP - CARD_BORDER - CARD_PADDING
)
const HEADER_HEIGHT: int = int(_INNER_H * 0.17)
const AVATAR_HEIGHT: int = int(_INNER_H * 0.34)
const FOOTER_HEIGHT: int = int(_INNER_H * 0.19)
const DESC_HEIGHT: int = (
	_INNER_H
	- HEADER_HEIGHT
	- AVATAR_HEIGHT
	- FOOTER_HEIGHT
	- SECTION_GAP * 3
)


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


static func s(value: int) -> int:
	return int(value * UI_SCALE)


static func sf(value: float) -> float:
	return value * UI_SCALE
