extends "./parameter_value_provider.gd"

const curve: Curve = preload("./blink.tres")

const SPEED = 0.5
const MSEC = 1000.0
const SCALE = SPEED * MSEC # speed at which we blink
const FREQUENCY = [SCALE, SCALE * 15]

@export var model: VtModel

# keep track of blink tweens so we don't start again while already blinking
var blinking: int = 0

func apply(inputs: Dictionary):
	if weight == 0.0:
		return
		
	var now = Time.get_ticks_msec()
	if blinking < now:
		blinking = now + randf_range(FREQUENCY[0], FREQUENCY[1])
	
	var blink_step = 1.0
	if now > blinking - SCALE:
		blink_step = 1.0 - curve.sample_baked(
			inverse_lerp(
				0.0, SCALE / 2,
				pingpong(
					(blinking - now), SCALE / 2
				)
			)
		)
	
	for i in model.studio_parameters:
		if i.blink:
			inputs[i.output_parameter] = inputs.get(i.output_parameter, 1.0) * blink_step
