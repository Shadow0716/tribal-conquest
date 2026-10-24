extends RefCounted
class_name TCNpcCastCatalog

## TC-54: resolve distinct HD NPC meshes per biome/role from free packs on disk.
## Johnny hard rule: NO INDIANS — reject Indian/Native American names, meshes, costumes, theming.
## Spawns MUST use world._spawn_npc (owns _seat_actor + _plant_actor).
## Never invent a second bury / plant path. Do not touch grass/road collision.
## Prefer source placement paths (Grab3D / outfits / space / undead) over plant-lock collapses.

const GRAB := "res://assets/grab3d/%s_rigged.glb"
const Q := "res://assets/quaternius/"
const SPACE := "res://assets/unity/flight/space/"
const UNITY := "res://assets/unity/characters/"
const KAY_SKEL := "res://assets/kaykit/skeletons/"
const KENNEY_ASTRO := "res://assets/incoming/kenney-space-kit/Models/GLTF format/"

const SUPER_M := Q + "Superhero_Male_FullBody.gltf"
const SUPER_F := Q + "Superhero_Female_FullBody.gltf"
const MALE_BODY := UNITY + "MaleBody.fbx"
const MALE_ARMOR := UNITY + "MaleArmor.fbx"
const FEM_A03 := UNITY + "A03.FBX"
const DEFENDER := UNITY + "defender/Defender.glb"
const ROLAND := Q + "roland/Knight_Roland.glb"
const KNIGHT_FBX := Q + "animated-knight/KnightCharacter.fbx"
const BLAKE := "res://assets/incoming/blake/Blake.glb"
const SKELETON := "res://assets/skeleton-greyfrog/skeleton.glb"
const ZOMBIE := UNITY + "zombie/model/fury.FBX"
const HARLOCK := "res://assets/incoming/space_pirate_captain_harlock.glb"
const OUTFIT_MR := Q + "outfits/Male_Ranger.gltf"
const OUTFIT_FR := Q + "outfits/Female_Ranger.gltf"
const OUTFIT_MP := Q + "outfits/Male_Peasant.gltf"
const OUTFIT_FP := Q + "outfits/Female_Peasant.gltf"
const Q_KNIGHT := "res://assets/cc0/characters/QuaterniusKnight.glb"
const DRAGON_KNIGHT := "res://assets/incoming/dragon_knight/scene.gltf"
const SKEL_WARRIOR := KAY_SKEL + "Skeleton_Warrior.glb"
const SKEL_MAGE := KAY_SKEL + "Skeleton_Mage.glb"
const SKEL_ROGUE := KAY_SKEL + "Skeleton_Rogue.glb"
const SKEL_MINION := KAY_SKEL + "Skeleton_Minion.glb"
const ASTRO_A := KENNEY_ASTRO + "astronautA.glb"
const ASTRO_B := KENNEY_ASTRO + "astronautB.glb"


static func exists(path: String) -> bool:
	return path != "" and (ResourceLoader.exists(path) or FileAccess.file_exists(path))


static func first_existing(paths: Array) -> String:
	for p in paths:
		var s := str(p)
		if exists(s):
			return s
	# Last ditch drawables (already imported in prior exports).
	if exists(MALE_BODY):
		return MALE_BODY
	return SUPER_M


static func grab_path(role: String) -> String:
	var key := str(role).strip_edges().to_lower().replace(" ", "-").replace("_", "-")
	return GRAB % key


static func grab(role: String) -> String:
	## Prefer Grab3D CC0 role GLBs on disk (suited cast). Seat/plant only via _spawn_npc.
	## Fallbacks: Defender / outfits / MaleBody — never invent a second plant path.
	var key := str(role).strip_edges().to_lower().replace(" ", "-").replace("_", "-")
	var fem := key in ["woman", "female", "lady"] or "woman" in key or "female" in key
	var primary := grab_path(key)
	if fem:
		return first_existing([primary, OUTFIT_FP, OUTFIT_FR, FEM_A03, SUPER_F, MALE_BODY])
	match key:
		"armored-knight", "soldier", "samurai":
			return first_existing([primary, DEFENDER, MALE_ARMOR, MALE_BODY])
		"wizard":
			return first_existing([primary, OUTFIT_MR, MALE_BODY])
		"sci-fi-soldier":
			return first_existing([primary, SPACE + "Astronaut.glb", DEFENDER, MALE_BODY])
		"businessman", "chef", "farmer", "man", "elderly-man", "viking":
			return first_existing([primary, OUTFIT_MP, MALE_BODY])
		_:
			return first_existing([primary, OUTFIT_MP if not fem else OUTFIT_FP, MALE_BODY])


static func mesh(key: String) -> String:
	## Named mesh keys for data/npc/casts.json + Grab3D role names.
	if _banned_theme(key):
		printerr("TC_NPC_BAN mesh_key=%s" % key)
		return first_existing([MALE_BODY, DEFENDER])
	var k := str(key).strip_edges().to_lower().replace(" ", "_").replace("-", "_")
	match k:
		"superhero_m", "super_m", "peasant_m", "peasant_m":
			return first_existing([OUTFIT_MP, SUPER_M, MALE_BODY])
		"superhero_f", "super_f", "peasant_f", "peasant_f":
			return first_existing([OUTFIT_FP, SUPER_F, FEM_A03, MALE_BODY])
		"male_ranger", "male-ranger":
			return first_existing([OUTFIT_MR, grab_path("soldier"), DEFENDER, MALE_BODY])
		"female_ranger", "female-ranger":
			return first_existing([OUTFIT_FR, grab_path("woman"), FEM_A03, MALE_BODY])
		"male_peasant", "male-peasant":
			return first_existing([OUTFIT_MP, grab_path("man"), MALE_BODY])
		"female_peasant", "female-peasant":
			return first_existing([OUTFIT_FP, grab_path("woman"), FEM_A03, MALE_BODY])
		"defender", "knight", "animated_knight", "animated-knight":
			return first_existing([DEFENDER, ROLAND, KNIGHT_FBX, grab_path("armored-knight"), MALE_ARMOR, MALE_BODY])
		"roland":
			return first_existing([ROLAND, DEFENDER, KNIGHT_FBX, grab_path("armored-knight"), MALE_ARMOR, MALE_BODY])
		"quaternius_knight", "q_knight":
			return first_existing([Q_KNIGHT, ROLAND, DEFENDER, grab_path("armored-knight"), MALE_BODY])
		"dragon_knight":
			return first_existing([DRAGON_KNIGHT, ROLAND, DEFENDER, grab_path("armored-knight"), MALE_BODY])
		"blake":
			return first_existing([BLAKE, OUTFIT_MR, grab_path("soldier"), MALE_BODY])
		"skeleton":
			return first_existing([SKELETON, ZOMBIE, grab_path("wizard"), MALE_BODY])
		"skel_warrior", "skeleton_warrior":
			return first_existing([SKEL_WARRIOR, SKELETON, ZOMBIE, grab_path("armored-knight"), MALE_BODY])
		"skel_mage", "skeleton_mage":
			return first_existing([SKEL_MAGE, SKELETON, grab_path("wizard"), MALE_BODY])
		"skel_rogue", "skeleton_rogue":
			return first_existing([SKEL_ROGUE, SKELETON, ZOMBIE, grab_path("soldier"), MALE_BODY])
		"skel_minion", "skeleton_minion":
			return first_existing([SKEL_MINION, SKELETON, ZOMBIE, MALE_BODY])
		"zombie", "fury":
			return first_existing([ZOMBIE, SKELETON, SKEL_MINION, MALE_BODY])
		"harlock", "pirate_captain", "pirate-captain":
			return first_existing([HARLOCK, grab_path("viking"), grab_path("soldier"), MALE_BODY])
		"astronaut":
			return first_existing([SPACE + "Astronaut.glb", grab_path("sci-fi-soldier"), MALE_BODY])
		"astronaut_b", "astronaut-b":
			return first_existing([SPACE + "Astronaut_b.glb", SPACE + "Astronaut.glb", grab_path("sci-fi-soldier"), MALE_BODY])
		"astronaut_c", "astronaut-c":
			return first_existing([SPACE + "Astronaut_c.glb", SPACE + "Astronaut.glb", grab_path("sci-fi-soldier"), MALE_BODY])
		"kenney_astro_a", "astro_a":
			return first_existing([ASTRO_A, SPACE + "Astronaut.glb", grab_path("sci-fi-soldier"), MALE_BODY])
		"kenney_astro_b", "astro_b":
			return first_existing([ASTRO_B, SPACE + "Astronaut_b.glb", grab_path("sci-fi-soldier"), MALE_BODY])
		"stan":
			return first_existing([SPACE + "Stan.fbx", SPACE + "Astronaut_b.glb", grab_path("sci-fi-soldier"), MALE_BODY])
		"mike":
			return first_existing([SPACE + "Mike.fbx", SPACE + "Astronaut_c.glb", grab_path("sci-fi-soldier"), MALE_BODY])
		"leela":
			return first_existing([SPACE + "Leela.fbx", OUTFIT_FR, SUPER_F, FEM_A03, MALE_BODY])
		_:
			return grab(k)


static func town_lineup() -> Array:
	## Distinct civic types for town proof / plaza framing (one mesh each).
	return [
		{"name": "Town Guard", "mesh": "armored-knight"},
		{"name": "Gate Guard", "mesh": "soldier"},
		{"name": "Knight Captain", "mesh": "roland"},
		{"name": "Banker", "mesh": "businessman"},
		{"name": "Innkeeper", "mesh": "chef"},
		{"name": "Blacksmith", "mesh": "farmer"},
		{"name": "Market Vendor", "mesh": "male_peasant"},
		{"name": "Noble", "mesh": "viking"},
		{"name": "Court Mage", "mesh": "wizard"},
		{"name": "Elder", "mesh": "elderly-man"},
		{"name": "Townsman", "mesh": "man"},
		{"name": "Townswoman", "mesh": "woman"},
		{"name": "Armorer", "mesh": "female_ranger"},
		{"name": "Samurai Retainer", "mesh": "samurai"},
		{"name": "Weaponsmith", "mesh": "defender"},
		{"name": "Guild Clerk", "mesh": "female_peasant"},
		{"name": "Stable Hand", "mesh": "male_peasant"},
		{"name": "City Champion", "mesh": "dragon_knight"},
	]


static func harbor_lineup() -> Array:
	## Pirate pack folder empty on disk → Harlock + Grab3D viking/soldier interim.
	return [
		{"name": "Dock Worker", "mesh": "man"},
		{"name": "Harbor Sailor", "mesh": "viking"},
		{"name": "Pirate Deckhand", "mesh": "soldier"},
		{"name": "Pirate Captain", "mesh": "harlock"},
		{"name": "Quartermaster", "mesh": "businessman"},
		{"name": "Shipwright", "mesh": "farmer"},
		{"name": "Fisher", "mesh": "elderly-man"},
		{"name": "Port Warden", "mesh": "sci-fi-soldier"},
		{"name": "Net Weaver", "mesh": "woman"},
		{"name": "Cargo Clerk", "mesh": "male_peasant"},
	]


static func wilds_lineup() -> Array:
	return [
		{"name": "Hunter", "mesh": "male_ranger"},
		{"name": "Scout", "mesh": "female_ranger"},
		{"name": "Traveler", "mesh": "blake"},
		{"name": "Road Patrol", "mesh": "soldier"},
		{"name": "Ranger Guide", "mesh": "defender"},
		{"name": "Wilds Guard", "mesh": "armored-knight"},
		{"name": "Woodsman", "mesh": "farmer"},
		{"name": "Caravan Trader", "mesh": "businessman"},
		{"name": "Forest Hermit", "mesh": "elderly-man"},
		{"name": "Trail Runner", "mesh": "male_peasant"},
	]


static func crypt_lineup() -> Array:
	## Undead theme within crypt; distinct meshes between stalker/walker/minion/mage.
	return [
		{"name": "Crypt Stalker", "mesh": "skel_rogue"},
		{"name": "Bone Walker", "mesh": "skeleton"},
		{"name": "Ash Minion", "mesh": "skel_minion"},
		{"name": "Bone Mage", "mesh": "skel_mage"},
		{"name": "Bone Warrior", "mesh": "skel_warrior"},
		{"name": "Tomb Warden", "mesh": "wizard"},
		{"name": "Relic Broker", "mesh": "businessman"},
		{"name": "Ash Guard", "mesh": "armored-knight"},
		{"name": "Crypt Fury", "mesh": "zombie"},
	]



## Johnny hard ban — Indian / Native American theming.
static func _banned_theme(text: String) -> bool:
	var t := text.to_lower().replace("-", " ").replace("_", " ")
	var keys := [
		"indian", "indians", "native american", "first nations", "apache", "cherokee",
		"navajo", "sioux", "comanche", "hopi", "inuit", "eskimo", "aztec", "mayan",
		"inca", "hindu", "sikh", "bollywood", "sari", "turban", "teepee", "tipi", "wigwam",
		"tomahawk", "headdress", "war bonnet", "moccasin", "powwow", "totem pole",
		"tribal indian",
	]
	for k in keys:
		if t.find(k) >= 0:
			return true
	return false

static func space_lineup() -> Array:
	var raw: Array = [
		{"name": "Landing Marshal", "mesh": "astronaut"},
		{"name": "Pad Technician", "mesh": "astronaut_b"},
		{"name": "Orbital Customs", "mesh": "astronaut_c"},
		{"name": "Suit Mechanic", "mesh": "sci-fi-soldier"},
		{"name": "Dock Astrotech", "mesh": "stan"},
		{"name": "Port Warden", "mesh": "kenney_astro_a"},
		{"name": "Hangar Lead", "mesh": "mike"},
		{"name": "Flight Officer", "mesh": "leela"},
		{"name": "Berth Hand", "mesh": "kenney_astro_b"},
	]
	var out: Array = []
	for row in raw:
		var nm := str(row.get("name", ""))
		var mesh_id := str(row.get("mesh", ""))
		if _banned_theme(nm) or _banned_theme(mesh_id):
			printerr("TC_NPC_BAN space_role=%s mesh=%s" % [nm, mesh_id])
			continue
		out.append(row)
	return out

static func lineup_for(biome: String) -> Array:
	match str(biome).to_lower():
		"harbor":
			return harbor_lineup()
		"wilds":
			return wilds_lineup()
		"crypt":
			return crypt_lineup()
		"space":
			return space_lineup()
		_:
			return town_lineup()


static func distinct_paths_for(biome: String) -> Array[String]:
	var rows: Array = lineup_for(biome)
	var out: Array[String] = []
	var seen := {}
	for row in rows:
		var p := mesh(str(row.get("mesh", "man")))
		if not seen.has(p):
			seen[p] = true
			out.append(p)
	return out


static func resolved_roles(biome: String) -> Array:
	## [{name, mesh_key, path}] for status / prove framing.
	var out: Array = []
	for row in lineup_for(biome):
		var key := str(row.get("mesh", "man"))
		out.append({
			"name": str(row.get("name", key)),
			"mesh": key,
			"path": mesh(key),
		})
	return out


static func inventory_summary() -> Dictionary:
	var biomes := ["town", "harbor", "wilds", "crypt", "space"]
	var summary := {}
	for b in biomes:
		var paths := distinct_paths_for(b)
		var roles := resolved_roles(b)
		summary[b] = {
			"role_count": roles.size(),
			"distinct_meshes": paths.size(),
			"paths": paths,
			"roles": roles,
		}
	return summary
