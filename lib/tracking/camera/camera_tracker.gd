extends "res://lib/tracking/interpolated_tracker.gd"

func _ready() -> void:
	Registry.add_parameter("FacePositionX", Vector2(-15, 15))
	Registry.add_parameter("FacePositionY", Vector2(-15, 15))
	Registry.add_parameter("FacePositionZ", Vector2(-10, 10))
	Registry.add_parameter("FaceAngleX", Vector2(-30, 30))
	Registry.add_parameter("FaceAngleY", Vector2(-30, 30))
	Registry.add_parameter("FaceAngleZ", Vector2(-30, 30))
	
	Registry.add_parameter("MouthSmile", Vector2(0, 1))
	Registry.add_parameter("MouthOpen", Vector2(0, 1))
	Registry.add_parameter("MouthX", Vector2(-1, 1))
	
	Registry.add_parameter("Brows", Vector2(0, 1))
	
	# iOS/Android only
	Registry.add_parameter("TongueOut", Vector2(0, 1))
	
	Registry.add_parameter("EyeOpenLeft", Vector2(0, 1), 1)
	Registry.add_parameter("EyeOpenRight", Vector2(0, 1), 1)
	Registry.add_parameter("EyeLeftX", Vector2(-1, 1))
	Registry.add_parameter("EyeLeftY", Vector2(-1, 1))
	Registry.add_parameter("EyeRightX", Vector2(-1, 1))
	Registry.add_parameter("EyeRightY", Vector2(-1, 1))
	
	# iOS only
	Registry.add_parameter("CheekPuff", Vector2(0, 1))
	Registry.add_parameter("FaceAngry", Vector2(0, 1))
	
	Registry.add_parameter("BrowLeftY", Vector2(-1, 1))
	Registry.add_parameter("BrowRightY", Vector2(-1, 1))
	
	Registry.add_parameter("MouthX", Vector2(-1, 1))
	
	# hand tracking (pc only)
	#Registry.add_parameter("HandLeftFound")
	#Registry.add_parameter("HandRightFound")
	#Registry.add_parameter("BothHandsFound")
	#Registry.add_parameter("HandDistance")
	#Registry.add_parameter("HandLeftPositionX", Vector2(-1, 1))
	#Registry.add_parameter("HandLeftPositionY", Vector2(-1, 1))
	#Registry.add_parameter("HandLeftPositionZ", Vector2(-1, 1))
	#Registry.add_parameter("HandRightPositionX", Vector2(-1, 1))
	#Registry.add_parameter("HandRightPositionY", Vector2(-1, 1))
	#Registry.add_parameter("HandRightPositionZ", Vector2(-1, 1))
	#Registry.add_parameter("HandLeftAngleX", Vector2(-1, 1))
	#Registry.add_parameter("HandLeftAngleZ", Vector2(-1, 1))
	#Registry.add_parameter("HandRightAngleX", Vector2(-1, 1))
	#Registry.add_parameter("HandRightAngleZ", Vector2(-1, 1))
	#Registry.add_parameter("HandLeftOpen")
	#Registry.add_parameter("HandRightOpen")
	#Registry.add_parameter("HandLeftFinger1Thumb")
	#Registry.add_parameter("HandLeftFinger2Index")
	#Registry.add_parameter("HandLeftFinger3Middle")
	#Registry.add_parameter("HandLeftFinger4Ring")
	#Registry.add_parameter("HandLeftFinger5Pinky")
	#Registry.add_parameter("HandRightFinger1Thumb")
	#Registry.add_parameter("HandRightFinger2Index")
	#Registry.add_parameter("HandRightFinger3Middle")
	#Registry.add_parameter("HandRightFinger4Ring")
	#Registry.add_parameter("HandRightFinger5Pinky")
	
	reset()

func reset():
	update([
		"FacePositionX",
		"FacePositionY",
		"FacePositionZ",
		"FaceAngleX",
		"FaceAngleY",
		"FaceAngleZ",
		"MouthSmile",
		"MouthOpen",
		"MouthX",
		"Brows",
		"TongueOut",
		"EyeOpenLeft",
		"EyeOpenRight",
		"EyeLeftX",
		"EyeLeftY",
		"EyeRightX",
		"EyeRightY",
		"CheekPuff",
		"FaceAngry",
		"BrowLeftY",
		"BrowRightY",
		"MouthX",
	].reduce(
		func (acc, parameter):
			acc[parameter] = Registry.get_default(parameter)
			return acc,
		{}
	))
