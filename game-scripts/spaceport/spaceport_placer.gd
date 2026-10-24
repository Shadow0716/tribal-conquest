extends RefCounted
class_name SpaceportPlacer

## Johnny world lock: ONE city is the first-landing spaceport.
## Designated city: South Landing (zone_id "landing") - existing harbor/docks.
## Pads + Kenney hangars + Grab3D/Kenney/Quaternius berths + suited space-district NPCs.
## Free itch packs only. Does not touch plant / TC_PLANT / loco.

const CITY_ZONE_ID := "landing"
const CITY_TITLE := "South Landing"
const SPACEPORT_NAME := "South Landing - First Landing Spaceport"
const SPACEPORT_SHORT := "First Landing Spaceport"

const SPACE_DIR := "res://assets/unity/flight/space"

const PAD_SLOTS := [
	Vector3(-48.0, 0.0, 28.0),
	Vector3(-48.0, 0.0, 38.0),
	Vector3(-58.0, 0.0, 33.0),
	Vector3(-38.0, 0.0, 33.0),
]

const HANGAR_SLOTS := [
	{"path_i": 0, "at": Vector3(-72.0, 0.0, 48.0), "yaw": 0.0, "scale": 1.15},
	{"path_i": 2, "at": Vector3(-72.0, 0.0, 18.0), "yaw": PI, "scale": 1.0},
	{"path_i": 3, "at": Vector3(-30.0, 0.0, 52.0), "yaw": -0.4, "scale": 1.05},
	{"path_i": 4, "at": Vector3(-55.0, 0.0, 55.0), "yaw": 0.2, "scale": 1.2},
]

const DISTRICT_SPOTS := [
	{"name": "Landing Marshal", "at": Vector3(-44.0, 0.0, 24.0), "duty": "guard", "axis": "x"},
	{"name": "Pad Technician", "at": Vector3(-52.0, 0.0, 42.0), "duty": "work", "axis": "z"},
	{"name": "Orbital Customs", "at": Vector3(-36.0, 0.0, 40.0), "duty": "patrol", "axis": "z"},
	{"name": "Suit Mechanic", "at": Vector3(-60.0, 0.0, 28.0), "duty": "work", "axis": "x"},
	{"name": "Dock Astrotech", "at": Vector3(-54.0, 0.0, 22.0), "duty": "wander", "axis": "z"},
	{"name": "Port Warden", "at": Vector3(-40.0, 0.0, 44.0), "duty": "guard", "axis": "x"},
]


static func apply(world: Node) -> void:
	if world == null:
		return
	var zone := str(world.get("zone_id"))
	if zone != CITY_ZONE_ID:
		printerr("TC_SPACEPORT skip zone=%s (first landing is %s / %s)" % [zone, CITY_ZONE_ID, CITY_TITLE])
		return
	world.set("zone_title", SPACEPORT_NAME)
	world.set("camp_label", "%s  ·  safe" % SPACEPORT_SHORT)
	world.set_meta("first_landing_spaceport", true)
	world.set_meta("spaceport_city_id", CITY_ZONE_ID)
	world.set_meta("spaceport_city_title", CITY_TITLE)
	world.set_meta("spaceport_display_name", SPACEPORT_NAME)

	var Assets = load("res://scripts/space_ship_assets.gd")
	var pads := _place_pads(world)
	var hangars := _place_hangars(world, Assets)
	var berthed := _berth_space_ships(world, Assets)
	var crew := _place_space_district(world)
	if world.has_method("_sign"):
		world._sign(SPACEPORT_SHORT, Vector3(-46.0, 0.0, 20.0))
		world._sign("Space district", Vector3(-42.0, 0.0, 46.0))
		world._sign("Landing pads", Vector3(-56.0, 0.0, 33.0))
		world._sign("Hangar row", Vector3(-68.0, 0.0, 40.0))
	printerr("TC_SPACEPORT city=%s pads=%d hangars=%d berthed=%d district=%d name=%s" % [
		CITY_ZONE_ID, pads, hangars, berthed, crew, SPACEPORT_NAME
	])


static func _place_pads(world: Node) -> int:
	var n := 0
	for slot in PAD_SLOTS:
		var at: Vector3 = slot
		var y := 0.06
		if world.has_method("_surface_y"):
			y = float(world.call("_surface_y", at.x, at.z)) + 0.06
		var pad := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(10.0, 0.14, 8.0)
		pad.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.38, 0.42, 0.48)
		mat.metallic = 0.55
		mat.roughness = 0.42
		mat.emission_enabled = true
		mat.emission = Color(0.25, 0.55, 0.85)
		mat.emission_energy_multiplier = 0.35
		pad.material_override = mat
		pad.position = Vector3(at.x, y, at.z)
		pad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pad.name = "FirstLandingPad_%d" % n
		pad.add_to_group("spaceport_pad")
		world.add_child(pad)
		for corner in [
			Vector3(-4.2, 0.2, -3.2), Vector3(4.2, 0.2, -3.2),
			Vector3(-4.2, 0.2, 3.2), Vector3(4.2, 0.2, 3.2),
		]:
			var lamp := MeshInstance3D.new()
			var globe := SphereMesh.new()
			globe.radius = 0.14
			globe.height = 0.28
			lamp.mesh = globe
			var glow := StandardMaterial3D.new()
			glow.albedo_color = Color(0.55, 0.85, 1.0)
			glow.emission_enabled = true
			glow.emission = Color(0.35, 0.75, 1.0)
			glow.emission_energy_multiplier = 1.1
			lamp.material_override = glow
			lamp.position = pad.position + corner
			lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			world.add_child(lamp)
		n += 1
	return n


static func _place_hangars(world: Node, Assets) -> int:
	if Assets == null:
		return 0
	var paths: Array = Assets.hangar_paths()
	if paths.is_empty():
		printerr("TC_SPACEPORT_NO_HANGARS")
		return 0
	var placed := 0
	for slot in HANGAR_SLOTS:
		var idx := int(slot["path_i"]) % paths.size()
		var path := str(paths[idx])
		var visual: Node3D = Assets.instantiate(path)
		if visual == null:
			continue
		var at: Vector3 = slot["at"]
		var y := 0.02
		if world.has_method("_surface_y"):
			y = float(world.call("_surface_y", at.x, at.z)) + 0.02
		var rig := Node3D.new()
		rig.name = "SpaceportHangar_%d" % placed
		rig.position = Vector3(at.x, y, at.z)
		rig.rotation.y = float(slot["yaw"])
		rig.add_to_group("spaceport_hangar")
		world.add_child(rig)
		rig.add_child(visual)
		var sc := float(slot.get("scale", 1.0))
		visual.scale = Vector3.ONE * sc
		# Seat on pad surface.
		var box := _aabb(visual)
		visual.position.y -= box.position.y
		placed += 1
	return placed


static func _berth_space_ships(world: Node, Assets) -> int:
	if Assets == null:
		return 0
	var paths: Array = Assets.berth_paths()
	if paths.is_empty():
		printerr("TC_SPACEPORT_NO_SHIPS")
		return 0
	var placed := 0
	for i in mini(PAD_SLOTS.size(), paths.size()):
		var path := str(paths[i % paths.size()])
		var slot: Vector3 = PAD_SLOTS[i]
		var hull := _spawn_berthed(world, Assets, path, slot, 5.5 if i > 0 else 7.0)
		if hull != null:
			placed += 1
	return placed


static func _spawn_berthed(world: Node, Assets, path: String, slot: Vector3, length_target: float) -> Node3D:
	var visual: Node3D = Assets.instantiate(path)
	if visual == null:
		return null
	var rig := Node3D.new()
	var y := 0.08
	if world.has_method("_surface_y"):
		y = float(world.call("_surface_y", slot.x, slot.z)) + 0.08
	rig.position = Vector3(slot.x, y, slot.z)
	rig.rotation.y = PI * 0.5 if int(slot.z) % 2 == 0 else 0.0
	rig.add_to_group("parked_ship")
	rig.add_to_group("spaceport_ship")
	rig.set_meta("scenery_ship", true)
	rig.set_meta("ship_file", path.get_file())
	rig.set_meta("first_landing_berth", true)
	world.add_child(rig)
	rig.add_child(visual)
	_fit_length(visual, length_target)
	var box := _aabb(visual)
	visual.position.y -= box.position.y
	rig.set_meta("rest", rig.position)
	return rig


static func _fit_length(node: Node3D, length_target: float) -> void:
	var box := _aabb(node)
	var length := maxf(box.size.x, box.size.z)
	if length > 0.05:
		node.scale = Vector3.ONE * clampf(length_target / length, 0.02, 12.0)


static func _aabb(root: Node3D) -> AABB:
	var first := true
	var merged := AABB()
	var stack: Array = [root]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is VisualInstance3D:
			var vi := current as VisualInstance3D
			var local := vi.get_aabb()
			var xf := vi.global_transform if vi.is_inside_tree() else vi.transform
			for sx in [0.0, 1.0]:
				for sy in [0.0, 1.0]:
					for sz in [0.0, 1.0]:
						var c: Vector3 = xf * (local.position + Vector3(local.size.x * sx, local.size.y * sy, local.size.z * sz))
						if first:
							merged = AABB(c, Vector3.ZERO)
							first = false
						else:
							merged = merged.expand(c)
		for child in current.get_children():
			stack.append(child)
	return merged


static func _space_kit() -> Array[String]:
	var kit: Array[String] = []
	var candidates := [
		"%s/Astronaut.glb" % SPACE_DIR,
		"%s/Astronaut_b.glb" % SPACE_DIR,
		"%s/Astronaut_c.glb" % SPACE_DIR,
		"res://assets/grab3d/sci-fi-soldier_rigged.glb",
		"%s/Mech.glb" % SPACE_DIR,
		"%s/Stan.fbx" % SPACE_DIR,
		"%s/Leela.fbx" % SPACE_DIR,
		"%s/Mike.fbx" % SPACE_DIR,
	]
	for path in candidates:
		if ResourceLoader.exists(path) or FileAccess.file_exists(path):
			kit.append(path)
	if kit.is_empty():
		kit.append("res://assets/grab3d/sci-fi-soldier_rigged.glb")
	return kit


static func _place_space_district(world: Node) -> int:
	if not world.has_method("_spawn_npc"):
		return 0
	var kit := _space_kit()
	var placed := 0
	for i in DISTRICT_SPOTS.size():
		var spot: Dictionary = DISTRICT_SPOTS[i]
		var path := kit[i % kit.size()]
		var body: Node3D = world.call(
			"_spawn_npc",
			str(spot["name"]),
			spot["at"] as Vector3,
			path,
			1.0,
			"",
			1.1,
			str(spot.get("duty", "patrol")),
			str(spot.get("axis", "z")),
			"port",
			"",
			false
		) as Node3D
		if body != null:
			body.set_meta("space_district", true)
			body.set_meta("first_landing_crew", true)
			body.add_to_group("spaceport_npc")
			placed += 1
	return placed
