extends CharacterBody2D

@export var speed: float = 150.0
@export var turn_smoothness: float = 20.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var backpack_ui = get_node("/root/BackpackUI")  # 获取背包UI

var _target_direction := Vector2.DOWN
var _current_direction := Vector2.DOWN

# 获取玩家当前位置
var player_position := Vector2.ZERO

func _ready():
	z_index = 1

func _physics_process(delta: float) -> void:
	var input_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_direction * speed
	
	if input_direction.length() > 0:
		_target_direction = input_direction.normalized()
	
	_current_direction = _current_direction.lerp(_target_direction, turn_smoothness * delta)
	
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
	
	move_and_slide()

# 玩家接触物品时拾取
func pickup_item(item):
	# 添加物品到背包
	if backpack_ui.backpack.has(item.item_type):
		backpack_ui.backpack[item.item_type] += 1
	else:
		backpack_ui.backpack[item.item_type] = 1
	
	# 更新背包UI
	backpack_ui.update_ui()
	
	# 销毁物品
	item.queue_free()
