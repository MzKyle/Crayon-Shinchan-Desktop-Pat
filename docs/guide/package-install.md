# 安装与打包

## portable bundle

默认打包方式不依赖 Godot export templates。它会把 Godot runtime、Godot 项目、资源目录、素材目录和 X11 快捷键辅助脚本复制到 `dist/GodotShinchanPet/`。

```bash
scripts/build_godot_linux.sh
```

产物入口：

```text
dist/GodotShinchanPet/CrayonShinchanGodotPet
```

运行：

```bash
dist/GodotShinchanPet/CrayonShinchanGodotPet
```

portable bundle 的优点是稳定、简单、无需额外安装 export templates；缺点是产物体积会更大。

## Godot export

安装 export templates：

```bash
scripts/setup_godot_export_templates.sh
```

执行正式导出：

```bash
scripts/build_godot_linux.sh --export
```

或：

```bash
GODOT_EXPORT=1 scripts/build_godot_linux.sh
```

导出配置来自：

```text
godot_pet/export_presets.cfg
```

## 桌面入口

打包完成后安装用户级 desktop entry：

```bash
scripts/install_desktop_entry.sh
```

安装位置：

```text
~/.local/share/applications/crayon-shinchan-desktop-pet.desktop
~/.local/share/icons/hicolor/256x256/apps/crayon-shinchan-desktop-pet.png
```

图标会优先从 `resource_hd/xianzhi/` 或 `resource/xianzhi/` 里取第一张 PNG。

## 打包内容

portable bundle 主要包含：

| 路径 | 说明 |
| --- | --- |
| `GodotPetRuntime` | Godot runtime 可执行文件 |
| `CrayonShinchanGodotPet` | 启动脚本，设置环境变量并启动项目 |
| `godot_pet/` | Godot 项目 |
| `resource/` | 原始动作帧 |
| `resource_hd/` | 高清动作帧 |
| `assets/` | 特效、小游戏和偷看素材 |
| `scripts/pet_hotkeys_x11.py` | X11 全局快捷键辅助脚本 |

## 发布前检查

发布前建议执行：

```bash
python3 scripts/generate_godot_manifest.py
scripts/build_godot_linux.sh
```

如果改过截图贴图功能，还建议在 X11 会话下确认：

```bash
dist/GodotShinchanPet/CrayonShinchanGodotPet
```

然后验证 `F1`、`F3`、`F4` 和右键菜单中的“截图贴图设置”。
