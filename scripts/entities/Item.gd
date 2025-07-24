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

# 是否已被使用（防止重复拾取）
var is_used: bool = false

# 信号
signal item_clicked(item)
signal item_collected(item)

# 创建简单纹理
func create_simple_texture() -> void:
	# 创建一个默认的物品纹理（绿色方块代表物品）
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
	
	# 设置物品类型
	if item_data.has("type"):
		item_type = item_data["type"]
		print("物品 " + item_id + " 类型设置为: " + str(item_type))
	else:
		print("警告: 物品 " + item_id + " 没有类型信息")
	
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
		# 根据物品ID创建对应的纹理
		var texture = create_item_texture(item_id)
		if texture:
			sprite.texture = texture

# 根据物品ID创建纹理
func create_item_texture(id: String) -> ImageTexture:
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var main_color: Color
	var border_color: Color
	var shape_type: String = "square"  # square, circle, diamond
	
	# 根据物品ID设置颜色和形状
	match id:
		# 钥匙 - 钥匙形状，不同颜色
		"yellow_key":
			main_color = Color(1.0, 0.843, 0.0, 1.0)  # 黄色
			border_color = Color(0.722, 0.525, 0.043, 1.0)  # 深黄色
			shape_type = "key"
		"blue_key":
			main_color = Color(0.255, 0.412, 0.882, 1.0)  # 蓝色
			border_color = Color(0.098, 0.098, 0.439, 1.0)  # 深蓝色
			shape_type = "key"
		"red_key":
			main_color = Color(0.863, 0.078, 0.235, 1.0)  # 红色
			border_color = Color(0.545, 0.0, 0.0, 1.0)  # 深红色
			shape_type = "key"
		
		# 药水 - 圆形瓶子，不同颜色
		"small_health_potion", "medium_health_potion", "large_health_potion":
			main_color = Color(1.0, 0.0, 0.0, 1.0)  # 红色（生命药水）
			border_color = Color(0.5, 0.0, 0.0, 1.0)  # 深红色
			shape_type = "potion"
		"attack_potion":
			main_color = Color(1.0, 0.5, 0.0, 1.0)  # 橙色（攻击药水）
			border_color = Color(0.5, 0.25, 0.0, 1.0)  # 深橙色
			shape_type = "potion"
		"defense_potion":
			main_color = Color(0.0, 0.0, 1.0, 1.0)  # 蓝色（防御药水）
			border_color = Color(0.0, 0.0, 0.5, 1.0)  # 深蓝色
			shape_type = "potion"
		
		# 装备 - 菱形，金属色
		"iron_sword", "steel_sword":
			main_color = Color(0.75, 0.75, 0.75, 1.0)  # 银色
			border_color = Color(0.4, 0.4, 0.4, 1.0)  # 深灰色
			shape_type = "diamond"
		"iron_shield", "steel_shield":
			main_color = Color(0.6, 0.4, 0.2, 1.0)  # 棕色
			border_color = Color(0.3, 0.2, 0.1, 1.0)  # 深棕色
			shape_type = "diamond"
		
		# 宝物 - 圆形，金色
		"gold_coin":
			main_color = Color(1.0, 0.843, 0.0, 1.0)  # 金色
			border_color = Color(0.722, 0.525, 0.043, 1.0)  # 深金色
			shape_type = "circle"
		"gem":
			main_color = Color(0.5, 0.0, 0.5, 1.0)  # 紫色
			border_color = Color(0.25, 0.0, 0.25, 1.0)  # 深紫色
			shape_type = "diamond"
		
		# 特殊物品 - 特殊形状
		"cross":
			main_color = Color(1.0, 1.0, 1.0, 1.0)  # 白色
			border_color = Color(0.5, 0.5, 0.5, 1.0)  # 灰色
			shape_type = "cross"
		"flying_shoes":
			main_color = Color(0.5, 0.25, 0.0, 1.0)  # 棕色
			border_color = Color(0.25, 0.125, 0.0, 1.0)  # 深棕色
			shape_type = "square"
		
		_:
			# 默认物品
			main_color = Color(0.2, 1.0, 0.2, 1.0)  # 绿色
			border_color = Color(0.1, 0.5, 0.1, 1.0)  # 深绿色
			shape_type = "square"
	
	# 根据形状类型绘制
	match shape_type:
		"key":
			draw_key_shape(image, main_color, border_color)
		"potion":
			draw_potion_shape(image, main_color, border_color)
		"circle":
			draw_circle_shape(image, main_color, border_color)
		"diamond":
			draw_diamond_shape(image, main_color, border_color)
		"cross":
			draw_cross_shape(image, main_color, border_color)
		_:
			draw_square_shape(image, main_color, border_color)
	
	# 创建纹理
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

# 绘制钥匙形状
func draw_key_shape(image: Image, main_color: Color, border_color: Color) -> void:
	image.fill(Color(0, 0, 0, 0))  # 透明背景
	
	# 钥匙头部（圆形）
	var center_x = 32
	var center_y = 20
	var radius = 12
	
	for x in range(64):
		for y in range(64):
			var dx = x - center_x
			var dy = y - center_y
			var distance = sqrt(dx * dx + dy * dy)
			
			# 钥匙头部圆形
			if distance <= radius:
				if distance >= radius - 2:
					image.set_pixel(x, y, border_color)
				else:
					image.set_pixel(x, y, main_color)
			
			# 钥匙柄部（矩形）
			if x >= 28 and x <= 36 and y >= 32 and y <= 52:
				if x == 28 or x == 36 or y == 32 or y == 52:
					image.set_pixel(x, y, border_color)
				else:
					image.set_pixel(x, y, main_color)
			
			# 钥匙齿部
			if x >= 36 and x <= 44 and y >= 44 and y <= 48:
				if x == 36 or x == 44 or y == 44 or y == 48:
					image.set_pixel(x, y, border_color)
				else:
					image.set_pixel(x, y, main_color)

# 绘制药水瓶形状
func draw_potion_shape(image: Image, main_color: Color, border_color: Color) -> void:
	image.fill(Color(0, 0, 0, 0))  # 透明背景
	
	# 瓶身（椭圆形）
	var center_x = 32
	var center_y = 40
	var width = 20
	var height = 24
	
	for x in range(64):
		for y in range(64):
			var dx = float(x - center_x) / width
			var dy = float(y - center_y) / height
			var distance = sqrt(dx * dx + dy * dy)
			
			# 瓶身
			if distance <= 1.0:
				if distance >= 0.85:
					image.set_pixel(x, y, border_color)
				else:
					image.set_pixel(x, y, main_color)
			
			# 瓶颈
			if x >= 28 and x <= 36 and y >= 16 and y <= 24:
				if x == 28 or x == 36 or y == 16:
					image.set_pixel(x, y, border_color)
				else:
					image.set_pixel(x, y, main_color)
			
			# 瓶口
			if x >= 26 and x <= 38 and y >= 12 and y <= 16:
				if y == 12 or y == 16:
					image.set_pixel(x, y, border_color)
				else:
					image.set_pixel(x, y, main_color)

# 绘制圆形
func draw_circle_shape(image: Image, main_color: Color, border_color: Color) -> void:
	image.fill(Color(0, 0, 0, 0))  # 透明背景
	
	var center_x = 32
	var center_y = 32
	var radius = 24
	
	for x in range(64):
		for y in range(64):
			var dx = x - center_x
			var dy = y - center_y
			var distance = sqrt(dx * dx + dy * dy)
			
			if distance <= radius:
				if distance >= radius - 2:
					image.set_pixel(x, y, border_color)
				else:
					image.set_pixel(x, y, main_color)

# 绘制菱形
func draw_diamond_shape(image: Image, main_color: Color, border_color: Color) -> void:
	image.fill(Color(0, 0, 0, 0))  # 透明背景
	
	var center_x = 32
	var center_y = 32
	var size = 24
	
	for x in range(64):
		for y in range(64):
			var dx = abs(x - center_x)
			var dy = abs(y - center_y)
			var distance = dx + dy
			
			if distance <= size:
				if distance >= size - 2:
					image.set_pixel(x, y, border_color)
				else:
					image.set_pixel(x, y, main_color)

# 绘制十字形
func draw_cross_shape(image: Image, main_color: Color, border_color: Color) -> void:
	image.fill(Color(0, 0, 0, 0))  # 透明背景
	
	# 垂直线
	for x in range(26, 39):
		for y in range(8, 57):
			if x == 26 or x == 38:
				image.set_pixel(x, y, border_color)
			else:
				image.set_pixel(x, y, main_color)
	
	# 水平线
	for x in range(8, 57):
		for y in range(26, 39):
			if y == 26 or y == 38:
				image.set_pixel(x, y, border_color)
			else:
				image.set_pixel(x, y, main_color)

# 绘制方形
func draw_square_shape(image: Image, main_color: Color, border_color: Color) -> void:
	image.fill(Color(0, 0, 0, 0))  # 透明背景
	
	for x in range(8, 57):
		for y in range(8, 57):
			if x < 10 or x >= 55 or y < 10 or y >= 55:
				image.set_pixel(x, y, border_color)
			else:
				image.set_pixel(x, y, main_color)

# 获取物品属性
func get_property(property_name: String, default_value = null):
	if item_data.has(property_name):
		return item_data[property_name]
	return default_value

# 使用物品
func use() -> bool:
	if not is_initialized or is_used:
		return false
	
	# 标记为已使用，防止重复拾取
	is_used = true
	
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
	print("开始使用药水: " + item_id)
	if not item_data.has("effect"):
		print("药水没有effect数据")
		return false
	
	print("药水effect数据: " + str(item_data["effect"]))
	
	# 应用药水效果
	for stat_name in item_data["effect"]:
		var effect_value = item_data["effect"][stat_name]
		print("应用药水效果: " + stat_name + " +" + str(effect_value))
		
		# 对于所有属性，直接增加（移除生命值上限限制）
		GameManager.add_player_stat(stat_name, effect_value)
	
	# 发送物品收集信号
	item_collected.emit(self)
	
	print("药水使用完成: " + item_id)
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