extends Node
# UI管理器 - 负责管理游戏中的所有UI界面

# UI界面枚举
enum UIScreen {
	MAIN_MENU,    # 主菜单
	GAME_HUD,     # 游戏HUD
	PAUSE_MENU,   # 暂停菜单
	INVENTORY,    # 物品栏
	DIALOG,       # 对话框
	BATTLE,       # 战斗界面
	GAME_OVER,    # 游戏结束
	SAVE_LOAD,    # 存档/读档
	SETTINGS,     # 设置
	HELP          # 帮助
}

# UI界面路径
const UI_PATHS = {
	UIScreen.MAIN_MENU: "res://scenes/ui/MainMenu.tscn",
	UIScreen.GAME_HUD: "res://scenes/ui/GameHUD.tscn",
	UIScreen.PAUSE_MENU: "res://scenes/ui/PauseMenu.tscn",
	UIScreen.INVENTORY: "res://scenes/ui/Inventory.tscn",
	UIScreen.DIALOG: "res://scenes/ui/DialogBox.tscn",
	UIScreen.BATTLE: "res://scenes/ui/BattleScreen.tscn",
	UIScreen.GAME_OVER: "res://scenes/ui/GameOver.tscn",
	UIScreen.SAVE_LOAD: "res://scenes/ui/SaveLoadScreen.tscn",
	UIScreen.SETTINGS: "res://scenes/ui/SettingsScreen.tscn",
	UIScreen.HELP: "res://scenes/ui/HelpScreen.tscn"
}

# 当前活动的UI界面
var active_screens: Dictionary = {}

# UI根节点
var ui_root: Control

# 信号
signal ui_screen_shown(screen_type)
signal ui_screen_hidden(screen_type)

# 初始化
func _ready() -> void:
	print("UI管理器初始化")
	
	# 等待一帧，确保场景树已完全加载
	await get_tree().process_frame
	
	# 查找UI根节点
	ui_root = get_ui_root()
	if not ui_root:
		push_error("找不到UI根节点")
		return
	
	# 连接游戏管理器信号
	GameManager.game_state_changed.connect(_on_game_state_changed)

# 获取UI根节点
func get_ui_root() -> Control:
	# 尝试在场景树中查找UI根节点
	var root = get_tree().root
	var main = root.get_child(root.get_child_count() - 1)
	
	# 查找名为"UI"的节点
	var ui = main.get_node_or_null("UI")
	if ui and ui is Control:
		return ui
	
	# 如果找不到，创建一个新的UI根节点
	ui = Control.new()
	ui.name = "UI"
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.add_child(ui)
	
	return ui

# 显示UI界面
func show_screen(screen_type: UIScreen, data: Dictionary = {}) -> Control:
	# 检查UI根节点
	if not ui_root:
		push_error("UI根节点未初始化")
		return null
	
	# 检查界面是否已经显示
	if active_screens.has(screen_type):
		return active_screens[screen_type]
	
	# 获取界面路径
	var screen_path = UI_PATHS.get(screen_type, "")
	if screen_path.is_empty():
		push_error("未定义UI界面路径: " + str(screen_type))
		return null
	
	# 加载界面场景
	var screen_scene = load(screen_path)
	if not screen_scene:
		push_error("无法加载UI界面: " + screen_path)
		return null
	
	# 实例化界面
	var screen_instance = screen_scene.instantiate()
	if not screen_instance:
		push_error("无法实例化UI界面: " + screen_path)
		return null
	
	# 添加到UI根节点
	ui_root.add_child(screen_instance)
	
	# 调用界面的初始化方法（如果有）
	if screen_instance.has_method("initialize"):
		screen_instance.initialize(data)
	
	# 记录活动界面
	active_screens[screen_type] = screen_instance
	
	# 发出信号
	ui_screen_shown.emit(screen_type)
	
	return screen_instance

# 隐藏UI界面
func hide_screen(screen_type: UIScreen) -> void:
	# 检查界面是否显示
	if not active_screens.has(screen_type):
		return
	
	# 获取界面实例
	var screen_instance = active_screens[screen_type]
	
	# 调用界面的清理方法（如果有）
	if screen_instance.has_method("cleanup"):
		screen_instance.cleanup()
	
	# 从UI根节点移除
	screen_instance.queue_free()
	
	# 从活动界面中移除
	active_screens.erase(screen_type)
	
	# 发出信号
	ui_screen_hidden.emit(screen_type)

# 隐藏所有UI界面
func hide_all_screens() -> void:
	var screens_to_hide = active_screens.keys()
	for screen_type in screens_to_hide:
		hide_screen(screen_type)

# 获取活动界面
func get_active_screen(screen_type: UIScreen) -> Control:
	return active_screens.get(screen_type, null)

# 检查界面是否活动
func is_screen_active(screen_type: UIScreen) -> bool:
	return active_screens.has(screen_type)

# 更新HUD信息
func update_hud() -> void:
	var hud = get_active_screen(UIScreen.GAME_HUD)
	if hud and hud.has_method("update_stats"):
		hud.update_stats()

# 显示对话框
func show_dialog(speaker_name: String, dialog_text: String, options: Array = []) -> void:
	var dialog_data = {
		"speaker": speaker_name,
		"text": dialog_text,
		"options": options
	}
	
	var dialog = get_active_screen(UIScreen.DIALOG)
	if dialog:
		# 如果对话框已经显示，更新内容
		if dialog.has_method("set_dialog"):
			dialog.set_dialog(dialog_data)
	else:
		# 否则显示新对话框
		show_screen(UIScreen.DIALOG, dialog_data)

# 显示战斗界面
func show_battle(player_data: Dictionary, enemy_data: Dictionary) -> void:
	var battle_data = {
		"player": player_data,
		"enemy": enemy_data
	}
	
	show_screen(UIScreen.BATTLE, battle_data)

# 显示游戏结束界面
func show_game_over(is_victory: bool = false) -> void:
	var game_over_data = {
		"is_victory": is_victory
	}
	
	show_screen(UIScreen.GAME_OVER, game_over_data)

# 显示存档/读档界面
func show_save_load(is_save_mode: bool = true) -> void:
	var save_load_data = {
		"is_save_mode": is_save_mode
	}
	
	show_screen(UIScreen.SAVE_LOAD, save_load_data)

# 游戏状态变化处理
func _on_game_state_changed(old_state: int, new_state: int) -> void:
	# 根据游戏状态显示/隐藏相应界面
	match new_state:
		GameManager.GameState.MAIN_MENU:
			hide_all_screens()
			show_screen(UIScreen.MAIN_MENU)
		
		GameManager.GameState.PLAYING:
			hide_screen(UIScreen.MAIN_MENU)
			hide_screen(UIScreen.PAUSE_MENU)
			show_screen(UIScreen.GAME_HUD)
		
		GameManager.GameState.PAUSED:
			show_screen(UIScreen.PAUSE_MENU)
		
		GameManager.GameState.DIALOG:
			# 对话框通过show_dialog方法显示
			pass
		
		GameManager.GameState.BATTLE:
			# 战斗界面通过show_battle方法显示
			pass
		
		GameManager.GameState.GAME_OVER:
			show_game_over()