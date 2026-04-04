## Data resource for a single card in the deck.
## Defines the card's type, stats, visuals, and gameplay effect.
class_name CardData
extends Resource

enum CardType { MOVE, SCOUT, GATHER, SETTLE, RESOURCE, ATTACK, DEFENSE, BUFF, DRAW, RECRUIT, BUILD }
enum ResourceType { NONE, FOOD, MATERIALS }

## Display name shown on the card face
@export var card_name: String = ""
## Flavor text describing the card's effect
@export_multiline var description: String = ""
## Determines valid targets and resolution logic
@export var card_type: CardType = CardType.MOVE
## Maximum range for targeting (tiles)
@export var range_value: int = 1
## Action point cost to play
@export var cost: int = 1
## Card face background color and hex highlight color
@export var card_color: Color = Color.WHITE
## Path to the card's icon SVG/PNG
@export var icon_path: String = ""
## Defense modifier cost when played (e.g. Dash costs 1 DEF)
@export var defense_cost: int = 0
## Scale factor for the icon on the card face
@export var icon_scale: float = 1.0
## Resource subtype for RESOURCE cards
@export var resource_type: ResourceType = ResourceType.NONE
## Resource value for RESOURCE cards
@export var resource_value: int = 0
## Override text for the range display in card footer
@export var range_display: String = ""
## Base damage for ATTACK cards
@export var attack_damage: int = 0
## Defense bonus for DEFENSE and BUFF cards
@export var defense_bonus: int = 0
## Attack bonus for BUFF cards (temporary, resets on turn)
@export var attack_bonus: int = 0
## HP bonus for BUFF cards (absorbs damage, resets on turn)
@export var health_bonus: int = 0
## Number of cards to draw for DRAW cards
@export var draw_count: int = 0
## Permanent HP added to target for RECRUIT cards
@export var permanent_hp: int = 0
