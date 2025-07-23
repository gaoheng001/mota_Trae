# 音频资源目录

这个目录用于存放游戏中使用的音频资源，包括背景音乐和音效。

## 目录结构

- `music/`: 存放背景音乐文件
- `sfx/`: 存放音效文件

## 音频格式

推荐使用以下格式：

- 背景音乐：OGG格式（.ogg），提供良好的压缩率和音质平衡
- 音效：WAV格式（.wav）用于短音效，OGG格式用于较长音效

## 音频资源命名规范

- 背景音乐：`bgm_[场景名].ogg`，例如：`bgm_main_menu.ogg`、`bgm_battle.ogg`
- 音效：`sfx_[类别]_[动作].wav`，例如：`sfx_door_open.wav`、`sfx_item_pickup.wav`

## 推荐音频资源

### 背景音乐

1. 主菜单音乐
2. 游戏场景音乐（按楼层或区域变化）
3. 战斗音乐
4. 胜利/失败音乐
5. 剧情/对话音乐

### 音效

1. 玩家移动音效
2. 门开启音效（黄、蓝、红门）
3. 物品拾取音效
4. 战斗音效（攻击、受伤、胜利、失败）
5. 升级音效
6. 按钮点击音效
7. 楼层切换音效

## 音频资源来源

可以使用以下免费音频资源：

- Freesound: https://freesound.org/
- OpenGameArt: https://opengameart.org/
- Free Music Archive: https://freemusicarchive.org/

## 注意事项

- 确保使用的音频资源具有适当的许可证，允许在游戏中使用
- 控制音频文件大小，避免过大的文件增加游戏包体积
- 在Godot中使用AudioStreamPlayer节点播放背景音乐，使用AudioStreamPlayer2D节点播放位置相关的音效