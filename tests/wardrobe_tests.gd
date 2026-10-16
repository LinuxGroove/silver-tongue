extends RefCounted
## The wardrobe's outfits for women (made by tools/blender/wardrobe.py): each has its pieces,
## skinned to the female body's own skeleton, and dresses a person who stands up in it.

const PIECES := {
	"halberd_suit": ["Suit", "Skirt", "Shirt", "Tie", "Trousers", "Shoes", "Buttons", "Pin", "Earpiece"],
	"evening_dress": ["Dress", "Shoes", "Necklace"],
}


func test_pieces(t) -> void:
	var base: Node = (load(Person.FEMALE) as PackedScene).instantiate()
	var base_skeleton: Skeleton3D = base.find_child("Skeleton3D", true, false)
	var bones := _bones(base_skeleton)
	var base_neck := base_skeleton.get_bone_global_rest(base_skeleton.find_bone("neck_01")).origin
	base.free()
	for outfit in PIECES:
		var path := Person.OUTFIT % [outfit, "female"]
		t.check(ResourceLoader.exists(path), "%s is made for women" % outfit)
		if not ResourceLoader.exists(path):
			continue
		var model: Node = (load(path) as PackedScene).instantiate()
		t.add_child(model)
		var skeleton: Skeleton3D = model.find_child("Skeleton3D", true, false)
		t.check(skeleton != null and _bones(skeleton) == bones, "%s keeps the female body's bones" % outfit)
		if skeleton:
			var neck := skeleton.get_bone_global_rest(skeleton.find_bone("neck_01")).origin
			t.check(neck.distance_to(base_neck) < 0.002, "%s keeps the female body's proportions" % outfit)
		var meshes := {}
		for mi in model.find_children("", "MeshInstance3D", true, false):
			meshes[String(mi.name)] = mi
		for piece in ["Body", "Eyes"] + PIECES[outfit]:
			var m: MeshInstance3D = meshes.get(piece)
			t.check(m != null, "%s has its %s" % [outfit, piece])
			if m == null:
				continue
			t.check(m.skin != null and m.get_node_or_null(m.skeleton) == skeleton, "the %s's %s is skinned to the body's skeleton" % [outfit, piece])
		# Anything the game doesn't know as clothes would be painted as skin.
		for piece in meshes:
			if piece != "Body" and not piece.begins_with("Eye"):
				t.check(Person.WARDROBE[outfit].has(piece), "the game knows how to colour the %s's %s" % [outfit, piece])
		model.queue_free()
	await t.frames(1)


func test_dress_reaches_the_floor(t) -> void:
	var model: Node = (load(Person.OUTFIT % ["evening_dress", "female"]) as PackedScene).instantiate()
	t.add_child(model)
	var dress: MeshInstance3D = model.find_child("Dress", true, false)
	var box := dress.mesh.get_aabb() if dress else AABB()
	t.check(dress != null and box.position.y < 0.08 and box.end.y > 1.3, "the gown runs from the shoulders to the floor")
	model.queue_free()
	await t.frames(1)


func test_women_stand_up_dressed(t) -> void:
	# A job that wears a suit made for women gets it.
	var guard := Person.make("guard", true, 3)
	t.add_child(guard)
	await t.frames(2)
	t.check(guard.outfit == "halberd_suit", "a woman on the door wears Halberd's suit")
	t.check(guard.bone_position("Head").y > 1.4, "the suit's skeleton stands her up (head at %.2f)" % guard.bone_position("Head").y)
	guard.play("Idle")
	await t.frames(3)
	t.check(guard.bone_position("Head").y > 1.4, "she stands in it as she idles")
	guard.queue_free()
	# No job wears the gown yet: the same skeleton and the game's clips stand it up too.
	var model: Node3D = (load(Person.OUTFIT % ["evening_dress", "female"]) as PackedScene).instantiate()
	t.add_child(model)
	var skeleton: Skeleton3D = model.find_child("Skeleton3D", true, false)
	var anim := AnimationPlayer.new()
	model.add_child(anim)
	anim.add_animation_library("ual1", load(Person.UAL1))
	anim.play("ual1/Idle")
	await t.frames(3)
	var head := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Head")).origin
	t.check(head.y > 1.4, "the gown's skeleton stands her up (head at %.2f)" % head.y)
	model.queue_free()
	await t.frames(1)


## The skeleton's bone names, in name order (the export may order them differently).
func _bones(skeleton: Skeleton3D) -> PackedStringArray:
	var out := PackedStringArray()
	if skeleton:
		for i in skeleton.get_bone_count():
			out.append(skeleton.get_bone_name(i))
	out.sort()
	return out
