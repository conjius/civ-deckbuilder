class_name SettlementNames
extends RefCounted

const NAMES: Array[String] = [
	"Aldermoor", "Ashenvale", "Blackthorn", "Briarwood",
	"Cedarfall", "Coppervein", "Dawnsreach", "Dunhollow",
	"Elmsworth", "Everwatch", "Falcrest", "Fernwick",
	"Gladeshire", "Goldmeadow", "Harrowgate", "Hearthstone",
	"Ironhaven", "Ivyreach", "Jade Hollow", "Kingsford",
	"Lakemere", "Larkspur", "Millhaven", "Moonvale",
	"Northwind", "Oakenhold", "Pinecrest", "Quartzridge",
	"Ravenspire", "Redwater", "Silverbrook", "Stonehearth",
	"Thornfield", "Tidewatch", "Umber Falls", "Valewood",
	"Willowmere", "Windhaven", "Wyrmrest", "Yarrow Bluff",
]

static var _used: Array[String] = []


static func get_random_name() -> String:
	var available: Array[String] = []
	for n in NAMES:
		if n not in _used:
			available.append(n)
	if available.is_empty():
		_used.clear()
		available = NAMES.duplicate()
	available.shuffle()
	var name: String = available[0]
	_used.append(name)
	return name
