# 项目设置指南

本文档提供了魔塔游戏项目的关键设置信息，帮助开发者理解和配置项目。

## 项目设置

### 显示设置

- **窗口大小**: 1280x720 像素（默认）
- **缩放模式**: 保持宽高比（Keep Aspect）
- **像素化**: 禁用抗锯齿，保持像素风格的清晰度

### 输入映射

以下是推荐的输入映射设置：

| 动作名称 | 键盘映射 | 控制器映射 |
|---------|---------|----------|
| move_up | W, Up Arrow | D-Pad Up |
| move_down | S, Down Arrow | D-Pad Down |
| move_left | A, Left Arrow | D-Pad Left |
| move_right | D, Right Arrow | D-Pad Right |
| interact | E, Space, Enter | A Button |
| menu | Escape | Start Button |
| quick_save | F5 | - |
| quick_load | F9 | - |

### 物理设置

- **物理引擎**: 2D
- **重力**: 0（顶视角游戏不需要重力）

### 渲染设置

- **环境**: 2D
- **默认清除颜色**: #000000（黑色）

### 音频设置

- **音频总线**: 
  - Master
  - Music
  - SFX
  - UI

## 项目层级

推荐的场景层级结构：

```
Main (主场景)
├── GameWorld
│   ├── CurrentFloor
│   │   ├── TileMap
│   │   ├── Player
│   │   ├── Enemies
│   │   ├── Items
│   │   └── NPCs
│   └── Camera2D
├── UI
│   ├── HUD
│   │   ├── PlayerStats
│   │   └── MiniMap
│   ├── Dialogs
│   ├── Inventory
│   ├── BattleScreen
│   └── PauseMenu
└── AudioPlayers
    ├── MusicPlayer
    └── SFXPlayer
```

## 自动加载脚本

以下脚本应设置为自动加载（Autoload）：

| 脚本名称 | 路径 | 用途 |
|---------|-----|------|
| GameManager | res://scripts/autoload/GameManager.gd | 管理游戏状态和玩家数据 |
| MapManager | res://scripts/autoload/MapManager.gd | 管理地图生成和交互 |
| BattleManager | res://scripts/autoload/BattleManager.gd | 管理战斗系统 |
| SaveManager | res://scripts/autoload/SaveManager.gd | 管理存档系统 |
| AudioManager | res://scripts/autoload/AudioManager.gd | 管理音频播放 |

## 资源预加载

为了提高性能，建议预加载以下资源：

- 常用UI元素
- 玩家精灵
- 常见敌人精灵
- 常用音效

## 导出设置

### Windows

- **导出格式**: 可执行文件 (.exe)
- **架构**: 64位
- **公司名称**: [你的公司名称]
- **产品名称**: 魔塔
- **应用程序图标**: res://assets/icons/app_icon.ico

### 其他平台

根据需要配置其他平台的导出设置，如macOS、Linux、Android或iOS。

## 性能优化建议

- 使用对象池管理频繁创建和销毁的对象（如敌人、特效）
- 对于大型地图，实现视野范围内的动态加载
- 使用精灵表（Sprite Sheets）减少纹理切换
- 优化光照和阴影效果
- 使用资源缓存减少加载时间

## 版本控制建议

- 使用.gitignore忽略Godot生成的临时文件和构建文件
- 考虑使用Git LFS管理大型二进制文件（如音频和图像）
- 遵循一致的提交消息格式