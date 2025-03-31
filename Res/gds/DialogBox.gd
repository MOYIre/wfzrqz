extends Control

@onready var dialog_label : Label = $Panel/Label
@export var texts : Array = []  # 存储对话文本
var current_text_index : int = 0  # 当前显示的文本索引

# 控制对话框是否显示
var is_showing : bool = true

func _ready():
	# 隐藏对话框
	self.visible = false
	# 连接点击信号，继续显示下一条文本
	self.connect("input_event", Callable(self, "_on_dialog_click"))

# 启动对话框并显示第一条文本
func start_dialog(new_texts: Array):
	texts = new_texts
	current_text_index = 0
	dialog_label.text = texts[current_text_index]
	self.visible = true
	is_showing = true

# 玩家点击时继续显示下一条文本
func _on_dialog_click(_viewport, _event, _shape_idx):
	if not is_showing: return
	if _event is InputEventMouseButton and _event.button_index == MOUSE_BUTTON_LEFT and _event.pressed:
		# 如果是鼠标左键点击
		current_text_index += 1
		if current_text_index < texts.size():
			# 更新文本为下一条
			dialog_label.text = texts[current_text_index]
		else:
			# 所有文本显示完毕，关闭对话框
			self.visible = false
			is_showing = false
