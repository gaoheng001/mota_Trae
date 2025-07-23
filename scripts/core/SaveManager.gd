extends Node
# 存档管理器 - 负责处理游戏的存档和读档功能

# 存档槽位数量
const MAX_SAVE_SLOTS: int = 3

# 存档信息缓存
var save_info_cache: Dictionary = {}

# 信号
signal game_saved(slot, save_info)
signal game_loaded(slot, save_info)
signal save_deleted(slot)

# 初始化
func _ready() -> void:
	print("存档管理器初始化")
	# 加载所有存档信息
	load_all_save_info()

# 加载所有存档信息
func load_all_save_info() -> void:
	save_info_cache.clear()
	
	for slot in range(MAX_SAVE_SLOTS):
		var save_info = get_save_info(slot)
		if not save_info.is_empty():
			save_info_cache[slot] = save_info

# 获取存档信息（不加载完整存档）
func get_save_info(slot: int) -> Dictionary:
	var save_path = "user://save_" + str(slot) + ".json"
	
	if not FileAccess.file_exists(save_path):
		return {}
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return {}
	
	var json_text = file.get_as_text()
	file.close()
	
	var json_data = JSON.parse_string(json_text)
	if not json_data is Dictionary:
		return {}
	
	# 只返回存档的基本信息，不包含完整游戏数据
	return {
		"slot": slot,
		"timestamp": json_data.get("timestamp", 0),
		"player_level": json_data.get("player", {}).get("level", 1),
		"current_floor": json_data.get("game_progress", {}).get("current_floor", 1),
		"play_time": json_data.get("play_time", 0),
		"save_date": Time.get_datetime_string_from_unix_time(json_data.get("timestamp", 0))
	}

# 保存游戏
func save_game(slot: int) -> bool:
	# 准备存档数据
	var save_data = {
		"player": GameManager.player_data.duplicate(true),
		"game_progress": GameManager.game_progress.duplicate(true),
		"timestamp": Time.get_unix_time_from_system(),
		"play_time": 0,  # 这里应该记录游戏时间
		"version": "1.0.0"  # 游戏版本
	}
	
	# 将数据转换为JSON
	var json_text = JSON.stringify(save_data)
	
	# 保存到文件
	var save_path = "user://save_" + str(slot) + ".json"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		print("保存游戏失败：无法写入文件")
		return false
	
	file.store_string(json_text)
	file.close()
	
	# 更新存档信息缓存
	var save_info = get_save_info(slot)
	save_info_cache[slot] = save_info
	
	# 发送保存成功信号
	game_saved.emit(slot, save_info)
	
	print("游戏已保存到槽位 " + str(slot))
	return true

# 加载游戏
func load_game(slot: int) -> bool:
	var save_path = "user://save_" + str(slot) + ".json"
	
	if not FileAccess.file_exists(save_path):
		print("加载游戏失败：存档文件不存在")
		return false
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		print("加载游戏失败：无法读取文件")
		return false
	
	var json_text = file.get_as_text()
	file.close()
	
	var json_data = JSON.parse_string(json_text)
	if not json_data is Dictionary:
		print("加载游戏失败：存档数据格式错误")
		return false
	
	# 检查版本兼容性
	var save_version = json_data.get("version", "1.0.0")
	# 这里可以添加版本兼容性检查
	
	# 加载玩家数据
	if json_data.has("player"):
		GameManager.player_data = json_data["player"].duplicate(true)
	
	# 加载游戏进度
	if json_data.has("game_progress"):
		GameManager.game_progress = json_data["game_progress"].duplicate(true)
	
	# 通知游戏管理器数据已更新
	GameManager.player_stats_changed.emit(GameManager.player_data)
	
	# 加载当前楼层
	var current_floor = GameManager.game_progress["current_floor"]
	GameManager.load_floor(current_floor)
	
	# 切换到游戏状态
	GameManager.change_game_state(GameManager.GameState.PLAYING)
	
	# 发送加载成功信号
	game_loaded.emit(slot, save_info_cache.get(slot, {}))
	
	print("游戏已从槽位 " + str(slot) + " 加载")
	return true

# 删除存档
func delete_save(slot: int) -> bool:
	var save_path = "user://save_" + str(slot) + ".json"
	
	if not FileAccess.file_exists(save_path):
		return false
	
	var dir = DirAccess.open("user://")
	if not dir:
		return false
	
	var result = dir.remove(save_path)
	if result == OK:
		# 从缓存中移除
		if save_info_cache.has(slot):
			save_info_cache.erase(slot)
		
		# 发送删除信号
		save_deleted.emit(slot)
		
		print("已删除槽位 " + str(slot) + " 的存档")
		return true
	return false

# 检查存档是否存在
func save_exists(slot: int) -> bool:
	return save_info_cache.has(slot)

# 获取所有存档信息
func get_all_save_info() -> Dictionary:
	return save_info_cache.duplicate(true)

# 自动保存
func auto_save() -> bool:
	# 使用特殊的自动存档槽位
	return save_game(MAX_SAVE_SLOTS - 1)

# 快速保存
func quick_save() -> bool:
	# 使用最后一个普通存档槽位作为快速存档
	return save_game(MAX_SAVE_SLOTS - 2)

# 快速加载
func quick_load() -> bool:
	# 从快速存档槽位加载
	return load_game(MAX_SAVE_SLOTS - 2)