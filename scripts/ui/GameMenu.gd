extends Control
# 游戏菜单 - 处理游戏暂停时的菜单界面

# 节点引用
@onready var panel = $Panel
@onready var save_panel = $SavePanel
@onready var load_panel = $LoadPanel
@onready var settings_panel = $SettingsPanel
@onready var confirm_panel = $ConfirmPanel

# 按钮引用
@onready var resume_button = $Panel/VBoxContainer/ResumeButton
@onready var save_button = $Panel/VBoxContainer/SaveButton
@onready var load_button = $Panel/VBoxContainer/LoadButton
@onready var settings_button = $Panel/VBoxContainer/SettingsButton
@onready var main_menu_button = $Panel/VBoxContainer/MainMenuButton
@onready var exit_button = $Panel/VBoxContainer/ExitButton

# 存档按钮引用
@onready var save_slots = $SavePanel/SaveSlots.get_children()
@onready var save_cancel_button = $SavePanel/CancelButton

# 读档按钮引用
@onready var load_slots = $LoadPanel/LoadSlots.get_children()
@onready var load_cancel_button = $LoadPanel/CancelButton

# 设置面板引用
@onready var settings_save_button = $SettingsPanel/SaveButton
@onready var settings_cancel_button = $SettingsPanel/CancelButton
@onready var music_slider = $SettingsPanel/VBoxContainer/MusicVolume/HSlider
@onready var sound_slider = $SettingsPanel/VBoxContainer/SoundVolume/HSlider
@onready var fullscreen_checkbox = $SettingsPanel/VBoxContainer/FullScreen/CheckBox

# 确认面板引用
@onready var confirm_message = $ConfirmPanel/Message
@onready var confirm_yes_button = $ConfirmPanel/HBoxContainer/YesButton
@onready var confirm_no_button = $ConfirmPanel/HBoxContainer/NoButton

# 确认操作类型
enum ConfirmAction { NONE, MAIN_MENU, EXIT }
var current_confirm_action = ConfirmAction.NONE

# 初始化
func _ready() -> void:
	# 连接按钮信号
	connect_buttons()
	
	# 初始隐藏所有面板
	save_panel.visible = false
	load_panel.visible = false
	settings_panel.visible = false
	confirm_panel.visible = false
	
	# 加载设置
	load_settings()
	
	# 更新存档按钮状态
	update_save_slots()
	update_load_slots()

# 连接按钮信号
func connect_buttons() -> void:
	# 主菜单按钮
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	# 存档面板按钮
	for i in range(save_slots.size()):
		save_slots[i].pressed.connect(_on_save_slot_pressed.bind(i))
	save_cancel_button.pressed.connect(_on_save_cancel_pressed)
	
	# 读档面板按钮
	for i in range(load_slots.size()):
		load_slots[i].pressed.connect(_on_load_slot_pressed.bind(i))
	load_cancel_button.pressed.connect(_on_load_cancel_pressed)
	
	# 设置面板按钮
	settings_save_button.pressed.connect(_on_settings_save_pressed)
	settings_cancel_button.pressed.connect(_on_settings_cancel_pressed)
	
	# 确认面板按钮
	confirm_yes_button.pressed.connect(_on_confirm_yes_pressed)
	confirm_no_button.pressed.connect(_on_confirm_no_pressed)

# 加载设置
func load_settings() -> void:
	# 这里应该从配置文件加载设置
	# 暂时使用默认值
	music_slider.value = 0.8
	sound_slider.value = 0.8
	fullscreen_checkbox.button_pressed = false

# 保存设置
func save_settings() -> void:
	# 这里应该保存设置到配置文件
	# 暂时只应用设置
	apply_settings()

# 应用设置
func apply_settings() -> void:
	# 设置音乐音量
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_slider.value))
	
	# 设置音效音量
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sound_slider.value))
	
	# 设置全屏
	if fullscreen_checkbox.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# 更新存档按钮状态
func update_save_slots() -> void:
	var save_info = SaveManager.get_all_save_info()
	
	for i in range(save_slots.size()):
		var slot = i + 1
		if save_info.has(str(slot)) and save_info[str(slot)] != null:
			var info = save_info[str(slot)]
			var floor_text = "第" + str(info["floor"]) + "层"
			var level_text = "等级" + str(info["level"])
			var time_text = info["time"]
			save_slots[i].text = "存档 " + str(slot) + ": " + floor_text + " | " + level_text + " | " + time_text
		else:
			save_slots[i].text = "存档 " + str(slot) + ": 空"

# 更新读档按钮状态
func update_load_slots() -> void:
	var save_info = SaveManager.get_all_save_info()
	
	for i in range(load_slots.size()):
		var slot = i + 1
		if save_info.has(str(slot)) and save_info[str(slot)] != null:
			var info = save_info[str(slot)]
			var floor_text = "第" + str(info["floor"]) + "层"
			var level_text = "等级" + str(info["level"])
			var time_text = info["time"]
			load_slots[i].text = "存档 " + str(slot) + ": " + floor_text + " | " + level_text + " | " + time_text
			load_slots[i].disabled = false
		else:
			load_slots[i].text = "存档 " + str(slot) + ": 空"
			load_slots[i].disabled = true

# 显示确认对话框
func show_confirm_dialog(message: String, action: ConfirmAction) -> void:
	current_confirm_action = action
	confirm_message.text = message
	
	# 隐藏其他面板
	panel.visible = false
	save_panel.visible = false
	load_panel.visible = false
	settings_panel.visible = false
	
	# 显示确认面板
	confirm_panel.visible = true

# 隐藏所有面板
func hide_all_panels() -> void:
	panel.visible = true
	save_panel.visible = false
	load_panel.visible = false
	settings_panel.visible = false
	confirm_panel.visible = false

# 继续游戏按钮处理
func _on_resume_pressed() -> void:
	# 隐藏菜单并恢复游戏
	visible = false
	GameManager.change_game_state(GameManager.GameState.PLAYING)

# 保存游戏按钮处理
func _on_save_pressed() -> void:
	# 更新存档按钮状态
	update_save_slots()
	
	# 显示存档面板
	panel.visible = false
	save_panel.visible = true

# 加载游戏按钮处理
func _on_load_pressed() -> void:
	# 更新读档按钮状态
	update_load_slots()
	
	# 显示读档面板
	panel.visible = false
	load_panel.visible = true

# 设置按钮处理
func _on_settings_pressed() -> void:
	# 显示设置面板
	panel.visible = false
	settings_panel.visible = true

# 主菜单按钮处理
func _on_main_menu_pressed() -> void:
	# 显示确认对话框
	show_confirm_dialog("确定要返回主菜单吗？未保存的进度将会丢失。", ConfirmAction.MAIN_MENU)

# 退出游戏按钮处理
func _on_exit_pressed() -> void:
	# 显示确认对话框
	show_confirm_dialog("确定要退出游戏吗？未保存的进度将会丢失。", ConfirmAction.EXIT)

# 存档槽按钮处理
func _on_save_slot_pressed(slot_index: int) -> void:
	# 保存游戏到指定槽位
	var slot = slot_index + 1
	SaveManager.save_game(slot)
	
	# 更新存档按钮状态
	update_save_slots()
	
	# 显示保存成功消息
	print("游戏已保存到槽位 " + str(slot))
	
	# 返回主菜单
	hide_all_panels()

# 存档取消按钮处理
func _on_save_cancel_pressed() -> void:
	# 返回主菜单
	hide_all_panels()

# 读档槽按钮处理
func _on_load_slot_pressed(slot_index: int) -> void:
	# 加载指定槽位的游戏
	var slot = slot_index + 1
	SaveManager.load_game(slot)
	
	# 隐藏菜单并恢复游戏
	visible = false
	GameManager.change_game_state(GameManager.GameState.PLAYING)

# 读档取消按钮处理
func _on_load_cancel_pressed() -> void:
	# 返回主菜单
	hide_all_panels()

# 设置保存按钮处理
func _on_settings_save_pressed() -> void:
	# 保存设置
	save_settings()
	
	# 返回主菜单
	hide_all_panels()

# 设置取消按钮处理
func _on_settings_cancel_pressed() -> void:
	# 返回主菜单
	hide_all_panels()

# 确认对话框确定按钮处理
func _on_confirm_yes_pressed() -> void:
	match current_confirm_action:
		ConfirmAction.MAIN_MENU:
			# 返回主菜单
			get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
			
		ConfirmAction.EXIT:
			# 退出游戏
			get_tree().quit()
			
		_:
			# 返回主菜单
			hide_all_panels()

# 确认对话框取消按钮处理
func _on_confirm_no_pressed() -> void:
	# 返回主菜单
	hide_all_panels()