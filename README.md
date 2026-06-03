# macOS Todo App

一个原生 macOS 待办项管理应用，使用 Swift + SwiftUI 开发。

## 功能特性

- 📁 分类管理：创建、编辑、删除、拖拽排序
- ✅ 待办项管理：标题、优先级、截止日期、完成状态
- ⚡ 全局快捷键：`⌘ + Shift + T` 快速添加待办项
- 🎨 柔和渐变视觉风格：现代简洁的 macOS 设计语言
- 💾 本地存储：Core Data 数据持久化

## 技术栈

- **框架**：Swift 5.9+, SwiftUI
- **数据存储**：Core Data
- **全局快捷键**：HotKey 库
- **系统要求**：macOS 13.0+

## 项目结构

```
TodoApp/
├── Models/              # Core Data 模型
├── Views/
│   ├── MainWindow/      # 主窗口视图
│   └── QuickInput/      # 快捷输入悬浮窗口
├── ViewModels/          # 数据操作逻辑
├── Services/            # Core Data & 快捷键管理
└── Utilities/           # 主题常量
```

## 开发进度

详见 [实现计划](docs/superpowers/plans/2026-06-02-macos-todo-app.md)

## 许可证

MIT License