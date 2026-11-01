extends Node

# Roguelike meta progression: Xenite shards collected in a run are banked when it ends
# (won or lost) and spent in the Hangar on permanent stat upgrades.
# Everything is kept per level - every new level starts from zero.

const SALVAGE_PER_MINUTE = 2
const VICTORY_SHARDS = 30

const ICONS = "res://resources/perks/"

# cost of the next rank = base_cost * (rank + 1)
const UPGRADES = [
	{ "id" : "hull", "icon" : ICONS + "icon_hull.png", "name" : "Reinforced Hull", "desc" : "Max life +10", "per_rank" : 10.0, "max_rank" : 5, "base_cost" : 15 },
	{ "id" : "shield", "icon" : ICONS + "icon_shield.png", "name" : "Shield Capacitor", "desc" : "Max shield +10", "per_rank" : 10.0, "max_rank" : 5, "base_cost" : 15 },
	{ "id" : "damage", "icon" : ICONS + "icon_damage.png", "name" : "Plasma Coils", "desc" : "Damage +5%", "per_rank" : 5.0, "max_rank" : 5, "base_cost" : 20 },
	{ "id" : "fire_rate", "icon" : ICONS + "icon_overclock.png", "name" : "Cooling Vents", "desc" : "Fire rate +4%", "per_rank" : 4.0, "max_rank" : 5, "base_cost" : 20 },
	{ "id" : "speed", "icon" : ICONS + "icon_thrusters.png", "name" : "Ion Thrusters", "desc" : "Speed +4%", "per_rank" : 4.0, "max_rank" : 4, "base_cost" : 15 },
	{ "id" : "armor", "icon" : ICONS + "icon_armor.png", "name" : "Ablative Plating", "desc" : "Armor +1", "per_rank" : 1.0, "max_rank" : 3, "base_cost" : 30 },
	{ "id" : "regen", "icon" : ICONS + "icon_nanobots.png", "name" : "Repair Nanites", "desc" : "Regen +0.4 life/s", "per_rank" : 0.4, "max_rank" : 3, "base_cost" : 30 },
	{ "id" : "crit", "icon" : ICONS + "icon_precision.png", "name" : "Targeting AI", "desc" : "Critical chance +2%", "per_rank" : 2.0, "max_rank" : 4, "base_cost" : 20 },
	{ "id" : "magnet", "icon" : ICONS + "icon_tractor.png", "name" : "Tractor Beam", "desc" : "Pickup radius +20", "per_rank" : 20.0, "max_rank" : 3, "base_cost" : 10 },
	{ "id" : "salvage", "icon" : ICONS + "icon_xenite_scanner.png", "name" : "Xenite Scanner", "desc" : "Shard drop chance +15%", "per_rank" : 15.0, "max_rank" : 3, "base_cost" : 25 },
]

signal changed(level : int)

# shard drop chance multiplier of the running level, set by apply()
var _shard_chance_factor : float = 1.0

func _get_meta(level : int) -> Dictionary:
	var data = ConfigHandler.get_level_meta(level)
	for key in ["shards", "deaths", "runs"]:
		if !data.has(key):
			data[key] = 0
	if !data.has("upgrades"):
		data["upgrades"] = {}
	return data

func _find(id : String) -> Dictionary:
	for upgrade in UPGRADES:
		if upgrade["id"] == id:
			return upgrade
	return {}

# public
func get_shards(level : int) -> int:
	return _get_meta(level)["shards"]

# public
func get_deaths(level : int) -> int:
	return _get_meta(level)["deaths"]

# public
func get_runs(level : int) -> int:
	return _get_meta(level)["runs"]

# public
func get_rank(level : int, id : String) -> int:
	return _get_meta(level)["upgrades"].get(id, 0)

# public - -1 when maxed
func get_cost(level : int, id : String) -> int:
	var upgrade = _find(id)
	var rank = get_rank(level, id)
	if rank >= upgrade["max_rank"]:
		return -1
	return upgrade["base_cost"] * (rank + 1)

# public
func can_buy(level : int, id : String) -> bool:
	var cost = get_cost(level, id)
	return cost > 0 and get_shards(level) >= cost

# public
func buy(level : int, id : String) -> bool:
	if !can_buy(level, id):
		return false
	var data = _get_meta(level)
	data["shards"] -= get_cost(level, id)
	data["upgrades"][id] = data["upgrades"].get(id, 0) + 1
	ConfigHandler.save_level_meta(level, data)
	changed.emit(level)
	return true

# public - dev console
func add_shards(level : int, value : int):
	var data = _get_meta(level)
	data["shards"] = max(data["shards"] + value, 0)
	ConfigHandler.save_level_meta(level, data)
	changed.emit(level)

# public - called after PlayerStatus.reset(), before the world loads
func apply(level : int):
	var bonus = func(id): return get_rank(level, id) * _find(id)["per_rank"]
	PlayerStatus.MaxLife += bonus.call("hull")
	PlayerStatus.MaxShield += bonus.call("shield")
	PlayerStatus.BaseDamage += bonus.call("damage")
	PlayerStatus.FireRate += bonus.call("fire_rate")
	PlayerStatus.Speed += bonus.call("speed")
	PlayerStatus.Armor += bonus.call("armor")
	PlayerStatus.Regen += bonus.call("regen")
	PlayerStatus.CriticalHitChance += bonus.call("crit")
	PlayerStatus.PickupRadius += bonus.call("magnet")
	_shard_chance_factor = 1.0 + 0.01 * bonus.call("salvage")

# public
func get_shard_chance_factor() -> float:
	return _shard_chance_factor

# public - shards for surviving, so even an unlucky death pays something
func get_salvage(seconds : float, victory : bool) -> int:
	return int(seconds / 60.0) * SALVAGE_PER_MINUTE + (VICTORY_SHARDS if victory else 0)

# public - banks the shards of the finished run, returns the new balance
func finish_run(level : int, shards : int, died : bool) -> int:
	var data = _get_meta(level)
	data["shards"] += shards
	data["runs"] += 1
	if died:
		data["deaths"] += 1
	ConfigHandler.save_level_meta(level, data)
	changed.emit(level)
	return data["shards"]
