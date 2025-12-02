import SwiftUI
import UniformTypeIdentifiers

// 主视图
struct AtmosphericProjectView: View {
    @ObservedObject var viewModel: PaperDoViewModel
    @State private var selectedProjectID: UUID? = nil
    
    // --- 1. 全局弹窗状态管理 ---
    @State private var showAddProjectModal = false
    @State private var newProjectName = ""
    
    @State private var showRenameModal = false
    @State private var projectToRename: Project?
    @State private var renameText = ""
    
    @State private var showDeleteAlert = false
    @State private var projectToDelete: Project?
    
    @State private var showAddTaskModal = false
    @State private var newTaskContent = ""
    @State private var activeColumnId: String? = nil
    
    @State private var showEditTaskModal = false
    @State private var editingTaskContent = ""
    @State private var editingTaskId: UUID?
    
    var body: some View {
        ZStack(alignment: .top) {
            // 1. 全局背景色 (强制纯白，消除割裂感)
            Color.white.ignoresSafeArea()

            // 主容器 (限制最大宽度)
            VStack(spacing: 0) {
                if let projectID = selectedProjectID,
                   let project = viewModel.projects.first(where: { $0.id == projectID }) {
                    
                    // --- 场景 B: 项目详情视图 (Kanban) ---
                    projectDetailView(project: project)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    
                } else {
                    
                    // --- 场景 A: 项目概览视图 (Gallery) ---
                    projectGalleryView
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
            .frame(maxWidth: 1000)
            .frame(maxHeight: .infinity)
            .background(Color.white) // [Fix] 确保内容容器纯白
            
            // --- 2. 自定义模态弹窗层 ---
            // (弹窗逻辑保持不变)
            if showAddProjectModal {
                ModernInputAlert(
                    isPresented: $showAddProjectModal,
                    title: "New Project",
                    placeholder: "Enter project name",
                    text: $newProjectName,
                    actionButtonText: "Create",
                    onCommit: {
                        if !newProjectName.isEmpty {
                            viewModel.addProject(name: newProjectName)
                            newProjectName = ""
                        }
                    }
                )
            }
            
            if showRenameModal {
                ModernInputAlert(
                    isPresented: $showRenameModal,
                    title: "Rename Project",
                    placeholder: "Enter new name",
                    text: $renameText,
                    actionButtonText: "Rename",
                    onCommit: {
                        if let p = projectToRename, !renameText.isEmpty {
                            viewModel.renameProject(id: p.id, newName: renameText)
                        }
                    }
                )
            }
            
            if showAddTaskModal {
                ModernInputAlert(
                    isPresented: $showAddTaskModal,
                    title: "Add New Task",
                    placeholder: "What needs to be done?",
                    text: $newTaskContent,
                    actionButtonText: "Add",
                    onCommit: {
                        if let pid = selectedProjectID, let cid = activeColumnId, !newTaskContent.isEmpty {
                            viewModel.addProjectTask(projectID: pid, content: newTaskContent, columnId: cid)
                            newTaskContent = ""
                        }
                    }
                )
            }
            
            if showEditTaskModal {
                ModernInputAlert(
                    isPresented: $showEditTaskModal,
                    title: "Edit Task",
                    placeholder: "Update task content",
                    text: $editingTaskContent,
                    actionButtonText: "Save",
                    onCommit: {
                        if let pid = selectedProjectID, let tid = editingTaskId, !editingTaskContent.isEmpty {
                            viewModel.updateProjectTask(projectID: pid, taskID: tid, newContent: editingTaskContent)
                        }
                    }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white) // [Fix] 最外层确保纯白
        .alert("Delete Project", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let p = projectToDelete {
                    withAnimation {
                        if selectedProjectID == p.id { selectedProjectID = nil }
                        viewModel.deleteProject(id: p.id)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(projectToDelete?.name ?? "this project")'? This action cannot be undone.")
        }
    }
    
    // --- 视图组件拆分 ---
    
    // 1. 项目概览 (Gallery)
    // [重点修改] 将 Header 和 Grid 放入同一个 ScrollView，实现一起滚动
    var projectGalleryView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Projects")
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundColor(.black)
                        
                        Text("Workspace")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                            .tracking(0.5)
                    }
                    
                    Spacer()
                    
                    // Add Project Button
                    Button(action: {
                        newProjectName = ""
                        withAnimation(.spring()) { showAddProjectModal = true }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text("New Project")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24) // [Fix] 统一边距 24
                .padding(.top, 24)        // [Fix] 顶部留白
                .padding(.bottom, 24)     // [Fix] 底部留白
                
                // Grid Content
                // [修改] 始终显示 Grid，即使为空，也会显示虚线添加按钮
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 20)], spacing: 20) {
                    // 现有项目卡片
                    ForEach(viewModel.projects) { project in
                        ProjectSummaryCard(project: project)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selectedProjectID = project.id
                                }
                            }
                            .contextMenu {
                                Button {
                                    projectToRename = project
                                    renameText = project.name
                                    withAnimation(.spring()) { showRenameModal = true }
                                } label: { Label("Rename", systemImage: "pencil") }
                                Button(role: .destructive) {
                                    projectToDelete = project
                                    showDeleteAlert = true
                                } label: { Label("Delete", systemImage: "trash") }
                            }
                    }
                    
                    // [新增] 虚线添加按钮 (作为 Grid 的一项)
                    Button(action: {
                        newProjectName = ""
                        withAnimation(.spring()) { showAddProjectModal = true }
                    }) {
                        VStack(spacing: 12) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .regular))
                                .foregroundColor(.gray.opacity(0.4))
                            
                            Text("Create New Project")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 140) // 与 ProjectSummaryCard 高度一致
                        .background(Color.gray.opacity(0.02))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 6])) // 虚线边框
                                .foregroundColor(.gray.opacity(0.15))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24) // [Fix] 统一边距 24
                .padding(.bottom, 40)
            }
        }
        .background(Color.white) // [Fix] 强制背景纯白
    }
    
    // 2. 项目详情 (Kanban Detail)
    func projectDetailView(project: Project) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .center) {
                // 左侧：返回 + 标题
                HStack(spacing: 16) {
                    Button(action: { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { selectedProjectID = nil } }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                            .padding(8)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            // 稍微加个边框确保在纯白背景下可见
                            .overlay(Circle().stroke(Color.gray.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(project.name)
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundColor(.black)
                        
                        let doneCount = project.tasks.filter { $0.columnId == "done" }.count
                        Text("\(doneCount) / \(project.tasks.count) completed")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // 右侧：操作区
                HStack(spacing: 8) {
                    Button(action: {
                        projectToRename = project
                        renameText = project.name
                        withAnimation(.spring()) { showRenameModal = true }
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundColor(.black)
                            .frame(width: 32, height: 32)
                            .background(Color(white: 0.96))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        projectToDelete = project
                        showDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.8))
                            .frame(width: 32, height: 32)
                            .background(Color(white: 0.96))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24) // [Fix] 统一边距
            .padding(.vertical, 24)
            
            // 看板列区域
            HStack(alignment: .top, spacing: 16) {
                buildColumn(id: "todo", title: "To Do", color: .blue, project: project)
                buildColumn(id: "doing", title: "In Progress", color: .orange, project: project)
                buildColumn(id: "done", title: "Done", color: .green, project: project)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.white) // [Fix] 确保背景纯白
    }
    
    // 辅助函数：构建看板列
    @ViewBuilder
    func buildColumn(id: String, title: String, color: Color, project: Project) -> some View {
        AtmosphericKanbanColumn(
            viewModel: viewModel,
            projectID: project.id,
            columnId: id,
            title: title,
            tasks: project.tasks.filter { $0.columnId == id },
            accentColor: color,
            onAddTap: {
                activeColumnId = id
                newTaskContent = ""
                withAnimation(.spring()) { showAddTaskModal = true }
            },
            onEditTap: { task in
                editingTaskId = task.id
                editingTaskContent = task.content
                withAnimation(.spring()) { showEditTaskModal = true }
            }
        )
    }
}

// --- 3. 优化后的看板列组件 (扁平化) ---
struct AtmosphericKanbanColumn: View {
    @ObservedObject var viewModel: PaperDoViewModel
    let projectID: UUID
    let columnId: String
    let title: String
    let tasks: [ProjectTask]
    let accentColor: Color
    
    let onAddTap: () -> Void
    let onEditTap: (ProjectTask) -> Void
    
    @State private var isTargeted = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 列标题
            HStack {
                Circle().fill(accentColor).frame(width: 6, height: 6)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.black.opacity(0.7))
                Spacer()
                Text("\(tasks.count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            
            // 任务列表
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) { // 任务间距
                    ForEach(tasks) { task in
                        HStack(alignment: .top, spacing: 10) {
                            Text(task.content)
                                .font(.system(size: 14))
                                .foregroundColor(columnId == "done" ? .gray : .black.opacity(0.85))
                                .strikethrough(columnId == "done", color: .gray.opacity(0.5))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineSpacing(2)
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(10)
                        // [Fix] 减弱阴影，适配纯白背景
                        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black.opacity(0.05), lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                        .onDrag { NSItemProvider(object: task.id.uuidString as NSString) }
                        .contextMenu {
                            Section {
                                if columnId != "todo" { Button("To Do") { withAnimation { viewModel.moveProjectTask(projectID: projectID, taskID: task.id, toColumn: "todo") } } }
                                if columnId != "doing" { Button("In Progress") { withAnimation { viewModel.moveProjectTask(projectID: projectID, taskID: task.id, toColumn: "doing") } } }
                                if columnId != "done" { Button("Done") { withAnimation { viewModel.moveProjectTask(projectID: projectID, taskID: task.id, toColumn: "done") } } }
                            }
                            Button { onEditTap(task) } label: { Label("Edit", systemImage: "pencil") }
                            Button(role: .destructive) {
                                withAnimation { viewModel.deleteProjectTask(projectID: projectID, taskID: task.id) }
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                    
                    // Add Button
                    Button(action: onAddTap) {
                        HStack {
                            Image(systemName: "plus").font(.system(size: 10))
                            Text("Add Task").font(.system(size: 12))
                        }
                        .foregroundColor(.gray.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4])))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // [Fix] 背景色极淡，几乎融合
        .background(Color(white: 0.98))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isTargeted ? accentColor.opacity(0.4) : Color.clear, lineWidth: 2)
        )
        .onDrop(of: ["public.text"], isTargeted: $isTargeted, perform: { providers in
            KanbanDropDelegate(viewModel: viewModel, projectID: projectID, targetColumnId: columnId).performDrop(info: providers)
        })
    }
}

// --- ProjectSummaryCard (更精致的卡片) ---
struct ProjectSummaryCard: View {
    let project: Project
    var totalTasks: Int { project.tasks.count }
    var doneTasks: Int { project.tasks.filter { $0.columnId == "done" }.count }
    var progress: Double { totalTasks > 0 ? Double(doneTasks) / Double(totalTasks) : 0 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon
            HStack {
                Image(systemName: "folder.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.black.opacity(0.8))
                Spacer()
                if progress >= 1.0 {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green).font(.system(size: 16))
                } else if progress > 0 {
                    Image(systemName: "chart.pie.fill").foregroundColor(.orange).font(.system(size: 16))
                }
            }
            
            Spacer()
            
            // Title
            Text(project.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
                .lineLimit(2)
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.gray.opacity(0.1)).frame(height: 3)
                        Capsule().fill(Color.black).frame(width: geo.size.width * CGFloat(progress), height: 3)
                    }
                }
                .frame(height: 3)
                
                Text("\(Int(progress * 100))% done")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
        }
        .padding(20)
        .frame(height: 140)
        .background(Color.white)
        .cornerRadius(16)
        // [Fix] 适配纯白背景的阴影
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.02), lineWidth: 1)
        )
    }
}

// --- 拖拽代理 (保持不变) ---
struct KanbanDropDelegate {
    let viewModel: PaperDoViewModel
    let projectID: UUID
    let targetColumnId: String
    func performDrop(info: [NSItemProvider]) -> Bool {
        guard let itemProvider = info.first(where: { $0.hasItemConformingToTypeIdentifier("public.text") }) else { return false }
        itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
            if let data = data as? Data, let uuidString = String(data: data, encoding: .utf8), let taskId = UUID(uuidString: uuidString) {
                DispatchQueue.main.async {
                    withAnimation(.spring()) {
                        viewModel.moveProjectTask(projectID: projectID, taskID: taskId, toColumn: targetColumnId)
                    }
                }
            }
        }
        return true
    }
}

// --- 4. 现代输入弹窗组件 ---
struct ModernInputAlert: View {
    @Binding var isPresented: Bool
    let title: String
    let placeholder: String
    @Binding var text: String
    var actionButtonText: String = "Confirm"
    let onCommit: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.2).ignoresSafeArea()
                .onTapGesture { withAnimation(.spring()) { isPresented = false } }
            
            VStack(spacing: 20) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(.black)
                
                TextField(placeholder, text: $text)
                    .font(.system(size: 15))
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(white: 0.97))
                    .cornerRadius(10)
                    .onSubmit {
                        onCommit()
                        withAnimation(.spring()) { isPresented = false }
                    }
                
                HStack(spacing: 12) {
                    Button(action: { withAnimation(.spring()) { isPresented = false } }) {
                        Text("Cancel")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        onCommit()
                        withAnimation(.spring()) { isPresented = false }
                    }) {
                        Text(actionButtonText)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
            .frame(width: 320)
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        }
        .zIndex(100)
    }
}
