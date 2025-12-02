<div align="center">
  <a href="https://github.com/Tuziking/OmniDo">
    <img src="images/logo.png" alt="OmniDo Logo" width="120">
  </a>

  <h1>OmniDo</h1>

  <p>
    <strong>专为 macOS 设计的氛围感极简效率应用。</strong><br>
    将任务管理、项目规划、习惯追踪和灵感收集融合在一个统一的沉浸式体验中。
  </p>

  <p>
    <a href="https://github.com/Tuziking/OmniDo/releases">
      <img src="https://img.shields.io/github/v/release/Tuziking/OmniDo?style=flat-square&label=macOS&color=000000&logo=apple" alt="Version">
    </a>
    <img src="https://img.shields.io/badge/Xcode-15.0+-blue?style=flat-square&logo=xcode" alt="Xcode Requirement">
    <img src="https://img.shields.io/github/license/Tuziking/OmniDo?style=flat-square&color=lightgrey" alt="License">
  </p>

  <br>
  
  </div>

---

## ✨ 功能特性与展示

OmniDo 旨在通过极简的设计语言，帮助你排除干扰，回归专注。

### 🧘 沉浸专注模式 (Immersive Focus Mode)

进入纯粹的专注时刻。纯白背景与极简设计，助你心无旁骛。

* **精美时钟:** 选择经典模拟时钟或醒目的数字显示。
* **今日概览:** 并排查看今日待办和已完成任务。

<div align="center">
  <img src="images/image.png" alt="沉浸专注模式展示" width="90%" style="border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
  </div>

<br>

### 🎯 核心效率套件

我们将复杂的工作流拆解为四个直观的维度。

<table>
  <tr>
    <td width="50%" align="center">
      <h3>✅ 任务 (Tasks)</h3>
      <p>通过干净、无干扰的界面管理每日待办事项。</p>
      <img src="images/image-1.png" alt="任务界面">
    </td>
    <td width="50%" align="center">
      <h3>📂 项目 (Projects)</h3>
      <p>将复杂的工作组织成易于管理的项目。</p>
      <img src="images/image-2.png" alt="项目视图">
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <h3>🌱 习惯 (Habits)</h3>
      <p>追踪日常习惯，建立自律生活。</p>
      <img src="images/image-6.png" alt="习惯追踪">
    </td>
    <td width="50%" align="center">
      <h3>💡 灵感 (Inspiration)</h3>
      <p>收集和回顾创意的专属沉浸空间。</p>
      <img src="images/image-7.png" alt="灵感收集">
    </td>
  </tr>
</table>

<br>

### 🖥️ 菜单栏集成 (Menu Bar Integration)

无需离开当前工作环境，随时掌握进度。

* **快速访问:** 点击菜单栏图标即可将 OmniDo 置于前台。
* **即将到期:** 右键点击查看即将到期的任务列表及剩余时间。

---

## ⚠️ 安装与安全提示

由于本项目是一个开源项目且未加入 Apple Developer Program，macOS 的 Gatekeeper 安全机制可能会拦截应用的运行。这属于正常现象，请按照以下步骤操作：

### 提示“无法验证开发者”
1. 在`设置`中找到`隐私与安全性`。
2. 滑到最底部
3. 在`允许以下来源的应用程序`中选择`App Store和已知开发者`。
<div align="center">
  <img src="images/警告.png" alt="沉浸专注模式展示" width="90%" style="border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
  </div>

<br>

---

## 🛠️ 系统要求与构建

### 环境要求
* macOS 14.0 (Sonoma) 或更高版本
* Xcode 15.0+ (用于从源码构建)

### 本地构建指南

如果你是一名开发者，希望从源码运行 OmniDo：

1.  克隆本仓库到本地：
    ```bash
    git clone [https://github.com/你的用户名/OmniDo.git](https://github.com/你的用户名/OmniDo.git)
    ```
2.  在 Xcode 中打开 `OmniDo.xcodeproj` 项目文件。
3.  等待 Swift Package 依赖加载完成。
4.  选择 `OmniDo` scheme，点击运行 (Cmd + R)。

## 📄 许可证

本项目基于 [MIT 许可证](LICENSE) 开源。