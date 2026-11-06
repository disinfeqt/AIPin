# AIPin — 魔兽世界：Forever 地图标记插件

让 AI 助手把 NPC 和地点标在你的地图上、帮你记待办，并读取你的角色信息。

## 安装

1. 完全退出游戏。
2. 把 `AIPin` 文件夹放进插件目录，装好后应是 `AddOns/AIPin/AIPin.toc`：
   - Windows：`C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\`
   - Mac：`/Applications/World of Warcraft/_forever_/Interface/AddOns/`
3. 启动游戏，在角色选择界面点「插件」，勾选 AIPin（显示过期就勾选「加载过期插件」）。

**更新**：退出游戏，用新的 `AIPin` 文件夹替换旧的。数据存在 `WTF` 文件夹里，不会丢失。

## 地图标记

```
/aipin 丹莫罗 44.1 57.1 巡山人格雷琴
```

坐标和 Wowhead 一样；省略区域则用当前地图。最新的标记会设置导航箭头。`/aipin list` 列出，`/aipin clear` 清除。

## 待办

```
/aipin todo 买背包
/aipin todo 学法杖 @ 暴风城               进入暴风城时提醒
/aipin todo 学法杖 @ 暴风城 63.9 69.1     走到附近时提醒
```

`/aipin todos` 列出，`done N` / `undone N` 完成 / 取消完成，`deltodo N` 删除，`cleartodos` 清除已完成的。

## 小地图按钮

左键打开待办和标记面板，右键同步（同 `/aipin sync`：保存角色信息、导入助手推送，然后重载界面）。

## 给 AI 助手

把 `AGENTS.md` 发给 AI 助手。助手读取你的角色信息，把标记和待办写进 `Inbox.lua`，你右键同步即可。数据只在你的电脑上，插件不联网。

`/aipin help` 显示全部命令，`/ap` 是 `/aipin` 的简写。
