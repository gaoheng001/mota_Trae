extends Control
# 状态栏 - 显示玩家的状态信息

# 节点引用
@onready var floor_label = $HBoxContainer/Floor
@onready var health_value = $HBoxContainer/Health/Value
@onready var attack_value = $HBoxContainer/Attack/Value
@onready var defense_value = $HBoxContainer/Defense/Value
@onready var yellow_key_value = $HBoxContainer/YellowKey/Value
@onready var blue_key_value = $HBoxContainer/BlueKey/Value
@onready var red_key_value = $HBoxContainer/RedKey/Value
@onready var gold_value = $HBoxContainer/Gold/Value
@onready var experience_value = $HBoxContainer/Experience/Value
@onready var level_value = $HBoxContainer/Level/Value

# 图标节点引用
@onready var health_icon = $HBoxContainer/Health/Icon
@onready var attack_icon = $HBoxContainer/Attack/Icon
@onready var defense_icon = $HBoxContainer/Defense/Icon
@onready var yellow_key_icon = $HBoxContainer/YellowKey/Icon
@onready var blue_key_icon = $HBoxContainer/BlueKey/Icon
@onready var red_key_icon = $HBoxContainer/RedKey/Icon
@onready var gold_icon = $HBoxContainer/Gold/Icon

# 初始化
@onready var GameManager = get_node("/root/GameManager")

func _ready() -> void:
	# 创建简单的图标纹理
	create_simple_icons()

	GameManager.player_stats_changed.connect(_on_player_stats_changed)
	GameManager.floor_changed.connect(_on_floor_changed)
	update_all()

	# 初始更新
	update_all()

# 创建简单的图标纹理
func create_simple_icons() -> void:
	# 创建不同颜色的纹理
	var heart_texture = create_simple_texture(Color.RED, 32, 32)
	var sword_texture = create_simple_texture(Color.GRAY, 32, 32)
	var shield_texture = create_simple_texture(Color.BLUE, 32, 32)
	var key_texture = create_simple_texture(Color.YELLOW, 32, 32)
	
	# 设置图标
	if health_icon:
		health_icon.texture = heart_texture
	if attack_icon:
		attack_icon.texture = sword_texture
	if defense_icon:
		defense_icon.texture = shield_texture
	if yellow_key_icon:
		yellow_key_icon.texture = key_texture
	if blue_key_icon:
		blue_key_icon.texture = key_texture
	if red_key_icon:
		red_key_icon.texture = key_texture
	if gold_icon:
		gold_icon.texture = key_texture

# 创建简单的纹理
func create_simple_texture(color: Color, width: int, height: int) -> ImageTexture:
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

# 更新所有状态
func update_all() -> void:
	update_floor(GameManager.game_progress["current_floor"])
	update_health(GameManager.player_data["health"], GameManager.player_data["max_health"])
	update_attack(GameManager.player_data["attack"])
	update_defense(GameManager.player_data["defense"])
	update_keys(
		GameManager.player_data["yellow_keys"],
		GameManager.player_data["blue_keys"],
		GameManager.player_data["red_keys"]
	)
	update_gold(GameManager.player_data["gold"])
	update_experience(GameManager.player_data["exp"], GameManager.player_data["level"])

# 更新楼层
func update_floor(floor_number: int) -> void:
	floor_label.text = "第" + str(floor_number) + "层"

# 更新生命值
func update_health(health: int, max_health: int) -> void:
	health_value.text = str(health) + "/" + str(max_health)
	
	# 根据生命值百分比改变颜色
	var health_percent = float(health) / max_health
	if health_percent <= 0.2:
		health_value.modulate = Color(1, 0, 0) # 红色
	elif health_percent <= 0.5:
		health_value.modulate = Color(1, 1, 0) # 黄色
	else:
		health_value.modulate = Color(1, 1, 1) # 白色

# 更新攻击力
func update_attack(attack: int) -> void:
	attack_value.text = str(attack)

# 更新防御力
func update_defense(defense: int) -> void:
	defense_value.text = str(defense)

# 更新钥匙
func update_keys(yellow: int, blue: int, red: int) -> void:
	yellow_key_value.text = str(yellow)
	blue_key_value.text = str(blue)
	red_key_value.text = str(red)

# 更新金币
func update_gold(gold: int) -> void:
	gold_value.text = str(gold)

# 更新经验和等级
func update_experience(experience: int, level: int) -> void:
	experience_value.text = str(experience)
	level_value.text = str(level)

# 玩家状态变化处理
func _on_player_stats_changed(stats: Dictionary) -> void:
	var player_data = stats
	update_health(player_data["health"], player_data["max_health"])
	update_attack(player_data["attack"])
	update_defense(player_data["defense"])
	update_keys(player_data["yellow_keys"], player_data["blue_keys"], player_data["red_keys"])
	update_gold(player_data["gold"])
	update_experience(player_data["exp"], player_data["level"])


# 楼层变化处理
func _on_floor_changed(floor_number: int) -> void:
	update_floor(floor_number)