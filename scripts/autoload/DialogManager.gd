extends Node
# 对话管理器 - 负责管理游戏中的对话系统

# 对话状态枚举
enum DialogState {
	IDLE,       # 空闲状态
	SHOWING,    # 显示对话
	WAITING,    # 等待玩家输入
	CHOOSING,   # 玩家选择选项
	ANIMATING   # 动画播放中
}

# 当前对话状态
var current_state: DialogState = DialogState.IDLE

# 当前对话数据
var current_dialog: Dictionary = {}
var current_dialog_id: String = ""
var current_page_index: int = 0
var current_choice_index: int = 0

# 对话显示设置
var text_speed: float = 0.03  # 每个字符显示的时间间隔（秒）
var auto_advance: bool = false  # 是否自动前进对话
var auto_advance_delay: float = 2.0  # 自动前进的延迟时间（秒）

# 对话UI引用
var dialog_ui = null

# 信号
signal dialog_started(dialog_id)
signal dialog_ended(dialog_id)
signal dialog_page_changed(page_index)
signal dialog_choice_made(choice_index, choice_text)

# 初始化
func _ready() -> void:
	print("对话管理器初始化")
	
	# 连接游戏管理器信号
	GameManager.game_state_changed.connect(_on_game_state_changed)

# 开始对话
func start_dialog(dialog_id: String) -> bool:
	# 检查当前状态
	if current_state != DialogState.IDLE:
		print("对话已在进行中，无法开始新对话")
		return false
	
	# 加载对话数据
	var dialog_data = DataManager.get_dialog(dialog_id)
	if dialog_data.is_empty():
		push_error("无法加载对话数据: " + dialog_id)
		return false
	
	# 设置当前对话
	current_dialog = dialog_data
	current_dialog_id = dialog_id
	current_page_index = 0
	current_choice_index = 0
	
	# 更新状态
	current_state = DialogState.SHOWING
	
	# 通知游戏管理器进入对话状态
	GameManager.change_game_state(GameManager.GameState.DIALOG)
	
	# 显示对话UI
	show_dialog_ui()
	
	# 显示当前页面
	show_current_page()
	
	# 发出信号
	dialog_started.emit(dialog_id)
	
	return true

# 结束对话
func end_dialog() -> void:
	# 检查当前状态
	if current_state == DialogState.IDLE:
		return
	
	# 隐藏对话UI
	hide_dialog_ui()
	
	# 保存对话ID
	var ended_dialog_id = current_dialog_id
	
	# 重置对话数据
	current_dialog = {}
	current_dialog_id = ""
	current_page_index = 0
	current_choice_index = 0
	
	# 更新状态
	current_state = DialogState.IDLE
	
	# 通知游戏管理器返回上一个状态
	GameManager.change_game_state(GameManager.GameState.PLAYING)
	
	# 发出信号
	dialog_ended.emit(ended_dialog_id)

# 显示对话UI
func show_dialog_ui() -> void:
	# 使用UI管理器显示对话UI
	if Engine.has_singleton("UIManager"):
		var ui_manager = Engine.get_singleton("UIManager")
		dialog_ui = ui_manager.show_screen(ui_manager.UIScreen.DIALOG)

# 隐藏对话UI
func hide_dialog_ui() -> void:
	# 使用UI管理器隐藏对话UI
	if Engine.has_singleton("UIManager"):
		var ui_manager = Engine.get_singleton("UIManager")
		ui_manager.hide_screen(ui_manager.UIScreen.DIALOG)
		dialog_ui = null

# 显示当前页面
func show_current_page() -> void:
	# 检查对话UI
	if not dialog_ui:
		push_error("对话UI未初始化")
		return
	
	# 检查当前对话数据
	if current_dialog.is_empty():
		push_error("当前对话数据为空")
		return
	
	# 获取页面数据
	var pages = current_dialog.get("pages", [])
	if current_page_index >= pages.size():
		# 对话结束
		end_dialog()
		return
	
	# 获取当前页面
	var page = pages[current_page_index]
	
	# 更新对话UI
	if dialog_ui.has_method("set_dialog_page"):
		dialog_ui.set_dialog_page(page)
	
	# 检查是否有选项
	if page.has("choices") and not page["choices"].is_empty():
		# 进入选择状态
		current_state = DialogState.CHOOSING
		current_choice_index = 0
		
		# 更新选项UI
		if dialog_ui.has_method("show_choices"):
			dialog_ui.show_choices(page["choices"], current_choice_index)
	else:
		# 进入等待状态
		current_state = DialogState.WAITING
		
		# 如果启用自动前进，设置定时器
		if auto_advance:
			await get_tree().create_timer(auto_advance_delay).timeout
			next_page()
	
	# 发出信号
	dialog_page_changed.emit(current_page_index)

# 下一页
func next_page() -> void:
	# 检查当前状态
	if current_state == DialogState.SHOWING or current_state == DialogState.ANIMATING:
		# 如果正在显示文本或动画，直接完成显示
		if dialog_ui and dialog_ui.has_method("complete_text"):
			dialog_ui.complete_text()
			current_state = DialogState.WAITING
		return
	
	if current_state != DialogState.WAITING:
		return
	
	# 前进到下一页
	current_page_index += 1
	
	# 显示当前页面
	show_current_page()

# 选择选项
func choose_option(index: int) -> void:
	# 检查当前状态
	if current_state != DialogState.CHOOSING:
		return
	
	# 获取页面数据
	var pages = current_dialog.get("pages", [])
	if current_page_index >= pages.size():
		return
	
	# 获取当前页面
	var page = pages[current_page_index]
	
	# 检查选项是否有效
	var choices = page.get("choices", [])
	if index < 0 or index >= choices.size():
		return
	
	# 保存选择的索引
	current_choice_index = index
	
	# 获取选择的选项
	var choice = choices[index]
	
	# 发出信号
	dialog_choice_made.emit(index, choice.get("text", ""))
	
	# 处理选项结果
	if choice.has("next_page"):
		# 跳转到指定页面
		current_page_index = choice["next_page"]
		show_current_page()
	elif choice.has("next_dialog"):
		# 开始新对话
		end_dialog()
		start_dialog(choice["next_dialog"])
	elif choice.has("action"):
		# 执行特定动作
		execute_dialog_action(choice["action"], choice.get("action_params", {}))
		
		# 继续对话
		current_page_index += 1
		show_current_page()
	else:
		# 默认前进到下一页
		current_page_index += 1
		show_current_page()

# 移动选项光标
func move_choice_cursor(direction: int) -> void:
	# 检查当前状态
	if current_state != DialogState.CHOOSING:
		return
	
	# 获取页面数据
	var pages = current_dialog.get("pages", [])
	if current_page_index >= pages.size():
		return
	
	# 获取当前页面
	var page = pages[current_page_index]
	
	# 获取选项数量
	var choices = page.get("choices", [])
	var choice_count = choices.size()
	if choice_count <= 0:
		return
	
	# 更新选项索引
	current_choice_index = (current_choice_index + direction) % choice_count
	if current_choice_index < 0:
		current_choice_index = choice_count - 1
	
	# 更新选项UI
	if dialog_ui and dialog_ui.has_method("update_choice_selection"):
		dialog_ui.update_choice_selection(current_choice_index)
	
	# 播放UI音效
	if Engine.has_singleton("AudioManager"):
		var audio_manager = Engine.get_singleton("AudioManager")
		audio_manager.play_ui("cursor_move")

# 确认当前选项
func confirm_choice() -> void:
	# 检查当前状态
	if current_state != DialogState.CHOOSING:
		return
	
	# 选择当前选项
	choose_option(current_choice_index)
	
	# 播放UI音效
	if Engine.has_singleton("AudioManager"):
		var audio_manager = Engine.get_singleton("AudioManager")
		audio_manager.play_ui("confirm")

# 处理输入
func _process(_delta: float) -> void:
	# 只在对话状态下处理输入
	if GameManager.current_state != GameManager.GameState.DIALOG:
		return
	
	# 处理输入
	if Input.is_action_just_pressed("ui_accept"):
		if current_state == DialogState.WAITING:
			next_page()
		elif current_state == DialogState.CHOOSING:
			confirm_choice()
		elif current_state == DialogState.SHOWING or current_state == DialogState.ANIMATING:
			# 加速文本显示
			if dialog_ui and dialog_ui.has_method("complete_text"):
				dialog_ui.complete_text()
				current_state = DialogState.WAITING
	
	if current_state == DialogState.CHOOSING:
		if Input.is_action_just_pressed("ui_up"):
			move_choice_cursor(-1)
		elif Input.is_action_just_pressed("ui_down"):
			move_choice_cursor(1)
	
	if Input.is_action_just_pressed("ui_cancel"):
		# 在某些情况下允许跳过对话
		if current_dialog.get("skippable", false):
			end_dialog()

# 执行对话动作
func execute_dialog_action(action: String, params: Dictionary) -> void:
	match action:
		"give_item":
			# 给予物品
			if params.has("item_id") and params.has("amount"):
				var item_id = params["item_id"]
				var amount = params["amount"]
				
				# 这里应该调用物品系统的相关方法
				print("给予物品: " + item_id + " x" + str(amount))
		
		"change_stat":
			# 改变玩家属性
			if params.has("stat") and params.has("value"):
				var stat = params["stat"]
				var value = params["value"]
				
				# 调用GameManager更新玩家属性
				match stat:
					"health":
						GameManager.add_player_health(value)
					"attack":
						GameManager.add_player_attack(value)
					"defense":
						GameManager.add_player_defense(value)
					"gold":
						GameManager.add_player_gold(value)
					"exp":
						GameManager.add_player_exp(value)
		
		"change_map":
			# 改变地图或楼层
			if params.has("floor"):
				var floor_number = params["floor"]
				
				# 调用GameManager加载楼层
				GameManager.load_floor(floor_number)
		
		"play_sound":
			# 播放音效
			if params.has("sound_id"):
				var sound_id = params["sound_id"]
				
				# 调用AudioManager播放音效
				if Engine.has_singleton("AudioManager"):
					var audio_manager = Engine.get_singleton("AudioManager")
					audio_manager.play_sfx(sound_id)
		
		"play_animation":
			# 播放动画
			if params.has("animation_id"):
				var animation_id = params["animation_id"]
				
				# 设置状态为动画播放中
				current_state = DialogState.ANIMATING
				
				# 这里应该播放相应的动画
				print("播放动画: " + animation_id)
				
				# 模拟动画播放时间
				await get_tree().create_timer(1.0).timeout
				
				# 恢复状态
				current_state = DialogState.WAITING
		
		"set_flag":
			# 设置游戏标志
			if params.has("flag") and params.has("value"):
				var flag = params["flag"]
				var value = params["value"]
				
				# 这里应该设置游戏标志
				print("设置标志: " + flag + " = " + str(value))
		
		_:
			push_error("未知的对话动作: " + action)

# 游戏状态变化处理
func _on_game_state_changed(old_state: int, new_state: int) -> void:
	# 如果离开对话状态，结束当前对话
	if old_state == GameManager.GameState.DIALOG and new_state != GameManager.GameState.DIALOG:
		if current_state != DialogState.IDLE:
			end_dialog()