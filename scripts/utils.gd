extends Node

func expandShape(shapeArr: Array, pixels: int):
	return shapeArr.map(
		func expandVector(v: Vector2): 
			var newV: Vector2 = Vector2(0,0)
			if v.x > 0:
				newV.x = v.x + pixels
			elif v.x < 0:
				newV.x = v.x - pixels
				
			if v.y > 0:
				newV.y = v.y + pixels
			elif v.y < 0:
				newV.y = v.y - pixels
				
			return newV
		# expandVector
	)
# expandShape

