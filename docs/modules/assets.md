# 素材与动作

## 资源目录

| 路径 | 说明 |
| --- | --- |
| `resource/` | 原始动作帧 |
| `resource_hd/` | 高清动作帧，运行时优先加载 |
| `assets/effects/` | 爱心、闪光、波纹等互动特效 |
| `assets/games/` | 饭团、球、靶心、奖杯等小游戏素材 |
| `assets/character/` | 贴边偷看图和来源说明 |
| `assets/character/mischief/` | 捣乱动作候选素材和来源说明 |

第三方素材来源见对应目录下的 `NOTICE.md`。

## 动作清单

动作清单位于：

```text
godot_pet/assets/actions.json
```

它由 `scripts/generate_godot_manifest.py` 生成。每个动作包含：

| 字段 | 说明 |
| --- | --- |
| `name` | 中文动作名 |
| `resource` | 对应资源目录 |
| `size` | Godot 中的显示尺寸 |
| `fps` | 播放帧率 |
| `loop` | 是否循环 |
| `loop_start` | 循环起始帧 |
| `next_action` | 非循环动作结束后的下一个动作 |
| `frames` | PNG 帧相对路径列表 |

## 当前动作

| 动作 ID | 动作名 | 资源目录 |
| --- | --- | --- |
| `idle` | 闲置 | `xianzhi` |
| `walk_left` | 向左散步 | `sanbu/zuo` |
| `walk_right` | 向右散步 | `sanbu/you` |
| `mischief_grab` | 费力抢鼠标 | `mischief_grab` |
| `fall` | 下落 | `xialuo` |
| `exercise` | 运动 | `yundong` |
| `eat` | 吃饭 | `eat` |
| `sleep` | 睡觉 | `sleep` |
| `wake` | 唤醒 | `waken` |
| `pipi` | 屁屁舞 | `pipi` |
| `transform` | 动感光波 | `xiandanchaoren` |
| `snack` | 偷吃宵夜 | `snack` |
| `meet` | 见到小白 | `meet` |
| `xiaobai` | 小白 | `xiaobai` |

## 高清资源生成

生成高清副本：

```bash
python3 scripts/generate_hd_assets.py --source resource --output resource_hd --scale 3 --force
```

运行时加载顺序：

```text
resource_hd/<action_frame>
resource/<action_frame>
```

因此可以逐步补高清资源，不需要一次性覆盖全部原始资源。

## 贴边与捣乱素材

重新生成贴边偷看图：

```bash
python3 scripts/generate_peek_assets.py --source /path/to/source.png
```

重新生成捣乱动作帧：

```bash
python3 scripts/generate_mischief_grab_assets.py --source /path/to/source.png
python3 scripts/generate_godot_manifest.py
```

修改动作资源后一定要重新生成 `actions.json`，否则 Godot 仍会按旧清单加载。
