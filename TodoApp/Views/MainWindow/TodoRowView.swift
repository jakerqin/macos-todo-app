import SwiftUI

@MainActor
struct TodoRowView: View {
    @ObservedObject var item: TodoItem

    let onToggle: () -> Void
    let onDelete: () -> Void
    let onUpdate: (_ title: String, _ priority: Int16, _ dueDate: Date?) -> Void

    @State private var isEditingTitle = false
    @State private var draftTitle = ""
    @State private var isHovering = false
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        HStack(spacing: Theme.spacingS) {
            completionButton

            titleContent

            Spacer(minLength: Theme.spacingS)

            priorityBadge

            if let dueDate = item.dueDate {
                dueDateLabel(dueDate)
            }
        }
        .padding(.horizontal, Theme.spacingS)
        .padding(.vertical, 8)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusItem, style: .continuous))
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .contextMenu {
            Button("删除", role: .destructive) {
                onDelete()
            }
        }
    }

    private var completionButton: some View {
        Button {
            onToggle()
        } label: {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(item.isCompleted ? Theme.accentStart : Color.secondary)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.isCompleted ? "标记为未完成" : "标记为已完成")
    }

    @ViewBuilder
    private var titleContent: some View {
        if isEditingTitle {
            TextField("标题", text: $draftTitle)
                .font(Theme.rounded(.body))
                .textFieldStyle(.plain)
                .focused($isTitleFocused)
                .onAppear {
                    isTitleFocused = true
                }
                .onSubmit(commitTitle)
                .onExitCommand(perform: cancelTitleEdit)
        } else {
            Text(item.title ?? "")
                .font(Theme.rounded(.body))
                .foregroundStyle(item.isCompleted ? Color.secondary : Color.primary)
                .strikethrough(item.isCompleted, color: .secondary)
                .lineLimit(2)
                .onTapGesture(count: 2, perform: beginTitleEdit)
        }
    }

    private var priorityBadge: some View {
        Text(priorityLabel)
            .font(Theme.rounded(.caption2, weight: .semibold))
            .foregroundStyle(priorityColor)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(priorityColor.opacity(0.12), in: Capsule())
            .accessibilityLabel("优先级\(priorityLabel)")
    }

    private func dueDateLabel(_ date: Date) -> some View {
        Text(date, format: .dateTime.year().month().day())
            .font(Theme.rounded(.caption))
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: Theme.radiusItem, style: .continuous)
            .fill(isHovering ? Theme.accentStart.opacity(0.08) : Color.clear)
    }

    private var priorityLabel: String {
        switch item.priority {
        case 2:
            return "高"
        case 1:
            return "中"
        default:
            return "低"
        }
    }

    private var priorityColor: Color {
        switch item.priority {
        case 2:
            return .red
        case 1:
            return .orange
        default:
            return .green
        }
    }

    private func beginTitleEdit() {
        draftTitle = item.title ?? ""
        isEditingTitle = true
    }

    private func commitTitle() {
        let trimmedTitle = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            cancelTitleEdit()
            return
        }

        onUpdate(trimmedTitle, item.priority, item.dueDate)
        isEditingTitle = false
        isTitleFocused = false
    }

    private func cancelTitleEdit() {
        isEditingTitle = false
        draftTitle = ""
        isTitleFocused = false
    }
}
