# 图像资源目录

这个目录用于存放游戏中使用的图像资源，包括精灵图、瓦片集、UI元素等。

## 推荐目录结构

- `characters/`: 角色精灵图
  - `player/`: 玩家角色精灵图
  - `enemies/`: 敌人精灵图
  - `npcs/`: NPC精灵图
- `tiles/`: 地图瓦片集
  - `floors/`: 地板瓦片
  - `walls/`: 墙壁瓦片
  - `doors/`: 门瓦片
  - `stairs/`: 楼梯瓦片
- `items/`: 物品精灵图
  - `keys/`: 钥匙精灵图
  - `potions/`: 药水精灵图
  - `equipment/`: 装备精灵图
  - `treasures/`: 宝物精灵图
- `ui/`: UI元素
  - `buttons/`: 按钮图像
  - `panels/`: 面板背景
  - `icons/`: 图标集
  - `status/`: 状态栏元素
- `effects/`: 特效图像
  - `battle/`: 战斗特效
  - `magic/`: 魔法特效

## 图像格式

推荐使用以下格式：

- PNG格式（.png）：支持透明度，适合精灵图和UI元素
- 精灵表（Sprite Sheets）：将多个相关图像组合成一个文件，减少加载时间

## 图像尺寸指南

- 瓦片：64x64像素（保持一致的瓦片大小）
- 角色精灵：64x64像素（可根据需要调整）
- UI元素：根据设计需求，但保持一致的比例

## 图像资源命名规范

- 角色：`[类型]_[名称]_[动作].png`，例如：`player_hero_idle.png`、`enemy_slime_attack.png`
- 瓦片：`tile_[类型]_[变种].png`，例如：`tile_floor_stone.png`、`tile_wall_brick.png`
- 物品：`item_[类型]_[名称].png`，例如：`item_key_yellow.png`、`item_potion_health.png`
- UI：`ui_[类型]_[状态].png`，例如：`ui_button_normal.png`、`ui_panel_inventory.png`

## 图像资源来源

可以使用以下免费图像资源：

- OpenGameArt: https://opengameart.org/
- Kenney: https://kenney.nl/assets
- Game-Icons: https://game-icons.net/
- itch.io: https://itch.io/game-assets/free

## 注意事项

- 确保使用的图像资源具有适当的许可证，允许在游戏中使用
- 保持一致的艺术风格，避免不同风格的图像混用
- 考虑使用矢量图形编辑器（如Inkscape）创建可缩放的UI元素
- 对于像素风格的游戏，禁用Godot的图像过滤，保持像素的清晰度