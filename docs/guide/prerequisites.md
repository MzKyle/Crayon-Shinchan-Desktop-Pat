# 环境依赖

## 基础环境

推荐环境：

| 依赖 | 推荐版本 | 说明 |
| --- | --- | --- |
| Linux | Ubuntu / Debian / Arch / Fedora 均可 | 项目主要面向 Linux 桌面环境 |
| Godot | 4.6.x | `scripts/setup_godot.sh` 可自动寻找或下载 portable 版本 |
| Python | 3.10+ | 资源处理脚本和 X11 全局快捷键桥接 |
| Bash | 系统自带 | 运行、打包、安装 desktop entry |
| pip | 最新稳定版 | 安装图片处理依赖 |

安装 Python 依赖：

```bash
python3 -m pip install -r requirements.txt
```

`requirements.txt` 目前主要用于资源生成和图片处理。运行 Godot 桌宠本体不依赖 Python GUI 框架。

## Godot 准备

项目会按下面顺序寻找 Godot：

1. `GODOT_BIN` 环境变量指定的可执行文件
2. 系统 PATH 中的 `godot4` 或 `godot`
3. `tools/godot/` 下已经下载的 Godot portable 二进制
4. 从 Godot GitHub Release 下载 `GODOT_VERSION` 指定版本

手动准备：

```bash
scripts/setup_godot.sh
```

默认版本由脚本中的 `GODOT_VERSION` 决定，目前是 `4.6.3-stable`。如需指定版本：

```bash
GODOT_VERSION=4.6.3-stable scripts/setup_godot.sh
```

## Linux 桌面依赖

透明窗口、置顶窗口和鼠标穿透由 Godot / 桌面环境共同支持。X11 通常兼容性更好；Wayland 会因合成器策略不同而出现差异。

截图贴图需要至少一个截图后端：

```bash
sudo apt-get update
sudo apt-get install -y python3 python3-pip imagemagick
```

KDE 环境推荐安装 Spectacle：

```bash
sudo apt-get install -y kde-spectacle
```

全局快捷键在 Linux/X11 下由 `scripts/pet_hotkeys_x11.py` 通过 `libX11` 注册。Wayland 下默认不启用全局快捷键，但应用窗口聚焦时仍保留应用内快捷键。

## 可选打包依赖

portable bundle 不需要 Godot export templates，会直接复制 Godot runtime 和项目资源。

如果要使用 Godot 正式 export：

```bash
scripts/setup_godot_export_templates.sh
```

脚本会下载并安装 Linux export templates 到：

```text
~/.local/share/godot/export_templates/<version>
```
