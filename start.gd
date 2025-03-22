extends Node2D

@export var player_scene: PackedScene  # 拖入 player.tscn 资源
var _player: CharacterBody2D

func _ready() -> void:
	# 检查场景资源是否加载
	if player_scene == null:
		push_error("错误：Player Scene 未绑定！请检查导出变量。")
		return
	_spawn_player()

func _spawn_player() -> void:
	# 实例化角色
	_player = player_scene.instantiate()
	add_child(_player)
	
	# 设置初始位置（示例：地图中心）
	_player.global_position = Vector2(500, 300)
	
	# 绑定相机（如果有）
	if has_node("Camera2D"):
		$Camera2D.make_current()
		$Camera2D.position = _player.global_position
