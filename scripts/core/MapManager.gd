extends Node
# 地图管理器 - 负责管理游戏地图的生成、加载和交互

# 地图尺寸
var map_width: int = 11
var map_height: int = 11

# 当前地图数据
var current_map_data: Array = []

# 所有楼层的地图数据缓存
var floor_maps: Dictionary = {}

# 缓存每个楼层的实际状态（包括已击败的敌人、拾取的物品等）
var floor_states: Dictionary = {}

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
	NPC,
	KEY_YELLOW,
	KEY_BLUE,
	KEY_RED
}

# 信号
signal map_loaded(floor_number)
signal tile_changed(position, old_type, new_type)
signal player_moved(old_position, new_position)

# 初始化
func _ready() -> void:
	print("地图管理器初始化")
	# 连接战斗结束信号
	BattleManager.battle_ended.connect(_on_battle_ended)

# 加载指定楼层的地图
func load_floor(floor_number: int) -> void:
	print("加载第 " + str(floor_number) + " 层地图")
	
	# 检查是否已有该楼层的实际状态
	if floor_states.has(floor_number):
		# 加载已保存的楼层状态
		current_map_data = floor_states[floor_number].duplicate(true)
		print("加载已保存的楼层状态")
	elif floor_maps.has(floor_number):
		# 使用初始地图数据并保存为当前状态
		current_map_data = floor_maps[floor_number].duplicate(true)
		floor_states[floor_number] = current_map_data.duplicate(true)
		print("使用初始地图数据创建楼层状态")
	else:
		# 从文件加载或生成新地图
		var map_data = load_map_from_file(floor_number)
		if map_data.is_empty():
			# 如果文件不存在，则生成新地图
			map_data = generate_map(floor_number)
		
		# 缓存初始地图数据和当前状态
		floor_maps[floor_number] = map_data.duplicate(true)
		floor_states[floor_number] = map_data.duplicate(true)
		current_map_data = map_data
		print("生成新地图并创建楼层状态")
	
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
	var down_x = -1
	var down_y = -1
	
	if floor_number > 1:
		# 添加下楼梯（到上一层）
		down_x = rng.randi_range(1, map_width - 2)
		down_y = rng.randi_range(1, map_height - 2)
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
	
	# 添加钥匙
	var key_types = [TileType.KEY_YELLOW, TileType.KEY_BLUE, TileType.KEY_RED]
	var key_counts = [2, 1, 1]  # 黄钥匙多，红钥匙少
	
	for i in range(key_types.size()):
		var key_type = key_types[i]
		var count = key_counts[i]
		
		# 高层增加钥匙数量
		count += floor(floor_number / 10)
		
		for j in range(count):
			var key_x = rng.randi_range(1, map_width - 2)
			var key_y = rng.randi_range(1, map_height - 2)
			# 确保不覆盖其他特殊元素
			while (map_data[key_y][key_x] != TileType.FLOOR):
				key_x = rng.randi_range(1, map_width - 2)
				key_y = rng.randi_range(1, map_height - 2)
			map_data[key_y][key_x] = key_type

# 记录玩家来源方向（用于确定在新楼层的位置）
var player_came_from: String = ""  # "up" 表示从上层下来，"down" 表示从下层上来

# 设置玩家初始位置
func set_player_initial_position(floor_number: int) -> void:
	# 对于第一层，如果是游戏开始或没有来源方向，设置固定的起始位置
	if floor_number == 1 and player_came_from == "":
		player_position = Vector2i(5, 9)  # 底部中间位置
		print("第一层游戏开始位置: " + str(player_position))
		return
	
	# 根据来源方向和楼梯位置设置（包括第一层从上层下来的情况）
	var target_stair_type: int
	if player_came_from == "up":
		# 从上层下来，应该在上楼梯旁边
		target_stair_type = TileType.STAIRS_UP
		print("从上层下来，寻找上楼梯")
	elif player_came_from == "down":
		# 从下层上来，应该在下楼梯旁边
		target_stair_type = TileType.STAIRS_DOWN
		print("从下层上来，寻找下楼梯")
	else:
		# 默认情况，寻找上楼梯
		target_stair_type = TileType.STAIRS_UP
		print("默认情况，寻找上楼梯")
	
	for y in range(map_height):
		for x in range(map_width):
			if current_map_data[y][x] == target_stair_type:
				# 检查楼梯周围的地板，选择一个作为玩家位置
				var directions = [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]
				for dir in directions:
					var check_pos = Vector2i(x, y) + dir
					if is_valid_position(check_pos) and get_tile(check_pos) == TileType.FLOOR:
						player_position = check_pos
						print("玩家位置设置在楼梯旁边: " + str(player_position))
						return
				
				# 如果周围没有地板，就直接放在楼梯上
				player_position = Vector2i(x, y)
				print("玩家位置设置在楼梯上: " + str(player_position))
				return
	
	# 如果没有找到目标楼梯，使用默认位置
	if floor_number == 1:
		player_position = Vector2i(5, 9)  # 第一层的默认位置
		print("第一层使用默认位置: " + str(player_position))
	else:
		player_position = Vector2i(5, 5)  # 其他楼层的默认位置
		print("使用默认玩家位置: " + str(player_position))

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
		
		# 更新当前楼层的状态缓存
		var current_floor = GameManager.game_progress["current_floor"]
		if floor_states.has(current_floor):
			floor_states[current_floor][position.y][position.x] = tile_type
			print("更新楼层状态: 位置 " + str(position) + " 从 " + str(old_type) + " 变为 " + str(tile_type))
		
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
				print("使用黄钥匙开门")
				GameManager.use_key("yellow")
				set_tile(new_position, TileType.FLOOR)
			else:
				return false
				
		TileType.DOOR_BLUE:
			# 需要蓝钥匙
			if GameManager.has_key("blue"):
				print("使用蓝钥匙开门")
				GameManager.use_key("blue")
				set_tile(new_position, TileType.FLOOR)
			else:
				return false
				
		TileType.DOOR_RED:
			# 需要红钥匙
			if GameManager.has_key("red"):
				print("使用红钥匙开门")
				GameManager.use_key("red")
				set_tile(new_position, TileType.FLOOR)
			else:
				return false
				
		TileType.STAIRS_UP:
			# 上楼
			var current_floor = GameManager.game_progress["current_floor"]
			# 保存当前楼层状态
			save_current_floor_state()
			player_came_from = "down"  # 记录玩家从下层上来
			GameManager.load_floor(current_floor + 1)
			return true
			
		TileType.STAIRS_DOWN:
			# 下楼
			var current_floor = GameManager.game_progress["current_floor"]
			if current_floor > 1:
				# 保存当前楼层状态
				save_current_floor_state()
				player_came_from = "up"  # 记录玩家从上层下来
				GameManager.load_floor(current_floor - 1)
			return true
			
		TileType.ENEMY:
			# 遇到敌人，触发战斗
			var enemy_id = "slime"  # 这里应该根据楼层和位置确定敌人类型
			var current_floor = GameManager.game_progress["current_floor"]
			if current_floor >= 5:
				enemy_id = "orc"
			elif current_floor >= 10:
				enemy_id = "ghost"
			elif current_floor >= 15:
				enemy_id = "dragon"
			
			# 开始战斗
			BattleManager.start_battle(enemy_id)
			# 战斗结果会通过信号处理，如果胜利则移除敌人并移动玩家
			# 如果失败则玩家不移动
			return false  # 暂时阻止移动，等待战斗结果
			
		TileType.ITEM:
			# 拾取物品
			# 这里应该调用物品系统
			# 暂时简化处理：直接移除物品
			set_tile(new_position, TileType.FLOOR)
			
		TileType.KEY_YELLOW, TileType.KEY_BLUE, TileType.KEY_RED:
			# 钥匙拾取现在由GameWorld的物品系统处理
			# 这里只允许移动，不直接处理拾取
			pass
			
		TileType.NPC:
			# 与NPC对话
			# 这里应该触发对话系统
			return false
	
	# 更新玩家位置
	var old_position = player_position
	player_position = new_position
	player_moved.emit(old_position, new_position)
	
	return true

# 保存当前楼层状态
func save_current_floor_state() -> void:
	var current_floor = GameManager.game_progress["current_floor"]
	if current_floor > 0:
		floor_states[current_floor] = current_map_data.duplicate(true)
		print("保存第 " + str(current_floor) + " 层状态")

# 重置指定楼层状态（恢复到初始状态）
func reset_floor_state(floor_number: int) -> void:
	if floor_maps.has(floor_number):
		floor_states[floor_number] = floor_maps[floor_number].duplicate(true)
		print("重置第 " + str(floor_number) + " 层状态")

# 获取楼层是否已被访问过
func is_floor_visited(floor_number: int) -> bool:
	return floor_states.has(floor_number)

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

# 处理战斗结束
func _on_battle_ended(result: Dictionary) -> void:
	print("MapManager收到战斗结果: " + str(result))
	
	if result["victory"]:
		# 战斗胜利，只移除敌人，玩家保持在原位置
		var enemy_position = find_enemy_position_near_player()
		if enemy_position != Vector2i(-1, -1):
			# 移除敌人
			set_tile(enemy_position, TileType.FLOOR)
			print("战斗胜利！敌人已被移除，玩家保持在原位置: " + str(player_position))
	else:
		# 战斗失败，玩家不移动
		print("战斗失败！玩家保持在原位置")

# 查找玩家附近的敌人位置
func find_enemy_position_near_player() -> Vector2i:
	var directions = [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]
	for dir in directions:
		var check_pos = player_position + dir
		if is_valid_position(check_pos) and get_tile(check_pos) == TileType.ENEMY:
			return check_pos
	return Vector2i(-1, -1)  # 没有找到敌人