<img src="AIPin/media/icon-512.png" alt="" width="96" height="96">

# AIPin

《魔兽世界：Forever》插件（Interface 16001）：让 AI 助手把 NPC 和地点标在你的地图上，并读取你的角色信息。

[English](#english)

## 功能

- **地图标记**：NPC 和地点会标在世界地图上，同时设置游戏自带的导航箭头；装了 [TomTom](https://www.curseforge.com/wow/addons/tomtom) 也会加一个 TomTom 路点。
- **两种标记方式**：把助手给的 `/aipin <区域> <x> <y> <名称>` 粘贴到聊天框；或者让能改你电脑文件的助手编辑 `Inbox.lua`，你点小地图按钮同步（会重载界面）。
- **角色信息**：等级、经验、金币、位置、天赋、专业、任务进度、装备、背包和炉石保存在 SavedVariables（`AIPinChars`），助手可以读取。
- **小地图按钮**：左键同步，右键打开标记列表。

## 下载

[AIPin.zip（最新版）](https://github.com/disinfeqt/AIPin/releases/latest/download/AIPin.zip)

## 安装

1. 完全退出游戏。
2. 解压 `AIPin.zip`，把 `AIPin` 文件夹放进插件目录：
   - Windows：`C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\`
   - macOS：`/Applications/World of Warcraft/_forever_/Interface/AddOns/`
3. 启动游戏，在角色选择界面点「插件」，勾选 AIPin。

装好后应该是 `AddOns/AIPin/AIPin.toc`，不要多套一层 `AIPin/AIPin/`（Windows 的「全部解压缩」默认会多建一层）。游戏装在别处的话，在战网客户端 Forever 的齿轮菜单里打开游戏文件夹。

### 更新

1. 退出游戏，下载新的 `AIPin.zip`。
2. 删掉旧的 `AIPin` 文件夹，换成新的。

标记和角色信息保存在 `_forever_/WTF/Account/<账号>/SavedVariables/AIPin.lua`，替换插件文件夹不会丢失。

如果助手用 `Inbox.lua` 推送过标记，替换前先备份旧的 `Inbox.lua`，换完再放回去，否则之后的推送可能不会被导入。

## 用法

把助手给的指令粘贴到聊天框：

```
/aipin 丹莫罗 44.1 57.1 巡山人格雷琴
/aipin 44.1 57.1 巡山人格雷琴
```

坐标是地图百分比（0–100），和 Wowhead 一样；省略区域则用当前地图。按 **M** 查看标记。

| 命令 | 作用 |
|------|------|
| `/aipin <区域> <x> <y> <名称>` | 添加标记 |
| `/ap` | `/aipin` 的简写 |
| `/aipin list` | 列出标记 |
| `/aipin clear` | 清除全部标记 |
| `/aipin help` | 显示帮助 |
| `/aipin me` | 显示角色简要信息 |
| `/aipin sync` | 同步：保存角色信息并导入助手推送的标记（会重载界面） |
| `/aipin minimap` | 显示 / 隐藏小地图按钮 |

小地图按钮：左键同步（同 `/aipin sync`），右键打开标记列表。

## 给 AI 助手

把 [AIPin/AGENTS.md](AIPin/AGENTS.md) 交给你的 AI 助手（插件文件夹里也有一份）。里面说明了怎么回复 `/aipin` 指令、怎么编辑 `Inbox.lua` 推送标记，以及怎么读取 `AIPinChars` 角色信息。

## 更新日志

[AIPin/CHANGELOG.md](AIPin/CHANGELOG.md)

## 许可

[MIT](LICENSE) © disinfeqt

AIPin 是玩家自制插件，与暴雪娱乐（Blizzard Entertainment）无关。

---

<a id="english"></a>

## English

AIPin is a World of Warcraft: Forever addon (Interface 16001) that lets your AI assistant pin NPCs and places on your map and read your character info.

### Features

- **Map pins**: NPCs and places are marked on the world map with the game's waypoint arrow, plus a [TomTom](https://www.curseforge.com/wow/addons/tomtom) waypoint if TomTom is installed.
- **Two ways to pin**: paste the assistant's `/aipin <zone> <x> <y> <title>` line into chat, or let an assistant that can edit files on your computer write to `Inbox.lua`, then click the minimap button to sync (this reloads the UI).
- **Character snapshot**: level, XP, money, location, talents, professions, quest progress, gear, bags and hearthstone are saved to SavedVariables (`AIPinChars`) for your assistant to read.
- **Minimap button**: left-click to sync, right-click to open the pin list.

In-game messages are in Simplified Chinese. Zone names work in English or Chinese.

### Download

[AIPin.zip (latest)](https://github.com/disinfeqt/AIPin/releases/latest/download/AIPin.zip)

### Install

1. Quit the game completely.
2. Unzip `AIPin.zip` and put the `AIPin` folder in the addons folder:
   - Windows: `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\`
   - macOS: `/Applications/World of Warcraft/_forever_/Interface/AddOns/`
3. Start the game, click AddOns on the character select screen and enable AIPin.

The result should be `AddOns/AIPin/AIPin.toc`, not `AddOns/AIPin/AIPin/` (Windows' Extract All adds an extra folder by default). If the game is installed elsewhere, open its folder from the gear menu next to Forever in the Battle.net app.

#### Updating

1. Quit the game and download the new `AIPin.zip`.
2. Delete the old `AIPin` folder and put the new one in its place.

Pins and character data are stored in `_forever_/WTF/Account/<account>/SavedVariables/AIPin.lua` and are kept when you replace the addon folder.

If your assistant has pushed pins through `Inbox.lua`, back up the old `Inbox.lua` before replacing the folder and copy it back afterwards; otherwise later pushes may not be imported.

### Usage

Paste the command from your assistant into chat:

```
/aipin Dun Morogh 44.1 57.1 Mountaineer Gretchen
/aipin 44.1 57.1 Mountaineer Gretchen
```

Coordinates are map percentages (0–100), the same as Wowhead; leave out the zone to use your current map. Press **M** to see the pin.

| Command | What it does |
|---------|--------------|
| `/aipin <zone> <x> <y> <title>` | Add a pin |
| `/ap` | Short for `/aipin` |
| `/aipin list` | List pins |
| `/aipin clear` | Remove all pins |
| `/aipin help` | Show help |
| `/aipin me` | Show a short character summary |
| `/aipin sync` | Sync: save the character snapshot and import assistant pins (reloads the UI) |
| `/aipin minimap` | Show / hide the minimap button |

Minimap button: left-click to sync (same as `/aipin sync`), right-click for the pin list.

### For AI assistants

Give [AIPin/AGENTS.md](AIPin/AGENTS.md) to your AI assistant (a copy is also in the addon folder). It explains how to reply with `/aipin` commands, how to push pins by editing `Inbox.lua`, and how to read the `AIPinChars` character data.

### Changelog

[AIPin/CHANGELOG.md](AIPin/CHANGELOG.md)

### License

[MIT](LICENSE) © disinfeqt

AIPin is a fan-made addon and is not affiliated with Blizzard Entertainment.
