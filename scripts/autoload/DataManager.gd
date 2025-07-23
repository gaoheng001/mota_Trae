extends Node
# 数据管理器 - 负责加载和管理游戏数据资源

# 数据目录路径
const DATA_DIR: String = "res://resources/data/"

# 数据类型枚举
enum DataType {
	ENEMY,    # 敌人数据
	ITEM,     # 物品数据
	NPC,      # NPC数据
	FLOOR,    # 楼层数据
	DIALOG    # 对话数据
}

# 数据缓存
var enemy_data: Dictionary = {}
var item_data: Dictionary = {}
var npc_data: Dictionary = {}
var floor_data: Dictionary = {}
var dialog_data: Dictionary = {}

# 初始化
func _ready() -> void:
	print("数据管理器初始化")
	
	# 预加载基础数据
	preload_data()

# 预加载基础数据
func preload_data() -> void:
	# 加载敌人数据
	load_all_data(DataType.ENEMY)
	
	# 加载物品数据
	load_all_data(DataType.ITEM)
	
	# 加载NPC数据
	load_all_data(DataType.NPC)
	
	# 加载对话数据
	load_all_data(DataType.DIALOG)
	
	# 楼层数据通常按需加载
	print("基础数据预加载完成")

# 加载所有特定类型的数据
func load_all_data(data_type: DataType) -> void:
	# 获取数据目录路径
	var dir_path = get_data_dir_path(data_type)
	
	# 检查目录是否存在
	var dir = DirAccess.open(dir_path)
	if not dir:
		push_error("无法打开数据目录: " + dir_path)
		return
	
	# 遍历目录中的所有JSON文件
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".json") and not file_name.begins_with("."):
			var file_path = dir_path + file_name
			var id = file_name.get_basename()
			
			# 加载数据
			load_data(data_type, id, file_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

# 加载特定数据
func load_data(data_type: DataType, id: String, file_path: String = "") -> Dictionary:
	# 如果未指定文件路径，使用默认路径
	if file_path.is_empty():
		file_path = get_data_file_path(data_type, id)
	
	# 检查数据是否已缓存
	var cache = get_data_cache(data_type)
	if cache.has(id):
		return cache[id]
	
	# 加载JSON文件
	var json_data = load_json_file(file_path)
	if json_data.is_empty():
		push_error("无法加载数据: " + file_path)
		return {}
	
	# 确保数据包含ID
	if not json_data.has("id"):
		json_data["id"] = id
	
	# 缓存数据
	cache[id] = json_data
	
	return json_data

# 获取数据
func get_data(data_type: DataType, id: String) -> Dictionary:
	# 获取数据缓存
	var cache = get_data_cache(data_type)
	
	# 检查数据是否已缓存
	if cache.has(id):
		return cache[id]
	
	# 尝试加载数据
	return load_data(data_type, id)

# 获取所有特定类型的数据
func get_all_data(data_type: DataType) -> Dictionary:
	return get_data_cache(data_type)

# 获取数据目录路径
func get_data_dir_path(data_type: DataType) -> String:
	match data_type:
		DataType.ENEMY:
			return DATA_DIR + "enemies/"
		DataType.ITEM:
			return DATA_DIR + "items/"
		DataType.NPC:
			return DATA_DIR + "npcs/"
		DataType.FLOOR:
			return DATA_DIR + "floors/"
		DataType.DIALOG:
			return DATA_DIR + "dialogs/"
		_:
			return DATA_DIR

# 获取数据文件路径
func get_data_file_path(data_type: DataType, id: String) -> String:
	return get_data_dir_path(data_type) + id + ".json"

# 获取数据缓存
func get_data_cache(data_type: DataType) -> Dictionary:
	match data_type:
		DataType.ENEMY:
			return enemy_data
		DataType.ITEM:
			return item_data
		DataType.NPC:
			return npc_data
		DataType.FLOOR:
			return floor_data
		DataType.DIALOG:
			return dialog_data
		_:
			return {}

# 加载JSON文件
func load_json_file(file_path: String) -> Dictionary:
	# 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		push_error("文件不存在: " + file_path)
		return {}
	
	# 打开文件
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("无法打开文件: " + file_path)
		return {}
	
	# 读取文件内容
	var json_text = file.get_as_text()
	
	# 解析JSON
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		push_error("JSON解析错误: " + json.get_error_message() + " at line " + str(json.get_error_line()))
		return {}
	
	return json.get_data()

# 保存JSON文件
func save_json_file(file_path: String, data: Dictionary) -> bool:
	# 确保目录存在
	var dir_path = file_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		var dir_error = DirAccess.make_dir_recursive_absolute(dir_path)
		if dir_error != OK:
			push_error("无法创建目录: " + dir_path)
			return false
	
	# 将数据转换为JSON文本
	var json_text = JSON.stringify(data, "\t")
	
	# 打开文件进行写入
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		push_error("无法打开文件进行写入: " + file_path)
		return false
	
	# 写入数据
	file.store_string(json_text)
	
	return true

# 创建或更新数据
func create_or_update_data(data_type: DataType, id: String, data: Dictionary) -> bool:
	# 确保数据包含ID
	data["id"] = id
	
	# 获取数据缓存
	var cache = get_data_cache(data_type)
	
	# 更新缓存
	cache[id] = data
	
	# 保存到文件
	var file_path = get_data_file_path(data_type, id)
	return save_json_file(file_path, data)

# 删除数据
func delete_data(data_type: DataType, id: String) -> bool:
	# 获取数据缓存
	var cache = get_data_cache(data_type)
	
	# 从缓存中移除
	if cache.has(id):
		cache.erase(id)
	
	# 删除文件
	var file_path = get_data_file_path(data_type, id)
	if FileAccess.file_exists(file_path):
		var error = DirAccess.remove_absolute(file_path)
		return error == OK
	
	return true

# 清除缓存
func clear_cache(data_type: DataType = -1) -> void:
	if data_type == -1:
		# 清除所有缓存
		enemy_data.clear()
		item_data.clear()
		npc_data.clear()
		floor_data.clear()
		dialog_data.clear()
	else:
		# 清除特定类型的缓存
		var cache = get_data_cache(data_type)
		cache.clear()

# 重新加载数据
func reload_data(data_type: DataType = -1) -> void:
	# 清除缓存
	clear_cache(data_type)
	
	if data_type == -1:
		# 重新加载所有数据
		preload_data()
	else:
		# 重新加载特定类型的数据
		load_all_data(data_type)

# 获取敌人数据
func get_enemy(enemy_id: String) -> Dictionary:
	return get_data(DataType.ENEMY, enemy_id)

# 获取物品数据
func get_item(item_id: String) -> Dictionary:
	return get_data(DataType.ITEM, item_id)

# 获取NPC数据
func get_npc(npc_id: String) -> Dictionary:
	return get_data(DataType.NPC, npc_id)

# 获取楼层数据
func get_floor(floor_id: String) -> Dictionary:
	return get_data(DataType.FLOOR, floor_id)

# 获取对话数据
func get_dialog(dialog_id: String) -> Dictionary:
	return get_data(DataType.DIALOG, dialog_id)

# 获取所有敌人数据
func get_all_enemies() -> Dictionary:
	return enemy_data

# 获取所有物品数据
func get_all_items() -> Dictionary:
	return item_data

# 获取所有NPC数据
func get_all_npcs() -> Dictionary:
	return npc_data

# 获取所有楼层数据
func get_all_floors() -> Dictionary:
	return floor_data

# 获取所有对话数据
func get_all_dialogs() -> Dictionary:
	return dialog_data