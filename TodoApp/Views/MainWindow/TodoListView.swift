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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            toolbar

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(activeTodos, id: \.objectID) { item in
                        row(for: item)
                    }

                    if !completedTodos.isEmpty {
                        completedSection
                    }
                }
                .padding(Theme.spacingS)
            }
        }
        .sheet(isPresented: $showAddSheet, onDismiss: resetNewTodoState) {
            addTodoSheet
        }
        .navigationTitle(category.name ?? "")
    }

    private var toolbar: some View {
        HStack {
            Button {
                showAddSheet = true
            } label: {
                Label("新待办项", systemImage: "plus")
                    .font(Theme.rounded(.body, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accentStart)

            Spacer()
        }
        .padding(Theme.spacingM)
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

    private var activeTodos: [TodoItem] {
        allTodos
            .filter { !$0.isCompleted }
            .sorted(by: sortByCreatedAt)
    }

    private var completedTodos: [TodoItem] {
        allTodos
            .filter(\.isCompleted)
            .sorted(by: sortByCreatedAt)
    }

    private var allTodos: [TodoItem] {
        let items = category.items as? Set<TodoItem>
        return Array(items ?? Set<TodoItem>())
    }

    private var trimmedNewTodoTitle: String {
        newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines)
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

    private func row(for item: TodoItem) -> some View {
        TodoRowView(item: item) {
            vm.toggleComplete(item)
        } onDelete: {
            vm.deleteTodo(item)
        } onUpdate: { title, priority, dueDate in
            vm.updateTodo(item, title: title, priority: priority, dueDate: dueDate)
        }
    }

    private func sortByCreatedAt(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
        let lhsDate = lhs.createdAt ?? .distantPast
        let rhsDate = rhs.createdAt ?? .distantPast

        if lhsDate == rhsDate {
            return lhs.objectID.uriRepresentation().absoluteString < rhs.objectID.uriRepresentation().absoluteString
        }

        return lhsDate < rhsDate
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

    private func resetNewTodoState() {
        newTodoTitle = ""
        newTodoPriority = 1
        newTodoDueDate = nil
    }
}
