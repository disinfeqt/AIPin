<img src="AIPin/media/icon-512.png" alt="" width="96" height="96">

# AIPin

《魔兽世界：Forever》插件（Interface 16001）：让 AI 助手把 NPC 和地点标在你的地图上，并读取你的角色信息。

[English](#english)

## 功能

- **地图标记**：NPC 和地点标在世界地图上，可以同时显示多个，悬停显示名字和坐标；最新的标记还会设置游戏的导航箭头，箭头上显示标记名字。
- **待办与地理提醒**：添加待办，写上 `@ 区域` 就在进入该区域时提醒，再写坐标则走到附近时提醒。
- **两种方式**：把助手给的 `/aipin` 指令粘贴到聊天框；或者让能改你电脑文件的助手编辑 `Inbox.lua` 推送标记和待办，你右键小地图按钮同步（会重载界面）。
- **角色信息**：等级、经验、金币、位置、天赋、专业、任务进度、装备、背包和炉石保存在 SavedVariables（`AIPinChars`），助手可以读取。打开过的专业窗口还会记下已学图样（`AIPinRecipes`），助手可以据此推荐做什么装备。
- **小地图按钮**：左键打开面板（待办 / 标记），右键同步；角标显示未完成的待办数量。

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

标记、待办和角色信息保存在 `_forever_/WTF/Account/<账号>/SavedVariables/AIPin.lua`，专业图样保存在各角色自己的目录下，替换插件文件夹都不会丢失。

如果助手用 `Inbox.lua` 推送过标记或待办，替换前先备份旧的 `Inbox.lua`，换完再放回去，否则之后的推送可能不会被导入。

## 用法

把助手给的指令粘贴到聊天框：

```
/aipin 丹莫罗 44.1 57.1 巡山人格雷琴
/aipin 44.1 57.1 巡山人格雷琴
/aipin todo 学法杖 @ 暴风城
/aipin todo 买背包
```

坐标是地图百分比（0–100），和 Wowhead 一样；省略区域则用当前地图。按 **M** 查看标记。待办加上 `@ 区域`，进入该区域时提醒；再写上坐标，则走到附近时提醒。

| 命令 | 作用 |
|------|------|
| `/aipin <区域> <x> <y> <名称>` | 添加标记 |
| `/aipin list` | 列出标记 |
| `/aipin clear` | 清除全部标记 |
| `/aipin todo <内容> [@ <区域> [x y]]` | 添加待办；带 `@ 区域` 就是地理提醒 |
| `/aipin todos` | 列出待办（带编号） |
| `/aipin done N` / `/aipin undone N` | 把第 N 条待办标为完成 / 未完成 |
| `/aipin deltodo N` | 删除第 N 条待办 |
| `/aipin cleartodos` | 清除已完成的待办 |
| `/aipin me` | 显示角色简要信息 |
| `/aipin sync` | 同步：保存角色信息并导入助手推送的标记和待办（会重载界面，战斗中不可用） |
| `/aipin minimap` | 显示 / 隐藏小地图按钮 |
| `/aipin help` | 显示帮助 |
| `/ap` | `/aipin` 的简写，所有命令都能用 |

小地图按钮：左键打开面板（待办 / 标记），右键同步（同 `/aipin sync`），拖动可移动位置。面板里也可以直接添加待办，或点「提醒在此处」用当前位置。

## 给 AI 助手

在 [网站](https://wow.duxi.ao/) 上点「复制 AI 安装指令」，发给 Claude Code、Codex 等 AI 助手，它会按 [AIPin/INSTALL.md](AIPin/INSTALL.md) 帮你安装或更新，再读 [AIPin/AGENTS.md](AIPin/AGENTS.md) 学会使用（插件文件夹里也有一份）。AGENTS.md 说明了怎么回复 `/aipin` 指令、怎么编辑 `Inbox.lua` 推送标记和待办，以及怎么用 `AIPinChars` 角色信息和 `AIPinRecipes` 图样按你的实际情况给建议。

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

- **Map pins**: NPCs and places are marked on the world map, several at once; hover for name and coordinates. The newest pin also sets the game's waypoint arrow, labelled with the pin's name.
- **Todos and geo-reminders**: add a todo with `@ zone` to be reminded when you enter that zone, or add coordinates to be reminded near a spot.
- **Two ways in**: paste the assistant's `/aipin` commands into chat, or let an assistant that can edit files on your computer push pins and todos through `Inbox.lua`, then right-click the minimap button to sync (this reloads the UI).
- **Character snapshot**: level, XP, money, location, talents, professions, quest progress, gear, bags and hearthstone are saved to SavedVariables (`AIPinChars`) for your assistant to read. Once you open a profession window, its learned recipes are saved too (`AIPinRecipes`), so your assistant can suggest what to craft.
- **Minimap button**: left-click for the panel (Todos / Pins), right-click to sync; a badge shows how many todos are open.

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

Pins, todos and character data are stored in `_forever_/WTF/Account/<account>/SavedVariables/AIPin.lua`, and recipes in each character's own folder; replacing the addon folder keeps all of them.

If your assistant has pushed pins or todos through `Inbox.lua`, back up the old `Inbox.lua` before replacing the folder and copy it back afterwards; otherwise later pushes may not be imported.

### Usage

Paste the command from your assistant into chat:

```
/aipin Dun Morogh 44.1 57.1 Mountaineer Gretchen
/aipin 44.1 57.1 Mountaineer Gretchen
/aipin todo Learn staves @ Stormwind
/aipin todo Buy bags
```

Coordinates are map percentages (0–100), the same as Wowhead; leave out the zone to use your current map. Press **M** to see the pin. Add `@ zone` to a todo to be reminded when you enter that zone, or add coordinates as well to be reminded near a spot.

| Command | What it does |
|---------|--------------|
| `/aipin <zone> <x> <y> <title>` | Add a pin |
| `/aipin list` | List pins |
| `/aipin clear` | Remove all pins |
| `/aipin todo <text> [@ <zone> [x y]]` | Add a todo; with `@ zone` it becomes a geo-reminder |
| `/aipin todos` | List todos with their numbers |
| `/aipin done N` / `/aipin undone N` | Mark todo N as done / not done |
| `/aipin deltodo N` | Delete todo N |
| `/aipin cleartodos` | Remove finished todos |
| `/aipin me` | Show a short character summary |
| `/aipin sync` | Sync: save the character snapshot and import assistant pins and todos (reloads the UI; not in combat) |
| `/aipin minimap` | Show / hide the minimap button |
| `/aipin help` | Show help |
| `/ap` | Short for `/aipin`; works with every command |

Minimap button: left-click for the panel (Todos / Pins), right-click to sync (same as `/aipin sync`), drag to move it. You can also add todos in the panel, or click 提醒在此处 (Remind here) to use your current spot.

### For AI assistants

On the [website](https://wow.duxi.ao/), click "Copy AI setup prompt" and send it to Claude Code, Codex or a similar assistant. It installs or updates AIPin by following [AIPin/INSTALL.md](AIPin/INSTALL.md), then reads [AIPin/AGENTS.md](AIPin/AGENTS.md) (also in the addon folder) to learn how to use it: replying with `/aipin` commands, pushing pins and todos through `Inbox.lua`, and using the `AIPinChars` snapshot and `AIPinRecipes` to fit its advice to your character.

### Changelog

[AIPin/CHANGELOG.md](AIPin/CHANGELOG.md)

### License

[MIT](LICENSE) © disinfeqt

AIPin is a fan-made addon and is not affiliated with Blizzard Entertainment.
