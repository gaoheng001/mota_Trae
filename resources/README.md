# 资源目录

这个目录用于存放游戏中使用的Godot资源文件，包括场景、预制体、主题、材质等。

## 推荐目录结构

- `themes/`: UI主题资源
- `materials/`: 材质资源
- `shaders/`: 着色器资源
- `data/`: 游戏数据文件
  - `enemies/`: 敌人数据
  - `items/`: 物品数据
  - `maps/`: 地图数据
  - `npcs/`: NPC数据
- `prefabs/`: 预制场景
- `animations/`: 动画资源

## 资源命名规范

- 主题：`theme_[用途].tres`，例如：`theme_main_menu.tres`、`theme_dialog.tres`
- 材质：`mat_[名称].tres`，例如：`mat_water.tres`、`mat_glow.tres`
- 着色器：`shader_[效果].gdshader`，例如：`shader_pixelate.gdshader`、`shader_outline.gdshader`
- 数据文件：`[类型]_[ID].json`，例如：`enemy_slime.json`、`item_key_yellow.json`
- 预制场景：`prefab_[名称].tscn`，例如：`prefab_door.tscn`、`prefab_chest.tscn`

## 数据文件格式

推荐使用JSON格式存储游戏数据，便于编辑和读取。例如：

```json
// enemy_slime.json
{
  "id": "slime",
  "name": "史莱姆",
  "health": 50,
  "attack": 15,
  "defense": 2,
  "gold": 5,
  "exp": 5,
  "sprite": "res://assets/images/enemies/slime.png",
  "special_abilities": []
}
```

## 资源导入设置

在Godot中，可以为不同类型的资源设置导入预设，确保一致的导入设置：

1. 选择一个资源文件
2. 在导入选项卡中调整设置
3. 点击「预设」下拉菜单，选择「创建新预设」
4. 为预设命名，例如「PixelArt」或「UI」
5. 将预设应用到同类型的其他资源

## 资源优化建议

- 使用资源唯一实例（Resource Unique Instances）避免重复加载
- 对于频繁使用的资源，考虑预加载（preload）
- 使用资源组（Resource Groups）管理相关资源的加载和卸载
- 对于大型资源，考虑使用资源服务器（ResourceLoader）异步加载

## 注意事项

- 保持资源文件的组织和命名一致性，便于团队协作和维护
- 定期清理未使用的资源，减少项目体积
- 使用版本控制系统（如Git）管理资源文件的变更
- 对于二进制资源文件，考虑使用Git LFS（Large File Storage）