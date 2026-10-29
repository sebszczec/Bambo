extends CanvasLayer

# Developer console (debug builds only): ` / ~ slides it down from the top of the screen.
# The game is paused while it is open, so you can type in the middle of a fight.
# Type `help` for the commands; Tab completes, Up / Down walk the history, Esc or ` closes it.
# Created by game_logic, which it uses to spawn enemies, bosses and give upgrades.

const HEIGHT = 0.45  # share of the screen the open console covers
const SLIDE_TIME = 0.2
const FONT_SIZE = 18
const MAX_HISTORY = 50
const C_NAME = "ffd633"
const C_VALUE = "ffffff"
const C_DIM = "8090b0"
const C_ERR = "ff5a4a"
const C_OK = "9fd67a"

const COMMANDS = ["help", "clear", "spawn", "boss", "hurtboss", "killall", "god", "heal",
	"xp", "levelup", "chest", "give", "upgrades", "stat", "skip", "endless", "perk"]

const ENEMY_NAMES = {
	"scout" : Enums.ENEMIES.SCOUT,
	"guard" : Enums.ENEMIES.GUARD,
	"hunter" : Enums.ENEMIES.HUNTER,
	"boss" : Enums.ENEMIES.BOSS,
	"worm" : Enums.ENEMIES.WORM_BOSS,
}

const PERK_NAMES = {
	"life" : Enums.PERKS.LIFE,
	"shield" : Enums.PERKS.SHIELD,
	"magnet" : Enums.PERKS.MAGNET,
	"bomb" : Enums.PERKS.BOMB,
}

var game = null  # game_logic

var _output : RichTextLabel
var _line : LineEdit
var _panel : PanelContainer
var _open = false
var _was_paused = false
var _tween : Tween
var _history : Array[String] = []
var _hist_pos = 0
var _completions : Array[String] = []
var _completion_i = -1

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	var view = get_viewport().get_visible_rect().size
	var font = SystemFont.new()
	font.font_names = PackedStringArray(["Consolas", "DejaVu Sans Mono", "Courier New", "monospace"])

	_panel = PanelContainer.new()
	var box = MenuTheme.box(Color(0.02, 0.03, 0.1, 0.95), MenuTheme.BORDER_COLOR)
	box.set_corner_radius_all(0)
	box.border_width_top = 0
	box.border_width_left = 0
	box.border_width_right = 0
	box.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", box)
	_panel.size = Vector2(view.x, view.y * HEIGHT)
	_panel.position = Vector2(0, -_panel.size.y)
	_panel.visible = false
	add_child(_panel)

	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_panel.add_child(v)

	_output = RichTextLabel.new()
	_output.bbcode_enabled = true
	_output.scroll_following = true
	_output.selection_enabled = true
	_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_output.focus_mode = Control.FOCUS_NONE
	_output.add_theme_font_override("normal_font", font)
	_output.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	_output.add_theme_color_override("default_color", MenuTheme.TEXT_COLOR)
	v.add_child(_output)

	var row = HBoxContainer.new()
	var prompt = Label.new()
	prompt.text = ">"
	prompt.add_theme_font_override("font", font)
	prompt.add_theme_font_size_override("font_size", FONT_SIZE)
	prompt.add_theme_color_override("font_color", MenuTheme.ACCENT_COLOR)
	row.add_child(prompt)
	_line = LineEdit.new()
	_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_line.add_theme_font_override("font", font)
	_line.add_theme_font_size_override("font_size", FONT_SIZE)
	_line.placeholder_text = "help, spawn worm, god, give orbit 3 ..."
	_line.keep_editing_on_text_submit = true
	_line.text_submitted.connect(_submit)
	_line.text_changed.connect(func(_t): _completion_i = -1)
	row.add_child(_line)
	v.add_child(row)

	_print("[color=#%s]Console[/color]: [color=#%s]help[/color] lists the commands, Tab completes, ` closes. The game is paused while it is open." % [C_NAME, C_NAME])

# public
func is_open() -> bool:
	return _open

func _open_console():
	if _open:
		return
	_open = true
	# the pause menu / level up menu may have paused the game already, restore that on close
	_was_paused = get_tree().paused
	get_tree().paused = true
	_panel.visible = true
	_slide(0.0, Tween.EASE_OUT)
	_line.grab_focus()

func _close_console():
	if !_open:
		return
	_open = false
	_line.release_focus()
	get_tree().paused = _was_paused
	_slide(-_panel.size.y, Tween.EASE_IN).finished.connect(func(): _panel.visible = _open)

func _slide(y : float, ease_kind : Tween.EaseType) -> Tween:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_panel, "position:y", y, SLIDE_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(ease_kind)
	return _tween

func _input(event: InputEvent) -> void:
	var key = event as InputEventKey
	if key == null or !key.pressed:
		return
	if _is_toggle_key(key) and !key.echo:
		if _open:
			_close_console()
		else:
			_open_console()
		get_viewport().set_input_as_handled()
		return
	if !_open:
		return
	match key.keycode:
		KEY_ESCAPE:
			_close_console()
		KEY_UP:
			_walk_history(-1)
		KEY_DOWN:
			_walk_history(1)
		KEY_TAB:
			_complete()
		KEY_PAGEUP:
			_output.get_v_scroll_bar().value -= _output.size.y * 0.8
		KEY_PAGEDOWN:
			_output.get_v_scroll_bar().value += _output.size.y * 0.8
		_:
			return
	get_viewport().set_input_as_handled()

static func _is_toggle_key(key : InputEventKey) -> bool:
	return key.physical_keycode == KEY_QUOTELEFT or key.keycode == KEY_QUOTELEFT \
			or key.keycode == KEY_ASCIITILDE or key.unicode == 96 or key.unicode == 126

func _submit(text : String):
	_line.clear()
	var line = text.strip_edges()
	if line == "":
		return
	if _history.is_empty() or _history[-1] != line:
		_history.append(line)
		if _history.size() > MAX_HISTORY:
			_history.pop_front()
	_hist_pos = _history.size()
	_print("[color=#%s]> %s[/color]" % [C_DIM, _esc(line)])
	var out = run(line)
	if out != "":
		_print(out)

func _print(bb : String):
	_output.append_text(bb + "\n")

func _walk_history(d : int):
	if _history.is_empty():
		return
	_hist_pos = clampi(_hist_pos + d, 0, _history.size())
	_line.text = _history[_hist_pos] if _hist_pos < _history.size() else ""
	_line.caret_column = _line.text.length()

# Tab completes the word under the caret, pressing it again cycles through the matches
func _complete():
	var text = _line.text
	var start = text.rfind(" ") + 1
	if _completion_i < 0:
		_completions = _completions_for(text.substr(0, start).strip_edges(), text.substr(start).to_lower())
		if _completions.size() > 1:
			_print("[color=#%s]%s[/color]" % [C_DIM, "  ".join(_completions)])
	if _completions.is_empty():
		return
	_completion_i = (_completion_i + 1) % _completions.size()
	_line.text = text.substr(0, start) + _completions[_completion_i]
	_line.caret_column = _line.text.length()  # setting text doesn't emit text_changed: the cycle goes on

func _completions_for(before : String, prefix : String) -> Array[String]:
	var words : Array = []
	match before.to_lower():
		"":
			words = COMMANDS
		"spawn":
			words = ENEMY_NAMES.keys()
		"boss":
			words = ["boss", "worm"]
		"perk":
			words = PERK_NAMES.keys()
		"god":
			words = ["on", "off"]
		"give":
			words = _upgrade_names()
		"stat":
			words = _stat_names()
	var out : Array[String] = []
	for w in words:
		if w.to_lower().begins_with(prefix):
			out.append(w)
	return out

# ------------------------------------------------------------------ commands

# public - runs one command line and returns what to print (BBCode)
func run(line : String) -> String:
	var words = line.strip_edges().split(" ", false)
	if words.is_empty():
		return ""
	var cmd = words[0].to_lower()
	var args = words.slice(1)
	var n = args[1].to_int() if args.size() > 1 and args[1].is_valid_int() else 1
	match cmd:
		"help", "?":
			return _help()
		"clear", "cls":
			_output.clear()
			return ""
		"spawn":
			return _spawn(args[0].to_lower() if args.size() > 0 else "", n)
		"boss":
			return _spawn(args[0].to_lower() if args.size() > 0 else "worm", 1)
		"hurtboss":
			return _hurt_boss(args[0].to_float() if args.size() > 0 and args[0].is_valid_float() else 50.0)
		"killall":
			return _ok("%d enemies killed" % game.kill_all_enemies())
		"god":
			return _god(args[0].to_lower() if args.size() > 0 else "")
		"heal":
			game.player.updateLife(PlayerStatus.MaxLife)
			game.player.updateShield(PlayerStatus.MaxShield)
			return _ok("healed")
		"xp":
			if args.is_empty() or !args[0].is_valid_int():
				return _err("xp <n>")
			PlayerStatus.add_xp(args[0].to_int())
			return _ok("+%s xp: level %d" % [args[0], PlayerStatus.Level])
		"levelup":
			var count = args[0].to_int() if args.size() > 0 and args[0].is_valid_int() else 1
			for i in range(count):
				PlayerStatus.add_xp(PlayerStatus.XpToNext - PlayerStatus.Xp)
			return _ok("level %d (close the console to pick)" % PlayerStatus.Level)
		"chest":
			game.levelUpMenu.queue_chest()
			return _ok("supply crate queued (close the console to pick)")
		"give":
			return _give(args[0].to_lower() if args.size() > 0 else "", n)
		"upgrades":
			return _list_upgrades()
		"stat", "stats":
			if args.size() < 2:
				return _list_stats(args[0] if args.size() > 0 else "")
			return _set_stat(args[0], args[1])
		"skip":
			if args.is_empty() or !args[0].is_valid_float():
				return _err("skip <seconds>")
			game.phase_guard.skip_time(args[0].to_float())
			return _ok("clock jumped to %s" % game.phase_guard.get_time_text())
		"endless":
			game.phase_guard.start_endless()
			return _ok("endless mode started")
		"perk":
			return _perk(args[0].to_lower() if args.size() > 0 else "")
	return _err("unknown command '%s' (try help)" % _esc(words[0]))

func _help() -> String:
	var lines = [
		"[color=#%s]Commands[/color]" % C_NAME,
		"  spawn <%s> [n]   n enemies just off screen" % "|".join(ENEMY_NAMES.keys()),
		"  boss [boss|worm]       a boss with its boss bar (default worm)",
		"  hurtboss [percent]     takes that share of the boss's max life (default 50, worm enrages below 50)",
		"  killall                every enemy dies (bosses too, with their rewards)",
		"  god [on|off]           no damage taken (no argument: toggle)",
		"  heal                   full life and shield",
		"  xp <n>    levelup [n]  chest     experience, level ups, a supply crate",
		"  give <upgrade> [n]     takes an upgrade n times (up to its max level), see upgrades",
		"  upgrades               the upgrade names and their levels",
		"  stat [name] [value]    PlayerStatus values: list, show or set",
		"  skip <seconds>         jumps the run clock (600 = boss)    endless   starts endless mode",
		"  perk <%s>   drops that pickup on you" % "|".join(PERK_NAMES.keys()),
		"  clear",
	]
	return "\n".join(lines)

func _spawn(enemy_name : String, count : int) -> String:
	if !ENEMY_NAMES.has(enemy_name):
		return _err("spawn %s [n]" % "|".join(ENEMY_NAMES.keys()))
	var type = ENEMY_NAMES[enemy_name]
	if type == Enums.ENEMIES.BOSS or type == Enums.ENEMIES.WORM_BOSS:
		if game.boss != null:
			return _err("a boss is already here (killall or hurtboss 100 first)")
		game.spawn_boss(type)
		return _ok("%s spawned" % enemy_name)
	for i in range(maxi(count, 1)):
		game.spawn_enemy(type, game.get_spawn_position())
	return _ok("%d %s spawned" % [maxi(count, 1), enemy_name])

func _hurt_boss(percent : float) -> String:
	if game.boss == null:
		return _err("no boss here (boss worm)")
	game.hurt_boss(percent)
	return _ok("boss life %d" % maxi(game.boss.Life, 0) if game.boss != null else "boss killed")

func _god(arg : String) -> String:
	match arg:
		"":
			game.player.godMode = !game.player.godMode
		"on", "1", "true":
			game.player.godMode = true
		"off", "0", "false":
			game.player.godMode = false
		_:
			return _err("god [on|off]")
	return _ok("god mode %s" % ("on" if game.player.godMode else "off"))

func _upgrade_names() -> Array:
	var names = []
	for entry in Upgrades.get_pool():
		names.append(entry["id"].trim_prefix("w_"))
	return names

func _give(upgrade_name : String, count : int) -> String:
	var entry = Upgrades.get_entry(upgrade_name)
	if entry.is_empty():
		entry = Upgrades.get_entry("w_" + upgrade_name)
	if entry.is_empty():
		return _err("give <upgrade> [n]: %s" % " ".join(_upgrade_names()))
	var taken = 0
	for i in range(maxi(count, 1)):
		if Upgrades.get_level(entry["id"]) >= entry["max_level"]:
			break
		Upgrades.choose(entry)
		taken += 1
	return _ok("%s level %d/%d (+%d)" % [entry["title"], Upgrades.get_level(entry["id"]), entry["max_level"], taken])

func _list_upgrades() -> String:
	var lines = ["[color=#%s]Upgrades[/color] (give <name> [n])" % C_NAME]
	for entry in Upgrades.get_pool():
		lines.append("  [color=#%s]%-12s[/color] %d/%d  [color=#%s]%s%s[/color]" % [
			C_NAME, entry["id"].trim_prefix("w_"), Upgrades.get_level(entry["id"]), entry["max_level"],
			C_DIM, "weapon: " if entry["weapon"] else "", entry["desc"]])
	return "\n".join(lines)

func _stat_names() -> Array:
	var names = []
	for p in PlayerStatus.get_property_list():
		if p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE and (p["type"] == TYPE_FLOAT or p["type"] == TYPE_INT):
			names.append(p["name"])
	return names

func _find_stat(stat_name : String) -> String:
	for s in _stat_names():
		if s.to_lower() == stat_name.to_lower():
			return s
	return ""

func _list_stats(filter : String) -> String:
	var lines = []
	for s in _stat_names():
		if filter == "" or s.to_lower().contains(filter.to_lower()):
			lines.append("  [color=#%s]%s[/color] = [color=#%s]%s[/color]" % [C_NAME, s, C_VALUE, str(PlayerStatus.get(s))])
	if lines.is_empty():
		return _err("no stat '%s'" % _esc(filter))
	return "\n".join(lines)

func _set_stat(stat_name : String, text : String) -> String:
	var s = _find_stat(stat_name)
	if s == "":
		return _err("no stat '%s' (stat lists them)" % _esc(stat_name))
	if !text.is_valid_float():
		return _err("'%s' is not a number" % _esc(text))
	var old = PlayerStatus.get(s)
	var value = text.to_float()
	# these have signals the bars listen to
	match s:
		"MaxLife":
			PlayerStatus.increase_max_life(value - old)
		"MaxShield":
			PlayerStatus.increase_max_shield(value - old)
		"BaseDamage":
			PlayerStatus.increase_damage(value - old)
		"Speed":
			PlayerStatus.increase_speed(value - old)
		_:
			PlayerStatus.set(s, int(value) if typeof(old) == TYPE_INT else value)
	return "[color=#%s]%s[/color] = [color=#%s]%s[/color]  [color=#%s](was %s)[/color]" % [
		C_NAME, s, C_VALUE, str(PlayerStatus.get(s)), C_DIM, str(old)]

func _perk(perk_name : String) -> String:
	if !PERK_NAMES.has(perk_name):
		return _err("perk %s" % "|".join(PERK_NAMES.keys()))
	game.drop_perk(PERK_NAMES[perk_name], game.player.global_position + Vector2(80, 0))
	return _ok("%s dropped beside you" % perk_name)

static func _ok(msg : String) -> String:
	return "[color=#%s]%s[/color]" % [C_OK, msg]

static func _err(msg : String) -> String:
	return "[color=#%s]%s[/color]" % [C_ERR, msg]

static func _esc(s : String) -> String:
	return s.replace("[", "[lb]")
