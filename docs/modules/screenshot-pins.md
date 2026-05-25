# 截图贴图

截图贴图模块提供类似 PixPin 的轻量工作流：区域截图、保存最近历史、轮换贴图、关闭当前贴图。

## 默认快捷键

| 快捷键 | 命令 | 说明 |
| --- | --- | --- |
| `F1` | screenshot | 区域截图，保存到历史，并尽量复制到剪贴板 |
| `F3` | paste_pin | 按最新、上一次、上上次顺序贴出截图 |
| `F4` | close_pin | 关闭当前贴图 |

右键菜单中的“截图贴图设置”可以修改快捷键、截图后端和最大贴图数。

## 配置文件

配置保存在：

```text
~/.config/crayon-shinchan-desktop-pet/config.json
```

默认结构：

```json
{
  "shortcuts": {
    "screenshot": "F1",
    "paste_pin": "F3",
    "close_pin": "F4"
  },
  "screenshot": {
    "backend": "auto"
  },
  "pins": {
    "max_count": 3
  }
}
```

`max_count` 会被限制在 1-3 之间。

## 截图后端

| 后端 | 命令 | 能力 |
| --- | --- | --- |
| `auto` | 自动选择 | 优先 Spectacle，失败后尝试 ImageMagick |
| `spectacle` | `spectacle --region --background --nonotify --copy-image --output` | 区域截图、输出文件、复制到剪贴板 |
| `import` | `import <output.png>` | 区域截图并保存文件，通常不复制到剪贴板 |

截图前，主窗口和已有贴图窗口会短暂隐藏，避免截到桌宠本身。

## 全局快捷键桥接

Godot 本身只能稳定处理应用聚焦时的输入。Linux/X11 全局快捷键由 `scripts/pet_hotkeys_x11.py` 完成：

1. `ScreenshotPins.gd` 启动 Python 辅助进程
2. 辅助进程用 `XGrabKey` 注册快捷键
3. 用户按快捷键时，辅助进程向 `127.0.0.1:38291` 发送 UDP 命令
4. `ScreenshotPins.gd` 轮询 UDP 并执行截图、贴图或关闭

如果端口不可用、Python 不存在、不是 X11 会话，模块会保留应用内快捷键作为兜底。

## 贴图窗口

每张贴图是一个独立的 Godot `Window`：

- 无边框
- 置顶
- 透明
- 不可缩放
- 只显示图片内容
- 左键拖动
- 拖动时自动限制在屏幕范围内

点击或拖动过的贴图会成为 `active_pin`。`F4` 优先关闭当前贴图，如果没有当前贴图则关闭最后创建的贴图。

## Wayland 限制

Wayland 合成器通常不允许普通应用随意注册全局快捷键或操控其他窗口层级。因此：

- Wayland 下默认不启用全局快捷键辅助脚本
- 应用窗口聚焦时仍可使用快捷键
- 截图后端是否可用取决于桌面环境和权限策略
