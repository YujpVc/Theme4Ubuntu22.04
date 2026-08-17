# 桌面美化

这套目录只负责桌面外观资源与外观安装，不修改软件配置、软件路径、默认浏览器或应用固定项。当前方案为：

- Shell / GTK：`WhiteSur-Light-solid`
- 顶部栏：黑色半透明背景、白色文字/状态图标、高度 `30px`
- 图标：`WhiteSur-dark` 白色 macOS 风格
- 光标：`McMojave-cursors`
- Dock：`Plank`，底部居中、透明主题、图标 `56px`、悬停放大 `150%`
- 扩展：`blur-my-shell`、`CoverflowAltTab`、`NetSpeed`、`OpenWeather`、`ubuntu-logo-panel`
- 顶部栏最左侧：自定义 Ubuntu 图标，点击打开系统设置
- 快捷键：`Win+Tab` / `Alt+Tab` 都走 Coverflow 切换效果
- 壁纸：哲风壁纸“卡通-水面-治愈”视频动态壁纸，循环播放

## 目录说明

- `themes/`：WhiteSur-Light、WhiteSur-Light-solid、Tahoe 旧主题
- `icons/`：WhiteSur、WhiteSur-light、WhiteSur-dark、McMojave-cursors
- `extensions/`：当前使用的用户 GNOME Shell 扩展
- `configs/`：Plank 自启动、GTK 覆盖样式、GNOME Shell 扩展外观 dconf
- `wallpapers/`：静态壁纸与 `Minimal-Mojave/` 动态壁纸资源
- `preview.png`：当前美化效果预览
- `install.sh`：一键复制到新机器用户目录

## 安装范围

会安装或应用：

- GNOME Shell / GTK 主题
- 图标主题和光标主题
- 壁纸
- Minimal-Mojave 动态壁纸
- Minimal-Mojave live 视频壁纸与登录自启动
- GTK 外观覆盖 CSS
- GNOME Shell 外观扩展
- Plank 自启动和视觉配置
- 桌面/锁屏壁纸、主题、图标、光标相关 gsettings

不会安装或修改：

- Cursor 或其他第三方软件入口、图标、路径
- Edge desktop 覆盖或默认浏览器
- Plank / GNOME 固定应用列表
- `appmenu-gtk-module` 等软件模块配置

## 新机器安装步骤

1. 目标机器要求：Ubuntu 22.04 / GNOME 42 / X11。Plank 不支持 Wayland。
2. 安装基础工具和 Plank：

   ```bash
   sudo apt update
   sudo apt install -y plank gnome-tweaks
   ```

3. 把整个 `Theme` 目录放到新机器任意位置，然后执行：

   ```bash
   cd Theme
   bash install.sh
   ```

4. 重启 GNOME Shell：

   ```bash
   kill -HUP $(pgrep -x gnome-shell | head -1)
   ```

5. 确认扩展已启用：

   ```bash
   gnome-extensions list --enabled
   ```

  需要启用：`blur-my-shell@aunetx`、`CoverflowAltTab@palatis.blogspot.com`、`netspeed@alynx.one`、`openweather-extension@jenslody.de`、`ubuntu-logo-panel@rx01334.local`、`user-theme@gnome-shell-extensions.gcampax.github.com`。

## 额外说明

- `NetSpeed` 已替换为 AlynxZhou 的 `Net Speed` v6，metadata 原生支持 `GNOME 40-44`。
- `configs/gtk-4.0/gtk.css` 和 `configs/gtk-3.0/gtk.css` 是 GTK4/GTK3 文件选择器 hover 残留的规避样式；带 `.disabled` 的是旧的 Tahoe 覆盖样式备份，不再启用。
- 顶部栏高度和颜色在 `themes/WhiteSur-Light-solid/gnome-shell/gnome-shell.css`：

  ```css
  #panel {
      height: 30px !important;
      background-color: rgba(0, 0, 0, 0.6);
      color: white;
  }
  ```

- 壁纸恢复：

  ```bash
  gsettings set org.gnome.desktop.background picture-uri "file://$HOME/.local/share/backgrounds/gnome/Minimal-Mojave-timed.xml"
  ```

- Ubuntu 22.04 / GNOME 42 原生支持 XML 时间轴动态壁纸；`install.sh` 会把
  `wallpapers/Minimal-Mojave/` 中的模板安装到用户目录并应用。资源来源：
  `https://github.com/manishprivet/dynamic-gnome-wallpapers`

- 若需要持续可见的动画，`install.sh` 还会安装
  `tools/minimal-mojave-live.sh` 和登录自启动条目，使用 `ffplay` 播放
  `Minimal-Mojave-live.mp4` 作为桌面层。当前该文件为哲风壁纸
  “卡通-水面-治愈”，原始分辨率 `2850x1604`。
