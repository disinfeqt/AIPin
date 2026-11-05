# CHANGELOG / 更新日志

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
