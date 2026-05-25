## 蜡笔小新桌宠 v2

Godot 4 驱动的本地桌宠，支持透明置顶窗口、长按抱起、甩飞、重力、贴边偷看、主动行为、小游戏和三种行为模式。项目已收敛为 Godot-only；Python 脚本仅用于资源生成和素材处理。

### 启动

首次准备 Godot portable：

```bash
scripts/setup_godot.sh
```

生成动作清单并启动：

```bash
python3 scripts/generate_godot_manifest.py
scripts/run_godot_pet.sh
```

`scripts/setup_godot.sh` 会优先使用 `GODOT_BIN`、系统 `godot4/godot`，找不到时下载官方 Linux x86_64 portable Godot 到 `tools/godot/`。二进制不会提交到仓库。

如果透明窗口在当前桌面环境里显示异常，可临时使用安全窗口模式：

```bash
CRAYON_PET_SAFE_WINDOW=1 scripts/run_godot_pet.sh
```

### 行为模式

启动默认进入“安静模式”，模式不会跨启动保存。

- 安静模式：不自动散步、不贴边走、不触发捣乱；右键菜单里的“散步”等手动操作仍可用。
- 活泼模式：保留随机散步、贴边走、邀请玩和脚印小特效。
- 捣乱模式：每 20-40 秒温和触发一次 4 秒“费力抢鼠标”视觉演出；小新会贴近并跟随光标，但不会移动、锁定或改变系统鼠标位置。

捣乱演出期间，透明窗口只保留右上角“停”按钮区域接收点击，其它区域会穿透到桌面。该行为依赖 Godot `Window.mouse_passthrough_polygon`：多边形内接收鼠标事件，多边形外穿透，空数组恢复默认拦截行为。

### 互动

- 长按 350ms：抱起，小新会用弹簧滞后跟随鼠标。
- 快速释放：按释放速度甩飞，受重力、阻尼、地面/墙面反弹影响。
- 慢速释放：轻放并恢复。
- 碰到屏幕边缘：反弹或贴边，贴边后可沿边走。
- 长按拖到屏幕边缘或角落释放：小新会藏到屏幕外，只露出一条偷看；单击或拖拽可把他叫出来。
- 单击头部：摸摸头。
- 单击身体：戳一戳。
- 双击：进入接球小游戏。
- 滚轮：显示状态气泡。
- 右键：动作、小游戏、显示大小、重力切换、安静/活泼/捣乱模式、清理、退出。

### 互动特效资源

`assets/effects/` 和 `assets/games/` 内的爱心、闪光、饭团、球、靶心、奖杯、计时器等图标来自 Google Noto Emoji，用于摸摸头、投喂、陪玩、睡觉/唤醒和小游戏反馈。

需要重新下载这些开源素材时：

```bash
scripts/download_effect_assets.sh
```

`assets/character/` 里放了本地个人使用的偷看 PNG 源图和由脚本生成的四个方向贴边 PNG。重新生成：

```bash
python3 scripts/generate_peek_assets.py
```

`assets/character/mischief/` 里记录“费力抢鼠标”候选 PNG 的来源；生成动作帧：

```bash
python3 scripts/generate_mischief_grab_assets.py
python3 scripts/generate_godot_manifest.py
```

### 高清资源

原始动画帧保留在 `resource/`，高清副本生成到 `resource_hd/`。应用运行时会优先使用 `resource_hd/`，缺失时回退到 `resource/`。

重新生成高清副本：

```bash
python3 scripts/generate_hd_assets.py --source resource --output resource_hd --scale 3 --force
```

右键菜单中的“显示大小”可以切换 `100% / 125% / 150%`。

### 安装依赖

```bash
python3 -m pip install -r requirements.txt
```

### Linux 打包和桌面入口

```bash
scripts/build_godot_linux.sh
scripts/install_desktop_entry.sh
```

Godot 打包结果位于 `dist/GodotShinchanPet/CrayonShinchanGodotPet`。当前 Godot 构建脚本默认使用官方 runtime + 项目资源的 portable bundle，避免首次构建下载很大的 export templates。安装 Godot export templates 后可运行：

```bash
scripts/setup_godot_export_templates.sh
scripts/build_godot_linux.sh --export
```

这会使用 `godot_pet/export_presets.cfg` 走 Godot Linux export。

状态会保存到：

```text
~/.config/crayon-shinchan-desktop-pet/state.json
```

行为模式不写入状态文件，每次启动都会回到安静模式。

### 参考来源

- VPet: https://github.com/LorisYounger/VPet
- Shimeji-ee: https://github.com/gil/shimeji-ee
- Godot Window: https://docs.godotengine.org/en/4.6/classes/class_window.html
- Godot Linux export: https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_linux.html
