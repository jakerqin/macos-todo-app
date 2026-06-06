import SwiftUI
import CoreData

@MainActor
struct SidebarView: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\.displayOrder)], animation: .default)
    private var categories: FetchedResults<Category>

    @ObservedObject var vm: TodoViewModel
    @Binding var selectedCategory: Category?

    @State private var editingCategoryID: NSManagedObjectID?
    @State private var editingName = ""
    @State private var showingAddSheet = false
    @State private var newCategoryName = ""
    @FocusState private var focusedCategoryID: NSManagedObjectID?

    var body: some View {
        List(selection: $selectedCategory) {
            Section {
                ForEach(categories) { category in
                    categoryRow(category)
                        .tag(category)
                }
                .onMove(perform: moveCategories)
            } header: {
                categoryListHeader
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                addCategoryButton
                    .padding(.leading, -72)
            }
        }
        .sheet(isPresented: $showingAddSheet, onDismiss: resetNewCategoryName) {
            addCategorySheet
        }
    }

    private var categoryListHeader: some View {
        Text("分类列表")
            .font(Theme.rounded(.caption, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.top, 2)
    }

    private var addCategoryButton: some View {
        Button {
            showingAddSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.accentStart)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .controlSize(.regular)
        .help("新建分类")
        .accessibilityLabel("新建分类")
    }

    private var addCategorySheet: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("新建分类")
                .font(Theme.rounded(.title3, weight: .semibold))
                .foregroundStyle(.primary)

            TextField("分类名称", text: $newCategoryName)
                .font(Theme.rounded(.body))
                .textFieldStyle(.roundedBorder)
                .onSubmit(addCategory)

            HStack {
                Spacer()

                Button("取消", role: .cancel) {
                    showingAddSheet = false
                }

                Button("添加") {
                    addCategory()
                }
                .disabled(trimmedNewCategoryName.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(Theme.spacingL)
        .frame(width: 320)
        .background(.background)
    }

    @ViewBuilder
    private func categoryRow(_ category: Category) -> some View {
        if editingCategoryID == category.objectID {
            TextField("分类名称", text: $editingName)
                .font(Theme.rounded(.body, weight: .medium))
                .textFieldStyle(.plain)
                .padding(.vertical, Theme.spacingS)
                .focused($focusedCategoryID, equals: category.objectID)
                .onAppear {
                    focusedCategoryID = category.objectID
                }
                .onSubmit {
                    commitRename(for: category)
                }
                .onExitCommand {
                    cancelRename()
                }
                .contextMenu {
                    categoryMenu(for: category)
                }
        } else {
            Text(category.name ?? "")
                .font(Theme.rounded(.body, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .padding(.vertical, Theme.spacingS)
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    beginRename(for: category)
                }
                .contextMenu {
                    categoryMenu(for: category)
                }
        }
    }

    @ViewBuilder
    private func categoryMenu(for category: Category) -> some View {
        Button("重命名") {
            beginRename(for: category)
        }

        Button("删除", role: .destructive) {
            delete(category)
        }
    }

    private var trimmedNewCategoryName: String {
        newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addCategory() {
        guard !trimmedNewCategoryName.isEmpty else { return }

        vm.addCategory(name: newCategoryName, after: lastDisplayOrder)
        showingAddSheet = false
    }

    private func beginRename(for category: Category) {
        editingCategoryID = category.objectID
        editingName = category.name ?? ""
        focusedCategoryID = category.objectID
    }

    private func commitRename(for category: Category) {
        vm.renameCategory(category, to: editingName)
        cancelRename()
    }

    private func cancelRename() {
        editingCategoryID = nil
        editingName = ""
        focusedCategoryID = nil
    }

    private func delete(_ category: Category) {
        if selectedCategory?.objectID == category.objectID {
            selectedCategory = nil
        }

        if editingCategoryID == category.objectID {
            cancelRename()
        }

        vm.deleteCategory(category)
    }

    private func moveCategories(from source: IndexSet, to destination: Int) {
        var orderedCategories = Array(categories)
        orderedCategories.move(fromOffsets: source, toOffset: destination)
        vm.reorderCategories(orderedCategories)
    }

    private var lastDisplayOrder: Int16 {
        categories.map(\.displayOrder).max() ?? -1
    }

    private func resetNewCategoryName() {
        newCategoryName = ""
    }
}
