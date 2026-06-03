# Agent Guide

This repository contains a native macOS Todo app implemented from the Superpowers spec and plan.

## Read First

- Product spec: `docs/superpowers/specs/2026-06-02-macos-todo-app-design.md`
- Implementation plan: `docs/superpowers/plans/2026-06-02-macos-todo-app.md`
- Project overview: `README.md`

Use the spec as the source of product intent. Use the implementation plan as an execution history and task checklist, not as an unquestioned script.

## Current State

The Xcode project now exists at `TodoApp.xcodeproj`.

Implemented plan scope:

- Task 1-2: Xcode project skeleton, Core Data model, persistence controller.
- Task 3-4: Theme constants and `TodoViewModel` CRUD.
- Task 5-7: Sidebar, todo rows/list, and main `NavigationSplitView`.
- Task 8-10: HotKey manager, quick-input `NSPanel`, and hotkey-to-panel wiring.

No commits should be assumed from this implementation unless `git log` confirms them; most app files may still be untracked.

## App Target

Build a SwiftUI macOS 13+ app named `TodoApp` with:

- Category CRUD and drag ordering.
- Todo CRUD with title, completion state, optional due date, and priority.
- Completed todos shown at the bottom in a collapsible section.
- Core Data local persistence.
- A global `Command + Shift + T` shortcut that toggles a floating quick-input panel.
- A soft, warm visual style using the theme values in the spec.

## Important Caveats

- The spec says the global shortcut is customizable in Settings, but the current implementation uses a fixed `Command + Shift + T` shortcut. Treat Settings/customization as future scope unless requested.
- The spec sketch includes search in the main window, but the implementation plan did not include a search task. Treat search as unimplemented future scope unless requested.
- The plan describes `Category.id` and `TodoItem.id` as auto-increment primary keys, but the implementation uses monotonic timestamp-based `Int64` IDs in `TodoViewModel`.
- The project uses generated Info.plist settings (`GENERATE_INFOPLIST_FILE = YES`), so Info.plist keys are configured in `TodoApp.xcodeproj/project.pbxproj`, not in a standalone `Info.plist`.
- The HotKey package is configured in the Xcode project, but full build verification requires a complete Xcode install and package resolution.
- Do not use `scripts/dev.sh commit`, `scripts/dev.sh push`, `scripts/dev.sh sync`, or `scripts/auto-commit.sh` without explicit user approval; those scripts can commit or push to `origin main`.

## Development Rules

- Preserve user changes. Check `git status --short` before editing and do not revert unrelated work.
- Keep changes scoped to the requested task.
- Avoid changing generated Xcode project files by hand unless necessary and understood.
- Do not run destructive cleanup commands without explicit approval.
- Do not commit, push, open a pull request, or modify remotes unless requested.

## Project Structure

```text
TodoApp/
├── TodoAppApp.swift
├── Models/
│   └── TodoApp.xcdatamodeld
├── Services/
│   ├── PersistenceController.swift
│   └── HotkeyManager.swift
├── Utilities/
│   └── Theme.swift
├── ViewModels/
│   └── TodoViewModel.swift
└── Views/
    ├── MainWindow/
    └── QuickInput/
```

## Verification

Preferred build check:

```bash
xcodebuild -project TodoApp.xcodeproj -scheme TodoApp -destination 'platform=macOS' build
```

If `xcodebuild` reports that the active developer directory is `/Library/Developer/CommandLineTools`, switch to a full Xcode developer directory before treating build verification as complete.

Useful static checks:

```bash
plutil -lint TodoApp.xcodeproj/project.pbxproj
git status --short
```

Manual checks after a successful build:

- Category add, rename, delete, and drag reorder.
- Todo add, edit title, toggle completion, delete, priority, and optional due date.
- Completed section collapses and expands.
- `Command + Shift + T` opens and hides the quick-input panel.
- Quick-input panel can add and toggle todos, closes on Esc/close button, and hides on deactivate.
