extends "./parameter_value_provider.gd"

const curve: Curve = preload("./breathe.tres")
const FREQUENCY = 3.0
const MSEC = 1000.0
const FREQ_SCALE = FREQUENCY * MSEC

var model

func apply(inputs: Dictionary):
	if weight == 0.0:
		return
		
	var step = curve.sample_baked(
		pingpong(
			fmod(Time.get_ticks_msec(), FREQ_SCALE * 2), FREQ_SCALE
		) / FREQ_SCALE
	)
		
	for i in model.studio_parameters:
		if i.breath:
			inputs[i.output_parameter] = step
