extends VtAction

const JOINTS: Dictionary[XRBodyTracker.Joint, String] = {
	XRBodyTracker.Joint.JOINT_ROOT: "Root",
	XRBodyTracker.Joint.JOINT_CHEST: "Chest",
	XRBodyTracker.Joint.JOINT_HEAD: "Head",
	XRBodyTracker.Joint.JOINT_HIPS: "Hips",
	XRBodyTracker.Joint.JOINT_LEFT_SHOULDER: "ShoulderL",
	XRBodyTracker.Joint.JOINT_RIGHT_SHOULDER: "ShoulderR",
	XRBodyTracker.Joint.JOINT_LEFT_FOOT: "FootL",
	XRBodyTracker.Joint.JOINT_RIGHT_FOOT: "FootR",
	XRBodyTracker.Joint.JOINT_LEFT_HAND: "HandL",
	XRBodyTracker.Joint.JOINT_RIGHT_HAND: "HandR",
}

func _ready():
	var trackers = XRServer.get_trackers(XRServer.TRACKER_BODY)
	for i in trackers:
		%Tracker.add_item(i)
	
func _build_slots() -> void:
	while get_child_count() > 1:
		var n = get_child(1)
		remove_child(n)
		n.queue_free()
	
	var tracker_name = %Tracker.get_item_text(%Tracker.selected)
	var tracker: XRBodyTracker = XRServer.get_tracker(tracker_name)
	
	var idx = 1
	for joint in range(XRBodyTracker.JOINT_MAX):
		var flags = tracker.get_joint_flags(joint)
		if flags & (XRBodyTracker.JOINT_FLAG_ORIENTATION_TRACKED | XRBodyTracker.JOINT_FLAG_POSITION_TRACKED):
			var joint_name = JOINTS.get(joint, "%s" % joint)
			var label = Label.new()
			label.text = joint_name
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			label.name = joint_name
			label.set_meta("joint", joint)
			add_child(label, true)
			set_slot_enabled_right(idx, true)
			set_slot_type_right(idx, VtAction.SlotType.VECTOR)
			idx += 1
			
func get_type() -> StringName:
	return &"xr_tracker"
	
func serialize():
	return {
		"tracker": %Tracker.get_item_text(%Tracker.selected),
	}
	
func deserialize(data: Dictionary):
	for i in range(%Tracker.item_count):
		if %Tracker.get_item_text(i) == data.get("tracker", ""):
			%Tracker.select(i)
			break
	
func get_input_slot_by_port(port: int) -> int:
	return -1
	
func get_input_port_by_name(slot: StringName) -> int:
	return -1
	
func get_output_slot_by_port(port: int) -> int:
	return port + 1
	
func get_output_port_by_name(slot: StringName) -> int:
	var node = find_child(slot, false, false)
	if node:
		return node.get_index() - 1
	return -1

func get_value(slot: int) -> Variant:
	var name = %Tracker.get_item_text(%Tracker.selected)
	var tracker: XRBodyTracker = XRServer.get_tracker(name)
	var joint = get_child(slot).get_meta("joint", -1)
	if joint > 0:
		return tracker.get_joint_transform(joint)
	return null

func _process(_delta):
	for i in get_child_count() - 1:
		slot_updated.emit(i)
