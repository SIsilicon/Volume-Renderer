extends Camera

const UP = Vector3(0, 1, 0)
const camera_speed = 5.0

var distance
func _ready():
	distance = translation.length()

func _physics_process(delta):
	
	var speed = delta * camera_speed
	
	var xform = get_transform()
	var upangle = acos(-xform.basis[2].dot(UP))
	
	if Input.is_key_pressed(KEY_A):
		translation -= xform.basis[0] * speed * sin(upangle)
	if Input.is_key_pressed(KEY_D):
		translation += xform.basis[0] * speed * sin(upangle)
	if Input.is_key_pressed(KEY_S):
		translation -= xform.basis[1] * speed
	if Input.is_key_pressed(KEY_W):
		translation += xform.basis[1] * speed
	
	translation = translation.normalized() * distance
	look_at($"../".translation, UP)
