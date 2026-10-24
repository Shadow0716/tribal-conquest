extends Node
class_name SpaceSkyTraffic

## Ambient space-ship sky traffic across the FULL map (not port-only).
## Hulls: Quaternius Ultimate Spaceships + Kenney craft + Grab3D (itch free / CC0).
## Own group sky_traffic - does not touch plant/loco.
## Boot: SpaceSkyTraffic.boot(world) from world._ready (one-liner). Idempotent.

const WORLD_HALF := 460.0
const FLEET_COUNT := 18
const GROUP := "sky_traffic"

var _world: Node = null
var _fleet: Array[Dictionary] = []
var _Assets = null


static func boot(world: Node) -> void:
	if world == null:
		return
	if bool(world.get_meta("spaceport_booted", false)):
		return
	world.set_meta("spaceport_booted", true)
	var placer = load("res://scripts/spaceport_placer.gd")
	if placer != null and placer.has_method("apply"):
		placer.apply(world)
	var node := Node.new()
	node.name = "SpaceSkyTraffic"
	node.set_script(load("res://scripts/space_sky_traffic.gd"))
	world.add_child(node)
	if node.has_method("setup"):
		node.call("setup", world)


func setup(world: Node) -> void:
	_world = world
	_Assets = load("res://scripts/space_ship_assets.gd")
	var paths: Array = []
	if _Assets != null:
		paths = _Assets.sky_fleet_paths()
	if paths.is_empty():
		printerr("TC_SKY_TRAFFIC empty hull list")
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x5C7A11F0
	for i in FLEET_COUNT:
		var path: String = str(paths[i % paths.size()])
		var hull := _spawn_hull(path, i)
		if hull == null:
			continue
		var lane := _make_lane(i, rng)
		hull.set_meta("sky_lane", lane)
		hull.set_meta("sky_t", rng.randf() * TAU)
		hull.set_meta("sky_speed", 0.08 + float(i % 5) * 0.018)
		hull.set_meta("sky_bob", 0.4 + float(i % 4) * 0.15)
		_fleet.append({"node": hull, "lane": lane})
		_step_one(hull, 0.0)
	printerr("TC_SKY_TRAFFIC fleet=%d hulls=%d span=+/-%.0f (full map, itch packs)" % [_fleet.size(), paths.size(), WORLD_HALF])


func _process(delta: float) -> void:
	for entry in _fleet:
		var hull: Node3D = entry.get("node")
		if hull == null or not is_instance_valid(hull):
			continue
		_step_one(hull, delta)


func _step_one(hull: Node3D, delta: float) -> void:
	var lane: Dictionary = hull.get_meta("sky_lane", {})
	var t := float(hull.get_meta("sky_t", 0.0)) + delta * float(hull.get_meta("sky_speed", 0.12))
	hull.set_meta("sky_t", t)
	var kind := str(lane.get("kind", "orbit"))
	var height := float(lane.get("height", 42.0))
	var bob := sin(t * 1.7) * float(hull.get_meta("sky_bob", 0.5))
	var pos := Vector3.ZERO
	var ahead := Vector3.ZERO
	if kind == "cross":
		var axis := str(lane.get("axis", "x"))
		var a := float(lane.get("a", -WORLD_HALF))
		var b := float(lane.get("b", WORLD_HALF))
		var fixed := float(lane.get("fixed", 0.0))
		var u := fposmod(t * 0.15, 1.0)
		var u2 := fposmod(u + 0.02, 1.0)
		if axis == "x":
			pos = Vector3(lerpf(a, b, u), height + bob, fixed)
			ahead = Vector3(lerpf(a, b, u2), height + bob, fixed)
		else:
			pos = Vector3(fixed, height + bob, lerpf(a, b, u))
			ahead = Vector3(fixed, height + bob, lerpf(a, b, u2))
		var sway := sin(t * 0.55) * float(lane.get("sway", 12.0))
		if axis == "x":
			pos.z += sway
			ahead.z += sway
		else:
			pos.x += sway
			ahead.x += sway
	else:
		var cx := float(lane.get("cx", 0.0))
		var cz := float(lane.get("cz", 0.0))
		var rx := float(lane.get("rx", WORLD_HALF * 0.7))
		var rz := float(lane.get("rz", WORLD_HALF * 0.55))
		pos = Vector3(cx + cos(t) * rx, height + bob, cz + sin(t) * rz)
		ahead = Vector3(cx + cos(t + 0.08) * rx, height + bob, cz + sin(t + 0.08) * rz)
	hull.global_position = pos
	if ahead.distance_squared_to(pos) > 0.04:
		hull.look_at(ahead, Vector3.UP)


func _make_lane(index: int, rng: RandomNumberGenerator) -> Dictionary:
	var height := 28.0 + float(index % 7) * 6.5
	if index % 3 == 0:
		var axis := "x" if index % 2 == 0 else "z"
		var fixed := rng.randf_range(-WORLD_HALF * 0.85, WORLD_HALF * 0.85)
		return {
			"kind": "cross",
			"axis": axis,
			"a": -WORLD_HALF,
			"b": WORLD_HALF,
			"fixed": fixed,
			"height": height,
			"sway": 8.0 + float(index % 4) * 5.0,
		}
	var cx := rng.randf_range(-WORLD_HALF * 0.35, WORLD_HALF * 0.35)
	var cz := rng.randf_range(-WORLD_HALF * 0.35, WORLD_HALF * 0.35)
	var rx := WORLD_HALF * (0.45 + float(index % 5) * 0.08)
	var rz := WORLD_HALF * (0.35 + float((index + 2) % 5) * 0.08)
	return {
		"kind": "orbit",
		"cx": cx,
		"cz": cz,
		"rx": rx,
		"rz": rz,
		"height": height,
	}


func _spawn_hull(path: String, index: int) -> Node3D:
	var visual: Node3D = null
	if _Assets != null:
		visual = _Assets.instantiate(path)
	if visual == null:
		return null
	var rig := Node3D.new()
	rig.name = "SkyShip_%d" % index
	rig.add_to_group(GROUP)
	rig.set_meta("sky_traffic", true)
	rig.set_meta("ship_file", path.get_file())
	_world.add_child(rig)
	rig.add_child(visual)
	var box := _aabb(visual)
	var length := maxf(box.size.x, maxf(box.size.y, box.size.z))
	var target := 7.5 + float(index % 4) * 1.8
	if length > 0.05:
		visual.scale = Vector3.ONE * clampf(target / length, 0.15, 2.2)
	_dim_shadows(visual)
	return rig


func _dim_shadows(root: Node) -> void:
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is GeometryInstance3D:
			(n as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for child in n.get_children():
			stack.append(child)


func _aabb(root: Node3D) -> AABB:
	var first := true
	var merged := AABB()
	var stack: Array = [root]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is VisualInstance3D:
			var vi := current as VisualInstance3D
			var local := vi.get_aabb()
			var xf: Transform3D
			if root.is_inside_tree() and vi.is_inside_tree():
				xf = root.global_transform.affine_inverse() * vi.global_transform
			else:
				xf = vi.transform
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