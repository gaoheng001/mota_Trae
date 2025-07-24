extends Node2D
# 敌人基类 - 定义敌人的基本属性和行为

# 敌人ID
@export var enemy_id: String = "slime"

# 敌人数据
var enemy_data: Dictionary = {}

# 是否已初始化
var is_initialized: bool = false

# 信号
signal enemy_clicked(enemy)

# 创建简单纹理
func create_simple_texture() -> void:
	# 创建一个简单的敌人纹理（红色方块代表敌人）
	var image = Image.create(64, 64, false, Image.FORMAT_RGB8)
	image.fill(Color(1.0, 0.2, 0.2))  # 红色
	
	# 添加一些细节（黑色边框）
	for x in range(64):
		for y in range(64):
			if x < 2 or x >= 62 or y < 2 or y >= 62:
				image.set_pixel(x, y, Color(0.1, 0.1, 0.1))  # 黑色边框
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	$Sprite2D.texture = texture

# 初始化
func _ready() -> void:
	# 创建简单纹理
	create_simple_texture()
	
	# 加载敌人数据
	load_enemy_data()
	
	# 设置点击区域
	var click_area = $ClickArea if has_node("ClickArea") else null
	if click_area:
		click_area.input_event.connect(_on_click_area_input_event)

# 加载敌人数据
func load_enemy_data() -> void:
	# 从战斗管理器获取敌人数据
	enemy_data = BattleManager.load_enemy_data(enemy_id)
	
	if enemy_data.is_empty():
		push_error("无法加载敌人数据: " + enemy_id)
		return
	
	# 更新敌人显示
	update_appearance()
	
	# 标记为已初始化
	is_initialized = true

# 更新敌人外观
func update_appearance() -> void:
	# 更新敌人精灵
	var sprite = $Sprite2D if has_node("Sprite2D") else null
	if sprite:
		# 这里应该根据敌人ID加载对应的纹理
		# 例如：sprite.texture = load("res://assets/sprites/enemies/" + enemy_id + ".png")
		pass
	
	# 更新敌人名称标签
	var name_label = $NameLabel if has_node("NameLabel") else null
	if name_label and enemy_data.has("name"):
		name_label.text = enemy_data["name"]

# 获取敌人属性
func get_stat(stat_name: String, default_value = 0):
	if enemy_data.has(stat_name):
		return enemy_data[stat_name]
	return default_value

# 检查是否有特殊能力
func has_ability(ability_name: String) -> bool:
	if enemy_data.has("special_abilities"):
		return ability_name in enemy_data["special_abilities"]
	return false

# 显示敌人信息
func show_info() -> void:
	if not is_initialized:
		return
	
	# 构建敌人信息文本
	var info_text = enemy_data["name"] + "\n"
	info_text += "生命值: " + str(enemy_data["health"]) + "\n"
	info_text += "攻击力: " + str(enemy_data["attack"]) + "\n"
	info_text += "防御力: " + str(enemy_data["defense"]) + "\n"
	
	# 检查是否可以战胜该敌人
	var battle_prediction = BattleManager.can_defeat_enemy(enemy_id)
	
	if battle_prediction["can_win"]:
		info_text += "\n预计损失生命值: " + str(battle_prediction["damage_taken"]) + "\n"
		info_text += "预计回合数: " + str(battle_prediction["turns"]) + "\n"
	else:
		info_text += "\n警告: 无法战胜该敌人!\n"
		info_text += "原因: " + battle_prediction["reason"] + "\n"
	
	# 显示信息
	print(info_text)
	# 这里应该显示一个UI面板来展示敌人信息
	# 例如：InfoPanel.show_enemy_info(info_text)

# 点击区域输入事件处理
func _on_click_area_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 发送敌人被点击信号
		enemy_clicked.emit(self)
		
		# 显示敌人信息
		show_info()

# 设置敌人ID并重新加载数据
func set_enemy_id(new_id: String) -> void:
	enemy_id = new_id
	load_enemy_data()