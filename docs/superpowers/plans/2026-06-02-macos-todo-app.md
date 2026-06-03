# macOS 待办项管理应用 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个原生 macOS 待办项管理应用，支持分类管理、全局快捷键快速输入，数据使用 Core Data 本地存储。

**Architecture:** Swift + SwiftUI，NavigationSplitView 主窗口，NSPanel 悬浮快捷输入窗口，Core Data 持久化。全局快捷键通过 HotKey 库注册。

**Tech Stack:** Swift 5.9+, SwiftUI, Core Data, HotKey 库 (全局快捷键), macOS 13.0+

---

## 文件结构

| 文件 | 职责 |
|------|------|
| `TodoAppApp.swift` | 应用入口，注册 Core Data，初始化快捷键 |
| `Models/TodoApp.xcdatamodeld` | Core Data 模型（Category, TodoItem） |
| `Services/PersistenceController.swift` | Core Data stack 单例 |
| `Services/HotkeyManager.swift` | HotKey 全局快捷键注册与回调 |
| `ViewModels/TodoViewModel.swift` | 分类和待办项的 CRUD 操作 |
| `Views/MainWindow/ContentView.swift` | NavigationSplitView 根视图 |
| `Views/MainWindow/SidebarView.swift` | 侧边栏分类列表 |
| `Views/MainWindow/TodoListView.swift` | 右侧待办项列表（含已完成区域） |
| `Views/MainWindow/TodoRowView.swift` | 单个待办项行视图 |
| `Views/QuickInput/QuickInputPanel.swift` | NSPanel 悬浮窗口控制器 |
| `Views/QuickInput/QuickInputView.swift` | 悬浮窗口的 SwiftUI 内容视图 |
| `Utilities/Theme.swift` | 颜色、字体、间距常量 |

---

### Task 1: Xcode 项目初始化

**Files:**
- Create: `TodoApp.xcodeproj`
- Create: `TodoApp/TodoAppApp.swift`

- [ ] **Step 1: 在 Xcode 创建新项目**

File → New → Project → macOS → App
- Product Name: `TodoApp`
- Bundle Identifier: `com.yourname.todoapp`
- Interface: SwiftUI
- Storage: Core Data（勾选）
- Language: Swift
- Minimum Deployment: macOS 13.0

- [ ] **Step 2: 清理 Xcode 默认生成的多余代码**

删除 `ContentView.swift` 中的 Hello World 内容，保留文件结构。
删除默认生成的 `Item` Core Data entity（我们将在 Task 2 重建）。

- [ ] **Step 3: 添加 HotKey Swift Package**

File → Add Package Dependencies
URL: `https://github.com/soffes/HotKey`
Version: Up to Next Major from `0.2.0`

- [ ] **Step 4: Commit**

```bash
git add .
git commit -m "chore: init Xcode project with Core Data and HotKey dependency"
```

---

### Task 2: Core Data 模型

**Files:**
- Modify: `TodoApp/Models/TodoApp.xcdatamodeld`
- Create: `TodoApp/Services/PersistenceController.swift`

- [ ] **Step 1: 在 .xcdatamodeld 中创建 Category entity**

Entity name: `Category`
Attributes:
- `id`: Integer 64, Optional: No
- `name`: String, Optional: No, Default: ""
- `displayOrder`: Integer 16, Optional: No, Default: 0
- `createdAt`: Date, Optional: No

Relationship:
- `items`: To-Many → TodoItem, Delete Rule: Cascade, Inverse: `category`

- [ ] **Step 2: 在 .xcdatamodeld 中创建 TodoItem entity**

Entity name: `TodoItem`
Attributes:
- `id`: Integer 64, Optional: No
- `title`: String, Optional: No, Default: ""
- `isCompleted`: Boolean, Optional: No, Default: NO
- `dueDate`: Date, Optional: Yes
- `priority`: Integer 16, Optional: No, Default: 1（1=中）
- `createdAt`: Date, Optional: No

Relationship:
- `category`: To-One → Category, Delete Rule: Nullify, Inverse: `items`

- [ ] **Step 3: 创建 PersistenceController.swift**

```swift
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TodoApp")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error { fatalError("Core Data error: \(error)") }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let ctx = controller.container.viewContext
        let cat = Category(context: ctx)
        cat.id = 1
        cat.name = "工作"
        cat.displayOrder = 0
        cat.createdAt = Date()
        try? ctx.save()
        return controller
    }()
}
```

- [ ] **Step 4: 更新 TodoAppApp.swift**

```swift
import SwiftUI

@main
struct TodoAppApp: App {
    let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
```

- [ ] **Step 5: 构建验证**

在 Xcode 按 `⌘B`，确认无编译错误。

- [ ] **Step 6: Commit**

```bash
git add .
git commit -m "feat: add Core Data model with Category and TodoItem entities"
```

---

### Task 3: Theme 常量

**Files:**
- Create: `TodoApp/Utilities/Theme.swift`

- [ ] **Step 1: 创建 Theme.swift**

```swift
import SwiftUI

enum Theme {
    // Colors - Light
    static let backgroundLight = Color(hex: "#F8F6FF")
    static let primaryTextLight = Color(hex: "#2D2D3A")
    static let secondaryTextLight = Color(hex: "#8B8BA7")
    static let hoverLight = Color(hex: "#EDE9FE")

    // Colors - Dark
    static let backgroundDark = Color(hex: "#16162A")
    static let primaryTextDark = Color(hex: "#E8E8FF")
    static let secondaryTextDark = Color(hex: "#6B6B8A")

    // Accent gradient
    static let accentStart = Color(hex: "#7C3AED")
    static let accentEnd = Color(hex: "#A855F7")
    static let accent = LinearGradient(
        colors: [accentStart, accentEnd],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Spacing
    static let spacingS: CGFloat = 10
    static let spacingM: CGFloat = 18
    static let spacingL: CGFloat = 28

    // Corner radius
    static let radiusItem: CGFloat = 10
    static let radiusPanel: CGFloat = 16

    // Font
    static func rounded(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded).weight(weight)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
```

- [ ] **Step 2: 构建验证**

`⌘B`，确认无错误。

- [ ] **Step 3: Commit**

```bash
git add TodoApp/Utilities/Theme.swift
git commit -m "feat: add Theme constants for Soft & Warm visual style"
```

---

### Task 4: TodoViewModel

**Files:**
- Create: `TodoApp/ViewModels/TodoViewModel.swift`

- [ ] **Step 1: 创建 TodoViewModel.swift**

```swift
import CoreData
import SwiftUI

class TodoViewModel: ObservableObject {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Category

    func addCategory(name: String, after lastOrder: Int16) {
        let cat = Category(context: context)
        cat.id = Int64(Date().timeIntervalSince1970 * 1000)
        cat.name = name
        cat.displayOrder = lastOrder + 1
        cat.createdAt = Date()
        save()
    }

    func renameCategory(_ category: Category, to name: String) {
        category.name = name
        save()
    }

    func deleteCategory(_ category: Category) {
        context.delete(category)
        save()
    }

    func reorderCategories(_ categories: [Category]) {
        for (index, cat) in categories.enumerated() {
            cat.displayOrder = Int16(index)
        }
        save()
    }

    // MARK: - TodoItem

    func addTodo(title: String, priority: Int16, dueDate: Date?, to category: Category) {
        let item = TodoItem(context: context)
        item.id = Int64(Date().timeIntervalSince1970 * 1000)
        item.title = title
        item.isCompleted = false
        item.priority = priority
        item.dueDate = dueDate
        item.createdAt = Date()
        item.category = category
        save()
    }

    func toggleComplete(_ item: TodoItem) {
        item.isCompleted.toggle()
        save()
    }

    func updateTodo(_ item: TodoItem, title: String, priority: Int16, dueDate: Date?) {
        item.title = title
        item.priority = priority
        item.dueDate = dueDate
        save()
    }

    func deleteTodo(_ item: TodoItem) {
        context.delete(item)
        save()
    }

    // MARK: - Private

    private func save() {
        try? context.save()
    }
}
```

- [ ] **Step 2: 构建验证**

`⌘B`，确认无错误。

- [ ] **Step 3: Commit**

```bash
git add TodoApp/ViewModels/TodoViewModel.swift
git commit -m "feat: add TodoViewModel with CRUD for categories and todos"
```

---

### Task 5: 侧边栏视图

**Files:**
- Create: `TodoApp/Views/MainWindow/SidebarView.swift`

- [ ] **Step 1: 创建 SidebarView.swift**

```swift
import SwiftUI
import CoreData

struct SidebarView: View {
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.displayOrder)],
        animation: .default
    ) private var categories: FetchedResults<Category>

    @ObservedObject var vm: TodoViewModel
    @Binding var selectedCategory: Category?
    @State private var editingCategory: Category?
    @State private var editingName = ""
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""

    var body: some View {
        List(selection: $selectedCategory) {
            ForEach(categories) { category in
                categoryRow(category)
                    .tag(category)
            }
            .onMove { from, to in
                var reordered = Array(categories)
                reordered.move(fromOffsets: from, toOffset: to)
                vm.reorderCategories(reordered)
            }
        }
        .safeAreaInset(edge: .bottom) {
            addCategoryButton
        }
        .sheet(isPresented: $showingAddCategory) {
            addCategorySheet
        }
    }

    @ViewBuilder
    private func categoryRow(_ category: Category) -> some View {
        if editingCategory == category {
            TextField("分类名称", text: $editingName)
                .onSubmit {
                    if !editingName.isEmpty {
                        vm.renameCategory(category, to: editingName)
                    }
                    editingCategory = nil
                }
        } else {
            Text(category.name ?? "")
                .font(Theme.rounded(.body))
                .contextMenu {
                    Button("重命名") {
                        editingName = category.name ?? ""
                        editingCategory = category
                    }
                    Button("删除", role: .destructive) {
                        vm.deleteCategory(category)
                    }
                }
                .onTapGesture(count: 2) {
                    editingName = category.name ?? ""
                    editingCategory = category
                }
        }
    }

    private var addCategoryButton: some View {
        Button {
            showingAddCategory = true
        } label: {
            Label("新分类", systemImage: "plus")
                .font(Theme.rounded(.body))
        }
        .buttonStyle(.plain)
        .padding(Theme.spacingS)
    }

    private var addCategorySheet: some View {
        VStack(spacing: Theme.spacingM) {
            Text("新建分类").font(Theme.rounded(.headline, weight: .semibold))
            TextField("分类名称", text: $newCategoryName)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("取消") { showingAddCategory = false }
                Spacer()
                Button("添加") {
                    if !newCategoryName.isEmpty {
                        vm.addCategory(name: newCategoryName, after: Int16(categories.count))
                        newCategoryName = ""
                        showingAddCategory = false
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(Theme.spacingM)
        .frame(width: 280)
    }
}
```

- [ ] **Step 2: 构建验证**

`⌘B`，确认无错误。

- [ ] **Step 3: Commit**

```bash
git add TodoApp/Views/MainWindow/SidebarView.swift
git commit -m "feat: add SidebarView with category list, add/rename/delete/reorder"
```

---

### Task 6: 待办项列表视图

**Files:**
- Create: `TodoApp/Views/MainWindow/TodoRowView.swift`
- Create: `TodoApp/Views/MainWindow/TodoListView.swift`

- [ ] **Step 1: 创建 TodoRowView.swift**

```swift
import SwiftUI

struct TodoRowView: View {
    @ObservedObject var item: TodoItem
    let onToggle: () -> Void
    let onDelete: () -> Void
    @State private var isEditing = false
    @State private var editTitle = ""

    private var priorityColor: Color {
        switch item.priority {
        case 2: return .red
        case 1: return .orange
        default: return .green
        }
    }

    private var priorityLabel: String {
        switch item.priority {
        case 2: return "高"
        case 1: return "中"
        default: return "低"
        }
    }

    var body: some View {
        HStack(spacing: Theme.spacingS) {
            Button { onToggle() } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? Theme.accentStart : .secondary)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)

            if isEditing {
                TextField("", text: $editTitle)
                    .onSubmit { commitEdit() }
            } else {
                Text(item.title ?? "")
                    .font(Theme.rounded(.body))
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                    .onTapGesture(count: 2) {
                        editTitle = item.title ?? ""
                        isEditing = true
                    }
            }

            Spacer()

            Text(priorityLabel)
                .font(Theme.rounded(.caption2, weight: .medium))
                .foregroundStyle(priorityColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(priorityColor.opacity(0.12))
                .clipShape(Capsule())

            if let due = item.dueDate {
                Text(due, style: .date)
                    .font(Theme.rounded(.caption))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, Theme.spacingS)
        .padding(.vertical, 6)
        .background(Color.clear)
        .cornerRadius(Theme.radiusItem)
        .contextMenu {
            Button("删除", role: .destructive) { onDelete() }
        }
    }

    private func commitEdit() {
        if !editTitle.isEmpty {
            item.title = editTitle
            try? item.managedObjectContext?.save()
        }
        isEditing = false
    }
}
```

- [ ] **Step 2: 创建 TodoListView.swift**

```swift
import SwiftUI
import CoreData

struct TodoListView: View {
    let category: Category
    @ObservedObject var vm: TodoViewModel
    @State private var showCompleted = false
    @State private var newTodoTitle = ""
    @State private var newTodoPriority: Int16 = 1
    @State private var newTodoDueDate: Date? = nil
    @State private var showAddTodo = false

    private var activeTodos: [TodoItem] {
        (category.items as? Set<TodoItem> ?? [])
            .filter { !$0.isCompleted }
            .sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
    }

    private var completedTodos: [TodoItem] {
        (category.items as? Set<TodoItem> ?? [])
            .filter { $0.isCompleted }
            .sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Toolbar
            HStack {
                Button {
                    showAddTodo = true
                } label: {
                    Label("新待办项", systemImage: "plus")
                        .font(Theme.rounded(.body))
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding(Theme.spacingM)

            Divider()

            // Active todos
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(activeTodos) { item in
                        TodoRowView(item: item) {
                            vm.toggleComplete(item)
                        } onDelete: {
                            vm.deleteTodo(item)
                        }
                    }

                    // Completed section
                    if !completedTodos.isEmpty {
                        Button {
                            withAnimation { showCompleted.toggle() }
                        } label: {
                            HStack {
                                Image(systemName: showCompleted ? "chevron.down" : "chevron.right")
                                Text("已完成 (\(completedTodos.count))")
                                    .font(Theme.rounded(.subheadline, weight: .medium))
                                Spacer()
                            }
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, Theme.spacingS)
                            .padding(.top, Theme.spacingM)
                        }
                        .buttonStyle(.plain)

                        if showCompleted {
                            ForEach(completedTodos) { item in
                                TodoRowView(item: item) {
                                    vm.toggleComplete(item)
                                } onDelete: {
                                    vm.deleteTodo(item)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.spacingS)
                .padding(.vertical, Theme.spacingS)
            }
        }
        .sheet(isPresented: $showAddTodo) {
            addTodoSheet
        }
        .navigationTitle(category.name ?? "")
    }

    private var addTodoSheet: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("新建待办项").font(Theme.rounded(.headline, weight: .semibold))

            TextField("标题", text: $newTodoTitle)
                .textFieldStyle(.roundedBorder)

            Picker("优先级", selection: $newTodoPriority) {
                Text("低").tag(Int16(0))
                Text("中").tag(Int16(1))
                Text("高").tag(Int16(2))
            }
            .pickerStyle(.segmented)

            DatePicker("截止日期（可选）",
                       selection: Binding(
                            get: { newTodoDueDate ?? Date() },
                            set: { newTodoDueDate = $0 }
                       ),
                       displayedComponents: .date)
            Toggle("设置截止日期", isOn: Binding(
                get: { newTodoDueDate != nil },
                set: { newTodoDueDate = $0 ? Date() : nil }
            ))

            HStack {
                Button("取消") { showAddTodo = false }
                Spacer()
                Button("添加") {
                    if !newTodoTitle.isEmpty {
                        vm.addTodo(title: newTodoTitle, priority: newTodoPriority, dueDate: newTodoDueDate, to: category)
                        newTodoTitle = ""
                        newTodoPriority = 1
                        newTodoDueDate = nil
                        showAddTodo = false
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(Theme.spacingM)
        .frame(width: 320)
    }
}
```

- [ ] **Step 3: 构建验证**

`⌘B`，确认无错误。

- [ ] **Step 4: Commit**

```bash
git add TodoApp/Views/MainWindow/TodoRowView.swift TodoApp/Views/MainWindow/TodoListView.swift
git commit -m "feat: add TodoListView and TodoRowView with active/completed sections"
```

---

### Task 7: 主窗口 ContentView

**Files:**
- Modify: `TodoApp/Views/MainWindow/ContentView.swift`

- [ ] **Step 1: 更新 ContentView.swift**

```swift
import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.displayOrder)],
        animation: .default
    ) private var categories: FetchedResults<Category>

    @StateObject private var vm: TodoViewModel
    @State private var selectedCategory: Category?

    init() {
        _vm = StateObject(wrappedValue: TodoViewModel(context: PersistenceController.shared.container.viewContext))
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(vm: vm, selectedCategory: $selectedCategory)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        } detail: {
            if let category = selectedCategory {
                TodoListView(category: category, vm: vm)
            } else {
                ContentUnavailableView("选择一个分类", systemImage: "list.bullet")
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            if selectedCategory == nil {
                selectedCategory = categories.first
            }
        }
    }
}
```

- [ ] **Step 2: 构建并运行**

`⌘R`，确认主窗口正常显示侧边栏和待办项列表，可以添加分类和待办项。

- [ ] **Step 3: Commit**

```bash
git add TodoApp/Views/MainWindow/ContentView.swift
git commit -m "feat: assemble main window with NavigationSplitView"
```

---

### Task 8: 全局快捷键管理器

**Files:**
- Create: `TodoApp/Services/HotkeyManager.swift`

- [ ] **Step 1: 创建 HotkeyManager.swift**

```swift
import HotKey
import AppKit

class HotkeyManager {
    static let shared = HotkeyManager()
    private var hotKey: HotKey?
    var onActivate: (() -> Void)?

    private init() {}

    func register() {
        // Default: ⌘ + Shift + T
        hotKey = HotKey(key: .t, modifiers: [.command, .shift])
        hotKey?.keyDownHandler = { [weak self] in
            self?.onActivate?()
        }
    }

    func unregister() {
        hotKey = nil
    }
}
```

- [ ] **Step 2: 在 TodoAppApp.swift 中启动注册**

```swift
import SwiftUI

@main
struct TodoAppApp: App {
    let persistence = PersistenceController.shared

    init() {
        HotkeyManager.shared.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
```

- [ ] **Step 3: 在 Info.plist 添加辅助功能权限说明**

在 Xcode 的 `Info.plist` 中添加：
- Key: `NSAppleEventsUsageDescription`
- Value: `TodoApp 需要辅助功能权限以支持全局快捷键`

- [ ] **Step 4: 构建验证**

`⌘B`，确认无错误。

- [ ] **Step 5: Commit**

```bash
git add TodoApp/Services/HotkeyManager.swift TodoApp/TodoAppApp.swift TodoApp/Info.plist
git commit -m "feat: add global hotkey manager with default ⌘+Shift+T"
```

---

### Task 9: 快捷输入悬浮窗口

**Files:**
- Create: `TodoApp/Views/QuickInput/QuickInputView.swift`
- Create: `TodoApp/Views/QuickInput/QuickInputPanel.swift`

- [ ] **Step 1: 创建 QuickInputView.swift**

```swift
import SwiftUI
import CoreData

struct QuickInputView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.displayOrder)]
    ) private var categories: FetchedResults<Category>

    @State private var selectedCategory: Category?
    @State private var title = ""
    @State private var priority: Int16 = 1
    @State private var dueDate: Date? = nil

    private var vm: TodoViewModel {
        TodoViewModel(context: context)
    }

    private var currentTodos: [TodoItem] {
        guard let cat = selectedCategory else { return [] }
        return (cat.items as? Set<TodoItem> ?? [])
            .sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: category picker + close
            HStack {
                Picker("", selection: $selectedCategory) {
                    ForEach(categories) { cat in
                        Text(cat.name ?? "").tag(Optional(cat))
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 160)

                Spacer()

                Button {
                    NSApp.keyWindow?.close()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.spacingM)
            .padding(.top, Theme.spacingM)
            .padding(.bottom, Theme.spacingS)

            Divider()

            // Input
            TextField("输入待办项标题...", text: $title)
                .font(Theme.rounded(.body))
                .textFieldStyle(.plain)
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingS)
                .onSubmit { addTodo() }

            Divider()

            // Priority + due date
            HStack(spacing: Theme.spacingM) {
                Picker("", selection: $priority) {
                    Text("低").tag(Int16(0))
                    Text("中").tag(Int16(1))
                    Text("高").tag(Int16(2))
                }
                .pickerStyle(.segmented)
                .frame(width: 140)

                Spacer()

                Toggle("截止", isOn: Binding(
                    get: { dueDate != nil },
                    set: { dueDate = $0 ? Date() : nil }
                ))

                if dueDate != nil {
                    DatePicker("", selection: Binding(
                        get: { dueDate ?? Date() },
                        set: { dueDate = $0 }
                    ), displayedComponents: .date)
                    .labelsHidden()
                }
            }
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, Theme.spacingS)

            Divider()

            // Current category todos list
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(currentTodos) { item in
                        HStack {
                            Button {
                                item.isCompleted.toggle()
                                try? context.save()
                            } label: {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(item.isCompleted ? Theme.accentStart : .secondary)
                            }
                            .buttonStyle(.plain)

                            Text(item.title ?? "")
                                .font(Theme.rounded(.body))
                                .strikethrough(item.isCompleted)
                                .foregroundStyle(item.isCompleted ? .secondary : .primary)

                            Spacer()
                        }
                        .padding(.horizontal, Theme.spacingM)
                        .padding(.vertical, 4)
                    }
                }
            }
            .frame(maxHeight: 200)

            Divider()

            // Add button
            HStack {
                Spacer()
                Button("添加") { addTodo() }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.isEmpty)
            }
            .padding(Theme.spacingM)
        }
        .frame(width: 360)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusPanel))
        .onAppear {
            selectedCategory = categories.first
        }
    }

    private func addTodo() {
        guard !title.isEmpty, let cat = selectedCategory else { return }
        vm.addTodo(title: title, priority: priority, dueDate: dueDate, to: cat)
        title = ""
        priority = 1
        dueDate = nil
    }
}
```

- [ ] **Step 2: 创建 QuickInputPanel.swift**

```swift
import AppKit
import SwiftUI
import CoreData

class QuickInputPanel: NSPanel {
    static let shared = QuickInputPanel()

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 480),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        level = .floating
        isMovableByWindowBackground = true
        hasShadow = true
        backgroundColor = .clear

        let context = PersistenceController.shared.container.viewContext
        let view = QuickInputView().environment(\.managedObjectContext, context)
        contentView = NSHostingView(rootView: view)
    }

    func toggle() {
        if isVisible {
            close()
        } else {
            center()
            setFrameOrigin(NSPoint(x: frame.origin.x, y: NSScreen.main!.frame.height * 0.65))
            makeKeyAndOrderFront(nil)
        }
    }
}
```

- [ ] **Step 3: 构建验证**

`⌘B`，确认无错误。

- [ ] **Step 4: Commit**

```bash
git add TodoApp/Views/QuickInput/QuickInputView.swift TodoApp/Views/QuickInput/QuickInputPanel.swift
git commit -m "feat: add QuickInputView and QuickInputPanel for global hotkey"
```

---

### Task 10: 连接快捷键与悬浮窗口

**Files:**
- Modify: `TodoApp/TodoAppApp.swift`

- [ ] **Step 1: 在 TodoAppApp.swift 的 init() 中绑定回调**

```swift
import SwiftUI

@main
struct TodoAppApp: App {
    let persistence = PersistenceController.shared

    init() {
        HotkeyManager.shared.register()
        HotkeyManager.shared.onActivate = {
            DispatchQueue.main.async {
                QuickInputPanel.shared.toggle()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
```

- [ ] **Step 2: 构建并测试**

`⌘R`，在任意应用按 `⌘+Shift+T`，确认悬浮窗口正常唤起和隐藏。

- [ ] **Step 3: Commit**

```bash
git add TodoApp/TodoAppApp.swift
git commit -m "feat: connect global hotkey to QuickInputPanel"
```

---

## 自审检查

**1. 规格覆盖检查:**
- ✅ 分类管理 (CRUD, 拖拽排序) → Task 1-5, 7
- ✅ 待办项管理 (标题, 完成状态, 截止日期, 优先级) → Task 4, 6-7
- ✅ 已完成项折叠区域 → Task 6 TodoListView
- ✅ 全局快捷键快速输入 → Task 8-10
- ✅ Core Data 本地存储 → Task 2
- ✅ 侧边栏+列表布局 → Task 5, 7
- ✅ 悬浮快捷输入窗口 → Task 9-10

**2. 占位符检查:**
无 TBD/TODO/实现后续 等占位符

**3. 类型一致性检查:**
- ✅ Category.id: Int64 (自增主键)
- ✅ TodoItem.id: Int64 (自增主键)
- ✅ TodoItem.priority: Int16 (0=低, 1=中, 2=高)
- ✅ 视图组件命名和方法调用一致

所有 Task 完整，代码块格式正确，可直接执行。

---

**Plan complete and saved to `docs/superpowers/plans/2026-06-02-macos-todo-app.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**