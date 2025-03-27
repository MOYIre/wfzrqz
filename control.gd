extends CharacterBody2D

@export var speed: float = 150.0
@export var turn_smoothness: float = 20.0
@export var min_distance_from_rocks: float = 5.0  # 距离石头的最小距离

@onready var animated_sprite: AnimatedSprite2D

var _target_direction := Vector2.DOWN
var _current_direction := Vector2.DOWN
var player_spawn_position := Vector2.ZERO

# 初始化
func _ready() -> void:
	# 确保玩家不出生在石头上
	player_spawn_position = find_valid_spawn_position()
	position = player_spawn_position

	# 动画初始化
	for child in get_children():
		if child is AnimatedSprite2D:
			animated_sprite = child
			break
	if animated_sprite == null:
		push_error("错误。")
		return

	z_index = 1

# 获取出生位置
func find_valid_spawn_position() -> Vector2:
	var spawn_position := Vector2.ZERO
	var spawn_valid := false
	
	while not spawn_valid:
		spawn_position = Vector2(randi_range(0, 100), randi_range(0, 100))  # 随机坐标
		
		# 这里只需要检查出生位置是否是石头
		if not is_rock(spawn_position):
			spawn_valid = true
	
	return spawn_position

# 判断是否是石头
func is_rock(position: Vector2) -> bool:
	var noise_value = (FastNoiseLite.new().get_noise_2d(position.x, position.y) + 1) / 2
	return noise_value > 0.7  # 如果噪声值大于 0.7，认为是石头

# 每帧更新
func _physics_process(delta: float) -> void:
	var input_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_direction * speed
	
	if input_direction.length() > 0:
		_target_direction = input_direction.normalized()
	
	_current_direction = _current_direction.lerp(_target_direction, turn_smoothness * delta)
	
	if animated_sprite != null:
		if abs(_current_direction.y) > abs(_current_direction.x):
			if _current_direction.y > 0:
				animated_sprite.play("down")
			else:
				animated_sprite.play("up")
		else:
			if _current_direction.x > 0:
				animated_sprite.play("right")
			else:
				animated_sprite.play("left")
	
	move_and_slide()
