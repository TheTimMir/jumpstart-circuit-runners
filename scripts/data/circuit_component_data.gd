extends Resource
class_name CircuitComponentData

enum CircuitComponentType {
	RESISTOR, 
	CAPACITOR
}

@export var position: Vector2i = Vector2i.ZERO
@export var type: CircuitComponentType 
@export var strength: int = 1 # resistor substracts this amount, capacitor adds
