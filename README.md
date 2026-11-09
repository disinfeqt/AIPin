<img src="AIPin/media/icon-512.png" alt="" width="96" height="96">

# AIPin

《魔兽世界：Forever》插件：让 AI 助手把 NPC 和地点标在你的地图上，并读取你的角色信息。

[English](#english)

## 功能

- **地图标记**：金色图钉标在世界地图上，悬停显示名字和坐标；点图钉或面板里的一行，导航点就设到那里。
- **待办与地理提醒**：给待办加上区域，比如 `@ 暴风城`，到了就提醒。
- **助手推送**：能改文件的 AI 助手把标记和待办写进 `Inbox.lua`，同步后导入。
- **角色信息**：等级、金币、位置、天赋、专业、任务、装备和已学图样，供助手读取。
- **小地图按钮**：左键打开待办和标记面板，右键同步。

## 下载

[AIPin.zip（最新版）](https://github.com/disinfeqt/AIPin/releases/latest/download/AIPin.zip)

## 安装

1. 完全退出游戏。
2. 解压，把 `AIPin` 文件夹放进插件目录，装好后应是 `AddOns/AIPin/AIPin.toc`：
   - Windows：`C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\`
   - macOS：`/Applications/World of Warcraft/_forever_/Interface/AddOns/`
3. 启动游戏，在角色选择界面点「插件」，勾选 AIPin。

**更新**：退出游戏，用新的 `AIPin` 文件夹替换旧的。数据存在 `WTF` 文件夹里，不会丢失。

## 用法

把助手给的指令粘贴到聊天框：

```
/aipin 丹莫罗 44.1 57.1 巡山人格雷琴
/aipin todo 学法杖 @ 暴风城
```

坐标和 Wowhead 一样；省略区域则用当前地图。

| 命令 | 作用 |
|------|------|
| `/aipin <区域> <x> <y> <名称>` | 添加标记 |
| `/aipin list` / `clear` | 列出 / 清除标记 |
| `/aipin todo <内容> [@ <区域> [x y]]` | 添加待办，带区域则到了提醒 |
| `/aipin todos` | 列出待办 |
| `/aipin done N` / `undone N` / `deltodo N` | 完成 / 取消完成 / 删除第 N 条 |
| `/aipin cleartodos` | 清除已完成的待办 |
| `/aipin me` | 显示角色信息 |
| `/aipin sync` | 保存角色信息，导入助手推送（重载界面） |
| `/aipin minimap` | 显示 / 隐藏小地图按钮 |
| `/aipin help` | 全部命令 |

`/ap` 是 `/aipin` 的简写。

## 给 AI 助手

在[网站](https://wow.duxi.ao/)上点「复制 AI 安装指令」发给 AI 助手。它会按 [INSTALL.md](AIPin/INSTALL.md) 安装，按 [AGENTS.md](AIPin/AGENTS.md) 使用。

## 更新日志

[AIPin/CHANGELOG.md](AIPin/CHANGELOG.md)

## 许可

[MIT](LICENSE) © disinfeqt。AIPin 是玩家自制插件，与暴雪娱乐无关。

---

<a id="english"></a>

## English

A World of Warcraft: Forever addon that lets your AI assistant pin NPCs and places on your map and read your character info.

### Features

- **Map pins**: gold pins on the world map; hover for name and coordinates, and click a pin or its row in the panel to make it the waypoint.
- **Todos and geo-reminders**: give a todo a zone, such as `@ Stormwind`, and get reminded when you arrive.
- **Assistant push**: agents that can edit files write pins and todos into `Inbox.lua`; they're imported on sync.
- **Character info**: level, money, location, talents, professions, quests, gear and learned recipes, for your assistant to read.
- **Minimap button**: left-click for todos and pins, right-click to sync.

In-game text is in Chinese. Zone names work in English or Chinese.

### Download

[AIPin.zip (latest)](https://github.com/disinfeqt/AIPin/releases/latest/download/AIPin.zip)

### Install

1. Quit the game completely.
2. Unzip and put the `AIPin` folder in the addons folder, so you get `AddOns/AIPin/AIPin.toc`:
   - Windows: `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\`
   - macOS: `/Applications/World of Warcraft/_forever_/Interface/AddOns/`
3. Start the game, click AddOns on the character select screen and enable AIPin.

**Updating**: quit the game and replace the old `AIPin` folder with the new one. Your data lives in `WTF` and is kept.

### Usage

Paste your assistant's command into chat:

```
/aipin Dun Morogh 44.1 57.1 Mountaineer Gretchen
/aipin todo Learn staves @ Stormwind
```

Coordinates are the same as Wowhead; leave out the zone to use your current map.

| Command | What it does |
|---------|--------------|
| `/aipin <zone> <x> <y> <title>` | Add a pin |
| `/aipin list` / `clear` | List / remove pins |
| `/aipin todo <text> [@ <zone> [x y]]` | Add a todo; with a zone, remind on arrival |
| `/aipin todos` | List todos |
| `/aipin done N` / `undone N` / `deltodo N` | Mark done / not done / delete todo N |
| `/aipin cleartodos` | Remove finished todos |
| `/aipin me` | Show character info |
| `/aipin sync` | Save character info and import pushes (reloads the UI) |
| `/aipin minimap` | Toggle the minimap button |
| `/aipin help` | All commands |

`/ap` is short for `/aipin`.

### For AI assistants

On the [website](https://wow.duxi.ao/), click "Copy AI setup prompt" and send it to your assistant. It installs with [INSTALL.md](AIPin/INSTALL.md) and learns the rest from [AGENTS.md](AIPin/AGENTS.md).

### Changelog

[AIPin/CHANGELOG.md](AIPin/CHANGELOG.md)

### License

[MIT](LICENSE) © disinfeqt. AIPin is a fan-made addon and is not affiliated with Blizzard Entertainment.
