extends CharacterBody2D

@export var speed: float = 150.0
@export var turn_smoothness: float = 20.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var backpack_ui = get_node("/root/BackpackUI")  # 获取背包UI

var _target_direction := Vector2.ZERO
var _current_direction := Vector2.ZERO
var target_position := Vector2.ZERO  # 新增目标位置变量
var stop_threshold := 5.0  # 停止阈值，当角色离目标位置小于此值时停止移动

# 获取玩家当前位置
var player_position := Vector2.ZERO

# 变量来控制角色是否在移动
var is_moving := false

# 点击位置的指示器
var click_indicator: Polygon2D = null  # 使用 Polygon2D 来绘制菱形

func _ready():
	# 确保在游戏开始时玩家的速度为零，避免自动移动
	velocity = Vector2.ZERO  # 设置初始速度为零
	target_position = position  # 初始目标位置为玩家当前的位置
	z_index = 1  # 设置玩家的 z_index 为 1

# 监听鼠标点击事件
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 获取鼠标点击的世界坐标并设置目标位置
			target_position = get_global_mouse_position()
			is_moving = true  # 开始移动，播放移动动画
			
			# 如果点击指示器不存在，则创建一个新的菱形指示器
			if click_indicator == null:
				click_indicator = Polygon2D.new()  # 创建 Polygon2D 对象
				# 设置菱形的顶点，这里用的是一个缩小4倍的红色菱形
				click_indicator.polygon = PackedVector2Array([
					Vector2(0, -2.5),   # 上
					Vector2(2.5, 0),     # 右
					Vector2(0, 2.5),     # 下
					Vector2(-2.5, 0),    # 左
				])
				# 设置菱形的颜色为红色
				click_indicator.color = Color(1, 0, 0)  # 红色
				get_parent().add_child(click_indicator)  # 将指示器添加到场景中
			# 设置指示器位置
			click_indicator.position = target_position

# 更新玩家移动
func _physics_process(delta: float) -> void:
	# 先处理键盘输入
	var input_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if input_direction.length() > 0:
		# 如果有键盘输入，角色根据键盘输入移动
		velocity = input_direction * speed
		_target_direction = input_direction.normalized()
		target_position = position  # 键盘输入时取消鼠标目标
	elif target_position != position:
		# 如果没有键盘输入并且有鼠标点击目标位置
		var direction = (target_position - position).normalized()
		
		# 计算到目标位置的距离
		var distance_to_target = position.distance_to(target_position)
		
		# 如果距离目标位置小于阈值，停止移动
		if distance_to_target < stop_threshold:
			velocity = Vector2.ZERO  # 停止移动
			_target_direction = _current_direction  # 保持当前方向
			is_moving = false  # 停止移动，指示器移除
		else:
			velocity = direction * speed
			_target_direction = direction

	# 平滑转向，但只有在移动时才进行转向
	if velocity.length() > 0:
		_current_direction = _current_direction.lerp(_target_direction, turn_smoothness * delta)

	# 更新动画
	if animated_sprite:
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

	move_and_slide()  # 移动角色

	# 如果停止移动，移除指示器
	if not is_moving and click_indicator != null:
		click_indicator.queue_free()  # 移除指示器
		click_indicator = null  # 清空指示器引用
