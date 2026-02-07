## Live2DPhysicsValueProvider
##
## Override GDCubism's native physics effect, instead recreating the system in GDScript
## to have finer grained control over how it mixes with other VTModel parameters.
## This allows us to apply weight to the outcome of each physics group

extends "res://lib/model/parameters/parameter_value_provider.gd"

const MAX_WEIGHT = 100.0
const AIR_RESISTANCE = 5.0
const THRESHOLD_VALUE = 0.001
const MAX_DELTA = 5.0

enum PhysicsSource {
	X_MOVEMENT,
	Y_MOVEMENT,
	ANGLE
}

static func mapto_physics_source(type: String) -> PhysicsSource:
	match type:
		"X":
			return PhysicsSource.X_MOVEMENT
		"Y":
			return PhysicsSource.Y_MOVEMENT
		"Angle":
			return PhysicsSource.ANGLE
	return PhysicsSource.X_MOVEMENT
	
class InputParameter:
	# properties
	var parameter: StringName
	var weight: float
	var source: PhysicsSource
	var reflect: bool
	
class OutputParameter:
	var parameter: StringName
	var scale: float
	var weight: float
	var vertex: PhysicsStrand
	var target: PhysicsSource
	var reflect: bool
	
class PhysicsStrand extends Node2D:
	# properties
	var mobility: float
	var delay: float
	var acceleration: float
	var radius: float
	
	# state
	var last_position: Vector2
	var initial_position: Vector2
	var gravity: Vector2
	var last_gravity: Vector2
	var velocity: Vector2
	
	func reset():
		if "initial_position" in get_parent():
			initial_position = get_parent().initial_position + Vector2(0, radius)
		else:
			initial_position = Vector2.ZERO
		last_position = initial_position
		position = initial_position
		last_gravity = Vector2(0, 1.0)
		velocity = Vector2.ZERO

class ChainDebug extends Node2D:
	func _draw() -> void:
		var p = Vector2.ZERO
		for c in get_parent().chain:
			var o = p
			p += c.position * 10
			draw_line(o, p, Color.BLUE, 3)
			draw_circle(p, 5, Color.BLUE)

var inputs: Array[InputParameter] = []
var outputs: Array[OutputParameter] = []
var chain: Array[PhysicsStrand] = []

@export var group: StringName
@export var gravity: Vector2
@export var wind: Vector2

# normalization of parameters
var normalization_position: Vector3
var normalization_angle: Vector3

var debug: ChainDebug

func _ready():
	debug = ChainDebug.new()
	debug.position = Vector2.ONE * 200
	add_child(debug)

func load_from_json(settings: Dictionary, meta: Dictionary) -> void:
	inputs = []
	outputs = []
	chain = []
	
	normalization_position = Vector3(
		settings.Normalization.Position.Minimum,
		settings.Normalization.Position.Maximum,
		settings.Normalization.Position.Default,
	)
	normalization_angle = Vector3(
		settings.Normalization.Angle.Minimum,
		settings.Normalization.Angle.Maximum,
		settings.Normalization.Angle.Default,
	)
	
	gravity = Vector2(
		meta.EffectiveForces.Gravity.X,
		meta.EffectiveForces.Gravity.Y,
	)
	wind = Vector2(
		meta.EffectiveForces.Wind.X,
		meta.EffectiveForces.Wind.Y,
	)
	
	for input in settings.get("Input", []):
		var i = InputParameter.new()
		i.parameter = StringName(input.Source.Id)
		i.source = mapto_physics_source(input.Type)
		i.weight = input.Weight / MAX_WEIGHT
		i.reflect = input.Reflect
		inputs.append(i)
		
	var tree = self
	for vtx in settings.get("Vertices"):
		var v = PhysicsStrand.new()
		v.position = Vector2(vtx.Position.X, vtx.Position.Y)
		v.mobility = vtx.Mobility
		v.delay = vtx.Delay
		v.acceleration = vtx.Acceleration
		v.radius = vtx.Radius
		chain.append(v)
		tree.add_child(v)
		tree = v
	
	for output in settings.get("Output", []):
		var o = OutputParameter.new()
		o.parameter = StringName(output.Destination.Id)
		o.scale = output.Scale / 100.0
		o.weight = output.Weight / MAX_WEIGHT
		o.vertex = chain[int(output.VertexIndex)]
		o.target = mapto_physics_source(output.Type)
		outputs.append(o)
		
## sets vertex strands to their initial position
func reset():
	for s in chain:
		s.reset()
	
func update(parameter_inputs: Dictionary, delta: float):
	# copy previous rig state for interpolation
	var previous_rig = self.values.duplicate()
	parameter_inputs.merge(previous_rig, true)
	
	var target_translation: Vector2 = Vector2.ZERO
	var target_angle: float = 0
	
	# update inputs
	for i in inputs:
		var model_parameter = parameters[i.parameter]
		if model_parameter == null:
			continue
		var value = parameter_inputs.get(i.parameter, model_parameter.default)
		match i.source:
			PhysicsSource.X_MOVEMENT:
				target_translation.x += lerp(
					normalization_position.x,
					normalization_position.y,
					inverse_lerp(
						model_parameter.min,
						model_parameter.max,
						value
					)
				) * i.weight
			PhysicsSource.Y_MOVEMENT:
				target_translation.y += lerp(
					normalization_position.x,
					normalization_position.y,
					inverse_lerp(
						model_parameter.min,
						model_parameter.max,
						value
					)
				) * i.weight
			PhysicsSource.ANGLE:
				target_angle += lerp(
					normalization_angle.x,
					normalization_angle.y,
					inverse_lerp(
						model_parameter.min,
						model_parameter.max,
						value
					)
				) * i.weight
		
	var rad = deg_to_rad(-target_angle)
	target_translation = target_translation.rotated(rad)
	chain[0].position = target_translation
	
	# calculate vertex position based on inputs and interpolation between frames
	rad = deg_to_rad(target_angle)
	var current_gravity = Vector2(
		sin(rad),
		cos(rad)
	).normalized()
	
	for idx in range(1, len(chain)):
		var i = chain[idx]
		i.last_position = i.position
		var facing = i.last_gravity.angle_to(current_gravity) / AIR_RESISTANCE
		var delay = i.delay * delta * 30.0
		
		var direction = i.position.rotated(facing)
		var velocity = i.velocity * delay
		var force = ((current_gravity * i.acceleration) + wind) * pow(delay, 2)
		var new_direction = (direction + velocity + force).normalized()
		i.position = new_direction * i.radius
		
		if abs(i.position.x) < THRESHOLD_VALUE:
			i.position.x = 0
		if delay != 0.0:
			i.velocity = (i.position - i.last_position) / delay * i.mobility
		i.last_gravity = current_gravity
	debug.queue_redraw()

	# update outputs
	for o in outputs:
		var out_param = parameters[o.parameter]
		var value = 0.0
		var invert = 1.0 if not o.reflect else -1.0
		var strand = o.vertex
		match o.target:
			PhysicsSource.X_MOVEMENT:
				value = strand.position.x
			PhysicsSource.Y_MOVEMENT:
				value = strand.position.y
			PhysicsSource.ANGLE:
				var g = -gravity
				if "position" in strand.get_parent():
					var p = strand.get_parent()
					if "position" in p.get_parent():
						g = -p.position
				value = g.angle_to(strand.position)
		
		value = clamp(
			value * invert * o.scale,
			out_param.min,
			out_param.max
		)
		var current = self.values.get(o.parameter, parameter_inputs.get(o.parameter, out_param.default))
		self.values[o.parameter] = lerp(current, value, o.weight)
		
