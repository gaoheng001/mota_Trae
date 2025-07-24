extends Node
# 战斗管理器 - 负责处理游戏中的战斗逻辑和伤害计算

# 战斗状态枚举
enum BattleState {
	INITIALIZING,
	PLAYER_TURN,
	ENEMY_TURN,
	BATTLE_END
}

# 当前战斗状态
var current_battle_state: BattleState = BattleState.INITIALIZING

# 当前战斗中的敌人数据
var current_enemy: Dictionary = {}

# 战斗结果
var battle_result: Dictionary = {}

# 信号
signal battle_started(enemy_data)
signal battle_ended(result)
signal turn_changed(turn_state)
signal damage_dealt(target, amount)

# 初始化
func _ready() -> void:
	print("战斗管理器初始化")

# 开始战斗
func start_battle(enemy_id: String) -> void:
	# 获取敌人数据
	var enemy_data = load_enemy_data(enemy_id)
	if enemy_data.is_empty():
		print("错误：无法加载敌人数据，ID: " + enemy_id)
		return
	
	# 设置当前敌人
	current_enemy = enemy_data
	
	# 重置战斗状态
	current_battle_state = BattleState.INITIALIZING
	battle_result = {}
	
	# 通知游戏管理器战斗开始
	GameManager.change_game_state(GameManager.GameState.BATTLE)
	
	# 发送战斗开始信号
	battle_started.emit(current_enemy)
	
	# 预先模拟战斗结果
	var simulation = simulate_battle()
	
	# 如果玩家无法对敌人造成伤害，提前结束战斗
	if simulation.player_damage_per_turn <= 0:
		end_battle({
			"victory": false,
			"reason": "无法对敌人造成伤害"
		})
		return
	
	# 如果敌人无法对玩家造成伤害，且玩家可以击败敌人
	if simulation.enemy_damage_per_turn <= 0 and simulation.player_damage_per_turn > 0:
		end_battle({
			"victory": true,
			"damage_taken": 0,
			"turns": ceil(float(current_enemy.health) / simulation.player_damage_per_turn)
		})
		return
	
	# 如果玩家会在战斗中死亡
	if simulation.player_health_after_battle <= 0:
		end_battle({
			"victory": false,
			"reason": "生命值不足"
		})
		return
	
	# 正常战斗流程
	current_battle_state = BattleState.PLAYER_TURN
	turn_changed.emit(current_battle_state)
	
	# 自动执行战斗
	execute_battle()

# 加载敌人数据
func load_enemy_data(enemy_id: String) -> Dictionary:
	# 这里应该从数据文件加载敌人数据
	# 暂时使用硬编码的示例数据
	
	# 基础敌人属性
	var base_enemies = {
		"slime": {
			"id": "slime",
			"name": "史莱姆",
			"health": 50,
			"attack": 15,
			"defense": 2,
			"gold": 5,
			"exp": 5,
			"special_abilities": []
		},
		"bat": {
			"id": "bat",
			"name": "蝙蝠",
			"health": 35,
			"attack": 20,
			"defense": 5,
			"gold": 8,
			"exp": 8,
			"special_abilities": []
		},
		"skeleton": {
			"id": "skeleton",
			"name": "骷髅",
			"health": 100,
			"attack": 25,
			"defense": 10,
			"gold": 12,
			"exp": 12,
			"special_abilities": []
		},
		"orc": {
			"id": "orc",
			"name": "兽人",
			"health": 150,
			"attack": 40,
			"defense": 15,
			"gold": 20,
			"exp": 20,
			"special_abilities": []
		},
		"ghost": {
			"id": "ghost",
			"name": "幽灵",
			"health": 80,
			"attack": 30,
			"defense": 0,  # 幽灵防御为0但有特殊能力
			"gold": 15,
			"exp": 15,
			"special_abilities": ["dodge"]  # 闪避能力
		},
		"dragon": {
			"id": "dragon",
			"name": "龙",
			"health": 500,
			"attack": 100,
			"defense": 50,
			"gold": 100,
			"exp": 100,
			"special_abilities": ["fire_breath"]  # 火焰吐息
		}
	}
	
	# 检查敌人ID是否存在
	if base_enemies.has(enemy_id):
		return base_enemies[enemy_id]
	
	# 如果找不到指定ID，返回默认敌人
	if enemy_id.begins_with("random"):
		# 随机选择一个敌人
		var keys = base_enemies.keys()
		var random_index = randi() % keys.size()
		return base_enemies[keys[random_index]]
	
	# 如果都不匹配，返回空字典
	return {}

# 计算伤害
func calculate_damage(attacker_attack: int, defender_defense: int) -> int:
	var damage = attacker_attack - defender_defense
	return max(1, damage)  # 最低伤害为1

# 模拟战斗结果
func simulate_battle() -> Dictionary:
	# 获取玩家数据
	var player_health = GameManager.player_data["health"]
	var player_attack = GameManager.player_data["attack"]
	var player_defense = GameManager.player_data["defense"]
	
	# 获取敌人数据
	var enemy_health = current_enemy["health"]
	var enemy_attack = current_enemy["attack"]
	var enemy_defense = current_enemy["defense"]
	
	# 计算每回合伤害
	var player_damage_per_turn = calculate_damage(player_attack, enemy_defense)
	var enemy_damage_per_turn = calculate_damage(enemy_attack, player_defense)
	
	# 计算击败敌人所需回合数
	var turns_to_defeat_enemy = ceil(float(enemy_health) / player_damage_per_turn) if player_damage_per_turn > 0 else 999
	
	# 计算玩家受到的总伤害（玩家先手，最后一回合击败敌人时敌人不会攻击）
	var total_damage_to_player = enemy_damage_per_turn * (turns_to_defeat_enemy - 1) if enemy_damage_per_turn > 0 and turns_to_defeat_enemy > 0 else 0
	
	# 计算战斗后玩家剩余生命值
	var player_health_after_battle = player_health - total_damage_to_player
	
	# 返回模拟结果
	return {
		"player_damage_per_turn": player_damage_per_turn,
		"enemy_damage_per_turn": enemy_damage_per_turn,
		"turns_to_defeat_enemy": turns_to_defeat_enemy,
		"total_damage_to_player": total_damage_to_player,
		"player_health_after_battle": player_health_after_battle,
		"victory": player_health_after_battle > 0
	}

# 执行战斗
func execute_battle() -> void:
	# 获取战斗模拟结果
	var simulation = simulate_battle()
	
	# 如果模拟结果显示玩家会胜利
	if simulation.victory:
		# 更新玩家生命值
		GameManager.update_player_stat("health", simulation.player_health_after_battle)
		
		# 增加金币和经验
		GameManager.add_player_stat("gold", current_enemy["gold"])
		GameManager.add_exp(current_enemy["exp"])
		
		# 结束战斗
		end_battle({
			"victory": true,
			"damage_taken": simulation.total_damage_to_player,
			"turns": simulation.turns_to_defeat_enemy,
			"gold_gained": current_enemy["gold"],
			"exp_gained": current_enemy["exp"]
		})
	else:
		# 玩家失败
		end_battle({
			"victory": false,
			"reason": "生命值不足"
		})

# 玩家回合
func player_turn() -> void:
	if current_battle_state != BattleState.PLAYER_TURN:
		return
	
	# 计算玩家对敌人的伤害
	var damage = calculate_damage(GameManager.player_data["attack"], current_enemy["defense"])
	
	# 应用伤害
	current_enemy["health"] -= damage
	
	# 发送伤害信号
	damage_dealt.emit("enemy", damage)
	
	# 检查敌人是否被击败
	if current_enemy["health"] <= 0:
		# 战斗胜利
		end_battle({
			"victory": true,
			"gold_gained": current_enemy["gold"],
			"exp_gained": current_enemy["exp"]
		})
	else:
		# 切换到敌人回合
		current_battle_state = BattleState.ENEMY_TURN
		turn_changed.emit(current_battle_state)
		
		# 执行敌人回合
		enemy_turn()

# 敌人回合
func enemy_turn() -> void:
	if current_battle_state != BattleState.ENEMY_TURN:
		return
	
	# 计算敌人对玩家的伤害
	var damage = calculate_damage(current_enemy["attack"], GameManager.player_data["defense"])
	
	# 应用伤害
	GameManager.reduce_player_stat("health", damage)
	
	# 发送伤害信号
	damage_dealt.emit("player", damage)
	
	# 检查玩家是否被击败
	if GameManager.player_data["health"] <= 0:
		# 战斗失败
		end_battle({
			"victory": false,
			"reason": "生命值耗尽"
		})
	else:
		# 切换回玩家回合
		current_battle_state = BattleState.PLAYER_TURN
		turn_changed.emit(current_battle_state)
		
		# 继续玩家回合
		player_turn()

# 结束战斗
func end_battle(result: Dictionary) -> void:
	# 设置战斗结果
	battle_result = result
	
	# 更新战斗状态
	current_battle_state = BattleState.BATTLE_END
	
	# 发送战斗结束信号
	battle_ended.emit(battle_result)
	
	# 通知游戏管理器战斗结束
	GameManager.change_game_state(GameManager.GameState.PLAYING)
	
	# 打印战斗结果
	if result["victory"]:
		print("战斗胜利！获得金币: " + str(result.get("gold_gained", 0)) + ", 经验: " + str(result.get("exp_gained", 0)))
	else:
		print("战斗失败！原因: " + result.get("reason", "未知"))

# 检查是否可以战胜敌人
func can_defeat_enemy(enemy_id: String) -> Dictionary:
	# 加载敌人数据
	var enemy_data = load_enemy_data(enemy_id)
	if enemy_data.is_empty():
		return {"can_win": false, "reason": "未知敌人"}
	
	# 保存当前敌人
	var temp_enemy = current_enemy
	current_enemy = enemy_data
	
	# 模拟战斗
	var simulation = simulate_battle()
	
	# 恢复当前敌人
	current_enemy = temp_enemy
	
	# 返回结果
	if simulation.player_damage_per_turn <= 0:
		return {"can_win": false, "reason": "无法对敌人造成伤害"}
	
	if not simulation.victory:
		return {"can_win": false, "reason": "生命值不足", "damage_needed": -simulation.player_health_after_battle}
	
	return {
		"can_win": true,
		"damage_taken": simulation.total_damage_to_player,
		"turns": simulation.turns_to_defeat_enemy
	}