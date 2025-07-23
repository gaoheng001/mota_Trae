extends Node
# 音频管理器 - 负责管理游戏中的所有音频播放

# 音频类型枚举
enum AudioType {
	MUSIC,  # 背景音乐
	SFX,    # 音效
	UI      # 界面音效
}

# 音频播放器节点
var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var ui_players: Array[AudioStreamPlayer] = []

# 音频资源缓存
var music_cache: Dictionary = {}
var sfx_cache: Dictionary = {}
var ui_cache: Dictionary = {}

# 音量设置
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var ui_volume: float = 0.7
var master_volume: float = 1.0

# 音频设置
var is_music_enabled: bool = true
var is_sfx_enabled: bool = true
var is_ui_enabled: bool = true

# 当前播放的背景音乐
var current_music: String = ""

# 音效播放器池大小
const SFX_PLAYER_POOL_SIZE: int = 5
const UI_PLAYER_POOL_SIZE: int = 3

# 初始化
func _ready() -> void:
	print("音频管理器初始化")
	
	# 创建音乐播放器
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	music_player.volume_db = linear_to_db(music_volume * master_volume)
	add_child(music_player)
	
	# 创建音效播放器池
	for i in range(SFX_PLAYER_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		player.volume_db = linear_to_db(sfx_volume * master_volume)
		player.finished.connect(_on_sfx_finished.bind(player))
		player.name = "SFXPlayer" + str(i)
		add_child(player)
		sfx_players.append(player)
	
	# 创建UI音效播放器池
	for i in range(UI_PLAYER_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "UI"
		player.volume_db = linear_to_db(ui_volume * master_volume)
		player.finished.connect(_on_ui_finished.bind(player))
		player.name = "UIPlayer" + str(i)
		add_child(player)
		ui_players.append(player)
	
	# 加载设置
	load_settings()

# 播放背景音乐
func play_music(music_name: String, fade_time: float = 1.0) -> void:
	if not is_music_enabled or music_name == current_music:
		return
	
	# 记录当前音乐
	current_music = music_name
	
	# 加载音乐资源
	var stream = _load_audio_resource(music_name, AudioType.MUSIC)
	if not stream:
		push_error("无法加载音乐: " + music_name)
		return
	
	# 如果有淡入淡出效果
	if fade_time > 0 and music_player.playing:
		# 创建淡出效果
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, fade_time)
		tween.tween_callback(func():
			# 设置新的音乐并播放
			music_player.stream = stream
			music_player.play()
			
			# 创建淡入效果
			var fade_in_tween = create_tween()
			fade_in_tween.tween_property(music_player, "volume_db", 
				linear_to_db(music_volume * master_volume), fade_time)
		)
	else:
		# 直接播放新音乐
		music_player.stream = stream
		music_player.volume_db = linear_to_db(music_volume * master_volume)
		music_player.play()

# 停止背景音乐
func stop_music(fade_time: float = 1.0) -> void:
	if not music_player.playing:
		return
	
	if fade_time > 0:
		# 创建淡出效果
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, fade_time)
		tween.tween_callback(func():
			music_player.stop()
			current_music = ""
		)
	else:
		music_player.stop()
		current_music = ""

# 播放音效
func play_sfx(sfx_name: String, pitch_scale: float = 1.0, volume_scale: float = 1.0) -> void:
	if not is_sfx_enabled:
		return
	
	# 加载音效资源
	var stream = _load_audio_resource(sfx_name, AudioType.SFX)
	if not stream:
		push_error("无法加载音效: " + sfx_name)
		return
	
	# 查找可用的音效播放器
	var player = _get_available_player(sfx_players)
	if not player:
		# 如果没有可用的播放器，使用第一个（最早使用的）
		player = sfx_players[0]
		player.stop()
	
	# 设置音效并播放
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = linear_to_db(sfx_volume * master_volume * volume_scale)
	player.play()

# 播放UI音效
func play_ui(ui_name: String, pitch_scale: float = 1.0, volume_scale: float = 1.0) -> void:
	if not is_ui_enabled:
		return
	
	# 加载UI音效资源
	var stream = _load_audio_resource(ui_name, AudioType.UI)
	if not stream:
		push_error("无法加载UI音效: " + ui_name)
		return
	
	# 查找可用的UI音效播放器
	var player = _get_available_player(ui_players)
	if not player:
		# 如果没有可用的播放器，使用第一个（最早使用的）
		player = ui_players[0]
		player.stop()
	
	# 设置音效并播放
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = linear_to_db(ui_volume * master_volume * volume_scale)
	player.play()

# 设置音量
func set_volume(type: AudioType, volume: float) -> void:
	volume = clamp(volume, 0.0, 1.0)
	
	match type:
		AudioType.MUSIC:
			music_volume = volume
			if music_player:
				music_player.volume_db = linear_to_db(music_volume * master_volume)
		AudioType.SFX:
			sfx_volume = volume
			for player in sfx_players:
				player.volume_db = linear_to_db(sfx_volume * master_volume)
		AudioType.UI:
			ui_volume = volume
			for player in ui_players:
				player.volume_db = linear_to_db(ui_volume * master_volume)
	
	# 保存设置
	save_settings()

# 设置主音量
func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	
	# 更新所有播放器的音量
	if music_player:
		music_player.volume_db = linear_to_db(music_volume * master_volume)
	
	for player in sfx_players:
		player.volume_db = linear_to_db(sfx_volume * master_volume)
	
	for player in ui_players:
		player.volume_db = linear_to_db(ui_volume * master_volume)
	
	# 保存设置
	save_settings()

# 启用/禁用音频
func set_audio_enabled(type: AudioType, enabled: bool) -> void:
	match type:
		AudioType.MUSIC:
			is_music_enabled = enabled
			if not enabled and music_player.playing:
				stop_music(0.5)
		AudioType.SFX:
			is_sfx_enabled = enabled
		AudioType.UI:
			is_ui_enabled = enabled
	
	# 保存设置
	save_settings()

# 加载音频设置
func load_settings() -> void:
	# 这里应该从配置文件加载设置
	# 示例实现，实际项目中应该使用配置系统
	pass

# 保存音频设置
func save_settings() -> void:
	# 这里应该保存设置到配置文件
	# 示例实现，实际项目中应该使用配置系统
	pass

# 预加载音频资源
func preload_audio(audio_name: String, type: AudioType) -> void:
	_load_audio_resource(audio_name, type)

# 清除音频缓存
func clear_cache() -> void:
	music_cache.clear()
	sfx_cache.clear()
	ui_cache.clear()

# 音效播放完成回调
func _on_sfx_finished(player: AudioStreamPlayer) -> void:
	# 重置播放器状态
	player.pitch_scale = 1.0

# UI音效播放完成回调
func _on_ui_finished(player: AudioStreamPlayer) -> void:
	# 重置播放器状态
	player.pitch_scale = 1.0

# 获取可用的音频播放器
func _get_available_player(players: Array[AudioStreamPlayer]) -> AudioStreamPlayer:
	for player in players:
		if not player.playing:
			return player
	return null

# 加载音频资源
func _load_audio_resource(audio_name: String, type: AudioType) -> AudioStream:
	# 检查缓存
	var cache = music_cache
	var path_prefix = "res://assets/audio/music/"
	
	match type:
		AudioType.MUSIC:
			cache = music_cache
			path_prefix = "res://assets/audio/music/"
		AudioType.SFX:
			cache = sfx_cache
			path_prefix = "res://assets/audio/sfx/"
		AudioType.UI:
			cache = ui_cache
			path_prefix = "res://assets/audio/ui/"
	
	# 如果已缓存，直接返回
	if cache.has(audio_name):
		return cache[audio_name]
	
	# 尝试加载资源
	var file_path = path_prefix + audio_name
	if not file_path.ends_with(".ogg") and not file_path.ends_with(".wav"):
		# 尝试不同的扩展名
		if FileAccess.file_exists(file_path + ".ogg"):
			file_path += ".ogg"
		elif FileAccess.file_exists(file_path + ".wav"):
			file_path += ".wav"
		else:
			push_error("找不到音频文件: " + audio_name)
			return null
	
	# 加载资源
	var stream = load(file_path)
	if stream:
		# 缓存资源
		cache[audio_name] = stream
		return stream
	
	push_error("无法加载音频文件: " + file_path)
	return null