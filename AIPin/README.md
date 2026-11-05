# AIPin — WoW: Forever 地图标记插件

把助手给你的 `/aipin` 指令粘贴到游戏聊天框，就会在世界地图上打一个亮色标记，并设置系统路点（有箭头）

## 安装（国服 / CN Battle.net · Forever）

1. **先完全退出**《魔兽世界：Forever》。
2. 解压 `AIPin.zip`，得到文件夹 `AIPin`（里面直接有 `AIPin.toc` 和 `AIPin.lua`）。
3. 把整个 `AIPin` 文件夹放到 Forever 插件目录：

   ```
   World of Warcraft\_forever_\Interface\AddOns\AIPin\
   ```

   常见完整路径示例：

   ```
   C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\AIPin\
   ```

   Mac 默认路径：`/Applications/World of Warcraft/_forever_/Interface/AddOns/AIPin/`

   若你用的是国服战网自定义安装目录，在战网客户端里右键 Forever →「显示安装文件夹」，再进入 `_forever_\Interface\AddOns\`。

4. 确认结构是：

   ```
   AddOns\
     AIPin\
       AIPin.toc
       AIPin.lua
       README.md
   ```

   **不要**多套一层 `AIPin\AIPin\...`。

5. 启动 Forever → 角色选择界面点 **插件 / AddOns** → 勾选 **AIPin** → 进入游戏。


## 用法

聊天框粘贴助手发来的指令，例如：

```
/aipin 丹莫罗 44.1 57.1 巡山人格雷琴
/aipin Dun Morogh 44.1 57.1 Mountaineer Gretchen
/aipin 铁炉堡 60.0 45.4 附魔训练师
/aipin 44.1 57.1 巡山人格雷琴
```

其它命令：

| 命令 | 作用 |
|------|------|
| `/aipin clear` 或 `/ap clear` | 清除全部 AIPin 标记 |
| `/aipin list` | 列出当前标记 |
| `/aipin help` | 简短帮助 |

命令：`/aipin`（主命令）、`/ap`（简写）。

坐标与 Wowhead / ForG 相同，是地图百分比（0–100）。打上标记后按 **M** 打开地图查看。

## 说明与限制

- 无外部依赖。
- 世界地图用黄色「可接任务」图标叠针；系统路点负责箭头导航。
- Forever 若某张地图不允许用户路点，仍会保存标记并在打开该区域大地图时显示。
- 区域名支持中英文（丹莫罗 / Dun Morogh 等）；未知区域名会回退到你当前所在地图。
- 最多保留最近 20 个标记。

## 版本

- **1.0.0** — Interface 16001（Forever）

## 助手直接推送标记（不用粘贴）
插件目录里的 `Inbox.lua` 是收件箱。助手可以直接在你电脑上改这个文件，你在游戏里输入 `/reload`，新标记就会出现在地图上。已经导入过的标记不会重复导入。
注意：第一次安装后需要完全重启游戏，插件才会加载 Inbox.lua。之后用 `/reload` 就够了。

## 给 AI 助手（agent）
如果你也在用 AI 助手，把同一目录里的 `AGENTS.md` 发给它看。里面写了怎么生成 `/aipin` 命令，以及怎么改 `Inbox.lua` 直接推送标记。

## 角色信息记录（v1.1）

AIPin 会自动记录你的角色信息：等级、经验、金币、所在地图和坐标、天赋、专业技能、任务日志及进度、装备、背包空位、炉石位置。你的助手在你 `/reload` 或下线后读取这些信息，就不用你手动告诉它等级和任务了。

- 游戏只在 `/reload`、退出游戏或切换角色时才写入文件。问助手之前打一下 `/reload`，数据就是最新的。
- 文件位置：`WTF/Account/<账号>/SavedVariables/AIPin.lua`（在 `_forever_` 文件夹里）。
- `/aipin me`：在聊天框显示简要信息（等级、位置、任务数）。
- 数据只保存在你自己的电脑上，插件不会联网。

## 小地图按钮（v1.1）

- 小地图边上有一个 AIPin 圆形按钮，可以拖动它沿小地图边缘移动。
- **右键：同步**。保存角色信息、导入助手推送的标记（会重载界面，效果同 `/reload`）。战斗中不能同步。
- **左键：标记列表**。可以逐个删除标记、全部清除，并显示上次同步时间和收件箱版本。
- 命令：`/aipin sync`（同步）、`/aipin minimap`（显示/隐藏按钮）。

## 待办清单与地理提醒（1.3.0）

左键点小地图 AIPin 按钮，面板下方就是待办区：
- 在输入框写内容，回车或点「添加待办」即可添加；
- 写成 `学法杖 @ 暴风城 63.9 69.1` 就是地理提醒，走到那附近会在聊天框和屏幕中央提醒并播放音效；
- 点「提醒在此处」用你当前位置创建提醒；
- 勾选框标记完成，✕ 删除，「清除已完成」批量清理。

小地图按钮右下角的数字是未完成待办数。

命令：
- `/aipin todo <内容> [@ 区域 x y]` 添加
- `/aipin todos` 列出
- `/aipin done N` / `/aipin undone N` 标记完成 / 未完成
- `/aipin deltodo N` 删除
- `/aipin cleartodos` 清除已完成
