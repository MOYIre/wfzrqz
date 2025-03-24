extends CharacterBody2D

@export var speed: float = 150.0
@export var turn_smoothness: float = 20.0
@onready var animated_sprite: AnimatedSprite2D

var _target_direction := Vector2.DOWN
var _current_direction := Vector2.DOWN

func _ready() -> void:
	# 动态查找 AnimatedSprite2D 节点
	for child in get_children():
		if child is AnimatedSprite2D:
			animated_sprite = child
			break
	if animated_sprite == null:
		push_error("错误：AnimatedSprite2D 节点未找到！请检查场景树。")
		return
	print("动画精灵初始化成功，路径:", animated_sprite.get_path())

func _physics_process(delta: float) -> void:
	var input_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_direction * speed
	
	# 更新目标方向
	if input_direction.length() > 0:
		_target_direction = input_direction.normalized()
	
	# 平滑插值当前方向
	_current_direction = _current_direction.lerp(_target_direction, turn_smoothness * delta)
	
	# 根据当前方向播放动画（优先垂直方向）
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
