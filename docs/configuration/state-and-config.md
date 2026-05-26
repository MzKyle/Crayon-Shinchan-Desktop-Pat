# 状态与配置文件

运行时数据写入用户配置目录：

```text
~/.config/crayon-shinchan-desktop-pet/
```

## 状态文件

```text
~/.config/crayon-shinchan-desktop-pet/state.json
```

示例：

```json
{
  "mood": 70,
  "hunger": 60,
  "energy": 80,
  "affection": 30
}
```

字段范围固定为 0-100。`StateStore.gd` 会在读取和写入时做边界保护。

行为模式不保存。每次启动都会回到安静模式。

## 截图贴图配置

```text
~/.config/crayon-shinchan-desktop-pet/config.json
```

保存内容：

| 字段 | 说明 |
| --- | --- |
| `shortcuts.screenshot` | 截图快捷键 |
| `shortcuts.paste_pin` | 贴图快捷键 |
| `shortcuts.close_pin` | 关闭贴图快捷键 |
| `screenshot.backend` | 内部保留字段，启动时重置为 `auto` |
| `pins.max_count` | 最大贴图数量，范围 1-3 |

右键菜单中的“截图贴图设置”会写入这个文件。

截图现在默认使用 Godot 内置截图，Linux 上仅在 Godot 截图不可用时自动兜底到 Spectacle 或 ImageMagick。旧配置里的 `spectacle` / `import` 偏好不会保留。

## 截图历史

```text
~/.config/crayon-shinchan-desktop-pet/screenshots/
```

截图文件命名格式：

```text
screenshot_<timestamp>_<ticks>.png
clipboard_<timestamp>_<ticks>.png
```

历史最多保留 3 张。超过上限时，旧截图文件会被删除。

## 清理配置

重置桌宠状态：

```bash
rm -f ~/.config/crayon-shinchan-desktop-pet/state.json
```

重置截图贴图设置：

```bash
rm -f ~/.config/crayon-shinchan-desktop-pet/config.json
```

清理截图历史：

```bash
rm -rf ~/.config/crayon-shinchan-desktop-pet/screenshots
```
