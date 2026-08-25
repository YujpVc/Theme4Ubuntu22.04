# Dock 双图标应用修复

这个目录不随 `install.sh` 自动执行，供 AI 或人工在安装后遇到以下问题时参考：

- Microsoft Edge 启动后 Dock 出现两个图标
- Terminator 启动后 Dock 出现两个图标

## 根因

### Edge

Edge 可能同时存在两个 desktop 入口：

```text
microsoft-edge.desktop
com.microsoft.Edge.desktop
```

如果 Plank 固定项指向 `microsoft-edge.desktop`，而窗口启动后匹配到
`com.microsoft.Edge.desktop`，Dock 会认为它们是两个应用，于是出现两个图标。

修复原则是只保留 `com.microsoft.Edge.desktop` 作为可见入口，把旧的
`microsoft-edge.desktop` 隐藏并改成不匹配窗口类，同时让 Plank 固定项和默认浏览器
都指向 `com.microsoft.Edge.desktop`。

### Terminator

Terminator 的窗口类实际为：

```text
WM_CLASS = "terminator", "Terminator"
```

但系统 `/usr/share/applications/terminator.desktop` 默认可能缺少
`StartupWMClass`，导致固定图标无法和运行窗口归并。

修复原则是创建或更新用户级 `terminator.desktop`，增加：

```text
StartupWMClass=terminator
```

### ToDesk

ToDesk 客户端启动后，主窗口可能只被创建为隐藏/未映射状态，Dock 再点一次也不会唤出。
用户级 desktop 入口需要指向一个启动脚本，负责检测/启动 ToDesk、映射隐藏窗口，
并把主窗口移到可见位置。

修复需要 `xdotool`，如果缺失先执行：

```bash
sudo apt install -y xdotool
```

在 `all` 模式下如果缺少 `xdotool`，脚本会跳过 ToDesk，只修 Edge/Terminator。

## 使用

进入 Theme 目录后运行：

```bash
bash configs/applications/fix-dock-app-icons.sh all
```

也可以只修其中一个：

```bash
bash configs/applications/fix-dock-app-icons.sh edge
bash configs/applications/fix-dock-app-icons.sh terminator
bash configs/applications/fix-dock-app-icons.sh todesk
```

先检查再执行：

```bash
bash configs/applications/fix-dock-app-icons.sh all --dry-run
```

脚本只写用户目录，不修改 `/usr/share/applications`，也不需要 root。它会：

- 创建或更新 `~/.local/share/applications/com.microsoft.Edge.desktop`
- 创建或更新 `~/.local/share/applications/microsoft-edge.desktop` 为隐藏占位入口
- 创建或更新 `~/.local/share/applications/terminator.desktop`
- 创建或更新 `~/.local/bin/todesk-dock`
- 创建或更新 `~/.local/share/applications/todesk.desktop`
- 修正 Plank `Launcher=file://...` 指向
- 修正 Edge 默认浏览器 MIME 关联
- 重建用户桌面数据库

## 排查命令

```bash
find /usr/share/applications ~/.local/share/applications \
  ~/.config/plank/dock1/launchers \
  -maxdepth 1 -iname "*edge*" -o -iname "*terminator*" 2>/dev/null

grep -H "StartupWMClass=" \
  /usr/share/applications/*edge*.desktop \
  ~/.local/share/applications/*edge*.desktop 2>/dev/null

grep -H "StartupWMClass=" \
  /usr/share/applications/terminator.desktop \
  ~/.local/share/applications/terminator.desktop 2>/dev/null
```

## 生效

修改后需要完全关闭 Edge/Terminator 再重新打开。若 Dock 仍有缓存图标，重启 Plank
或注销重登一次。

ToDesk 修改后先关闭并重新打开 ToDesk；如果主窗口仍不可见，可手动运行：

```bash
bash ~/.local/bin/todesk-dock
```

```bash
pkill -x plank
plank &
```

如果 GNOME Shell 的 Ubuntu Dock 也在显示运行图标，还需要：

```bash
kill -HUP "$(pgrep -x gnome-shell | head -1)"
```
