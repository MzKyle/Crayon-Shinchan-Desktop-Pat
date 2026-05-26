# 模块全景

## Godot 脚本模块

| 模块 | 职责 | 关键输入 | 关键输出 |
| --- | --- | --- | --- |
| `Main.gd` | 运行时编排、窗口配置、菜单、模式切换 | 输入事件、菜单 ID、环境变量 | 窗口位置、动画、气泡、行为触发 |
| `PetSprite.gd` | 加载动作帧、播放动画、计算可见区域 | `actions.json`、资源目录 | 当前帧、窗口建议尺寸、可见矩形 |
| `PetPhysics.gd` | 物理状态机、速度、重力、碰撞、贴边 | 释放速度、播放区域、接触矩形 | 窗口坐标、物理状态、碰撞信号 |
| `InteractionController.gd` | 点击、双击、滚轮、长按、拖拽和甩飞识别 | Godot 鼠标事件 | 交互信号 |
| `BehaviorBrain.gd` | 安静/活泼/捣乱模式调度 | 当前模式、暂停状态 | 自动行为请求 |
| `MiniGames.gd` | 饭团投喂和接球挑战 | 鼠标拖拽、角色碰撞区域 | 成功信号和游戏结束信号 |
| `StateStore.gd` | 心情、饥饿、体力、亲密度持久化 | 行为增量 | `state.json` |
| `ScreenshotPins.gd` | 截图、贴图、快捷键、配置、历史 | 快捷键、Godot 截图、剪贴板 helper | 贴图窗口、配置文件、截图历史 |
| `PinImageWindow.gd` | 单张贴图窗口 | 图片、起始位置、最大尺寸 | 置顶可拖动贴图 |
| `ScreenshotSettingsWindow.gd` | 截图贴图设置 UI | 当前配置 | 保存后的配置 |

## 脚本工具模块

| 脚本 | 职责 |
| --- | --- |
| `scripts/setup_godot.sh` | 寻找或下载 Godot portable |
| `scripts/run_godot_pet.sh` | 设置运行环境并启动 Godot 项目 |
| `scripts/generate_godot_manifest.py` | 根据资源帧生成动作清单 |
| `scripts/generate_hd_assets.py` | 生成高清资源副本 |
| `scripts/generate_peek_assets.py` | 生成贴边偷看图 |
| `scripts/generate_mischief_grab_assets.py` | 生成捣乱动作帧 |
| `scripts/download_effect_assets.sh` | 下载 Noto Emoji 互动素材 |
| `scripts/build_godot_linux.sh` | 打包 portable bundle 或 Godot export |
| `scripts/install_desktop_entry.sh` | 安装 Linux 桌面启动器 |
| `scripts/pet_helper.py` | 全局快捷键和图片剪贴板桥接 |

## 模块通信方式

Godot 运行层主要通过信号通信：

- `InteractionController.gd` 发出 `single_clicked`、`double_clicked`、`grab_started`、`grab_released`
- `PetPhysics.gd` 发出 `landed`、`bounced`、`attached_to_wall`
- `BehaviorBrain.gd` 发出 `action_requested`、`mischief_requested`
- `MiniGames.gd` 发出 `feed_success`、`catch_success`、`game_finished`
- `ScreenshotPins.gd` 发出 `notify`

`Main.gd` 订阅这些信号，并决定播放哪段动画、是否更新状态、是否改变窗口大小和是否显示气泡。
