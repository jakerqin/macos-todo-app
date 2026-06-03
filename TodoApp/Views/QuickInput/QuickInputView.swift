import CoreData
import SwiftUI

@MainActor
struct QuickInputView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [SortDescriptor(\.displayOrder)], animation: .default)
    private var categories: FetchedResults<Category>

    let onClose: () -> Void

    @State private var selectedCategory: Category?
    @State private var title = ""
    @State private var priority: Int16 = 1
    @State private var dueDate: Date?

    private var vm: TodoViewModel {
        TodoViewModel(context: context)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            titleField

            Divider()

            options

            Divider()

            todoList

            Divider()

            footer
        }
        .frame(width: 360)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusPanel, style: .continuous))
        .onAppear {
            if selectedCategory == nil {
                selectedCategory = categories.first
            }
        }
        .onExitCommand(perform: onClose)
    }

    private var header: some View {
        HStack(spacing: Theme.spacingS) {
            Picker("", selection: $selectedCategory) {
                ForEach(categories, id: \.objectID) { category in
                    Text(category.name ?? "").tag(Optional(category))
                }
            }
            .labelsHidden()
            .frame(maxWidth: 180)

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("关闭")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.spacingM)
        .padding(.top, Theme.spacingM)
        .padding(.bottom, Theme.spacingS)
    }

    private var titleField: some View {
        TextField("输入待办项标题...", text: $title)
            .font(Theme.rounded(.body))
            .textFieldStyle(.plain)
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, Theme.spacingS)
            .onSubmit(addTodo)
    }

    private var options: some View {
        HStack(spacing: Theme.spacingM) {
            Picker("", selection: $priority) {
                Text("低").tag(Int16(0))
                Text("中").tag(Int16(1))
                Text("高").tag(Int16(2))
            }
            .pickerStyle(.segmented)
            .frame(width: 140)

            Spacer()

            Toggle("截止", isOn: hasDueDateBinding)
                .font(Theme.rounded(.callout))

            if dueDate != nil {
                DatePicker("", selection: dueDateBinding, displayedComponents: .date)
                    .labelsHidden()
            }
        }
        .padding(.horizontal, Theme.spacingM)
        .padding(.vertical, Theme.spacingS)
    }

    private var todoList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(currentTodos, id: \.objectID) { item in
                    quickTodoRow(item)
                }
            }
            .padding(.vertical, Theme.spacingS)
        }
        .frame(maxHeight: 200)
    }

    private var footer: some View {
        HStack {
            Spacer()

            Button("添加") {
                addTodo()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(trimmedTitle.isEmpty || selectedCategory == nil)
        }
        .padding(Theme.spacingM)
    }

    private func quickTodoRow(_ item: TodoItem) -> some View {
        HStack(spacing: Theme.spacingS) {
            Button {
                vm.toggleComplete(item)
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(item.isCompleted ? Theme.accentStart : Color.secondary)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)

            Text(item.title ?? "")
                .font(Theme.rounded(.body))
                .foregroundStyle(item.isCompleted ? Color.secondary : Color.primary)
                .strikethrough(item.isCompleted, color: .secondary)
                .lineLimit(1)

            Spacer(minLength: Theme.spacingS)
        }
        .padding(.horizontal, Theme.spacingM)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var currentTodos: [TodoItem] {
        guard let selectedCategory else { return [] }
        let items = selectedCategory.items as? Set<TodoItem>
        return Array(items ?? Set<TodoItem>()).sorted(by: sortByCreatedAt)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasDueDateBinding: Binding<Bool> {
        Binding {
            dueDate != nil
        } set: { hasDueDate in
            dueDate = hasDueDate ? (dueDate ?? Date()) : nil
        }
    }

    private var dueDateBinding: Binding<Date> {
        Binding {
            dueDate ?? Date()
        } set: { date in
            dueDate = date
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
        guard !trimmedTitle.isEmpty, let selectedCategory else { return }

        vm.addTodo(title: title, priority: priority, dueDate: dueDate, to: selectedCategory)
        title = ""
        priority = 1
        dueDate = nil
    }
}
