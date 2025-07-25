extends "../vt_action.gd"

enum Operator {
	Add,
	Multiply
}

var operator : Operator :
	get():
		return %Operator.selected
	set(v):
		%Operator.selected = v

var a : float :
	get():
		return %InputA.value
	set(v):
		%InputA.value = v

var b : float :
	get():
		return %InputB.value
	set(v):
		%InputB.value = v

func get_value(_slot):
	match operator:
		Operator.Add:
			return a + b
		Operator.Multiply:
			return a * b

func update_value(slot, value):
	var dirty = false
	if slot == 0 and a != value:
		a = value
		dirty = true
	if slot == 1 and b != value:
		b = value
		dirty = true
	
	if dirty:
		slot_updated.emit(0)
	
