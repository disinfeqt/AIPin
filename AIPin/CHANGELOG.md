# CHANGELOG / 更新日志

## 1.1.4 - 2026-11-05

- 移除了 AIPin 自己画的黄色地图标记，它的位置是错的；现在只保留暴雪导航点和 TomTom 标记。
- Removed AIPin's own yellow map overlay icons, which were drawn at the wrong coordinates; only the Blizzard waypoint and TomTom pins remain.

## 1.1.3 - 2026-11-05

- 修正小地图按钮图标偏移，现在居中在圆框里。
- Fixed the minimap button icon being off-center in its ring.

## 1.1.2 - 2026-11-05

- 小地图按钮：左键打开标记列表，右键同步（避免误触重载界面）。
- 标记列表改为两行显示（名字 / 地区和坐标），长名字不再重叠。
- 同一地点的重复标记会合并，不再出现两条。
- Minimap button: left-click opens the pin list, right-click syncs.
- Pin list rows are two lines (title / zone + coords); long titles no longer overlap.
- Duplicate pins at the same spot are merged.

## 1.1.1 - 2026-11-05

- 暴雪自带的导航点不再只显示「地图标记分享」：鼠标悬停和屏幕上的导航图标会显示 AIPin 标记的名字。
- Blizzard's map pin tooltip and on-screen navigation marker now show the AIPin pin title instead of the generic "Map Pin".

## 1.1.0
- 插件改名为 AIPin（命令 `/aipin`、`/ap`；存档变量 AIPinDB、AIPinChars、AIPinInbox；存档文件 SavedVariables/AIPin.lua）。
- 新增角色信息记录（AIPinChars）：等级、经验、金币、位置、天赋、专业、任务进度、装备、背包、炉石。新增 `/aipin me`。
- Renamed to AIPin (commands `/aipin`, `/ap`; SavedVariables AIPinDB, AIPinChars, AIPinInbox; file SavedVariables/AIPin.lua).
- Added character snapshot (AIPinChars): level, XP, money, location, talents, professions, quest progress, gear, bags, hearthstone. Added `/aipin me`.

- 新增小地图按钮：左键同步（保存角色信息并导入助手标记），右键打开标记列表（逐个删除、全部清除、上次同步时间、收件箱版本）；新增 `/aipin sync`、`/aipin minimap`。
- Added minimap button: left-click sync (save snapshot + import inbox via reload), right-click pin list panel (remove, clear all, last sync, inbox version); added `/aipin sync`, `/aipin minimap`.

## 1.0.0
- 地图标记、助手推送收件箱（Inbox.lua）、TomTom 支持。
- Map pins, assistant inbox (Inbox.lua), and TomTom support.
