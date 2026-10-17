class_name ResultCard
extends Control
## How the door went: through or caught, in how many lines and how long,
## how suspicious he got, and the average timings, with a way back.

signal again
signal to_title

var _panel: PanelContainer
var _col: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	center.add_child(_panel)
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 10)
	_panel.add_child(_col)


## Shows the result. `summary` has "outcome" ("through" or "caught"),
## "turns", "seconds", "peak", "heard", "thought", "spoke" (averages, -1 for
## none), "scripted" (how many lines came from the script).
func show_result(summary: Dictionary) -> void:
	for c in _col.get_children():
		_col.remove_child(c)
		c.queue_free()
	var through := str(summary.get("outcome", "")) == "through"
	_col.add_child(HotelTheme.title_label("YOU'RE THROUGH" if through else "HE CALLED IT IN", 40, HotelTheme.BRASS if through else HotelTheme.BURGUNDY))
	var lines := PackedStringArray()
	lines.append("%d lines in %s" % [int(summary.get("turns", 0)), _clock(float(summary.get("seconds", 0.0)))])
	lines.append("Suspicion peaked at %d of 5" % int(summary.get("peak", 0)))
	var timing := PackedStringArray()
	if float(summary.get("heard", -1.0)) >= 0.0:
		timing.append("heard in %.1f s" % float(summary.heard))
	if float(summary.get("thought", -1.0)) >= 0.0:
		timing.append("thought in %.1f s" % float(summary.thought))
	if float(summary.get("spoke", -1.0)) >= 0.0:
		timing.append("spoke in %.2f s" % float(summary.spoke))
	if not timing.is_empty():
		lines.append("On average: " + ", ".join(timing))
	if int(summary.get("scripted", 0)) > 0:
		lines.append("%d of his lines were scripted (no model, or too slow)" % int(summary.scripted))
	if str(summary.get("file", "")) != "":
		lines.append("The turns are in %s" % str(summary.file))
	for l in lines:
		var lab := LGUi.label(l, "DimLabel" if l == lines[lines.size() - 1] and str(summary.get("file", "")) != "" else "")
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.custom_minimum_size.x = 560
		_col.add_child(lab)
	_col.add_child(Control.new())
	_col.add_child(LGUi.button("Try the door again", _again, 560))
	_col.add_child(LGUi.button("Back to the title", _title, 560))
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	LGUi.focus_first(_col)


static func _clock(s: float) -> String:
	return "%d:%02d" % [int(s) / 60, int(s) % 60]


func _again() -> void:
	again.emit()


func _title() -> void:
	to_title.emit()
