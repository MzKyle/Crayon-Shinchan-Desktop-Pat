# 打包模块

## 打包入口

主入口是：

```text
scripts/build_godot_linux.sh
```

它会先执行：

```bash
python3 scripts/generate_godot_manifest.py
```

确保 `actions.json` 和当前资源目录一致。

## portable bundle 流程

默认流程：

1. 准备 Godot runtime
2. 清理并创建 `dist/GodotShinchanPet/`
3. 复制 Godot runtime 为 `GodotPetRuntime`
4. 复制 `godot_pet/`
5. 复制 `resource/`、`resource_hd/`、`assets/`
6. 复制 `scripts/pet_hotkeys_x11.py`
7. 写入启动脚本 `CrayonShinchanGodotPet`

启动脚本会设置：

```bash
CRAYON_PET_ROOT="$APP_DIR"
CRAYON_PET_TRANSPARENT=1
CRAYON_PET_ALWAYS_ON_TOP=1
CRAYON_PET_BORDERLESS=1
CRAYON_PET_MOUSE_PASSTHROUGH=1
```

然后执行：

```bash
GodotPetRuntime --path godot_pet
```

## Godot export 流程

当传入 `--export` 或 `GODOT_EXPORT=1` 时，脚本会检查 export templates：

```text
~/.local/share/godot/export_templates/<version>/linux_debug.x86_64
~/.local/share/godot/export_templates/<version>/linux_release.x86_64
```

缺失时会提示运行：

```bash
scripts/setup_godot_export_templates.sh
```

导出成功后仍会复制外部资源目录，因为当前项目运行时需要从仓库根或打包根加载资源。

## desktop entry

`scripts/install_desktop_entry.sh` 会把模板：

```text
packaging/crayon-shinchan-desktop-pet.desktop.in
```

渲染为用户级 desktop entry。它不会写系统目录，不需要 root 权限。

## 常见打包问题

| 问题 | 处理 |
| --- | --- |
| 找不到 Godot | 运行 `scripts/setup_godot.sh` 或设置 `GODOT_BIN` |
| export templates 缺失 | 运行 `scripts/setup_godot_export_templates.sh` |
| 打包后没有全局快捷键 | 确认 `scripts/pet_hotkeys_x11.py` 已被复制并有可执行权限 |
| 透明窗口异常 | 运行时设置 `CRAYON_PET_SAFE_WINDOW=1` 排查 |
