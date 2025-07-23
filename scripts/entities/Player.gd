extends CharacterBody2D
# 玩家控制器 - 负责处理玩家的移动和交互

# 移动速度
@export var move_speed: float = 4.0

# 是否正在移动
var is_moving: bool = false

# 目标位置
var target_position: Vector2 = Vector2.ZERO

# 移动方向
var move_direction: Vector2 = Vector2.ZERO

# 网格大小
@export var grid_size: int = 64

# 动画播放器引用
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# 信号
signal movement_completed
signal interaction_triggered(object)

func _ready() -> void:
	# 初始化目标位置为当前位置
	target_position = position
	
	# 连接到地图管理器的信号
	MapManager.player_moved.connect(_on_map_player_moved)
	
	# 播放默认动画
	if animation_player and animation_player.has_animation("idle_down"):
		animation_player.play("idle_down")

func _physics_process(delta: float) -> void:
	# 如果游戏状态不是PLAYING，不处理输入
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	
	# 如果正在移动，继续移动到目标位置
	if is_moving:
		var move_step = move_direction * move_speed
		var distance_to_target = position.distance_to(target_position)
		
		# 如果距离目标位置很近，直接设置为目标位置
		if distance_to_target < move_speed:
			position = target_position
			is_moving = false
			movement_completed.emit()
			
			# 播放站立动画
			play_idle_animation()
		else:
			# 继续移动
			position += move_step
	else:
		# 处理输入
		process_input()

# 处理输入
func process_input() -> void:
	# 获取输入方向
	var input_direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_up"):
		input_direction = Vector2(0, -1)
	elif Input.is_action_pressed("move_down"):
		input_direction = Vector2(0, 1)
	elif Input.is_action_pressed("move_left"):
		input_direction = Vector2(-1, 0)
	elif Input.is_action_pressed("move_right"):
		input_direction = Vector2(1, 0)
	
	# 如果有输入，尝试移动
	if input_direction != Vector2.ZERO:
		move(input_direction)
	
	# 检查交互输入
	if Input.is_action_just_pressed("interact"):
		trigger_interaction()

# 移动到指定方向
func move(direction: Vector2) -> void:
	# 计算地图上的移动
	var map_direction = Vector2i(int(direction.x), int(direction.y))
	var success = MapManager.move_player(map_direction)
	
	# 如果地图移动成功，更新视觉位置
	if success:
		# 设置移动方向
		move_direction = direction
		
		# 计算目标位置
		target_position = position + direction * grid_size
		
		# 设置为移动状态
		is_moving = true
		
		# 播放移动动画
		play_move_animation(direction)
	else:
		# 即使不能移动，也更新朝向
		update_facing_direction(direction)

# 触发交互
func trigger_interaction() -> void:
	# 获取面向的方向
	var facing_direction = get_facing_direction()
	
	# 计算交互位置
	var interaction_position = MapManager.player_position + Vector2i(int(facing_direction.x), int(facing_direction.y))
	
	# 获取该位置的地图元素
	var tile_type = MapManager.get_tile(interaction_position)
	
	# 根据地图元素类型处理交互
	match tile_type:
		MapManager.TileType.NPC:
			# 与NPC对话
			print("与NPC对话")
			# 这里应该触发对话系统
			interaction_triggered.emit({"type": "npc", "position": interaction_position})
			
		MapManager.TileType.ITEM:
			# 拾取物品
			print("拾取物品")
			# 这里应该触发物品系统
			interaction_triggered.emit({"type": "item", "position": interaction_position})
			
		_:
			# 其他类型的交互
			print("没有可交互的对象")

# 获取面向的方向
func get_facing_direction() -> Vector2:
	# 根据当前动画确定面向方向
	var current_animation = ""
	if animation_player:
		current_animation = animation_player.current_animation
	
	if current_animation.contains("up"):
		return Vector2(0, -1)
	elif current_animation.contains("down"):
		return Vector2(0, 1)
	elif current_animation.contains("left"):
		return Vector2(-1, 0)
	elif current_animation.contains("right"):
		return Vector2(1, 0)
	
	# 默认面向下方
	return Vector2(0, 1)

# 更新面向方向
func update_facing_direction(direction: Vector2) -> void:
	# 播放对应方向的站立动画
	if direction.y < 0:
		if animation_player and animation_player.has_animation("idle_up"):
			animation_player.play("idle_up")
	elif direction.y > 0:
		if animation_player and animation_player.has_animation("idle_down"):
			animation_player.play("idle_down")
	elif direction.x < 0:
		if animation_player and animation_player.has_animation("idle_left"):
			animation_player.play("idle_left")
	elif direction.x > 0:
		if animation_player and animation_player.has_animation("idle_right"):
			animation_player.play("idle_right")

# 播放移动动画
func play_move_animation(direction: Vector2) -> void:
	if not animation_player:
		return
	
	if direction.y < 0 and animation_player.has_animation("walk_up"):
		animation_player.play("walk_up")
	elif direction.y > 0 and animation_player.has_animation("walk_down"):
		animation_player.play("walk_down")
	elif direction.x < 0 and animation_player.has_animation("walk_left"):
		animation_player.play("walk_left")
	elif direction.x > 0 and animation_player.has_animation("walk_right"):
		animation_player.play("walk_right")

# 播放站立动画
func play_idle_animation() -> void:
	if not animation_player:
		return
	
	var current_animation = animation_player.current_animation
	
	if current_animation.contains("walk_up") and animation_player.has_animation("idle_up"):
		animation_player.play("idle_up")
	elif current_animation.contains("walk_down") and animation_player.has_animation("idle_down"):
		animation_player.play("idle_down")
	elif current_animation.contains("walk_left") and animation_player.has_animation("idle_left"):
		animation_player.play("idle_left")
	elif current_animation.contains("walk_right") and animation_player.has_animation("idle_right"):
		animation_player.play("idle_right")

# 地图玩家移动回调
func _on_map_player_moved(old_position: Vector2i, new_position: Vector2i) -> void:
	# 这里可以处理地图位置变化后的逻辑
	pass

# 设置玩家位置（用于初始化或传送）
func set_grid_position(grid_position: Vector2i) -> void:
	# 更新地图管理器中的玩家位置
	MapManager.player_position = grid_position
	
	# 更新视觉位置
	position = Vector2(grid_position.x * grid_size, grid_position.y * grid_size)
	target_position = position
	is_moving = false