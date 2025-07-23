extends Control
# 主菜单 - 游戏的入口点，提供开始新游戏、加载存档等功能

# 场景引用
@export var game_scene_path: String = "res://scenes/levels/GameWorld.tscn"
const GAME_WORLD_SCENE = "res://scenes/levels/GameWorld.tscn"

# 节点引用
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var load_button: Button = $VBoxContainer/LoadButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var exit_button: Button = $VBoxContainer/ExitButton
@onready var load_game_panel: Panel = $LoadGamePanel
@onready var settings_panel: Panel = $SettingsPanel
@onready var save_list = $LoadGamePanel/SaveList if has_node("LoadGamePanel/SaveList") else null

# 加载面板按钮
@onready var load_panel_load_button = $LoadGamePanel/LoadButton if has_node("LoadGamePanel/LoadButton") else null
@onready var load_panel_cancel_button = $LoadGamePanel/CancelButton if has_node("LoadGamePanel/CancelButton") else null

# 设置面板引用
@onready var settings_save_button = $SettingsPanel/SaveButton if has_node("SettingsPanel/SaveButton") else null
@onready var settings_cancel_button = $SettingsPanel/CancelButton if has_node("SettingsPanel/CancelButton") else null
@onready var music_slider = $SettingsPanel/VBoxContainer/MusicVolume/HSlider if has_node("SettingsPanel/VBoxContainer/MusicVolume/HSlider") else null
@onready var sound_slider = $SettingsPanel/VBoxContainer/SoundVolume/HSlider if has_node("SettingsPanel/VBoxContainer/SoundVolume/HSlider") else null
@onready var fullscreen_checkbox = $SettingsPanel/VBoxContainer/FullScreen/CheckBox if has_node("SettingsPanel/VBoxContainer/FullScreen/CheckBox") else null

# 初始化
func _ready() -> void:
	# 连接按钮信号
	connect_buttons()
	
	# 初始隐藏面板
	if load_game_panel:
		load_game_panel.visible = false
	if settings_panel:
		settings_panel.visible = false
	
	# 播放背景音乐
	play_background_music()
	
	# 检查存档
	update_load_button_state()
	
	# 加载设置
	load_settings()

# 连接按钮信号
func connect_buttons() -> void:
	# 主菜单按钮
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
	if load_button:
		load_button.pressed.connect(_on_load_button_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_button_pressed)
	if exit_button:
		exit_button.pressed.connect(_on_exit_button_pressed)
	
	# 加载面板按钮
	if load_panel_load_button:
		load_panel_load_button.pressed.connect(_on_load_panel_load_pressed)
	if load_panel_cancel_button:
		load_panel_cancel_button.pressed.connect(_on_close_load_panel_button_pressed)
	
	# 设置面板按钮
	if settings_save_button:
		settings_save_button.pressed.connect(_on_settings_save_pressed)
	if settings_cancel_button:
		settings_cancel_button.pressed.connect(_on_close_settings_panel_button_pressed)

# 播放背景音乐
func play_background_music() -> void:
	# 这里应该播放主菜单背景音乐
	# 例如：$BackgroundMusic.play()
	pass

# 更新加载按钮状态
func update_load_button_state() -> void:
	# 检查是否有可用的存档
	var has_saves = false
	var save_info = SaveManager.get_all_save_info()
	
	if not save_info.is_empty():
		has_saves = true
	
	# 更新加载按钮状态
	if load_button:
		load_button.disabled = not has_saves

# 开始新游戏
func start_new_game() -> void:
	# 初始化新游戏
	GameManager.start_new_game()
	
	# 切换到游戏场景
	change_to_game_scene()

# 加载游戏
func load_game(slot: int) -> void:
	# 尝试加载存档
	var success = SaveManager.load_game(slot)
	
	if success:
		# 切换到游戏场景
		change_to_game_scene()
	else:
		# 显示加载失败消息
		show_message("加载失败", "无法加载存档，请检查存档文件是否损坏。")

# 切换到游戏场景
func change_to_game_scene() -> void:
	# 切换场景
	var error = get_tree().change_scene_to_file(game_scene_path)
	
	if error != OK:
		push_error("无法加载游戏场景: " + game_scene_path)
		show_message("错误", "无法加载游戏场景，请检查游戏文件是否完整。")

# 显示消息
func show_message(title: String, message: String) -> void:
	# 这里应该显示一个消息对话框
	# 例如：MessageDialog.show(title, message)
	print(title + ": " + message)

# 开始按钮点击处理
func _on_start_button_pressed() -> void:
	# 检查是否有存档
	var save_info = SaveManager.get_all_save_info()
	
	if not save_info.is_empty():
		# 询问是否覆盖存档
		# 这里应该显示一个确认对话框
		# 例如：ConfirmationDialog.show("确认", "已有存档，开始新游戏将覆盖现有进度。是否继续？", self, "start_new_game")
		
		# 暂时直接开始新游戏
		start_new_game()
	else:
		# 直接开始新游戏
		start_new_game()

# 加载按钮点击处理
func _on_load_button_pressed() -> void:
	# 显示加载游戏面板
	if load_game_panel:
		load_game_panel.visible = true
		
		# 更新存档列表
		update_save_list()

# 设置按钮点击处理
func _on_settings_button_pressed() -> void:
	# 显示设置面板
	if settings_panel:
		settings_panel.visible = true

# 退出按钮点击处理
func _on_exit_button_pressed() -> void:
	# 询问是否确认退出
	# 这里应该显示一个确认对话框
	# 例如：ConfirmationDialog.show("确认", "确定要退出游戏吗？", self, "quit_game")
	
	# 暂时直接退出
	quit_game()

# 退出游戏
func quit_game() -> void:
	get_tree().quit()

# 更新存档列表
func update_save_list() -> void:
	# 获取所有存档信息
	var save_info = SaveManager.get_all_save_info()
	
	# 更新存档列表UI
	if save_list:
		# 清空列表
		save_list.clear()
		
		# 添加存档到列表
		var has_saves = false
		for slot in range(1, SaveManager.MAX_SAVE_SLOTS + 1):
			var slot_str = str(slot)
			if save_info.has(slot_str) and save_info[slot_str] != null:
				var info = save_info[slot_str]
				var floor_text = "第" + str(info["floor"]) + "层"
				var level_text = "等级" + str(info["level"])
				var time_text = info["time"]
				save_list.add_item("存档 " + slot_str + ": " + floor_text + " | " + level_text + " | " + time_text, null, true)
				save_list.set_item_metadata(save_list.get_item_count() - 1, slot)
				has_saves = true
			else:
				save_list.add_item("存档 " + slot_str + ": 空", null, false)
				save_list.set_item_metadata(save_list.get_item_count() - 1, slot)
		
		# 更新加载按钮状态
		if load_panel_load_button:
			load_panel_load_button.disabled = not has_saves or save_list.get_selected_items().size() == 0
		
		# 连接选择信号
		if not save_list.item_selected.is_connected(_on_save_item_selected):
			save_list.item_selected.connect(_on_save_item_selected)

# 存档项点击处理
func _on_save_item_selected(index: int) -> void:
	if save_list and load_panel_load_button:
		# 获取存档槽位
		var slot = save_list.get_item_metadata(index)
		
		# 更新加载按钮状态
		load_panel_load_button.disabled = false

# 加载面板加载按钮处理
func _on_load_panel_load_pressed() -> void:
	if save_list:
		# 获取选中的存档
		var selected_items = save_list.get_selected_items()
		if selected_items.size() > 0:
			var selected_index = selected_items[0]
			var slot = save_list.get_item_metadata(selected_index)
			
			# 加载游戏
			load_game(slot)

# 关闭加载面板
func _on_close_load_panel_button_pressed() -> void:
	if load_game_panel:
		load_game_panel.visible = false

# 设置面板保存按钮处理
func _on_settings_save_pressed() -> void:
	# 保存设置
	save_settings()
	
	# 隐藏设置面板
	if settings_panel:
		settings_panel.visible = false

# 关闭设置面板
func _on_close_settings_panel_button_pressed() -> void:
	if settings_panel:
		settings_panel.visible = false

# 加载设置
func load_settings() -> void:
	# 这里应该从配置文件加载设置
	# 暂时使用默认值
	if music_slider:
		music_slider.value = 0.8
	if sound_slider:
		sound_slider.value = 0.8
	if fullscreen_checkbox:
		fullscreen_checkbox.button_pressed = false

# 保存设置
func save_settings() -> void:
	# 这里应该保存设置到配置文件
	# 暂时只应用设置
	apply_settings()

# 应用设置
func apply_settings() -> void:
	# 设置音乐音量
	if music_slider:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_slider.value))
	
	# 设置音效音量
	if sound_slider:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sound_slider.value))
	
	# 设置全屏
	if fullscreen_checkbox:
		if fullscreen_checkbox.button_pressed:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)