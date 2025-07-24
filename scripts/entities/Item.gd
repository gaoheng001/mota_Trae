extends Node2D
# 物品基类 - 定义游戏中各种物品的基本属性和行为

# 物品类型枚举
enum ItemType {
	KEY,        # 钥匙
	POTION,     # 药水
	EQUIPMENT,  # 装备
	TREASURE,   # 宝物
	SPECIAL     # 特殊物品
}

# 物品ID
@export var item_id: String = ""

# 物品类型
@export var item_type: ItemType = ItemType.POTION

# 物品数据
var item_data: Dictionary = {}

# 是否已初始化
var is_initialized: bool = false

# 信号
signal item_clicked(item)
signal item_collected(item)

# 创建简单纹理
func create_simple_texture() -> void:
	# 创建一个简单的物品纹理（绿色方块代表物品）
	var image = Image.create(64, 64, false, Image.FORMAT_RGB8)
	image.fill(Color(0.2, 1.0, 0.2))  # 绿色
	
	# 添加一些细节（白色边框）
	for x in range(64):
		for y in range(64):
			if x < 2 or x >= 62 or y < 2 or y >= 62:
				image.set_pixel(x, y, Color(0.9, 0.9, 0.9))  # 白色边框
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	$Sprite2D.texture = texture

# 初始化
func _ready() -> void:
	# 创建简单纹理
	create_simple_texture()
	
	# 加载物品数据
	load_item_data()
	
	# 设置点击区域
	var click_area = $ClickArea if has_node("ClickArea") else null
	if click_area:
		click_area.input_event.connect(_on_click_area_input_event)

# 加载物品数据
func load_item_data() -> void:
	# 从物品数据库加载物品数据
	item_data = get_item_data_from_database(item_id)
	
	if item_data.is_empty():
		push_error("无法加载物品数据: " + item_id)
		return
	
	# 更新物品显示
	update_appearance()
	
	# 标记为已初始化
	is_initialized = true

# 从数据库获取物品数据
func get_item_data_from_database(id: String) -> Dictionary:
	# 这里应该从数据文件加载物品数据
	# 暂时使用硬编码的示例数据
	
	# 基础物品数据库
	var items_database = {
		# 钥匙
		"yellow_key": {
			"id": "yellow_key",
			"name": "黄钥匙",
			"type": ItemType.KEY,
			"description": "用于打开黄色的门",
			"effect": {"yellow_keys": 1}
		},
		"blue_key": {
			"id": "blue_key",
			"name": "蓝钥匙",
			"type": ItemType.KEY,
			"description": "用于打开蓝色的门",
			"effect": {"blue_keys": 1}
		},
		"red_key": {
			"id": "red_key",
			"name": "红钥匙",
			"type": ItemType.KEY,
			"description": "用于打开红色的门",
			"effect": {"red_keys": 1}
		},
		
		# 药水
		"small_health_potion": {
			"id": "small_health_potion",
			"name": "小型生命药水",
			"type": ItemType.POTION,
			"description": "恢复200点生命值",
			"effect": {"health": 200}
		},
		"medium_health_potion": {
			"id": "medium_health_potion",
			"name": "中型生命药水",
			"type": ItemType.POTION,
			"description": "恢复500点生命值",
			"effect": {"health": 500}
		},
		"large_health_potion": {
			"id": "large_health_potion",
			"name": "大型生命药水",
			"type": ItemType.POTION,
			"description": "恢复1000点生命值",
			"effect": {"health": 1000}
		},
		"attack_potion": {
			"id": "attack_potion",
			"name": "攻击药水",
			"type": ItemType.POTION,
			"description": "永久增加10点攻击力",
			"effect": {"attack": 10}
		},
		"defense_potion": {
			"id": "defense_potion",
			"name": "防御药水",
			"type": ItemType.POTION,
			"description": "永久增加10点防御力",
			"effect": {"defense": 10}
		},
		
		# 装备
		"iron_sword": {
			"id": "iron_sword",
			"name": "铁剑",
			"type": ItemType.EQUIPMENT,
			"description": "增加20点攻击力",
			"effect": {"attack": 20},
			"equipment_type": "weapon"
		},
		"steel_sword": {
			"id": "steel_sword",
			"name": "钢剑",
			"type": ItemType.EQUIPMENT,
			"description": "增加40点攻击力",
			"effect": {"attack": 40},
			"equipment_type": "weapon"
		},
		"iron_shield": {
			"id": "iron_shield",
			"name": "铁盾",
			"type": ItemType.EQUIPMENT,
			"description": "增加20点防御力",
			"effect": {"defense": 20},
			"equipment_type": "shield"
		},
		"steel_shield": {
			"id": "steel_shield",
			"name": "钢盾",
			"type": ItemType.EQUIPMENT,
			"description": "增加40点防御力",
			"effect": {"defense": 40},
			"equipment_type": "shield"
		},
		
		# 宝物
		"gold_coin": {
			"id": "gold_coin",
			"name": "金币",
			"type": ItemType.TREASURE,
			"description": "可用于购买物品",
			"effect": {"gold": 10}
		},
		"gem": {
			"id": "gem",
			"name": "宝石",
			"type": ItemType.TREASURE,
			"description": "珍贵的宝石，可用于特殊交易",
			"effect": {"gem": 1}
		},
		
		# 特殊物品
		"cross": {
			"id": "cross",
			"name": "十字架",
			"type": ItemType.SPECIAL,
			"description": "可以查看敌人的属性",
			"effect": {"ability": "view_enemy_stats"}
		},
		"flying_shoes": {
			"id": "flying_shoes",
			"name": "飞行靴",
			"type": ItemType.SPECIAL,
			"description": "可以在楼层间自由移动",
			"effect": {"ability": "fly_between_floors"}
		}
	}
	
	# 检查物品ID是否存在
	if items_database.has(id):
		return items_database[id]
	
	# 如果找不到指定ID，返回随机物品（用于测试）
	if id.begins_with("random"):
		# 随机选择一个物品
		var keys = items_database.keys()
		var random_index = randi() % keys.size()
		return items_database[keys[random_index]]
	
	# 如果都不匹配，返回空字典
	return {}

# 更新物品外观
func update_appearance() -> void:
	# 更新物品精灵
	var sprite = $Sprite2D if has_node("Sprite2D") else null
	if sprite:
		# 这里应该根据物品ID加载对应的纹理
		# 例如：sprite.texture = load("res://assets/sprites/items/" + item_id + ".png")
		pass

# 获取物品属性
func get_property(property_name: String, default_value = null):
	if item_data.has(property_name):
		return item_data[property_name]
	return default_value

# 使用物品
func use() -> bool:
	if not is_initialized:
		return false
	
	# 根据物品类型执行不同的效果
	match item_type:
		ItemType.KEY:
			return use_key()
		ItemType.POTION:
			return use_potion()
		ItemType.EQUIPMENT:
			return equip()
		ItemType.TREASURE:
			return collect_treasure()
		ItemType.SPECIAL:
			return use_special_item()
		_:
			return false

# 使用钥匙
func use_key() -> bool:
	if not item_data.has("effect"):
		return false
	
	# 增加对应类型的钥匙数量
	for key_type in item_data["effect"]:
		GameManager.add_player_stat(key_type, item_data["effect"][key_type])
	
	# 发送物品收集信号
	item_collected.emit(self)
	
	return true

# 使用药水
func use_potion() -> bool:
	if not item_data.has("effect"):
		return false
	
	# 应用药水效果
	for stat_name in item_data["effect"]:
		if stat_name == "health":
			# 对于生命值，需要确保不超过最大值
			var current_health = GameManager.player_data["health"]
			var max_health = GameManager.player_data["max_health"]
			var new_health = min(current_health + item_data["effect"][stat_name], max_health)
			GameManager.update_player_stat("health", new_health)
		else:
			# 对于其他属性，直接增加
			GameManager.add_player_stat(stat_name, item_data["effect"][stat_name])
	
	# 发送物品收集信号
	item_collected.emit(self)
	
	return true

# 装备物品
func equip() -> bool:
	if not item_data.has("effect") or not item_data.has("equipment_type"):
		return false
	
	# 应用装备效果
	for stat_name in item_data["effect"]:
		GameManager.add_player_stat(stat_name, item_data["effect"][stat_name])
	
	# 记录已装备的物品
	# 这里应该处理装备替换逻辑
	# 例如：GameManager.equip_item(item_data["equipment_type"], item_id)
	
	# 发送物品收集信号
	item_collected.emit(self)
	
	return true

# 收集宝物
func collect_treasure() -> bool:
	if not item_data.has("effect"):
		return false
	
	# 应用宝物效果
	for stat_name in item_data["effect"]:
		GameManager.add_player_stat(stat_name, item_data["effect"][stat_name])
	
	# 发送物品收集信号
	item_collected.emit(self)
	
	return true

# 使用特殊物品
func use_special_item() -> bool:
	if not item_data.has("effect") or not item_data["effect"].has("ability"):
		return false
	
	# 获取特殊能力
	var ability = item_data["effect"]["ability"]
	
	# 根据不同的特殊能力执行不同的效果
	match ability:
		"view_enemy_stats":
			# 启用查看敌人属性的能力
			print("获得查看敌人属性的能力")
			# 这里应该设置一个全局标志
			# 例如：GameManager.set_ability_enabled("view_enemy_stats", true)
			
		"fly_between_floors":
			# 启用楼层间飞行的能力
			print("获得楼层间飞行的能力")
			# 这里应该设置一个全局标志
			# 例如：GameManager.set_ability_enabled("fly_between_floors", true)
			
		_:
			return false
	
	# 发送物品收集信号
	item_collected.emit(self)
	
	return true

# 显示物品信息
func show_info() -> void:
	if not is_initialized:
		return
	
	# 构建物品信息文本
	var info_text = item_data["name"] + "\n"
	info_text += item_data.get("description", "") + "\n"
	
	# 根据物品类型添加额外信息
	match item_type:
		ItemType.POTION, ItemType.EQUIPMENT:
			if item_data.has("effect"):
				for stat_name in item_data["effect"]:
					var effect_value = item_data["effect"][stat_name]
					info_text += stat_name + ": +" + str(effect_value) + "\n"
	
	# 显示信息
	print(info_text)
	# 这里应该显示一个UI面板来展示物品信息
	# 例如：InfoPanel.show_item_info(info_text)

# 点击区域输入事件处理
func _on_click_area_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 发送物品被点击信号
		item_clicked.emit(self)
		
		# 显示物品信息
		show_info()

# 设置物品ID并重新加载数据
func set_item_id(new_id: String) -> void:
	item_id = new_id
	load_item_data()