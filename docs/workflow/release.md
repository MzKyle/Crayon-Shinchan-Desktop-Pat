# 发布流程

## 版本发布前

建议确认工作区：

```bash
git status --short
```

确认动作清单：

```bash
python3 scripts/generate_godot_manifest.py
```

检查 README 和文档站：

```bash
cd docs
python3 -m http.server 4173 --bind 127.0.0.1
```

## 打包

默认 portable bundle：

```bash
scripts/build_godot_linux.sh
```

正式 Godot export：

```bash
scripts/setup_godot_export_templates.sh
scripts/build_godot_linux.sh --export
```

## 安装并验证

安装桌面入口：

```bash
scripts/install_desktop_entry.sh
```

运行验证：

```bash
dist/GodotShinchanPet/CrayonShinchanGodotPet
```

验收清单：

- 透明窗口正常
- 右键菜单可打开
- 显示大小可切换
- 重力开关生效
- 抱起、甩飞、落地正常
- 拖到屏幕边缘可进入偷看
- 活泼模式会自动散步或贴边
- 捣乱模式可开始和停止
- `F1`、`F3`、`F4` 在 X11 下可用

## 开源发布前检查

- 不提交 `dist/`、`tools/`、`godot_pet/.godot/` 等本地产物
- 不提交个人配置目录中的 `state.json`、`config.json` 或截图历史
- 确认 `LICENSE` 为 MIT
- 确认第三方素材 `NOTICE.md` 仍在对应目录
- 确认 README 中的仓库链接、文档链接和命令可用
