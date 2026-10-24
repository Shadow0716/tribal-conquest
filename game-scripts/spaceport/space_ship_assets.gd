extends RefCounted
class_name SpaceShipAssets

## Free itch / AssetLib / CC0 ship hulls for first-landing spaceport + full-map sky traffic.
## Prefer incoming junction packs (see internal/incoming-dragons-ships.md).
## Fall back to already-imported unity/flight copies when FBX is not imported yet.

const GRAB3D_HERO := "res://assets/incoming/grab3d-spaceship/spaceship.glb"
const Q_ROOT := "res://assets/incoming/quaternius-ultimate-spaceships/Ultimate Spaceships - May 2021"
const KENNEY_GLTF := "res://assets/incoming/kenney-space-kit/Models/GLTF format"
const UNITY_SHIPS := "res://assets/unity/flight/ships"

const QUATERNIUS_NAMES := [
	"Bob", "Challenger", "Dispatcher", "Executioner", "Imperial",
	"Insurgent", "Omen", "Pancake", "Spitfire", "Striker", "Zenith",
]

const KENNEY_CRAFT := [
	"craft_cargoA.glb", "craft_cargoB.glb", "craft_miner.glb", "craft_racer.glb",
	"craft_speederA.glb", "craft_speederB.glb", "craft_speederC.glb", "craft_speederD.glb",
]

const KENNEY_HANGARS := [
	"hangar_largeA.glb", "hangar_largeB.glb", "hangar_roundA.glb",
	"hangar_smallA.glb", "rocket_baseA.glb",
]

static var _cache: Dictionary = {}


static func first_existing(candidates: Array) -> String:
	for c in candidates:
		var path := str(c)
		if path == "":
			continue
		var lower := path.to_lower()
		if lower.ends_with(".fbx"):
			if ResourceLoader.exists(path):
				return path
			continue
		if ResourceLoader.exists(path) or FileAccess.file_exists(path):
			return path
	return ""


static func sky_fleet_paths() -> Array[String]:
	var out: Array[String] = []
	for name in QUATERNIUS_NAMES:
		var path := first_existing([
			"%s/%s.fbx" % [UNITY_SHIPS, name],
			"%s/%s/FBX/%s.fbx" % [Q_ROOT, name, name],
		])
		if path != "":
			out.append(path)
	for file_name in KENNEY_CRAFT:
		var path := first_existing(["%s/%s" % [KENNEY_GLTF, file_name]])
		if path != "":
			out.append(path)
	var hero := first_existing([GRAB3D_HERO])
	if hero != "":
		out.append(hero)
	if out.is_empty():
		for file_name in ["Spaceship.glb", "Spaceship_b.glb", "Spaceship_c.glb", "Spaceship_d.glb"]:
			var path := "%s/%s" % [UNITY_SHIPS, file_name]
			if ResourceLoader.exists(path) or FileAccess.file_exists(path):
				out.append(path)
	return out


static func berth_paths() -> Array[String]:
	var out: Array[String] = []
	var hero := first_existing([GRAB3D_HERO, "%s/Spaceship.glb" % UNITY_SHIPS])
	if hero != "":
		out.append(hero)
	for file_name in ["craft_cargoA.glb", "craft_cargoB.glb", "craft_miner.glb", "craft_speederA.glb"]:
		var path := first_existing(["%s/%s" % [KENNEY_GLTF, file_name]])
		if path != "":
			out.append(path)
	for name in ["Imperial", "Striker", "Spitfire"]:
		var path := first_existing([
			"%s/%s.fbx" % [UNITY_SHIPS, name],
			"%s/%s/FBX/%s.fbx" % [Q_ROOT, name, name],
		])
		if path != "":
			out.append(path)
	return out


static func hangar_paths() -> Array[String]:
	var out: Array[String] = []
	for file_name in KENNEY_HANGARS:
		var path := first_existing(["%s/%s" % [KENNEY_GLTF, file_name]])
		if path != "":
			out.append(path)
	return out


static func instantiate(path: String) -> Node3D:
	if path == "":
		return null
	var packed := _load_packed(path)
	if packed == null:
		printerr("TC_SHIP_SKIP %s" % path)
		return null
	return packed.instantiate() as Node3D


static func _load_packed(path: String) -> PackedScene:
	if _cache.has(path):
		var cached = _cache[path]
		if cached is PackedScene:
			return cached as PackedScene
		return null
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is PackedScene:
			_cache[path] = res
			return res as PackedScene
	var lower := path.to_lower()
	if lower.ends_with(".glb") or lower.ends_with(".gltf"):
		var abs_path := path
		if path.begins_with("res://"):
			abs_path = ProjectSettings.globalize_path(path)
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		var err := doc.append_from_file(abs_path, state)
		if err == OK:
			var generated := doc.generate_scene(state)
			if generated != null:
				var packed := PackedScene.new()
				if packed.pack(generated) == OK:
					_cache[path] = packed
					generated.queue_free()
					return packed
				generated.queue_free()
		printerr("TC_SHIP_GLTF_FAIL %s err=%s" % [path, err])
	if lower.ends_with(".fbx") and ResourceLoader.exists(path):
		var res2 = load(path)
		if res2 is PackedScene:
			_cache[path] = res2
			return res2 as PackedScene
	_cache[path] = null
	return null