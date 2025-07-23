extends Node
# 配置管理器 - 负责管理游戏的配置设置

# 配置文件路径
const CONFIG_FILE_PATH: String = "user://config.cfg"

# 默认配置
var default_config: Dictionary = {
	# 音频设置
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"ui_volume": 0.7,
		"music_enabled": true,
		"sfx_enabled": true,
		"ui_enabled": true
	},
	
	# 视频设置
	"video": {
		"fullscreen": false,
		"vsync": true,
		"resolution": Vector2i(1280, 720),
		"pixel_perfect": true
	},
	
	# 游戏设置
	"gameplay": {
		"difficulty": 1,  # 0: 简单, 1: 普通, 2: 困难
		"show_damage_numbers": true,
		"show_battle_predictions": true,
		"auto_save": true,
		"auto_save_interval": 300  # 自动保存间隔（秒）
	},
	
	# 控制设置
	"controls": {
		"move_up": "W",
		"move_down": "S",
		"move_left": "A",
		"move_right": "D",
		"interact": "E",
		"menu": "Escape",
		"quick_save": "F5",
		"quick_load": "F9"
	},
	
	# 界面设置
	"ui": {
		"language": "zh_CN",
		"text_speed": 1.0,  # 文本显示速度
		"show_tooltips": true,
		"hud_opacity": 0.9
	}
}

# 当前配置
var config: Dictionary = {}

# 信号
signal config_changed(section, key, value)
signal config_loaded
signal config_saved

# 初始化
func _ready() -> void:
	print("配置管理器初始化")
	
	# 加载配置
	load_config()
	
	# 应用配置
	apply_config()

# 加载配置
func load_config() -> void:
	# 重置为默认配置
	config = default_config.duplicate(true)
	
	# 检查配置文件是否存在
	var config_file = ConfigFile.new()
	var err = config_file.load(CONFIG_FILE_PATH)
	
	if err != OK:
		print("无法加载配置文件，使用默认配置")
		save_config()  # 保存默认配置
		config_loaded.emit()
		return
	
	# 读取配置文件中的所有部分和键
	for section in config_file.get_sections():
		if not config.has(section):
			config[section] = {}
		
		for key in config_file.get_section_keys(section):
			var value = config_file.get_value(section, key)
			
			# 特殊处理分辨率（转换为Vector2i）
			if section == "video" and key == "resolution" and value is String:
				var parts = value.split("x")
				if parts.size() == 2:
					value = Vector2i(int(parts[0]), int(parts[1]))
			
			# 更新配置
			if config[section].has(key):
				config[section][key] = value
	
	print("配置加载完成")
	config_loaded.emit()

# 保存配置
func save_config() -> void:
	var config_file = ConfigFile.new()
	
	# 将配置写入ConfigFile对象
	for section in config.keys():
		for key in config[section].keys():
			var value = config[section][key]
			
			# 特殊处理分辨率（转换为字符串）
			if section == "video" and key == "resolution" and value is Vector2i:
				value = "%dx%d" % [value.x, value.y]
			
			config_file.set_value(section, key, value)
	
	# 保存到文件
	var err = config_file.save(CONFIG_FILE_PATH)
	if err != OK:
		push_error("无法保存配置文件: " + str(err))
		return
	
	print("配置保存完成")
	config_saved.emit()

# 应用配置
func apply_config() -> void:
	# 应用视频设置
	apply_video_config()
	
	# 应用音频设置
	apply_audio_config()
	
	# 应用UI设置
	apply_ui_config()
	
	# 应用游戏设置
	apply_gameplay_config()

# 应用视频设置
func apply_video_config() -> void:
	var video_config = config["video"]
	
	# 设置全屏模式
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if video_config["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
	)
	
	# 设置垂直同步
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if video_config["vsync"] else DisplayServer.VSYNC_DISABLED
	)
	
	# 设置分辨率（仅在窗口模式下）
	if not video_config["fullscreen"]:
		var resolution = video_config["resolution"]
		DisplayServer.window_set_size(resolution)
	
	# 设置像素完美模式
	if video_config["pixel_perfect"]:
		# 禁用所有纹理过滤
		RenderingServer.texture_set_default_filters(
			RenderingServer.TEXTURE_FILTER_NEAREST,
			RenderingServer.TEXTURE_FILTER_NEAREST,
			RenderingServer.TEXTURE_FILTER_NEAREST,
			RenderingServer.TEXTURE_FILTER_NEAREST
		)
	else:
		# 启用默认过滤
		RenderingServer.texture_set_default_filters(
			RenderingServer.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS,
			RenderingServer.TEXTURE_FILTER_LINEAR,
			RenderingServer.TEXTURE_FILTER_LINEAR,
			RenderingServer.TEXTURE_FILTER_LINEAR
		)

# 应用音频设置
func apply_audio_config() -> void:
	var audio_config = config["audio"]
	
	# 检查AudioManager是否可用
	if not Engine.has_singleton("AudioManager"):
		return
	
	var audio_manager = Engine.get_singleton("AudioManager")
	
	# 设置音量
	audio_manager.set_master_volume(audio_config["master_volume"])
	audio_manager.set_volume(audio_manager.AudioType.MUSIC, audio_config["music_volume"])
	audio_manager.set_volume(audio_manager.AudioType.SFX, audio_config["sfx_volume"])
	audio_manager.set_volume(audio_manager.AudioType.UI, audio_config["ui_volume"])
	
	# 设置启用状态
	audio_manager.set_audio_enabled(audio_manager.AudioType.MUSIC, audio_config["music_enabled"])
	audio_manager.set_audio_enabled(audio_manager.AudioType.SFX, audio_config["sfx_enabled"])
	audio_manager.set_audio_enabled(audio_manager.AudioType.UI, audio_config["ui_enabled"])

# 应用UI设置
func apply_ui_config() -> void:
	var ui_config = config["ui"]
	
	# 设置语言
	TranslationServer.set_locale(ui_config["language"])
	
	# 其他UI设置可以在UIManager中应用
	# 这里只是示例，实际项目中可能需要更复杂的处理

# 应用游戏设置
func apply_gameplay_config() -> void:
	var gameplay_config = config["gameplay"]
	
	# 游戏设置通常在游戏开始时应用
	# 这里只是示例，实际项目中可能需要更复杂的处理

# 获取配置值
func get_config(section: String, key: String, default_value = null):
	if not config.has(section) or not config[section].has(key):
		return default_value
	return config[section][key]

# 设置配置值
func set_config(section: String, key: String, value) -> void:
	# 确保部分存在
	if not config.has(section):
		config[section] = {}
	
	# 更新配置
	config[section][key] = value
	
	# 发出信号
	config_changed.emit(section, key, value)
	
	# 保存配置
	save_config()
	
	# 应用特定设置
	if section == "video":
		apply_video_config()
	elif section == "audio":
		apply_audio_config()
	elif section == "ui":
		apply_ui_config()
	elif section == "gameplay":
		apply_gameplay_config()

# 重置为默认配置
func reset_to_default() -> void:
	config = default_config.duplicate(true)
	save_config()
	apply_config()

# 重置特定部分的配置
func reset_section(section: String) -> void:
	if not default_config.has(section):
		return
	
	config[section] = default_config[section].duplicate(true)
	save_config()
	
	# 应用特定设置
	if section == "video":
		apply_video_config()
	elif section == "audio":
		apply_audio_config()
	elif section == "ui":
		apply_ui_config()
	elif section == "gameplay":
		apply_gameplay_config()

# 获取可用分辨率列表
func get_available_resolutions() -> Array:
	var resolutions = [
		Vector2i(1280, 720),
		Vector2i(1366, 768),
		Vector2i(1600, 900),
		Vector2i(1920, 1080),
		Vector2i(2560, 1440),
		Vector2i(3840, 2160)
	]
	
	return resolutions

# 获取可用语言列表
func get_available_languages() -> Dictionary:
	return {
		"en": "English",
		"zh_CN": "简体中文",
		"zh_TW": "繁體中文",
		"ja": "日本語",
		"ko": "한국어",
		"fr": "Français",
		"de": "Deutsch",
		"es": "Español",
		"ru": "Русский"
	}