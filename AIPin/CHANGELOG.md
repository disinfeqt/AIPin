# CHANGELOG / 更新日志

## 1.4.7 - 2026-11-06

- 面板里的待办和标记都能拖动排序。
- 双击待办可以直接修改，写法和添加时一样，也能改 @ 区域和坐标。
- 标记超过 20 个时，删掉最早添加的那个，而不是列表最上面的。
- Drag to reorder todos and pins in the panel.
- Double-click a todo to edit it, using the same syntax as adding, including its @ zone and coordinates.
- Over 20 pins, the oldest one added is dropped, not the one at the top of the list.

## 1.4.6 - 2026-11-06

- 点面板「标记」里的一行，红旗导航点和屏幕上的导航标记就换到那个标记，选中的一行会高亮。世界地图开着时会跳到那个标记所在的地图。
- Click a row in the panel's Pins tab to move the red-flag waypoint and the on-screen marker there; the selected row is highlighted. If the world map is open, it jumps to that pin's map.

## 1.4.5 - 2026-11-06

- 修复：同步或 /reload 后世界地图上看不到标记。现在打开地图或切换地图时，当前地图的所有标记都会显示，铁炉堡这类城市地图也一样。
- 导航点优先指向你所在地图上的标记。点面板「标记」里的一行，或者点地图上的标记，就能把导航点换过去。
- Fix: pins didn't show on the world map after a sync or /reload. Opening or switching maps now shows every pin for that map, city maps like Ironforge included.
- The waypoint now goes to a pin on the map you're on. Click a pin in the panel's Pins tab, or on the map, to move the waypoint there.

## 1.4.4 - 2026-11-06

- 修复：刚登录就同步会清空金钱、经验、装备、专业和任务目标。现在会等数据加载完再保存，读不到的保留上次的值。
- Fix: syncing right after login could wipe money, XP, gear, professions and quest objectives. Sync now waits for the data to load, and anything still empty keeps its last saved value.

## 1.4.3 - 2026-11-05

- 插件列表显示 AIPin 图标和版本号。
- The AddOns list shows the AIPin icon and version.

## 1.4.2 - 2026-11-05

- 给 AI 助手的说明和角色数据更精简：图样单独存放，只在问做什么装备时才读取。
- Leaner docs and character data for AI assistants: recipes are stored separately and only read when you ask what to craft.

## 1.4.1 - 2026-11-05

- 所有制造专业都能读取已学图样；采集专业记录技能等级。
- Learned recipes for every crafting profession; gathering professions record their skill level.

## 1.4.0 - 2026-11-05

- 角色信息新增已学的专业图样，AI 助手可以据此推荐做什么装备。
- Character snapshot now includes learned profession recipes, so your AI assistant can suggest what to craft.

## 1.3.2 - 2026-11-05

- 新面板样式：半透明圆角窗口，底部加「同步」按钮。
- AI 助手可以按 AGENTS.md 直接帮你安装插件。
- New panel look: translucent rounded window with a Sync button.
- AI assistants can install AIPin for you by following AGENTS.md.

## 1.3.1 - 2026-11-05

- 面板分「待办 / 标记」两个标签页。
- 待办可以只写区域名：`/aipin todo 学法杖 @ 暴风城`。
- Panel tabs for Todos and Pins.
- Zone-only reminders: `/aipin todo Learn staves @ Stormwind`.

## 1.3.0 - 2026-11-05

- 待办清单，可以设地理提醒，走到附近就提醒。
- 小地图按钮显示未完成的待办数量。
- 助手可以通过 Inbox.lua 推送待办。
- Todo list with geo-reminders.
- Minimap badge with the open todo count.
- Assistants can push todos through Inbox.lua.

## 1.2.0 - 2026-11-05

- 世界地图上同时显示多个标记，悬停显示名字和坐标。
- Multiple pins on the world map; hover for name and coordinates.

## 1.1.4 - 2026-11-05

- 问题修复。
- Bug fixes.

## 1.1.3 - 2026-11-05

- 问题修复。
- Bug fixes.

## 1.1.2 - 2026-11-05

- 小地图按钮：左键打开标记列表，右键同步。
- Minimap button: left-click opens the pin list, right-click syncs.

## 1.1.1 - 2026-11-05

- 导航点显示 AIPin 标记的名字。
- The waypoint shows the AIPin pin's name.

## 1.1.0

- 改名为 AIPin，命令 `/aipin`、`/ap`。
- 角色信息：等级、经验、金币、位置、天赋、专业、任务等，助手可以读取；新增 `/aipin me`。
- 小地图按钮和 `/aipin sync` 同步。
- Renamed to AIPin, with `/aipin` and `/ap`.
- Character snapshot (level, XP, money, location, talents, professions, quests…) for your assistant to read; added `/aipin me`.
- Minimap button and `/aipin sync`.

## 1.0.0

- 地图标记；助手可以通过 Inbox.lua 推送标记。
- Map pins; assistants can push pins through Inbox.lua.
