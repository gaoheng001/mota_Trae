extends Node
# 游戏管理器 - 负责管理游戏的全局状态和流程

# 游戏状态枚举
enum GameState {
	MAIN_MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	DIALOG,
	BATTLE
}

# 当前游戏状态
var current_state: GameState = GameState.MAIN_MENU

# 游戏数据
var player_data: Dictionary = {
	"health": 1000,
	"max_health": 1000,
	"attack": 10,
	"defense": 10,
	"gold": 0,
	"yellow_keys": 0,
	"blue_keys": 0,
	"red_keys": 0,
	"level": 1,
	"exp": 0,
	"next_level_exp": 100
}

# 游戏进度数据
var game_progress: Dictionary = {
	"current_floor": 1,
	"highest_floor": 1,
	"visited_floors": [1],
	"defeated_bosses": [],
	"collected_items": [],
	"completed_events": []
}

# 信号
signal game_state_changed(new_state)
signal player_stats_changed(stats)
signal floor_changed(floor_number)

func _ready() -> void:
	# 初始化游戏
	print("游戏管理器初始化")
	
	# 连接信号
	game_state_changed.connect(_on_game_state_changed)
	player_stats_changed.connect(_on_player_stats_changed)
	floor_changed.connect(_on_floor_changed)

# 改变游戏状态
func change_game_state(new_state: GameState) -> void:
	if current_state != new_state:
		current_state = new_state
		game_state_changed.emit(new_state)

# 开始新游戏
func start_new_game() -> void:
	# 重置玩家数据
	reset_player_data()
	
	# 重置游戏进度
	reset_game_progress()
	
	# 切换到游戏状态
	change_game_state(GameState.PLAYING)
	
	# 加载初始楼层
	load_floor(1)

# 重置玩家数据
func reset_player_data() -> void:
	player_data = {
		"health": 1000,
		"max_health": 1000,
		"attack": 10,
		"defense": 10,
		"gold": 0,
		"yellow_keys": 0,
		"blue_keys": 0,
		"red_keys": 0,
		"level": 1,
		"exp": 0,
		"next_level_exp": 100
	}
	player_stats_changed.emit(player_data)

# 重置游戏进度
func reset_game_progress() -> void:
	game_progress = {
		"current_floor": 1,
		"highest_floor": 1,
		"visited_floors": [1],
		"defeated_bosses": [],
		"collected_items": [],
		"completed_events": []
	}

# 加载楼层
func load_floor(floor_number: int) -> void:
	if floor_number < 1:
		floor_number = 1
	
	game_progress["current_floor"] = floor_number
	
	# 更新最高楼层记录
	if floor_number > game_progress["highest_floor"]:
		game_progress["highest_floor"] = floor_number
	
	# 添加到已访问楼层
	if not floor_number in game_progress["visited_floors"]:
		game_progress["visited_floors"].append(floor_number)
	
	# 发送楼层变化信号
	floor_changed.emit(floor_number)
	
	# 这里应该调用地图管理器加载对应楼层
	# MapManager.load_floor(floor_number)

# 更新玩家属性
func update_player_stat(stat_name: String, value) -> void:
	if player_data.has(stat_name):
		player_data[stat_name] = value
		player_stats_changed.emit(player_data)

# 增加玩家属性值
func add_player_stat(stat_name: String, amount) -> void:
	if player_data.has(stat_name):
		player_data[stat_name] += amount
		player_stats_changed.emit(player_data)

# 减少玩家属性值
func reduce_player_stat(stat_name: String, amount) -> bool:
	if player_data.has(stat_name):
		if player_data[stat_name] >= amount:
			player_data[stat_name] -= amount
			player_stats_changed.emit(player_data)
			return true
	return false

# 检查玩家是否有足够的钥匙
func has_key(key_type: String) -> bool:
	var key_name = key_type + "_keys"
	if player_data.has(key_name):
		return player_data[key_name] > 0
	return false

# 使用钥匙
func use_key(key_type: String) -> bool:
	var key_name = key_type + "_keys"
	return reduce_player_stat(key_name, 1)

# 增加经验值并检查升级
func add_exp(amount: int) -> void:
	player_data["exp"] += amount
	
	# 检查是否升级
	while player_data["exp"] >= player_data["next_level_exp"]:
		level_up()
	
	player_stats_changed.emit(player_data)

# 玩家升级
func level_up() -> void:
	player_data["level"] += 1
	player_data["exp"] -= player_data["next_level_exp"]
	
	# 计算下一级所需经验值 (简单线性增长)
	player_data["next_level_exp"] = 100 * player_data["level"]
	
	# 增加属性
	player_data["max_health"] += 100
	player_data["health"] = player_data["max_health"] # 升级时恢复满血
	player_data["attack"] += 2
	player_data["defense"] += 2
	
	# 这里可以添加升级特效或提示
	print("玩家升级到 " + str(player_data["level"]) + " 级!")

# 游戏状态变化处理
func _on_game_state_changed(new_state) -> void:
	print("游戏状态变为: " + str(new_state))
	
	# 根据不同状态执行相应逻辑
	match new_state:
		GameState.MAIN_MENU:
			# 主菜单逻辑
			pass
		GameState.PLAYING:
			# 游戏进行中逻辑
			pass
		GameState.PAUSED:
			# 暂停逻辑
			pass
		GameState.GAME_OVER:
			# 游戏结束逻辑
			pass
		GameState.DIALOG:
			# 对话逻辑
			pass
		GameState.BATTLE:
			# 战斗逻辑
			pass

# 玩家属性变化处理
func _on_player_stats_changed(stats) -> void:
	# 这里可以更新UI显示
	pass

# 楼层变化处理
func _on_floor_changed(floor_number) -> void:
	print("当前楼层: " + str(floor_number))
	# 这里可以更新UI显示
	pass