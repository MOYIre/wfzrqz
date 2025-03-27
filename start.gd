extends Node2D

# 常量设置
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

# 初始化噪声设置
func _ready():

	noise = FastNoiseLite.new()
	noise.seed = randi()  # 随机种子
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
			var rect = ColorRect.new()  # 创建图块节点
			rect.size = Vector2(tile_size, tile_size)  # 设置图块大小
			rect.position = Vector2(i * tile_size, j * tile_size)  # 设置图块位置
			
			# 根据地形类型设置图块颜色并处理碰撞
			setup_terrain(rect, terrain_type, i, j, chunk)
	
	return chunk

# 根据地形类型设置图块颜色并处理碰撞
func setup_terrain(rect: ColorRect, terrain_type: int, i: int, j: int, chunk: Node2D):
	match terrain_type:
		TerrainType.GRASS:
			rect.color = Color(0.3, 0.7, 0.3)  # 草地绿色
		TerrainType.WATER:
			rect.color = Color(0.1, 0.3, 0.7)  # 水域蓝色
		TerrainType.ROAD:
			rect.color = Color(0.8, 0.8, 0.2)  # 道路黄色
		TerrainType.MOUNTAIN:
			rect.color = Color(0.5, 0.5, 0.5)  # 山地灰色
			# 为山地添加碰撞体
			add_mountain_collision(i, j, chunk)
		TerrainType.FOREST:
			rect.color = Color(0.2, 0.5, 0.2)  # 森林绿色
		TerrainType.DESERT:
			rect.color = Color(0.9, 0.7, 0.3)  # 沙漠黄色

	# 将图块加入区块
	chunk.add_child(rect)

# 为山地添加碰撞体
func add_mountain_collision(i: int, j: int, chunk: Node2D):
	var static_body = StaticBody2D.new()
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	# 设置碰撞体的尺寸，这里直接设置宽高为图块的大小
	shape.extents = Vector2(tile_size / 2, tile_size / 2)  # 保证碰撞体的大小是图块的一半
	
	# 确保碰撞体的中心点对齐到图块的左上角
	collision_shape.shape = shape
	static_body.add_child(collision_shape)
	
	# 设置碰撞体的位置使其和图块对齐
	static_body.position = Vector2(i * tile_size + tile_size / 2, j * tile_size + tile_size / 2)  # 调整为图块的中心点
	
	chunk.add_child(static_body)  # 将碰撞体添加到区块

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
		return TerrainType.MOUNTAIN   # 石头
	else:
		return TerrainType.ROAD  # 道路

# 更新地图：根据玩家的位置动态生成和销毁区块
func update_map():
	# 获取玩家当前所在区块的坐标
	var player_chunk_x = int(player_position.x / (chunk_size * tile_size))
	var player_chunk_y = int(player_position.y / (chunk_size * tile_size))
	
	# 生成玩家周围的区块
	for x in range(player_chunk_x - generation_radius, player_chunk_x + generation_radius + 1):
		for y in range(player_chunk_y - generation_radius, player_chunk_y + generation_radius + 1):
			var chunk_pos = Vector2(x, y)
			# 如果该区块未生成，则生成并加入场景
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
			chunk.queue_free()  # 销毁该区块

	# 从已生成区块字典中删除销毁的区块
	for chunk_key in to_remove:
		chunks.erase(chunk_key)

# 每帧更新地图
func _process(delta):
	player_position = $Player.position  # 获取玩家位置
	update_map()  # 更新地图
	$Player.z_index = 1  # 确保玩家位于图块之上
