extends Area2D
# NPC类 - 处理NPC的对话和交互

# NPC ID
@export var npc_id: String = "old_man"

# NPC数据
var npc_data: Dictionary = {}

# 对话面板
@onready var dialog_panel = $DialogPanel
@onready var name_label = $DialogPanel/Name
@onready var message_label = $DialogPanel/Message

# 对话状态
var is_talking: bool = false
var dialog_index: int = 0
var dialogs: Array = []

# 信号
signal dialog_started(npc_id)
signal dialog_ended(npc_id)
signal dialog_next(npc_id, index)

# 初始化
func _ready() -> void:
	# 隐藏对话面板
	dialog_panel.visible = false
	
	# 加载NPC数据
	load_npc_data()
	
	# 更新外观
	update_appearance()

# 加载NPC数据
func load_npc_data() -> void:
	# 这里应该从数据文件加载NPC数据
	# 暂时使用硬编码的示例数据
	var npc_database = {
		"old_man": {
			"name": "老人",
			"sprite": "res://assets/sprites/npcs/old_man.png",
			"dialogs": [
				"欢迎来到魔塔，勇者！你需要收集钥匙，打败怪物，最终到达塔顶。",
				"每层楼都有不同的怪物和宝物，要谨慎选择你的战斗。",
				"记得收集各种钥匙，它们将帮助你打开通往更高层的道路。"
			],
			"gives_item": "",
			"requires_item": "",
			"special_effect": ""
		},
		"merchant": {
			"name": "商人",
			"sprite": "res://assets/sprites/npcs/merchant.png",
			"dialogs": [
				"你好，勇者！我有一些物品可以卖给你。",
				"用50金币换一把黄钥匙怎么样？",
				"或者用100金币提升你的攻击力？"
			],
			"gives_item": "yellow_key",
			"requires_item": "gold",
			"special_effect": "increase_attack"
		},
		"princess": {
			"name": "公主",
			"sprite": "res://assets/sprites/npcs/princess.png",
			"dialogs": [
				"勇敢的勇者，请救救我！",
				"魔王将我囚禁在这座塔的顶层。",
				"只有击败他，才能解救我和这个王国。"
			],
			"gives_item": "",
			"requires_item": "",
			"special_effect": ""
		},
		"wizard": {
			"name": "魔法师",
			"sprite": "res://assets/sprites/npcs/wizard.png",
			"dialogs": [
				"我是这座塔的魔法师，可以为你提供一些帮助。",
				"给我一个蓝宝石，我可以告诉你下一层的秘密。",
				"或者给我一个红宝石，我可以提升你的防御力。"
			],
			"gives_item": "",
			"requires_item": "blue_gem",
			"special_effect": "reveal_map"
		}
	}
	
	# 获取NPC数据
	if npc_database.has(npc_id):
		npc_data = npc_database[npc_id]
		dialogs = npc_data["dialogs"]
	else:
		push_error("NPC ID不存在: " + npc_id)
		npc_data = {
			"name": "未知NPC",
			"sprite": "res://assets/sprites/npcs/unknown.png",
			"dialogs": ["..."]
		}
		dialogs = npc_data["dialogs"]

# 更新外观
func update_appearance() -> void:
	# 设置精灵纹理
	if npc_data.has("sprite") and ResourceLoader.exists(npc_data["sprite"]):
		var texture = load(npc_data["sprite"])
		if texture:
			$Sprite2D.texture = texture

# 开始对话
func start_dialog() -> void:
	if is_talking:
		next_dialog()
		return
	
	is_talking = true
	dialog_index = 0
	
	# 显示对话面板
	dialog_panel.visible = true
	name_label.text = npc_data["name"]
	message_label.text = dialogs[dialog_index]
	
	# 发出信号
	emit_signal("dialog_started", npc_id)

# 下一段对话
func next_dialog() -> void:
	dialog_index += 1
	
	if dialog_index >= dialogs.size():
		end_dialog()
		return
	
	# 更新对话内容
	message_label.text = dialogs[dialog_index]
	
	# 发出信号
	emit_signal("dialog_next", npc_id, dialog_index)

# 结束对话
func end_dialog() -> void:
	is_talking = false
	dialog_panel.visible = false
	
	# 处理特殊效果
	if npc_data.has("special_effect") and npc_data["special_effect"] != "":
		apply_special_effect()
	
	# 发出信号
	emit_signal("dialog_ended", npc_id)

# 应用特殊效果
func apply_special_effect() -> void:
	var effect = npc_data["special_effect"]
	var requires_item = npc_data["requires_item"]
	var gives_item = npc_data["gives_item"]
	
	# 检查是否需要物品
	if requires_item != "":
		if not GameManager.has_item(requires_item):
			return
		
		# 消耗物品
		GameManager.remove_item(requires_item)
	
	# 给予物品
	if gives_item != "":
		GameManager.add_item(gives_item)
	
	# 应用效果
	match effect:
		"increase_attack":
			GameManager.increase_player_attack(5)
		"increase_defense":
			GameManager.increase_player_defense(5)
		"increase_health":
			GameManager.increase_player_max_health(100)
		"reveal_map":
			MapManager.reveal_map()
		"teleport":
			var target_floor = int(npc_data.get("target_floor", GameManager.game_progress["current_floor"]))
			GameManager.change_floor(target_floor)

# 交互
func interact() -> void:
	start_dialog()

# 鼠标进入
func _on_mouse_entered() -> void:
	if not is_talking:
		dialog_panel.visible = true
		name_label.text = npc_data["name"]
		message_label.text = "按E键交谈"

# 鼠标离开
func _on_mouse_exited() -> void:
	if not is_talking:
		dialog_panel.visible = false

# 输入事件
func _on_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		start_dialog()