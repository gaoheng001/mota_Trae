extends Node2D
# 游戏世界 - 游戏的主要场景，负责管理地图、玩家和UI等元素

# 节点引用
@onready var tilemap: TileMap = $TileMap if has_node("TileMap") else null
@onready var player: CharacterBody2D = $Player if has_node("Player") else null
@onready var ui_layer: CanvasLayer = $UILayer if has_node("UILayer") else null
@onready var game_menu: Control = $UILayer/GameMenu if has_node("UILayer/GameMenu") else null
@onready var battle_scene: Control = $UILayer/BattleScene if has_node("UILayer/BattleScene") else null
@onready var status_bar: Control = $UILayer/StatusBar if has_node("UILayer/StatusBar") else null

# 地图元素预制体
var enemy_scene: PackedScene = preload("res://scenes/entities/Enemy.tscn")
var item_scene: PackedScene = preload("res://scenes/entities/Item.tscn")
var npc_scene: PackedScene = preload("res://scenes/entities/NPC.tscn")

# 地图元素容器
var enemies: Node2D
var items: Node2D
var npcs: Node2D

# 当前楼层
var current_floor: int = 1

# 初始化
func _ready() -> void:
	print("游戏世界初始化")
	
	# 创建地图元素容器
	enemies = Node2D.new()
	enemies.name = "Enemies"
	add_child(enemies)
	
	items = Node2D.new()
	items.name = "Items"
	add_child(items)
	
	npcs = Node2D.new()
	npcs.name = "NPCs"
	add_child(npcs)
	
	# 连接信号
	GameManager.floor_changed.connect(_on_floor_changed)
	GameManager.game_state_changed.connect(_on_game_state_changed)
	MapManager.map_loaded.connect(_on_map_loaded)
	MapManager.tile_changed.connect(_on_tile_changed)
	BattleManager.battle_started.connect(_on_battle_started)
	BattleManager.battle_ended.connect(_on_battle_ended)
	
	# 初始化UI
	init_ui()
	
	# 加载当前楼层
	load_current_floor()
	
	# 设置输入处理
	set_process_input(true)

# 初始化UI
func init_ui() -> void:
	# 初始化状态栏
	if status_bar:
		update_status_bar()
	
	# 初始隐藏游戏菜单和战斗场景
	if game_menu:
		game_menu.visible = false
	if battle_scene:
		battle_scene.visible = false

# 加载当前楼层
func load_current_floor() -> void:
	# 获取当前楼层
	current_floor = GameManager.game_progress["current_floor"]
	
	# 加载地图
	MapManager.load_floor(current_floor)

# 更新地图显示
func update_map_display() -> void:
	if not tilemap:
		return
	
	# 清除现有地图
	tilemap.clear()
	
	# 清除地图元素
	clear_map_entities()
	
	# 遍历地图数据
	for y in range(MapManager.map_height):
		for x in range(MapManager.map_width):
			var tile_type = MapManager.get_tile(Vector2i(x, y))
			
			# 设置地图瓦片
			set_tile(Vector2i(x, y), tile_type)
			
			# 创建地图元素
			create_map_entity(Vector2i(x, y), tile_type)
	
	# 更新玩家位置
	update_player_position()

# 设置地图瓦片
func set_tile(position: Vector2i, tile_type: int) -> void:
	if not tilemap:
		return
	
	# 根据地图元素类型设置瓦片
	match tile_type:
		MapManager.TileType.FLOOR:
			tilemap.set_cell(0, position, 0, Vector2i(0, 0))
		MapManager.TileType.WALL:
			tilemap.set_cell(0, position, 0, Vector2i(1, 0))
		MapManager.TileType.DOOR_YELLOW:
			tilemap.set_cell(0, position, 0, Vector2i(2, 0))
		MapManager.TileType.DOOR_BLUE:
			tilemap.set_cell(0, position, 0, Vector2i(3, 0))
		MapManager.TileType.DOOR_RED:
			tilemap.set_cell(0, position, 0, Vector2i(4, 0))
		MapManager.TileType.STAIRS_UP:
			tilemap.set_cell(0, position, 0, Vector2i(5, 0))
		MapManager.TileType.STAIRS_DOWN:
			tilemap.set_cell(0, position, 0, Vector2i(6, 0))
		_:
			# 其他类型（敌人、物品、NPC）使用地板瓦片
			tilemap.set_cell(0, position, 0, Vector2i(0, 0))

# 创建地图元素
func create_map_entity(position: Vector2i, tile_type: int) -> void:
	# 计算世界坐标
	var world_position = Vector2(position.x * 64, position.y * 64)
	
	# 根据地图元素类型创建实体
	match tile_type:
		MapManager.TileType.ENEMY:
			# 创建敌人
			var enemy_instance = enemy_scene.instantiate()
			enemy_instance.position = world_position
			
			# 设置敌人ID（根据楼层随机选择）
			var enemy_id = get_random_enemy_id(current_floor)
			enemy_instance.enemy_id = enemy_id
			
			enemies.add_child(enemy_instance)
			
		MapManager.TileType.ITEM:
			# 创建物品
			var item_instance = item_scene.instantiate()
			item_instance.position = world_position
			
			# 设置物品ID（根据楼层随机选择）
			var item_id = get_random_item_id(current_floor)
			item_instance.item_id = item_id
			
			items.add_child(item_instance)
			
		MapManager.TileType.NPC:
			# 创建NPC
			var npc_instance = npc_scene.instantiate()
			npc_instance.position = world_position
			
			# 设置NPC ID
			# 这里应该根据楼层和位置设置特定的NPC
			
			npcs.add_child(npc_instance)

# 获取随机敌人ID
func get_random_enemy_id(floor_number: int) -> String:
	# 根据楼层选择合适的敌人
	var enemy_pool = []
	
	if floor_number <= 5:
		# 低层敌人
		enemy_pool = ["slime", "bat"]
	elif floor_number <= 15:
		# 中层敌人
		enemy_pool = ["bat", "skeleton", "orc"]
	else:
		# 高层敌人
		enemy_pool = ["skeleton", "orc", "ghost", "dragon"]
	
	# 随机选择
	var rng = RandomNumberGenerator.new()
	rng.seed = floor_number * 1000 + Time.get_unix_time_from_system()
	var index = rng.randi() % enemy_pool.size()
	
	return enemy_pool[index]

# 获取随机物品ID
func get_random_item_id(floor_number: int) -> String:
	# 根据楼层选择合适的物品
	var item_pool = []
	
	# 基础物品（所有楼层都可能出现）
	var base_items = ["yellow_key", "blue_key", "small_health_potion"]
	
	# 根据楼层添加不同物品
	if floor_number >= 3:
		base_items.append("medium_health_potion")
		base_items.append("attack_potion")
	
	if floor_number >= 5:
		base_items.append("red_key")
		base_items.append("defense_potion")
		base_items.append("iron_sword")
	
	if floor_number >= 10:
		base_items.append("large_health_potion")
		base_items.append("iron_shield")
	
	if floor_number >= 15:
		base_items.append("steel_sword")
		base_items.append("steel_shield")
	
	if floor_number >= 20:
		base_items.append("cross")
	
	if floor_number >= 25:
		base_items.append("flying_shoes")
	
	# 随机选择
	var rng = RandomNumberGenerator.new()
	rng.seed = floor_number * 2000 + Time.get_unix_time_from_system()
	var index = rng.randi() % base_items.size()
	
	return base_items[index]

# 清除地图元素
func clear_map_entities() -> void:
	# 清除所有敌人
	for child in enemies.get_children():
		child.queue_free()
	
	# 清除所有物品
	for child in items.get_children():
		child.queue_free()
	
	# 清除所有NPC
	for child in npcs.get_children():
		child.queue_free()

# 更新玩家位置
func update_player_position() -> void:
	if not player:
		return
	
	# 获取地图上的玩家位置
	var player_map_pos = MapManager.player_position
	
	# 设置玩家的网格位置
	player.set_grid_position(player_map_pos)

# 更新状态栏
func update_status_bar() -> void:
	if not status_bar:
		return
	
	# 更新玩家状态显示
	# 这里应该更新状态栏UI
	# 例如：
	# status_bar.update_health(GameManager.player_data["health"], GameManager.player_data["max_health"])
	# status_bar.update_attack(GameManager.player_data["attack"])
	# status_bar.update_defense(GameManager.player_data["defense"])
	# status_bar.update_keys(GameManager.player_data["yellow_keys"], GameManager.player_data["blue_keys"], GameManager.player_data["red_keys"])
	# status_bar.update_floor(current_floor)
	pass

# 显示游戏菜单
func show_game_menu() -> void:
	if game_menu:
		game_menu.visible = true
		GameManager.change_game_state(GameManager.GameState.PAUSED)

# 隐藏游戏菜单
func hide_game_menu() -> void:
	if game_menu:
		game_menu.visible = false
		GameManager.change_game_state(GameManager.GameState.PLAYING)

# 输入处理
func _input(event: InputEvent) -> void:
	# 检查菜单键
	if event.is_action_pressed("menu"):
		if GameManager.current_state == GameManager.GameState.PLAYING:
			show_game_menu()
		elif GameManager.current_state == GameManager.GameState.PAUSED:
			hide_game_menu()

# 楼层变化处理
func _on_floor_changed(floor_number: int) -> void:
	current_floor = floor_number
	update_status_bar()

# 地图加载处理
func _on_map_loaded(floor_number: int) -> void:
	print("地图已加载: 第 " + str(floor_number) + " 层")
	update_map_display()

# 地图元素变化处理
func _on_tile_changed(position: Vector2i, old_type: int, new_type: int) -> void:
	# 更新地图瓦片
	set_tile(position, new_type)
	
	# 如果新类型是地板，移除原有实体
	if new_type == MapManager.TileType.FLOOR:
		remove_entity_at_position(position)
	else:
		# 否则创建新实体
		create_map_entity(position, new_type)

# 移除指定位置的实体
func remove_entity_at_position(position: Vector2i) -> void:
	# 计算世界坐标
	var world_position = Vector2(position.x * 64, position.y * 64)
	
	# 检查并移除敌人
	for enemy in enemies.get_children():
		if enemy.position.distance_to(world_position) < 1.0:
			enemy.queue_free()
			break
	
	# 检查并移除物品
	for item in items.get_children():
		if item.position.distance_to(world_position) < 1.0:
			item.queue_free()
			break
	
	# 检查并移除NPC
	for npc in npcs.get_children():
		if npc.position.distance_to(world_position) < 1.0:
			npc.queue_free()
			break

# 游戏状态变化处理
func _on_game_state_changed(new_state) -> void:
	match new_state:
		GameManager.GameState.PLAYING:
			# 恢复游戏
			if game_menu:
				game_menu.visible = false
			
		GameManager.GameState.PAUSED:
			# 暂停游戏
			pass
			
		GameManager.GameState.BATTLE:
			# 进入战斗
			if battle_scene:
				battle_scene.visible = true
			
		GameManager.GameState.GAME_OVER:
			# 游戏结束
			show_game_over()

# 战斗开始处理
func _on_battle_started(enemy_data: Dictionary) -> void:
	print("战斗开始: " + enemy_data["name"])
	
	# 更新战斗场景
	if battle_scene:
		# 这里应该设置战斗场景的敌人数据
		# 例如：battle_scene.set_enemy_data(enemy_data)
		battle_scene.visible = true

# 战斗结束处理
func _on_battle_ended(result: Dictionary) -> void:
	print("战斗结束: " + ("胜利" if result["victory"] else "失败"))
	
	# 隐藏战斗场景
	if battle_scene:
		battle_scene.visible = false
	
	# 更新状态栏
	update_status_bar()
	
	# 如果战斗失败，显示游戏结束
	if not result["victory"]:
		show_game_over()

# 显示游戏结束
func show_game_over() -> void:
	# 这里应该显示游戏结束界面
	# 例如：$UILayer/GameOverScreen.visible = true
	print("游戏结束")