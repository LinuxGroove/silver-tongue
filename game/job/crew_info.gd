class_name CrewInfo
extends RefCounted
## One member of the crew on a job: who's playing, their cover and clothes,
## the forged invitation, and whether they're held or inside. `node` is
## their body on this device: the player's own [CrewMember], or a
## [CrewAvatar] for someone on another device.

var id := 1
## The device's peer (1 is the host).
var peer := 1
## The player's own name, for the crew's eyes only.
var name := "Stranger"
var cover := "guest"
## The name the cover goes by.
var cover_name := ""
var female := false
## Skin, hair and style, for [Person.make].
var look := {}
var outfit := "guest"
var has_invitation := false
var held := false
var inside := false
var node: Node3D


static func make(p_id: int, p_peer: int, p_name: String, p_cover: String, p_female: bool, p_look := {}) -> CrewInfo:
	var c := CrewInfo.new()
	c.id = p_id
	c.peer = p_peer
	c.name = p_name
	c.cover = p_cover if Covers.ALL.has(p_cover) else "guest"
	c.female = p_female
	c.look = p_look
	c.cover_name = Covers.cover_name(c.cover, p_female)
	c.outfit = str(Covers.ALL[c.cover].outfit)
	return c


func mouth() -> Vector3:
	if node and node.has_method("mouth_position"):
		return node.mouth_position()
	return node.global_position + Vector3(0, 1.6, 0) if node else Vector3.ZERO


## Which way they're looking, flat.
func facing() -> Vector3:
	var f := Vector3.FORWARD
	if node and node.has_method("look_dir"):
		f = node.look_dir()
	elif node:
		f = -node.global_transform.basis.z
	f.y = 0.0
	return f.normalized() if f.length() > 0.01 else Vector3.FORWARD


func position() -> Vector3:
	return node.global_position if node else Vector3.ZERO


## For the session: everything another device needs to know about them.
func to_dict() -> Dictionary:
	return {"id": id, "peer": peer, "name": name, "cover": cover, "female": female, "look": look, "outfit": outfit, "has_invitation": has_invitation, "held": held, "inside": inside}


static func from_dict(d: Dictionary) -> CrewInfo:
	var c := make(int(d.get("id", 1)), int(d.get("peer", 1)), str(d.get("name", "Stranger")), str(d.get("cover", "guest")), bool(d.get("female", false)), d.get("look", {}))
	c.outfit = str(d.get("outfit", c.outfit))
	c.has_invitation = bool(d.get("has_invitation", false))
	c.held = bool(d.get("held", false))
	c.inside = bool(d.get("inside", false))
	return c
