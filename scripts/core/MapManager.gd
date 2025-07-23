extends Node
# 地图管理器 - 负责管理游戏地图的生成、加载和交互

# 地图尺寸
var map_width: int = 11
var map_height: int = 11

# 当前地图数据
var current_map_data: Array = []

# 所有楼层的地图数据缓存
var floor_maps: Dictionary = {}

# 玩家在地图上的位置
var player_position: Vector2i = Vector2i(5, 5)

# 地图元素枚举
enum TileType {
	FLOOR,
	WALL,
	DOOR_YELLOW,
	DOOR_BLUE,
	DOOR_RED,
	STAIRS_UP,
	STAIRS_DOWN,
	ENEMY,
	ITEM,
	NPC
}

# 信号
signal map_loaded(floor_number)
signal tile_changed(position, old_type, new_type)
signal player_moved(old_position, new_position)

# 初始化
func _ready() -> void:
	print("地图管理器初始化")

# 加载指定楼层的地图
func load_floor(floor_number: int) -> void:
	print("加载第 " + str(floor_number) + " 层地图")
	
	# 检查是否已缓存该楼层地图
	if floor_maps.has(floor_number):
		current_map_data = floor_maps[floor_number].duplicate(true)
	else:
		# 从文件加载或生成新地图
		var map_data = load_map_from_file(floor_number)
		if map_data.is_empty():
			# 如果文件不存在，则生成新地图
			map_data = generate_map(floor_number)
		
		# 缓存地图数据
		floor_maps[floor_number] = map_data.duplicate(true)
		current_map_data = map_data
	
	# 设置玩家初始位置
	set_player_initial_position(floor_number)
	
	# 发送地图加载信号
	map_loaded.emit(floor_number)

# 从文件加载地图数据
func load_map_from_file(floor_number: int) -> Array:
	var map_data = []
	
	# 构建文件路径
	var file_path = "res://resources/data/maps/floor_" + str(floor_number) + ".json"
	
	# 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		return []
	
	# 打开文件
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return []
	
	# 读取JSON数据
	var json_text = file.get_as_text()
	var json_data = JSON.parse_string(json_text)
	
	# 验证数据格式
	if not json_data is Dictionary or not json_data.has("map_data"):
		return []
	
	# 提取地图数据
	map_data = json_data["map_data"]
	
	return map_data

# 生成新地图
func generate_map(floor_number: int) -> Array:
	print("生成第 " + str(floor_number) + " 层地图")
	
	# 创建空地图
	var map_data = []
	for y in range(map_height):
		var row = []
		for x in range(map_width):
			# 边界设为墙
			if x == 0 or y == 0 or x == map_width - 1 or y == map_height - 1:
				row.append(TileType.WALL)
			else:
				# 内部区域设为地板
				row.append(TileType.FLOOR)
		map_data.append(row)
	
	# 根据楼层添加特定元素
	add_floor_specific_elements(map_data, floor_number)
	
	return map_data

# 添加楼层特定元素
func add_floor_specific_elements(map_data: Array, floor_number: int) -> void:
	# 这里应该根据楼层号添加不同的元素
	# 例如：墙壁、门、楼梯、敌人、物品等
	
	# 简单示例：添加一些随机墙
	var rng = RandomNumberGenerator.new()
	rng.seed = floor_number * 1000  # 使用楼层号作为种子，确保同一楼层生成相同的地图
	
	# 添加一些随机墙
	var wall_count = 10 + floor_number * 2  # 随楼层增加墙的数量
	for i in range(wall_count):
		var x = rng.randi_range(2, map_width - 3)
		var y = rng.randi_range(2, map_height - 3)
		map_data[y][x] = TileType.WALL
	
	# 添加上下楼梯
	if floor_number > 1:
		# 添加下楼梯（到上一层）
		var down_x = rng.randi_range(1, map_width - 2)
		var down_y = rng.randi_range(1, map_height - 2)
		map_data[down_y][down_x] = TileType.STAIRS_DOWN
	
	# 添加上楼梯（到下一层）
	var up_x = rng.randi_range(1, map_width - 2)
	var up_y = rng.randi_range(1, map_height - 2)
	# 确保上下楼梯不在同一位置
	while floor_number > 1 and up_x == down_x and up_y == down_y:
		up_x = rng.randi_range(1, map_width - 2)
		up_y = rng.randi_range(1, map_height - 2)
	map_data[up_y][up_x] = TileType.STAIRS_UP
	
	# 添加一些门
	var door_types = [TileType.DOOR_YELLOW, TileType.DOOR_BLUE, TileType.DOOR_RED]
	var door_counts = [3, 2, 1]  # 黄门多，红门少
	
	for i in range(door_types.size()):
		var door_type = door_types[i]
		var count = door_counts[i]
		
		# 高层增加门的数量
		count += floor(floor_number / 5)
		
		for j in range(count):
			var door_x = rng.randi_range(1, map_width - 2)
			var door_y = rng.randi_range(1, map_height - 2)
			# 确保不覆盖楼梯
			while (map_data[door_y][door_x] != TileType.FLOOR):
				door_x = rng.randi_range(1, map_width - 2)
				door_y = rng.randi_range(1, map_height - 2)
			map_data[door_y][door_x] = door_type
	
	# 添加一些敌人
	var enemy_count = 5 + floor_number  # 随楼层增加敌人数量
	for i in range(enemy_count):
		var enemy_x = rng.randi_range(1, map_width - 2)
		var enemy_y = rng.randi_range(1, map_height - 2)
		# 确保不覆盖其他特殊元素
		while (map_data[enemy_y][enemy_x] != TileType.FLOOR):
			enemy_x = rng.randi_range(1, map_width - 2)
			enemy_y = rng.randi_range(1, map_height - 2)
		map_data[enemy_y][enemy_x] = TileType.ENEMY
	
	# 添加一些物品
	var item_count = 3 + floor(floor_number / 2)  # 随楼层增加物品数量
	for i in range(item_count):
		var item_x = rng.randi_range(1, map_width - 2)
		var item_y = rng.randi_range(1, map_height - 2)
		# 确保不覆盖其他特殊元素
		while (map_data[item_y][item_x] != TileType.FLOOR):
			item_x = rng.randi_range(1, map_width - 2)
			item_y = rng.randi_range(1, map_height - 2)
		map_data[item_y][item_x] = TileType.ITEM

# 设置玩家初始位置
func set_player_initial_position(floor_number: int) -> void:
	# 对于第一层，设置固定的起始位置
	if floor_number == 1:
		player_position = Vector2i(5, 9)  # 底部中间位置
		return
	
	# 对于其他楼层，根据楼梯位置设置
	for y in range(map_height):
		for x in range(map_width):
			# 如果是从下一层下来，玩家应该在上楼梯旁边
			if current_map_data[y][x] == TileType.STAIRS_UP:
				# 检查楼梯周围的地板，选择一个作为玩家位置
				var directions = [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]
				for dir in directions:
					var check_pos = Vector2i(x, y) + dir
					if is_valid_position(check_pos) and get_tile(check_pos) == TileType.FLOOR:
						player_position = check_pos
						return
				
				# 如果周围没有地板，就直接放在楼梯上
				player_position = Vector2i(x, y)
				return

# 获取指定位置的地图元素
func get_tile(position: Vector2i) -> int:
	if is_valid_position(position):
		return current_map_data[position.y][position.x]
	return TileType.WALL  # 默认为墙

# 设置指定位置的地图元素
func set_tile(position: Vector2i, tile_type: int) -> void:
	if is_valid_position(position):
		var old_type = current_map_data[position.y][position.x]
		current_map_data[position.y][position.x] = tile_type
		tile_changed.emit(position, old_type, tile_type)

# 检查位置是否有效
func is_valid_position(position: Vector2i) -> bool:
	return position.x >= 0 and position.x < map_width and position.y >= 0 and position.y < map_height

# 移动玩家
func move_player(direction: Vector2i) -> bool:
	var new_position = player_position + direction
	
	# 检查新位置是否有效
	if not is_valid_position(new_position):
		return false
	
	# 获取目标位置的地图元素
	var target_tile = get_tile(new_position)
	
	# 根据目标位置的元素类型处理移动
	match target_tile:
		TileType.WALL:
			# 不能穿墙
			return false
			
		TileType.DOOR_YELLOW:
			# 需要黄钥匙
			if GameManager.has_key("yellow"):
				GameManager.use_key("yellow")
				set_tile(new_position, TileType.FLOOR)
			else:
				return false
				
		TileType.DOOR_BLUE:
			# 需要蓝钥匙
			if GameManager.has_key("blue"):
				GameManager.use_key("blue")
				set_tile(new_position, TileType.FLOOR)
			else:
				return false
				
		TileType.DOOR_RED:
			# 需要红钥匙
			if GameManager.has_key("red"):
				GameManager.use_key("red")
				set_tile(new_position, TileType.FLOOR)
			else:
				return false
				
		TileType.STAIRS_UP:
			# 上楼
			var current_floor = GameManager.game_progress["current_floor"]
			GameManager.load_floor(current_floor + 1)
			return true
			
		TileType.STAIRS_DOWN:
			# 下楼
			var current_floor = GameManager.game_progress["current_floor"]
			if current_floor > 1:
				GameManager.load_floor(current_floor - 1)
			return true
			
		TileType.ENEMY:
			# 与敌人战斗
			# 这里应该调用战斗系统
			# 暂时简化处理：直接移除敌人
			set_tile(new_position, TileType.FLOOR)
			
		TileType.ITEM:
			# 拾取物品
			# 这里应该调用物品系统
			# 暂时简化处理：直接移除物品
			set_tile(new_position, TileType.FLOOR)
			
		TileType.NPC:
			# 与NPC对话
			# 这里应该触发对话系统
			return false
	
	# 更新玩家位置
	var old_position = player_position
	player_position = new_position
	player_moved.emit(old_position, new_position)
	
	return true

# 保存地图数据到文件
func save_map_to_file(floor_number: int, map_data: Array) -> bool:
	# 构建文件路径
	var dir_path = "user://maps/"
	var file_path = dir_path + "floor_" + str(floor_number) + ".json"
	
	# 确保目录存在
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("maps"):
		dir.make_dir("maps")
	
	# 准备JSON数据
	var json_data = {
		"floor_number": floor_number,
		"map_width": map_width,
		"map_height": map_height,
		"map_data": map_data
	}
	
	# 转换为JSON字符串
	var json_string = JSON.stringify(json_data)
	
	# 写入文件
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		return false
	
	file.store_string(json_string)
	return true