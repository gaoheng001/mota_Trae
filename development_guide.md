# 魔塔游戏开发指南

本文档提供了魔塔游戏项目的开发指南，包括编码规范、最佳实践和工作流程。

## 编码规范

### 命名约定

- **文件名**: 使用PascalCase（如`PlayerController.gd`、`MainMenu.tscn`）
- **节点名**: 使用PascalCase（如`Player`、`EnemySpawner`）
- **变量名**: 使用snake_case（如`player_health`、`current_floor`）
- **常量**: 使用SCREAMING_SNAKE_CASE（如`MAX_HEALTH`、`ENEMY_TYPES`）
- **函数名**: 使用snake_case（如`move_player`、`calculate_damage`）
- **信号名**: 使用snake_case，通常使用过去时态（如`health_changed`、`enemy_defeated`）

### 代码组织

在每个脚本中，按以下顺序组织代码：

1. 类文档注释
2. 继承声明
3. 类级别注释
4. 常量
5. 导出变量
6. 公共变量
7. 私有变量
8. 信号声明
9. 内部类或枚举
10. `_init()` 方法
11. `_ready()` 方法
12. `_process()` 或 `_physics_process()` 方法
13. 公共方法
14. 私有方法
15. 信号回调方法

### 注释规范

- 使用中文注释，保持一致性
- 为每个脚本、类、函数和复杂逻辑添加注释
- 使用 `#` 进行单行注释
- 对于多行注释，每行都使用 `#` 并保持对齐

示例：

```gdscript
# 玩家控制器脚本
# 负责处理玩家输入和移动逻辑
extends CharacterBody2D

# 玩家移动速度
@export var move_speed: float = 100.0

# 处理玩家输入并移动角色
func _physics_process(delta: float) -> void:
    # 获取输入方向
    var direction = Vector2.ZERO
    direction.x = Input.get_axis("move_left", "move_right")
    direction.y = Input.get_axis("move_up", "move_down")
    
    # 归一化方向向量，防止对角线移动速度更快
    if direction.length() > 1.0:
        direction = direction.normalized()
    
    # 应用移动
    velocity = direction * move_speed
    move_and_slide()
```

## 最佳实践

### 信号使用

- 使用信号实现松耦合的组件通信
- 信号命名应清晰表达事件的性质
- 避免过度使用信号，对于简单的父子节点通信，可以直接调用方法

### 资源管理

- 使用资源预加载（`preload`）加载常用资源
- 对于大型资源或不常用资源，使用动态加载（`load`）
- 使用资源引用（`Resource`）共享数据，而不是复制数据

### 性能优化

- 避免在 `_process` 或 `_physics_process` 中执行昂贵的操作
- 使用对象池模式管理频繁创建和销毁的对象
- 对于大型地图，实现视野范围内的动态加载和卸载
- 使用 `Node.set_process(false)` 和 `Node.set_physics_process(false)` 暂停不需要每帧更新的节点

### 调试技巧

- 使用 `print()` 或 `print_debug()` 输出调试信息
- 使用 Godot 的调试器设置断点和检查变量
- 使用 `@onready` 标记延迟初始化的变量，避免空引用错误

## 工作流程

### 功能开发流程

1. **计划**: 明确功能需求和设计
2. **实现**: 编写代码和创建必要的场景
3. **测试**: 确保功能正常工作且没有明显bug
4. **优化**: 改进代码质量和性能
5. **文档**: 更新相关文档

### 版本控制工作流

1. 从主分支创建功能分支（`feature/feature-name`）
2. 在功能分支上开发和测试
3. 完成后，将主分支合并到功能分支，解决冲突
4. 创建合并请求（Pull Request）
5. 代码审查通过后，合并到主分支

### 发布流程

1. 从主分支创建发布分支（`release/vX.Y.Z`）
2. 在发布分支上进行最终测试和bug修复
3. 完成后，将发布分支合并到主分支和开发分支
4. 在主分支上创建标签（`vX.Y.Z`）
5. 构建发布版本

## 常见问题解决

### 节点引用为空

- 确保使用 `@onready` 或在 `_ready()` 中初始化节点引用
- 检查节点路径是否正确
- 确保引用的节点已添加到场景树中

### 信号连接问题

- 确保信号名称拼写正确
- 检查信号连接代码是否在正确的时机执行
- 使用 Godot 编辑器的信号面板检查连接状态

### 性能问题

- 使用Godot的性能监视器识别瓶颈
- 检查是否有不必要的每帧操作
- 考虑使用多线程处理耗时操作

## 学习资源

- [Godot 官方文档](https://docs.godotengine.org/)
- [GDScript 风格指南](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [Godot 教程](https://docs.godotengine.org/en/stable/tutorials/index.html)
- [Godot Reddit 社区](https://www.reddit.com/r/godot/)
- [Godot Discord 服务器](https://discord.gg/4JBkykG)

## 贡献指南

1. 确保你的代码遵循本文档中的编码规范
2. 为新功能编写测试和文档
3. 确保你的代码不会破坏现有功能
4. 提交前进行自我代码审查
5. 在提交消息中清晰描述你的更改

---

本指南将随项目发展不断更新。如有任何建议或问题，请通过项目Issues页面提出。