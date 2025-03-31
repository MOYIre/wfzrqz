extends Node2D
@onready var dialog_box : Control = get_node("DialogBox")
@onready var player : Node2D = $Player  # 获取玩家节点

# 物品类型枚举
enum ItemType {
	MINERAL  # 只保留矿石类型
}

# 物品类
class Item:
	var item_type: ItemType
	var position: Vector2
	var sprite: Sprite2D

	# 构造函数
	func _init(new_item_type: ItemType, new_position: Vector2):
		self.item_type = new_item_type
		self.position = new_position
		self.sprite = Sprite2D.new()

		# 根据物品类型加载纹理
		match new_item_type:
			ItemType.MINERAL:
				# 生成矿石，纹理从0到10随机选择
				var mineral_index = randi_range(0, 10)
				self.sprite.texture = load("res://Res/Gem/" + str(mineral_index) + ".png")  # 使用load而非preload

		self.sprite.position = new_position

# 地图和物品设置
var tile_size = 16  # 每个图块的大小
var chunk_size = 10  # 每个区块的图块数
var generation_radius = 3  # 玩家周围生成区块的半径
var player_position = Vector2.ZERO  # 玩家当前位置

# 存储已生成的区块
var chunks = {}

# 定义地形类型
enum TerrainType {
	GRASS,
	WATER,
	MOUNTAIN,
	ROAD,
	FOREST,
	DESERT
}

# 创建并初始化 FastNoiseLite 噪声对象
var noise : FastNoiseLite
var noise_seed : int  # 用于保存噪声生成的种子

# 初始化噪声设置
func _ready():
	# 加载之前的游戏状态
	load_game_state()

	# 如果没有加载到种子，则生成一个新的种子
	if noise_seed == null:
		noise_seed = randi()

	noise = FastNoiseLite.new()
	noise.seed = noise_seed  # 使用加载的种子
	noise.noise_type = FastNoiseLite.TYPE_PERLIN  # 使用 Perlin 噪声
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM  # 使用 FBM 分形
	noise.frequency = 0.05  # 设置频率

# 生成区块
func generate_chunk(x, y):
	var chunk = Node2D.new()
	chunk.position = Vector2(x * chunk_size * tile_size, y * chunk_size * tile_size)

	# 生成区块内的图块
	for i in range(chunk_size):
		for j in range(chunk_size):
			var terrain_type = get_terrain_type(x * chunk_size + i, y * chunk_size + j)  # 获取地形类型
			var rect = ColorRect.new()  # 创建一个图块节点
			rect.size = Vector2(tile_size, tile_size)  # 设置图块大小
			rect.position = Vector2(i * tile_size, j * tile_size)  # 设置图块位置

			# 根据地形类型设置颜色
			match terrain_type:
				TerrainType.GRASS:
					rect.color = Color(0.3, 0.7, 0.3)  # 草地绿色
				TerrainType.WATER:
					rect.color = Color(0.1, 0.3, 0.7)  # 水域蓝色
				TerrainType.FOREST:
					rect.color = Color(0.2, 0.5, 0.2)  # 森林绿色
				TerrainType.MOUNTAIN:
					rect.color = Color(0.5, 0.5, 0.5)  # 山地灰色
					# 为山地添加碰撞体
					add_mountain_collision(i, j, chunk)
				TerrainType.DESERT:
					rect.color = Color(0.9, 0.7, 0.3)  # 沙漠黄色
				TerrainType.ROAD:
					rect.color = Color(0.8, 0.8, 0.2)  # 道路黄色

			# 将图块加入区块
			chunk.add_child(rect)

			# 在草地地形上随机生成矿石
			if terrain_type == TerrainType.GRASS and randf() < 0.01:  # 1%的概率生成矿石
				spawn_item(chunk, i, j)  # 在该位置放置矿石

	# 返回生成的区块
	return chunk

# 为山地添加碰撞体
func add_mountain_collision(i: int, j: int, chunk: Node2D):
	var static_body = StaticBody2D.new()
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	# 设置碰撞体的尺寸，这里直接设置宽高为图块的大小
	shape.extents = Vector2(tile_size / 2.0, tile_size / 2.0)  # 保证碰撞体的大小是图块的一半
	
	# 确保碰撞体的中心点对齐到图块的左上角
	collision_shape.shape = shape
	static_body.add_child(collision_shape)
	
	# 设置碰撞体的位置使其和图块对齐
	static_body.position = Vector2(i * tile_size + tile_size / 2.0, j * tile_size + tile_size / 2.0)  # 调整为图块的中心点
	
	chunk.add_child(static_body)  # 将碰撞体添加到区块

# 随机生成矿石
func spawn_item(chunk: Node2D, x: int, y: int):
	var item_type = ItemType.MINERAL  # 只生成矿石
	var item = Item.new(item_type, Vector2(x * tile_size + tile_size / 2.0, y * tile_size + tile_size / 2.0))
	item.sprite.scale = Vector2(0.03, 0.03)  # 缩小矿石的显示大小
	chunk.add_child(item.sprite)  # 将矿石添加到区块中

# 根据噪声值决定地形类型
func get_terrain_type(x, y) -> int:
	var noise_value = noise.get_noise_2d(x, y)
	noise_value = (noise_value + 1) / 2  # 正常化噪声值

	# 映射噪声值到不同的地形类型
	if noise_value < 0.4:
		return TerrainType.WATER  # 水域
	elif noise_value < 0.5:
		return TerrainType.GRASS  # 草地
	elif noise_value < 0.6:
		return TerrainType.FOREST  # 森林
	elif noise_value < 0.7:
		return TerrainType.DESERT  # 沙漠
	elif noise_value < 0.8:
		return TerrainType.MOUNTAIN  # 石头
	else:
		return TerrainType.ROAD  # 道路

# 更新地图：根据玩家的位置动态生成和销毁区块
func update_map():
	var player_chunk_x = int(player_position.x / (chunk_size * tile_size))
	var player_chunk_y = int(player_position.y / (chunk_size * tile_size))

	# 生成玩家周围的区块
	for x in range(player_chunk_x - generation_radius, player_chunk_x + generation_radius + 1):
		for y in range(player_chunk_y - generation_radius, player_chunk_y + generation_radius + 1):
			var chunk_pos = Vector2(x, y)
			if not chunks.has(chunk_pos):
				var chunk = generate_chunk(x, y)
				chunks[chunk_pos] = chunk
				add_child(chunk)

	# 卸载远离玩家的区块
	var to_remove = []
	for chunk_key in chunks.keys():
		var x = chunk_key.x
		var y = chunk_key.y
		if abs(x - player_chunk_x) > generation_radius or abs(y - player_chunk_y) > generation_radius:
			var chunk = chunks[chunk_key]
			to_remove.append(chunk_key)
			chunk.queue_free()

	for chunk_key in to_remove:
		chunks.erase(chunk_key)

# 保存游戏状态
func save_game_state():
	var game_data = {}
	game_data["player_position"] = player.position
	game_data["noise_seed"] = noise_seed  # 保存噪声种子
	game_data["chunks"] = []  # 存储生成的区块信息

	# 保存每个区块的位置信息
	for chunk_key in chunks.keys():
		# 保存 Vector2 的 x 和 y，而不是直接保存 Vector2
		game_data["chunks"].append({"x": chunk_key.x, "y": chunk_key.y})

	# 使用 JSON 类来序列化数据
	var json = JSON.new()
	var json_string = json.print(game_data)  # 将字典转换为 JSON 字符串

	# 保存到文件
	var file = FileAccess.open("user://save_game.json", FileAccess.WRITE)  # 使用 FileAccess.WRITE
	file.store_string(json_string)  # 将 JSON 字符串写入文件
	file.close()

# 加载游戏状态
func load_game_state():
	var file = FileAccess.open("user://save_game.json", FileAccess.READ)  # 打开文件
	if file:
		var json = JSON.new()
		var game_data = json.parse(file.get_as_text())  # 解析 JSON 字符串
		if game_data.error == OK:
			game_data = game_data.result
			if game_data.has("player_position"):
				player_position = game_data["player_position"]
				player.position = player_position  # 恢复玩家位置
			if game_data.has("noise_seed"):
				noise_seed = game_data["noise_seed"]  # 恢复噪声种子
			if game_data.has("chunks"):
				# 恢复已生成的区块
				for chunk_info in game_data["chunks"]:
					var chunk_pos = Vector2(chunk_info["x"], chunk_info["y"])
					if not chunks.has(chunk_pos):
						var chunk = generate_chunk(chunk_pos.x, chunk_pos.y)
						chunks[chunk_pos] = chunk
						add_child(chunk)

		file.close()

# 每帧更新地图
func _process(_delta):
	player_position = player.position  # 获取玩家位置
	update_map()  # 更新地图
