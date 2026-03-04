# BossKey

[English](README.md) | 简体中文 | [日本語](README.ja-JP.md)

BossKey 是一个面向 Windows 的桌面工具，用于快速隐藏、恢复和整理指定程序窗口。它既适合传统“老板键”场景，也适合作为轻量级窗口管理工具来整理日常工作环境。

## 功能特性

- 一键隐藏或恢复所有已选目标窗口
- 支持全局热键和分组热键
- 支持纯键盘热键，也支持键盘 + 鼠标按键组合，例如 `Ctrl + Alt + 鼠标中键`
- 支持将相同的隐藏/显示热键作为 `Toggle` 使用
- 支持从运行中窗口列表添加目标，也支持通过窗口拾取器直接点选窗口
- 支持目标分组、重命名分组、折叠分组，以及在分组之间拖拽目标
- 支持为每个目标单独设置右键菜单行为：
  - 隐藏时静音
  - 隐藏时冻结
  - 显示时置顶
  - 显示时移动到鼠标中心
  - 启用或禁用目标
- 支持托盘运行、开机启动、关闭时最小化到托盘、运行日志
- 支持导入 / 导出配置
- 支持手动检查更新和自动检查更新
- 支持基于 JSON 的语言包系统：
  - 程序内置英文
  - 其他语言可从 GitHub 获取并更新到本地
- 支持内置主题系统：
  - 默认亮色 / 暗色主题
  - 实时主题预览
  - 自定义颜色编辑器
  - 主题化消息框和对话框

## 语言包

- 内置语言：English
- 当前仓库提供的远端语言包：简体中文、日语
- 已安装语言包默认保存在：
  - `%APPDATA%\\BossKey\\Languages`
- 主配置文件默认保存在：
  - `%APPDATA%\\BossKey\\settings.json`
- 程序检查更新时，也会检查本地已安装语言包是否存在可用的新版本

## 下载

请从 GitHub Releases 页面获取最新版本：

- 安装包版：适合常规使用
- 单文件版：适合便携使用

发布页：

- <https://github.com/MayFlyOvO/BossKey/releases>

## 运行环境

- Windows 10 / 11
- x64
- 如需从源码构建，请安装 .NET 8 SDK

## 本地运行

```powershell
dotnet build BossKey.sln
dotnet run --project .\BossKey.App\BossKey.App.csproj
```

## 正式构建

```bat
Build-Release.bat
```

GitHub Actions 会构建：

- 自包含安装包
- 自包含单文件版本

## 说明

- 某些高权限或受保护进程，可能需要以管理员身份运行 BossKey 才能稳定使用冻结功能
- 多进程程序的行为取决于所选窗口实际归属的进程
- 某些系统窗口、UWP 容器窗口或特殊渲染窗口，恢复行为可能与普通桌面程序不同

## License

BossKey 使用 [MIT License](LICENSE)。

仓库中同时内置了 Google Material 图标字体资源，这部分资源遵循 Apache 2.0 分发。
