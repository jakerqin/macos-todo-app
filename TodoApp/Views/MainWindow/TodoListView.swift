import SwiftUI
import CoreData

@MainActor
struct TodoListView: View {
    let category: Category
    @ObservedObject var vm: TodoViewModel

    @State private var showCompleted = false
    @State private var newTodoTitle = ""
    @State private var newTodoPriority: Int16 = 1
    @State private var newTodoDueDate: Date?
    @State private var showAddSheet = false
    @State private var editingTodo: TodoItem?
    @State private var editTodoTitle = ""
    @State private var editTodoPriority: Int16 = 1
    @State private var editTodoDueDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            todoScrollView
        }
        .sheet(isPresented: $showAddSheet, onDismiss: resetNewTodoState) {
            addTodoSheet
        }
        .sheet(isPresented: isEditingTodo, onDismiss: resetEditTodoState) {
            if let editingTodo {
                editTodoSheet(for: editingTodo)
            }
        }
        .navigationTitle(category.name ?? "")
    }

    private var todoScrollView: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(activeTodos, id: \.objectID) { item in
                            row(for: item)
                        }

                        if !completedTodos.isEmpty {
                            completedSection
                        }
                    }
                    .padding(Theme.spacingS)

                    Spacer(minLength: 0)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            showAddSheet = true
                        }
                }
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .topLeading)
            }
        }
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    showCompleted.toggle()
                }
            } label: {
                HStack(spacing: Theme.spacingS) {
                    Image(systemName: showCompleted ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 14)

                    Text("已完成 (\(completedTodos.count))")
                        .font(Theme.rounded(.subheadline, weight: .semibold))

                    Spacer()
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, Theme.spacingS)
                .padding(.top, Theme.spacingS)
                .padding(.bottom, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showCompleted {
                ForEach(completedTodos, id: \.objectID) { item in
                    row(for: item)
                }
            }
        }
    }

    private var addTodoSheet: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("新建待办项")
                .font(Theme.rounded(.title3, weight: .semibold))
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Text("标题")
                    .font(Theme.rounded(.callout, weight: .medium))
                    .foregroundStyle(.secondary)

                TextField("标题", text: $newTodoTitle)
                    .font(Theme.rounded(.body))
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addTodo)
            }

            Picker("优先级", selection: $newTodoPriority) {
                Text("低").tag(Int16(0))
                Text("中").tag(Int16(1))
                Text("高").tag(Int16(2))
            }
            .font(Theme.rounded(.body))
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Toggle("设置截止日期", isOn: hasDueDateBinding)
                    .font(Theme.rounded(.body))

                if newTodoDueDate != nil {
                    DatePicker(
                        "截止日期（可选）",
                        selection: dueDateBinding,
                        displayedComponents: .date
                    )
                    .font(Theme.rounded(.body))
                }
            }

            HStack {
                Spacer()

                Button("取消", role: .cancel) {
                    showAddSheet = false
                }

                Button("添加") {
                    addTodo()
                }
                .disabled(trimmedNewTodoTitle.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(Theme.spacingL)
        .frame(width: 360)
        .background(.background)
    }

    private func editTodoSheet(for item: TodoItem) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("编辑待办项")
                .font(Theme.rounded(.title3, weight: .semibold))
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Text("标题")
                    .font(Theme.rounded(.callout, weight: .medium))
                    .foregroundStyle(.secondary)

                TextField("标题", text: $editTodoTitle)
                    .font(Theme.rounded(.body))
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        updateTodo(item)
                    }
            }

            Picker("优先级", selection: $editTodoPriority) {
                Text("低").tag(Int16(0))
                Text("中").tag(Int16(1))
                Text("高").tag(Int16(2))
            }
            .font(Theme.rounded(.body))
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Toggle("设置截止日期", isOn: hasEditDueDateBinding)
                    .font(Theme.rounded(.body))

                if editTodoDueDate != nil {
                    DatePicker(
                        "截止日期（可选）",
                        selection: editDueDateBinding,
                        displayedComponents: .date
                    )
                    .font(Theme.rounded(.body))
                }
            }

            HStack {
                Spacer()

                Button("取消", role: .cancel) {
                    editingTodo = nil
                }

                Button("保存") {
                    updateTodo(item)
                }
                .disabled(trimmedEditTodoTitle.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(Theme.spacingL)
        .frame(width: 360)
        .background(.background)
    }

    private var activeTodos: [TodoItem] {
        allTodos
            .filter { !$0.isCompleted }
            .sorted(by: sortByPriorityAndCreatedAt)
    }

    private var completedTodos: [TodoItem] {
        allTodos
            .filter(\.isCompleted)
            .sorted(by: sortByPriorityAndCreatedAt)
    }

    private var allTodos: [TodoItem] {
        let items = category.items as? Set<TodoItem>
        return Array(items ?? Set<TodoItem>())
    }

    private var trimmedNewTodoTitle: String {
        newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedEditTodoTitle: String {
        editTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isEditingTodo: Binding<Bool> {
        Binding {
            editingTodo != nil
        } set: { isPresented in
            if !isPresented {
                editingTodo = nil
            }
        }
    }

    private var hasDueDateBinding: Binding<Bool> {
        Binding {
            newTodoDueDate != nil
        } set: { hasDueDate in
            newTodoDueDate = hasDueDate ? (newTodoDueDate ?? Date()) : nil
        }
    }

    private var dueDateBinding: Binding<Date> {
        Binding {
            newTodoDueDate ?? Date()
        } set: { date in
            newTodoDueDate = date
        }
    }

    private var hasEditDueDateBinding: Binding<Bool> {
        Binding {
            editTodoDueDate != nil
        } set: { hasDueDate in
            editTodoDueDate = hasDueDate ? (editTodoDueDate ?? Date()) : nil
        }
    }

    private var editDueDateBinding: Binding<Date> {
        Binding {
            editTodoDueDate ?? Date()
        } set: { date in
            editTodoDueDate = date
        }
    }

    private func row(for item: TodoItem) -> some View {
        TodoRowView(item: item) {
            vm.toggleComplete(item)
        } onDelete: {
            vm.deleteTodo(item)
        } onEdit: {
            beginEdit(item)
        }
    }

    private func sortByPriorityAndCreatedAt(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
        if lhs.priority != rhs.priority {
            return lhs.priority > rhs.priority
        }

        let lhsDate = lhs.createdAt ?? .distantPast
        let rhsDate = rhs.createdAt ?? .distantPast

        if lhsDate == rhsDate {
            return lhs.objectID.uriRepresentation().absoluteString < rhs.objectID.uriRepresentation().absoluteString
        }

        return lhsDate < rhsDate
    }

    private func beginEdit(_ item: TodoItem) {
        editingTodo = item
        editTodoTitle = item.title ?? ""
        editTodoPriority = item.priority
        editTodoDueDate = item.dueDate
    }

    private func addTodo() {
        guard !trimmedNewTodoTitle.isEmpty else { return }

        vm.addTodo(
            title: newTodoTitle,
            priority: newTodoPriority,
            dueDate: newTodoDueDate,
            to: category
        )
        showAddSheet = false
    }

    private func updateTodo(_ item: TodoItem) {
        guard !trimmedEditTodoTitle.isEmpty else { return }

        vm.updateTodo(
            item,
            title: editTodoTitle,
            priority: editTodoPriority,
            dueDate: editTodoDueDate
        )
        editingTodo = nil
    }

    private func resetNewTodoState() {
        newTodoTitle = ""
        newTodoPriority = 1
        newTodoDueDate = nil
    }

    private func resetEditTodoState() {
        editTodoTitle = ""
        editTodoPriority = 1
        editTodoDueDate = nil
    }
}
