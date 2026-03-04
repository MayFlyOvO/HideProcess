# BossKey

English | [简体中文](README.zh-CN.md) | [日本語](README.ja-JP.md)

BossKey is a Windows desktop utility for quickly hiding, restoring, and organizing selected application windows. It is built for fast “boss key” workflows, but it is also useful as a lightweight window control tool for daily work setups.

## Features

- Hide or restore all selected targets instantly.
- Configure global hotkeys and per-group hotkeys.
- Use keyboard-only hotkeys or keyboard + mouse button combinations such as `Ctrl + Alt + Mouse Middle`.
- Allow the same hide/show hotkey to act as a toggle.
- Add targets from the running window list or by using the window picker.
- Organize targets into groups, rename groups, collapse groups, and drag targets between groups.
- Configure per-target behaviors from the context menu:
  - mute on hide
  - freeze on hide
  - topmost on show
  - center on cursor on show
  - enable or disable a target
- Run in the tray, start with Windows, minimize to tray on close, and keep a runtime log.
- Import and export settings.
- Check for app updates manually or automatically.
- Use JSON-based language packs:
  - English is built in
  - additional languages can be fetched from GitHub and updated locally
- Customize the UI with a built-in theme system:
  - default light and dark themes
  - live theme preview
  - custom color editor
  - themed message boxes and dialogs

## Language Packs

- Built-in language: English
- Remote language packs currently included in this repository: Simplified Chinese and Japanese
- Installed language packs are stored in:
  - `%APPDATA%\\BossKey\\Languages`
- Main settings are stored in:
  - `%APPDATA%\\BossKey\\settings.json`
- When the app checks for updates, it can also refresh installed language packs if newer versions are available.

## Download

Get the latest release from GitHub Releases:

- Installer build: recommended for normal use
- Single-file build: recommended for portable use

Release page:

- <https://github.com/MayFlyOvO/BossKey/releases>

## Requirements

- Windows 10 / 11
- x64
- .NET 8 SDK to build from source

## Build From Source

```powershell
dotnet build BossKey.sln
dotnet run --project .\BossKey.App\BossKey.App.csproj
```

## Release Build

```bat
Build-Release.bat
```

The GitHub Actions workflow builds:

- a self-contained installer package
- a self-contained single-file package

## Notes

- Some elevated or protected processes may require BossKey itself to run as administrator for freeze behavior to work reliably.
- Behavior for multi-process applications depends on which process owns the selected window.
- Some system windows, UWP container windows, or special-rendered windows may not restore exactly like standard desktop apps.

## License

BossKey is licensed under the [MIT License](LICENSE).

This repository also bundles Google Material icon font assets that are distributed under Apache 2.0.
